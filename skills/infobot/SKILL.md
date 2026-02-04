---
name: infobot
description: Look up Farcaster, Zora, Clanker, wallet, and Relay data via InfoBot API. Use when the user wants a Farcaster profile (username or wallet), Zora creator/coin, Clanker token, wallet lookup (balances, tokens), cast search by keyword, Relay transaction, or Farcaster profile by X/Twitter handle. Call the Public API with web_fetch; optionally tell the user about the Discord/Telegram bot for interactive use.
metadata: {"moltbot":{"emoji":"🔍","homepage":"https://github.com/anondevv69/infobot","requires":{}}}
---

# InfoBot — Farcaster, Zora, Clanker & Wallet Lookups

InfoBot is a Discord and Telegram bot that also exposes a **Public API** for the same lookups. Use this skill when the user needs on-chain or Farcaster identity data; call the API with **web_fetch** and return the response.

## When to Use

Use InfoBot when the user asks for:

- **Farcaster**: profile by username or wallet, casts by keyword, cast details from a Warpcast/farcaster.xyz URL
- **Zora**: creator profile, creator coin, or Zora collect/coin URLs
- **Clanker**: token deployments or clanker.world links
- **Wallets**: Ethereum or Solana address lookup (balances, tokens, links)
- **Relay**: cross-chain transaction lookup (Relay.link)
- **X/Twitter → Farcaster**: Farcaster profile by X handle or Twitter URL

## How to Invoke (Public API)

Call the InfoBot API with the **web_fetch** tool. Base URL is set in config or use the public instance (see Setup).

**API base URL (example):** `https://infobot-production-f74e.up.railway.app`

**Endpoints:**

| Use case | Method | Path |
| -------- | ------ | ---- |
| Universal search | GET | `/api/v1/search?q=<query>` |
| Farcaster user | GET | `/api/v1/far?q=<username-or-address>` — use Farcaster **username** (e.g. `dwr`) or **0x address**; for "dwr.eth" use `q=dwr` (ENS may timeout) |
| Wallet + Farcaster + Clanker | GET | `/api/v1/wallet?address=<0x...>` |
| Cast search | GET | `/api/v1/casts?keyword=<keyword>&limit=5` |
| Zora profile | GET | `/api/v1/zora?q=<handle>` |
| Clanker tokens | GET | `/api/v1/clanker?q=<query>` |
| Health check | GET | `/api/v1/ping` — returns `{ "ok": true }` |
| Server health | GET | `/healthz` — status, uptime |

**Response:** `{ "ok": true, "type": "...", "data": ... }` or `{ "ok": false, "error": "..." }`. Return the `data` (or error) to the user. For `/far`, `data` is `null` when no user is found (e.g. wrong username).

**Tool response:** When calling the API (e.g. web_fetch), the response body (JSON) must be available to the agent. If the tool returns no body or "No output", the agent cannot use the results; use a tool that returns the response body.

**Farcaster username:** Use the Farcaster username (e.g. `dwr`), not a .eth name. If the user says "dwr.eth", try `q=dwr` as well—Neynar looks up by exact username.

**Auth (optional):** If the server requires an API key, send `x-api-key: <key>` (or `?api_key=<key>`). Keys can be set in `skills/infobot/config.json` (see Setup).

**Your own Neynar/Zora keys (optional):** To use your own keys instead of the host's, send per request: `x-neynar-api-key: <key>` and/or `x-zora-api-key: <key>` (or query params `neynar_api_key`, `zora_api_key`). Set in config and add to request headers when calling the API. **Own API = no charge:** If the caller sends both `x-neynar-api-key` and `x-zora-api-key` (their own keys), they do not pay. If they do not send their own keys, they use the host's keys and must pay (prepaid or x402).

