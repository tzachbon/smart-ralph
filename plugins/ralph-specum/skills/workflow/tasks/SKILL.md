---
name: ralph:tasks
description: Break design into implementation tasks — POC-first 4-phase breakdown with verification steps
---

# Tasks Phase

## Overview

The tasks phase breaks the technical design into a sequentially executable task list. It follows three principles:

1. **POC-first** -- Validate the idea works end-to-end before refactoring, testing, or polishing.
2. **Every task is autonomous** -- Each task has explicit steps (Do), file targets (Files), success criteria (Done when), a verification command (Verify), and a commit message (Commit).
3. **Quality checkpoints** -- Insert verification gates every 2-3 tasks to catch issues early.

Tasks produces `tasks.md` in the spec directory and sets `awaitingApproval: true` in state so the user reviews the plan before execution begins.

### Inputs

- `specs/<name>/design.md` -- Architecture, components, data flow, technical decisions.
- `specs/<name>/requirements.md` -- User stories, acceptance criteria, FR/NFR tables.
- `specs/<name>/research.md` -- Quality commands, codebase patterns, constraints.
- `specs/<name>/.progress.md` -- Original goal and accumulated learnings.
- `specs/<name>/.ralph-state.json` -- Current state (should have `phase: "tasks"`).

### Output

- `specs/<name>/tasks.md` -- Ordered task list with all 4 phases (see template below).
- Updated `.ralph-state.json` with `awaitingApproval: true` and `totalTasks` count.
- Appended learnings in `.progress.md`.

---

## Steps

### 1. Read Design and Requirements

Read all spec artifacts to understand the full context:

```bash
SPEC_DIR="./specs/<name>"
cat "$SPEC_DIR/design.md"
cat "$SPEC_DIR/requirements.md"
cat "$SPEC_DIR/research.md"
cat "$SPEC_DIR/.progress.md"
```

Extract key inputs:
- Components and their responsibilities (from design)
- File structure with create/modify actions (from design)
- Acceptance criteria to trace tasks back to (from requirements)
- Quality commands discovered during research (lint, typecheck, test, build)
- Existing patterns to follow

### 2. Explore the Codebase

Before planning tasks, search the codebase for context:

- **Find existing test patterns**: Locate test files to understand verification commands.
- **Check build/quality scripts**: Identify actual commands for quality checkpoints.
- **Locate files to modify**: Verify paths from the design doc are accurate.
- **Find commit message conventions**: Check recent commits for style.

Record actual file paths and commands -- do not guess.

### 3. Plan Phase 1: Make It Work (POC)

Create tasks that validate the core idea end-to-end:

- Focus on the happy path only
- Skip error handling (Phase 2)
- Skip tests (Phase 3)
- Accept hardcoded values and shortcuts
- Each task produces a working increment

Order tasks by dependency -- each task builds on the previous one.

Insert a quality checkpoint after every 2-3 tasks:
- For small/simple tasks: checkpoint after 3 tasks
- For medium tasks: checkpoint after 2-3 tasks
- For large/complex tasks: checkpoint after 2 tasks

End Phase 1 with a POC Checkpoint that verifies the feature works end-to-end.

### 4. Plan Phase 2: Refactoring

Create tasks to clean up POC code:

- Extract and modularize components
- Add proper error handling
- Remove hardcoded values
- Follow project patterns and conventions
- Reference design.md Architecture and Error Handling sections

Insert quality checkpoints after every 2-3 refactoring tasks.

### 5. Plan Phase 3: Testing

Create tasks for test coverage:

- Unit tests for core components
- Integration tests for component boundaries
- E2E tests if the feature has UI
- Reference design.md Test Strategy section

Insert quality checkpoints to verify tests pass alongside lint/types.

### 6. Plan Phase 4: Quality Gates

Create tasks for final quality validation:

- Local quality check (all lint, type, test commands)
- Create PR and verify CI
- Optional merge task (only if explicitly requested)

If the goal is a fix (`.progress.md` contains `## Reality Check (BEFORE)`), add a verification task that re-runs the original failing command to confirm the fix.

### 7. Write tasks.md

Create `specs/<name>/tasks.md` with all phases organized into the standard format (see Output Format below).

Count total tasks and update the state file:

```bash
SPEC_DIR="./specs/<name>"
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
jq --argjson total "$TOTAL" '.totalTasks = $total | .awaitingApproval = true' "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

### 8. Update Progress

Append any significant discoveries to the `## Learnings` section of `.progress.md`:

- Task dependencies that affect execution order
- Risk areas identified during planning
- Verification commands that may need adjustment
- Shortcuts planned for POC phase
- Complex areas that may need extra attention

---

## Advanced

### Task Format

Every task follows this exact format:

```markdown
- [ ] X.Y [Task name]
  - **Do**: [Numbered steps to implement]
  - **Files**: [Exact file paths to create/modify]
  - **Done when**: [Explicit success criteria]
  - **Verify**: [Automated command that exits 0 on success]
  - **Commit**: `type(scope): [description]`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_
```

Rules:
- **Do** must be specific enough for autonomous execution -- no ambiguity
- **Files** must list actual file paths (verified by codebase exploration)
- **Done when** must be objectively verifiable
- **Verify** must be an automated command (never "manual test" or "visually check")
- **Commit** must follow conventional commit format
- Requirements/Design traces are optional but recommended

### Quality Checkpoint Format

