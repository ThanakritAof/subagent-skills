---
name: gemini-team
description: Have a premium model decompose a large task into subtasks, assign each subtask to a paired Gemini Flash dev and premium tester via `agy`, then orchestrate review, integration, and feedback loops until the full task meets acceptance criteria. Use when the user asks for "gemini team", "agy team", "gemini dev and tester", "split this across gemini", or when a broad task needs cheap parallel implementation/testing with premium-model orchestration. Do not use for small single-worker delegation; use gemini-agent instead.
---

# Gemini Team

## Overview

Use Gemini Flash as cheap dev capacity, not as the final authority. The premium model decomposes the large task into subtasks, gives each subtask an `gemini-dev` (Gemini Flash) and `gemini-tester` (premium model), then reviews, integrates, and controls the feedback loop.

## Prerequisites

Confirm `agy` is installed and authenticated before decomposing anything: `which agy` and `agy models`. If either fails, stop and fix setup — don't discover it mid-rollout after subtasks are already launched.

## Use Criteria

Use this workflow only when all of these are true:

- The work is substantial enough to split into 2-5 subtasks.
- Each subtask is substantial enough to justify both an implementation pass and an independent test/review pass.
- Each dev task and tester task can be described with absolute paths, explicit inputs, outputs, and acceptance criteria.
- A wrong Gemini result is easy for the premium reviewer or main agent to catch.
- The feedback loop is worth the extra orchestration cost.

Do not use this workflow for:

- One-file mechanical edits that fit `gemini-agent`.
- Architecture, security-sensitive changes, production operations, or destructive actions.
- Debugging before a reliable repro exists and the fail path is known.
- Tasks where workers need hidden conversation context to succeed.
- Tasks where no meaningful independent tester role exists.

As a concrete threshold: if the whole task touches roughly 3 files or fewer, or one worker could finish it solo in under ~15 minutes, do it directly. The dev + tester + reviewer orchestration overhead usually costs more than it saves at that scale — reserve this workflow for work that genuinely needs 2-5 independently-testable subtasks.

## Before Running Unattended

Parallel/background `agy` runs with `--dangerously-skip-permissions` (steps 4-5 below) form an unsandboxed autonomous loop with no per-action approval gate. Claude Code's auto-mode permission classifier can — and in testing did — block this outright ("unsandboxed autonomous loop, no per-action approval gate"), even with `Bash(agy:*)` allow-listed. Before launching parallel/background dev or tester runs, tell the user what's about to run and get explicit confirmation that unattended execution is OK, rather than firing the commands and finding out from the block.

## Roles

### Main Agent

Frame the task, choose whether team mode is justified, decompose the work into subtasks, define success for each subtask and the whole task, launch subagents, inspect outputs, apply or reject edits, run verification, and report honestly. Never claim an external premium reviewer approved the work unless that reviewer actually ran.

### AG Dev (Gemini Flash)

Use one `gemini-dev` per active subtask. The dev receives a self-contained prompt with the repository path, subtask goal, allowed files, forbidden files/actions, acceptance criteria, and requested output. The dev may edit files only inside its allowed scope.

Command pattern:

```bash
agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "<self-contained dev prompt>"
```

### AG Tester (Premium)

Use one `gemini-tester` per active subtask — always a **premium model**, not Gemini Flash. The tester needs judgment to catch issues the cheap dev would miss. Use `Claude Sonnet 4.6 (Thinking)`, `Claude Opus 4.6 (Thinking)`, or let the main agent perform the test review directly.

Command pattern (via agy):

```bash
agy --model "Claude Sonnet 4.6 (Thinking)" --dangerously-skip-permissions -p "<self-contained tester prompt>"
```

Or if the main agent is already premium, have it perform the tester review directly and label it as internal review.

### Premium Reviewer

Use the main orchestrating agent or `agy --model "Claude Opus 4.6 (Thinking)"` as the final reviewer. If no external premium model is available, the main agent performs this review and states so explicitly.

## Workflow

### 1. Verify a Safety Net Exists

Before launching any `gemini-dev`, confirm the repository has a rollback path:

- Check whether the target is a git repo (e.g. `git -C <repo> rev-parse --is-inside-work-tree`).
- If it is a git repo, note whether the working tree is already dirty so the final `git diff` review (step 9) is meaningful.
- If it is **not** a git repo, back up every file or directory listed in each subtask's "Allowed files or directories" (e.g. copy to a scratch location) before that subtask's dev pass starts. Do not let `gemini-dev` touch ungoverned files with no way to diff or roll back.

### 2. Decompose the Task

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

### 3. Create Dev and Tester Prompts

For both prompts, define:

- Inputs: absolute paths, commands, logs, or artifacts.
- Subtask id and goal.
- Output: changed files, test report, risk list, or recommendation.
- Acceptance criteria: what must be true for the subtask to count.
- Boundaries: files, directories, commands, or systems the worker must not touch.