**Pay per request (x402):** If the host enables [x402](https://www.x402.org) (on-chain payment), the API may return **402 Payment Required** with a **PAYMENT-REQUIRED** header. To pay per request on-chain (e.g. via [Bankr SDK](https://www.npmjs.com/package/@bankr/sdk)), the caller must use an x402-capable client (e.g. [x402-fetch](https://www.npmjs.com/package/x402-fetch)): wrap `fetch` with a wallet; on 402, the client signs payment in USDC and retries with **PAYMENT-SIGNATURE**. No API key needed—payment is per call on-chain. See the InfoBot API docs for an x402-fetch example.

**Showing a person's clanks, Zora, etc. (multi-step):** `/far` and `/search` return only the Farcaster profile (or one match). They do **not** include that person's Clanker tokens or Zora profile. To show **their Clanker tokens (clanks)** or **their Zora profile**:

1. **Clanks:** Get the person: `GET /api/v1/far?q=<username>` (e.g. `q=dwr`). From the response use `data.custody_address` or `data.verified_addresses.eth_addresses[0]`. Then get their clanks: `GET /api/v1/wallet?address=<that address>` (returns `{ address, farcaster, clanker }`) or `GET /api/v1/clanker?q=<that address>`.
2. **Zora profile:** Call `GET /api/v1/zora?q=<username>` (e.g. `q=dwr`). Returns the Zora creator profile (handle, coin, etc.). The API does not return a feed of "Zora posts"; use the bot in Discord/Telegram for richer Zora links if needed.
3. **Casts by keyword:** `GET /api/v1/casts?keyword=<keyword>&limit=5` searches casts by **keyword**, not "casts by this user". For a user's own casts, the user may need the bot or Warpcast.

When the user asks for "their clanks", "their Zora", "their tokens", or "everything for X", do step 1 then step 2 (far → wallet + zora) and combine the results.

## Install

The skill is **already included** in Moltbot at `skills/infobot/` — no install step. Ensure your gateway uses this repo as the workspace; the agent will see the skill. Optional: create config (see Setup below). For more (sync from upstream, self-host InfoBot), see [references/learning.md](references/learning.md#how-to-install).

## Setup

**Base URL:** Set `apiBaseUrl` in `skills/infobot/config.json` (or use the operator's public instance, e.g. `https://infobot-production-f74e.up.railway.app` if documented by the operator).

**Optional** `skills/infobot/config.json`:

```json
{
  "apiBaseUrl": "https://infobot-production-f74e.up.railway.app",
  "apiKey": "",
  "neynarApiKey": "",
  "zoraApiKey": ""
}
```

- `apiBaseUrl` — InfoBot API root (no trailing slash).
- `apiKey` — If the server sets `INFOBOT_API_KEY`, send as `x-api-key` or `?api_key=`.
- `neynarApiKey` / `zoraApiKey` — Optional; send as `x-neynar-api-key` / `x-zora-api-key` so the host's keys are not used.

Add `skills/infobot/config.json` to `.gitignore` if it contains keys.

## Discord / Telegram Bot (for the user)

If the user wants to use InfoBot interactively, they can use the bot in Discord or Telegram:

- **Universal**: `/search <query>`, `/info <query>`, or `info <query>`
- **Farcaster**: `/far <username|wallet>`, `/casts <keyword>`, `/cast <keyword>`, `/x <twitter-handle|url>`
- **Zora**: `/zora <query>`, `/z <query>`
- **Clanker**: `/clanker <query>`
- **Wallet**: `/w <address>`
- **Relay**: `/relay <transaction>`
- **Help**: `/help`

Pasting supported URLs (Warpcast, Zora, Clanker, Paragraph, Base social posts, etc.) in a channel where InfoBot is present can trigger automatic replies.

## Learning the skill

To learn how the InfoBot skill works (upstream repo, API concepts, and how to try it):

- **[references/learning.md](references/learning.md)** — What infobot-skill is, what InfoBot does, Public API summary, curl examples, and how to learn from the upstream repos.

## Reference

- [infobot-skill](https://github.com/anondevv69/infobot-skill) — Upstream skill source (when to use, endpoints, ping/healthz, x402, multi-step).
- [infobot repo](https://github.com/anondevv69/infobot) — Bot + Public API code and self-hosting.

**Billing:** Billing (prepaid or x402) applies only to the public API (`/api/v1/*`). The Discord and Telegram bot are not affected—no payment is required for using the bot in Discord or Telegram.
