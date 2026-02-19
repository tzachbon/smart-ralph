---
spec: improve-task-generation
phase: tasks
total_tasks: 48
created: 2026-02-19
---

# Tasks: Improve Task Generation

## Overview

Total tasks: 48
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Add all content to all 7 files
2. Phase 2: Refactoring - Cross-file consistency, wording polish
3. Phase 3: Testing - Automated verification of all changes
4. Phase 4: Quality Gates - CI checks, version bump, PR
5. Phase 5: PR Lifecycle - CI monitoring, review resolution

## Execution Context

| Setting | Value |
|---------|-------|
| Testing depth | Standard - unit + integration (balanced for markdown-prompt plugin) |
| Deployment approach | Standard CI/CD pipeline (existing CI checks) |
| Execution priority | Balanced - reasonable quality with speed |

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: Existing execution flow unchanged, no broken specs
- All 7 files modified per design document
- No "manual" verification patterns in any template/agent
- Task sizing rules present in task-planner.md
- Bad/good examples present in templates/tasks.md
- TASK_MODIFICATION_REQUEST protocol in spec-executor.md
- Modification handler in implement.md
- State schema extended with modificationMap
- Plugin version bumped
- CI green, PR ready

> **Quality Checkpoints**: Intermediate quality gate checks inserted every 2-3 tasks.

## Phase 1: Make It Work (POC)

Focus: Insert all new content into the 7 target files. Follow design document content exactly. Validate each insertion is syntactically correct.

### Component B: Bad/Good Examples (templates/tasks.md)

- [x] 1.1 Add Task Writing Guide header and principles to templates/tasks.md
  - **Do**:
    1. Open `plugins/ralph-specum/templates/tasks.md`
    2. After line 27 (the `> **Quality Checkpoints**:...` line, before `## Phase 1`), insert the first part of the Task Writing Guide: the `## Task Writing Guide` header, sizing rules summary, and `### Task Writing Principles` subsection (4 principles: Think First, Simplicity, Surgical, Goal-Driven)
    3. Use exact content from design.md Component B lines 122-131
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: `## Task Writing Guide` section exists between Completion Criteria and Phase 1, containing 4 numbered principles
  - **Verify**: `grep -c "Task Writing Principles" plugins/ralph-specum/templates/tasks.md | grep -q 1`
  - **Commit**: `feat(templates): add task writing principles to tasks.md template`
  - _Requirements: FR-5, AC-3.1, AC-6.2_
  - _Design: Component B_

- [x] 1.2 Add Bad vs Good Example 1 (File Creation) to templates/tasks.md
  - **Do**:
    1. In `plugins/ralph-specum/templates/tasks.md`, after the Task Writing Principles subsection, add `### Bad vs. Good Examples` header
    2. Add Example 1 "File Creation (too vague vs. precise)" with BAD and GOOD blocks
    3. Use exact content from design.md Component B lines 135-151
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: Example 1 with BAD/GOOD pair for file creation exists in template
  - **Verify**: `grep -q "Example 1: File Creation" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `feat(templates): add bad/good example 1 - file creation`
  - _Requirements: FR-5, AC-3.1, AC-3.2_
  - _Design: Component B_

- [x] 1.3 Add Bad vs Good Example 2 (Integration) to templates/tasks.md
  - **Do**:
    1. After Example 1 in templates/tasks.md, add Example 2 "Integration (bundled vs. atomic)"
    2. Use exact content from design.md Component B lines 153-169
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: Example 2 with BAD/GOOD pair for integration exists
  - **Verify**: `grep -q "Example 2: Integration" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `feat(templates): add bad/good example 2 - integration`
  - _Requirements: FR-5, AC-3.1, AC-3.2_
  - _Design: Component B_

- [x] 1.4 [VERIFY] Quality checkpoint: grep validation of template structure
  - **Do**: Verify templates/tasks.md has correct structure after Examples 1-2
  - **Verify**: `grep -c "### Bad vs. Good Examples" plugins/ralph-specum/templates/tasks.md | grep -q 1 && grep -c "Example 1:" plugins/ralph-specum/templates/tasks.md | grep -q 1 && grep -c "Example 2:" plugins/ralph-specum/templates/tasks.md | grep -q 1`
  - **Done when**: All 3 grep checks pass
  - **Commit**: `chore(templates): pass quality checkpoint` (only if fixes needed)

- [x] 1.5 Add Bad vs Good Example 3 (Refactoring) to templates/tasks.md
  - **Do**:
    1. After Example 2, add Example 3 "Refactoring (overloaded vs. focused)"
    2. Use exact content from design.md Component B lines 171-186
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: Example 3 with BAD/GOOD pair for refactoring exists
  - **Verify**: `grep -q "Example 3: Refactoring" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `feat(templates): add bad/good example 3 - refactoring`
  - _Requirements: FR-5, AC-3.1, AC-3.2_
  - _Design: Component B_

- [x] 1.6 Add Bad vs Good Example 4 (Goal-Driven) to templates/tasks.md
  - **Do**:
    1. After Example 3, add Example 4 "Goal-Driven (imperative command vs. success criteria)"
    2. Use exact content from design.md Component B lines 188-205
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: Example 4 with BAD/GOOD pair for goal-driven pattern exists
  - **Verify**: `grep -q "Example 4: Goal-Driven" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `feat(templates): add bad/good example 4 - goal-driven`
  - _Requirements: FR-5, AC-3.1, AC-3.2_
  - _Design: Component B_

