---
summary: "Using BankrBot/moltbot-skills in this repo"
read_when:
  - Adding or updating skills from https://github.com/BankrBot/moltbot-skills
---
# Moltbot-skills (BankrBot) setup

Skills from [BankrBot/moltbot-skills](https://github.com/BankrBot/moltbot-skills) are available in this repo in two ways.

## 1. Copied into workspace (current setup)

The following skill folders were copied from the upstream repo into `skills/`:

- **bankr** – crypto trading, Polymarket, DeFi, automation
- **base** – Base chain (placeholder)
- **neynar** – Neynar (placeholder)
- **onchainkit** – OnchainKit
- **zapper** – Zapper (placeholder)

They load automatically when this repo is used as the Moltbot workspace. No config change needed.

## 2. Optional: load from clone via extraDirs

To load directly from the clone (e.g. to pull updates without re-copying), clone the repo and add it to `~/.clawdbot/moltbot.json`:

```bash
git clone https://github.com/BankrBot/moltbot-skills.git ~/moltbot-skills
```

In `~/.clawdbot/moltbot.json`:

```json5
{
  "skills": {
    "load": {
      "extraDirs": ["~/moltbot-skills"]
    }
  }
}
```

Then run `git pull` in `~/moltbot-skills` to update. If the same skill name exists in both `skills/` and extraDirs, the workspace `skills/` version wins.

## Updating the copied skills

From the repo root:

```bash
git -C moltbot-skills pull
cp -r moltbot-skills/bankr moltbot-skills/base moltbot-skills/neynar moltbot-skills/onchainkit moltbot-skills/zapper skills/
```

The clone is ignored by git (`moltbot-skills/` in `.gitignore`). Re-run the clone if you remove it.
