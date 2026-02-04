#!/usr/bin/env bash
set -euo pipefail

# Neynar Farcaster API wrapper
# Usage: neynar.sh <command> [args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Find config: skill dir (workspace) first, then ~/.clawdbot, then ~/.moltbot
if [[ -f "$SKILL_DIR/config.json" ]]; then
    CONFIG_FILE="$SKILL_DIR/config.json"
elif [[ -f "${HOME}/.clawdbot/skills/neynar/config.json" ]]; then
    CONFIG_FILE="${HOME}/.clawdbot/skills/neynar/config.json"
elif [[ -f "${HOME}/.moltbot/skills/neynar/config.json" ]]; then
    CONFIG_FILE="${HOME}/.moltbot/skills/neynar/config.json"
else
    echo "Error: Config not found. Create skills/neynar/config.json or ~/.moltbot/skills/neynar/config.json with {\"apiKey\":\"YOUR_NEYNAR_API_KEY\"}" >&2
    exit 1
fi

# Optional: load .env in skill dir so NEYNAR_API_KEY / NEYNAR_SIGNER_UUID override config
if [[ -f "$SKILL_DIR/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$SKILL_DIR/.env"
    set +a
fi

API_BASE="https://api.neynar.com/v2/farcaster"

# Load config; overridden by env NEYNAR_API_KEY and NEYNAR_SIGNER_UUID (or .env)
# Config must use exactly: apiKey, signerUuid (not "farcaster signer UUID" or "farcaster FID")
API_KEY="${NEYNAR_API_KEY:-$(jq -r '.apiKey // .api_key // empty' "$CONFIG_FILE")}"
API_KEY="${API_KEY//[$'\r\n']/}"
API_KEY="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
API_KEY="${API_KEY%"${API_KEY##*[![:space:]]}"}"
SIGNER_UUID="${NEYNAR_SIGNER_UUID:-$(jq -r '.signerUuid // .signer_uuid // empty' "$CONFIG_FILE")}"
SIGNER_UUID="${SIGNER_UUID//[$'\r\n']/}"
SIGNER_UUID="${SIGNER_UUID#"${SIGNER_UUID%%[![:space:]]*}"}"
SIGNER_UUID="${SIGNER_UUID%"${SIGNER_UUID##*[![:space:]]}"}"

if [[ -z "$API_KEY" ]] || [[ "$API_KEY" == "null" ]]; then
    echo "Error: apiKey not set. Set in config (apiKey) or env (NEYNAR_API_KEY)" >&2
    exit 1
fi

# API request helpers with proper error handling
api_get() {
    local endpoint="$1"
    local response
    if ! response=$(curl -sf -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
        "${API_BASE}${endpoint}" 2>&1); then
        echo "Error: API request failed for $endpoint" >&2
        return 1
    fi
    echo "$response"
}

# Use heredoc to avoid exposing data in process list
api_post() {
    local endpoint="$1"
    local data="$2"
    local tmp
    tmp=$(mktemp -t neynar-post.XXXXXX)
    trap 'rm -f "$tmp"' RETURN
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o "$tmp" -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
        --data-binary @- "${API_BASE}${endpoint}" <<< "$data")
    local response
    response=$(<"$tmp")
    if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
        echo "Error: API POST failed for $endpoint (HTTP $http_code)" >&2
        if [[ -n "$response" ]]; then
            echo "Response: $(echo "$response" | jq -c 'if type == "object" then (.message // .msg // .error // .) else . end' 2>/dev/null || echo "$response" | head -c 600)" >&2
        fi
        if [[ "$http_code" -eq 401 ]]; then
            local key_src="config"
            [[ -n "${NEYNAR_API_KEY:-}" ]] && key_src="env"
            echo "Tip: API key from $key_src, length=${#API_KEY}. Get a valid key at https://dev.neynar.com" >&2
        fi
        if [[ "$http_code" -eq 400 ]] && [[ "$endpoint" == "/cast" ]]; then
            echo "Tip: 400 Invalid body usually means signer_uuid is missing, wrong format (must be a UUID), or not approved. Create/approve a signer at https://dashboard.neynar.com and set signerUuid in config." >&2
        fi
        return 1
    fi
    echo "$response"
}

# Commands
cmd_user() {
    if [[ $# -eq 0 ]]; then
        echo "Error: user requires a username or FID" >&2
        exit 1
    fi
    
    local identifier="$1"
    local by_fid=false
    
    if [[ "${2:-}" == "--fid" ]] || [[ "$identifier" =~ ^[0-9]+$ ]]; then
        by_fid=true
    fi
    
    if $by_fid; then
        api_get "/user/bulk?fids=$identifier" | jq '.users[0] | {
            fid,
            username,
            display_name,
            pfp_url,
            bio: .profile.bio.text,
            follower_count,
            following_count,
            verified_addresses: .verified_addresses.eth_addresses
        }'
    else
        api_get "/user/by_username?username=$identifier" | jq '.user | {
            fid,
            username,
            display_name,
            pfp_url,
            bio: .profile.bio.text,
            follower_count,
            following_count,
            verified_addresses: .verified_addresses.eth_addresses
        }'
    fi
}

cmd_users() {
    if [[ $# -eq 0 ]]; then
        echo "Error: users requires comma-separated usernames" >&2
        exit 1
    fi
    
    local usernames="$1"
    # Convert comma-separated to API format
    api_get "/user/bulk-by-username?usernames=$usernames" | jq '.users[] | {
        fid,
        username,
        display_name,
        follower_count
    }'
}

cmd_feed() {
    local feed_type="user"
    local identifier=""
    local limit=10
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user) feed_type="user"; identifier="$2"; shift 2 ;;
            --channel) feed_type="channel"; identifier="$2"; shift 2 ;;
            --trending) feed_type="trending"; shift ;;
            --following) feed_type="following"; shift ;;
            --limit) limit="$2"; shift 2 ;;
            *) identifier="$1"; shift ;;
        esac
    done
    
    case "$feed_type" in
        user)
            if [[ -n "$identifier" ]]; then
                api_get "/feed/user/casts?fid=$identifier&limit=$limit" | jq '.casts[] | {
                    hash,
                    text,
                    timestamp,
                    reactions: {likes: .reactions.likes_count, recasts: .reactions.recasts_count},
                    replies_count
                }'
            else
                echo "Error: --user requires a username or FID" >&2
                exit 1
            fi
            ;;
        channel)
            api_get "/feed/channels?channel_ids=$identifier&limit=$limit" | jq '.casts[] | {
                hash,
                author: .author.username,
                text,
                timestamp,
                reactions: {likes: .reactions.likes_count, recasts: .reactions.recasts_count}
            }'
            ;;
        trending)
            api_get "/feed/trending?limit=$limit" | jq '.casts[] | {
                hash,
                author: .author.username,
                text,
                timestamp,
                reactions: {likes: .reactions.likes_count, recasts: .reactions.recasts_count}
            }'
            ;;
        following)
            if [[ -z "$SIGNER_UUID" ]]; then
                echo "Error: Following feed requires signerUuid in config" >&2
                exit 1
            fi
            api_get "/feed/following?fid=me&limit=$limit" | jq '.casts[] | {
                hash,
                author: .author.username,
                text,
                timestamp
            }'
            ;;
    esac
}

