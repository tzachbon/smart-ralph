---
spec: improve-task-generation
phase: requirements
created: 2026-02-19
---

# Requirements: Improve Task Generation

## Goal

Transform Ralph's task planner and executor to generate dramatically more granular, clearer tasks (target 40-60+ per spec vs current avg 22.4) and enable the executor to dynamically adapt the task plan during execution via structured signals.

## User Decisions

Captured from interview:

| Decision | Answer |
|----------|--------|
| Primary problem | All — tasks too coarse, not enough tasks, lack clarity/structure |
| Who can modify tasks? | Both planner and executor, with guardrails. Executor suggests changes via protocol (update tasks.md, log reasoning) |
| Success looks like | Atomic tasks with clear AC, executor rarely improvises, dynamic adaptation when needed |
| Inspiration | GSD (Get Shit Done) framework for task structure |
| Primary consumers | AI agents (spec-executor and task-planner) |
| Priority tradeoff | Balanced — equal weight on better initial generation AND dynamic modification |
| Success metric | More tasks + dynamic adaptation + fewer executor failures/improvisations |

## User Stories

### US-1: Atomic Task Generation

**As a** task-planner agent
**I want to** generate tasks with strict sizing constraints (max 4 Do steps, max 2-3 files)
**So that** each task is small enough for the executor to complete without improvisation

**Acceptance Criteria:**
- [ ] AC-1.1: Every generated task has <= 4 numbered steps in its Do section
- [ ] AC-1.2: Every generated task touches <= 3 files in its Files section (except tightly-coupled test+impl pairs)
- [ ] AC-1.3: Task planner agent contains explicit sizing rules with split-if/combine-if thresholds
- [ ] AC-1.4: Tasks with > 4 Do steps are automatically split into multiple smaller tasks
- [ ] AC-1.5: A "clarity test" instruction exists: "Could another Claude instance execute this without asking clarifying questions?"

### US-2: Higher Task Count via Splitting Rules

**As a** task-planner agent
**I want to** follow mandatory splitting rules that produce 40-60+ tasks per spec
**So that** execution proceeds in small, verifiable increments

**Acceptance Criteria:**
- [ ] AC-2.1: Task planner contains a target task count guidance of 40-60+ tasks for standard specs
- [ ] AC-2.2: Splitting rules documented: split if > 4 Do steps, > 3 files, > 1 logical concern, or mixed creation+testing
- [ ] AC-2.3: Anti-combination rules: never bundle "create file" + "write tests" + "run CI" in one task
- [ ] AC-2.4: Phase-level task count guidance exists (e.g., Phase 1 = 50-60% of tasks, Phase 2 = 15-20%, etc.)

### US-3: Task Specificity and Bad/Good Examples

**As a** task-planner agent
**I want to** reference concrete bad/good example pairs in the template
**So that** I generate precise tasks instead of vague ones

**Acceptance Criteria:**
- [ ] AC-3.1: Template contains >= 3 bad/good example pairs (vague vs. precise tasks)
- [ ] AC-3.2: Examples cover different task types: file creation, API integration, refactoring
- [ ] AC-3.3: Template enforces "Verify must be a runnable command" with no manual verification allowed
- [ ] AC-3.4: Template "manual test" placeholder in current templates replaced with automated command examples

### US-4: Dynamic Task Modification by Executor

**As a** spec-executor agent
**I want to** signal task modification requests (split, add prerequisite, add follow-up) to the coordinator
**So that** the task plan adapts to discoveries made during execution

**Acceptance Criteria:**
- [ ] AC-4.1: Executor can output `TASK_MODIFICATION_REQUEST` with a structured payload describing the change
- [ ] AC-4.2: Three modification types supported: `SPLIT_TASK`, `ADD_PREREQUISITE`, `ADD_FOLLOWUP`
- [ ] AC-4.3: Each request includes: proposed task markdown, reasoning, and affected task IDs
- [ ] AC-4.4: Coordinator validates and inserts approved modifications into tasks.md
- [ ] AC-4.5: Coordinator increments totalTasks in state after inserting new tasks
- [ ] AC-4.6: Max 3 modification requests per original task (prevents runaway expansion)
- [ ] AC-4.7: Executor logs every modification request and outcome in .progress.md

### US-5: Coordinator Handles Modification Requests

**As the** coordinator (implement.md)
**I want to** parse and process task modification requests from the executor
**So that** the task plan stays up to date without manual intervention

**Acceptance Criteria:**
- [ ] AC-5.1: Coordinator detects `TASK_MODIFICATION_REQUEST` in executor output
- [ ] AC-5.2: Coordinator parses the structured payload (type, proposed tasks, reasoning)
- [ ] AC-5.3: For `SPLIT_TASK`: marks original as [x], inserts sub-tasks after it, updates totalTasks
- [ ] AC-5.4: For `ADD_PREREQUISITE`: inserts new task before current task, shifts execution
- [ ] AC-5.5: For `ADD_FOLLOWUP`: inserts new task after current task
- [ ] AC-5.6: Coordinator logs modification action in .progress.md under "Task Modifications" section
- [ ] AC-5.7: Guardrail: rejects requests that exceed depth limit (max 2 levels of nesting, e.g., 1.3.1.1 is deepest)

### US-6: Improved Task Template

**As a** task-planner agent
**I want to** use an updated tasks.md template with sizing rules, examples, and quality guidance
**So that** every generated task file follows best practices by default