- [x] 1.7 Fix POC Checkpoint manual verification in templates/tasks.md
  - **Do**:
    1. Find the POC Checkpoint task block (currently at ~line 67-70 before our additions shifted lines)
    2. Replace the existing POC checkpoint block that has `**Verify**: Manual test of core flow` with the updated version from design.md lines 219-223
    3. New Verify: `Run automated end-to-end verification (e.g., \`curl API | jq\`, browser automation script, or test command)`
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: No "Manual test" string exists in templates/tasks.md Verify fields
  - **Verify**: `! grep -q "Manual test" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `fix(templates): replace manual test with automated verification in POC checkpoint`
  - _Requirements: FR-6, AC-3.3, AC-3.4, AC-6.3_
  - _Design: Component B_

- [x] 1.8 [VERIFY] Quality checkpoint: full template validation
  - **Do**: Verify templates/tasks.md has all 4 examples and no manual verification
  - **Verify**: `grep -c "Example [1-4]:" plugins/ralph-specum/templates/tasks.md | grep -q 4 && ! grep -qi "manual test" plugins/ralph-specum/templates/tasks.md && grep -q "Task Writing Principles" plugins/ralph-specum/templates/tasks.md`
  - **Done when**: 4 examples present, no manual test, principles section exists
  - **Commit**: `chore(templates): pass quality checkpoint` (only if fixes needed)

### Component A: Task Sizing Rules (task-planner.md)

- [x] 1.9 Add Task Sizing Rules section to task-planner.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/task-planner.md`
    2. After the `</mandatory>` closing tag of the `## [VERIFY] Task Format` section (line 281), insert the new `## Task Sizing Rules` section
    3. Include the `<mandatory>` block with: size limits (max 4 Do steps, max 3 files, 1 logical concern), split-if rules, combine-if rules
    4. Use exact content from design.md Component A lines 79-95
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: `## Task Sizing Rules` section exists after `## [VERIFY] Task Format` with split-if/combine-if rules
  - **Verify**: `grep -q "## Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Split if:" plugins/ralph-specum/agents/task-planner.md && grep -q "Combine if:" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `feat(task-planner): add task sizing rules with split/combine thresholds`
  - _Requirements: FR-1, FR-2, AC-1.1, AC-1.2, AC-1.3, AC-2.2, AC-2.3_
  - _Design: Component A_

- [x] 1.10 Add target task count and principles to Task Sizing Rules
  - **Do**:
    1. In the `## Task Sizing Rules` section just added, after the combine-if rules, add: target task count (40-60+), phase distribution ratios, simplicity principle, surgical principle, clarity test
    2. Use exact content from design.md Component A lines 101-110 (from `**Target task count:**` through `</mandatory>`)
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: Target task count "40-60+" exists, phase distribution percentages present, clarity test question present
  - **Verify**: `grep -q "40-60+" plugins/ralph-specum/agents/task-planner.md && grep -q "Phase distribution:" plugins/ralph-specum/agents/task-planner.md && grep -q "Clarity test" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `feat(task-planner): add task count targets and clarity test`
  - _Requirements: FR-3, FR-4, AC-2.1, AC-2.4, AC-1.5_
  - _Design: Component A_

- [x] 1.11 [VERIFY] Quality checkpoint: task-planner sizing rules complete
  - **Do**: Verify task-planner.md has all sizing rules components
  - **Verify**: `grep -q "Max 4 numbered steps" plugins/ralph-specum/agents/task-planner.md && grep -q "Max 3 files" plugins/ralph-specum/agents/task-planner.md && grep -q "Simplicity principle" plugins/ralph-specum/agents/task-planner.md && grep -q "Surgical principle" plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: All 4 sizing components verified
  - **Commit**: `chore(task-planner): pass quality checkpoint` (only if fixes needed)

### Component C: Quality Checklist (task-planner.md)

- [x] 1.12 Replace Quality Checklist in task-planner.md with expanded version
  - **Do**:
    1. In `plugins/ralph-specum/agents/task-planner.md`, find the existing `## Quality Checklist` section (starts at line 506 in original, shifted by previous insertions)
    2. Replace the entire section (from `## Quality Checklist` through the last `- [ ]` item before `## Final Step`) with the expanded version from design.md Component C lines 236-252
    3. New checklist has 14 items including: sizing checks, manual verification ban, task count 40+, meaningful Done when, simplicity/surgical/think-first principle checks
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: Quality Checklist has 14+ items including "All tasks have <= 4 Do steps" and "Total task count is 40+"
  - **Verify**: `grep -q "All tasks have <= 4 Do steps" plugins/ralph-specum/agents/task-planner.md && grep -q "Total task count is 40+" plugins/ralph-specum/agents/task-planner.md && grep -q 'No Verify field contains "manual"' plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `feat(task-planner): expand quality checklist with sizing and principle checks`
  - _Requirements: FR-11, AC-6.4_
  - _Design: Component C_

- [x] 1.13 [VERIFY] Quality checkpoint: task-planner.md fully updated
  - **Do**: Verify task-planner.md has both new sections (sizing rules + expanded checklist)
  - **Verify**: `grep -q "## Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Total task count is 40+" plugins/ralph-specum/agents/task-planner.md && grep -q "50-60%" plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Both sections present with correct content
  - **Commit**: `chore(task-planner): pass quality checkpoint` (only if fixes needed)

### Component D: TASK_MODIFICATION_REQUEST Protocol (spec-executor.md)

