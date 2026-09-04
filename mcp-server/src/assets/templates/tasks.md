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

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks to catch issues early. For small tasks, insert after 3 tasks. For medium/large tasks, insert after 2 tasks.

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

- [ ] 1.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify recent changes don't break the build
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - E2E: `pnpm test:e2e` or equivalent (if exists)
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)

- [ ] 1.4 {{Continue with more tasks...}}
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

- [ ] 2.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify refactoring doesn't break the build
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test` (if applicable)
    - E2E: `pnpm test:e2e` or equivalent (if exists)
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)

- [ ] 2.4 Code cleanup
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

- [ ] 3.3 Quality Checkpoint
  - **Do**: Run all quality checks to verify tests don't introduce issues
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test`
    - E2E: `pnpm test:e2e` or equivalent (if exists)
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)

- [ ] 3.4 E2E tests (if UI)
  - **Do**: Create E2E test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: User flow tested
  - **Verify**: E2E test command passes
  - **Commit**: `test(scope): add e2e tests`
  - _Requirements: US-1_

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch (main/master). Branch management is handled at startup via `/ralph-specum:start`. You should already be on a feature branch by this phase.

> **Default Behavior**: When on a feature branch (not main/master), the final deliverable is a Pull Request with all CI checks passing. This is the default unless explicitly stated otherwise.

- [ ] 4.1 Local quality check
  - **Do**: Run ALL quality checks locally before creating PR
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test`
    - E2E: `pnpm test:e2e` or equivalent (if exists)
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(scope): address lint/type issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user (branch should be set at startup)
    3. Push branch: `git push -u origin $(git branch --show-current)`
    4. Create PR using gh CLI (if available):
       ```bash
       gh pr create --title "feat: {{feature-name}}" --body "## Summary
       {{brief description of changes}}

       ## Test Plan
       - [x] Local quality gates pass (types, lint, tests, E2E)
       - [ ] CI checks pass"
       ```
    5. If gh CLI unavailable, output: "Create PR at: https://github.com/<org>/<repo>/compare/<branch>"
  - **Verify**: Use gh CLI to verify CI status:
    ```bash
    # Wait for CI and watch status
    gh pr checks --watch

    # Or check current status
    gh pr checks

    # Get detailed status
    gh pr view --json statusCheckRollup --jq '.statusCheckRollup[] | "\(.name): \(.conclusion)"'
    ```
  - **Done when**: All CI checks show ✓ (passing), PR ready for review
  - **If CI fails**:
    1. View failures: `gh pr checks`
    2. Get detailed logs: `gh run view <run-id> --log-failed`
    3. Fix issues locally
    4. Commit and push: `git add . && git commit -m "fix: address CI failures" && git push`
    5. Re-verify: `gh pr checks --watch`

- [ ] VF [VERIFY] Verify original issue resolved (only for fix-type goals)
  - **Do**: Re-run the command from "Reality Check (BEFORE)" section in .progress.md
  - **Verify**: Same command now exits 0 (or produces expected output)
  - **Done when**: Original failure no longer reproduces, BEFORE/AFTER comparison documented
  - **Note**: This task only applies when goal was classified as "fix" type. Skip if goal was "add" or "enhance".

- [ ] 4.3 Merge after approval (optional - only if explicitly requested)
  - **Do**: Merge PR after approval and CI green
  - **Verify**: `gh pr merge --auto` or manual merge
  - **Done when**: Changes in main branch
  - **Note**: Do NOT auto-merge unless user explicitly requests it

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met. The executor monitors CI, addresses review comments, and iterates until production-ready.

- [ ] 5.1 Create pull request
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat: {{feature-name}}" --body "$(cat <<'EOF'
## Summary
{{brief description}}

## Completion Criteria
- [x] Zero regressions (all existing tests pass)
- [x] Code is modular and reusable
- [x] Real-world validation complete
- [ ] CI checks green
- [ ] Code review approved
EOF
)"`
  - **Verify**: `gh pr view` shows PR URL
  - **Done when**: PR created and URL returned
  - **Commit**: None

- [ ] 5.2 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    6. Push: `git push`
    7. Repeat from step 1 until all green
  - **Verify**: `gh pr checks` shows all ✓
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed per iteration)

- [ ] 5.3 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED" or .state == "PENDING")'`
       - Note: For inline comment threads, use: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
    2. For each unresolved review/comment:
       - Read review body and inline comments
       - Implement requested change
       - Commit: `fix: address review - {{comment summary}}`
    3. Push all fixes: `git push`
    4. Wait 5 minutes
    5. Re-check for new reviews
    6. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED or PENDING states
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - {{summary}}` (per comment)

- [ ] 5.4 Final validation
  - **Do**: Verify ALL completion criteria met:
    1. Run full test suite: `pnpm test` or equivalent
    2. Verify zero regressions (compare test count before/after)
    3. Check CI: `gh pr checks` all green
    4. Verify modularity documented in .progress.md
    5. Confirm real-world validation documented
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria ✅
  - **Commit**: None

## Notes

- **POC shortcuts taken**: {{list hardcoded values, skipped validations}}
- **Production TODOs**: {{what needs proper implementation in Phase 2}}

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality) → Phase 5 (PR Lifecycle)
```
