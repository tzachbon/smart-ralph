# Ralph Specum Workflow

## Entry Surface

| Claude surface | Codex surface |
|----------------|---------------|
| `/ralph-specum:start` | `$ralph-specum` or `$ralph-specum-start` |
| `/ralph-specum:new` | `$ralph-specum` or `$ralph-specum-start` |
| `/ralph-specum:research` | `$ralph-specum` or `$ralph-specum-research` |
| `/ralph-specum:requirements` | `$ralph-specum` or `$ralph-specum-requirements` |
| `/ralph-specum:design` | `$ralph-specum` or `$ralph-specum-design` |
| `/ralph-specum:tasks` | `$ralph-specum` or `$ralph-specum-tasks` |
| `/ralph-specum:implement` | `$ralph-specum` or `$ralph-specum-implement` |
| `/ralph-specum:status` | `$ralph-specum` or `$ralph-specum-status` |
| `/ralph-specum:switch` | `$ralph-specum` or `$ralph-specum-switch` |
| `/ralph-specum:cancel` | `$ralph-specum` or `$ralph-specum-cancel` |
| `/ralph-specum:index` | `$ralph-specum` or `$ralph-specum-index` |
| `/ralph-specum:refactor` | `$ralph-specum` or `$ralph-specum-refactor` |
| `/ralph-specum:feedback` | `$ralph-specum` or `$ralph-specum-feedback` |
| `/ralph-specum:help` | `$ralph-specum` or `$ralph-specum-help` |

## Delegation Rules

Every phase skill acts as a coordinator. The coordinator:

1. Normalizes mode through `scripts/phase_gate.py mode`. Only exact `--quick` and exact `--interactive` change mode.
2. Runs the applicable skill discovery pass.
3. Reloads the internal `interview-framework-codex` skill, every selected domain skill, and every required current-work reference.
4. Runs the critical-decision frontier interview from `skills/interview-framework-codex/references/algorithm.md`.
5. Obtains explicit `approve and delegate` confirmation.
6. Persists that choice with confirmation source `approve-and-delegate`, runs `phase_gate.py check-delegation`, and delegates artifact generation to the phase sub-agent.
7. Validates the sub-agent output and presents it for artifact approval.

| Phase | Sub-agent type |
|-------|---------------|
| Research | `research-analyst` |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Tasks | `task-planner` |
| Implement | `spec-executor` (per task) |
| Triage | `triage-analyst` |
| Refactor | `refactor-specialist` |

The coordinator MUST NOT write spec artifacts directly. If sub-agent delegation is unavailable or the phase gate fails, report the limitation and stop.

## Normal Flow

1. Resolve current repo state and set up or resume the spec.
2. Run skill discovery pass 1 and the start goal grill.
3. After explicit final approval, delegate `research.md` to `research-analyst`.
4. Review and approve the research artifact.
5. Run skill discovery pass 2 and the requirements grill. After explicit final approval, delegate `requirements.md`.
6. Repeat the reload, grill, final approval, and delegation path for design and tasks.
7. Approve `tasks.md`, then delegate each implementation task until complete or blocked.
8. Use `status`, `switch`, `cancel`, `index`, `refactor`, `feedback`, and `help` as needed.

Direct or resumed `triage`, `research`, `requirements`, `design`, or `tasks` invocations run their applicable discovery pass when state lacks it. A resumed grill reloads the complete selected manifest before asking another question.

The old `Wait for explicit direction to continue to research` setup pause is obsolete. Start begins the goal grill after setup and waits for explicit `approve and delegate` at the final interview gate.

## Start And New

- `new` is an alias within the start flow.
- Resolve the target spec by explicit path, exact name, or current spec.
- If the current branch is the default branch and the user wants isolation, offer:
  - feature branch in place
  - worktree with a feature branch
- If the user wants a worktree, stop after creating it and ask them to continue from the worktree.
- Start setup is complete when the spec directory, state, progress, and current-spec marker exist. In normal mode, begin the goal grill at that point. Do not ask setup or administration questions in the grill.