```markdown
- [ ] X.Y Quality checkpoint
  - **Do**: Run all quality checks to verify recent changes
  - **Verify**: All commands must pass:
    - Type check: [actual typecheck command from research]
    - Lint: [actual lint command from research]
    - Tests: [actual test command if applicable]
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

Use actual commands discovered from research.md, not assumed ones.

### POC-First Workflow: 4 Phases

```
Phase 1: Make It Work (POC)
  Goal: Validate idea end-to-end
  Rules: Skip tests, accept shortcuts, happy path only
  End: POC checkpoint proves feature works

Phase 2: Refactoring
  Goal: Clean up code structure
  Rules: Follow project patterns, proper error handling, remove hardcoded values
  End: Code is production-quality

Phase 3: Testing
  Goal: Add test coverage
  Rules: Unit tests, integration tests, E2E tests per design Test Strategy
  End: Adequate coverage for acceptance criteria

Phase 4: Quality Gates
  Goal: Pass all quality checks, create PR
  Rules: All lint/type/test commands pass, CI green
  End: PR created and CI passing
```

### Output Format: tasks.md Template

```markdown
---
spec: <spec-name>
phase: tasks
total_tasks: [N]
created: [timestamp]
generated: auto
---

# Tasks: <Feature Name>

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [ ] 1.1 [Task name]
  - **Do**: [Steps]
  - **Files**: [Paths]
  - **Done when**: [Criteria]
  - **Verify**: [Command]
  - **Commit**: `feat(scope): [description]`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.2 [Task name]
  - **Do**: [Steps]
  - **Files**: [Paths]
  - **Done when**: [Criteria]
  - **Verify**: [Command]
  - **Commit**: `feat(scope): [description]`

- [ ] 1.3 Quality checkpoint
  - **Do**: Run quality checks
  - **Verify**: [Actual quality commands]
  - **Done when**: All checks pass
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)

- [ ] 1.N POC Checkpoint
  - **Do**: Verify feature works end-to-end
  - **Done when**: Feature demonstrated working via automated verification
  - **Verify**: [End-to-end verification command]
  - **Commit**: `feat(scope): complete POC`

## Phase 2: Refactoring

After POC validated, clean up code.

- [ ] 2.1 Extract and modularize
  - **Do**: [Specific refactoring steps]
  - **Files**: [Files to modify]
  - **Done when**: Code follows project patterns
  - **Verify**: [Typecheck command]
  - **Commit**: `refactor(scope): extract [component]`
  - _Design: Architecture section_

- [ ] 2.2 Add error handling
  - **Do**: Add proper error handling
  - **Done when**: All error paths handled
  - **Verify**: [Typecheck command]
  - **Commit**: `refactor(scope): add error handling`
  - _Design: Error Handling_

- [ ] 2.3 Quality checkpoint
  - **Do**: Run quality checks
  - **Verify**: [Quality commands]
  - **Done when**: All checks pass
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)

## Phase 3: Testing

- [ ] 3.1 Unit tests for [component]
  - **Do**: Create test file
  - **Files**: [Test file path]
  - **Done when**: Tests cover main functionality
  - **Verify**: [Test command]
  - **Commit**: `test(scope): add unit tests for [component]`

- [ ] 3.2 Integration tests
  - **Do**: Create integration test
  - **Files**: [Test file path]
  - **Done when**: Integration points tested
  - **Verify**: [Test command]
  - **Commit**: `test(scope): add integration tests`

- [ ] 3.3 Quality checkpoint
  - **Do**: Run quality checks
  - **Verify**: [Quality commands]
  - **Done when**: All checks pass
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: [All quality commands]
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(scope): address lint/type issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch
    2. Push branch
    3. Create PR
  - **Verify**: CI checks all green
  - **Done when**: PR created, all CI checks passing

## Notes

- **POC shortcuts taken**: [list hardcoded values, skipped validations]
- **Production TODOs**: [what needs proper implementation in Phase 2]

## Dependencies

Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality)
```

### Task Planning Quality Checklist

Before finalizing, verify:

- [ ] All tasks reference requirements and/or design sections
- [ ] POC phase focuses on validation, not perfection
- [ ] Every task has an automated Verify command (no manual testing)
- [ ] Quality checkpoints inserted every 2-3 tasks throughout all phases
- [ ] Quality gates are the last phase
- [ ] Tasks are ordered by dependency
- [ ] File paths are actual paths from the codebase (not guesses)
- [ ] Verification commands are actual project commands (from research.md)
- [ ] Total task count set in state file
- [ ] Set `awaitingApproval: true` in state file
- [ ] Appended learnings to `.progress.md`

### Commit Conventions

Use conventional commits throughout:

- `feat(scope):` -- New feature or capability
- `fix(scope):` -- Bug fix
- `refactor(scope):` -- Code restructuring without behavior change
- `test(scope):` -- Adding or modifying tests
- `chore(scope):` -- Quality checkpoints, maintenance
- `docs(scope):` -- Documentation changes

### Anti-Patterns

- **Never create tasks with manual verification** -- The executor is fully autonomous and cannot ask questions.
- **Never guess file paths** -- Explore the codebase to find actual paths.
- **Never assume quality commands** -- Read research.md for discovered commands.
- **Never skip quality checkpoints** -- They catch issues before they compound.
- **Never put tests in Phase 1** -- POC validates the idea; tests come in Phase 3.
- **Never create tasks that spawn new spec directories** -- Work within the current spec context.
