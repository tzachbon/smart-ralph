# Research: improve-task-generation

## Executive Summary

The current Ralph Specum task planner generates tasks with inconsistent granularity (15% coarse-grained), no explicit sizing constraints, and no mechanism for dynamic task modification during execution. Analysis of 17 existing specs reveals that successful specs (35+ tasks fully executed) share fine-grained tasks averaging 1-2 actions each, regular [VERIFY] checkpoints every 3-5 tasks, and clear programmatic verification. The Get Shit Done (GSD) framework provides a strong reference model with XML-structured atomic tasks, strict 2-3 tasks per plan, and auto-fix rules for executor-driven modifications.

## External Research

### Prior Art: Get Shit Done (GSD) Framework

The [GSD framework](https://github.com/glittercowboy/get-shit-done) is a spec-driven development system for Claude Code that handles task generation and execution well. Key learnings:

#### Task Format (XML-based)
```xml
<task type="auto">
  <name>Task N: [Action-oriented name]</name>
  <files>path/to/file.ext</files>
  <action>Implementation instructions</action>
  <verify>Verification command</verify>
  <done>Success criteria</done>
</task>
```

Every task has 4 required fields: `files` (exact paths), `action` (specific implementation), `verify` (runnable command), `done` (measurable acceptance criteria).

#### Granularity Rules
- **Target duration**: 15-60 minutes of Claude execution time per task
- **Split if**: Duration > 60 min, modifies > 5 files, addresses multiple subsystems, or contains multiple paragraphs of complex actions
- **Combine if**: Task 1 sets up for Task 2, both touch same file, neither meaningful alone
- **Maximum 2-3 tasks per plan** — each plan targets ~50% context budget

#### Specificity Standard
| TOO VAGUE | PRECISE |
|-----------|---------|
| "Add authentication" | "Create POST /api/auth/login accepting {email, password}, validate with bcrypt, return JWT in httpOnly cookie (15-min expiry)" |
| "Create the API" | "Create POST /api/projects accepting {name, description}, validate name 3-50 chars, return 201 with project object" |
| "Handle errors" | "Wrap calls in try/catch, return {error: string} on 4xx/5xx, display toast via sonner" |

**Clarity test**: Could another Claude instance execute this without asking clarifying questions?

#### Dynamic Executor Modifications (GSD)
GSD executor applies **automatic fixes without user approval** for:
1. **Auto-fix bugs**: Wrong queries, logic errors, type errors (no approval needed)
2. **Auto-add missing critical functionality**: Error handling, input validation, auth (no approval needed)
3. **Auto-fix blocking issues**: Missing deps, wrong types, broken imports (no approval needed)
4. **Architectural decisions**: Major structural changes → STOP, require user checkpoint

After 3 auto-fix attempts per task, executor stops and documents issues as "Deferred Issues."

### Best Practices for Atomic Task Decomposition

#### INVEST Criteria for Tasks
- **I**ndependent: Each task can be completed without other tasks running simultaneously
- **N**egotiable: Scope can be adjusted without invalidating the whole plan
- **V**aluable: Produces a meaningful, verifiable change
- **E**stimable: Scope is clear enough to estimate complexity
- **S**mall: Fits in a single focused execution session
- **T**estable: Has clear, programmatic pass/fail criteria

#### Vertical Slicing
Tasks should cut vertically through the stack — each task produces a working increment, not a horizontal layer. Instead of "Create all models, then all controllers, then all views," prefer "Create User model + controller + view for login feature."

#### Task Sizing Heuristics
- **Atomic task**: Touches 1-2 files, 1 logical change, verifiable in one command
- **If a task has > 4 "Do" steps**: Split it
- **If a task touches > 3 files**: Split it (unless tightly coupled like test + implementation)
- **If verification requires > 1 command**: Consider splitting

### Pitfalls to Avoid
1. **Over-planning**: Generating 100+ micro-tasks creates overhead that exceeds the benefit
2. **Under-specifying**: Tasks like "implement feature X" with no details lead to executor improvisation
3. **Tight coupling**: Tasks that can only succeed if a previous task was done exactly right are fragile
4. **Missing verification**: Tasks without programmatic verification are impossible to validate autonomously
5. **Context loss**: Very small tasks may lose the "big picture" — need phase-level summaries

## Codebase Analysis

### Current Task Planner Agent (task-planner.md)

**Core philosophy**: 3 focuses — POC-first workflow, clear task definitions, quality gates.

**9 mandatory rules**:
1. Fully autonomous = end-to-end validation (not just "code compiles")
2. No manual tasks (all Verify fields must be automated commands)
3. No new spec directories for testing
4. Use Explore for context gathering (spawn 2-3 Explore subagents before planning)
5. Append learnings to .progress.md
6. POC-first 4-phase workflow (mandatory)
7. VF task generation for fix goals
8. Intermediate quality checkpoints every 2-3 tasks
9. [VERIFY] task format for checkpoints

**Current task format**:
```markdown
- [ ] X.Y [TAG] Task name
  - **Do**: Steps (numbered list)
  - **Files**: File paths to create/modify
  - **Done when**: Explicit success criteria
  - **Verify**: Automated command
  - **Commit**: `conventional-commit: message`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_
```

### Key Limitations Identified

1. **No task count constraints** — no min/max tasks, no sizing guidance
2. **No task sizing definition** — no criteria for small/medium/large
3. **Quality checkpoint frequency is subjective** — "every 2-3 tasks" with no clear rules
4. **No task dependency specification** — all tasks assumed sequential
5. **POC completion criteria unclear** — no explicit transition rules between phases
6. **Verify command discovery dependency** — checkpoints depend on research finding actual commands
7. **Template has manual verification example** that contradicts "no manual tasks" rule
8. **Phase 5 is mandatory in template** but not always needed

### Current Spec-Executor Capabilities

**Execution flow**: Read .progress.md → Parse task → Execute Do steps → Verify Done when → Run Verify command → Commit → Output TASK_COMPLETE

**Current task modification capabilities (limited)**:
1. **Recovery mode** — on failure, coordinator generates fix tasks (not executor)
2. **Phase 5 dynamic tasks** — PR lifecycle creates fix/review tasks
3. **Neither executor nor coordinator can split tasks mid-execution**

**Key constraint**: Executor is read-only on task list structure. Only coordinator can modify tasks.md (via fix task generation). Executor cannot add/modify/remove tasks.

**Gaps for dynamic modification**:
- Cannot add "Install X" task if dependency discovered mid-execution
- Cannot split itself if task reveals unexpected complexity
- Cannot add prerequisite tasks
- No structured communication channel from executor → coordinator for task requests

### Existing Tasks.md Quality Analysis (17 specs)

**Statistics**:
- Average: 22.4 tasks per spec (range: 5-39)
- 41% fine-grained, 44% medium-grained, 15% coarse-grained
- Successful specs average 3.2 checkpoints per phase

**Best examples**: implement-ralph-wiggum (35 tasks, 100% completion), codebase-indexing (39 tasks, 100% completion) — both use fine-grained tasks averaging 1-2 actions.

**Common anti-patterns**:
1. **Overly coarse tasks** (8+ nested Do steps) — found in plan-source-feature, ralph-speckit
2. **Vague verification** ("manual review") — ~15% of tasks
3. **File scope creep** (5+ unrelated files in one task)
4. **Missing Done criteria** — ~5% of tasks
5. **Mixed concerns** (bundling creation + testing + CI in one task)

## Quality Commands

**Available CI workflows**:
- `bats-tests.yml` — Shell script testing framework
- `plugin-version-check.yml` — Ensures version bumps with plugin changes
- `spec-file-check.yml` — Validates spec.json/schema consistency

**Not currently available**: No package.json in repo root (this is a plugin repo, not an npm project).

## Feasibility Assessment

**Feasibility**: High — changes are primarily to markdown templates and agent prompts, no complex infrastructure needed.

**Risk**: Medium — changes to task-planner agent affect ALL future specs. Incorrect granularity rules could over-split or under-split tasks.

**Effort**: Medium — touches 3-4 key files (task-planner.md, templates/tasks.md, spec-executor.md, implement.md coordinator).

## Recommendations for Requirements

### R1: Add Explicit Task Sizing Rules to Task Planner
- Define atomic/small/medium task categories with measurable criteria
- Enforce max 4 "Do" steps per task
- Enforce max 2-3 files per task
- Add GSD-inspired clarity test: "Could another Claude instance execute without asking?"

### R2: Dramatically Increase Task Count via Splitting Rules
- Current average: 22 tasks. Target: 40-60+ tasks per spec
- Every task with > 4 steps should be split
- Every task touching > 3 files should be split
- Encourage more [VERIFY] checkpoints (every 2-3 implementation tasks)

### R3: Enable Dynamic Task Modification by Executor
- Allow spec-executor to output structured task modification requests
- Coordinator processes: SPLIT_TASK, ADD_TASK, REORDER_TASK signals
- Guardrails: max N new tasks per original, depth limit, coordinator approval
- Align with GSD's auto-fix rules (auto-fix bugs/blocking, stop for architectural)

### R4: Improve Task Template Specificity
- Replace vague placeholders with GSD-inspired specificity examples
- Add "Bad Example / Good Example" section to template
- Enforce programmatic Verify commands (ban "manual review")
- Add file scope limit to template

### R5: Add Task Modification Protocol to Spec-Executor
- New output signals: `TASK_NEEDS_SPLITTING`, `TASK_NEEDS_PREREQUISITE`
- Structured JSON payload with proposed new tasks
- Coordinator validates and inserts into tasks.md
- Update totalTasks in state

## Open Questions

1. Should task modification by executor require coordinator approval for each change, or use auto-approve rules like GSD?
2. What's the ideal maximum task count? GSD uses 2-3 per plan but has multiple plans. Should Ralph target 40-60 total or have no upper limit?
3. Should the task format change (e.g., add XML-like structure) or stay as markdown?
4. How should task splitting interact with parallel execution [P] markers?
5. Should there be a "Phase 0: Discovery" for specs where research didn't find quality commands?

## Sources

- [GSD Repository](https://github.com/glittercowboy/get-shit-done) — spec-driven development system for Claude Code
- [GSD Planner Agent](https://github.com/glittercowboy/get-shit-done/blob/main/agents/gsd-planner.md) — task format and granularity rules
- [GSD Executor Agent](https://github.com/glittercowboy/get-shit-done/blob/main/agents/gsd-executor.md) — auto-fix rules and task processing
- Internal: `plugins/ralph-specum/agents/task-planner.md` — current planner agent
- Internal: `plugins/ralph-specum/agents/spec-executor.md` — current executor agent
- Internal: `plugins/ralph-specum/commands/implement.md` — coordinator logic
- Internal: `plugins/ralph-specum/templates/tasks.md` — current task template
- Internal: 17 existing specs analyzed for quality patterns
