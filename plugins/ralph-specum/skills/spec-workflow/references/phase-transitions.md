# Phase Transitions

Detailed flow for spec-driven development phases.

## Phase Order

```
new/start -> research -> requirements -> design -> tasks -> implement
```

## Optional Prototype Overlay

Prototype interrupts a main phase without becoming one. Keep `phase` on its current main value and store each live request under `activePrototypes.<id>`. Existing state without `activePrototypes` means the overlay is empty.

Before an overlay operation:

1. Resolve the configured spec root and `basePath` with `hooks/scripts/path-resolver.sh`. Completion criterion: every state, lock, candidate, final, index, and context path derives from that resolved `basePath`.
2. Reconcile candidates and terminal records with `hooks/scripts/prototype-records.py reconcile`. Completion criterion: interrupted publication has one deterministic resume action.
3. Mutate state only through `hooks/scripts/locked-state.py` under `<basePath>/.ralph-state.lock`. Completion criterion: the update preserves unrelated fields and no raw `jq`, temp-file move, copy, or state deletion runs outside the helper.

Entry and return rules:

- After research or requirements, normal mode may offer `continue to prototype` beside the next-phase choice. The user chooses whether to enter.
- `/ralph-specum:prototype` may start from research, requirements, design, tasks, or execution. Record `triggerPhase`, `returnPhase`, and `returnTaskIndex` when execution is interrupted.
- An active blocker pauses only dependent artifacts or tasks. Proven unrelated work may continue after dependency and path checks.
- On terminal handoff, restore `returnPhase` and `returnTaskIndex`, or move to the earliest artifact the selected handoff makes stale.

Terminal evidence follows one path: render an exclusive candidate, review its exact bytes and source evidence, publish an immutable `prototypes/<id>.md` without overwrite, verify the final hash, then remove the active entry under lock. Corrections and changed conclusions publish a new record with `supersedes`; final records remain immutable.

## Phase Details

### 1. Research Phase

**Command**: `/ralph-specum:research`
**Agent**: research-analyst
**Output**: `./specs/<name>/research.md`

Activities:
- Web search for best practices
- Codebase analysis for existing patterns
- Related specs discovery
- Quality command discovery
- Feasibility assessment

Ends with: `awaitingApproval: true`

Normal continuation may proceed to requirements or enter the optional prototype overlay and return to requirements.

### 2. Requirements Phase

**Command**: `/ralph-specum:requirements`
**Agent**: product-manager
**Output**: `./specs/<name>/requirements.md`

Activities:
- User stories creation
- Acceptance criteria definition
- Functional requirements table
- Non-functional requirements
- Out of scope items

Ends with: `awaitingApproval: true`

Normal continuation may proceed to design or enter the optional prototype overlay and return to design.

### 3. Design Phase

**Command**: `/ralph-specum:design`
**Agent**: architect-reviewer
**Output**: `./specs/<name>/design.md`

Activities:
- Architecture diagrams (mermaid)
- Component definitions
- Interface specifications
- Data flow documentation
- Technical decisions table
- Test strategy

Ends with: `awaitingApproval: true`

### 4. Tasks Phase

**Command**: `/ralph-specum:tasks`
**Agent**: task-planner
**Output**: `./specs/<name>/tasks.md`

Activities:
- POC-first task breakdown
- 4-phase structure (POC, Refactor, Test, Quality)
- Verify commands for each task
- Commit messages
- Quality checkpoints every 2-3 tasks

Ends with: `awaitingApproval: true`

### 5. Execution Phase

**Command**: `/ralph-specum:implement`
**Agent**: spec-executor (via Ralph Loop)
**State**: `phase: "execution"`

Activities:
- Task-by-task execution
- Verification after each task
- Commit after verified completion
- Progress tracking in `.progress.md`

Ends with: State file deleted on completion

## Quick Mode

With `--quick` flag:
- All phases run automatically using the same agents as normal mode
- Interviews, walkthroughs, and awaitingApproval skipped
- spec-reviewer validates each artifact (max 3 iterations)
- Exactly one prototype request is allowed after requirements and before design
- The agent owns capture, verdict, handoff, and eligible ephemeral cleanup decisions
- The request takes over the oldest active design blocker; otherwise it selects the highest-risk grounded question
- `requestAttempt` counts the request separately from up to two `builderExecutionAttempt` launches
- No prototype question or decision is delegated to the user
- `validated` and `rejected` evidence may feed design; skipped, failed, and inconclusive evidence does not
- Design always continues after the request, including lock timeout or builder failure
- Auto-transitions to execution

## State File Transitions

| Phase | State Value |
|-------|-------------|
| Research | `"research"` |
| Requirements | `"requirements"` |
| Design | `"design"` |
| Tasks | `"tasks"` |
| Execution | `"execution"` |

`prototype` is never a value in this table or in `.ralph-state.json.phase`. It appears only in immutable prototype record frontmatter.

## Isolation And Authority

- Prototype source runs in an isolated sibling worktree or eligible scratch directory. Keep the current checkout and current conversation on their existing branch and path.
- Normal mode preserves source by default. The user chooses capture mode, verdict, handoff, and exact deletion.
- Quick mode may delete only pre-authorized ephemeral isolation after reviewed cleanup-receipt verification. Retained source, terminal records, quarantines, and normal-mode source remain preserved.
- Retained source receives a local commit on its isolated branch. `commitSpec` controls local commits of terminal spec records.
- Prototype source and records stay local. A push, branch publication, PR inclusion, issue update, or other remote action requires separate explicit authority.

## Gate Selection And Recovery

Downstream dispatchers use only valid, non-superseded, `gateApproved` terminal records. Normal records are approved only by the user's include decision. Quick `validated` and `rejected` records are agent-approved. Active blockers and stale dependent artifacts stop only affected work.

Reconcile at prototype, start, status, phase, and stop-hook boundaries. Resume a candidate when its final is missing; remove a matching candidate and active entry when a verified final exists; quarantine a hash mismatch; exclude malformed finals; resume an active entry from its recorded status and source pointers. Completion keeps `.ralph-state.json` while `activePrototypes` is nonempty.

## Phase Skipping

Not recommended but possible:
- `/ralph-specum:tasks` can be run after minimal research
- Quality may suffer without full spec phases
- Use `--fresh` to restart from any phase
