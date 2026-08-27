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

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Check `design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
5. Check `requirements.md` exists
6. Read `.ralph-state.json`; verify explicit design artifact approval before clearing its artifact approval flag
7. **`--tasks-size` flag handling**: Check `$ARGUMENTS` for `--tasks-size` flag:
   - If value is `fine` or `coarse`: update `granularity` in `.ralph-state.json` to the given value (overrides any value set by `/ralph-specum:start`)
   - If value is invalid (not `fine` or `coarse`): warn the user (`Invalid --tasks-size value "<value>", defaulting to fine`) and set `"granularity": "fine"` in `.ralph-state.json`
   - If `--tasks-size` is absent and `granularity` is already set, preserve it
   - If `--tasks-size` is absent and `granularity` is unset, set the documented `fine` default
8. Reject simultaneous exact `--quick` and `--interactive`. Normalize persistent mode with `phase_gate.py mode`.
9. Treat granularity as workflow administration. Never add it to the interview frontier or count it as an answered gate decision.
10. Run any missing applicable skill discovery pass. When research exists, pass 2 must be present.
11. Read context: `requirements.md`, `design.md`, `research.md` (if exists), `.progress.md`

## Step 2: Skill Load, Critical Grill, and Approval

If normalized `quickMode` is true, call `begin-interview` for phase `tasks` and continue to Step 3.

In interactive mode, reload all selected contracts and apply the interview-framework with phase `tasks`.

Use these as critical decision candidates, not a question checklist:
- **Testing thoroughness** -- minimal POC-only tests, standard unit + integration, or comprehensive E2E?
- **Deployment considerations** -- feature flags, database migrations, backward compatibility, rollback plan?
- **Execution priority** -- ship fast with shortcuts, balanced pace, or quality-first from the start?
- **Dependency ordering** -- are there tasks that must complete before others can begin?
- **Team workflow constraints** -- PR review process, CI pipeline requirements, branch strategy?
- **E2E verification** -- add autonomous end-to-end verification tasks? (default YES). What should be tested end-to-end?

Inspect test tooling, CI, dependency order, deployment mechanisms, and team conventions instead of asking about them. Keep only decisions that materially change task sequencing, acceptance, or risk. Ask the whole unblocked critical frontier in calls of at most four questions, persist partial answers, apply control-only and bare-skip semantics, and require explicit `Approve and delegate`. On approval, run `check-delegation` and launch Step 3 immediately in the same response.

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
4. **Spawn teammate**: Immediately run `check-delegation`, then call `Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1")`. Include artifact agent ID `planner-1`, the gate marker, full selected-skill manifest, approved decision brief, requirements, and design. Instruct the agent to:
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

**Revision delegation**: Run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke task-planner with reviewer feedback, gate marker, manifest, current artifact, and upstream context. The agent reloads successful sources, records receipts, and checks its write gate. Focus on specific issues.

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
2. Run `check-delegation`, then re-invoke task-planner using the **cleanup-and-recreate** team pattern with a new unique artifact agent ID, the gate marker, manifest, feedback, and current tasks.md
3. Re-display walkthrough, ask again with same 3 choices. Loop until approved.

## Step 6: Finalize

### Update State

1. Count total tasks from generated file
2. Update `.ralph-state.json`: `{ "phase": "tasks", "totalTasks": <count>, "awaitingApproval": true }`
3. Update `.progress.md`: retain the explicit design approval, set current phase, and update task count

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. If true:
```bash
git add ./specs/$spec/tasks.md
git commit -m "spec($spec): add implementation tasks"
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
