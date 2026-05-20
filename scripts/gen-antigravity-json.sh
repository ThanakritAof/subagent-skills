#!/usr/bin/env bash
# Generates antigravity.json from every shippable SKILL.md in the repo.
# Run this after adding or editing a skill so the Antigravity manifest stays in sync.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/antigravity.json"

python3 - "$REPO" "$OUT" <<'PYEOF'
import sys, json, os, re

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
        skill_path = os.path.join(bucket_path, skill_name)
        skill_md = os.path.join(skill_path, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue

        with open(skill_md) as f:
            content = f.read()

        m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
        if not m:
            continue
        front = m.group(1)

        name_m = re.search(r'^name:\s*(.+)$', front, re.MULTILINE)
        desc_m = re.search(r'^description:\s*(.+)$', front, re.MULTILINE)
        if not name_m:
            continue

        skills.append({
            "name": name_m.group(1).strip(),
            "path": f"./skills/{bucket}/{skill_name}",
            "category": bucket,
            "description": desc_m.group(1).strip() if desc_m else "",
        })

manifest = {
    "name": "subagent-skills",
    "version": "1.0.0",
    "description": "Engineering and productivity skills for AI coding assistants.",
    "author": "ThanakritAof",
    "repository": "github:ThanakritAof/subagent-skills",
    "tags": ["engineering", "productivity", "debugging", "code-review", "context-management"],
    "skills": skills,
}

with open(out, "w") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"generated {out}")
PYEOF
