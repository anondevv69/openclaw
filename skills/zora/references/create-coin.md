# Zora Coins — Create Coin

How to create new content coins on the Zora protocol. Source: [Zora Docs — Create Coin](https://docs.zora.co/coins/sdk/create-coin).

## Overview

Creating a coin means generating calldata (via SDK or REST API) and sending a transaction that deploys the ERC20 with protocol integrations. The creator (or their wallet) must sign and submit the transaction.

- **SDK**: Use `createCoin` (high-level: send and wait) or `createCoinCall` (low-level: get `to`/`data`/`value` for your own tx flow).
- **REST API**: `POST https://api-sdk.zora.engineering/create/content` returns transaction parameters (`calls`, `predictedCoinAddress`); the client signs and sends the tx.

## Parameters

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| creator | Address | Yes | Creator EOA address; auto-included in owners, default payout recipient if none set |
| name | string | Yes | Human-readable coin name (e.g. "My Awesome Coin") |
| symbol | string | Yes | Ticker (e.g. "MAC") |
| metadata | object | Yes | `{ type: "RAW_URI", uri: "ipfs://..." }` — valid metadata URI per [Metadata](https://docs.zora.co/coins/sdk/create-coin#metadata) |
| currency | enum | Yes | Backing currency: `CREATOR_COIN` \| `CREATOR_COIN_OR_ZORA` \| `ZORA` \| `ETH`. `ZORA`, `CREATOR_COIN`, `CREATOR_COIN_OR_ZORA` not on Base Sepolia |
| chainId | number | No | Default Base mainnet `8453`; Base Sepolia `84532` |
| startingMarketCap | enum | No | `LOW` (default) or `HIGH` — initial liquidity config; use `HIGH` for known creators to reduce sniping |
| platformReferrer | Address | No | Referral address; use zero address if not used |
| additionalOwners | Address[] | No | Extra owner addresses (creator is always included) |
| payoutRecipientOverride | Address | No | Override payout recipient; defaults to creator |
| enableSmartWalletRouting | boolean | No | Default `false` |

## Metadata

- `metadata.uri` must point to valid metadata (name, symbol, image, etc.) as in the [Metadata](https://docs.zora.co/coins/sdk/create-coin#metadata) spec.
- Use the [Metadata Builder](https://docs.zora.co/coins/sdk/create-coin#metadata) to upload assets and get a URI, or host JSON on IPFS/HTTPS.

Example (SDK):

```ts
import {
  createMetadataBuilder,
  createZoraUploaderForCreator,
} from "@zoralabs/coins-sdk";

const { createMetadataParameters } = await createMetadataBuilder()
  .withName("Test ZORA Coin")
  .withSymbol("TZC")
  .withDescription("Test Description")
  .withImage(new File(["FILE"], "test.png", { type: "image/png" }))
  .upload(createZoraUploaderForCreator(creatorAddress));
// createMetadataParameters → name, symbol, uri for createCoin
```

## SDK usage

### High-level: send and wait for receipt

```ts
import {
  createCoin,
  CreateConstants,
} from "@zoralabs/coins-sdk";
import { createWalletClient, createPublicClient, http } from "viem";
import { base } from "viem/chains";

const result = await createCoin({
  call: {
    creator: "0xYourAddress" as Address,
    name: "My Awesome Coin",
    symbol: "MAC",
    metadata: { type: "RAW_URI", uri: "ipfs://bafy..." },
    currency: CreateConstants.ContentCoinCurrencies.ZORA,
    chainId: base.id,
    startingMarketCap: CreateConstants.StartingMarketCaps.LOW,
    platformReferrer: "0xOptionalReferrer" as Address,
  },
  walletClient,
  publicClient,
});

// result.hash, result.address, result.receipt, result.deployment, result.chain
```

### Low-level: get calldata for WAGMI / custom flow

`createCoinCall(call)` returns:

```ts
{
  calls: Array<{ to: Address; data: Hex; value: bigint }>;
  predictedCoinAddress: Address;
}
```

Use `calls[0]` with your tx sender (e.g. WAGMI `useSendTransaction`). `predictedCoinAddress` is the coin address once the tx confirms.

## REST API (create/content)

**Endpoint:** `POST https://api-sdk.zora.engineering/create/content`

**Headers:** `Content-Type: application/json`, optional `api-key: <ZORA_API_KEY>`

**Body (JSON):**

- `creator` (string, address) — required  
- `name` (string) — required  
- `symbol` (string) — required  
- `metadata` (object) — required: `{ type: "RAW_URI", uri: "<ipfs-or-https-uri>" }`  
- `currency` (string) — required: `CREATOR_COIN` | `ZORA` | `ETH` | `CREATOR_COIN_OR_ZORA`  
- `chainId` (number) — optional, default Base mainnet  
- `startingMarketCap` (string) — optional: `LOW` | `HIGH`  
- `platformReferrer` (string, address) — optional  
- `additionalOwners` (string[]) — optional  
- `payoutRecipientOverride` (string, address) — optional  
- `enableSmartWalletRouting` (boolean) — optional  

**Response:** `{ calls, predictedCoinAddress, backingCurrency, usedSmartWalletRouting? }` — client signs and submits `calls`.

## When to use

- **User wants to create a Zora coin:** Guide them to the [Create Coin](https://docs.zora.co/coins/sdk/create-coin) docs; or in an app use the SDK (`createCoin` / `createCoinCall`) or call the REST API to get `calls` then send the transaction from a wallet.
- **Agent has no wallet:** The agent can describe parameters, suggest metadata URIs, or call the REST API to return `calls` + `predictedCoinAddress`; the user (or a wallet integration) must sign and submit the tx.

## Links

- [Create Coin (Zora Docs)](https://docs.zora.co/coins/sdk/create-coin)
- [Public REST API](https://docs.zora.co/coins/sdk/public-rest-api)
- [SDK Getting Started](sdk-getting-started.md)