### 4. Run AG Dev Per Subtask

**You MUST invoke `agy` for every dev subtask. Do not implement the subtask yourself.**

Run each dev subtask via the **gemini-agent** skill using this exact command pattern:

```bash
agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "<self-contained dev prompt>"
```

For background / parallel (independent subtasks run at the same time), redirect to a log in your scratch/temp directory — not a hardcoded `/tmp` path (Claude Code provides a session scratchpad directory for this):

```bash
agy --model "Gemini 3.5 Flash (Medium)" --dangerously-skip-permissions -p "<dev prompt>" > <scratch-dir>/ag-subtask-<id>.log 2>&1
```

Launch all independent subtasks as parallel background runs. Follow gemini-agent's rules for scoping the prompt to bounded files/dirs.

If a subtask returns an API error, empty result, or timeout, retry it up to 2 times before marking it FAILED. Report FAILED subtasks to the premium reviewer — do not silently skip them.

Dev prompt shape:

```text
You are gemini-dev in a Gemini dev/test pair.
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

### 5. Run AG Tester Per Subtask

Delegate each tester subtask to a **premium model** after the matching dev pass completes. Run via `agy --model "Claude Sonnet 4.6 (Thinking)"` or have the main agent review directly. Give the tester the original request, subtask acceptance criteria, relevant files, changed-file list, and any commands the dev ran.

Apply the same retry rule as step 4: up to 2 retries on API error / empty result / timeout, then mark FAILED and report to the reviewer.

Tester prompt shape:

```text
You are the tester for this subtask. You are a premium model — be thorough.
Repository: /absolute/path
Original user request: ...
Overall goal: ...
Subtask id: ...
Subtask acceptance criteria: ...
Changed files or diff summary from gemini-dev: ...
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

### 6. Premium Review and Orchestration

Once all parallel subtasks have a dev+test result, build a single reviewer packet:

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

Send the packet to the premium reviewer. If using agy: `agy --model "Claude Opus 4.6 (Thinking)" --dangerously-skip-permissions -p "<reviewer packet>"`. If no external reviewer is available, the main agent reviews directly and labels it as internal review.

Reviewer evaluates both dev and tester output per subtask:

- Dev review: diff within allowed scope, output matches acceptance criteria, no unsafe changes.
- Tester review: all 3 case groups covered and actually tested (not just claimed), defects reproducible, missing coverage flagged.

If the tester's work is shallow (missing case groups, no real verification), treat it as `CHANGES_REQUIRED` on the tester before judging the dev.

Reviewer decision rules per subtask:

- `APPROVE`: both dev and tester passed. Mark subtask done, exclude from next round.
- `CHANGES_REQUIRED`: queue the subtask for rework — specify whether dev, tester, or both need changes.
- `REJECT`: stop that subtask, explain, redesign or ask the user.

### 7. Feedback Loop

```text
decompose
    │
    └── [all subtasks] gemini-dev → gemini-tester ── parallel
                │
        premium review (all results at once)
                │
        route back ONLY failed subtasks
                │
        [failed subtasks] gemini-dev rework → gemini-tester ── parallel
                │
        premium review (failed subtasks only)
                │
        repeat until all APPROVE
                │
        integration review
```

Only subtasks that received `CHANGES_REQUIRED` re-enter the dev → test cycle each round. Approved subtasks are frozen. After 3 failed rounds on the same subtask, stop and have the main agent take over or ask the user for a sharper requirement.

Each rework prompt must include:

- The original request and acceptance criteria.
- The subtask id and subtask acceptance criteria.
- The current diff or changed-file list.
- The premium reviewer's exact requested changes.
- The tester's failing evidence and good/normal/bad case results.
- What files may be touched in the rework.

### 8. Integration Review

After all subtasks are individually approved, the premium reviewer must review the combined result:

```text
Original request: ...
Subtasks approved: ...
Combined diff summary: ...
Cross-subtask risks: ...
Tests run: ...
Decision requested: APPROVE, CHANGES_REQUIRED, or REJECT for the full task.
```

If integration review returns `CHANGES_REQUIRED`, assign the fix to a targeted `gemini-dev` subtask and rerun the matching tester. If it returns `REJECT`, stop and redesign.

### 9. Main Agent Verification

Run the relevant tests, linters, build, or manual checks yourself. If step 1 found a git repo, review `git diff` before final response; if not, diff against the backup taken in step 1. Remove temporary artifacts unless they are intentional deliverables.

## Output Rules

In the final response, include:

- How the premium model decomposed the task.
- What `gemini-dev` implemented.
- What `gemini-tester` checked and found, including good/normal/bad case results.
- Whether a premium reviewer actually ran, which model it was, and its decision.
- How many feedback rounds were needed.
- Verification commands and results.
- Remaining risks or follow-ups.

Never say "approved by Claude/Gemini" unless that model actually reviewed the packet. Never hide worker failures; summarize the failure and how it was handled.
