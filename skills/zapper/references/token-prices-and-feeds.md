# Zapper — Token Prices, fungibleTokenV2, Rankings & Feeds

Get comprehensive onchain prices (current and historical), token details, holders, latest swaps, token rankings, and token activity feeds. Price ticks are provided for charts (open, median, close). All queries use the same endpoint: `POST https://public.zapper.xyz/graphql` with header `x-zapper-api-key: YOUR_API_KEY`.

---

## fungibleTokenV2

**Input:** `address: Address!`, `chainId: Int!`. Returns detailed token info including real-time onchain price, price history, holders, liquidity, market cap, latest swaps. Supports multiple price currencies (default USD).

### Token price data and price ticks (charts)

Variables example: `{ "address": "0xf3f92a60e6004f3982f0fde0d43602fc0a30a0db", "chainId": 480, "currency": "USD", "timeFrame": "DAY" }`

```graphql
query TokenPriceData($address: Address!, $chainId: Int!, $currency: Currency!, $timeFrame: TimeFrame!) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    address
    symbol
    name
    decimals
    imageUrlV2
    priceData {
      marketCap
      price
      priceChange5m
      priceChange1h
      priceChange24h
      volume24h
      totalGasTokenLiquidity
      totalLiquidity
      priceTicks(currency: $currency, timeFrame: $timeFrame) {
        open
        median
        close
        timestamp
      }
    }
  }
}
```

**TimeFrame:** `HOUR`, `DAY`, `WEEK`, `MONTH`, `YEAR`. **Currency:** e.g. `USD`, `ETH`, `BTC`.

### Historical price at a timestamp

```graphql
query TokenPriceData($address: Address!, $chainId: Int!) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    address symbol name decimals imageUrlV2
    priceData {
      historicalPrice(timestamp: 1742262500000) {
        timestamp
        price
      }
    }
  }
}
```

### Latest swaps (token)

**Note:** This field costs an additional 8 credits.

Variables: `{ "address": "0x0578d8a44db98b23bf096a382e016e29a5ce0ffe", "chainId": 8453 }`

```graphql
query fungibleTokenV2($address: Address!, $chainId: Int!) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    priceData {
      latestSwaps(first: 3) {
        edges {
          node {
            boughtTokenAddress boughtAmount soldTokenAddress soldAmount
            gasTokenVolume volumeUsd timestamp transactionHash
            from {
              address
              displayName { value source }
              farcasterProfile { fid username metadata { displayName imageUrl } }
            }
          }
        }
      }
    }
  }
}
```

### Token holders (paginated, with identity)

Variables: `{ "address": "0xbe19c96f5deec29a91ca84e0d038d4bb01d098cd", "chainId": 8453, "first": 5 }`

```graphql
query TokenHolders($address: Address!, $chainId: Int!, $first: Float!) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    address symbol name decimals imageUrlV2
    holders(first: $first) {
      edges {
        node {
          holderAddress
          percentileShare
          value
          account {
            displayName { value source }
            farcasterProfile { username fid metadata { imageUrl warpcast } }
          }
        }
      }
    }
  }
}
```

### Swaps by followed Farcaster accounts (latestRelevantFarcasterSwaps)

Variables: `{ "address": "0x1111111111166b7fe7bd91427724b487980afc69", "chainId": 8453, "fid": 177, "first": 5 }`

```graphql
query RelevantSwapFeed($address: Address!, $chainId: Int!, $fid: Int!, $first: Int) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    address symbol name decimals imageUrlV2
    priceData {
      marketCap price priceChange5m priceChange1h priceChange24h volume24h totalGasTokenLiquidity totalLiquidity
      latestRelevantFarcasterSwaps(fid: $fid, first: $first) {
        edges {
          node {
            timestamp transactionHash isBuy amount volumeUsd
            profile { username fid metadata { displayName imageUrl } }
          }
        }
      }
    }
  }
}
```

### Swaps by Farcaster accounts only (latestFarcasterSwaps)

**Note:** Costs an additional 8 credits.

Variables: `{ "address": "0x1111111111166b7fe7bd91427724b487980afc69", "chainId": 8453, "first": 5 }`

```graphql
query FarcasterOnlySwapFeed($address: Address!, $chainId: Int!, $first: Int) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    address symbol name decimals imageUrlV2
    priceData {
      marketCap price priceChange5m priceChange1h priceChange24h volume24h totalLiquidity
      latestFarcasterSwaps(first: $first) {
        edges {
          node {
            timestamp transactionHash isBuy amount volumeUsd
            profile { username fid metadata { displayName imageUrl } }
          }
        }
      }
    }
  }
}
```

### Farcaster token holders (farcasterHolders)

Variables: `{ "address": "0x9cb41fd9dc6891bae8187029461bfaadf6cc0c69", "chainId": 8453, "first": 12 }`

```graphql
query FungibleTokenV2($address: Address!, $chainId: Int!, $first: Int!) {
  fungibleTokenV2(address: $address, chainId: $chainId) {
    farcasterHolders(first: $first) {
      totalCount
      pageInfo { hasPreviousPage hasNextPage startCursor endCursor }
      edges {
        node {
          account { farcasterProfile { username } }
          holderAddress
          percentileShare
        }
      }
    }
  }
}
```

### Followed Farcaster holders (followedFarcasterHolders)

Variables: `{ "chainId": 8453, "address": "0x9cb41fd9dc6891bae8187029461bfaadf6cc0c69", "fid": 954583, "first": 10, "after": null }`

