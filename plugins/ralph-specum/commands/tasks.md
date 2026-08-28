---
description: Generate implementation tasks from design
argument-hint: [spec-name] [--tasks-size fine|coarse]
allowed-tools: "*"
---

# Tasks Phase

Generate implementation tasks for the active spec. Running this command implicitly approves design. You are a **coordinator, not a task planner** -- delegate ALL work to the `task-planner` subagent.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read design, requirements, research
2. **Grill** -- resolve the design-tree frontier (skip if `--quick`)
3. **Execute task generation** -- dispatch task-planner via team
4. **Artifact review** -- spec-reviewer validation loop (only if `--quick`)
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Check `design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
5. Check `requirements.md` exists
6. Clear the approval flag through the locked helper while preserving every other field:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "awaitingApproval=false"
   ```
7. **`--tasks-size` flag handling**: Check `$ARGUMENTS` for `--tasks-size` flag:
   - If value is `fine` or `coarse`: merge it with `locked-state.py merge --state "$SPEC_PATH/.ralph-state.json" --set "granularity=$GRANULARITY"` (overrides any value set by `/ralph-specum:start`)
   - If value is invalid (not `fine` or `coarse`): warn the user (`Warning: Invalid --tasks-size value "<value>", defaulting to fine`) and merge `granularity=fine` through the same helper
   - If `--tasks-size` flag is absent: leave `granularity` unchanged in `.ralph-state.json` (preserve any value set by `/ralph-specum:start`)
8. **Quick mode granularity default**: If `--quick` is present in `$ARGUMENTS` AND `granularity` is not set in the current state, merge `granularity=fine` through `locked-state.py`; never replace the state object
9. Read context: `requirements.md`, `design.md`, `research.md` (if exists), `.progress.md`
10. Run prototype record selection before task generation:
    ```bash
    python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" select-downstream --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json"
    ```
11. Include only valid, `gateApproved: true`, non-superseded prototype evidence returned by the selector. Reject skipped, failed, inconclusive, cancelled, malformed, superseded, and explicitly excluded records.
12. If selection reports an `activePrototypes` blocker for task generation, stop before Step 2 and report the active prototype ID, blocker reason, and resume command. Proven unrelated prototypes do not block task generation.
13. If selection reports stale `design.md` or an upstream artifact that design depends on, stop and route to the earliest stale phase. Do not generate tasks from stale design.
14. Pass selected prototype evidence and the clean blocker/stale-gate result to the task-planner.

## Step 2: Grill (skip if --quick)

Check if `--quick` appears in `$ARGUMENTS`. If present, skip to Step 3.

### Grilling

Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` in full. It owns context and spec-index reading, fact lookup, the design tree, frontier rounds, domain-language work, progress capture, and the shared-understanding confirmation gate.

Read intent classification and prior interview responses only as context for building the tree. Do not derive question counts from intent.

**Tasks Exploration Territory** (hints, not a script):
- **Testing thoroughness** -- minimal POC-only tests, standard unit + integration, or comprehensive E2E?
- **Deployment considerations** -- feature flags, database migrations, backward compatibility, rollback plan?
- **Execution priority** -- ship fast with shortcuts, balanced pace, or quality-first from the start?
- **Dependency ordering** -- are there tasks that must complete before others can begin?
- **Team workflow constraints** -- PR review process, CI pipeline requirements, branch strategy?
- **E2E verification** -- add autonomous end-to-end verification tasks? (default YES). What should be tested end-to-end?
- **Task granularity** -- fine (40-60+ small tasks, ideal for parallel) or coarse (10-20 larger tasks, fewer tokens)? Both include [VERIFY] checkpoints every 2-3 tasks. Fine is recommended.

**Granularity question skip conditions**: Only ask the "Task granularity" question when ALL of these are true:
- `--quick` is NOT present in `$ARGUMENTS`
- `granularity` is NOT already set in `.ralph-state.json` (i.e., not pre-set via `--tasks-size` flag on `/ralph-specum:start` or `/ralph-specum:tasks`)

If either condition is false, skip the granularity question:
- In `--quick` mode: handled in Step 1 (quick mode granularity default)
- If `granularity` already set in `.ralph-state.json`: use the existing value without asking

When the user answers the granularity question, store the response in `.progress.md` under Interview Responses and merge `granularity` through `locked-state.py merge`.

### Execution Strategy Branch

When execution strategy requires a user decision, add 2-3 grounded strategies to the design tree. Examples (illustrative only):
- **(A)** Aggressive POC -- fewer tasks, ship in small increments, add polish later
- **(B)** Thorough -- more tasks with full test coverage and quality gates throughout
- **(C)** Phased delivery -- split into multiple PRs with clear milestones

### Store Grill Results

Append to `.progress.md` under "Interview Responses":
```markdown
### Tasks Grill (from tasks.md)
- [Round decisions and resolved facts]
- E2E verification: YES/NO -- [strategy or "auto"]
- Chosen approach: [name] -- [brief description]
- Shared understanding: confirmed
```

Pass combined context to delegation prompt as "Interview Context".

## Step 3: Execute Task Generation (Team-Based)

<mandatory>
**Use Claude Code Teams with `task-planner` as the teammate subagent type.**

ALL specs MUST follow POC-first workflow. Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` for the mandatory 5-phase structure and phase distribution rules.