cmd_search() {
    if [[ $# -eq 0 ]]; then
        echo "Error: search requires a query" >&2
        exit 1
    fi
    
    local query="$1"
    local channel=""
    local limit=10
    
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --channel) channel="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    
    local endpoint="/cast/search?q=$(echo "$query" | jq -Rr @uri)&limit=$limit"
    if [[ -n "$channel" ]]; then
        endpoint="${endpoint}&channel_id=$channel"
    fi
    
    api_get "$endpoint" | jq '.result.casts[] | {
        hash,
        author: .author.username,
        text,
        timestamp,
        channel: .channel.id
    }'
}

cmd_search_users() {
    if [[ $# -eq 0 ]]; then
        echo "Error: search-users requires a query" >&2
        exit 1
    fi
    
    local query="$1"
    api_get "/user/search?q=$(echo "$query" | jq -Rr @uri)&limit=10" | jq '.result.users[] | {
        fid,
        username,
        display_name,
        follower_count
    }'
}

cmd_cast() {
    if [[ $# -eq 0 ]]; then
        echo "Error: cast requires a hash or URL" >&2
        exit 1
    fi
    
    local identifier="$1"
    
    # Check if it's a URL or hash
    if [[ "$identifier" == http* ]]; then
        api_get "/cast?type=url&identifier=$(echo "$identifier" | jq -Rr @uri)" | jq '.cast | {
            hash,
            author: .author.username,
            text,
            timestamp,
            reactions: {likes: .reactions.likes_count, recasts: .reactions.recasts_count},
            replies_count,
            embeds
        }'
    else
        api_get "/cast?type=hash&identifier=$identifier" | jq '.cast | {
            hash,
            author: .author.username,
            text,
            timestamp,
            reactions: {likes: .reactions.likes_count, recasts: .reactions.recasts_count},
            replies_count,
            embeds
        }'
    fi
}

cmd_post() {
    if [[ -z "$SIGNER_UUID" ]]; then
        echo "Error: Posting requires signerUuid in config" >&2
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Error: post requires text" >&2
        exit 1
    fi
    
    local text="$1"
    local reply_to=""
    local channel=""
    local embed=""
    
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --reply-to) reply_to="$2"; shift 2 ;;
            --channel) channel="$2"; shift 2 ;;
            --embed) embed="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    
    # Build JSON safely with jq to prevent injection
    local data
    data=$(jq -n \
        --arg signer "$SIGNER_UUID" \
        --arg text "$text" \
        --arg reply_to "$reply_to" \
        --arg channel "$channel" \
        --arg embed "$embed" \
        '{signer_uuid: $signer, text: $text} +
        (if $reply_to != "" then {parent: $reply_to} else {} end) +
        (if $channel != "" then {channel_id: $channel} else {} end) +
        (if $embed != "" then {embeds: [{url: $embed}]} else {} end)')
    
    api_post "/cast" "$data" | jq '{
        success: .success,
        hash: .cast.hash,
        text: .cast.text
    }'
}

