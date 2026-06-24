---
name: qwen-team
description: Have a premium model such as Claude, Codex, Gemini, or the current agent decompose a large task into subtasks, assign each subtask to paired Qwen-backed dev and tester subagents, then orchestrate review, integration, and feedback loops until the full task meets acceptance criteria. Use when the user asks for "qwen team", "qwen dev and tester", "split this across qwen", "use qwen as a team", or when a broad task needs cheap parallel implementation/testing with premium-model orchestration. Do not use for small single-worker delegation; use qwen-agent instead.
---

# Qwen Team

## Overview

Use Qwen as cheap dev/test capacity, not as the final authority. The premium model decomposes the large task into subtasks, gives each subtask a `qwen-dev` and `qwen-tester`, then reviews, integrates, and controls the feedback loop.

## Use Criteria

Use this workflow only when all of these are true:

- The work is substantial enough to split into 2-5 subtasks.
- Each subtask is substantial enough to justify both an implementation pass and an independent test/review pass.
- Each dev task and tester task can be described with absolute paths, explicit inputs, outputs, and acceptance criteria.
- A wrong Qwen result is easy for the premium reviewer or main agent to catch.
- The feedback loop is worth the extra orchestration cost.

Do not use this workflow for:

- One-file mechanical edits that fit `qwen-agent`.
- Architecture, security-sensitive changes, production operations, or destructive actions.
- Debugging before a reliable repro exists and the fail path is known.
- Tasks where workers need hidden conversation context to succeed.
- Tasks where no meaningful independent tester role exists.

## Roles

### Main Agent

Frame the task, choose whether team mode is justified, decompose the work into subtasks, define success for each subtask and the whole task, launch subagents, inspect outputs, apply or reject edits, run verification, and report honestly. Never claim an external premium reviewer approved the work unless that reviewer actually ran.

### Qwen Dev

Use one `qwen-dev` per active subtask. The dev receives a self-contained prompt with the repository path, subtask goal, allowed files, forbidden files/actions, acceptance criteria, and requested output. The dev may edit files only inside its allowed scope.

### Qwen Tester

Use one `qwen-tester` per active subtask. The tester receives the original request, subtask acceptance criteria, relevant paths, and the dev's changed-file list or diff summary. The tester must cover three case groups: good case, normal case, and bad case. Prefer giving the tester read/test permissions first; allow test edits only when the task explicitly includes adding or fixing tests.

### Premium Reviewer

Use Claude, Codex, Gemini, or the current stronger model as the orchestrator, feedback controller, integrator, and final reviewer. Prefer the reviewer the user requested. If no external premium model CLI/tool is available, have the main agent perform this review and state that no external reviewer was run.

The premium reviewer receives the original request, subtask plan, dev outputs, tester outputs, diffs, verification logs, and unresolved risks. It must return one of: `APPROVE`, `CHANGES_REQUIRED`, or `REJECT`, plus concrete feedback when changes are required.

## Workflow

### 1. Decompose the Task

State the overall goal in one sentence. The premium model then splits the work into 2-5 subtasks. Each subtask must have a clear boundary, owner label, acceptance criteria, and integration notes.

Subtask shape:

```text
Subtask id: subtask-a
Goal: ...
Inputs: ...
Allowed files or directories: ...
Forbidden files or actions: ...
Acceptance criteria: ...
Dependencies: independent | after subtask-b | before subtask-c
Integration notes: ...
```

Prefer parallel subtasks when file ownership does not overlap. If subtasks touch the same files or depend on each other, serialize them.

### 2. Create Dev and Tester Prompts

For both prompts, define:

- Inputs: absolute paths, commands, logs, or artifacts.
- Subtask id and goal.
- Output: changed files, test report, risk list, or recommendation.
- Acceptance criteria: what must be true for the subtask to count.
- Boundaries: files, directories, commands, or systems the worker must not touch.

### 3. Run Qwen Dev Per Subtask

**You MUST invoke `claude-subagent` for every dev subtask. Do not implement the subtask yourself.**

Run each dev subtask via the **qwen-agent** skill using this exact command pattern:

```bash
claude-subagent --effort ultracode -p "<self-contained dev prompt>" --allowedTools Bash Read Edit Write Glob Grep
```

For background / parallel (independent subtasks run at the same time):

```bash
claude-subagent --effort ultracode -p "<dev prompt>" --allowedTools Bash Read Edit Write Glob Grep > /tmp/qwen-subtask-<id>.log 2>&1
```

Launch all independent subtasks as parallel background runs. Follow qwen-agent's rules for context window sizing (128k limit — scope the prompt to bounded files/dirs only).

If a subtask returns an API error, empty result, or timeout, retry it up to 2 times before marking it FAILED. Report FAILED subtasks to the premium reviewer — do not silently skip them. The reviewer decides whether to skip, redesign, or escalate.

Dev prompt shape:

```text
You are qwen-dev in a Qwen dev/test pair.
Repository: /absolute/path
Original user request: ...
Overall goal: ...
Subtask id: ...
Subtask goal: ...
Task: implement this subtask only.
Allowed files or directories: ...
Forbidden files or actions: ...
Acceptance criteria: ...
Return: changed files, diff summary, commands run, results, risks, and follow-up needed.
Do not rely on prior conversation context.
```

Inspect each dev's diff before testing. If a dev edited outside scope, touched files owned by another active subtask, or made unsafe changes, reject that pass and either rerun with narrower instructions or take over directly.

