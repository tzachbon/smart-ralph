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

1. Gathers context (spec state, progress, prior artifacts)
2. Runs the brainstorming interview (skip if `--quick`)
3. Delegates artifact generation to the appropriate sub-agent type
4. Validates the sub-agent output exists and is well-formed
5. Presents the walkthrough summary
6. Waits for user approval (skip if `--quick`)

| Phase | Sub-agent type |
|-------|---------------|
| Research | `research-analyst` |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Tasks | `task-planner` |
| Implement | `spec-executor` (per task) |
| Triage | `triage-analyst` |
| Refactor | `refactor-specialist` |

The coordinator MUST NOT write spec artifacts directly. If sub-agent delegation is unavailable, report the limitation and stop.

## Normal Flow

1. Resolve current repo state, branch, and spec roots.
2. Start or resume a spec.
3. STOP. Wait for explicit direction to continue to research unless `--quick`.
4. Delegate `research.md` to `research-analyst` sub-agent. STOP and request approval unless `--quick`.
5. Delegate `requirements.md` to `product-manager` sub-agent. STOP and request approval unless `--quick`.
6. Delegate `design.md` to `architect-reviewer` sub-agent. STOP and request approval unless `--quick`.
7. Delegate `tasks.md` to `task-planner` sub-agent. STOP and request approval unless `--quick`.
8. Delegate each task to `spec-executor` sub-agent until complete or blocked.
9. Use `status`, `switch`, `cancel`, `index`, `refactor`, `feedback`, and `help` as needed.

## Start And New

- `new` is an alias within the start flow.
- Resolve the target spec by explicit path, exact name, or current spec.
- If the current branch is the default branch and the user wants isolation, offer:
  - feature branch in place
  - worktree with a feature branch
- If the user wants a worktree, stop after creating it and ask them to continue from the worktree.

## Quick Mode

Quick mode does not rely on Claude hooks. In Codex it means:

1. Create or resolve the spec.
2. Generate missing phase artifacts in order.
3. Count tasks.
4. Continue directly into implementation in the same run.
5. Persist `.ralph-state.json` after every task so a later run can resume.

Only use quick mode when the user explicitly asks Ralph to be autonomous, do it quickly, or continue without pauses.

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

When a phase writes `research.md`, `requirements.md`, `design.md`, `tasks.md`, or refactored spec files outside quick mode:

- name the file or files that changed
- give a short summary
- end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to <named next step>`

Treat `continue to <named next step>` as approval of the current artifact.

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
