---
summary: "Step-by-step: run Moltbot locally with this repo as workspace"
read_when:
  - First-time local run with the repo as workspace
---
# Run Moltbot locally (this repo, step by step)

## Prerequisites

- **Node.js 22+** ([nodejs.org](https://nodejs.org))
- **pnpm** (`npm install -g pnpm`)

## Step 1: Install dependencies

From the repo root:

```bash
cd /Volumes/X9\ Pro\ 1/repos/molt/moltbot
pnpm install
```

## Step 2: Build

```bash
pnpm build
```

(If build fails, fix any errors; the gateway needs the built output.)

## Step 3: Set this repo as the workspace

Create or edit the config file so Moltbot uses this repo as the agent workspace.

**Config file location:** `~/.clawdbot/moltbot.json`  
(On macOS/Linux, `~` is your home directory.)

If the file doesn't exist, create it. If it exists, add or merge the `agents` block. Use the **absolute path** to this repo on your machine:

```json
{
  "agents": {
    "defaults": {
      "workspace": "/Volumes/X9 Pro 1/repos/molt/moltbot"
    }
  }
}
```

**Important:** If your repo path has spaces (like above), the path in JSON is still a normal string: `"/Volumes/X9 Pro 1/repos/molt/moltbot"`.

Save the file.

## Step 4: Onboard (first time only)

If you haven't run Moltbot before on this machine (or you want to set up model + channels again):

```bash
pnpm moltbot onboard
```

- When it asks for **workspace**, it should show or use the path you set in Step 3. Confirm or enter the repo path.
- Add your **model provider** (e.g. OpenAI API key or Anthropic).
- Optionally add **channels** (Telegram, Discord, etc.); you can skip and add later.
- Finish the wizard.

You only need to do this once (or when you want to change model/channels).

## Step 5: Start the gateway

From the repo root:

```bash
pnpm moltbot gateway run
```

Leave this terminal open. You should see the gateway start and a message like:

- Control UI: `http://127.0.0.1:18789` (or similar)
- A **token** to open the UI (copy it if you need to paste into the browser).

## Step 6: Open the Control UI

1. In your browser go to: **http://127.0.0.1:18789**
2. If it asks for a token, paste the token from the terminal (Step 5).
3. You can chat with the agent, manage skills, and connect channels from here.

---

## Summary

| Step | Command / action |
|------|------------------|
| 1 | `pnpm install` |
| 2 | `pnpm build` |
| 3 | Set `agents.defaults.workspace` to this repo path in `~/.clawdbot/moltbot.json` |
| 4 | `pnpm moltbot onboard` (first time only) |
| 5 | `pnpm moltbot gateway run` |
| 6 | Open http://127.0.0.1:18789 in the browser |

Skills in this repo's `skills/` folder (including bankr, neynar, onchainkit, and all built-in skills) will load automatically because the workspace is this repo.

## Troubleshooting

- **"Workspace not found"** – Check the path in `~/.clawdbot/moltbot.json` is exact and absolute (e.g. `/Volumes/X9 Pro 1/repos/molt/moltbot`).
- **Port in use** – Use a different port: `pnpm moltbot gateway run --port 18790` and open `http://127.0.0.1:18790`.
- **Build errors** – Run `pnpm build` again; ensure Node 22+ and `pnpm install` completed.
- **Agent says it doesn't have the bankr (or other) skill** – Skills must be *eligible* to appear in the prompt. Run `pnpm moltbot skills info bankr`. If it shows "Missing requirements" (e.g. bins: jq), install them (e.g. `brew install jq`). Restart the gateway and **start a new chat** (skills are fixed when the session starts).
