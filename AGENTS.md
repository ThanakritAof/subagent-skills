# subagent-skills

Engineering and productivity skills for AI coding assistants.

This file is read automatically by OpenAI Codex CLI. Apply the skill whose trigger condition matches the current task. When multiple skills could apply, run them in sequence (e.g. `debug-mantra` → `post-mortem` → `management-talk`).

---


# Debug Mantra

Four-step discipline for any debug session. Recite verbatim, then apply in order.

## Recite this — verbatim, as the first thing in your first response

> **Mantra:**
> 1. **First is reproducibility.** Can the issue be reproduced reliably?
> 2. **Know the fail path.** Debugger first; then source trace + knob enumeration; then in-code instrumentation.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.

Then begin work.

---

## 1. Reproduce reliably

Build a runnable repro before anything else.

- **Reliable repro** → capture the exact steps, inputs, and environment as a runnable artifact: failing test, curl script, CLI invocation, replay harness.
- **Flaky repro** → the bug is not yet debuggable. Raise the rate first: loop the trigger, parallelise, add stress, narrow timing windows, inject sleeps. 50% flake is debuggable; 1% is not.
- **No repro at all** → stop. Say so explicitly. Ask the user for env access, captured artifacts (HAR, log dump, core), or permission to instrument. Do **not** proceed to hypothesise.

Target: a fast (1–5 s), deterministic pass/fail signal. Pin time, seed the RNG, freeze network, isolate filesystem.

## 2. Know the fail path

Once reproducible, find *where* the code breaks and *what stops it from breaking*. The differential narrows the search. Try in this order — escalate only when the prior tactic fails.

