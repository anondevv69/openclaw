---
name: base-alpha
description: Base Alpha — find and trade alpha on Base using Zapper trending tokens, Farcaster social signals, a followed wallet list, and InfoBot for creator history. All buys/sells via Bankr. Cast every trade on Farcaster (no transaction link). Hourly Polymarket arbitrage scan; quick wins via Polymarket and daily BTC/ETH. Optimize for quick wins and long holds; factor in low-FID smart money.
metadata: '{"moltbot":{"emoji":"📈","homepage":"","requires":{}}}'
---

# Base Alpha

**Workflow in one line:** (1) Zapper trending tokens → (2) compare with Neynar/Farcaster (social + trades) → (3) decide if alpha → (4) buy or skip via Bankr; (5) Polymarket scan for quick flips. Combine Zapper, Neynar, InfoBot, followed wallets, and Bankr; cast every scan and trade on Farcaster via **exec** + `./scripts/neynar.sh post "..."` from `skills/neynar` — **do not use the message tool** for Farcaster (it will fail; only neynar.sh post can cast).

Find and trade alpha on Base by combining **trending tokens** (Zapper), **social and Farcaster signals** (Neynar), a **followed wallet list**, and **creator history** (InfoBot). All execution is via **Bankr**. Every trade is **cast on Farcaster** (what coin, how much, why; no transaction link; on sell, state why and profit/loss). Run **Polymarket arbitrage** scan via Bankr (separate cron, e.g. every 30 min). Pursue **quick wins** (Polymarket: stocks, news, BTC/ETH daily) and **long wins** (token holds). Factor in **smart money**: Farcaster accounts with **FID &lt; 20,000** are treated as early/smart money when a token is slowly trending.

## When to Use

- User asks to "find alpha", "scan Base alpha", "run base alpha", "check trending tokens and trade", or similar.
- User wants automated or semi-automated alpha discovery + execution with casting.
- User wants hourly Polymarket arbitrage checks or quick wins (Polymarket, daily charts).

## How to run (no single script)

Base Alpha has **no executable script** (no `base-alpha.sh`). You perform the workflow by calling APIs and scripts yourself.

**CRITICAL — web_fetch for Zapper and Neynar:** Do **not** call web_fetch with only the URL. That will return 400 (Zapper) or 401 (Neynar). You **must** pass **method**, **headers**, and for Zapper also **body**. First **read** the API key from `skills/zapper/config.json` (field `apiKey`) and from `skills/neynar/config.json` (field `apiKey`), then pass them in the **headers** of web_fetch.

**Zapper (tokenRanking) — exact steps (do both in order):**
1. **Read** `skills/zapper/config.json` and note the **apiKey** value (e.g. a UUID string).
2. **Call web_fetch** with **all** of: **url** `https://public.zapper.xyz/graphql`, **method** `POST`, **headers** `{ "Content-Type": "application/json", "x-zapper-api-key": "<paste the apiKey you read>", "x-apollo-operation-name": "TokenRanking" }`, **body** the JSON string `"{\"query\":\"query TokenRanking($first: Int) { tokenRanking(first: $first) { edges { node { id token { symbol address } } } } }\",\"variables\":{\"first\":10}}"`. Do **not** call web_fetch for Zapper with only the URL — that returns 401 and may be cached; you must pass method, headers, and body in the **same** call.

**Neynar (trending fungibles) — exact steps:** Read `skills/neynar/config.json` for **apiKey**, then call web_fetch with **url** `https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=1h`, **method** `GET`, **headers** `{ "x-api-key": "<paste the apiKey you read>" }`.

1. **Zapper** — Use **web_fetch** with the parameters above (method POST, headers including x-zapper-api-key and x-apollo-operation-name, body). Run `tokenRanking` and optionally `tokenActivityFeed` (see skills/zapper references). Get API key from `skills/zapper/config.json` (apiKey).
2. **Neynar** — Use **web_fetch** with the parameters above (method GET, headers with x-api-key). Base URL is **https://api.neynar.com** (not InfoBot). For fungible trades use URL `https://api.neynar.com/v2/farcaster/fungible/trades/?network=base&address=<contract>&time_window=24h` with the same **headers**. Or **exec** with `./scripts/neynar.sh` from `skills/neynar` for feed/search.
3. **InfoBot** — Use **web_fetch** to InfoBot API (e.g. GET `https://infobot-production-f74e.up.railway.app/api/v1/far?q=...`). No custom headers required.
4. **Bankr** — Use **exec** with `./scripts/bankr.sh "..."` from `skills/bankr` **only for executing trades** or for Polymarket scan. Do **not** send "Run Base Alpha scan" to Bankr.
5. **Casts** — Use **exec** with workdir `skills/neynar` and command `./scripts/neynar.sh post "your cast text"`. **Do not use the `message` tool** for Farcaster.

