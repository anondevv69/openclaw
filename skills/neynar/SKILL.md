---
name: neynar
description: Interact with Farcaster via Neynar API. Use when the user wants to read Farcaster feeds, look up users, post casts, search content, trending tokens (fungibles) or token trades on Base, or interact with the Farcaster social protocol. Requires NEYNAR_API_KEY.
metadata: {"clawdbot":{"emoji":"🟪","homepage":"https://neynar.com","requires":{"bins":["curl","jq"]}}}
---

# Neynar (Farcaster API)

Interact with the Farcaster decentralized social protocol via Neynar's API.

## Quick Start

### Setup

1. Get an API key from [dev.neynar.com](https://dev.neynar.com)
2. Create config in the skill dir (workspace) or home:

**Option A — workspace** (e.g. `skills/neynar/config.json` in your Moltbot repo):

Use **exactly** these two keys (no spaces in key names, no "farcaster signer UUID" or "farcaster FID" — the script does not read those):

```json
{
  "apiKey": "YOUR_NEYNAR_API_KEY",
  "signerUuid": "YOUR_SIGNER_UUID"
}
```

**Option A2 — env file** (optional): Copy `skills/neynar/.env.example` to `skills/neynar/.env`, fill in your values. The script loads `.env` if present; these override config.json.

**Option B — home**:

```bash
mkdir -p ~/.moltbot/skills/neynar
cat > ~/.moltbot/skills/neynar/config.json << 'EOF'
{"apiKey": "YOUR_NEYNAR_API_KEY", "signerUuid": "YOUR_SIGNER_UUID"}
EOF
```

The script looks for config in: `skills/neynar/config.json` (workspace) → `~/.clawdbot/skills/neynar/config.json` → `~/.moltbot/skills/neynar/config.json`.

You can override the API key with the **`NEYNAR_API_KEY`** environment variable (useful if config is not writable or you prefer env-based secrets).

**Note**: `signerUuid` is only required for posting casts. Get one via Neynar's signer management.

**Agent posting casts:** The agent must use **exec** with **workdir** = the **full path** to the `skills/neynar` directory (i.e. `<workspace>/skills/neynar`). The script resolves config relative to its own directory. If the agent's **workspace** is the default (`~/clawd`), then `skills/neynar` is `~/clawd/skills/neynar` — and config in the Moltbot repo will not be found. Set the agent workspace to the repo that contains `skills/neynar/config.json`: from the repo root run `./scripts/set-workspace-to-repo.sh`, then restart the gateway and start a new chat.

### Verify Setup

```bash
scripts/neynar.sh user dwr.eth
```

## Core Concepts

- **FID** — Farcaster ID, a permanent numeric identifier for each user
- **Cast** — A post on Farcaster (like a tweet)
- **Channel** — Topic-based feeds (like subreddits)
- **Frame** — Interactive mini-apps embedded in casts

## Usage

### User Lookup

```bash
# By username
scripts/neynar.sh user vitalik.eth

# By FID
scripts/neynar.sh user --fid 5650

# Multiple users
scripts/neynar.sh users dwr.eth,v,jessepollak
```

### Read Feed

```bash
# User's casts
scripts/neynar.sh feed --user dwr.eth

# Channel feed
scripts/neynar.sh feed --channel base

# Trending feed
scripts/neynar.sh feed --trending

# Following feed (requires signer)
scripts/neynar.sh feed --following
```

**Trending feed API:** `GET /v2/farcaster/feed/trending/` — optional params: `limit` (1–10), `cursor`, `viewer_fid`, `time_window` (1h, 6h, 12h, 24h, 7d; 7d for channel feeds only), `channel_id` or `parent_url` to filter by channel. Response: `{ casts, next: { cursor } }`. See [references/feed-apis.md](references/feed-apis.md) and https://docs.neynar.com/llms.txt for full docs.

### Search

```bash
# Search casts
scripts/neynar.sh search "ethereum"

# Search users
scripts/neynar.sh search-users "vitalik"

# Search in channel
scripts/neynar.sh search "onchain summer" --channel base
```

### Get Cast

```bash
# By hash
scripts/neynar.sh cast 0x1234abcd...

# By URL
scripts/neynar.sh cast "https://warpcast.com/dwr.eth/0x1234"
```

### Post Cast (requires signer)

```bash
# Simple cast
scripts/neynar.sh post "gm farcaster"

# Reply to cast
scripts/neynar.sh post "great point!" --reply-to 0x1234abcd

# Cast in channel
scripts/neynar.sh post "hello base" --channel base

# Cast with embed
scripts/neynar.sh post "check this out" --embed "https://example.com"
```

### Reactions

```bash
# Like a cast
scripts/neynar.sh like 0x1234abcd

# Recast
scripts/neynar.sh recast 0x1234abcd
```

### Follow/Unfollow

```bash
scripts/neynar.sh follow dwr.eth
scripts/neynar.sh unfollow dwr.eth
```

### Onchain (trending fungibles, fungible trades)

When the user asks for **trending tokens** (fungibles) on Base or **recent trades** for a token, call the Neynar onchain APIs (e.g. with **web_fetch**):

- **Trending fungibles:** `GET /v2/farcaster/fungible/trending/?network=base&time_window=24h` — fungibles ranked by buy volume/count from watched addresses.
- **Fungible trades:** `GET /v2/farcaster/fungible/trades/?network=base&address=<contract>&time_window=24h` — recent trades for a token (optional: `min_amount_usd`).

See [references/onchain-apis.md](references/onchain-apis.md) for parameters and examples.

## API Reference

**Full docs index for LLMs:** Fetch **https://docs.neynar.com/llms.txt** to discover all available Neynar API pages. See [references/feed-apis.md](references/feed-apis.md) for trending feed; [references/onchain-apis.md](references/onchain-apis.md) for trending fungibles and fungible trades.

### Endpoints Used

| Action | Endpoint | Auth |
|--------|----------|------|
| User lookup | `GET /v2/farcaster/user/by_username` | API key |
| User by FID | `GET /v2/farcaster/user/bulk` | API key |
| User feed | `GET /v2/farcaster/feed/user/casts` | API key |
| Channel feed | `GET /v2/farcaster/feed/channels` | API key |
| **Trending feed** | `GET /v2/farcaster/feed/trending/` | API key — params: `limit` (1–10), `cursor`, `viewer_fid`, `time_window` (1h, 6h, 12h, 24h, 7d), `channel_id` or `parent_url`, `provider` |
| **Trending fungibles** | `GET /v2/farcaster/fungible/trending/` | API key — params: `network` (required, e.g. base), `time_window` (1h, 6h, 12h, 24h, 7d). Returns fungibles ranked by buy volume/count. |
| **Fungible trades** | `GET /v2/farcaster/fungible/trades/` | API key — params: `network` (required), `address` (contract), `time_window` (1h–7d), `min_amount_usd` (optional). Recent trades for a token. |
| Search casts | `GET /v2/farcaster/cast/search` | API key |
| Get cast | `GET /v2/farcaster/cast` | API key |
| Post cast | `POST /v2/farcaster/cast` | API key + Signer |
| React | `POST /v2/farcaster/reaction` | API key + Signer |
| Follow | `POST /v2/farcaster/user/follow` | API key + Signer |

### Response Format

All responses are JSON. The script extracts key fields for readability:

```json
{
  "user": {
    "fid": 3,
    "username": "dwr.eth",
    "display_name": "Dan Romero",
    "follower_count": 450000,
    "following_count": 2800,
    "verified_addresses": ["0x..."]
  }
}
```

## Common Patterns

### Monitor a Channel

```bash
# Get latest casts from /base channel
scripts/neynar.sh feed --channel base --limit 20
```

### Find Active Users

```bash
# Search for users by keyword
scripts/neynar.sh search-users "ethereum developer"
```

### Cross-Post from Twitter

```bash
# Post same content to Farcaster
scripts/neynar.sh post "gm, just shipped a new feature 🚀"
```

### Reply to Mentions

```bash
# Get notifications via API (see Troubleshooting section for full command)
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/notifications?fid=YOUR_FID&type=mentions&limit=10"

# Reply to specific cast
scripts/neynar.sh post "thanks!" --reply-to 0xabc123
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Invalid or missing API key | Use the **raw** key from [dev.neynar.com](https://dev.neynar.com) in `config.json` as `"apiKey": "your-key"` (no prefix like `NEYNAR_API_KEY=`). Or set env `NEYNAR_API_KEY=your-key`. |
| 403 Forbidden | Signer required | Set up signer for write operations |
| 404 Not Found | User/cast doesn't exist | Verify username/hash |
| 429 Rate Limited | Too many requests | Wait and retry |

## Signer Setup (Moltbot in charge of your Farcaster account)

For write operations (posting, liking, following), you need a **signer** linked to your Farcaster account:

1. Have a Farcaster account (e.g. [Warpcast](https://warpcast.com)).
2. Create a **managed signer** in Neynar: [dashboard.neynar.com](https://dashboard.neynar.com) or [Create Signer API](https://docs.neynar.com/reference/create-signer). Open the approval URL and approve with your Farcaster account.
3. Copy the **signer UUID** and add it to config: `signerUuid` in `skills/neynar/config.json` (or `~/.moltbot/skills/neynar/config.json`).
4. Restart the gateway and start a new chat; then you can ask Moltbot to “post to Farcaster” or “cast in the base channel.”

**Managed signers** are easiest — Neynar handles the key custody. See [references/signer-setup.md](references/signer-setup.md) for step-by-step.

## Rate Limits

- Free tier: 300 requests/minute
- Paid tiers: Higher limits available
- Check `X-RateLimit-Remaining` header

## Best Practices

1. **Cache user lookups** — FIDs don't change, usernames rarely do
2. **Use channels** — Better reach than random posting
3. **Engage genuinely** — Farcaster culture values authenticity
4. **Batch requests** — Use bulk endpoints when possible
5. **Handle rate limits** — Implement backoff

## Resources

- **Docs index (LLMs)**: https://docs.neynar.com/llms.txt — discover all available API pages
- **Neynar Docs**: https://docs.neynar.com
- **API Reference**: https://docs.neynar.com/reference
- **Trending feed (OpenAPI)**: https://docs.neynar.com/reference/fetch-trending-feed — params, schemas, Node SDK `fetchTrendingFeed`
- **Feed APIs reference**: [references/feed-apis.md](references/feed-apis.md) — trending feed params, time_window, channel_id/parent_url, examples
- **Onchain APIs reference**: [references/onchain-apis.md](references/onchain-apis.md) — trending fungibles (`/v2/farcaster/fungible/trending/`), fungible trades (`/v2/farcaster/fungible/trades/`)
- **Developer Portal**: https://dev.neynar.com
- **Farcaster Docs**: https://docs.farcaster.xyz

## Troubleshooting

### Config not found / agent says "Neynar tool not set up"

The agent runs `neynar.sh` with **workdir** = `<workspace>/skills/neynar`. The **workspace** is the agent's working directory (from config). If it is the **default** (`~/clawd`), then the agent looks for config in `~/clawd/skills/neynar/config.json` — but your config is in the **Moltbot repo** (e.g. `moltbot/skills/neynar/config.json`). So the script exits with "Config not found" and the agent reports Neynar as not set up.

**Fix:** Set the agent workspace to the repo that contains `skills/neynar/config.json`. From the Moltbot repo root run:
```bash
./scripts/set-workspace-to-repo.sh
```
Then restart the gateway and start a **new chat**. After that, the agent's workspace is the repo and `skills/neynar` resolves to the correct folder.

### API Key Not Working (401 "Incorrect or missing API key")

- **Config**: In `skills/neynar/config.json` use the exact key from [dev.neynar.com](https://dev.neynar.com): `"apiKey": "your-key-here"` with no extra prefix or quotes inside the value.
- **Env override**: You can set `NEYNAR_API_KEY` in your environment (e.g. in the shell before running the gateway); the script uses it if set.
- **Verify**:
  ```bash
  curl -s -H "x-api-key: YOUR_KEY" "https://api.neynar.com/v2/farcaster/user/bulk?fids=1" | jq .
  ```
  If the key is valid you get user data; if not you get an error body.

### Signer Issues

- Ensure signer is approved and active
- Check signer permissions match your FID
- Managed signers are simpler than self-hosted

### Signer Not Found (but posting works)

The Neynar signer lookup endpoint (`GET /v2/farcaster/signer?signer_uuid=...`) may return "Signer not found" even when the signer is valid. This can happen with signers created via different methods or recently approved signers.

**Test by posting directly:**
```bash
./scripts/neynar.sh post "test"
```

If posting works, the signer is valid — ignore the lookup error.

### Wrong Account Posting

If casts appear from the wrong Farcaster account, your signer is linked to a different FID:

1. **Each signer = one account** — A signer UUID is permanently linked to the FID that approved it
2. **Create new signer** — If you changed accounts, create a fresh signer via Neynar dashboard and approve it with the correct Farcaster account
3. **Update config** — Replace `signerUuid` in `config.json` with the new UUID

**Find your FID:**
```bash
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/user/search?q=yourusername" | jq '.result.users[0].fid'
```

### Checking Notifications (API)

The CLI doesn't have a `notifications` command yet. Use the API directly:

```bash
# Get notifications for your FID
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/notifications?fid=YOUR_FID&limit=20" | jq '.notifications[] | {type, text: .cast.text?, author: .cast.author.username?}'

# Filter by type (mentions only)
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/notifications?fid=YOUR_FID&type=mentions&limit=20"
```

### Cast Not Appearing

- Casts propagate in seconds, but indexing may take longer
- Check the cast hash in the response
- Verify on warpcast.com directly
