# Tasks: {{FEATURE_NAME}}

## Overview

Total tasks: {{N}}
POC-first workflow with 4 phases.

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [ ] 1.1 {{Specific task name}}
  - **Do**: {{Exact steps to implement}}
  - **Files**: {{Exact file paths to create/modify}}
  - **Done when**: {{Explicit success criteria}}
  - **Verify**: {{Command to verify, e.g., "manually test X does Y"}}
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

- [ ] 1.3 POC Checkpoint
  - **Do**: Verify feature works end-to-end
  - **Done when**: Feature can be demonstrated working
  - **Verify**: Manual test of core flow
  - **Commit**: `feat(scope): complete POC`

## Phase 2: Refactoring

After POC validated, clean up code.

- [ ] 2.1 Extract and modularize
  - **Do**: {{Specific refactoring steps}}
  - **Files**: {{Files to modify}}
  - **Done when**: Code follows project patterns
  - **Verify**: Type check passes
  - **Commit**: `refactor(scope): extract {{component}}`
  - _Design: Architecture section_

- [ ] 2.2 Add error handling
  - **Do**: Add try/catch, proper error messages
  - **Done when**: All error paths handled
  - **Verify**: Type check passes
  - **Commit**: `refactor(scope): add error handling`
  - _Design: Error Handling_

- [ ] 2.3 Code cleanup
  - **Do**: Remove hardcoded values, add proper types
  - **Done when**: No TODOs or hardcoded values remain
  - **Verify**: Code review checklist passes
  - **Commit**: `refactor(scope): cleanup and finalize`

## Phase 3: Testing

- [ ] 3.1 Unit tests for {{component}}
  - **Do**: Create test file at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: Tests cover main functionality
  - **Verify**: `pnpm test` or test command passes
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

- [ ] 3.3 E2E tests (if UI)
  - **Do**: Create E2E test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: User flow tested
  - **Verify**: E2E test command passes
  - **Commit**: `test(scope): add e2e tests`
  - _Requirements: US-1_

## Phase 4: Quality Gates

- [ ] 4.1 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(scope): address lint/type issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**: Push branch, create PR, wait for CI
  - **Verify**: All CI checks green
  - **Done when**: CI passes, PR ready for review

- [ ] 4.3 Merge after approval
  - **Do**: Merge PR after approval and CI green
  - **Done when**: Changes in main branch

## Notes

- **POC shortcuts taken**: {{list hardcoded values, skipped validations}}
- **Production TODOs**: {{what needs proper implementation in Phase 2}}

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality)
```
