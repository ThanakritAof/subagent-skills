#!/usr/bin/env bash
# Generates AGENTS.md from every shippable SKILL.md in the repo.
# Run this after adding or editing a skill so Codex picks up the change.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/AGENTS.md"

{
  cat <<'HEADER'
# subagent-skills

Engineering and productivity skills for AI coding assistants.

This file is read automatically by OpenAI Codex CLI. Apply the skill whose trigger condition matches the current task. When multiple skills could apply, run them in sequence (e.g. `debug-mantra` → `post-mortem` → `management-talk`).

---

HEADER

  find "$REPO/skills" -name SKILL.md \
    -not -path '*/node_modules/*' \
    -not -path '*/deprecated/*' \
    -not -path '*/in-progress/*' \
    -not -path '*/personal/*' \
    | sort \
    | while IFS= read -r skill_md; do

    # Strip YAML frontmatter (between the first two ---), emit the body only.
    awk '
      NR==1 && /^---/ { in_front=1; next }
      in_front && /^---/ { in_front=0; next }
      !in_front { print }
    ' "$skill_md"

    printf '\n---\n\n'
  done
} > "$OUT"

echo "generated $OUT"
