---
name: smart-ralph
description: This skill should be used when the user asks about "ralph arguments", "quick mode", "commit spec", "max iterations", "ralph state file", "prototype overlay", "execution modes", "ralph loop", "coordinator behavior", "delegate to subagent", or needs guidance on Ralph plugin arguments, state management, delegation patterns, or execution loop behavior. Core behavioral skill for all Ralph Specum operations.
version: 0.2.0
user-invocable: false
---

# Smart Ralph

Core skill for all Ralph plugins. Defines common arguments, execution modes, shared behaviors, and coordinator delegation rules.

## Common Arguments

All Ralph commands support these standard arguments:

| Argument | Short | Description | Default |
|----------|-------|-------------|---------|
| `--quick` | `-q` | Skip interactive phases, auto-generate artifacts, start execution immediately | false |
| `--commit` | `-c` | Commit spec/feature files locally after generation | true (normal), false (quick) |
| `--no-commit` | | Explicitly disable committing files | - |
| `--max-task-iterations` | `-m` | Max retries per failed task before stopping | 5 |
| `--fresh` | `-f` | Force new spec/feature, overwrite if exists | false |

Argument precedence: `--no-commit` > `--commit` > mode default.

## Execution Modes

### Normal Mode (Interactive)

- User reviews artifacts between phases
- Phase transitions require explicit commands
- Each phase sets `awaitingApproval: true`
- Commits spec files by default
- Research and requirements may offer the optional prototype overlay
- The user owns prototype capture, verdict, handoff, and deletion decisions

### Quick Mode (`--quick`)

- Skip all interactive prompts, interviews, and approval pauses
- Run the same phase agents (research, requirements, design, tasks) sequentially
- Agents receive a "be more opinionated" directive since there is no user feedback
- spec-reviewer validates each artifact (max 3 iterations)
- Run at most one agent-owned prototype request after requirements and before design
- Take over the oldest design-blocking prototype when one exists; otherwise choose the highest-risk grounded question
- Ask no prototype question or decision and continue to design after every outcome
- Immediately start execution after all phases complete
- Do NOT commit by default (use `--commit` to override)
- Still delegate to subagents (delegation is mandatory)

## State File

All Ralph plugins use `.ralph-state.json` for execution state. See `references/state-file-schema.md` for full schema.

Key fields: `phase`, `taskIndex`, `totalTasks`, `taskIteration`, `maxTaskIterations`, `awaitingApproval`, and optional `activePrototypes`.

Prototype is an overlay. `phase` remains one of the five main workflow phases and is never `prototype`. Resolve `basePath` before access, treat a missing `activePrototypes` map as empty, and route every mutation or deletion through `hooks/scripts/locked-state.py`. Read [`references/state-file-schema.md`](references/state-file-schema.md) before changing state, resuming an overlay, or deciding whether execution state may be deleted.

## Commit Behavior

When `commitSpec` is true:

1. Stage spec/feature files after generation
2. Commit with message: `chore(<plugin>): commit spec files before implementation`
3. Keep the commit local unless a separate command and explicit authority permit a remote action

When `commitSpec` is false:

- Files remain uncommitted
- User can manually commit later

Prototype terminal records are spec artifacts, so `commitSpec` controls their local commit. Retained prototype source always receives a local commit on its isolated branch, independent of `commitSpec`. Neither path authorizes a push, remote branch, PR inclusion, issue mutation, or ticket comment.

## Prototype Overlay

The coordinator follows this sequence:

1. Resolve `basePath`, reconcile candidates and finals, and reserve or resume `activePrototypes.<id>` under the state lock. Completion criterion: the main phase and unrelated fields are unchanged.
2. Keep source in an isolated sibling worktree or eligible scratch path. Completion criterion: the current checkout remains on its original branch and prototype files exist only in the recorded isolation path.
3. Build and review one falsifiable question. Completion criterion: the reviewer passes the exact candidate bytes, source/run evidence, isolation, blocker, handoff, and `sourceDisposition`.
4. Publish one immutable terminal record without overwrite, apply gate selection, restore the recorded return phase/task, then remove the active entry under lock. Completion criterion: downstream work sees only valid, non-superseded, gate-approved evidence.

Normal mode waits without a verdict or handoff timeout and keeps decisions with the user. Quick mode owns the one post-requirements request, can take over the oldest design blocker, uses reviewed receipts for eligible ephemeral cleanup, and always continues to design. Cancellation and interruption preserve source and publish reviewed terminal evidence before active-state removal.

Prototype source, records, cleanup receipts, and quarantines are local evidence. A remote push, branch publication, PR inclusion, issue write, or deletion outside the single quick ephemeral cleanup path requires separate explicit authority.

## Task Execution Loop

Ralph Specum v3.0.0+ has a self-contained execution loop via the stop-hook. No external dependencies required.

Key signals:
- `TASK_COMPLETE` - executor finished task
- `ALL_TASKS_COMPLETE` - coordinator ends loop

## Error Handling

When `taskIteration > maxTaskIterations`: block task, suggest manual intervention.

If state file missing/invalid: output error, suggest re-running implement command.

## Branch Management

All Ralph plugins follow consistent branch strategy:

1. Check current branch before starting
2. If on default branch (main/master): prompt for branch strategy
3. If on feature branch: offer to continue or create new
4. Quick mode: auto-create branch, no prompts

Prototype isolation is separate from this feature-branch choice. Create or reuse a sibling worktree or eligible scratch path without checking out its branch in the current checkout. Retained and interrupted source remains available for recovery.

## Coordinator Behavior

The main agent is a coordinator, not an implementer. Delegate all work to subagents.

### Coordinator Responsibilities

1. Parse user input and determine intent
2. Read state files for context
3. Delegate work to subagents via Task tool
4. Report results to user

### Do Not

- Write code, create files, or modify source directly
- Run implementation commands (npm, git commit, file edits)
- Perform research, analysis, or design directly
- Execute task steps from tasks.md

### Delegation Mapping

| Work Type | Delegate To |
|-----------|-------------|
| Research | Research Team (parallel teammates) |
| Requirements | product-manager subagent |
| Design | architect-reviewer subagent |
| Task planning | task-planner subagent |
| Task execution | spec-executor subagent |
| Prototype building | prototype-builder background subagent |

Quick mode still requires delegation.
