# Tasks: {{FEATURE_NAME}}

## Overview

Total tasks: {{N}}
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Validate idea end-to-end
2. Phase 2: Refactoring - Clean up code structure
3. Phase 3: Testing - Add unit/integration/e2e tests
4. Phase 4: Quality Gates - Local quality checks and PR creation
5. Phase 5: PR Lifecycle - Autonomous CI monitoring, review resolution, final validation

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

✅ **Zero Regressions**: All existing tests pass (no broken functionality)
✅ **Modular & Reusable**: Code follows project patterns, properly abstracted
✅ **Real-World Validation**: Feature tested in actual environment (not just unit tests)
✅ **All Tests Pass**: Unit, integration, E2E all green
✅ **CI Green**: All CI checks passing
✅ **PR Ready**: Pull request created, reviewed, approved
✅ **Review Comments Resolved**: All code review feedback addressed

**Note**: The executor will continue working until all criteria are met. Do not stop at Phase 4 if CI fails or review comments exist.

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks to catch issues early. For small tasks, insert after 3 tasks. For medium or large tasks, insert after 2 tasks.

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [ ] 1.1 {{Specific task name}}
  - **Do**: {{Exact steps to implement}}
  - **Files**: {{Exact file paths to create or modify}}
  - **Done when**: {{Explicit success criteria}}
  - **Verify**: {{Command to verify}}
  - **Commit**: `feat(scope): {{task description}}`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.2 {{Another task}}
  - **Do**: {{Steps}}
  - **Files**: {{Paths}}
  - **Done when**: {{Criteria}}
  - **Verify**: {{Command}}
  - **Commit**: `feat(scope): {{description}}`
  - _Requirements: FR-2_
  - _Design: Component B_

- [ ] 1.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify recent changes do not break the build
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - E2E: `pnpm test:e2e` or equivalent if it exists
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` only if fixes were needed

- [ ] 1.4 {{Continue with more tasks}}
  - **Do**: {{Steps}}
  - **Files**: {{Paths}}
  - **Done when**: {{Criteria}}
  - **Verify**: {{Command}}
  - **Commit**: `feat(scope): {{description}}`

- [ ] 1.5 POC Checkpoint
  - **Do**: Verify feature works end-to-end
  - **Done when**: Feature can be demonstrated working
  - **Verify**: Manual test of core flow
  - **Commit**: `feat(scope): complete POC`

## Phase 2: Refactoring

After POC is validated, clean up code.

- [ ] 2.1 Extract and modularize
  - **Do**: {{Specific refactoring steps}}
  - **Files**: {{Files to modify}}
  - **Done when**: Code follows project patterns
  - **Verify**: Type check passes
  - **Commit**: `refactor(scope): extract {{component}}`
  - _Design: Architecture section_

- [ ] 2.2 Add error handling
  - **Do**: Add try/catch and proper error messages
  - **Done when**: All error paths handled
  - **Verify**: Type check passes
  - **Commit**: `refactor(scope): add error handling`
  - _Design: Error Handling_

- [ ] 2.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify refactoring does not break the build
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test` if it exists
    - E2E: `pnpm test:e2e` or equivalent if it exists
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` only if fixes were needed

- [ ] 2.4 Code cleanup
  - **Do**: Remove hardcoded values and add proper types
  - **Done when**: No TODOs or hardcoded values remain
  - **Verify**: Code review checklist passes
  - **Commit**: `refactor(scope): cleanup and finalize`

## Phase 3: Testing

- [ ] 3.1 Unit tests for {{component}}
  - **Do**: Create test file at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: Tests cover main functionality
  - **Verify**: `pnpm test` or equivalent passes
  - **Commit**: `test(scope): add unit tests for {{component}}`
  - _Requirements: AC-1.1, AC-1.2_
  - _Design: Test Strategy_

- [ ] 3.2 Integration tests
  - **Do**: Create integration test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: Integration points tested
  - **Verify**: Test command passes
  - **Commit**: `test(scope): add integration tests`
  - _Design: Test Strategy_

- [ ] 3.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify tests do not introduce issues
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test`
    - E2E: `pnpm test:e2e` or equivalent if it exists
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` only if fixes were needed

- [ ] 3.4 E2E tests if UI exists
  - **Do**: Create E2E test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: User flow tested
  - **Verify**: E2E test command passes
  - **Commit**: `test(scope): add e2e tests`
  - _Requirements: US-1_

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Run all local quality checks before PR creation
  - **Verify**: Types, lint, tests, and E2E pass where available
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(scope): address quality issues` only if fixes were needed

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch
    2. Push the branch
    3. Create a PR with `gh` if available
    4. Watch CI and fix failures
  - **Done when**: PR exists and CI is green

- [ ] 4.3 Merge after approval if explicitly requested
  - **Do**: Merge only when the user explicitly asks
  - **Done when**: Requested merge is complete

## Phase 5: PR Lifecycle

- [ ] 5.1 Create pull request
  - **Do**: Push the branch and open a PR
  - **Done when**: PR URL exists

- [ ] 5.2 Monitor CI and fix failures
  - **Do**: Repeat fix, commit, push, and recheck until CI is green
  - **Done when**: All checks pass

- [ ] 5.3 Address code review comments
  - **Do**: Resolve outstanding review comments and push fixes
  - **Done when**: No unresolved review feedback remains

- [ ] 5.4 Final validation
  - **Do**: Re-run the full validation set and confirm all completion criteria
  - **Done when**: The feature is ready

## Notes

- **POC shortcuts taken**: {{list hardcoded values and skipped validations}}
- **Production TODOs**: {{what still needs proper implementation}}

## Dependencies

```text
Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality) -> Phase 5 (PR Lifecycle)
```
