# subagent-skills

Agent skills loaded by Claude Code.

## Layout

Skills live under `skills/`, grouped into buckets:

- `engineering/` — daily code work
- `productivity/` — daily non-code workflow tools
- `misc/` — kept around but rarely used
- `personal/` — tied to my own setup, not promoted
- `in-progress/` — drafts not yet ready to ship
- `deprecated/` — no longer used

Each skill is its own directory containing a `SKILL.md` (with YAML frontmatter — `name` and `description`) and any bundled scripts or reference files.

## Install

### With `npx skills` (Recommended - works for every agent)

```bash
npx skills add ThanakritAof/subagent-skills
```

### Alternative - Bash script

For my own dev loop — symlink every shippable skill into `~/.claude/skills/`:

```bash
./scripts/link-skills.sh
```

List every `SKILL.md` in the repo:

```bash
./scripts/list-skills.sh
```

## Reference

### Engineering

- **[debug-mantra](./skills/engineering/debug-mantra/SKILL.md)** — Four-mantra debugging discipline: reproduce → trace the fail path → falsify the hypothesis → cross-reference every breadcrumb. Recites verbatim at session start, then applies in order before any fix.
- **[post-mortem](./skills/engineering/post-mortem/SKILL.md)** — Write the canonical engineering record of a fixed bug — root cause, mechanism, fix, validation, how it slipped through. Engineer-audience; refuses to draft without a reliable repro, known cause, and validated fix.
- **[scrutinize](./skills/engineering/scrutinize/SKILL.md)** — Outsider-perspective end-to-end review of a plan, PR, or code change. Questions intent (is there a simpler way?), traces the actual code path, and verifies the change does what it claims. Output is concise, actionable, with rationale.
- **[qwen-agent](./skills/engineering/qwen-agent/SKILL.md)** — Delegate menial, well-scoped coding tasks to a cheap Qwen-backed subagent via `claude-subagent --effort ultracode`. Use for bulk renames, formatting, boilerplate, grep-style summarization, scaffolding, and build/test reporting.
- **[qwen-team](./skills/engineering/qwen-team/SKILL.md)** — Premium model decomposes a large task into 2-5 subtasks; each subtask runs a mandatory `claude-subagent` dev pass and a premium-model tester pass (both `--effort ultracode`) in parallel, then loops through premium review until all subtasks are approved.

### Productivity

- **[management-talk](./skills/productivity/management-talk/SKILL.md)** — Rewrite engineer-to-engineer content for engineering-org leadership and shape it for the channel it's going to (JIRA, Slack, async standup, email, meeting talking-points).
- **[qwenchance](./skills/productivity/qwenchance/SKILL.md)** — Keeps a long Claude Code task on-track — breaks loops, bounds internal reasoning, watches the context budget, and triggers a clean handoff before the window fills.

### Misc

_(none yet)_