### 4. Run Qwen Tester Per Subtask

Delegate each tester subtask to a **premium model** (Claude, Codex, or Gemini — not Qwen), after the matching dev pass completes. The tester needs judgment to catch issues that a cheap model would miss. Run with `--effort ultracode` to maximise test thoroughness. Give the tester the original request, subtask acceptance criteria, relevant files, changed-file list, and any commands the dev ran.

Apply the same retry rule as step 3: up to 2 retries on API error / empty result / timeout, then mark FAILED and report to the reviewer.

Tester prompt shape:

```text
You are the tester for this subtask. You are a premium model — be thorough.
Repository: /absolute/path
Original user request: ...
Overall goal: ...
Subtask id: ...
Subtask acceptance criteria: ...
Changed files or diff summary from qwen-dev: ...
Task: independently test and review whether the implementation satisfies this subtask and does not break the overall task.
Inputs: ...
Allowed files or directories: ...
Forbidden files or actions: ...
Required test coverage:
- Good case: the best/ideal or high-value path succeeds.
- Normal case: the common everyday path succeeds.
- Bad case: invalid, empty, failing, edge, or misuse input behaves correctly.
Return: commands run, pass/fail results for all three case groups, defects found, missing coverage, and recommended fixes.
Do not rely on prior conversation context.
```

Prefer a tester that runs tests and reports defects without editing implementation files. If one of the three case groups is not applicable, the tester must say why and propose the closest equivalent. If the tester adds tests, inspect those diffs separately.

### 5. Premium Review and Orchestration

Once all parallel subtasks have a dev+test result, build a single reviewer packet covering all subtasks in this round:

```text
Original request: ...
Repository: /absolute/path
Overall goal: ...
Overall acceptance criteria: ...
Subtask plan: ...
Results per subtask:
  subtask-1: dev output / tester output / case coverage / diff summary
  subtask-2: dev output / tester output / case coverage / diff summary
  ...
Known risks or unverified areas: ...
Decision requested per subtask: APPROVE, CHANGES_REQUIRED, or REJECT with reasons.
```

Send the packet to the requested premium reviewer if available. Check availability before invoking a CLI such as `claude`, `codex`, or `gemini`; do not invent a review. If no external reviewer is available, the main agent performs this review directly and labels it as internal review.

The reviewer evaluates **both** dev and tester output for every subtask.

Dev review — check the implementation:

- Diff stays within allowed scope.
- Output matches the acceptance criteria.
- No unsafe or out-of-scope changes.

Tester review — scrutinize harder:

- All 3 case groups covered (good / normal / bad) — not just claimed, actually tested.
- Tests are independent: the tester verified behavior, not just repeated what the dev did.
- Reported defects are reproducible with concrete evidence, not guesses.
- Missing coverage is flagged explicitly.

If the tester's work is weak (shallow tests, missing case groups, no real verification), treat it as `CHANGES_REQUIRED` on the tester — rerun the tester with stricter instructions before judging the dev's output.

Reviewer decision rules per subtask:

- `APPROVE`: both dev and tester passed review. Mark the subtask done. Exclude it from the next round.
- `CHANGES_REQUIRED`: queue the subtask for rework — specify whether the issue is with the dev, the tester, or both.
- `REJECT`: stop that subtask, explain the rejection, and redesign or ask the user for direction.

### 6. Feedback Loop

```text
decompose
    │
    └── [all subtasks] dev → test ── parallel
                │
        premium review (all results at once)
                │
        route back ONLY failed subtasks
                │
        [failed subtasks] dev rework → test ── parallel
                │
        premium review (failed subtasks only)
                │
        repeat until all APPROVE
                │
        integration review
```

Each round, only subtasks that received `CHANGES_REQUIRED` re-enter the dev → test cycle. Approved subtasks are frozen. To avoid blind spinning, after 3 failed rounds on the same subtask, stop and have the main agent take over or ask the user for a sharper requirement.

Each rework prompt must include:

- The original request and acceptance criteria.
- The subtask id and subtask acceptance criteria.
- The current diff or changed-file list.
- The premium reviewer's exact requested changes.
- The tester's failing evidence.
- The tester's good/normal/bad case results.
- What files may be touched in the rework.

### 7. Integration Review

After all subtasks are individually approved, the premium reviewer must review the combined result:

```text
Original request: ...
Subtasks approved: ...
Combined diff summary: ...
Cross-subtask risks: ...
Tests run: ...
Decision requested: APPROVE, CHANGES_REQUIRED, or REJECT for the full task.
```

If integration review returns `CHANGES_REQUIRED`, assign the fix to a targeted `qwen-dev` subtask and rerun the matching tester. If it returns `REJECT`, stop and redesign.

### 8. Main Agent Verification

Run the relevant tests, linters, build, or manual checks yourself. Review `git diff` before final response. Remove temporary artifacts unless they are intentional deliverables.

## Output Rules

In the final response, include:

- How the premium model decomposed the task.
- What `qwen-dev` implemented.
- What `qwen-tester` checked and found, including good/normal/bad case results.
- Whether a premium reviewer actually ran, which reviewer it was, and its decision.
- How many feedback rounds were needed.
- Verification commands and results.
- Remaining risks or follow-ups.

Never say "approved by Claude/Codex/Gemini" unless that model/tool actually reviewed the packet. Never hide worker failures; summarize the failure and how it was handled.