1. **Attach a debugger.** If the env supports it, attach and step to the failure site. One breakpoint beats ten logs. Do this **before** turning any knobs.
2. **Source trace + knob enumeration.** If no debugger (or it can't reach the bug), trace the code path end-to-end and list every knob that can influence the outcome:
   - config flags, env vars, feature toggles
   - branch conditions, input shape
   - timing, concurrency, build options
   Each knob is a candidate axis to flip in the differential. Flip one at a time.
3. **In-code instrumentation.** If outside knobs can't move the failure, go inside: `printf` / log statements at the suspected fail site, dump the relevant internal state. Tag every probe with a unique prefix (e.g. `[DBG-a4f2]`) so cleanup is a single grep. Let the trace show where reality diverges from your model.

## 3. Falsify the hypothesis

When a candidate root cause surfaces, scrutinise it **before** testing it.

- Does it actually explain the symptom end-to-end? Walk it through.
- What is the simplest **proof**? What is the cleanest **disproof**?
- Run the **disproof first**. If the hypothesis survives, it's real. If it dies, you saved yourself from chasing a phantom.
- Generate 3–5 ranked hypotheses, not one. Single-hypothesis thinking anchors on the first plausible idea.

## 4. Every run is a breadcrumb

Maintain a running **ledger** of every experiment in this session. Each entry: what changed, what happened, what it ruled in or out.

- When a new hypothesis surfaces, walk the ledger. Does it hold for **every** prior observation, not just the most recent?
- If any past run contradicts it, the hypothesis is wrong or incomplete — refine or discard.
- When in doubt, design the **single experiment** whose outcome makes it certain. Run that next, instead of churning on adjacent runs.
- Update the ledger after every run. It is your memory across the session.

---

## Operating rules

- Recite the mantra block **once** per debug session, in your first response. Do not re-recite mid-session.
- Recite **verbatim**. Never paraphrase, shorten, or skip lines of the recital.
- If the user says "skip the mantra" → skip the recital but still apply the four steps silently.
- Apply the four steps **in order**:
  - Do not propose a fix before #1 is satisfied (reliable repro exists).
  - Do not start testing hypotheses before #2 has narrowed the fail path.
  - Do not commit to a hypothesis before #3 has tried to disprove it.
  - Do not declare a hypothesis correct until #4 confirms it against every prior breadcrumb.
- If you catch yourself proposing a fix without a reliable repro, stop and return to step 1.
- The mantra is a constraint **you** carry through the session — not advice to deliver back to the user.

---


# Post-mortem

The canonical engineering record of a bug fix. Written **after** debugging lands a real fix, **for** other engineers (and future-you, who will have forgotten everything in 6 months). Code identifiers are welcome here — this is the artifact that lets the next person recover the mental model fast.

For the up-the-org version of this same content, hand the finished post-mortem to [`management-talk`](../../productivity/management-talk/SKILL.md). They compose: post-mortem owns the engineering truth, management-talk reframes it for leadership.

## When to invoke

- "/post-mortem"
- "write the post-mortem / postmortem / RCA / root-cause analysis"
- "document this fix" / "write up the root cause" / "close out this bug with a writeup"
- After a debug session has clearly landed a fix, proactively offer to draft one.

## When NOT to use

- **Bug not fixed yet, or fix not validated.** A post-mortem of a hypothesis is misleading. Refuse and tell the user what's missing.
- **Customer-visible outage / incident.** Those need a separate incident report (timeline, blast radius, paging history, comms). This skill is bug-fix scope. Flag and confirm before producing one.
- **Trivial fix** (typo, obvious one-liner). The PR description is the record. Don't manufacture ceremony.

## Required inputs — refuse to draft without these

Before writing a single line, confirm all four. If any are missing, list what's missing and stop:

- [ ] **Reliable repro** exists (not "happens sometimes" — a deterministic or high-rate-flake repro the next person can run).
- [ ] **Root cause is known** (the mechanism is identified, not a hypothesis).
- [ ] **Fix is identified** (PR / commit / branch pointer).
- [ ] **Fix is validated** (the original repro now passes; the customer workload / failing test now succeeds).

These map directly to `debug-mantra` steps 1–4. If you came in via `debug-mantra`, the breadcrumb ledger from step 4 is your raw material — pull from it.

## Structure

Use these blocks in this order. **Summary, Root cause, Fix, and Validation are mandatory.** The rest are conditional but usually present.

### 1. Summary _(mandatory)_
One paragraph. What broke, in user/workload terms. What fixed it, in one sentence. JIRA key, PR number, owner. A reader who stops here should have the right answer.

### 2. Symptom
What was actually observed. Test output, error message, log line, perf number, customer report. Concrete identifiers — don't paraphrase the failure mode.

### 3. Root cause _(mandatory)_
The actual bug mechanism. **Code identifiers welcome and expected** — function names, file paths, struct fields, branch conditions, commit SHAs of the offending change. Walk the cause chain end-to-end. This is the most expensive section and the reason the post-mortem exists at all. Future-you will live or die by how clearly you write this.

### 4. Why it produced the symptom
Link the root cause to the symptom. Often non-obvious — the bug is in `tadaLaunchPrepare` but the visible failure is a customer training run hanging hours later. Walk the chain so a reader who only knows the symptom can connect it back to the cause without re-deriving it.

### 5. Fix _(mandatory)_
What changed and **why this change addresses the root cause** rather than hiding the symptom. Link to PR / commit. If a previous fix attempt papered over the symptom, name it and explain what was wrong with it — that history is part of the cause.

### 6. How it was found
Short. The debugging path:
- What repro made it deterministic.
- What tools cracked it (debugger, source tracing, knob enumeration, in-code instrumentation — the `debug-mantra` step 2 cascade).
- Hypotheses tried and rejected, with the one-line reason each was rejected. (Pull from the breadcrumb ledger.)
- The single experiment that confirmed the cause.

This section is for the next debugger — make it learnable.

### 7. Why it slipped through
What allowed this bug to reach the branch / release / customer. Pick the real reason:
- CI gap (no test exercises this path / configuration).
- Latent code (correct when written, broken by a later change in a different file).
- Workload gap (no real workload reached this code path until now).
- Incomplete prior fix (defensive check hid the symptom; root cause untouched).
- Review miss (the change was reviewable; the implication wasn't).

If the honest answer is "no good reason — we should have caught this," say so. **Blameless** — describe the gap, not the person.

### 8. Validation _(mandatory)_
How we know the fix works. Concrete:
- Original failing test now passes (test name, link).
- Customer workload now completes (workload identifier, run link).
- Perf regression resolved (number before, number after).
- Stress / soak / fuzz run completed clean (duration, scale).
- Other affected configurations / workloads also tested.

If you only validated one configuration, say so explicitly — *"validated on Llama-2-70B / 8 GPUs / DeepSpeed; not retested on other workloads."* Don't imply broader coverage than you actually have.

### 9. Action items / follow-ups
Concrete next-steps that aren't in the fix PR itself. Each item: what + owner + tracking artifact.

- Regression test added at \<seam\>. (Owner, test name.)
- Refactor to prevent class of bug. (Owner, ticket.)
- CI gap closed: \<new check\>. (Owner, PR.)
- Doc / runbook updated. (Owner, link.)
- Related ticket filed for \<adjacent issue you noticed\>. (Owner, key.)

If there are no action items, write *"None — the fix is sufficient and no class-of-bug follow-up is warranted."* Don't manufacture action items to look thorough.

## Tone

This is engineer-to-engineer. Different from `management-talk`:

- **Code identifiers are first-class.** `tadaLaunchPrepare`, `tada/prim.h::syncWaitPeer`, `scratchBuf`, commit SHAs, line numbers — keep them. The whole point is that future engineers can grep their way back to the change.
- **Mechanism over narrative.** Walk the actual cause chain. Don't soften it into "a synchronization issue" — say which function skipped which event under which gate.
- **Active voice, concrete subjects, short paragraphs.** Same rule as everywhere else.
- **No hedging.** "We believe" / "appears to" / "may have" — drop. State it or don't write it.
- **Blameless.** Describe the bug, the gap, and the fix. Never "X should have caught this." The CI gap is the failure mode, not the person.
- **No advocacy.** A post-mortem records what happened and what's next. If you want to argue for a refactor, that's a separate proposal — link to it from the action items.

## Output flow

1. **Confirm all four required inputs are satisfied.** If any are missing, list them and stop. Do not draft.
2. **Confirm where it goes** (default: JIRA comment on the source ticket). Other valid destinations: PR description, `docs/postmortems/<ticket>.md`, internal wiki page. The shape is the same — only the wrapping changes.
3. **Produce the draft** as a single chat block.
4. **Sign-off before posting.** If posting back to JIRA, show the exact ADF payload, wait for explicit *"post it"* / *"go ahead"* / *"yes,"* then `POST /rest/api/3/issue/<KEY>/comment`. Print-only output needs no approval.
5. **Offer the management-talk handoff:** *"Want a leadership-flavored version? I can hand this to `management-talk`."* Don't do it automatically.

## Worked example — Tada hang in dumbModel (JIRA-12345)

> **Summary.** Tada's single-stream fast-path skipped a required cross-stream synchronization, causing kernels to launch before scratch-buffer writes were visible. Triggered reliably by dumbModel on LLM-7B fine-tuning, hanging the workload at every eval step. Fixed by removing the unsafe fast-path and tightening a device-side check. JIRA-12345, PR org/platform#5751, owner Alex (Tada team).
>
> **Symptom.** 8-GPU LLM-7B fine-tuning under dumbModel hung indefinitely at the first eval step. No error, no timeout — busy-spin in `tadaKernel_AllReduce_f32_RING`. Reproduced on every run.
>
> **Root cause.** The single-stream fast-path in `tadaLaunchPrepare` / `tadaLaunchKernel` / `tadaLaunchFinish` (gated on `scheduler->numStreams == 1 && !plan->persistent`) skipped the cross-stream event between `launchStream` and `handle->shared->deviceStream`. dumbModel hits this gate exactly. The kernel was launched before the IPC publish / scratch-buffer writes on `deviceStream` (which populate `scratchBuf`) were visible to `launchStream`. In the kernel: `scratchBuf == NULL` → stray pointer dereference → ring ready-flag read from garbage memory → thread spins forever waiting for a ready signal that will never arrive.
>
> **Why it produced the symptom.** The hang lives in the all-reduce ring waitloop, which is the last visible thing in the call stack — but the actual bug is at launch-prep, several frames earlier. The skipped sync is silent until a workload triggers the exact gate (single-stream, non-persistent), and dumbModel's reduce-scatter pattern hits it at every eval step.
>
> **Fix.** PR #5751 removes the single-stream fast-path entirely (the saving was negligible vs. the safety it bypassed) and adds a device-side null check on `scratchBuf` before dereference, so the same class of bug fails loudly instead of silently spinning. A previous attempt (PR #5612) added a host-side defensive check after IPC publish that hid the symptom in some paths but left the underlying race in place — that change is also reverted.
>
> **How it was found.** Reproducer narrowed from "8-GPU LLM-7B hangs sometimes" to a deterministic 30s repro by pinning to a single eval step on a 2-GPU subset. Initial hypothesis: kernel launch ordering on `launchStream`. Disproved by the debugger — the kernel was correctly enqueued. Second hypothesis: scratch-buffer init race. Confirmed by adding `[DBG-7af3]` instrumentation in `tadaLaunchPrepare` printing `scratchBuf` and a `deviceStream` event-record timestamp; the launch happened before the publish completed. Single experiment that nailed it: forcing `numStreams = 2` made the bug disappear, isolating the gate.
>
> **Why it slipped through.** Latent code path. The single-stream fast-path was added in March under the assumption that dumbModel paths always took the multi-stream route. That assumption was true at the time. A May change to dumbModel's launcher began collapsing eval steps to a single stream — at which point the gate flipped. Tada's CI did not exercise the single-stream + IPC + scratch-buffer combination; the customer workload was the first to hit it.
>
> **Validation.** Original LLM-7B / 8-GPU / dumbModel workload now completes a full eval pass cleanly (3 consecutive 2-hour runs). `tada-tests` `all_reduce_perf` regression suite green. Soak run: 6 hours on 8 GPUs, no hang. Not retested on other model sizes or non-dumbModel workloads — both go through the multi-stream path and were never affected.
>
> **Action items.**
> - Regression test added: `tests/single_stream_ipc_publish_test.cpp` exercising the previously-uncovered gate. (Alex, merged in PR #5751.)
> - CI gap: add a single-stream + IPC matrix entry to nightly. (Alex, JIRA-12346.)
> - Doc update: Tada launch-fast-path invariants documented in `docs/launch_synchronization.md`. (Alex, PR #5752.)
> - Related: audit other `numStreams == 1` fast-paths for the same class of bug. (Filed as JIRA-12347.)

What this post-mortem does that the management-talk version didn't:

- Names every code identifier (`tadaLaunchPrepare`, `scratchBuf`, `numStreams`, `handle->shared->deviceStream`).
- Walks the cause chain end-to-end so the reader can grep their way to the offending lines.
- Names the *prior fix attempt* (PR #5612) and what was wrong with it.
- Documents the *exact experiment* that nailed the cause (`numStreams = 2` made it disappear).
- States validation coverage honestly — "not retested on other model sizes" is information, not a hole.
- Action items have owners and tracking artifacts.

## Rules

- **Refuse to draft without all four required inputs.** A post-mortem of a hypothesis is worse than no post-mortem.
- **Never invent root cause, owner, validation runs, or action items.** If a section's facts aren't there, ask. Don't fill the gap with plausible prose.
- **Never strip code identifiers** in the engineering record. They are the index. The leadership reframe is `management-talk`'s job, not yours.
- **Blameless.** Describe gaps and bugs, never people.
- **State validation coverage honestly.** If you only tested one config, say so. Implying broader coverage is the failure mode that breeds repeat regressions.
- **Get sign-off before posting to JIRA.** Print-only output needs no approval. Never post to non-JIRA destinations from this skill.
- **One iteration is normal, three is a smell.** If the user is still revising on the third pass, ask what specific section is wrong — don't keep tweaking blindly.

---


# qwen-agent

Offload **menial, self-contained** tasks to a Qwen model running inside a headless Claude Code instance (`claude-subagent`). Keeps expensive Claude reasoning for work that needs it.

## The command

`claude-subagent` is a shell alias → `claude --model qwen3.6-35b-a3b` routed through the subagent gateway. Run it headless with `-p`:

```bash
claude-subagent -p "<self-contained task prompt>" --allowedTools Bash Read Edit Write Glob Grep
```

- **This is the default invocation.** The flag list scopes which tools the subagent may use without a prompt, so it can finish a menial job unattended. Without it the subagent stalls waiting for approval on the first edit or command.
- The alias bakes in `--allowedTools '*'`, which Claude Code **silently ignores** with a warning (`Wildcard tool name "*" is not supported`). That warning is expected and harmless — the `--allowedTools` you append is what takes effect.
- For edit-only, lower-risk tasks you may instead use `--permission-mode acceptEdits` (auto-accepts file edits, but Bash still prompts — don't use it for verification/build/test runs).

## Writing the task prompt (most important step)

The qwen subagent has **zero** context from this conversation. A vague prompt is the #1 failure mode. Every prompt must be standalone:

- **Absolute paths** for every input and output file (`/Users/tpatinya/proj/src/foo.ts`, not `foo.ts`).
- **Explicit inputs, outputs, and acceptance criteria** — what to change, what "done" looks like.
- **No references** to "the file we discussed", "above", or prior turns.
- Treat qwen as a capable-but-literal junior: spell out the steps, keep scope tight.

Bad: `clean up the imports`
Good: `In /Users/tpatinya/proj/src/api.ts, remove unused imports and sort the remaining import statements alphabetically. Do not change any other code. Confirm the file still parses.`

## Mind the context window (128k)

Qwen runs with a **128k-token context window** — much smaller than Claude's. The whole job (your prompt + every file it reads + its own reasoning and edits) has to fit inside it. Size each delegated task to the model, not just to "is it menial":

- **Estimate the footprint** before delegating: roughly the bytes of files it must read + open + write, ÷ 4 ≈ tokens. If a single task would pull in large files or many files at once, it won't fit.
- **Break large jobs into independent chunks** that each touch a bounded slice — e.g. one file (or a few small ones) per run, one directory per run, one log segment per run. Run the chunks as separate `claude-subagent` invocations (foreground, or background-parallel per the Return contract section).
- **Don't make it read what it doesn't need.** Point it at the exact files/paths required; never tell it to "scan the repo" or read a whole large tree.
- **Watch for context-exhaustion symptoms** when verifying: truncated edits, ignored later instructions, or a summary that omits files it was told to touch usually mean the task overflowed — split it smaller and retry.

When a job is inherently too big to slice cleanly (it needs whole-codebase context to do correctly), that's a sign it isn't a qwen task — keep it yourself.

## Working directory

The Bash tool's `cd` resets between calls and `cd &&` can trip permission prompts. Don't rely on cwd:

- Put **absolute paths in the prompt**, or
- Pass `--add-dir /abs/path` to grant the subagent access to a directory.

## Return contract

- **Default (text):** qwen's final message prints to stdout — read it directly.
- **Need to parse the result:** add `--output-format json` and extract the `result` field.
- **Background / parallel (run several at once):** redirect to a log and run with the Bash tool's `run_in_background: true`, then read the log when it finishes:

  ```bash
  claude-subagent -p "<task>" --allowedTools Bash Read Edit Write Glob Grep > /tmp/qwen-<label>.log 2>&1
  ```

  Launch independent tasks as separate background runs; collect each log on completion. Use this when delegating 2+ unrelated menial jobs.

## Workflow checklist

1. Confirm the task is menial and low-risk (see description). If it needs design judgment or this chat's context, **do it yourself** — don't delegate.
2. Check it fits qwen's **128k context window** — estimate the file footprint and split large jobs into bounded per-file/per-dir chunks (see "Mind the context window").
3. Write a fully self-contained prompt with absolute paths and acceptance criteria.
4. Run `claude-subagent -p "..." --allowedTools Bash Read Edit Write Glob Grep` (foreground), or background-redirect for parallel jobs.
5. **Verify the output yourself** — qwen is cheaper and less reliable. Check the file/result actually meets the acceptance criteria before reporting success.

## One-time setup (optional, removes repeated prompts)

To stop per-call permission prompts on delegated runs, add a Bash allow rule for the command (via the `update-config` skill, or by editing settings):

```json
{ "permissions": { "allow": ["Bash(claude-subagent:*)"] } }
```

## When NOT to delegate

Architecture/design, debugging that needs reasoning, security-sensitive changes, anything requiring this conversation's context, or tasks where a wrong cheap-model edit is costly to catch. When in doubt, keep it.

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

Delegate each dev subtask using the **qwen-agent** skill. Follow qwen-agent's invocation rules for context window sizing, allowedTools, and background/parallel pattern. Run all independent subtasks in parallel.

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

Delegate each tester subtask using the **qwen-agent** skill, after the matching dev pass completes. Give the tester the original request, subtask acceptance criteria, relevant files, changed-file list, and any commands the dev ran.

Apply the same retry rule as step 3: up to 2 retries on API error / empty result / timeout, then mark FAILED and report to the reviewer.

Tester prompt shape:

```text
You are qwen-tester in a Qwen dev/test pair.
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

---


# Scrutinize

Stand outside the change and ask whether it should exist at all, then verify it actually does what it claims end-to-end.

## Operating stance

- **Outsider.** Forget who wrote it and why they think it's right. Read the artifact cold.
- **End-to-end, not diff-local.** The diff is the entry point, not the scope. Follow the call graph through real code paths.
- **Actionable, concise, with rationale.** Every finding states *what to change*, *why*, and *what evidence* led you there. No filler, no restating the diff back.

## Workflow

Run these in order. Do not skip ahead.

### 1. Intent — what is this actually trying to do?

- State the goal in one sentence, in your own words. If you cannot, the artifact is underspecified — say so and stop.
- Ask: **is there a simpler, smaller, or more elegant way to achieve the same goal?** Consider:
  - Doing nothing (is the problem real / load-bearing?).
  - Using something that already exists in the codebase instead of adding new surface.
  - A smaller change that solves 90% of the goal with 10% of the risk.
  - Solving it at a different layer (config vs code, framework vs app, build vs runtime).
- If a better alternative exists, name it explicitly with rationale. This is the most valuable thing you can output — surface it before the line-by-line review.

### 2. Trace — walk the actual code path

- For each behavior the change claims, trace the path end-to-end through the real code, not just the lines in the diff:
  - Entry point → call sites → branches taken → state mutated → exit / return / side effect.
  - Include the unchanged code on either side of the diff. Bugs hide at the seams.
- For a plan or design doc: trace the proposed flow against the existing system. Where does it touch reality? What does it assume that isn't true?
- Note every place the trace surprises you (unexpected branch, dead code reached, state you didn't know existed). Surprises are signal.

### 3. Verify — does it actually do what it claims?

For each claim the change/plan makes, answer:

- **Does the code path you just traced actually produce that behavior?** Walk it explicitly. "It claims X. Path: A → B → C. At C, [observation]. Therefore [holds / doesn't hold]."
- **What inputs / states would break it?** Edge cases, concurrent callers, error paths, partial failures, retries, empty/null/unicode/huge inputs, ordering assumptions.
- **What does it silently change?** Performance, error semantics, observability, contract for other callers, on-disk / on-wire format.
- **How is it tested?** Do the tests actually exercise the traced path, or do they pass while skipping it (mocks that hide the bug, asserts on intermediate state, happy path only)?

### 4. Report

Output one tight section per finding. Order by severity (blocker → major → nit). For each:

- **Finding** — one sentence, specific. Cite `file:line` when applicable.
- **Why it matters** — the consequence, not the principle.
- **Evidence** — the trace step or input that exposes it.
- **Suggested change** — concrete, minimal.

Close with a one-line verdict: ship / fix-then-ship / rework / reject — with the single biggest reason.

## Operating rules

- **No rubber-stamps.** "LGTM" is not an output. If you genuinely find nothing, say what you traced and what you checked, so the user can judge whether your review covered the surface they cared about.
- **Cite or it didn't happen.** Every claim about the code references a specific path, file, or line. No vague "this might break under load."
- **Distinguish claim from verification.** "The PR says X" and "I traced X and confirmed / refuted it" are different — keep them separate in the output.
- **One simpler-alternative pass is mandatory.** Even on small changes, spend one breath asking if the whole thing is necessary. Skip only if the user explicitly says "don't question scope."
- **Don't pad with style nits when there's a structural problem.** If step 1 or step 2 surfaces a real issue, lead with it; defer nits or drop them.
- **No flattery, no hedging.** "This is a great PR but..." adds nothing. State the finding.

---


# Management Talk

Same audience and translation rules as a written status report, but **shaped for the channel** — JIRA comment, Slack post, async standup, email, or meeting talking-points. The audience reads code names but not code. The channel decides the length, formatting, and how much structure to leave on the page.

Use this any time engineering content needs to flow up the org, sideways into product/release, or into a non-engineering meeting — regardless of the destination.

## When to invoke

- "write something for management / exec / VP / director / PM / release manager"
- "rewrite this for [non-eng audience]"
- "make this non-technical" / "less techy" / "less jargony"
- "send a slack update / standup note / email" *about a piece of engineering work*
- "executive summary" / "exec summary" / "leadership update" / "status update"
- "talking points for [meeting]" *based on an engineering update*

If the channel is unclear after the trigger, ask one short question — *"JIRA, Slack, standup, or email?"* — and stop.

## Audience — what "engineering-org leadership" means

Engineering-savvy non-engineers: VPs, directors, PMs, release managers, execs in companies that ship technical products. They read product/framework names and cross-reference JIRA keys and PRs. They do not read code.

They want: *what's the state, what does it mean for customers, who owns it, what's next.* They do not want: how the bug works at the function level.

This is **not** for marketing, finance, customer-facing, or true ELI5 audiences — those need a different rewrite. Flag and confirm before producing one.

## Tone

**Keep.** Product names, framework names, team-owned component names, JIRA keys, PR numbers, customer/workload identifiers (`Tada`, `DeepSpeed`, `PyTorch`, `Llama-2-70B`, `vLLM`, `JIRA-12345`, `PR #5751`). These are the bridge between engineering and leadership tracking.

**Strip.** Function names, file paths, struct fields, commit SHAs, code expressions, env var names, line numbers, internal data-structure jargon (`tadaLaunchPrepare`, `tada/prim.h::syncWaitPeer`, `scratchBuf`, `0e0a6bac`). None of this is actionable to the audience.

**Translate.** Mechanism into one or two sentences of plain-English cause-and-effect. Not *"the kernel reads from `scratchBuf == NULL`"* but *"the GPUs end up reading from an uninitialized buffer and wait forever for a signal that never arrives."* Translate without lying — a race stays a race; a regression stays a regression.

**Don't over-strip.** Engineering-org leadership reads concept-level technical vocabulary fluently — *race condition, synchronization, uninitialized buffer, fast-path, workaround, registration, queue, driver, kernel* (in the GPU sense). The line is between *concept exists and matters here* (keep) and *here's the function/struct/file/SHA* (strip). Replacing "race" with "timing issue" patronizes the reader.

**Bias toward** active voice, concrete subjects, short paragraphs. *"We found the bug. Alex wrote the fix. PR is up for review."* beats *"The root cause has been identified and a fix has been authored and submitted for review."*

**Avoid:**

- Hedging that isn't really hedging (*"we believe," "appears to," "may have"*). State it or don't.
- Re-stating the obvious for thoroughness (*"This bug is in Tada, which is used for GPU communication, which is important for distributed training, which..."*).
- Telling leadership how to do their job (*"you should prioritize," "this needs to land before X"*). Give them the facts; they decide.
- Engineering-process minutiae: bisect runs, debug iterations, GDB sessions. They care that you found it, not how. (Exception: when the *process* itself is the story — *"we burned three weeks before realising the bisect was misleading"* — then a single sentence as a learning, not a play-by-play.)

## Channel shapes

Same content, different shell. Pick the shape that matches where it's going.

### JIRA comment / written status report

Full structured block. Bolded section labels. Easy to scan from the ticket page.

Building blocks (use as many as fit):

- **Status / TL;DR.** One bolded line. Reader can stop here and have the right answer. *"Fixed pending merge."* / *"Root cause unknown — investigating."* / *"Blocked on vendor."* / *"Customer-visible regression in 7.2; rollback in flight."*
- **Impact.** Who's affected, how badly, what they see. Customer / workload / product terms, not test-suite terms. *"Llama-2-70B fine-tuning hangs on every eval step"* > *"the test fails."*
- **What broke.** Short paragraph. Plain-English mechanism, one level of why, no code identifiers.
- **Why now / how it slipped through.** Optional. Include when leadership will ask anyway: latent regression, CI gap, prior incomplete fix, change that landed during a freeze.
- **Owner.** Person + team + their PR/branch/JIRA artifact. One link, not five.
- **Next steps.** Concrete, near-term, ordered. *"Code review → merge → backport to 7.2."*
- **Workaround / mitigation.** If customers are hitting it now, what can they do today? One sentence.
- **Risk.** Optional. Real risks only — *"fix touches the hot path; perf regression possible until benchmarked."* Don't manufacture risk to look thorough.

Order by what matters most for *this* item.

### Slack — channel post or DM

Single message, no walls of text. Heavy bolded section labels read as "I escaped from JIRA" — don't.

- One **bolded TL;DR** as the first line.
- 2–4 short bullets underneath: impact, owner+link, next step. Drop blocks that don't apply.
- One link, embedded inline (`JIRA-12345` / `PR #5751`). Not a link wall.
- No greeting, no signoff. The channel is the context.
- If it's a **thread reply** rather than a new post, lose the TL;DR — just lead with the answer.

Length target: under ~80 words for a top-level post; under ~40 for a thread reply.

### Async standup note

The audience scans 10 of these in 30 seconds. Front-load the verb.

- 1–3 lines, max.
- Pattern: *"\<state\> \<thing\>. \<owner if not me\>. \<next\>."*
- Examples:
  - *"Fixed Tada hang affecting dumbModel runs (JIRA-12345). PR #5751 in review. Backport to v7.2 next."*
  - *"Still chasing the LLM-7B eval-step hang. Reproducer is reliable now; bisecting. No ETA yet."*
- No bullets, no bolded labels. The format **is** the sentence.

### Email — internal exec / cross-team

Subject line is half the value.

- **Subject:** the TL;DR rewritten as a noun phrase. *"Tada hang in dumbModel: fix in review (JIRA-12345)."*
- **Greeting:** match the recipient register (*Hi Sam,* / *Hi all,*).
- **Body:** the JIRA-comment shape, but as flowing paragraphs separated by blank lines rather than bolded section labels. Two or three paragraphs is plenty.
- **Sign off** with the next decision point that needs the recipient's attention, if any. If none, a plain *"— [Name]"* is fine.

### Meeting talking-points

You're going to *say* this, not show it.

- Bullet list, max one short clause per bullet.
- Order is the order you'll speak in.
- Include the numbers/keys you want to reference out loud, in the bullet itself, so you don't fumble.
- Skip prose. *"dumbModel LLM-7B fine-tuning was hanging."* / *"Root cause: skipped sync in Tada fast-path."* / *"Alex's fix in review, PR #5751."* / *"Backport to v7.2 once it lands."*

## Source material

The input is one of:

1. **A JIRA ticket key** (e.g. `JIRA-12345`) → fetch via `GET /rest/api/3/issue/<KEY>?fields=summary,status,priority,assignee,comment` plus any custom fields your instance uses for technical evaluation — usually the cleanest source of current state. The most recent substantive comment is what to reframe; don't dump the full thread.
2. **Pasted technical text** → use directly.
3. **The current conversation** → if you (or the user) just produced engineering content and the user now says *"now in slack"* / *"now for the VP,"* reuse what's in context.

If the source is ambiguous, ask one question and stop.

## Output flow

1. **Confirm the channel** if it's not stated.
2. **Produce the draft** as a single chat block, formatted as the channel would render it.
3. **Ask where it goes:**
   - Default: print-only — the user copies it.
   - JIRA back-post: only if the user explicitly says so. Show the exact ADF payload, wait for explicit *"post it"* / *"go ahead"* / *"yes,"* then `POST /rest/api/3/issue/<KEY>/comment`.
   - **Never post to Slack, email, or any non-JIRA channel from this skill.** Hand the draft to the user; they post it.
4. **One iteration is normal, three is a smell.** If the user is on the third revision, ask what specific framing/audience assumption you're missing — don't keep tweaking blindly.

## Worked example — same bug, three channels

**Source (engineering JIRA comment):**

> **Mechanism:** the single-stream fast-path in `tadaLaunchPrepare` / `tadaLaunchKernel` / `tadaLaunchFinish` (gated on `scheduler->numStreams == 1 && !plan->persistent`) skipped the cross-stream event between `launchStream` and `handle->shared->deviceStream`. dumbModel hits this gate exactly. Kernel launched before deviceStream's IPC publish / scratch-buffer writes (the ones that populate `scratchBuf`) were visible to launchStream → `scratchBuf == NULL` in the kernel → stray pointer dereference → ring ready-flag read from garbage → thread spins forever.

### As a JIRA comment

> **Status: Fixed pending merge.** Bug found, fix validated, PR up for review.
>
> **Impact:** LLM-7B fine-tuning on 8 GPUs would hang every time it tried to evaluate the model — blocking the entire workload. Affects customers using dumbModel (a popular framework for training large models that don't fit on a single GPU), which means most large-model fine-tuning runs on the platform were exposed.
>
> **What broke:** Our GPU communication library (Tada) skipped an internal synchronization step under a specific configuration that dumbModel happens to trigger. The GPUs ended up reading from an uninitialized buffer and got stuck waiting for a signal that would never arrive. The unsafe shortcut had been in the code for months but wasn't reached by any real workload until now.
>
> **A previous fix attempt** added a defensive check that hid the symptom in some paths but left the underlying race in place. This new fix removes the unsafe shortcut entirely and tightens the safety check on the device side.
>
> **Owner:** Alex (Tada team). PR org/platform#5751.
>
> **Next steps:** code review → merge. Customers hitting this today can disable IPC registration as a temporary workaround.

### As a Slack post

> **Tada hang affecting dumbModel LLM-7B fine-tuning is fixed pending merge.** (JIRA-12345)
>
> - Skipped synchronization in the comms fast-path → GPUs read uninitialized memory → hang. Latent for months; dumbModel was the first workload to hit it.
> - Owner: Alex, PR #5751 in review.
> - Workaround until merge: disable IPC registration.

### As a standup note

> Fixed Tada hang on dumbModel LLM-7B (JIRA-12345). Alex's PR #5751 in review. Workaround posted in the ticket; backport to v7.2 next.

What changed between channels: same diagnosis, same owner, same next step. JIRA gets every block. Slack drops "why now" and "previous fix attempt" — too much for the channel. Standup keeps just state + key + owner + next. None of them mention `scratchBuf` or `tadaLaunchPrepare`.

## Rules

- **Never invent facts** to make the rewrite cleaner. If the engineering source says "root cause unknown," the rewrite says "root cause unknown" — do not promote a speculation to a finding for narrative tidiness.
- **Never strip a JIRA key, PR number, or customer/workload name** during de-jargoning. They're the cross-reference bridge — losing them breaks tracking.
- **Never invent owners.** If the source doesn't name one, ask the user — don't guess from `git blame` or recent commits.
- **Get sign-off before posting to JIRA.** Reuse the jira-check approval flow. Print-only output needs no approval.
- **Never post to Slack, email, or any non-JIRA channel from this skill.** Hand the draft to the user; they post it.
- **Stay out of advocacy.** This skill produces a status update, not a recommendation. If the user wants a recommendation memo, confirm before reframing.

---


# Staying on Track

Long, multi-step work fails three ways: **looping**, **over-thinking**, and **running out of context**. Run the checklist below **before each step**. When a trigger fires, do the matching action — don't deliberate about it.

## Before each step — run this

| Check | Trigger fires when... | Do this |
|---|---|---|
| **Looping?** | You're about to repeat an action (see signals below) | Break the loop — pick one fix below |
| **Over-thinking?** | You've reasoned past ~1000 words without acting | Stop. Act on your current best decision, or ask the user one question |
| **Context tight?** | A low-context reminder appeared, **or** 2+ budget signals hold | Finish this step, then hand off |

If nothing fires, take the step.

## 1. Loops — detect and break

A step is a loop if **any** of these is true:

- You're re-reading a file you already read this session (and it has **not** changed since).
- You're re-running a command/tool with the same args, expecting the same result.
- You're returning to a hypothesis you already tried and dropped.
- You're "reconsidering from the start" with no new evidence.
- The last 2 steps gained no new information.

**Re-reading a file you just edited is NOT a loop** — that's verifying.

When a loop fires, **stop** and do exactly one:

1. State the blocker in one sentence and ask the user a specific question.
2. Write what you know vs. don't know, then take a **different** action than last time.
3. Looped 2+ times on the same sub-problem? Declare it unsolved-for-now; move on or hand off.

Never repeat a failed action hoping for a different result.

**Retry cap:** never run the same failing command a 3rd time. Can't get something working (a command, a test runner, an import) after ~3 attempts — *even varied ones* — STOP and ask the user; don't grind through more variations.

**Don't edit blind** — it's the top loop source. Read enough to know the change is correct *before* editing. After each edit, verify it (read the diff / run it / run the test) **before** the next step. One edit → one check.

## 2. Thinking — keep it bounded

Cap reasoning at **~1000 words per step**. Past that, you're deliberating instead of acting.

- Decide → act → observe. Don't re-derive a decision you already made.
- Can't decide in ~1000 words? The task is underspecified — **ask the user one sharp question**.
- Don't restate the whole problem to yourself. Reference what you concluded; don't rebuild it.

## 3. Context budget — count signals, don't estimate

**Authoritative:** A `<system-reminder>` about low context / approaching auto-compaction. → **Hand off now** (section 4). Don't start new work.

**Otherwise, count how many of these are true right now:**

- [ ] 20+ assistant turns into the task.
- [ ] Read 5+ files, or any one huge file/log/dump.
- [ ] Long tool outputs you keep scrolling back to.
- [ ] 3+ plan steps still left.

**Count the boxes that are true, then map the count to an action:**

- **Count is 0 or 1 → CONTINUE** working normally.
- **Count is 2, 3, or 4 → HAND OFF** — finish the current step, then go to section 4.

Count first, then decide — don't judge by feel. A higher count means *more* context pressure, not less. Being on the last step or "almost done" does **not** lower the count or cancel a HAND OFF.

Before any **expensive** step (large read, new subtask, long generation), ask: *"Room to finish this AND hand off after?"* If the count says HAND OFF, finish the current atomic unit, then hand off — don't start the next.

## 4. Hand off cleanly

When context is tight or the user asks:

1. **Land durable artifacts first** — save the file, commit, write the result. Nothing lost.
2. **Invoke the `handoff` skill** to compact the conversation. Don't hand-write the handoff.
3. Tell the user plainly: "Context is getting tight — handing off now; start a fresh session (`/clear`)."

---

