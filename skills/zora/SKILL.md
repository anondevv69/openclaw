---
name: zora
description: Look up and create Zora creator/content coins via Zora API and SDK. Use when the user asks about a Zora coin, creator profile, wallet holdings, trending coins, market data, or how to create a Zora coin. Supports Base (chain 8453). Optional ZORA_API_KEY for higher rate limits. For creating coins, see references/create-coin.md.
metadata: '{"moltbot":{"emoji":"🪙","homepage":"https://docs.zora.co","requires":{"bins":["curl","jq"]}}}'
---

# Zora Coins Protocol

Query Zora creator coins, content coins, profiles, and explore data via the Zora Coins REST API.

**Protocol context**: Creator coins are profile-level tokens (1B supply, 50% creator vesting over 5 years, 50% tradeable). Content coins are post-level tokens (10M to creator, 990M tradeable). See [references/protocol-overview.md](references/protocol-overview.md) for distribution and rewards. For **creating coins** (parameters, metadata, SDK vs REST), see [references/create-coin.md](references/create-coin.md) and [Zora Create Coin docs](https://docs.zora.co/coins/sdk/create-coin). For general SDK use, see [references/sdk-getting-started.md](references/sdk-getting-started.md) (Coins SDK: `@zoralabs/coins-sdk`, viem peer dep, `setApiKey()`).

## Quick Start

### Setup

API key is optional (higher rate limits with a key). Get one at [zora.co/settings/developer](https://zora.co/settings/developer).

**Option A — workspace** (`skills/zora/config.json`):

```json
{"apiKey": "YOUR_ZORA_API_KEY"}
```

Config keys: `apiKey` or `api_key` (camelCase preferred).

**Option B — home**: `~/.moltbot/skills/zora/config.json` with the same shape.

**Option C — env**: Set `ZORA_API_KEY` in the environment, or copy `skills/zora/.env.example` to `skills/zora/.env` and fill in your key. The script loads `skills/zora/.env` if present; env overrides config. See [.env.example](.env.example).

If no config or env, the script still works without a key (subject to stricter rate limits).

### Verify

```bash
scripts/zora.sh coin 0x... 8453
scripts/zora.sh profile 0x...
```

## Usage

### Coin lookup (by contract address + chain)

```bash
# Base chain = 8453
scripts/zora.sh coin <contract_address> [chain_id]

# Example
scripts/zora.sh coin 0x777777751622c0d3258f214F9DF38E35BF45baF3 8453
```

Returns coin metadata, market data, and related info.

### Profile lookup (wallet)

```bash
scripts/zora.sh profile <address_or_identifier>
```

Returns profile balances and activity for that wallet on Zora.

### Explore (trending / new / top gainers)

The script maps CLI words to the Zora API `listType` enum: `trending` → `TRENDING_ALL`, `new` → `NEW`, `top-gainers` → `TOP_GAINERS`.

```bash
# Trending coins (listType=TRENDING_ALL)
scripts/zora.sh explore trending [chain_id]

# New coins (listType=NEW; default chain 8453 = Base)
scripts/zora.sh explore new 8453

# Top gainers (listType=TOP_GAINERS)
scripts/zora.sh explore top-gainers 8453
```

## Chain IDs

| Chain   | ID     |
| ------- | ------ |
| Base    | 8453   |
| Base Sepolia | 84532 |
| Ethereum | 1    |

Default chain when omitted is Base (8453).

## API

- **Base URL**: https://api-sdk.zora.engineering
- **Auth**: Optional `api-key` header (set in config)
- **Docs**: [Public REST API](https://docs.zora.co/coins/sdk/public-rest-api), [Interactive API](https://api-sdk.zora.engineering/docs)

## Error handling

- **Rate limit** — Use an API key or retry later
- **404 / empty** — Check address and chain ID
- **Invalid response** — Script prints raw JSON; check API docs for schema changes

## Creating coins

When the user wants to **create** a Zora (content) coin:

1. Read [references/create-coin.md](references/create-coin.md) for parameters (creator, name, symbol, metadata URI, currency, chainId, startingMarketCap), metadata requirements, and SDK vs REST flow.
2. **SDK**: Use `createCoin` (send and wait) or `createCoinCall` (get calldata for WAGMI/custom tx) from `@zoralabs/coins-sdk` with viem; requires a wallet client to sign.
3. **REST API**: `POST https://api-sdk.zora.engineering/create/content` with JSON body returns `calls` and `predictedCoinAddress`; the user (or app) must sign and submit the transaction.
4. Creator must have a wallet; the agent can explain the flow, suggest parameters, or return API response (`calls` + address) for the user to submit elsewhere.

Official docs: [Create Coin](https://docs.zora.co/coins/sdk/create-coin).

## Resources

- [Zora Coins SDK](https://docs.zora.co/coins/sdk)
- [Create Coin](https://docs.zora.co/coins/sdk/create-coin)
- [Zora for Developers](https://docs.zora.co)
- [API key](https://zora.co/settings/developer)