cmd_like() {
    if [[ -z "$SIGNER_UUID" ]]; then
        echo "Error: Liking requires signerUuid in config" >&2
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Error: like requires a cast hash" >&2
        exit 1
    fi
    
    local cast_hash="$1"
    
    # Build JSON safely with jq
    local data
    data=$(jq -n \
        --arg signer "$SIGNER_UUID" \
        --arg target "$cast_hash" \
        '{signer_uuid: $signer, reaction_type: "like", target: $target}')
    
    api_post "/reaction" "$data" | jq '{
        success: .success,
        reaction_type: .reaction.reaction_type
    }'
}

cmd_recast() {
    if [[ -z "$SIGNER_UUID" ]]; then
        echo "Error: Recasting requires signerUuid in config" >&2
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Error: recast requires a cast hash" >&2
        exit 1
    fi
    
    local cast_hash="$1"
    
    # Build JSON safely with jq
    local data
    data=$(jq -n \
        --arg signer "$SIGNER_UUID" \
        --arg target "$cast_hash" \
        '{signer_uuid: $signer, reaction_type: "recast", target: $target}')
    
    api_post "/reaction" "$data" | jq '{
        success: .success,
        reaction_type: .reaction.reaction_type
    }'
}

cmd_follow() {
    if [[ -z "$SIGNER_UUID" ]]; then
        echo "Error: Following requires signerUuid in config" >&2
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Error: follow requires a username" >&2
        exit 1
    fi
    
    local username="$1"
    
    # First get FID with error handling
    local user_response
    if ! user_response=$(api_get "/user/by_username?username=$username"); then
        echo "Error: Failed to look up user $username" >&2
        exit 1
    fi
    
    local fid
    fid=$(echo "$user_response" | jq -r '.user.fid')
    
    if [[ -z "$fid" || "$fid" == "null" ]]; then
        echo "Error: Could not find FID for user $username" >&2
        exit 1
    fi
    
    # Build JSON safely with jq
    local data
    data=$(jq -n \
        --arg signer "$SIGNER_UUID" \
        --argjson fid "$fid" \
        '{signer_uuid: $signer, target_fids: [$fid]}')
    
    api_post "/user/follow" "$data" | jq '{
        success: .success,
        followed: .target_fids
    }'
}

