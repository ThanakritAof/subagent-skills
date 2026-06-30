---
name: gemini-agent
description: Delegate menial, well-scoped coding tasks to a cheap Gemini Flash subagent via the `agy` command instead of burning Claude tokens/quota. Use when the work is mechanical and low-risk — bulk renames, formatting, boilerplate, find-replace, grep-style search & summarization, reading/condensing logs or files, test/docstring/comment scaffolding, or running builds/linters/tests and reporting pass-fail. Also use when the user says "use gemini", "use agy", "delegate this to gemini", or "do this cheaply with gemini". Do NOT use for architecture, design, debugging judgment, security-sensitive edits, or anything needing this conversation's context.
---

# gemini-agent

Offload **menial, self-contained** tasks to a Gemini 3.5 Flash model running inside a headless Antigravity instance (`agy`). Keeps expensive Claude reasoning for work that needs it.

## The command

`agy` is the Antigravity CLI at `~/.local/bin/agy`. Run it headless with `-p`:

```bash
agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "<self-contained task prompt>"
```

- **This is the default invocation.** `Gemini 3.5 Flash (Medium)` is the cheap workhorse model — fast and low-cost for menial work.
- `--dangerously-skip-permissions` auto-approves all tool permission requests so the subagent can finish unattended. Without it the subagent stalls waiting for approval on the first edit or command.
- For higher reasoning on a delegated task, step up to `Gemini 3.5 Flash (High)`.

## Writing the task prompt (most important step)

The agy subagent has **zero** context from this conversation. A vague prompt is the #1 failure mode. Every prompt must be standalone:

- **Absolute paths** for every input and output file (`/Users/user/proj/src/foo.ts`, not `foo.ts`).
- **Explicit inputs, outputs, and acceptance criteria** — what to change, what "done" looks like.
- **No references** to "the file we discussed", "above", or prior turns.
- Treat it as a capable-but-literal junior: spell out the steps, keep scope tight.

Bad: `clean up the imports`
Good: `In /Users/user/proj/src/api.ts, remove unused imports and sort the remaining import statements alphabetically. Do not change any other code. Confirm the file still parses.`

## Context window

Gemini 3.5 Flash runs with a **large context window (~1M tokens)** — far larger than Qwen's 128k. Most single-file or directory-scoped tasks will fit comfortably. Still, scope each task to what it actually needs:

- Point it at the exact files required; never tell it to "scan the entire repo".
- For very large codebases or tasks pulling in hundreds of files, still split into bounded chunks for reliability and faster turnaround.

## Working directory

Don't rely on cwd — it may not match your project root:

- Put **absolute paths in the prompt**, or
- Pass `--add-dir /abs/path` to explicitly grant the subagent access to a directory.

## Return contract

- **Default (text):** agy's final message prints to stdout — read it directly.
- **Background / parallel (run several at once):** redirect to a log and run with the Bash tool's `run_in_background: true`, then read the log when it finishes:

  ```bash
  agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "<task>" > /tmp/ag-<label>.log 2>&1
  ```

  Launch independent tasks as separate background runs; collect each log on completion. Use this when delegating 2+ unrelated menial jobs.

## Workflow checklist

1. Confirm the task is menial and low-risk (see description). If it needs design judgment or this chat's context, **do it yourself** — don't delegate.
2. Write a fully self-contained prompt with absolute paths and acceptance criteria.
3. Run `agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "..."` (foreground), or background-redirect for parallel jobs.
4. **Verify the output yourself** — Gemini Flash is cheaper and less reliable for nuanced work. Check the file/result actually meets the acceptance criteria before reporting success.

## One-time setup (optional, removes repeated prompts)

To stop per-call permission prompts when running `agy` from within Claude Code, add a Bash allow rule (via the `update-config` skill, or by editing settings):

```json
{ "permissions": { "allow": ["Bash(agy:*)"] } }
```

## When NOT to delegate

Architecture/design, debugging that needs reasoning, security-sensitive changes, anything requiring this conversation's context, or tasks where a wrong cheap-model edit is costly to catch. When in doubt, keep it.