```graphql
query FollowedFarcasterHolders($chainId: Int!, $address: Address!, $fid: Int!, $first: Int!, $after: String) {
  fungibleTokenV2(chainId: $chainId, address: $address) {
    followedFarcasterHolders(fid: $fid, first: $first, after: $after) {
      totalCount
      pageInfo { hasPreviousPage hasNextPage startCursor endCursor }
      edges {
        node {
          holderAddress
          percentileShare
          account { displayName { value } farcasterProfile { username fid } }
        }
      }
    }
  }
}
```

---

## fungibleTokenBatchV2

Takes an array of `{ address, chainId }` and returns the same data structure as fungibleTokenV2 for multiple tokens in one request.

Variables example:

```json
{
  "tokens": [
    { "address": "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf", "chainId": 8453 },
    { "address": "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9", "chainId": 1 },
    { "address": "0x00ef6220b7e28e890a5a265d82589e072564cc57", "chainId": 8453 }
  ]
}
```

```graphql
query FungibleTokenBatchV2($tokens: [FungibleTokenInputV2!]!) {
  fungibleTokenBatchV2(tokens: $tokens) {
    address
    symbol
    name
    decimals
    imageUrlV2
    priceData {
      price
      priceChange5m
      priceChange1h
      priceChange24h
      volume24h
      totalGasTokenLiquidity
      totalLiquidity
    }
  }
}
```

---

## tokenRanking

Returns a paginated list of tokens ranked by swap activity and adoption. Optionally provide a Farcaster FID for rankings tailored to that user's social graph.

Variables: `{ "first": 10, "after": null, "fid": 954583 }`

```graphql
query TokenRanking($first: Int, $after: String, $fid: Int) {
  tokenRanking(first: $first, after: $after, fid: $fid) {
    pageInfo { hasPreviousPage hasNextPage startCursor endCursor }
    edges {
      cursor
      node {
        id
        chainId
        tokenAddress
        token {
          address name symbol
          priceData { price }
        }
        buyCount
        buyerCount
        buyerCount24h
      }
    }
  }
}
```

Arguments: `first` (default 6, max 20), `after` (cursor), `fid` (optional).

---

## Transaction History (Farcaster → addresses → timeline)

**Step 1:** Resolve Farcaster to addresses using `farcasterProfile` (or `accounts` with farcasterUsernames/fids).

```graphql
query GetFarcasterProfile($username: String) {
  farcasterProfile(username: $username) {
    username fid metadata { displayName description imageUrl warpcast }
    custodyAddress
    connectedAddresses
  }
}
```

**Step 2:** Use resolved addresses in `transactionHistoryV2(subjects: $subjects, ...)`. Combine `connectedAddresses` and `custodyAddress`.

Full transaction details: request `transaction` (hash, timestamp, network, fromUser, toUser), `interpretation` (processedDescription, description, descriptionDisplayItems with TokenDisplayItem, NFTDisplayItem, ActorDisplayItem, etc.), and `perspectiveDelta` (account, tokenDeltasV2, nftDeltasV2). When displaying token amounts, adjust `amountRaw` using the token's `decimals`.

See [api.md](api.md) for a minimal transactionHistoryV2 example.

---

## tokenActivityFeed

Surface token-related social activity: swaps and casts. Supports feed types: DEFAULT (swaps + casts), ALL_CASTS, FOLLOWED_SWAPS, ALL_SWAPS.

Variables: `{ "chainId": 8453, "tokenAddress": "0x9cb41fd9dc6891bae8187029461bfaadf6cc0c69", "fid": 954583, "type": "DEFAULT", "filters": { "minimumUsdVolume": 50 } }`

```graphql
query TokenActivityFeed($chainId: Int!, $tokenAddress: String!, $fid: Int!, $filters: ChannelFeedFilterArgs, $type: TokenChannelFeedType) {
  tokenActivityFeed(chainId: $chainId, tokenAddress: $tokenAddress, fid: $fid, filters: $filters, type: $type) {
    pageInfo { hasPreviousPage hasNextPage startCursor endCursor }
    edges {
      cursor
      node {
        ... on ChannelFeedSwap {
          id fid transactionHash timestamp chainId volumeUsd amount isBuy
          channelParentUrl: parentUrl
        }
        ... on FarcasterTopCast {
          id hash authorFid parentHash parentUrl rootParentUrl parentAuthorFid authorPowerBadge mentionedFids text timestamp
        }
      }
    }
  }
}
```

**TokenChannelFeedType:** `DEFAULT`, `ALL_CASTS`, `FOLLOWED_SWAPS`, `ALL_SWAPS`. **ChannelFeedFilterArgs:** `minimumUsdVolume`, `ignoreAutomated`, `isBuy`.

---

## Enums and types (quick reference)

- **TimeFrame:** HOUR, DAY, WEEK, MONTH, YEAR  
- **Currency:** USD, EUR, GBP, CAD, CNY, KRW, JPY, RUB, AUD, NZD, CHF, SGD, INR, BRL, ETH, BTC, HKD, SEK, NOK, MXN, TRY  
- **priceData** fields: price, marketCap, totalLiquidity, totalGasTokenLiquidity, priceChange5m, priceChange1h, priceChange24h, volume24h, priceTicks(currency, timeFrame), historicalPrice(timestamp), latestSwaps(first), latestFarcasterSwaps(first), latestRelevantFarcasterSwaps(fid, first)

Credits: `latestSwaps` and `latestFarcasterSwaps` cost an additional 8 credits per request.
