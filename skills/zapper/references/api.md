# Zapper API — Usage for LLMs

This document describes how to get onchain data with the Zapper API (GraphQL). Use it when the user asks for portfolio data, token balances, Farcaster onchain context, transaction history, **token prices (current/historical)**, **token rankings**, or **token activity feeds**.

**Token prices, fungibleTokenV2, tokenRanking, and feeds:** See **[references/token-prices-and-feeds.md](token-prices-and-feeds.md)** for:
- **fungibleTokenV2** — Token details, onchain price, price ticks (charts), historical price, latest swaps, holders, Farcaster holders and followed holders, latestRelevantFarcasterSwaps / latestFarcasterSwaps.
- **fungibleTokenBatchV2** — Batch lookup for multiple tokens.
- **tokenRanking** — Ranked tokens by swap activity; optional Farcaster FID for personalized rankings.
- **tokenActivityFeed** — Token social activity (swaps + casts) with types DEFAULT, ALL_CASTS, FOLLOWED_SWAPS, ALL_SWAPS.
- **Transaction history** — Resolve Farcaster via farcasterProfile/accounts, then transactionHistoryV2 with full interpretation/descriptionDisplayItems.

## API endpoint and auth

- **Endpoint:** `https://public.zapper.xyz/graphql`
- **Method:** POST, body: JSON `{ "query": "...", "variables": { ... } }`
- **Required headers:** `Content-Type: application/json`, `x-zapper-api-key: YOUR_API_KEY`
- **CSRF (Apollo):** Zapper returns "blocked as a potential Cross-Site Request Forgery" unless you also send **x-apollo-operation-name** with the **exact GraphQL operation name** (the name after `query` or `mutation` in your query string). Examples: for `query TokenRanking(...)` use `x-apollo-operation-name: TokenRanking`; for `query PortfolioV2Query(...)` use `x-apollo-operation-name: PortfolioV2Query`. When using **web_fetch**, pass **method: "POST"**, **headers**: `{ "Content-Type": "application/json", "x-zapper-api-key": "<key>", "x-apollo-operation-name": "<OperationName>" }` (required — use the exact operation name from your query, e.g. `TokenRanking`), and **body**: JSON string `{ "query": "...", "variables": { ... } }`. Without these, the request will be blocked (CSRF). Optional: `Origin: https://zapper.xyz`, `Referer: https://zapper.xyz/`.

For programmatic access to the schema and instructions:
```bash
curl https://protocol.zapper.xyz/agents.txt
```

## Troubleshooting (400 CSRF)

1. **Test from terminal** — From the repo root, with your key in `skills/zapper/config.json`:
   ```bash
   ZAPPER_KEY="$(jq -r .apiKey skills/zapper/config.json)"
   curl -s -X POST 'https://public.zapper.xyz/graphql' \
     -H 'Content-Type: application/json' \
     -H "x-zapper-api-key: $ZAPPER_KEY" \
     -H 'x-apollo-operation-name: TokenRanking' \
     -d '{"query":"query TokenRanking($first: Int) { tokenRanking(first: $first) { edges { node { id token { symbol } } } } }","variables":{"first":5}}'
   ```
   If you get JSON (with `data` or `errors`), the API and key work; the issue is how **web_fetch** is invoked (method/headers/body). If you get 400 with "CSRF", one of the three headers is missing or wrong.

2. **web_fetch** — You must pass **method: "POST"**, **headers** (Content-Type, x-zapper-api-key, x-apollo-operation-name), and **body** as a **JSON string** (not an object). The gateway must be running code that supports these parameters; restart the gateway and start a new chat.

3. **Operation name** — The value of **x-apollo-operation-name** must match the GraphQL operation name exactly (e.g. `TokenRanking` for `query TokenRanking(...)`).

## Making requests

1. **Validate addresses** before querying.
2. Send a JSON body: `{ "query": "<GraphQL query>", "variables": { ... } }`.
3. Use the `path` argument when reading files (not `file_path`).

### Example: portfolio by address

