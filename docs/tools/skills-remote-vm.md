---
summary: "Running Moltbot on a VM/cloud and adding skills remotely"
read_when:
  - You run the Gateway on a VPS, exe.dev, Railway, or Docker
  - You want to add or update skills when the agent runs virtually
---
# Skills when running virtually (VM / cloud)

You can run Moltbot on a VM or in the cloud and **add or update skills the same way as locally** — the only difference is that skills live on the **remote host** where the Gateway runs.

## Run Moltbot virtually (options)

| Option | Best for | Docs |
|--------|----------|-----|
| **exe.dev** | Cheap always-on Linux VM, HTTPS UI | [exe.dev](/platforms/exe-dev) |
| **Railway** | One-click deploy, no terminal on server | [Railway](/railway) |
| **Northflank** | One-click + browser setup | [Northflank](/northflank) |
| **Fly.io** | App platform, global regions | [Fly.io](/platforms/fly) |
| **Docker** | Any host (local or VPS), isolated | [Docker](/install/docker) |
| **GCP / Hetzner / Oracle** | Full control, production VPS | [VPS hub](/vps), [GCP](/platforms/gcp), [Hetzner](/platforms/hetzner) |

How it works:

- The **Gateway runs on the VM/container** and owns state, workspace, and skills.
- You connect from your laptop/phone via the **Control UI** (over HTTPS or SSH tunnel).
- All skill paths are on that host: workspace `skills/`, `~/.clawdbot/skills/`, and `skills.load.extraDirs` in `~/.clawdbot/moltbot.json`.

## Adding skills when the Gateway runs on a VM/cloud

Yes — you can add skills when running virtually. Do it **on the host where the Gateway runs** (or via a flow that updates that host).

### 1) Workspace skills (recommended for “virtual” setups)

Skills under the **agent workspace** on the VM are loaded like local workspace skills.

- **Path on VM:** `<workspace>/skills/` (default workspace is `~/clawd`, so `~/clawd/skills/`).
- **Railway / Docker with `/data`:** if workspace is `/data/workspace`, use `/data/workspace/skills/`.

**Ways to get skill folders there:**

- **SSH + clone/copy:** SSH into the VM, clone a repo or copy skill folders into `<workspace>/skills/`.
- **Git-backed workspace:** Keep the workspace in a private git repo; add skill folders in that repo, push from your laptop, then on the VM run `git pull` in the workspace (or use a deploy hook). Skills in `skills/` then update with the rest of the workspace.
- **One-time copy:** Use `scp` or rsync from your laptop to copy a `skills/` directory (or individual skill folders) into the remote workspace.

Example (after SSH into the VM):

```bash
# On the VM (workspace default ~/clawd)
mkdir -p ~/clawd/skills
git clone --depth 1 https://github.com/BankrBot/moltbot-skills.git /tmp/moltbot-skills
cp -r /tmp/moltbot-skills/bankr /tmp/moltbot-skills/neynar ~/clawd/skills/
```

### 2) Managed skills on the VM

Same idea as local: put skill folders in **managed skills** on the VM.

- **Path on VM:** `~/.clawdbot/skills/`
- **Railway / Docker:** if state dir is `/data/.clawdbot`, use `/data/.clawdbot/skills/`

SSH in (or use a startup script / Dockerfile) and create dirs + copy skills:

```bash
mkdir -p ~/.clawdbot/skills
# then copy or clone skill folders into ~/.clawdbot/skills/
```

### 3) Extra dirs on the VM

Clone a skill repo **on the VM** and point `skills.load.extraDirs` at it in the **VM’s** config.

- Edit `~/.clawdbot/moltbot.json` on the VM (or `/data/.clawdbot/moltbot.json` if using `/data`).
- Add the path where you cloned the repo (e.g. `~/moltbot-skills`).

Example on the VM:

```bash
git clone https://github.com/BankrBot/moltbot-skills.git ~/moltbot-skills
```

Then in `~/.clawdbot/moltbot.json` on the VM:

```json5
{
  "skills": {
    "load": {
      "extraDirs": ["~/moltbot-skills"]
    }
  }
}
```

Updates: `cd ~/moltbot-skills && git pull` on the VM; no need to copy files.

### 4) Control UI (install deps only)

The Control UI on the VM shows skills and can **install skill dependencies** (e.g. brew/node) for skills that are already present. It does not add new skill folders from a URL; you still add folders via workspace, managed, or extraDirs as above.

## Summary

| Question | Answer |
|----------|--------|
| Can I run Moltbot virtually? | Yes — exe.dev, Railway, Fly, Docker, GCP, Hetzner, etc. |
| Can I add skills when running virtually? | Yes — add them on the VM (workspace `skills/`, `~/.clawdbot/skills/`, or `extraDirs`). |
| Same as local? | Yes — same layout and config; only the host is remote. |
| Easiest remote flow? | Git-backed workspace with `skills/` in the repo, or SSH + clone/copy into `<workspace>/skills/`. |

See [Skills](/tools/skills), [Skills config](/tools/skills-config), and [VPS hosting](/vps) for more.