- [x] 1.14 Add Task Modification Requests header and when-to-request rules to spec-executor.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/spec-executor.md`
    2. After the `## Error Handling` section's last line (line 359: `Lying about completion wastes iterations and breaks the spec workflow.`), before `## Communication Style`, insert `## Task Modification Requests` with the `<mandatory>` opening, think-first principle paragraph, and "When to request modification" bullet list
    3. Use exact content from design.md Component D lines 263-276
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: `## Task Modification Requests` section exists with 5 "when to request" bullets
  - **Verify**: `grep -q "## Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "When to request modification" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add task modification request header and triggers`
  - _Requirements: FR-7, AC-4.1_
  - _Design: Component D_

- [x] 1.15 Add TASK_MODIFICATION_REQUEST signal format to spec-executor.md
  - **Do**:
    1. After the "When to request modification" bullets, add the "Signal format" section with the JSON structure showing type, originalTaskId, reasoning, proposedTasks
    2. Use exact content from design.md Component D lines 278-291
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: Signal format with JSON template containing `SPLIT_TASK | ADD_PREREQUISITE | ADD_FOLLOWUP` exists
  - **Verify**: `grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/agents/spec-executor.md && grep -q "SPLIT_TASK" plugins/ralph-specum/agents/spec-executor.md && grep -q "ADD_PREREQUISITE" plugins/ralph-specum/agents/spec-executor.md && grep -q "ADD_FOLLOWUP" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add modification request signal format`
  - _Requirements: FR-7, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Component D_

- [x] 1.16 [VERIFY] Quality checkpoint: spec-executor signal format
  - **Do**: Verify spec-executor.md has the modification request section with all 3 types
  - **Verify**: `grep -c "SPLIT_TASK\|ADD_PREREQUISITE\|ADD_FOLLOWUP" plugins/ralph-specum/agents/spec-executor.md | awk '{exit ($1 >= 3) ? 0 : 1}'`
  - **Done when**: All 3 modification types referenced at least once
  - **Commit**: `chore(spec-executor): pass quality checkpoint` (only if fixes needed)

- [x] 1.17 Add modification types table and rules to spec-executor.md
  - **Do**:
    1. After the signal format, add the "Modification types" table (3 rows: SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP with When/Effect columns)
    2. Add the "Rules" section: max 3 per task, standard format required, sizing rules apply, TASK_COMPLETE behavior per type
    3. Use exact content from design.md Component D lines 293-306
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: Modification types table with 3 rows exists, rules section with max 3 limit exists
  - **Verify**: `grep -q "Max 3 modification requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "ADD_PREREQUISITE, do NOT output TASK_COMPLETE" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add modification types table and rules`
  - _Requirements: FR-7, AC-4.2, AC-4.5, AC-4.6_
  - _Design: Component D_

- [x] 1.18 Add ADD_PREREQUISITE example and closing tags to spec-executor.md
  - **Do**:
    1. After the rules section, add the "Example: ADD_PREREQUISITE" section showing Redis caching scenario
    2. Add the closing `</mandatory>` tag
    3. Use exact content from design.md Component D lines 308-327
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: Redis example exists, `</mandatory>` closes the section
  - **Verify**: `grep -q "Redis client" plugins/ralph-specum/agents/spec-executor.md && grep -q "ioredis" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add prerequisite example to modification protocol`
  - _Requirements: FR-7, AC-4.3_
  - _Design: Component D_

- [x] 1.19 [VERIFY] Quality checkpoint: spec-executor.md modification protocol complete
  - **Do**: Verify full modification protocol section in spec-executor.md
  - **Verify**: `grep -q "## Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/agents/spec-executor.md && grep -q "Max 3 modification" plugins/ralph-specum/agents/spec-executor.md && grep -q "Example: ADD_PREREQUISITE" plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: All 4 key elements of the protocol verified
  - **Commit**: `chore(spec-executor): pass quality checkpoint` (only if fixes needed)

### Component F: State Schema Extension (spec.schema.json)

- [x] 1.20 Add modificationMap to spec.schema.json
  - **Do**:
    1. Open `plugins/ralph-specum/schemas/spec.schema.json`
    2. In the `definitions.state.properties` object, after the `fixTaskMap` property (ends around line 148), add the `modificationMap` property
    3. Use exact schema from design.md Component F lines 434-456: type object, default {}, additionalProperties with count (integer), modifications (array of {id, type, reason})
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `modificationMap` property exists in state schema with correct structure
  - **Verify**: `jq '.definitions.state.properties.modificationMap' plugins/ralph-specum/schemas/spec.schema.json | grep -q "object"`
  - **Commit**: `feat(schema): add modificationMap to state schema`
  - _Requirements: FR-9, AC-5.3_
  - _Design: Component F_

- [x] 1.21 Add maxModificationsPerTask and maxModificationDepth to spec.schema.json
  - **Do**:
    1. After modificationMap in the state properties, add `maxModificationsPerTask` (integer, min 1, default 3) and `maxModificationDepth` (integer, min 1, default 2)
    2. Use exact schema from design.md Component F lines 457-469
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: Both new properties exist in schema
  - **Verify**: `jq '.definitions.state.properties | has("maxModificationsPerTask", "maxModificationDepth")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true`
  - **Commit**: `feat(schema): add modification limits to state schema`
  - _Requirements: FR-9, AC-4.6_
  - _Design: Component F_

- [x] 1.22 [VERIFY] Quality checkpoint: schema validation
  - **Do**: Verify spec.schema.json is valid JSON and has all new fields
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties | keys[]' plugins/ralph-specum/schemas/spec.schema.json | grep -q modificationMap`
  - **Done when**: Schema is valid JSON, modificationMap present
  - **Commit**: `chore(schema): pass quality checkpoint` (only if fixes needed)

