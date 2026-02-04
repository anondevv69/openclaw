#!/usr/bin/env bash
# Set the default agent workspace to this repo so skills (including zora) are loaded from repo/skills.
# Run from the repo root: ./scripts/set-workspace-to-repo.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_JSON="[{\"id\":\"main\",\"default\":true,\"workspace\":\"${REPO_ROOT}\"}]"

pnpm moltbot config set agents.defaults.workspace "\"${REPO_ROOT}\"" --json
pnpm moltbot config set agents.list "${AGENTS_JSON}" --json

echo "Workspace set to: ${REPO_ROOT}"
echo "Run: pnpm moltbot skills list && pnpm moltbot skills info zora"
