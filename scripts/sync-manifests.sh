#!/usr/bin/env bash
# Regenerates every machine-generated manifest from the skills on disk, then
# warns about anything that still needs a human (README prose entries).
#
#   ./scripts/sync-manifests.sh          # regenerate + warn on README gaps
#
# Run after adding or editing a skill. The pre-commit hook runs this for you.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

"$REPO/scripts/gen-plugin-json.sh"
"$REPO/scripts/gen-agents-md.sh"
"$REPO/scripts/gen-antigravity-json.sh"

# README entries are hand-written prose, so we can't generate them — only flag
# shippable skills that are missing a link to their SKILL.md in the top README.
missing=0
while IFS= read -r skill_md; do
  rel="${skill_md#"$REPO/"}"          # skills/<bucket>/<name>/SKILL.md
  if ! grep -qF "$rel" "$REPO/README.md"; then
    if [ "$missing" -eq 0 ]; then
      echo "warning: README.md is missing links for these shippable skills:" >&2
    fi
    echo "  - $rel" >&2
    missing=$((missing + 1))
  fi
done < <(
  find "$REPO/skills" -name SKILL.md \
    -not -path '*/node_modules/*' \
    -not -path '*/deprecated/*' \
    -not -path '*/in-progress/*' \
    -not -path '*/personal/*' \
    | sort
)

if [ "$missing" -gt 0 ]; then
  echo "warning: add the entries above to README.md (and the bucket README) by hand." >&2
fi

echo "manifests synced"