## Skill discovery and load

Run pass 1 after start setup using the goal. Run pass 2 after the final research artifact using the goal plus only the `## Executive Summary` section through the next level-2 heading. Hash the full applicable `research.md` bytes for gate staleness even though selection relevance uses only that summary. Collect candidates from plugin skills, project `.agents/skills`, project `.claude/skills`, and the current Codex harness catalog.

- Always select explicitly named skills.
- When names collide, use the harness-resolved active source and record other sources as shadowed in the selection reason and `.progress.md`. Reserve manifest warnings for exact load errors.
- Append cumulative `discoveredSkills` history for every pass with pass, revision, name, active source, reason, and shadowed sources. Legacy `invoked` is not a load receipt.
- Put the internal `interview-framework-codex` skill first in every normal-mode phase manifest.
- Reload every selected `SKILL.md` and required current-work reference before every new or resumed grill.
- Treat discovery and preload as contract extraction. Start no prescribed domain-skill task action during either step.
- Stop when the core interview skill fails. Warn and continue when a domain skill fails.
- Give failed receipts a null hash and exact errors. Loaded receipts use the current source hash.
- Resolve clear conflicts through harness instruction precedence and record them without asking. Ask only unresolved material contract conflicts in the first critical-decision frontier.
- Pass the verbatim manifest and gate identity to the artifact agent.

## Quick Mode

Quick mode does not rely on Claude hooks. In Codex it means:

1. Create or resolve the spec.
2. Generate missing phase artifacts in order.
3. Count tasks.
4. Continue directly into implementation in the same run.
5. Persist `.ralph-state.json` after every task so a later run can resume.

Only exact `--quick` enables quick mode. Exact `--interactive` clears it for any affected phase. Passing both is an error. Reject `-q`, flag variants, and natural-language autonomy requests. A phase invocation without either flag normalizes legacy or invalid quick state to interactive before deciding whether to grill.

Quick bypasses interview questions and final interview confirmation only. Run the applicable discovery pass, record a current `complete` or `partial_warned` manifest, and pass it through the parent delegation check. Each quick-mode artifact child reloads the manifest, records every loaded source under its unique dispatch identity, and passes `check-agent-write` before writing.

## Implement

- Read `tasks.md`, `.progress.md`, and `.ralph-state.json`.
- Recompute task counts before execution.
- Process tasks in order.
- `[P]` tasks may be batched only when file sets do not overlap and verification is independent.
- `[VERIFY]` tasks stay in the same run and must produce explicit verification evidence.
- After each task:
  - mark checkbox
  - update state
  - update progress
  - commit using the task commit line unless task commits were explicitly disabled
- Remove `.ralph-state.json` only when all tasks are complete and verified.

## Cancel

Claude `cancel` deletes the spec directory. In Codex:

- confirm before deleting a spec directory
- allow a safer "stop but keep files" interpretation when the user asks to keep the spec
- always clear execution state when the user asks to stop execution

## Index

Index creates or updates:

- `specs/.index/index.md`
- `specs/.index/components/*.md`
- `specs/.index/external/*.md`

Use the canonical templates from `assets/templates/`.

## Refactor

Refactor updates existing spec artifacts after implementation learnings. Review files in order:

1. `requirements.md`
2. `design.md`
3. `tasks.md`

Cascade downstream updates when upstream requirements or design changes.

## Approval Prompt Shape

The pre-delegation interview and post-generation artifact review are separate gates.

Before delegation, show the decision ledger and require the explicit native user-input choice `Approve and delegate (Recommended)`. Replies that only say `apply the changes`, `continue`, `proceed`, or `go ahead` answer no interview question and approve no delegation. Bare `skip` during an active interview fills the remaining critical decisions with recorded defaults and assumptions, then still requires final approval.

Classify each reply with `phase_gate.py classify-reply`. Persist final approval only with `confirm --source approve-and-delegate`. If the user chooses revision at final confirmation, call `revise` for all affected decision IDs, collect the reopened answers in its incremented round, and return to the same final confirmation ID.