## Goals

- **Maximize profit** — Balance quick wins (Polymarket, daily BTC/ETH) and long wins (token holds).
- **Smart money** — If a token is slowly trending but has activity from **low-FID Farcaster accounts (FID &lt; 20,000)**, weight that positively (early/smart money).
- **Creator quality** — Always use **InfoBot** to check if a person has many clanks or coins deployed; use that to make smarter buy/skip decisions.
- **Transparency** — Cast every trade on Farcaster: entry (coin, amount, why); exit (why sold, profit or loss). **Do not share any transaction link** in casts.

## Data Sources (Discovery)

1. **Zapper** — Trending tokens: use **tokenRanking** (and optionally **tokenActivityFeed**) for tokens with strong buy activity. Prefer time windows that reflect "past hour" or "past 30 minutes" where the API supports it; filter or rank by **buyCount** / **buyerCount** / **buyerCount24h** (e.g. more than 20 buys). Read `skills/zapper/SKILL.md` and `skills/zapper/references/token-prices-and-feeds.md`; call `POST https://public.zapper.xyz/graphql` with `x-zapper-api-key` from config or `ZAPPER_API_KEY`.
2. **Neynar** — **Trending fungibles** and **fungible trades** on Base. Base URL is **https://api.neynar.com** (do not use InfoBot's URL). **web_fetch** with **method GET**, **headers** `{ "x-api-key": "<key from skills/neynar/config.json>" }`, URL e.g. `https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=1h` or `.../v2/farcaster/fungible/trades/?network=base&address=<contract>&time_window=24h`. **Trending feed** and **cast search** via `scripts/neynar.sh`. Read `skills/neynar/SKILL.md` and `skills/neynar/references/onchain-apis.md`.
3. **Followed wallet list** — From `skills/base-alpha/config.json`: `followedWallets` (array of addresses). For each candidate token, check (via Zapper **transactionHistoryV2** or Neynar fungible trades) whether **any of these addresses** bought or created the token. If yes, treat as a strong signal.
4. **InfoBot** — For any Farcaster user or address involved in a token (e.g. from swaps or casts), call InfoBot: **GET /api/v1/far?q=&lt;username&gt;** then **GET /api/v1/wallet?address=&lt;address&gt;** or **GET /api/v1/clanker?q=&lt;address&gt;** to see clanks/coins deployed. Use to decide: many quality clanks/coins = positive signal; use with caution for unknown creators. Read `skills/infobot/SKILL.md`.

## Smart Money (Low FID)

- When evaluating tokens, if **Farcaster activity** (swaps, casts) comes from accounts with **FID &lt; 20,000**, treat that as **smart money** (early adopters) and factor it into confidence.
- Use Neynar user lookup or Zapper Farcaster profile data to get **FID**; compare to 20,000 and adjust score/reasoning accordingly.

## Execution (Bankr Only)

- **All buys and sells** are done via **Bankr**. Read `skills/bankr/SKILL.md`; run `./scripts/bankr.sh "&lt;natural language trade&gt;"` from `skills/bankr` (e.g. "Buy $5 of TOKEN on Base", "Sell 50% of TOKEN on Base").
- **Position size** — Default **$5** per new token, or **10% of wallet** (for the relevant chain/asset) when confidence is high. Let the user override in config if present (e.g. `defaultPositionUsd`, `maxPositionPercent`).
- **Confidence** — Only execute when the combined research (trending + social + wallet list + InfoBot + smart money) checks out; skip or reduce size when uncertain.

## Casting Rules (Farcaster)

