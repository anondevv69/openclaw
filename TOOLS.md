# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

**Read / write / edit tools:** Call these with the **`path`** argument (e.g. `{"path": "skills/bankr/SKILL.md"}`). Do not use `file_path` — some runtimes validate against the schema and reject `file_path`.

## What Goes Here

Things like:
- Camera names and locations
- SSH hosts and aliases  
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras
- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH
- home-server → 192.168.1.100, user: admin

### TTS
- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Bankr (crypto portfolio)

When the user asks to check their crypto portfolio, Bankr balance, or what they're holding:

1. Use the **read** tool to read `skills/bankr/SKILL.md` (from workspace root).
2. Use the **exec** tool with:
   - **command:** `./scripts/bankr.sh "What is my portfolio balance?"` (or the user's exact question in quotes)
   - **workdir:** the workspace root path + `/skills/bankr` (e.g. if workspace is `/Volumes/X9 Pro 1/repos/molt/moltbot` then workdir is `/Volumes/X9 Pro 1/repos/molt/moltbot/skills/bankr`).

   The script must run from inside the `skills/bankr` folder so `./scripts/bankr.sh` resolves. The script uses the API key in `skills/bankr/config.json`.

**Alpha Finder + Bankr:** When the user finds a deal via Alpha Finder (x402) and wants to **buy** it, do **not** complete the transaction via Alpha Finder's x402. Use **Bankr** to execute the buy: read `skills/bankr/SKILL.md`, then run `./scripts/bankr.sh "Buy <user's intent>"` from `skills/bankr`. Alpha Finder is for discovery only; Bankr is for execution.

---

## Alpha Finder (discovery only)

When the user wants to find alpha or deals (e.g. trending tokens, opportunities):

1. Use the **read** tool to read `skills/alpha-finder/SKILL.md` (from workspace root).
2. Use Alpha Finder for **discovery only** — find and list deals. Do **not** execute trades or pay via Alpha Finder's x402.
3. When the user wants to **buy** a found deal, use **Bankr** (see Bankr section above): run `./scripts/bankr.sh "Buy …"` from `skills/bankr`.

---

## Farcaster cast (post only)

To **post on Farcaster** (e.g. scan summary, trade update, ASCII art): use **exec** with **workdir** `skills/neynar` and **command** `./scripts/neynar.sh post "your text"` (add `--channel base` if desired). **Do not use the message tool** for Farcaster — the message tool is for WhatsApp/Telegram/etc. and will fail (no target or wrong channel); only **exec** + `neynar.sh post` can cast. Requires `signerUuid` in `skills/neynar/config.json`.

---

## ClawdHub (install skill from hub)

When the user wants to **download/install a skill** from ClawdHub (e.g. https://clawhub.ai/Andretuta/polymarket-agent): use **exec** from the **workspace root** with `npx clawdhub search "polymarket"` to find the slug, then `npx clawdhub install <slug>`. Slug from URL `clawhub.ai/User/skill-name` is usually `User/skill-name` or `skill-name`. Example: `npx clawdhub install Andretuta/polymarket-agent`. Skills install into `./skills`; Moltbot loads them on next session. Read `skills/clawdhub/SKILL.md` for search/install/update. If `clawdhub` is not installed, `npx clawdhub` runs it via npm.

---

## Base Alpha (discovery + execution + casting)

**Workflow in one line:** Zapper trending tokens → compare with Neynar/Farcaster (social + trades) → decide alpha or not → buy or skip via Bankr; then Polymarket scan for quick flips. Combine Zapper, Neynar, InfoBot, followed wallets, and Bankr; cast every scan and trade on Farcaster via **exec** + `neynar.sh post` (not message tool).

When the user wants to "run base alpha", find and trade alpha on Base with casting:

1. Use the **read** tool to read `skills/base-alpha/SKILL.md` (from workspace root). **There is no single script** — you run the workflow yourself via web_fetch and exec.
2. **Discovery:** Use **web_fetch** for **Zapper** (POST .../graphql: tokenRanking), **Neynar** (GET trending fungibles/trades), **InfoBot** (GET /far, /wallet, /clanker). Compare Zapper trending with Farcaster activity; use **followedWallets** from `skills/base-alpha/config.json`. Do **not** send "Run Base Alpha scan" to Bankr; use Bankr only to **execute trades** or Polymarket scan.
3. **Smart money:** If Farcaster activity comes from **FID &lt; 20,000**, weight positively. Use InfoBot to decide go/no-go.
4. **Execution:** All buys/sells via **Bankr** — **exec** `./scripts/bankr.sh "Buy $5 of TOKEN on Base"` from `skills/bankr` when confidence is high.
5. **Casting:** Post on Farcaster **only** via **exec** with workdir `skills/neynar` and command `./scripts/neynar.sh post "…"` (e.g. `--channel base`). **Do not use the message tool** — it will fail for Farcaster; only neynar.sh post can cast. After every scan cast what you gathered and Entering or Waiting; no tx links.
6. **Polymarket:** Separate cron for Polymarket arbitrage / quick flips; use Bankr for that scan and for executing trades.
7. Config: `skills/base-alpha/config.json`; needs Zapper, Neynar (with **signerUuid** for casts), InfoBot, Bankr configured.

---

## Neynar (Farcaster)

When the user wants to look up Farcaster users, read feeds, search casts, or **post a cast**:

1. Use the **read** tool to read `skills/neynar/SKILL.md` (from workspace root).
2. Use the **exec** tool with:
   - **workdir:** **must** be the full path to the **skills/neynar** directory **inside the agent's workspace** — i.e. `<workspace_dir>/skills/neynar`. The script loads config from that directory (or ~/.moltbot/skills/neynar). Example: if workspace is `/Volumes/X9 Pro 1/repos/molt/moltbot` then workdir is `/Volumes/X9 Pro 1/repos/molt/moltbot/skills/neynar`.
   - **command:** `./scripts/neynar.sh <command> [args]` — e.g. `./scripts/neynar.sh user dwr.eth`, `./scripts/neynar.sh post "big upgrades today"` (add `--channel base` if desired).
   - **To post a cast:** `./scripts/neynar.sh post "your text"`. Posting requires `signerUuid` in config.

**"Config not found" / "Neynar tool not set up":** The agent's **workspace** is where it resolves `skills/neynar`. If the workspace is the **default** (`~/clawd`), then workdir becomes `~/clawd/skills/neynar` — and your config is in the **repo** (e.g. moltbot/skills/neynar/config.json), not there. Fix: set the agent workspace to the repo so that `skills/neynar` points at the repo. From the repo root run: `./scripts/set-workspace-to-repo.sh`. Then restart the gateway and start a new chat.

---

## Bird (X / Twitter)

When the user wants to read X/Twitter tweets, search, view timelines, or get trending/news:

1. Use the **read** tool to read `skills/bird/SKILL.md` (from workspace root).
2. Use the **exec** tool to run the `bird` CLI (must be installed: `brew install steipete/tap/bird` or `npm i -g @steipete/bird`). Examples:
   - **command:** `bird whoami` — check logged-in account
   - **command:** `bird read <url-or-id>` — read a tweet
   - **command:** `bird search "query" -n 10` — search tweets
   - **command:** `bird user-tweets @handle -n 20` — user timeline
   - **command:** `bird trending` — trending/news

   Bird uses cookie-based auth; user must have run `bird check` or set `--cookie-source` / config so credentials are available.

---

## Zora (creator coins & profiles)

When the user wants to look up a Zora creator coin, creator profile, wallet holdings on Zora, or trending/new coins:

1. Use the **read** tool to read `skills/zora/SKILL.md` (from workspace root).
2. Use the **exec** tool with:
   - **workdir:** workspace root + `/skills/zora` (e.g. `/Volumes/X9 Pro 1/repos/molt/moltbot/skills/zora`).
   - **command:** `./scripts/zora.sh <command> [args]` — e.g. `./scripts/zora.sh coin 0x... 8453`, `./scripts/zora.sh profile 0x...`, `./scripts/zora.sh explore trending 8453`.

   Optional: add `skills/zora/config.json` with `{"apiKey": "YOUR_ZORA_API_KEY"}` for higher rate limits (get key at zora.co/settings/developer).

When the user wants to **create** a Zora (content) coin: read `skills/zora/references/create-coin.md` for parameters (creator, name, symbol, metadata URI, currency, chainId), SDK (`createCoin` / `createCoinCall`) vs REST (`POST .../create/content`), and that the user must sign and submit the transaction.

---

## Infobot (Farcaster, Zora, Clanker, wallet, Relay)

When the user asks to look up a Farcaster profile, Zora creator, Clanker token, wallet, cast search, Relay transaction, or Farcaster by X handle:

1. Use the **read** tool to read `skills/infobot/SKILL.md` (from workspace root).
2. Use the **web_fetch** tool to call the InfoBot Public API:
   - **Base URL:** From `skills/infobot/config.json` `apiBaseUrl`, or default `https://infobot-production-f74e.up.railway.app` (no trailing slash).
   - **Endpoints:** `GET /api/v1/search?q=<query>` (universal), `/api/v1/far?q=<username-or-address>` (Farcaster), `/api/v1/wallet?address=<0x...>`, `/api/v1/casts?keyword=<keyword>&limit=5`, `/api/v1/zora?q=<handle>`, `/api/v1/clanker?q=<query>`.
   - **Auth (optional):** If config has `apiKey`, send header `x-api-key: <key>`. Optional `neynarApiKey` / `zoraApiKey` as `x-neynar-api-key` / `x-zora-api-key` to use your own keys.
   - Return the response `data` (or error) to the user.

---

## Zapper (onchain portfolio, tokens, Farcaster onchain)

When the user asks for wallet/portfolio data, token balances by address, or Farcaster user onchain data:

1. Use the **read** tool to read `skills/zapper/SKILL.md` and `skills/zapper/references/api.md` (use **path**).
2. Use the **web_fetch** tool to call the Zapper GraphQL API:
   - **URL:** `POST https://public.zapper.xyz/graphql`
   - **Headers:** `Content-Type: application/json`, `x-zapper-api-key: <key>` (required; from `skills/zapper/config.json` `apiKey` or env `ZAPPER_API_KEY`).
   - **Body:** JSON `{ "query": "<GraphQL query>", "variables": { "addresses": ["0x..."], "chainIds": [1] } }`.
   - Key queries: `portfolioV2(addresses, chainIds)` for token/app/NFT balances; `accounts(farcasterUsernames: [...])` to resolve Farcaster to addresses; `transactionHistoryV2(subjects: [...], perspective: Signer, first: 20)` for transaction timeline.
   - Return `response.data` on success; surface `response.errors` on failure.

---

Add whatever helps you do your job. This is your cheat sheet.
