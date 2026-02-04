# Zora Coins SDK — Getting started

The Coins SDK is a library that allows you to create, manage, and query data for Zora coins.

Most features available on the Zora product on web and native mobile apps are available in the SDK and API.

## Installation

The SDK works in both client and server environments (JavaScript and TypeScript).

**NPM / pnpm / yarn / bun:**

```bash
npm install @zoralabs/coins-sdk
# or: pnpm add @zoralabs/coins-sdk | yarn add @zoralabs/coins-sdk | bun add @zoralabs/coins-sdk
```

**Peer dependency — viem (required for on-chain writes):**

```bash
npm install viem
# or: pnpm add viem | yarn add viem | bun add viem
```

On-chain write operations will not work without `viem` installed.

## Usage

The SDK integrates with `fetch` and `viem` for on-chain interactions and writes. It can be used in both client and server environments.

## API key

Use an API key to avoid rate limiting and unlock all features.

Set the key with `setApiKey` before making SDK requests:

```ts
import { setApiKey } from "@zoralabs/coins-sdk";

setApiKey("your-api-key-here");
```

To obtain an API key:

1. Log in or create an account on [Zora](https://zora.co)
2. Go to [Developer Settings](https://zora.co/settings/developer)
3. Create an API key

For REST API usage from other languages (curl, Python, etc.), see the [Public REST API](/coins/sdk/public-rest-api) documentation. The Moltbot Zora skill uses the REST API via `scripts/zora.sh`; optional API key goes in `skills/zora/config.json`.