- **After every search/scan** (whether you trade or not): Cast on Farcaster a **scan summary**: (1) **What you gathered** — e.g. top trending tokens, wallet activity from followed list, smart-money (low FID) signals, Polymarket/quick-win checks. (2) **Status** — either **Entering: &lt;what you bought and why&gt;** or **Waiting: &lt;brief reason no trade yet, e.g. no high-confidence setup&gt;**. Do not include any transaction link. This way every run produces one cast: either entering or waiting.
- **After every buy:** Cast: **what coin**, **how much** (e.g. $5 or 10% size), **why** (e.g. trending, smart money bought, creator has clanks). **Do not include any transaction link.**
- **After every sell:** Cast: **why you sold** (e.g. target hit, stop loss, thesis broken), **profit or loss** (e.g. +$12, -$3).
- **Posting casts (Farcaster only):** Use **exec** with workdir `skills/neynar` and command `./scripts/neynar.sh post "cast text"` (e.g. `./scripts/neynar.sh post "Waiting: ..." --channel base`). **Do not use the `message` tool** for Farcaster — the message tool is for other channels (WhatsApp, Telegram, etc.) and will fail (no target / wrong channel); only **exec** + `neynar.sh post` can post casts. For ASCII art or scan summaries, use the same: exec from `skills/neynar` with `./scripts/neynar.sh post "your text"`. Prefer the channel in config (`castChannel`) if set, e.g. `--channel base`.

## Hourly: Polymarket Arbitrage

- **Once per hour only** — Polymarket arbitrage scan runs **hourly** (not on every Base Alpha run). Use a **separate cron** with `--every 3600000` (1 hour) so the agent runs Polymarket scan + cast once per hour. The 20‑min Base Alpha cron does Zapper/Neynar/wallets/InfoBot + cast; do **not** include Polymarket in that message. Use **Bankr** for the scan: "Scan Polymarket for arbitrage opportunities" or "Find Polymarket arbitrage and list opportunities." Execute only when the user has approved or when configured for auto-execution. After each Polymarket run, cast what you gathered and Entering or Waiting.

## Scheduling (always-on style) and credits

**"Always running"** — The agent is not a daemon; it runs when triggered. To get **recurring scans** (e.g. "always checking"):

1. **Gateway cron** — Add a cron job that triggers the agent on a schedule. The job runs **inside the Gateway**; when it fires, the agent runs one turn (discovery + optional execution + casting). Use **isolated** session so scans don't clutter your main chat; optionally deliver a short summary to a channel.
2. **Example (hourly Base Alpha + Polymarket):**
   ```bash
   moltbot cron add \
     --name "Base Alpha scan" \
     --every 3600000 \
     --session isolated \
     --message "Run Base Alpha: check Zapper trending (1h), Neynar fungibles/trades, followed wallets, InfoBot for creators; if high confidence execute via Bankr. After every scan cast on Farcaster what you gathered and say Entering (if you traded) or Waiting (if no trade). No tx links. Do not run Polymarket in this job (Polymarket has its own hourly cron)."
   ```
   `--every 3600000` = every 1 hour (ms). Use `--every 1800000` for every 30 minutes.
3. **Credits and cost** — More frequent runs = more API calls and higher cost:
   - **Zapper**: tokenRanking, tokenActivityFeed, transactionHistoryV2 — each GraphQL call may count against your plan.
   - **Neynar**: trending fungibles, fungible trades, feed — rate limits / paid tiers.
   - **InfoBot**: /far, /wallet, /clanker — may have x402 or rate limits.
   - **Bankr**: mainly used when **executing** trades; scan-only uses fewer Bankr calls.
   **Recommendation:** Start with **hourly** (`--every 3600000`). If you want "always on" with lower cost, use **every 30 minutes** (`--every 1800000`); avoid going below ~15 minutes or credits will add up quickly. Disable or reduce frequency if you hit limits.
4. **Every 20 minutes (aggressive, e.g. overnight):** `--every 1200000` (20 × 60 × 1000 ms). Use for night runs or when you want maximum opportunity capture; expect higher Zapper/Neynar/InfoBot usage.
5. **Polymarket once per hour (separate cron):** Add a **second** cron so Polymarket arbitrage runs hourly, not on every Base Alpha run:
   ```bash
   moltbot cron add \
     --name "Base Alpha Polymarket" \
     --every 3600000 \
     --session isolated \
     --message "Polymarket only: scan for arbitrage via Bankr; if opportunity execute via Bankr and cast. Cast what you gathered and Entering or Waiting. No tx links."
   ```
6. **List or edit crons:** `moltbot cron list`, `moltbot cron edit <jobId> --every 1200000`. **Manual run:** `moltbot cron run <jobId> --force`.

## Quick Wins

- **Polymarket** — Bet on stock market, news, or BTC/ETH price (daily). Use Bankr for Polymarket execution. When anything is bought or sold (including Polymarket), **cast the trade on Farcaster** (what, how much, why; no tx link; on sell, why and P&amp;L).
- **Daily BTC/ETH** — Use Bankr (and optionally Zapper for charts) for short-term daily moves; same casting rules.

## Workflow (Summary)

