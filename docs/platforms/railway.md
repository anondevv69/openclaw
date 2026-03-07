---
title: Railway
description: Deploy OpenClaw on Railway
---

# Railway Deployment

**Goal:** OpenClaw Gateway running on [Railway](https://railway.app) with persistent storage and your channels (Discord, Telegram, etc.) connected.

## What you need

- [Railway CLI](https://docs.railway.app/guides/cli) installed (`npm i -g @railway/cli`)
- Railway account (free tier works for testing)
- Model auth: Anthropic API key (or other provider keys)
- Channel credentials: Discord bot token, Telegram token, etc.

## Quick Start

1. Fork/clone the repo → create Railway project
2. Add a volume for persistence
3. Set environment variables (secrets)
4. Deploy
5. Configure via Control UI or CLI

## 1) Create the Railway Project

```bash
# Login to Railway
railway login

# Clone the repo (or fork it first)
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Create a new Railway project
railway init
```

Select "Empty Project" and give it a name like `my-openclaw`.

## 2) Add a Persistent Volume

Railway volumes persist data across deploys:

```bash
# Add a volume (1GB is usually enough to start)
railway volume create -s openclaw-gateway --mount-path /data
```

Or use the Railway dashboard:

1. Go to your project
2. Click "New" → "Volume"
3. Mount path: `/data`
4. Size: 1-5GB depending on your needs

## 3) Configure Environment Variables

Set your secrets via the Railway dashboard or CLI:

```bash
# Required: Gateway token for non-loopback binding
railway variables set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# Required: State directory for persistence
railway variables set OPENCLAW_STATE_DIR=/data

# Model provider API keys
railway variables set ANTHROPIC_API_KEY=sk-ant-...

# Optional: Other providers
railway variables set OPENAI_API_KEY=sk-...
railway variables set GOOGLE_API_KEY=...

# Channel tokens (pick your channels)
railway variables set DISCORD_BOT_TOKEN=MTQ...
railway variables set TELEGRAM_TOKEN=8104...
```

**Notes:**

- Non-loopback binds require `OPENCLAW_GATEWAY_TOKEN` for security
- `OPENCLAW_STATE_DIR=/data` ensures config, sessions, and credentials persist
- Railway automatically injects `PORT` — we'll use that in the start command

## 4) Configure the Service

In the Railway dashboard:

1. Go to your service settings
2. **Start Command:**
   ```
   node dist/index.js gateway --allow-unconfigured --bind lan --port ${PORT}
   ```
3. **Healthcheck Path:** `/health` (optional but recommended)

Or via `railway.json` in your repo root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "node dist/index.js gateway --allow-unconfigured --bind lan --port ${PORT}",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

## 5) Deploy

```bash
railway up
```

Or connect your GitHub repo for auto-deploys on push.

Watch the logs:

```bash
railway logs -f
```

You should see:

```
[gateway] listening on ws://0.0.0.0:XXXX (PID xxx)
```

## 6) Access the Control UI

Once deployed, Railway provides a public URL:

```bash
railway domain
```

Or check the dashboard for the service URL (e.g., `https://my-openclaw-production.up.railway.app`).

Open this URL in your browser and paste your gateway token to authenticate.

## 7) Configure OpenClaw

You have two options:

### Option A: Control UI (Easiest)

1. Open your Railway URL in a browser
2. Authenticate with your gateway token
3. Use the onboarding wizard to set up channels and models

### Option B: CLI via Railway Shell

```bash
# Open a shell in the running container
railway shell

# Create config file
cat > /data/openclaw.json << 'EOF'
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5",
        "fallbacks": ["anthropic/claude-sonnet-4-5"]
      }
    },
    "list": [
      {
        "id": "main",
        "default": true
      }
    ]
  },
  "auth": {
    "profiles": {
      "anthropic:default": { "mode": "token", "provider": "anthropic" }
    }
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "allowlist",
      "guilds": {
        "YOUR_GUILD_ID": {
          "channels": { "general": { "allow": true } }
        }
      }
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "auto"
  }
}
EOF

exit

# Restart to apply
railway redeploy
```

## Environment Variables Reference

| Variable                 | Required | Description                                                  |
| ------------------------ | -------- | ------------------------------------------------------------ |
| `OPENCLAW_GATEWAY_TOKEN` | Yes      | Random token for auth (generate with `openssl rand -hex 32`) |
| `OPENCLAW_STATE_DIR`     | Yes      | Must be `/data` for persistence                              |
| `ANTHROPIC_API_KEY`      | Yes\*    | For Claude models (\*or other provider key)                  |
| `OPENAI_API_KEY`         | No       | For OpenAI models                                            |
| `GOOGLE_API_KEY`         | No       | For Google/Gemini models                                     |
| `DISCORD_BOT_TOKEN`      | No       | For Discord channel                                          |
| `TELEGRAM_TOKEN`         | No       | For Telegram channel                                         |
| `PORT`                   | Auto     | Railway sets this automatically                              |

## Troubleshooting

### "App failed to start" / Crashing

Check logs:

```bash
railway logs
```

Common issues:

- Missing `OPENCLAW_GATEWAY_TOKEN` — required for `--bind lan`
- Missing `OPENCLAW_STATE_DIR` — causes data loss on restart
- OOM (out of memory) — upgrade service tier or reduce concurrency

### Gateway not binding correctly

Ensure your start command uses `--bind lan` and the Railway `$PORT`:

```
node dist/index.js gateway --bind lan --port ${PORT}
```

### Data not persisting

Verify:

1. Volume is mounted at `/data`
2. `OPENCLAW_STATE_DIR=/data` is set
3. Check with: `railway shell` → `ls -la /data`

### Can't access Control UI

Railway services are public by default. If you get auth errors:

1. Check `railway variables get OPENCLAW_GATEWAY_TOKEN`
2. Use that exact token in the browser

For a private deployment, see [Private Deployment](#private-deployment) below.

### Gateway lock issues after crash

If the gateway won't start because of a stale lock:

```bash
railway shell
rm -f /data/gateway.*.lock
exit
railway redeploy
```

## Private Deployment

By default, Railway gives your service a public URL. For a hardened private deployment:

1. **Remove the public domain:**
   - Go to Settings → Networking
   - Remove the generated domain

2. **Access via Railway CLI:**

   ```bash
   railway connect
   ```

3. **Or use Railway's TCP proxying** for specific access patterns.

## Updates

With GitHub integration:

1. Push to your repo
2. Railway auto-deploys

Manual update:

```bash
git pull origin main
railway up
```

## Cost

Railway pricing is usage-based:

- **Free tier:** $5 credit/month, good for testing
- **Hobby:** ~$5-20/month depending on usage
- **Pro:** Higher limits, team features

Recommended specs for OpenClaw:

- **Memory:** 2GB minimum (512MB will OOM)
- **CPU:** Shared is fine for light use
- **Volume:** 1-5GB depending on session history

See [Railway pricing](https://railway.app/pricing) for details.

## Migrating from Mac Mini

To migrate your existing config:

1. **Export from Mac mini:**

   ```bash
   # On your Mac
   tar czf openclaw-backup.tar.gz ~/.openclaw
   ```

2. **Import to Railway:**

   ```bash
   # Extract and copy to volume
   railway shell
   # In the shell:
   # (You'll need to upload the backup somehow - perhaps via curl/wget)
   tar xzf openclaw-backup.tar.gz -C /data
   ```

3. **Update paths** in `/data/openclaw.json` if needed

4. **Redeploy**

## Next Steps

- Set up [sandboxing](/gateway/sandboxing) for secure tool execution
- Configure [cron jobs](/gateway/cron) for scheduled tasks
- Add [memory](/plugins/memory) for persistent context
