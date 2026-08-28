---
description: Generate implementation tasks from design
argument-hint: [spec-name] [--tasks-size fine|coarse] [--quick|--interactive]
allowed-tools: "*"
---

# Tasks Phase

Generate implementation tasks for the active spec after explicit design artifact approval. You are a **coordinator, not a task planner** -- delegate ALL work to the `task-planner` subagent.

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` before gathering context.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read design, requirements, research
2. **Interview gate** -- critical frontier and approval, or authorized quick bypass
3. **Execute task generation** -- dispatch task-planner via team
4. **Artifact review** -- automatic spec-reviewer loop in authorized quick mode
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`. Store the resolved spec directory as `SPEC_PATH`.
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Check `design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
5. Check `requirements.md` exists
6. Read `.ralph-state.json`, reject simultaneous exact `--quick` and `--interactive`, and normalize persistent mode with `phase_gate.py mode`.
7. When normalized `quickMode` is false, require explicit design artifact approval before clearing its approval flag. Exact quick mode continues with the validated file.
8. Clear the approval flag through the locked helper while preserving every other field:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "awaitingApproval=false"
   ```
9. **`--tasks-size` flag handling**: Check `$ARGUMENTS` for `--tasks-size` flag:
   - If value is `fine` or `coarse`: merge it with `locked-state.py merge --state "$SPEC_PATH/.ralph-state.json" --set "granularity=$GRANULARITY"` (overrides any value set by `/ralph-specum:start`)
   - If value is invalid (not `fine` or `coarse`): warn the user (`Warning: Invalid --tasks-size value "<value>", defaulting to fine`) and merge `granularity=fine` through the same helper
   - If `--tasks-size` is absent and `granularity` is already set: preserve it
   - If `--tasks-size` is absent and `granularity` is unset: merge the documented `granularity=fine` default through the same helper
10. Treat granularity as workflow administration. Never add it to the interview frontier or count it as an answered gate decision.
11. Run any missing applicable skill discovery pass. When research exists, pass 2 must be present.
12. Read context: `requirements.md`, `design.md`, `research.md` (if exists), `.progress.md`.
13. Run prototype record selection before task generation:
    ```bash
    python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" select-downstream --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json" --target tasks --target 'transition:design->tasks' --path design.md --path tasks.md
    ```
14. Include only valid, `gateApproved: true`, non-superseded prototype evidence returned by the selector. Reject skipped, failed, inconclusive, cancelled, malformed, superseded, and explicitly excluded records.
15. If selection reports an `activePrototypes` blocker for task generation, stop before Step 2 and report the active prototype ID, blocker reason, and resume command. Proven unrelated prototypes may continue only when every matching `targetDecisions` entry has `proofAvailable: true` and `eligible: true`; missing dependency or transfer-path proof blocks conservatively.
16. If selection reports stale `design.md` or an upstream artifact that design depends on, stop and route to the earliest stale phase. Do not generate tasks from stale design.
17. Pass selected prototype evidence and the clean blocker/stale-gate result to the task-planner.

## Step 2: Skill Load, Critical Grill, and Approval

Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` in full to resolve the design-tree frontier under the persisted gate state.

In both interactive and exact quick mode, reload all selected contracts and required current-work resources, hash them, record the current manifest, then call `begin-interview` for phase `tasks`. A core load failure blocks either mode.

If normalized `quickMode` is true, the helper records `bypassed_quick`; continue to Step 3 without questions.

In interactive mode, apply the interview-framework with phase `tasks`.

Use these as critical decision candidates, not a question checklist:
- **Testing thoroughness** -- minimal POC-only tests, standard unit + integration, or comprehensive E2E?
- **Deployment considerations** -- feature flags, database migrations, backward compatibility, rollback plan?
- **Execution priority** -- ship fast with shortcuts, balanced pace, or quality-first from the start?
- **Dependency ordering** -- are there tasks that must complete before others can begin?
- **Team workflow constraints** -- PR review process, CI pipeline requirements, branch strategy?
- **E2E verification** -- add autonomous end-to-end verification tasks? (default YES). What should be tested end-to-end?

Inspect test tooling, CI, dependency order, deployment mechanisms, and team conventions instead of asking about them. Keep only decisions that materially change task sequencing, acceptance, or risk. Ask the whole unblocked critical frontier in calls of at most four questions, persist partial answers, apply control-only and bare-skip semantics, and require explicit `Approve and delegate`. On approval, run `check-delegation` and launch Step 3 immediately in the same response.

Treat these candidates as exploration territory for the design tree, not a script. Add grounded sequencing or verification approaches only when they remain genuine user decisions. Apply domain-language modeling from the interview framework and append each completed frontier round to `.progress.md`.

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

Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for the explicit approval selection.

## Step 3: Execute Task Generation (Team-Based)

<mandatory>
**Use Claude Code Teams with `task-planner` as the teammate subagent type.**

ALL specs MUST follow POC-first workflow. Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` for the mandatory 5-phase structure and phase distribution rules.