```graphql
query PortfolioV2Query($addresses: [Address!]!, $chainIds: [Int!]) {
  portfolioV2(addresses: $addresses, chainIds: $chainIds) {
    tokenBalances {
      totalBalanceUSD
      byToken(first: 10) {
        edges {
          node {
            tokenAddress
            symbol
            balance
            balanceUSD
            imgUrlV2
            network { name }
          }
        }
      }
    }
  }
}
```

Variables: `{ "addresses": ["0x..."], "chainIds": [1] }` (1 = Ethereum Mainnet).

### cURL example

```bash
curl --location 'https://public.zapper.xyz/graphql' \
  --header 'Content-Type: application/json' \
  --header 'x-zapper-api-key: YOUR_API_KEY' \
  --header 'x-apollo-operation-name: PortfolioV2Query' \
  --data '{"query":"query PortfolioV2Query($addresses: [Address!]!, $chainIds: [Int!]) { portfolioV2(addresses: $addresses, chainIds: $chainIds) { tokenBalances { totalBalanceUSD byToken(first: 10) { edges { node { tokenAddress symbol balance balanceUSD imgUrlV2 network { name } } } } } } }","variables":{"addresses":["0x3d280fde2ddb59323c891cf30995e1862510342f"],"chainIds":[1]}}'
```

For **tokenRanking**, use `x-apollo-operation-name: TokenRanking`.

### Node.js (fetch)

```javascript
const response = await fetch('https://public.zapper.xyz/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-zapper-api-key': process.env.ZAPPER_API_KEY,
    'x-apollo-operation-name': 'PortfolioV2Query',  // required for CSRF; use your query name
  },
  body: JSON.stringify({ query: PortfolioV2Query, variables: { addresses: ['0x...'], chainIds: [1] } }),
});
const json = await response.json();
if (json.errors) throw new Error(JSON.stringify(json.errors));
return json.data;
```

## Farcaster onchain context

To get portfolio or transaction data for a Farcaster user:

1. **Resolve FID/username to addresses** with the `accounts` query:

```graphql
query GetFarcasterAddresses($fids: [Float!], $farcasterUsernames: [String!]) {
  accounts(fids: $fids, farcasterUsernames: $farcasterUsernames) {
    farcasterProfile {
      username
      fid
      connectedAddresses
      custodyAddress
    }
  }
}
```

2. Use the resolved addresses in `portfolioV2(addresses: [...])`. Combine both `connectedAddresses` and `custodyAddress` when querying.

### Farcaster transaction timeline

1. Use the same `accounts` query to get the user's addresses.
2. Query `transactionHistoryV2` with those addresses:

```graphql
query GetFarcasterTimeline($subjects: [Address!]!, $perspective: TransactionHistoryV2Perspective = Signer) {
  transactionHistoryV2(
    subjects: $subjects
    perspective: $perspective
    first: 20
    filters: { orderByDirection: DESC }
  ) {
    edges {
      node {
        ... on TimelineEventV2 {
          transaction { hash timestamp network }
          interpretation { processedDescription }
        }
        ... on ActivityTimelineEventDelta {
          transactionHash
          transactionBlockTimestamp
          network
          perspectiveAccount { address }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

`perspective`: `Signer` (signed by address), `Receiver` (received by address), or `All`.

## Best practices for agents

1. Validate addresses before querying.
2. Implement rate limiting and retries with exponential backoff.
3. Handle API errors and `response.errors` in the JSON body.
4. Cache responses when appropriate.
5. Verify network/chainId values against the schema (e.g. `Network` enum or chainIds).
6. Use the full schema in [schema.graphql](schema.graphql) to build valid queries.

## Response handling

- Success: `response.data` contains the result of the query.
- Errors: `response.errors` is an array of GraphQL errors; surface them to the user.
- Always check for `response.errors` before using `response.data`.

## Full schema

The complete GraphQL schema (types, enums, Query, Mutation) is in [schema.graphql](schema.graphql). Use it to construct valid queries and understand required/optional fields and the `Network` enum.
