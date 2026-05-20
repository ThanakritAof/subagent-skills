#!/usr/bin/env bash
# Generates .claude-plugin/plugin.json from every shippable skill on disk.
# The skills array is derived purely from directory layout, so it never drifts.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/.claude-plugin/plugin.json"

python3 - "$REPO" "$OUT" <<'PYEOF'
import sys, json, os

repo, out = sys.argv[1], sys.argv[2]
excluded = {"deprecated", "in-progress", "personal"}
skills_dir = os.path.join(repo, "skills")

skills = []

for bucket in sorted(os.listdir(skills_dir)):
    if bucket in excluded or bucket.startswith("."):
        continue
    bucket_path = os.path.join(skills_dir, bucket)
    if not os.path.isdir(bucket_path):
        continue
    for skill_name in sorted(os.listdir(bucket_path)):
        skill_md = os.path.join(bucket_path, skill_name, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue
        skills.append(f"./skills/{bucket}/{skill_name}")

manifest = {
    "name": "subagent-skills",
    "skills": skills,
}

with open(out, "w") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"generated {out}")
PYEOF
