#!/usr/bin/env bash
# Regenerates AGENTS.md from current skills and symlinks it to ~/.codex/AGENTS.md
# so Codex CLI picks up the skills globally across all projects.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.codex/AGENTS.md"

"$REPO/scripts/gen-agents-md.sh"

mkdir -p "$HOME/.codex"
ln -sfn "$REPO/AGENTS.md" "$DEST"
echo "linked $DEST -> $REPO/AGENTS.md"