**Acceptance Criteria:**
- [ ] AC-6.1: Template header includes task sizing rules (max Do steps, max files)
- [ ] AC-6.2: Template includes bad/good example section before Phase 1
- [ ] AC-6.3: All placeholder Verify fields use automated commands (no "manually test")
- [ ] AC-6.4: Template includes a "Task Quality Checklist" that the planner runs before finalizing

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Task sizing rules: max 4 Do steps, max 2-3 files per task | P0 | Planner agent contains enforceable rules with split-if thresholds |
| FR-2 | Splitting rules: auto-split when sizing thresholds exceeded | P0 | Rules documented in planner; tasks exceeding limits are split |
| FR-3 | Task count target: 40-60+ tasks for standard specs | P0 | Guidance in planner with phase distribution ratios |
| FR-4 | Clarity test: "Could another Claude execute without asking?" | P0 | Instruction present in planner mandatory section |
| FR-5 | Bad/good example pairs in template (>= 3 pairs) | P0 | Template updated with concrete vague-vs-precise comparisons |
| FR-6 | Ban manual verification in templates and planner | P0 | No Verify field uses "manual", "visually", or "ask user" |
| FR-7 | Executor TASK_MODIFICATION_REQUEST signal | P1 | Executor can output structured modification requests |
| FR-8 | Coordinator modification request parser | P1 | Coordinator detects and processes SPLIT/ADD_PREREQ/ADD_FOLLOWUP |
| FR-9 | Modification guardrails: max 3 per task, depth limit 2 | P1 | Coordinator enforces limits, rejects excess requests |
| FR-10 | Modification logging in .progress.md | P1 | All requests and outcomes logged under "Task Modifications" section |
| FR-11 | Task quality checklist in planner | P1 | Planner runs checklist before finalizing tasks.md |
| FR-12 | Phase distribution guidance | P2 | Planner has recommended % split across phases |
| FR-13 | Task dependency hints (optional) | P2 | Tasks can specify "depends-on: X.Y" for ordering clarity |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Task planner prompt stays within context limits | Token count of task-planner.md | < 8000 tokens (current ~4500) |
| NFR-2 | No regression in existing execution flow | Existing specs continue executing | 100% backwards compatible |
| NFR-3 | Modification request parsing latency | Time to parse and insert | < 2 seconds (negligible overhead) |
| NFR-4 | Template clarity for AI consumers | Planner generates correct format on first attempt | > 95% format compliance |

## Glossary

- **Atomic task**: Task with 1-2 files, 1 logical change, <= 4 Do steps, verifiable in one command
- **Clarity test**: Heuristic — "Could another Claude instance execute this without asking clarifying questions?"
- **TASK_MODIFICATION_REQUEST**: Structured signal from executor to coordinator requesting task plan changes
- **SPLIT_TASK**: Modification type: break one task into 2+ smaller tasks
- **ADD_PREREQUISITE**: Modification type: insert a task before the current one
- **ADD_FOLLOWUP**: Modification type: insert a task after the current one
- **GSD**: "Get Shit Done" framework — reference spec-driven dev system for Claude Code
- **Sizing threshold**: Max Do steps (4) and max files (3) before a task must be split
- **Phase distribution**: Recommended % of total tasks per phase (e.g., Phase 1 = 50-60%)

## Out of Scope

- Changing task format from markdown to XML (stay with current markdown format)
- Adding a "Phase 0: Discovery" phase
- Modifying parallel execution [P] marker behavior
- Changing the [VERIFY] checkpoint system (already working well)
- Auto-merging PRs or changing Phase 5 PR lifecycle
- Upper limit cap on task count (no hard max — only guidance)
- Executor auto-approving its own modifications (coordinator always validates)
- Changing the state file (.ralph-state.json) schema beyond adding modification tracking fields

## Dependencies

- Research findings from 17 existing spec analysis (completed)
- GSD framework reference patterns (researched)
- Current task-planner.md, spec-executor.md, implement.md, templates/tasks.md (all read)
- Related spec: parallel-task-execution (modification requests must not break [P] marker logic)
- Related spec: iterative-failure-recovery (fix task generation must coexist with modification requests)

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Over-splitting produces 100+ micro-tasks | High — overhead exceeds benefit, context loss | Phase distribution guidance, "combine-if" rules, no hard max but soft 60 target |
| Executor abuses modification requests | Medium — runaway task expansion | Max 3 per task, depth limit 2, coordinator validation |
| Larger planner prompt degrades generation quality | Medium — prompt too long for model to follow | Keep additions concise, use examples not prose, stay < 8000 tokens |
| Backwards incompatibility with existing specs | High — breaks in-progress specs | All changes additive, no removal of existing fields, modification signals are opt-in |

## Success Criteria

1. **Task count**: New specs generate 40-60+ tasks (up from avg 22.4)
2. **Task granularity**: >= 90% of tasks have <= 4 Do steps and <= 3 files
3. **Executor improvisation**: Executor outputs TASK_MODIFICATION_REQUEST instead of silently improvising
4. **Clarity**: 0% of tasks use manual/vague verification
5. **Dynamic adaptation**: Executor can request task modifications that coordinator processes within same execution loop
6. **No regression**: Existing execution flow, [VERIFY] system, and parallel execution work unchanged

## Unresolved Questions

- Should modification request payload be JSON or markdown? JSON is easier to parse; markdown is consistent with tasks.md format. Recommend: JSON payload containing markdown task blocks.
- Should there be a configurable "aggressiveness" setting for splitting (conservative = 30 tasks, aggressive = 60+)? Recommend: single mode with soft guidance, not configurable.
- How should task modifications interact with parallel [P] batches mid-execution? Recommend: modifications break out of current parallel batch and re-evaluate.

## Next Steps

1. Design the modification request protocol (signal format, payload schema, coordinator parsing)
2. Design updated task-planner.md sizing rules and splitting logic
3. Design updated tasks.md template with examples and quality checklist
4. Proceed to implementation after design approval