Read `${CLAUDE_PLUGIN_ROOT}/references/quality-checkpoints.md` for checkpoint insertion rules (frequency, format, final verification sequence).

Follow the full team lifecycle:

1. **Clean up stale team (MANDATORY FIRST ACTION)**: Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.
2. **Create team**: `TeamCreate(team_name: "tasks-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate implementation tasks for $spec", activeForm: "Generating tasks")`
4. **Spawn teammate**: `Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1")` -- delegate with requirements, design, selected prototype evidence, the clean blocker/stale-gate result, and interview context. Instruct to:
   - Break implementation into POC-first phases (Phase 1-5 per phase-rules.md)
   - Create atomic, autonomous-ready tasks with Do/Files/Done when/Verify/Commit fields
   - Insert quality checkpoints per quality-checkpoints.md
   - Each task = one commit, tasks must be executable without human interaction
   - Count total tasks, output to `./specs/$spec/tasks.md`
   - If quick mode: auto-enable VE tasks. Pass verification tooling from research.md and strategy "auto" to task-planner
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "planner-1")`
7. **Collect results**: Read `./specs/$spec/tasks.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: task-planner)` call.

> **Delegation Context**: When delegating to task-planner, include these inputs:
> - **Granularity**: [fine|coarse] (from `granularity` field in `.ralph-state.json`; default to `fine` if field is absent)
>
> For VE Tasks — VE1 (startup), VE2 (check), VE3 (cleanup) — generation:
> - **E2E Verification**: enabled or disabled (from interview response, or auto-enabled in quick mode)
> - **Verification Tooling**: the Verification Tooling section from research.md (dev server commands, browser deps, ports, health endpoints)
> - **Strategy**: the user's chosen verification strategy, or "auto" in quick mode
</mandatory>

## Step 4: Artifact Review (only in --quick mode)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If NOT `--quick`, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke task-planner with feedback + requirements + design context, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full tasks.md content, iteration count, prior findings. Upstream: design.md + requirements.md.

**Revision delegation**: Re-invoke task-planner with reviewer feedback and upstream context. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/tasks.md` and display:

```
Tasks complete for '$spec'.
Output: $PWD/specs/$spec/tasks.md

## What I Planned

**Total**: [X] tasks across 4 phases

**Phase Breakdown**:
- Phase 1 (POC): [count] tasks - proves the idea works
- Phase 2 (Refactor): [count] tasks - clean up
- Phase 3 (Testing): [count] tasks - add coverage
- Phase 4 (Quality): [count] tasks - CI/PR

**POC Milestone**: Task [X.Y] - [brief description of what's working at that point]
```
</mandatory>

### User Approval (skip if --quick)

If `--quick`, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Approve** (Recommended) -- Accept artifact as-is, advance to next phase
2. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
3. **Request changes** -- Provide specific feedback to revise the artifact

**If "Approve"**: proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full tasks.md content (upstream: design.md + requirements.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 3-choice question (user decides next action).
**If "Request changes" or "Other"**:
1. Ask what to change
2. Re-invoke task-planner using **cleanup-and-recreate** team pattern (TeamDelete old -> TeamCreate new -> spawn with feedback + current tasks.md -> wait -> shutdown -> TeamDelete)
3. Re-display walkthrough, ask again with same 3 choices. Loop until approved.

## Step 6: Finalize

### Update State

1. Count total tasks from the generated file into `TOTAL_TASKS`
2. Merge the task phase fields through the locked helper, preserving every existing and unknown field:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "phase=tasks" \
     --set "totalTasks=$TOTAL_TASKS" \
     --set "awaitingApproval=true"
   ```
3. Update `.progress.md`: mark design as implicitly approved, set current phase, update task count

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. It authorizes the local commit only. If true:
```bash
git add ./specs/$spec/tasks.md
git commit -m "spec($spec): add implementation tasks"
```

In quick mode, skip only this push: do not ask a remote question, do not push, and continue the quick phase flow. In normal mode, run the Prototype Evidence Push Gate from `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` immediately before the existing push. If outbound commits contain `**/prototypes/*.md`, require separate explicit authorization naming every exact record; otherwise preserve the existing push behavior.

```bash
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO IMPLEMENT.**

(Does not apply in `--quick` mode.)

1. Display: `-> Next: Run /ralph-specum:implement to start execution`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:implement`
</mandatory>