### Component F: State Init (implement.md)

- [x] 1.23 Add modificationMap fields to implement.md state initialization
  - **Do**:
    1. Open `plugins/ralph-specum/commands/implement.md`
    2. Find the jq merge pattern in "Initialize Execution State" (around line 80-96) where state fields are set
    3. Add 3 new fields to the jq merge object: `modificationMap: {}`, `maxModificationsPerTask: 3`, `maxModificationDepth: 2`
    4. Add them after `fixTaskMap: {}` and before the closing `}` of the merge object
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: State init includes modificationMap, maxModificationsPerTask, and maxModificationDepth
  - **Verify**: `grep -q "modificationMap" plugins/ralph-specum/commands/implement.md && grep -q "maxModificationsPerTask" plugins/ralph-specum/commands/implement.md && grep -q "maxModificationDepth" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add modification tracking to state initialization`
  - _Requirements: FR-9, AC-5.3_
  - _Design: Component F_

### Component E: Coordinator Modification Handler (implement.md)

- [x] 1.24 Add Section 6e header and detection logic to implement.md
  - **Do**:
    1. In `plugins/ralph-specum/commands/implement.md`, after Section 6d (the `### 6d. Iterative Failure Recovery Orchestrator` section ends before `### 7. Verification Layers`)
    2. Insert `### 6e. Modification Request Handler` with the opening paragraph and "Detection" subsection
    3. Use content from design.md Component E lines 339-346
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `### 6e. Modification Request Handler` section exists with detection logic
  - **Verify**: `grep -q "### 6e. Modification Request Handler" plugins/ralph-specum/commands/implement.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add modification request detection`
  - _Requirements: FR-8, AC-5.1_
  - _Design: Component E_

- [x] 1.25 Add Parse and Validate subsections to Section 6e
  - **Do**:
    1. After the Detection subsection, add "Parse Modification Request" showing JSON payload structure and "Validate Request" with 5 validation steps (read modificationMap, count check >=3, depth check >3 dots, field validation)
    2. Use content from design.md Component E lines 348-365
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Parse and Validate subsections exist with count and depth checks
  - **Verify**: `grep -q "Parse Modification Request" plugins/ralph-specum/commands/implement.md && grep -q "Validate Request" plugins/ralph-specum/commands/implement.md && grep -q "count >= 3" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add modification request parsing and validation`
  - _Requirements: FR-8, FR-9, AC-5.2, AC-5.7_
  - _Design: Component E_

- [x] 1.26 [VERIFY] Quality checkpoint: Section 6e header and validation
  - **Do**: Verify implement.md has Section 6e with detection, parse, and validate subsections
  - **Verify**: `grep -q "### 6e" plugins/ralph-specum/commands/implement.md && grep -q "Validate Request" plugins/ralph-specum/commands/implement.md && grep -q "depth" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 3 subsections present
  - **Commit**: `chore(coordinator): pass quality checkpoint` (only if fixes needed)

- [x] 1.27 Add SPLIT_TASK handler to Section 6e
  - **Do**:
    1. After the Validate subsection, add "Process by Type" header and the "SPLIT_TASK" handler with 6 steps: mark original [x], insert proposedTasks, update totalTasks, update modificationMap, set taskIndex, log in .progress.md
    2. Use content from design.md Component E lines 367-376
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: SPLIT_TASK handler exists with 6 implementation steps
  - **Verify**: `grep -q "SPLIT_TASK" plugins/ralph-specum/commands/implement.md && grep -q "Mark original task" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add SPLIT_TASK modification handler`
  - _Requirements: FR-8, AC-5.3_
  - _Design: Component E_

- [x] 1.28 Add ADD_PREREQUISITE handler to Section 6e
  - **Do**:
    1. After SPLIT_TASK handler, add the "ADD_PREREQUISITE" handler with 7 steps: do NOT mark complete, insert before current task, update totalTasks, update modificationMap, delegate prerequisite, retry original after, log
    2. Use content from design.md Component E lines 378-384
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: ADD_PREREQUISITE handler exists with "Do NOT mark original task complete" instruction
  - **Verify**: `grep -q "ADD_PREREQUISITE" plugins/ralph-specum/commands/implement.md && grep -q "Do NOT mark original task complete" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add ADD_PREREQUISITE modification handler`
  - _Requirements: FR-8, AC-5.4_
  - _Design: Component E_

- [x] 1.29 Add ADD_FOLLOWUP handler to Section 6e
  - **Do**:
    1. After ADD_PREREQUISITE handler, add the "ADD_FOLLOWUP" handler with 6 steps: original already [x], insert after current, update totalTasks, update modificationMap, normal advancement, log
    2. Use content from design.md Component E lines 386-392
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: ADD_FOLLOWUP handler with "Normal advancement" instruction exists
  - **Verify**: `grep -q "ADD_FOLLOWUP" plugins/ralph-specum/commands/implement.md && grep -q "Normal advancement" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add ADD_FOLLOWUP modification handler`
  - _Requirements: FR-8, AC-5.5_
  - _Design: Component E_

- [x] 1.30 [VERIFY] Quality checkpoint: all 3 modification handlers
  - **Do**: Verify implement.md has all 3 modification type handlers
  - **Verify**: `grep -q "SPLIT_TASK" plugins/ralph-specum/commands/implement.md && grep -q "ADD_PREREQUISITE" plugins/ralph-specum/commands/implement.md && grep -q "ADD_FOLLOWUP" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 3 handlers present in Section 6e
  - **Commit**: `chore(coordinator): pass quality checkpoint` (only if fixes needed)