1. **Discover** — Zapper tokenRanking / Neynar trending fungibles + trades; filter for strong buy activity (e.g. &gt;20 buys in relevant window).
2. **Social** — Neynar feed/search: are people talking about, buying, or trading this token?
3. **Wallet list** — Did any `followedWallets` buy or create this token? (Zapper transactionHistoryV2 or Neynar.)
4. **Smart money** — For Farcaster actors, check FID; if FID &lt; 20,000, weight positively.
5. **InfoBot** — For relevant users/addresses, check clanks/coins deployed; use for go/no-go.
6. **Decide** — Score confidence; if high, **execute via Bankr** ($5 or 10% of wallet).
7. **Cast** — Post on Farcaster: entry (coin, amount, why); no tx link. On sell: why sold, profit/loss.
8. **Hourly** — Polymarket arbitrage scan via Bankr (separate hourly cron); cast any resulting trades.
9. **Quick wins** — Polymarket (stocks, news, BTC/ETH daily) via Bankr; cast all trades.

## Aggressive mode (maximize opportunity)

If the user wants to **be aggressive and make money**:

1. **Run scans more often** — Cron every **20 minutes** overnight (or 24/7): `--every 1200000`. More runs = more chances to catch moves early; balance against API credits (Zapper, Neynar, InfoBot).
2. **Larger size when confident** — In `config.json`, raise `defaultPositionUsd` (e.g. 10 or 20) and/or `maxPositionPercent` (e.g. 15–20) so that when the agent has high confidence (trending + smart money + creator quality), it sizes up. Do not exceed what you can afford to lose.
3. **Quick wins + base alpha** — Add a **second cron** for Polymarket / quick wins (e.g. every 30–60 min) so the agent also checks Polymarket arbitrage, stocks, news, and BTC/ETH daily without waiting for the main Base Alpha run. Example:
   ```bash
   moltbot cron add --name "Base Alpha quick wins" --every 1800000 --session isolated \
     --message "Quick wins: check Polymarket arbitrage via Bankr; check BTC/ETH daily setup. If clear opportunity, execute via Bankr and cast (no tx link)."
   ```
4. **Act on more signals** — The agent should still only execute when research checks out (Zapper + Neynar + wallet list + InfoBot + smart money). Being aggressive means **more scans** and **slightly larger size when confidence is high**, not lowering the bar for when to trade.

## Config

- **Path:** `skills/base-alpha/config.json` (gitignored). Copy from `skills/base-alpha/config.json.example`.
- **followedWallets** — Array of Ethereum/Base addresses (0x...) to track; if they buy or create a token, treat as signal.
- **defaultPositionUsd** — Default dollar amount per token (e.g. 5). Increase (e.g. 10–20) for aggressive sizing when confident.
- **maxPositionPercent** — Max share of wallet per token (e.g. 10). Increase (e.g. 15–20) for aggressive when confident.
- **castChannel** or **castChannelId** — Optional Farcaster channel for trade casts (e.g. "base").
- **enableHourlyPolymarketScan** — If true, run Polymarket arbitrage scan when the user or cron triggers it.

## Install and verify

- **Skill is in-repo** — Base Alpha lives at `skills/base-alpha/`; Moltbot loads it when the workspace is this repo. No `clawdhub install` needed.
- **Ensure config** — Copy `skills/base-alpha/config.json.example` to `skills/base-alpha/config.json` and set `followedWallets` (and optional `defaultPositionUsd`, `maxPositionPercent`, `castChannel`). You already have config if you loaded the cielo wallets.
- **Restart gateway** — Restart the Moltbot gateway (app or `moltbot gateway run`) so it picks up the skill.
- **New chat** — Start a **new** chat so the agent sees Base Alpha. Then say e.g. "Run Base Alpha scan" or add a cron (see Scheduling) to trigger it on a schedule.
- **Casting** — Neynar must have **signerUuid** in `skills/neynar/config.json` for posting casts; without it, the agent cannot cast scan summaries or trades.

## Dependencies

- **Zapper** — API key in `skills/zapper/config.json` or `ZAPPER_API_KEY`. Used for tokenRanking, tokenActivityFeed, transactionHistoryV2, fungibleTokenV2.
- **Neynar** — API key + **signer** in `skills/neynar/config.json` (or env). Used for trending fungibles, trades, feed, search, **post cast**. Signer required for every scan cast and trade cast.
- **InfoBot** — API base in `skills/infobot/config.json`. Used for /far, /wallet, /clanker.
- **Bankr** — API key in `skills/bankr/config.json`. Used for all buys, sells, Polymarket, quick wins.

## Troubleshooting Zapper and Neynar

