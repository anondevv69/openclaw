# Neynar Onchain APIs (LLM reference)

**Documentation index:** Fetch the complete documentation index at: **https://docs.neynar.com/llms.txt** — use this file to discover all available Neynar API pages.

---

## Trending fungibles

Fetch trending fungibles based on buy activity from watched addresses. Returns fungibles ranked by USD buy volume and buy count within the specified time window.

- **API:** `GET https://api.neynar.com/v2/farcaster/fungible/trending/`
- **Auth:** `x-api-key: YOUR_NEYNAR_API_KEY`
- **Node.js SDK:** [fetchTrendingFungibles](https://docs.neynar.com/nodejs-sdk/onchain-apis/fetchTrendingFungibles)

### Query parameters

| Parameter     | Type   | Required | Default | Description |
|---------------|--------|----------|---------|-------------|
| `network`     | string | Yes      | —       | Network; currently `base` only. |
| `time_window` | string | No       | 24h     | Time window: `1h`, `6h`, `12h`, `24h`, `7d`. |

### Example

```bash
curl -s -H "x-api-key: $NEYNAR_API_KEY" \
  "https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=24h"
```

### Response (200)

- `{ "trending": [ { "object": "trending_fungible", "fungible": { "object": "fungible", "network", "name", "symbol", "address", "decimals", "total_supply", "logo", "price": { "in_usd" } } } ] }`

---

## Get fungible trades

Get recent trades for a specific fungible within a timeframe. Returns trades ordered by timestamp (most recent first).

- **API:** `GET https://api.neynar.com/v2/farcaster/fungible/trades/`
- **Auth:** `x-api-key: YOUR_NEYNAR_API_KEY`
- **Node.js SDK:** [fetchFungibleTrades](https://docs.neynar.com/nodejs-sdk/onchain-apis/fetchFungibleTrades)

### Query parameters

| Parameter       | Type   | Required | Default | Description |
|-----------------|--------|----------|---------|-------------|
| `network`       | string | Yes      | —       | Network; currently `base` only. |
| `address`       | string | Yes      | —       | Contract address of the fungible. |
| `time_window`   | string | No       | 24h     | Time window: `1h`, `6h`, `12h`, `24h`, `7d`. |
| `min_amount_usd`| number | No       | —       | Minimum USD amount to filter trades. |

### Example

```bash
curl -s -H "x-api-key: $NEYNAR_API_KEY" \
  "https://api.neynar.com/v2/farcaster/fungible/trades/?network=base&address=0x...&time_window=24h"
```

### Response (200)

- `{ "object": "fungible_trades", "trades": [ { "object": "trade", "trader" (UserDehydrated), "pool": { "object", "address", "protocol_family", "protocol_version" }, "transaction": { "hash", "network", "net_transfer": { "receiving_fungible", "sending_fungible" (FungibleBalance with token + balance.in_usd, balance.in_token) } } } ] }`

---

## Troubleshooting (404 / 401)

1. **Base URL** — Use **https://api.neynar.com** only. Do not use InfoBot's URL (`infobot-production-f74e.up.railway.app`); Neynar endpoints are not on InfoBot and will 404 there.

2. **Test from terminal** — From the repo root, with your key in `skills/neynar/config.json`:
   ```bash
   NEYNAR_KEY="$(jq -r .apiKey skills/neynar/config.json)"
   curl -s -H "x-api-key: $NEYNAR_KEY" \
     "https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=1h"
   ```
   If you get JSON with `trending`, the API and key work. If you get 401, the key is wrong or the header name must be `x-api-key`. If you get 404, the URL is wrong (check base URL and path).

3. **web_fetch** — For Neynar, use **method GET** and **headers** `{ "x-api-key": "<key from skills/neynar/config.json>" }`. Restart the gateway and start a new chat so the agent uses the web_fetch that supports custom headers.

## Links

- **Trending fungibles (OpenAPI):** https://docs.neynar.com/reference/fetch-trending-fungibles
- **Fungible trades (OpenAPI):** https://docs.neynar.com/reference/fetch-fungible-trades