- [x] 1.31 Add Parallel Batch Interaction rules to Section 6e
  - **Do**:
    1. After ADD_FOLLOWUP handler, add "Parallel Batch Interaction" subsection: if current task in [P] batch, break out of parallel batch, re-evaluate as sequential
    2. Use content from design.md Component E lines 394-397
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Parallel batch interaction rules exist mentioning "[P] batch" and "re-evaluate"
  - **Verify**: `grep -q "Parallel Batch Interaction" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add parallel batch interaction rules for modifications`
  - _Requirements: FR-8_
  - _Design: Component E_

- [x] 1.32 Add Update State (modificationMap) jq pattern to Section 6e
  - **Do**:
    1. After parallel batch rules, add "Update State (modificationMap)" subsection with the jq command pattern for updating modificationMap
    2. Use exact jq pattern from design.md Component E lines 399-414
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: jq modificationMap update pattern exists with `//=` defaults
  - **Verify**: `grep -q "modificationMap" plugins/ralph-specum/commands/implement.md && grep -q '.modificationMap\[$taskId\]' plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add modificationMap state update pattern`
  - _Requirements: FR-10, AC-5.6, AC-4.7_
  - _Design: Component E_

- [x] 1.33 Add Insertion Algorithm to Section 6e
  - **Do**:
    1. After the state update pattern, add "Insertion Algorithm" subsection with 6 steps: read tasks.md, locate target task, find block end, insert position logic, use Edit tool
    2. Use content from design.md Component E lines 416-423
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Insertion algorithm with 6 steps exists referencing Edit tool
  - **Verify**: `grep -q "Insertion Algorithm" plugins/ralph-specum/commands/implement.md && grep -q "Edit tool" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(coordinator): add task insertion algorithm for modifications`
  - _Requirements: FR-8, AC-5.3, AC-5.4, AC-5.5_
  - _Design: Component E_

- [x] 1.34 [VERIFY] Quality checkpoint: Section 6e complete
  - **Do**: Verify full Section 6e with all subsections
  - **Verify**: `grep -q "### 6e. Modification Request Handler" plugins/ralph-specum/commands/implement.md && grep -q "Insertion Algorithm" plugins/ralph-specum/commands/implement.md && grep -q "Parallel Batch Interaction" plugins/ralph-specum/commands/implement.md && grep -q "modificationMap" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 4 key subsections of 6e verified
  - **Commit**: `chore(coordinator): pass quality checkpoint` (only if fixes needed)

- [x] 1.35 Add modification detection to implement.md Section 6 delegation flow
  - **Do**:
    1. In implement.md's "After Delegation" subsection (after line 333 area, the section that checks for TASK_COMPLETE)
    2. Add a check: "If spec-executor output contains `TASK_MODIFICATION_REQUEST`: process modification per Section 6e before continuing"
    3. This should be checked BEFORE the TASK_COMPLETE check, so modifications are processed first
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: Delegation flow checks for TASK_MODIFICATION_REQUEST before TASK_COMPLETE
  - **Verify**: `grep -A5 "After Delegation" plugins/ralph-specum/commands/implement.md | grep -q "TASK_MODIFICATION_REQUEST"`
  - **Commit**: `feat(coordinator): add modification request detection to delegation flow`
  - _Requirements: FR-8, AC-5.1_
  - _Design: Component E_

### Component G: Stop-Watcher Extension

- [x] 1.36 Add TASK_MODIFICATION_REQUEST line to stop-watcher.sh continuation prompt
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. In the REASON heredoc (around line 167, after the line `- On failure: increment taskIteration, retry or generate fix task if recoveryMode`)
    3. Add new line: `- On TASK_MODIFICATION_REQUEST: validate, insert tasks, update state (see implement.md Section 6e)`
  - **Files**: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: Stop-watcher continuation prompt mentions TASK_MODIFICATION_REQUEST
  - **Verify**: `grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Commit**: `feat(stop-watcher): add modification request handling to continuation prompt`
  - _Requirements: FR-8_
  - _Design: Component G_

- [x] 1.37 [VERIFY] Quality checkpoint: all 7 files modified
  - **Do**: Verify all 7 target files have been modified with new content
  - **Verify**: `grep -q "Task Writing Guide" plugins/ralph-specum/templates/tasks.md && grep -q "Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "6e. Modification Request Handler" plugins/ralph-specum/commands/implement.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "modificationMap" plugins/ralph-specum/schemas/spec.schema.json && jq empty plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: All 7 files contain their expected new content
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

- [x] 1.38 POC Checkpoint
  - **Do**: Verify all components work end-to-end using automated tools
    1. Verify templates/tasks.md: 4 bad/good examples, no manual test, task writing principles
    2. Verify task-planner.md: sizing rules, expanded checklist
    3. Verify spec-executor.md: modification protocol with 3 types
    4. Verify implement.md: Section 6e with all handlers, state init with modificationMap
    5. Verify stop-watcher.sh: modification line in continuation prompt
    6. Verify spec.schema.json: valid JSON with 3 new fields
  - **Done when**: All 7 files contain all required content per design document
  - **Verify**: `grep -c "Example [1-4]:" plugins/ralph-specum/templates/tasks.md | grep -q 4 && grep -q "40-60+" plugins/ralph-specum/agents/task-planner.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/agents/spec-executor.md && grep -q "### 6e" plugins/ralph-specum/commands/implement.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && jq '.definitions.state.properties | has("modificationMap")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true`
  - **Commit**: `feat(improve-task-gen): complete POC - all components inserted`

