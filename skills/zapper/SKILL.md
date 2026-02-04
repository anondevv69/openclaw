---
name: zapper
description: Fetch onchain portfolio, token balances, NFT balances, transaction history, token prices (current and historical), token rankings, and token activity feeds via the Zapper GraphQL API. Use when the user asks for wallet/portfolio data, token balances by address, token price or chart data, trending tokens, Farcaster user onchain data, or transaction timeline. Requires Zapper API key (x-zapper-api-key). Supports addresses and Farcaster (FID/username) resolution.
metadata: '{"moltbot":{"emoji":"📊","homepage":"https://zapper.xyz","requires":{}}}'
---

# Zapper — Onchain Portfolio, Prices & Activity

Get onchain data (portfolio, token balances, NFTs, transaction history, **token prices and price ticks**, **token rankings**, **token activity feeds**) via the Zapper GraphQL API. Use **web_fetch** to call the API with a GraphQL POST request.

## When to use

- **Portfolio / token balances** — User asks for wallet balance, holdings, or portfolio value by address.
- **Token prices and charts** — User asks for current/historical token price, price ticks (open/median/close), market cap, volume: use **fungibleTokenV2** with `priceData` and optionally `priceTicks(currency, timeFrame)` or `historicalPrice(timestamp)`.
- **Token details** — User asks for token info by address and chain: **fungibleTokenV2(address, chainId)**; for multiple tokens use **fungibleTokenBatchV2(tokens)**.
- **Trending / ranked tokens** — User asks for trending or top tokens by swap activity: **tokenRanking(first, after, fid)**; optional `fid` for Farcaster-personalized rankings.
- **Token activity feed** — User asks for token-related social activity (swaps, casts): **tokenActivityFeed(chainId, tokenAddress, fid, type, filters)**.
- **Farcaster onchain** — User asks for a Farcaster user's portfolio or transaction history: resolve FID/username to addresses with `accounts` or `farcasterProfile`, then query `portfolioV2` or `transactionHistoryV2`.
- **Transaction timeline** — User asks for recent transactions for an address or Farcaster user.

## API overview

- **Endpoint:** `POST https://public.zapper.xyz/graphql`
- **Auth:** Required. Header: `x-zapper-api-key: YOUR_API_KEY`
- **Body:** JSON `{ "query": "<GraphQL query>", "variables": { ... } }`

API key: get one from [Zapper](https://zapper.xyz) (developer/API section).

**Where to put your key:** Create `skills/zapper/config.json` with your key (the file is gitignored). Copy the example and add your key:

```bash
cp skills/zapper/config.json.example skills/zapper/config.json
# then edit skills/zapper/config.json and set "apiKey": "your-zapper-api-key"
```

Or set the env var `ZAPPER_API_KEY` in the environment where the gateway runs. The agent sends the key as the `x-zapper-api-key` header.

## Key queries

1. **Portfolio by address** — `portfolioV2(addresses: [Address!]!, chainIds: [Int!])` → tokenBalances, appBalances, nftBalances, totalBalanceUSD.
2. **Token price and chart data** — `fungibleTokenV2(address: Address!, chainId: Int!)` → priceData (price, marketCap, volume24h, priceChange5m/1h/24h), priceTicks(currency, timeFrame), historicalPrice(timestamp). TimeFrame: HOUR, DAY, WEEK, MONTH, YEAR.
3. **Token rankings (trending tokens)** — `tokenRanking(first: Int, after: String, fid: Int)` → edges with token, buyCount, buyerCount, buyerCount24h; optional fid for Farcaster-personalized list.
4. **Resolve Farcaster to addresses** — `accounts(fids: [Float!], farcasterUsernames: [String!])` or `farcasterProfile(username)` → connectedAddresses, custodyAddress. Combine for portfolio/timeline.
5. **Transaction history** — `transactionHistoryV2(subjects: [Address!]!, perspective: Signer|Receiver|All, first: 20, filters: { orderByDirection: DESC })` → edges with transaction hash, timestamp, interpretation.processedDescription.

## References

- **[references/api.md](references/api.md)** — Full API usage for LLMs: auth, portfolio/Farcaster/transaction examples, cURL/Node, best practices.
- **[references/token-prices-and-feeds.md](references/token-prices-and-feeds.md)** — Token prices, **fungibleTokenV2** (price data, price ticks, historical price, latest swaps, holders, Farcaster holders), **fungibleTokenBatchV2**, **tokenRanking**, **tokenActivityFeed**, transaction history with full interpretation.
- **[references/schema.graphql](references/schema.graphql)** — Key GraphQL types and operations; full schema: `curl https://protocol.zapper.xyz/agents.txt`.

## How to invoke from the agent

1. Read `skills/zapper/SKILL.md` and `skills/zapper/references/api.md` (use **path** argument). For token prices, charts, rankings, or activity feeds, also read `skills/zapper/references/token-prices-and-feeds.md`.
2. Get API key from config or env (`skills/zapper/config.json` or `ZAPPER_API_KEY`).
3. Use **web_fetch** to `POST https://public.zapper.xyz/graphql` with:
   - Headers: `Content-Type: application/json`, `x-zapper-api-key: <key>`
   - Body: JSON with `query` (GraphQL string) and `variables` (e.g. `addresses`, `chainIds`, `address`+`chainId` for fungibleTokenV2, `first`+`fid` for tokenRanking).
4. Parse `response.data` on success; surface `response.errors` on failure.

For Farcaster users: first call `accounts` or `farcasterProfile` with username/FID, then use the returned addresses in `portfolioV2` or `transactionHistoryV2`. For token prices/rankings/feeds use the queries in token-prices-and-feeds.md (fungibleTokenV2, tokenRanking, tokenActivityFeed).