When a phase writes `research.md`, `requirements.md`, `design.md`, `tasks.md`, or refactored spec files outside quick mode:

- name the file or files that changed
- give a short summary
- end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to <named next step>`

Treat `continue to <named next step>` as approval of the current artifact.

During artifact review, `apply the changes` immediately delegates already-recorded feedback through the same gate and a new unique dispatch, redisplays the artifact, and returns to artifact approval. Ask one focused change question only when no revision feedback is pending. A bare `continue`, `proceed`, or `go ahead` does not approve the artifact.

## Hook-Driven Execution Path

When the Codex Stop hook is enabled (`[features] codex_hooks = true` in Codex config), the execution loop runs without user re-invocation:

1. The stop-watcher script runs on every agent stop event.
2. It reads `.ralph-state.json` to determine the current phase and task index.
3. If tasks remain, it outputs `{"decision": "block", "reason": "<next task prompt>"}` to prevent the session from closing and inject the next task instruction.
4. The agent resumes, executes the next task, marks the checkbox, updates state, and stops again.
5. The loop repeats until all tasks are complete or `taskIndex >= totalTasks`.
6. On completion the script outputs `{"decision": "proceed"}` to allow the session to close normally.

The Stop hook is experimental and requires `codex_hooks = true`. It is disabled by default and not available on Windows. Verify the feature flag is set before relying on hook-driven execution.

## Manual Fallback Path

When hooks are disabled or unavailable, re-invoke the implement skill after each task to advance the loop:

1. Run `$ralph-specum-implement` (or the primary `$ralph-specum` skill with an implement intent).
2. The skill reads `.ralph-state.json`, finds `taskIndex` pointing to the next incomplete task, and executes it.
3. After the task completes, the skill updates state and stops.
4. Repeat step 1 until the skill reports all tasks complete.
5. If a task is blocked (exceeded retry limit), the skill will report the blocker. Resolve the issue manually, then re-invoke to continue.

Use this path whenever `codex_hooks` is not set, when running on Windows, or when verifying hook behavior during development.

## Hook-Driven Execution Path

When `[features] codex_hooks = true` is set in `config.toml`, the execution loop is automated via the Stop hook.

### How it works

1. User invokes `$ralph-specum-implement`
2. Skill reads `.ralph-state.json`, delegates current task to a subagent
3. Subagent completes task, outputs `TASK_COMPLETE`
4. Codex attempts to stop the turn
5. Stop hook (`hooks/stop-watcher.sh`) fires, reads state file
6. If `taskIndex < totalTasks`: outputs `{"decision": "block", "reason": "Continue to task N/M"}`
7. Codex resumes with the reason as the new prompt
8. Skill reads updated state, delegates next task
9. Loop repeats until `taskIndex >= totalTasks`
10. Stop hook outputs nothing (exit 0), Codex stops naturally

### Stop hook output format

```json
{"decision": "block", "reason": "Continue to task 5/20. Next: 1.6 Write ralph-specum-research skill"}
```

### Guard conditions

- `awaitingApproval: true` in state -> exit 0 (do not continue)
- No `.ralph-state.json` found -> exit 0
- `taskIndex >= totalTasks` -> exit 0 (all done)

## Manual Fallback Path

When hooks are disabled (no `codex_hooks = true`, or on Windows), run phases manually:

### Step-by-step re-invocation

1. Invoke `$ralph-specum-implement` -- executes first incomplete task
2. After task completes, Codex stops naturally
3. Re-invoke `$ralph-specum-implement` -- reads state, picks up next task
4. Repeat until all tasks complete
5. Final invocation outputs `ALL_TASKS_COMPLETE`

### Tips for manual mode

- Each invocation handles exactly one task
- State persists in `.ralph-state.json` between invocations
- Progress is tracked in `.progress.md`
- If a task fails, fix the issue and re-invoke -- the same task will retry
- Use `$ralph-specum-status` to check progress at any time
