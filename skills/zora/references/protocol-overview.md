# Zora Coins Protocol Overview

The Zora Coins Protocol is a way to participate in the new creator economy—one where users trade on attention, creativity, and cultural momentum. Every post can become an instantly tradeable cryptocurrency token, transforming social media content into a tradeable asset.

**Open, free, and valuable.**

## How It Works

Every coin has a **backing currency** and trades through a dedicated Uniswap V4 pool with a custom hook that:

- **Protects against sniping** with an early launch fee that decays from 99% to 1% over 10 seconds
- **Distributes rewards** to creators, referrers, and the protocol on every trade
- **Preserves liquidity** by locking 20% of trading fees as permanent pool depth
- **Converts fees** through multi-hop swaps so all rewards are paid in ZORA
- **Deposits initial liquidity** using Doppler protocol for optimized multi-curve positioning

## How Coins Work

**Creator Coins** are profile-level tokens on Zora — each account has its own coin where the username becomes the ticker ($username).

### Creator Coins

- **One coin per profile** — Each creator gets a single coin representing their brand
- **Fixed supply** — 1 billion total per coin
- **50% to creator** — Automatically distributed over 5 years (linear vesting)
- **50% tradeable** — Instantly available on the open market
- **Earn from every trade** — Creators earn $ZORA from trade activity

### Content Coins

- **Post-level tokens** — Every post can become an instantly tradeable coin
- **Creator-backed** — Uses the creator's coin as backing currency
- **Instant creator allocation** — 10M tokens go directly to creators at launch
- **990M tradeable** — Available on the market immediately

## Token Supply Distribution

All coins have a **1 billion token supply** with different allocation strategies:

### Creator Coin Distribution

| Allocation          | Amount      | Details                           |
| ------------------- | ----------- | --------------------------------- |
| **Liquidity Pool**  | 500M tokens | Available for trading immediately |
| **Creator Vesting** | 500M tokens | Linear vesting over 5 years       |
| **Total Supply**    | 1B tokens   | Fixed maximum supply              |

### Content Coin Distribution

| Allocation         | Amount      | Details                           |
| ------------------ | ----------- | --------------------------------- |
| **Liquidity Pool** | 990M tokens | Available for trading immediately |
| **Creator Reward** | 10M tokens  | Instant allocation to creator     |
| **Total Supply**   | 1B tokens   | Fixed maximum supply              |

Vesting: Creator coins vest linearly over 5 years; creators claim gradually via `claimVesting()`.

## Developer Resources

- [Getting Started](https://docs.zora.co/coins/sdk) — JavaScript SDK for creating and managing coins
- [Create Coin](https://docs.zora.co/coins/sdk/create-coin) — Deploy coins programmatically
- [Creating a Coin (contracts)](https://docs.zora.co/coins/contracts/creating-a-coin) — Deploy using the factory contract
- [Coin Rewards](https://docs.zora.co/coins/contracts/rewards) — How automatic reward distribution works