Read `${CLAUDE_PLUGIN_ROOT}/references/quality-checkpoints.md` for checkpoint insertion rules (frequency, format, final verification sequence).

Follow the full team lifecycle:

1. **Clean up stale team (MANDATORY FIRST ACTION)**: Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.
2. **Create team**: `TeamCreate(team_name: "tasks-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate implementation tasks for $spec", activeForm: "Generating tasks")`
4. **Spawn teammate**: Immediately run `check-delegation`, then call `Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1")`. Include the absolute state and helper paths, complete `[RALPH_PHASE_GATE]` tuple (`state`, `phase`, `interviewId`, `discoveryRevision`, `contextDigest`), verbatim manifest, fresh artifact agent ID `planner-1`, matching load/write-check instructions, approved decision brief, requirements, design, selected prototype evidence, and the clean blocker/stale-gate result. Instruct the agent to:
   - Break implementation into POC-first phases (Phase 1-5 per phase-rules.md)
   - Create atomic, autonomous-ready tasks with Do/Files/Done when/Verify/Commit fields
   - Insert quality checkpoints per quality-checkpoints.md
   - Each task = one commit, tasks must be executable without human interaction
   - Count total tasks, output to `$SPEC_PATH/tasks.md`
   - If quick mode: auto-enable VE tasks. Pass verification tooling from research.md and strategy "auto" to task-planner
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "planner-1")`
7. **Collect results**: Read `$SPEC_PATH/tasks.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still failing, run `check-delegation` and use a direct `Task(subagent_type: task-planner)` with the same complete gate packet and a fresh unique artifact agent ID.

> **Delegation Context**: When delegating to task-planner, include these inputs:
> - **Granularity**: [fine|coarse] (from `granularity` field in `.ralph-state.json`; default to `fine` if field is absent)
>
> For VE Tasks — VE1 (startup), VE2 (check), VE3 (cleanup) — generation:
> - **E2E Verification**: enabled or disabled (from interview response, or auto-enabled in quick mode)
> - **Verification Tooling**: the Verification Tooling section from research.md (dev server commands, browser deps, ports, health endpoints)
> - **Strategy**: the user's chosen verification strategy, or "auto" in quick mode
</mandatory>

## Step 4: Automatic Artifact Review (authorized quick mode)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If normalized `quickMode` is false, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke task-planner with feedback + requirements + design context, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full tasks.md content, iteration count, prior findings. Upstream: design.md + requirements.md.

**Revision delegation**: Run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke task-planner with the absolute state/helper paths, complete marker identity tuple, verbatim manifest, matching load/write-check instructions, reviewer feedback, current artifact, and upstream context. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `$SPEC_PATH/tasks.md` and display:

```
Tasks complete for '$spec'.
Output: $SPEC_PATH/tasks.md

## What I Planned

**Total**: [X] tasks across 5 phases

**Phase Breakdown**:
- Phase 1 (POC): [count] tasks - proves the idea works
- Phase 2 (Refactor): [count] tasks - clean up
- Phase 3 (Testing): [count] tasks - add coverage
- Phase 4 (Quality): [count] tasks - CI/PR
- Phase 5 (PR Lifecycle): [count] tasks - keep CI and review green through completion

**POC Milestone**: Task [X.Y] - [brief description of what's working at that point]
```
</mandatory>

### User Approval (interactive mode)

If normalized `quickMode` is true, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Approve** (Recommended) -- Accept artifact as-is, advance to next phase
2. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
3. **Request changes** -- Provide specific feedback to revise the artifact

**If "Approve"**: proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full tasks.md content (upstream: design.md + requirements.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 3-choice question (user decides next action).
**If "Request changes", "Other", or `apply the changes`**:
1. Apply already-recorded review or revision feedback immediately. Ask one focused change question only when no pending feedback exists.
2. Run `check-delegation`, then re-invoke task-planner using the **cleanup-and-recreate** team pattern with the same complete packet and a new unique artifact agent ID, feedback, and current tasks.md
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
3. Update `.progress.md`: retain the explicit design approval, set current phase, and update task count

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. It authorizes the local commit only. If true:
```bash
git add "$SPEC_PATH/tasks.md"
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

(Does not apply when normalized quick mode is authorized.)

1. Display: `-> Next: Run /ralph-specum:implement to start execution`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:implement`
</mandatory>
