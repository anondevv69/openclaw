# Using infobot from Moltbot

Infobot (https://github.com/anondevv69/infobot) is a Discord/Telegram bot. To use it from Moltbot, expose one of:

- A **CLI** (script) the agent can run with **exec**
- An **HTTP API** the agent can call with **web_fetch**

## Option A: CLI script in infobot

1. In your infobot repo, add a script (e.g. `scripts/lookup.js` or `lookup.ts`) that:
   - Accepts one argument: the search query (wallet, username, keyword, etc.)
   - Uses your existing Neynar/Zora/Clanker services to perform the lookup
   - Prints the result as JSON or readable text to stdout

2. Example invocation from Moltbot (agent runs via exec):
   - **workdir:** path to your infobot clone (e.g. `/path/to/infobot`)
   - **command:** `node scripts/lookup.js "0x1234..."` or `npx ts-node scripts/lookup.ts "username"`

3. Ensure `NEYNAR_API_KEY` (and other keys) are available when the script runs (env in the gateway process or in `skills.entries.infobot.env` in config).

## Option B: HTTP API

1. In infobot, add a small HTTP server or extend the existing backend with e.g.:
   - `GET /lookup?q=<query>` or
   - `POST /search` with body `{ "query": "..." }`
   that runs the same lookup logic and returns JSON.

2. Run that server locally (e.g. `http://127.0.0.1:3001`) or deploy it.

3. In the Moltbot skill, the agent uses **web_fetch** to call that URL with the user’s query and returns the response.

## After integration

- Put the infobot skill in `skills/infobot/` (this folder) with SKILL.md describing when to use it and how to invoke (CLI path or API URL).
- If using CLI: set **workdir** in TOOLS.md or in the skill body to the infobot repo path, and ensure exec is allowed (e.g. `tools.exec.security: "full"` or allowlist that includes the script).
- Restart the gateway and start a new chat so the agent sees the skill.