If **web_fetch** still returns 400 (Zapper CSRF) or 404/401 (Neynar), work through the following.

### 1. Test from the terminal (isolate API vs agent)

Run these from the repo root. Replace keys with values from `skills/zapper/config.json` and `skills/neynar/config.json`.

**Zapper (tokenRanking):**
```bash
ZAPPER_KEY="$(jq -r .apiKey skills/zapper/config.json)"
curl -s -X POST 'https://public.zapper.xyz/graphql' \
  -H 'Content-Type: application/json' \
  -H "x-zapper-api-key: $ZAPPER_KEY" \
  -H 'x-apollo-operation-name: TokenRanking' \
  -d '{"query":"query TokenRanking($first: Int) { tokenRanking(first: $first) { edges { node { id token { symbol } } } } }","variables":{"first":5}}'
```
If you see JSON with `data` (or GraphQL errors in the body), the API and key work; the issue is how the agent is calling **web_fetch**. If you see 400 with "CSRF", the request is missing one of the headers above.

**Neynar (trending fungibles):**
```bash
NEYNAR_KEY="$(jq -r .apiKey skills/neynar/config.json)"
curl -s -H "x-api-key: $NEYNAR_KEY" \
  "https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=1h"
```
If you see JSON with `trending`, the API and key work. If you see 401, the key is wrong or missing. Use **https://api.neynar.com** only (not InfoBot's URL).

### 2. Restart gateway and start a new chat

The **web_fetch** tool must support **method**, **headers**, and **body**. That requires the updated Moltbot code. Restart the gateway (Mac app or `moltbot gateway run`) and start a **new** chat so the agent uses the current tool schema.

### 3. Call web_fetch with the correct shape

**Zapper** — You must pass **method**, **headers**, and **body**; otherwise the request is sent as GET with no custom headers and Zapper returns 400.

- **url:** `https://public.zapper.xyz/graphql`
- **method:** `POST`
- **headers:** `{ "Content-Type": "application/json", "x-zapper-api-key": "<key from skills/zapper/config.json>", "x-apollo-operation-name": "TokenRanking" }`
- **body:** A single JSON string, e.g. `"{\"query\":\"query TokenRanking($first: Int) { tokenRanking(first: $first) { edges { node { id token { symbol } } } } }\",\"variables\":{\"first\":10}}"`

**Neynar** — You must pass **headers** with **x-api-key** (and **method GET** if the tool defaults to GET). Base URL must be **https://api.neynar.com** (not InfoBot).

- **url:** `https://api.neynar.com/v2/farcaster/fungible/trending/?network=base&time_window=1h`
- **method:** `GET`
- **headers:** `{ "x-api-key": "<key from skills/neynar/config.json>" }`

### 4. Common mistakes

- **Zapper returns 401 Unauthorized or response is "cached" with errors** — You called **web_fetch with only the URL** (no method, headers, or body). Zapper requires **method POST**, **headers** (Content-Type, x-zapper-api-key, x-apollo-operation-name), and **body** in the **same** call. Follow "Zapper (tokenRanking) — exact steps" above: (1) read skills/zapper/config.json for apiKey, (2) call web_fetch with url, method POST, headers including that apiKey, and body.
- **Agent says "API keys are invalid"** — Usually the agent called **web_fetch with only the URL** (no method, headers, or body). Zapper and Neynar then return 400/401. The keys in config are fine; the agent must pass **method**, **headers**, and (Zapper) **body** and must **read** the key from config and put it in the headers. See "CRITICAL" and "Zapper/Neynar — exact steps" in "How to run" above.
- **Zapper:** Forgetting **x-apollo-operation-name** or using a typo (must match the query name exactly, e.g. `TokenRanking`). Sending **body** as an object instead of a JSON string. Using GET instead of POST.
- **Neynar:** Using InfoBot's base URL for Neynar endpoints; Neynar base is **https://api.neynar.com**. Forgetting the **x-api-key** header.
- **Gateway:** Using an old gateway build that does not support **method**/**headers**/**body** on web_fetch — restart and use a new chat.

## References

- Zapper: `skills/zapper/SKILL.md`, `skills/zapper/references/token-prices-and-feeds.md`, `skills/zapper/references/api.md`
- Neynar: `skills/neynar/SKILL.md`, `skills/neynar/references/onchain-apis.md`, `skills/neynar/references/feed-apis.md`
- InfoBot: `skills/infobot/SKILL.md`, `skills/infobot/references/api.md`
- Bankr: `skills/bankr/SKILL.md`
