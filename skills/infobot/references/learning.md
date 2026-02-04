# Learning the InfoBot skill

This doc helps you learn the InfoBot skill: what it is, where it comes from, and how to use it in Moltbot.

## How to install

### 1. Use the InfoBot skill in Moltbot (no install)

The InfoBot skill is **already in your Moltbot repo** at `skills/infobot/`. There is no separate install step.

- The agent loads skills from the workspace; as long as your gateway uses this repo as the workspace, the InfoBot skill is available.
- **Optional:** Create `skills/infobot/config.json` if you want a custom API base URL or API keys (see [Setup in SKILL.md](../SKILL.md#setup)).

```bash
# Optional: create config (e.g. custom base URL or keys)
mkdir -p skills/infobot
cat > skills/infobot/config.json << 'EOF'
{
  "apiBaseUrl": "https://infobot-production-f74e.up.railway.app",
  "apiKey": "",
  "neynarApiKey": "",
  "zoraApiKey": ""
}
EOF
```

Restart the gateway and start a new chat so the agent sees the skill; then ask e.g. “Search Farcaster for dwr.eth” or “Zora profile for zora”.

### 2. Optional: sync from the infobot-skill repo

If you want to pull the latest skill definition (SKILL.md, etc.) from upstream:

```bash
git clone https://github.com/anondevv69/infobot-skill.git /tmp/infobot-skill
# Copy skill content (moltbot keeps references/ and config in this repo)
cp /tmp/infobot-skill/infobot/SKILL.md skills/infobot/SKILL.md
# Optionally copy infobot README for install notes:
# cp /tmp/infobot-skill/infobot/README.md skills/infobot/references/upstream-readme.md
```

Then restart the gateway. Upstream repo: [github.com/anondevv69/infobot-skill](https://github.com/anondevv69/infobot-skill).

### 3. Optional: self-host InfoBot (bot + Public API)

To run your own InfoBot server (Discord/Telegram bot + Public API):

1. Clone the main repo: `git clone https://github.com/anondevv69/infobot.git`
2. Follow its README (install deps, set env vars such as `NEYNAR_API_KEY`, `ZORA_API_KEY`, Discord/Telegram tokens, etc.).
3. Run the server (e.g. `npm run start` or whatever the repo documents).
4. In Moltbot set `apiBaseUrl` in `skills/infobot/config.json` to your server URL (e.g. `http://localhost:3000` or your deployed URL).

Moltbot’s agent will then call your instance via **web_fetch** instead of the public Railway instance.

---

## What is the infobot-skill?

The **infobot-skill** is the upstream source for Moltbot’s InfoBot skill:

- **Repo:** [github.com/anondevv69/infobot-skill](https://github.com/anondevv69/infobot-skill)
- **Main InfoBot (bot + API):** [github.com/anondevv69/infobot](https://github.com/anondevv69/infobot)

The *skill* repo defines how an AI agent (e.g. Moltbot) should use InfoBot: when to call it, which API endpoints to use, and how to interpret responses. The *infobot* repo is the actual Discord/Telegram bot and Public API server.

## What InfoBot does

InfoBot is a **unified lookup** service for:

| Domain | What you can look up |
|--------|------------------------|
| **Farcaster** | User by username or wallet, casts by keyword, cast by Warpcast/farcaster.xyz URL |
| **Zora** | Creator profile, creator coin, Zora collect/coin URLs |
| **Clanker** | Token deployments, clanker.world links |
| **Wallets** | Ethereum or Solana address (balances, tokens, links) |
| **Relay** | Cross-chain transaction (Relay.link) |
| **X/Twitter** | Farcaster profile by X handle or Twitter URL |

So instead of the agent calling Neynar, Zora, and Clanker APIs separately, it can call **one** InfoBot API and get the right type of lookup based on the path and query.

## How Moltbot uses it

1. **Skill** — The agent is instructed (via `skills/infobot/SKILL.md`) to use InfoBot when the user asks for Farcaster/Zora/Clanker/wallet/Relay/X lookups.
2. **Tool** — The agent calls the **web_fetch** tool with the InfoBot Public API URL (from config or default).
3. **Config** — `skills/infobot/config.json` can set:
   - `apiBaseUrl` — InfoBot API root (e.g. `https://infobot-production-f74e.up.railway.app`)
   - `apiKey` — If the server requires auth
   - `neynarApiKey` / `zoraApiKey` — Optional; your own keys sent as headers so the host uses them instead of its own

No script is run; the agent uses **web_fetch** only.

## Public API (what to learn)

Base URL example: `https://infobot-production-f74e.up.railway.app` (no trailing slash).

| Use case | Method | Path | Query |
|----------|--------|------|-------|
| Universal search | GET | `/api/v1/search` | `q=<query>` |
| Farcaster user | GET | `/api/v1/far` | `q=<username-or-address>` |
| Wallet + Farcaster + Clanker | GET | `/api/v1/wallet` | `address=<0x...>` |
| Cast search | GET | `/api/v1/casts` | `keyword=<keyword>&limit=5` |
| Zora profile | GET | `/api/v1/zora` | `q=<handle>` |
| Clanker tokens | GET | `/api/v1/clanker` | `q=<query>` |
| Health check | GET | `/api/v1/ping` | — returns `{ "ok": true }` |
| Server health | GET | `/healthz` | — status, uptime |

**Response:** `{ "ok": true, "type": "...", "data": ... }` or `{ "ok": false, "error": "..." }`. The agent returns `data` (or the error) to the user. For `/far`, `data` is `null` when no user is found.

**Optional auth:** `x-api-key: <key>` or `?api_key=<key>`. Optional override keys: `x-neynar-api-key`, `x-zora-api-key` (or query params). **Own API = no charge:** If the caller sends both Neynar and Zora keys, they do not pay; otherwise they use the host's keys and may pay (prepaid or x402).

**x402 (pay per request):** If the host enables [x402](https://www.x402.org), the API may return 402 Payment Required; use an x402-capable client (e.g. [x402-fetch](https://www.npmjs.com/package/x402-fetch)) to pay on-chain. Billing applies only to the public API; the Discord/Telegram bot are not affected.

## Try it yourself

```bash
# Universal search
curl -s "https://infobot-production-f74e.up.railway.app/api/v1/search?q=dwr.eth" | jq .

# Farcaster user
curl -s "https://infobot-production-f74e.up.railway.app/api/v1/far?q=dwr.eth" | jq .

# Zora profile
curl -s "https://infobot-production-f74e.up.railway.app/api/v1/zora?q=zora" | jq .
```

If the public instance is down or you self-host InfoBot, set `apiBaseUrl` in `skills/infobot/config.json` to your server.

## Learning from the upstream repo

To go deeper:

1. **Clone the skill repo:**
   ```bash
   git clone https://github.com/anondevv69/infobot-skill.git
   ```
   Look at `infobot/SKILL.md` (when to use, endpoints, ping/healthz, x402, multi-step) and `infobot/README.md` (install, Moltbot skill setup).

2. **Clone the main InfoBot repo** (bot + API):
   ```bash
   git clone https://github.com/anondevv69/infobot.git
   ```
   Read the README and API routes to see how `/api/v1/*` is implemented and what Neynar/Zora/Clanker it uses.

3. **Compare with Moltbot’s skill** — Our `skills/infobot/SKILL.md` and `references/api.md` are derived from that upstream skill; we keep the same endpoints and config shape so the agent behavior stays aligned.

## Summary

- **infobot-skill** = upstream skill definition ([github.com/anondevv69/infobot-skill](https://github.com/anondevv69/infobot-skill)): when to use InfoBot, which endpoints (including `/api/v1/ping`, `/healthz`), x402, own-keys billing, multi-step for clanks/Zora.
- **InfoBot** = Discord/Telegram bot + Public API (unified Farcaster/Zora/Clanker/wallet/Relay/X lookups).
- **Moltbot** = uses the skill + **web_fetch** to call the Public API; config in `skills/infobot/config.json`.
- **Billing** (prepaid or x402) applies only to the public API; the Discord/Telegram bot are not affected.

Learning the skill means: knowing when to use InfoBot vs calling Neynar/Zora directly, knowing the API paths and query params, and how to set `apiBaseUrl` and optional keys in config.