cmd_unfollow() {
    if [[ -z "$SIGNER_UUID" ]]; then
        echo "Error: Unfollowing requires signerUuid in config" >&2
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Error: unfollow requires a username" >&2
        exit 1
    fi
    
    local username="$1"
    
    # First get FID with error handling
    local user_response
    if ! user_response=$(api_get "/user/by_username?username=$username"); then
        echo "Error: Failed to look up user $username" >&2
        exit 1
    fi
    
    local fid
    fid=$(echo "$user_response" | jq -r '.user.fid')
    
    if [[ -z "$fid" || "$fid" == "null" ]]; then
        echo "Error: Could not find FID for user $username" >&2
        exit 1
    fi
    
    # Build JSON safely with jq
    local data
    data=$(jq -n \
        --arg signer "$SIGNER_UUID" \
        --argjson fid "$fid" \
        '{signer_uuid: $signer, target_fids: [$fid], unfollow: true}')
    
    api_post "/user/follow" "$data" | jq '{
        success: .success,
        unfollowed: .target_fids
    }'
}

cmd_help() {
    cat << 'EOF'
Neynar Farcaster API CLI

Usage: neynar.sh <command> [args]

Commands:
  user <username|fid>           Look up a user
  users <user1,user2,...>       Look up multiple users
  feed [options]                Get feed
    --user <username>           User's casts
    --channel <id>              Channel feed
    --trending                  Trending casts
    --following                 Following feed (requires signer)
    --limit <n>                 Number of results
  search <query>                Search casts
    --channel <id>              Filter by channel
  search-users <query>          Search users
  cast <hash|url>               Get cast details
  post <text>                   Post a cast (requires signer)
    --reply-to <hash>           Reply to cast
    --channel <id>              Post in channel
    --embed <url>               Embed a URL
  like <hash>                   Like a cast (requires signer)
  recast <hash>                 Recast (requires signer)
  follow <username>             Follow user (requires signer)
  unfollow <username>           Unfollow user (requires signer)

Examples:
  neynar.sh user dwr.eth
  neynar.sh feed --channel base --limit 5
  neynar.sh search "ethereum" --channel ethereum
  neynar.sh post "gm farcaster"
EOF
}

# Main dispatch
case "${1:-help}" in
    user) shift; cmd_user "$@" ;;
    users) shift; cmd_users "$@" ;;
    feed) shift; cmd_feed "$@" ;;
    search) shift; cmd_search "$@" ;;
    search-users) shift; cmd_search_users "$@" ;;
    cast) shift; cmd_cast "$@" ;;
    post) shift; cmd_post "$@" ;;
    like) shift; cmd_like "$@" ;;
    recast) shift; cmd_recast "$@" ;;
    follow) shift; cmd_follow "$@" ;;
    unfollow) shift; cmd_unfollow "$@" ;;
    help|--help|-h) cmd_help ;;
    *) echo "Unknown command: $1" >&2; cmd_help; exit 1 ;;
esac
