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
| `/ralph-specum:prototype` | `$ralph-specum` or `$ralph-specum-prototype` |
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
| Prototype source | Child agent recorded by `agentId` |

The coordinator MUST NOT write spec artifacts directly. Prototype source also stays delegated to a child agent; do not create a user-owned task with `create_thread`. If sub-agent delegation is unavailable, report the limitation and stop in normal mode. Quick mode records a failed prototype outcome and continues to design.

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

After normal research or requirements, offer `continue to prototype` beside the next phase; never force it. Direct `$ralph-specum-prototype` is available from any main phase. The prototype is an `activePrototypes` overlay and never changes the main `phase` to `prototype`.

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
3. After requirements, run exactly one prototype request. Ask no prototype questions. Take over the oldest active design blocker when one exists; otherwise select the highest-risk grounded question or record a skip.
4. Own verdict, cleanup, and handoff decisions, then continue to design in every outcome.
5. Count tasks and continue directly into implementation in the same run.
6. Persist `.ralph-state.json` after every task so a later run can resume.

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
- Before dispatch, reconcile records and stop only for a prototype blocker or stale artifact/task that affects the current task. Restore `returnTaskIndex` after handoff. Keep state at completion while `activePrototypes` is nonempty.

## Prototype Evidence Push Gate

Run this gate immediately before every push produced by implementation batching, generated tasks, CI repair, review repair, branch publication, or PR lifecycle work:

1. Resolve the exact target remote and branch. Inspect the commits the push would add to that target with `git log --format= --name-only <remote-target>..HEAD -- '**/prototypes/*.md' | sed '/^$/d' | sort -u`. For a new target branch, identify its actual remote base first; stop before pushing if the outbound range cannot be determined.
2. Preserve the existing non-prototype push when no prototype record appears.
3. In normal mode, stop at the push boundary when records appear and require separate explicit authorization naming every exact record path. `commitSpec`, task execution, and generic branch, PR, or push approval do not count.
4. When the gate skips or denies the push, end the dependent remote lifecycle path. Do not run `gh pr create`, `gh pr merge`, `gh pr checks`, `gh pr view`, `gh api`, `gh run`, `gh issue`, remote review polling, issue writes, or any later remote step that depends on that push.
5. Quick mode asks no question and skips the push. Keep every commit local, continue or finish locally, and report `Remote lifecycle skipped: prototype evidence stayed local.`
6. When the gate permits and completes the push, preserve the existing normal remote lifecycle.
7. Never push an isolated `prototype/<spec>/<id>` source branch.

Re-run the inspection after every new commit and immediately before the push. `commitSpec` remains local commit authorization.

## Cancel

Safe cancel is the default. Publish and verify one immutable `cancelled` record for each active prototype before removing its active entry. Preserve source, partial work, records, and local branches. Full spec removal or prototype-source deletion requires a separate confirmation naming the exact local path and branch. Never delete a remote branch.

## Prototype Overlay

1. Resolve `basePath`, reconcile candidates and finals, and read `activePrototypes` through the shared helpers.
2. Resume an explicit ID, the sole active entry, or a user-selected entry. Quick mode selects the oldest design blocker without asking.
3. Build in a sibling worktree or eligible scratch area without switching the current checkout or copying unapproved dirty paths.
4. Review exact candidate bytes, publish an immutable final under `<basePath>/prototypes/`, verify it, then remove the active entry.
5. Feed only gate-approved, non-superseded `validated` or `rejected` evidence to affected downstream work. Keep malformed, excluded, cancelled, failed, skipped, and inconclusive records out.

Prototype source and evidence remain local. A local commit does not authorize a push, PR update, issue write, or any other remote action. Apply the Prototype Evidence Push Gate before every push-capable downstream task.

## Index

Index creates or updates:

- `specs/.index/index.md`
- `specs/.index/components/*.md`
- `specs/.index/external/*.md`

Use the canonical templates from `"$RALPH_CODEX_PLUGIN_ROOT/templates/"`.

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

## Hook-Driven Execution Overview

When the bundled Codex Stop hook is trusted and enabled, the execution loop runs without user re-invocation:

1. The stop-watcher script runs on every agent stop event.
2. It reads `.ralph-state.json` to determine the current phase and task index.
3. If tasks remain, it outputs `{"decision": "block", "reason": "<next task prompt>"}` to prevent the session from closing and inject the next task instruction.
4. The agent resumes, executes the next task, marks the checkbox, updates state, and stops again.
5. The loop repeats until all tasks are complete or `taskIndex >= totalTasks`.
6. On completion the script allows the session to close only when `activePrototypes` is empty.

Codex enables hooks by default, but plugin hooks do not run until you review and trust them with `/hooks`. This hook also requires `bash` and `jq`.

## Manual Fallback Path

When hooks are disabled or unavailable, re-invoke the implement skill after each task to advance the loop:

1. Run `$ralph-specum-implement` (or the primary `$ralph-specum` skill with an implement intent).
2. The skill reads `.ralph-state.json`, finds `taskIndex` pointing to the next incomplete task, and executes it.
3. After the task completes, the skill updates state and stops.
4. Repeat step 1 until the skill reports all tasks complete.
5. If a task is blocked (exceeded retry limit), the skill will report the blocker. Resolve the issue manually, then re-invoke to continue.

Use this path whenever the Stop hook is not trusted or enabled, when `bash` or `jq` is unavailable, or when verifying hook behavior during development.

## Hook-Driven Execution Details

When the bundled Stop hook is trusted and enabled, it automates the execution loop.

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
- a dependent active prototype or stale current task -> block with resume guidance
- completed tasks with nonempty `activePrototypes` -> block and preserve state

## Manual Fallback Details

When the Stop hook is not trusted or enabled, or when `bash` or `jq` is unavailable, run phases manually:

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