## Phase 2: Refactoring

Focus: Cross-file consistency, wording alignment, remove contradictions.

- [x] 2.1 Ensure no "manual" verification patterns remain across all plugin files
  - **Do**:
    1. Search all files in `plugins/ralph-specum/` for patterns: "manual test", "manually", "visually check", "ask user" in Verify-field contexts
    2. Replace any found instances with automated alternatives
    3. Specifically check templates/tasks.md (primary target) and any agent files
  - **Files**: plugins/ralph-specum/templates/tasks.md (primary), any other files with matches
  - **Done when**: Zero grep matches for manual verification patterns in Verify fields
  - **Verify**: `! grep -ri "manual test\|manually verify\|visually check\|ask user" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `refactor(templates): eliminate all manual verification patterns`
  - _Requirements: FR-6, AC-3.3, AC-3.4_

- [x] 2.2 Verify sizing rules in task-planner.md align with template examples
  - **Do**:
    1. Compare task-planner.md sizing rules (max 4 Do, max 3 files) with templates/tasks.md "Sizing rules" summary line
    2. Ensure identical thresholds stated in both files
    3. Verify the template GOOD examples all comply with sizing rules (each has <= 4 Do steps, <= 3 files)
  - **Files**: plugins/ralph-specum/agents/task-planner.md, plugins/ralph-specum/templates/tasks.md
  - **Done when**: Sizing thresholds match exactly between planner and template
  - **Verify**: `grep "Max 4" plugins/ralph-specum/agents/task-planner.md && grep "max 3 files" plugins/ralph-specum/templates/tasks.md`
  - **Commit**: `refactor(improve-task-gen): align sizing rules across files`

- [x] 2.3 [VERIFY] Quality checkpoint: cross-file consistency
  - **Do**: Verify consistency across all modified files
  - **Verify**: `! grep -ri "manual test" plugins/ralph-specum/templates/ && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/agents/spec-executor.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/commands/implement.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Signal name consistent across executor, coordinator, and stop-watcher
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

- [x] 2.4 Verify modification protocol consistency between executor and coordinator
  - **Do**:
    1. Confirm spec-executor.md JSON payload fields (type, originalTaskId, reasoning, proposedTasks) match what implement.md Section 6e expects to parse
    2. Confirm SPLIT_TASK/ADD_PREREQUISITE/ADD_FOLLOWUP naming matches exactly in both files
    3. Confirm max 3 limit referenced in both executor rules and coordinator validation
  - **Files**: plugins/ralph-specum/agents/spec-executor.md, plugins/ralph-specum/commands/implement.md
  - **Done when**: Payload structure, type names, and limits match between executor and coordinator
  - **Verify**: `grep -q '"type": "SPLIT_TASK"' plugins/ralph-specum/agents/spec-executor.md && grep -q "SPLIT_TASK" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(improve-task-gen): align modification protocol between executor and coordinator`

- [ ] 2.5 Verify state schema matches implement.md initialization
  - **Do**:
    1. Compare spec.schema.json modificationMap schema with implement.md jq merge pattern
    2. Ensure defaults match: modificationMap={}, maxModificationsPerTask=3, maxModificationDepth=2
    3. Verify `//=` pattern in implement.md for backwards compatibility
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json, plugins/ralph-specum/commands/implement.md
  - **Done when**: Schema defaults match init values, backwards compat pattern present
  - **Verify**: `jq '.definitions.state.properties.maxModificationsPerTask.default' plugins/ralph-specum/schemas/spec.schema.json | grep -q 3 && jq '.definitions.state.properties.maxModificationDepth.default' plugins/ralph-specum/schemas/spec.schema.json | grep -q 2`
  - **Commit**: `refactor(improve-task-gen): align schema defaults with state initialization`

- [ ] 2.6 [VERIFY] Quality checkpoint: refactoring complete
  - **Do**: Full cross-file consistency validation
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && ! grep -ri "manual test" plugins/ralph-specum/templates/ && grep -q "modificationMap" plugins/ralph-specum/commands/implement.md && grep -q "modificationMap" plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema valid, no manual tests, modificationMap consistent
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Automated validation that all changes are correct and no regressions.

- [ ] 3.1 Verify no manual verification in templates (automated grep test)
  - **Do**:
    1. Run comprehensive grep across all template files for forbidden patterns
    2. Check for: "manual", "manually", "visually", "ask user", "check by hand" in Verify-context lines
    3. Document results
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: Zero matches for forbidden verification patterns
  - **Verify**: `! grep -in "manual\|visually\|ask user" plugins/ralph-specum/templates/tasks.md | grep -i "verify"`
  - **Commit**: `test(templates): verify no manual verification patterns`
  - _Requirements: FR-6, AC-3.3_

- [ ] 3.2 Verify spec.schema.json is valid JSON with all required fields
  - **Do**:
    1. Run `jq empty` on schema file
    2. Verify all 3 new properties exist: modificationMap, maxModificationsPerTask, maxModificationDepth
    3. Verify modificationMap.additionalProperties has count, modifications fields
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: Schema valid, all 3 new fields present with correct structure
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties.modificationMap.additionalProperties.properties | has("count", "modifications")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true`
  - **Commit**: `test(schema): verify schema validity and new fields`
  - _Requirements: AC-5.3_

- [ ] 3.3 [VERIFY] Quality checkpoint: test results
  - **Do**: Verify all tests from 3.1-3.2 pass
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && ! grep -in "manual" plugins/ralph-specum/templates/tasks.md | grep -qi "verify"`
  - **Done when**: All test verifications pass
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

