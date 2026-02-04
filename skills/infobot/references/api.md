# InfoBot Public API

Learned from [infobot-skill](https://github.com/anondevv69/infobot-skill). The same lookups available in Discord/Telegram are exposed over HTTP.

## Base URL

Example: `https://infobot-production-f74e.up.railway.app` (Railway). Override with `apiBaseUrl` in `skills/infobot/config.json`.

## Endpoints

| Use case | Path | Query |
| -------- | ---- | ----- |
| Universal search | GET /api/v1/search | `q=<query>` |
| Farcaster user | GET /api/v1/far | `q=<username-or-address>` — use Farcaster **username** (e.g. `dwr`) or **0x address**; ENS like `dwr.eth` may not resolve and can timeout, so prefer username when known |
| Wallet + Farcaster + Clanker | GET /api/v1/wallet | `address=<0x...>` |
| Cast search | GET /api/v1/casts | `keyword=<keyword>&limit=5` |
| Zora profile | GET /api/v1/zora | `q=<handle>` |
| Clanker tokens | GET /api/v1/clanker | `q=<query>` |
| Health check | GET /api/v1/ping | — returns `{ "ok": true }` |
| Server health | GET /healthz | — status, uptime |

## Auth

- **Server API key:** If the server sets `INFOBOT_API_KEY`, send `x-api-key: <key>` or `?api_key=<key>`.
- **Your Neynar key:** `x-neynar-api-key: <key>` or `?neynar_api_key=...` so the host's key is not used.
- **Your Zora key:** `x-zora-api-key: <key>` or `?zora_api_key=...`.

**Own API = no charge:** If the caller sends both `x-neynar-api-key` and `x-zora-api-key` (their own keys), they do not pay. If they do not send their own keys, they use the host's keys and must pay (prepaid or x402).

**Pay per request (x402):** If the host enables [x402](https://www.x402.org), the API may return **402 Payment Required** with **PAYMENT-REQUIRED** header. Use an x402-capable client (e.g. [x402-fetch](https://www.npmjs.com/package/x402-fetch)): on 402, sign payment in USDC and retry with **PAYMENT-SIGNATURE**. See [Bankr SDK](https://www.npmjs.com/package/@bankr/sdk) and InfoBot API docs for examples.

## Response

- Success: `{ "ok": true, "type": "...", "data": ... }`
- Error: `{ "ok": false, "error": "..." }`
- For `/far`, `data` is `null` when no user is found (e.g. wrong username).

Return `data` to the user on success, or the error message on failure.
