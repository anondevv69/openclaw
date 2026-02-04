#!/usr/bin/env bash
# Zora Coins REST API wrapper
# Usage: zora.sh <command> [args]
# Commands: coin <address> [chain], profile <identifier>, explore <trending|new|top-gainers> [chain]

set -euo pipefail

# Always set so api_get never sees unbound variable (e.g. when exec runs script)
CURL_EXTRA=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
API_BASE="https://api-sdk.zora.engineering"

# Find config (optional)
CONFIG_FILE=""
if [[ -f "$SKILL_DIR/config.json" ]]; then
    CONFIG_FILE="$SKILL_DIR/config.json"
elif [[ -f "${HOME}/.moltbot/skills/zora/config.json" ]]; then
    CONFIG_FILE="${HOME}/.moltbot/skills/zora/config.json"
elif [[ -f "${HOME}/.clawdbot/skills/zora/config.json" ]]; then
    CONFIG_FILE="${HOME}/.clawdbot/skills/zora/config.json"
fi

# Optional: load .env in skill dir so ZORA_API_KEY overrides config
if [[ -f "$SKILL_DIR/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$SKILL_DIR/.env"
    set +a
fi

# Config must use exactly: apiKey (or api_key). Overridden by env ZORA_API_KEY.
API_KEY=""
if [[ -n "${ZORA_API_KEY:-}" ]]; then
    API_KEY="$ZORA_API_KEY"
elif [[ -n "${CONFIG_FILE:-}" ]]; then
    API_KEY=$(jq -r '.apiKey // .api_key // empty' "$CONFIG_FILE")
fi
API_KEY="${API_KEY//[$'\r\n']/}"
API_KEY="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
API_KEY="${API_KEY%"${API_KEY##*[![:space:]]}"}"

# Optional api-key header for curl
if [[ -n "${API_KEY:-}" ]] && [[ "$API_KEY" != "null" ]]; then
    CURL_EXTRA=(-H "api-key: $API_KEY")
fi

api_get() {
    local url="$1"
    local tmp
    tmp=$(mktemp -t zora-get.XXXXXX)
    trap 'rm -f "$tmp"' RETURN
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o "$tmp" -H "Content-Type: application/json" "${CURL_EXTRA[@]+"${CURL_EXTRA[@]}"}" "$url")
    local response
    response=$(<"$tmp")
    if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
        echo "Error: API request failed for $url (HTTP $http_code)" >&2
        if [[ -n "$response" ]]; then
            echo "Response: $(echo "$response" | jq -c 'if type == "object" then (.message // .msg // .error // .) else . end' 2>/dev/null || echo "$response" | head -c 600)" >&2
        fi
        return 1
    fi
    echo "$response"
}

cmd_coin() {
    local address="${1:?Usage: zora.sh coin <contract_address> [chain_id]}"
    local chain="${2:-8453}"
    api_get "${API_BASE}/coin?address=${address}&chain=${chain}" | jq .
}

cmd_profile() {
    local identifier="${1:?Usage: zora.sh profile <address_or_identifier>}"
    api_get "${API_BASE}/profile?identifier=${identifier}" | jq .
}

cmd_explore() {
    local kind="${1:?Usage: zora.sh explore <trending|new|top-gainers> [chain_id]}"
    local chain="${2:-8453}"
    # Zora API listType must be one of: TOP_GAINERS, NEW, TRENDING_ALL, etc. (see OpenAPI enum)
    local list_type=""
    case "$kind" in
        trending)   list_type="TRENDING_ALL" ;;
        new)        list_type="NEW" ;;
        top-gainers) list_type="TOP_GAINERS" ;;
        *) echo "Error: explore type must be trending, new, or top-gainers" >&2; exit 1 ;;
    esac
    api_get "${API_BASE}/explore?listType=${list_type}&chain=${chain}" | jq .
}

usage() {
    echo "Usage: zora.sh <command> [args]"
    echo "  coin <address> [chain]     - Coin by contract address (default chain 8453 = Base)"
    echo "  profile <identifier>     - Profile balances and activity"
    echo "  explore <trending|new|top-gainers> [chain] - Explore coins"
    exit 1
}

case "${1:-}" in
    coin)   shift; cmd_coin "$@" ;;
    profile) shift; cmd_profile "$@" ;;
    explore) shift; cmd_explore "$@" ;;
    *) usage ;;
esac