- [ ] 3.4 Verify task-planner.md has all required sizing rule components
  - **Do**:
    1. Verify section exists: `## Task Sizing Rules`
    2. Verify split-if rules (5 criteria)
    3. Verify combine-if rules (3 criteria)
    4. Verify target count "40-60+"
    5. Verify clarity test question
    6. Verify phase distribution percentages
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: All 6 sizing rule components verified present
  - **Verify**: `grep -q "## Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Split if:" plugins/ralph-specum/agents/task-planner.md && grep -q "Combine if:" plugins/ralph-specum/agents/task-planner.md && grep -q "40-60+" plugins/ralph-specum/agents/task-planner.md && grep -q "Clarity test" plugins/ralph-specum/agents/task-planner.md && grep -q "Phase distribution" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `test(task-planner): verify all sizing rule components present`
  - _Requirements: FR-1, FR-2, FR-3, FR-4_

- [ ] 3.5 Verify spec-executor.md modification protocol completeness
  - **Do**:
    1. Verify section: `## Task Modification Requests`
    2. Verify 3 types: SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP
    3. Verify JSON payload structure with 4 fields
    4. Verify max 3 limit rule
    5. Verify example section
    6. Verify think-first principle mentioned
  - **Files**: plugins/ralph-specum/agents/spec-executor.md
  - **Done when**: All 6 protocol components verified
  - **Verify**: `grep -q "## Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "SPLIT_TASK" plugins/ralph-specum/agents/spec-executor.md && grep -q "ADD_PREREQUISITE" plugins/ralph-specum/agents/spec-executor.md && grep -q "ADD_FOLLOWUP" plugins/ralph-specum/agents/spec-executor.md && grep -q "Max 3" plugins/ralph-specum/agents/spec-executor.md && grep -q "think" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `test(spec-executor): verify modification protocol completeness`
  - _Requirements: FR-7, AC-4.1, AC-4.2_

- [ ] 3.6 Verify implement.md Section 6e has all handler subsections
  - **Do**:
    1. Verify section header: `### 6e. Modification Request Handler`
    2. Verify Detection subsection
    3. Verify Parse subsection
    4. Verify Validate subsection
    5. Verify all 3 type handlers (SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP)
    6. Verify Parallel Batch Interaction
    7. Verify Update State with jq pattern
    8. Verify Insertion Algorithm
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: All 8 subsections verified present
  - **Verify**: `grep -q "### 6e" plugins/ralph-specum/commands/implement.md && grep -q "Detection" plugins/ralph-specum/commands/implement.md && grep -q "Parse Modification" plugins/ralph-specum/commands/implement.md && grep -q "Validate Request" plugins/ralph-specum/commands/implement.md && grep -q "SPLIT_TASK" plugins/ralph-specum/commands/implement.md && grep -q "ADD_PREREQUISITE" plugins/ralph-specum/commands/implement.md && grep -q "ADD_FOLLOWUP" plugins/ralph-specum/commands/implement.md && grep -q "Insertion Algorithm" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `test(coordinator): verify Section 6e completeness`
  - _Requirements: FR-8, AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5_

- [ ] 3.7 [VERIFY] Quality checkpoint: all tests pass
  - **Do**: Run all verification commands from 3.1-3.6
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && grep -q "Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "### 6e" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All component verifications pass
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

- [ ] 3.8 Verify templates/tasks.md has all 4 bad/good examples with correct structure
  - **Do**:
    1. Count examples: should be exactly 4
    2. Verify each has BAD and GOOD labels
    3. Verify Example 4 is the goal-driven pattern
    4. Verify all GOOD examples have <= 4 Do steps
  - **Files**: plugins/ralph-specum/templates/tasks.md
  - **Done when**: 4 examples with BAD/GOOD pairs, all compliant with sizing rules
  - **Verify**: `grep -c "Example [1-4]:" plugins/ralph-specum/templates/tasks.md | grep -q 4 && grep -c "^BAD:" plugins/ralph-specum/templates/tasks.md | grep -q 4 && grep -c "^GOOD:" plugins/ralph-specum/templates/tasks.md | grep -q 4`
  - **Commit**: `test(templates): verify all 4 bad/good example pairs`
  - _Requirements: FR-5, AC-3.1_

- [ ] 3.9 Verify quality checklist expansion in task-planner.md
  - **Do**:
    1. Verify checklist has 14+ items
    2. Verify new items: "All tasks have <= 4 Do steps", "All tasks touch <= 3 files", "Total task count is 40+", "meaningful Done when", "No speculative features", "No unrelated files", "Ambiguous tasks surface assumptions"
  - **Files**: plugins/ralph-specum/agents/task-planner.md
  - **Done when**: Expanded checklist verified with all new items
  - **Verify**: `grep -q "All tasks have <= 4 Do steps" plugins/ralph-specum/agents/task-planner.md && grep -q "Total task count is 40+" plugins/ralph-specum/agents/task-planner.md && grep -q "meaningful" plugins/ralph-specum/agents/task-planner.md && grep -q "speculative" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `test(task-planner): verify expanded quality checklist`
  - _Requirements: FR-11, AC-6.4_

- [ ] 3.10 [VERIFY] Quality checkpoint: all integration tests pass
  - **Do**: Comprehensive verification of all changes across all 7 files (minus plugin.json version bump which is Phase 4)
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && ! grep -qi "manual test" plugins/ralph-specum/templates/tasks.md && grep -c "Example [1-4]:" plugins/ralph-specum/templates/tasks.md | grep -q 4 && grep -q "Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "40-60+" plugins/ralph-specum/agents/task-planner.md && grep -q "Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "### 6e" plugins/ralph-specum/commands/implement.md && grep -q "modificationMap" plugins/ralph-specum/commands/implement.md && grep -q "TASK_MODIFICATION_REQUEST" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: All 7 files verified with correct content
  - **Commit**: `chore(improve-task-gen): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch (main/master). Branch management is handled at startup via `/ralph-specum:start`. You should already be on a feature branch by this phase.

- [ ] 4.1 Bump plugin version in plugin.json and marketplace.json
  - **Do**:
    1. Open `plugins/ralph-specum/.claude-plugin/plugin.json`, change `"version": "3.4.1"` to `"version": "3.5.0"` (minor bump: new feature)
    2. Open `.claude-plugin/marketplace.json`, change the ralph-specum entry `"version": "3.4.1"` to `"version": "3.5.0"`
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files show version "3.5.0"
  - **Verify**: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json | grep -q "3.5.0" && jq -r '.plugins[0].version' .claude-plugin/marketplace.json | grep -q "3.5.0"`
  - **Commit**: `chore(ralph-specum): bump version to 3.5.0`

- [ ] 4.2 [VERIFY] Full local validation: schema + grep checks + version
  - **Do**: Run complete local validation suite
  - **Verify**: All commands must pass:
    - Schema valid: `jq empty plugins/ralph-specum/schemas/spec.schema.json`
    - No manual tests: `! grep -qi "manual test" plugins/ralph-specum/templates/tasks.md`
    - Version bumped: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json | grep -q "3.5.0"`
    - All components present: `grep -q "Task Sizing Rules" plugins/ralph-specum/agents/task-planner.md && grep -q "Task Modification Requests" plugins/ralph-specum/agents/spec-executor.md && grep -q "### 6e" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All local validation commands pass with no errors
  - **Commit**: `fix(improve-task-gen): address quality issues` (if fixes needed)

- [ ] 4.3 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user (branch should be set at startup)
    3. Push branch: `git push -u origin $(git branch --show-current)`
    4. Create PR using gh CLI:
       ```bash
       gh pr create --title "feat(ralph-specum): improve task generation with sizing rules and modification protocol" --body "$(cat <<'EOF'
       ## Summary
       - Add task sizing rules (max 4 Do steps, max 3 files) and 40-60+ task count target to task-planner.md
       - Add 4 bad/good example pairs and Task Writing Principles to templates/tasks.md
       - Add TASK_MODIFICATION_REQUEST protocol to spec-executor.md (SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP)
       - Add Section 6e Modification Request Handler to implement.md coordinator
       - Extend state schema with modificationMap tracking
       - Fix manual verification in POC checkpoint template
       - Bump plugin version to 3.5.0

       ## Requirements
       Implements FR-1 through FR-12 from improve-task-generation spec.

       ## Test Plan
       - [x] Schema validates: `jq empty spec.schema.json`
       - [x] No manual verification patterns in templates
       - [x] All 4 bad/good examples present
       - [x] Sizing rules with split/combine thresholds
       - [x] Modification protocol with 3 types in executor and coordinator
       - [x] Version bumped in plugin.json and marketplace.json
       - [ ] CI checks pass
       EOF
       )"
       ```
    5. If gh CLI unavailable, output PR creation URL
  - **Verify**: Use gh CLI to verify CI status:
    ```bash
    gh pr checks --watch
    ```
  - **Done when**: All CI checks show passing, PR ready for review
  - **If CI fails**:
    1. View failures: `gh pr checks`
    2. Get detailed logs: `gh run view <run-id> --log-failed`
    3. Fix issues locally
    4. Commit and push fixes
    5. Re-verify: `gh pr checks --watch`

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met.

- [ ] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`, fix locally, commit, push
    4. Repeat until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed)

- [ ] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED")'`
    2. For inline comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
    3. For each unresolved comment: implement change, commit, push
    4. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - <summary>` (per comment)

- [ ] 5.3 Final validation
  - **Do**: Verify ALL completion criteria:
    1. All tasks marked [x] in tasks.md
    2. CI all green: `gh pr checks`
    3. No manual verification patterns: `! grep -qi "manual test" plugins/ralph-specum/templates/tasks.md`
    4. Schema valid: `jq empty plugins/ralph-specum/schemas/spec.schema.json`
    5. Version bumped: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json`
    6. All 7 files modified per design
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: None significant - all changes are markdown/JSON content insertions with exact content from design document
- **Production TODOs**: None - all content is production-ready as specified in design
- **Key risk**: Line numbers in design doc may shift as earlier insertions change file lengths. Use content-based Edit tool matching (old_string/new_string) rather than line numbers
- **Token budget**: task-planner.md additions ~500 tokens total (well under 8000 budget per NFR-1)
- **Backwards compatibility**: All new state fields use `//=` defaults in jq patterns. Old state files work without modification

## Dependencies

```
Phase 1 (POC: all 7 files) -> Phase 2 (cross-file consistency) -> Phase 3 (automated tests) -> Phase 4 (version bump + PR) -> Phase 5 (CI + reviews)
```

Within Phase 1:
- Template tasks (1.1-1.8) can proceed independently
- Task-planner tasks (1.9-1.13) can proceed independently
- Spec-executor tasks (1.14-1.19) can proceed independently
- Schema tasks (1.20-1.22) should complete before implement.md state init (1.23)
- Implement.md Section 6e (1.24-1.35) depends on understanding executor protocol (1.14-1.18)
- Stop-watcher (1.36) is independent
