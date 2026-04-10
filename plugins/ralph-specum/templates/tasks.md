# Tasks: {{FEATURE_NAME}}

## Overview

Total tasks: {{N}}

<!-- Select workflow based on Intent Classification in .progress.md -->
<!-- GREENFIELD → POC-first workflow | TRIVIAL/REFACTOR/MID_SIZED → TDD workflow -->

**POC-first workflow** (GREENFIELD):
1. Phase 1: Make It Work (POC) - Validate idea end-to-end
2. Phase 2: Refactoring - Clean up code structure
3. Phase 3: Testing - Add unit/integration/e2e tests
4. Phase 4: Quality Gates - Local quality checks and PR creation
5. Phase 5: PR Lifecycle - Autonomous CI monitoring, review resolution, final validation

**TDD Red-Green-Yellow workflow** (TRIVIAL/REFACTOR/MID_SIZED):
1. Phase 1: Red-Green-Yellow Cycles - Test-first implementation
2. Phase 2: Additional Testing - Integration/E2E beyond unit tests
3. Phase 3: Quality Gates - Local quality checks and PR creation
4. Phase 4: PR Lifecycle - Autonomous CI monitoring, review resolution, final validation

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

## Task Writing Guide

**Sizing rules**: Max 4 Do steps, max 3 files per task. Split if exceeded.

**Parallel markers**: Mark independent tasks with [P] for concurrent execution. Adjacent [P] tasks form a parallel group. [VERIFY] tasks always break groups.

### Task Writing Principles

1. **Think First**: Tasks should surface what's unclear, not assume. If a task depends on an uncertain assumption (e.g., "config file exists at X"), state it explicitly in the Do section or add a verification step. Don't hide confusion in vague steps.
2. **Simplicity**: Minimum steps to achieve the goal. No speculative features, no abstractions for single-use code. If the task can be done in 2 steps, don't write 4.
3. **Surgical**: Each task touches only what it must. No drive-by refactors, no "while you're in there" improvements. Every file in the Files section traces directly to the task's goal.
4. **Goal-Driven**: Emphasize **Done when** and **Verify** over **Do** steps. The Do is guidance; the Done when is the contract. Transform imperative commands into declarative success criteria. Instead of "Add validation" write "Done when: invalid inputs return 400 with error message."

### Bad vs. Good Examples

**Example 1: File Creation (too vague vs. precise)**

BAD:
- [ ] 1.1 Set up the API module
  - **Do**: Create the API module with routes and handlers
  - **Files**: src/api/
  - **Verify**: Code compiles

GOOD:
- [ ] 1.1 Create user registration endpoint
  - **Do**:
    1. Create `src/api/routes/auth.ts` with POST /register route
    2. Add request body validation: email (valid format), password (min 8 chars)
    3. Return 201 with `{ id, email }` on success, 400 with `{ error }` on validation fail
  - **Files**: src/api/routes/auth.ts
  - **Done when**: POST /register returns 201 for valid input, 400 for invalid
  - **Verify**: `curl -X POST localhost:3000/register -d '{"email":"a@b.com","password":"12345678"}' -w '%{http_code}' | grep 201`

**Example 2: Integration (bundled vs. atomic)**

BAD:
- [ ] 2.1 Add analytics tracking
  - **Do**: Install PostHog, create wrapper, add to all pages, write tests
  - **Files**: src/analytics.ts, src/pages/*.tsx, tests/analytics.test.ts
  - **Verify**: Tests pass

GOOD:
- [ ] 2.1 Install PostHog SDK and create wrapper
  - **Do**:
    1. Add posthog-js: `pnpm add posthog-js`
    2. Create `src/lib/analytics.ts` exporting `track(event, props)` and `identify(userId)`
    3. Initialize with env var `POSTHOG_KEY` in wrapper
  - **Files**: src/lib/analytics.ts, package.json
  - **Done when**: `import { track } from '@/lib/analytics'` resolves without error
  - **Verify**: `pnpm check-types`

**Example 3: Refactoring (overloaded vs. focused)**

BAD:
- [ ] 3.1 Refactor and test the auth module
  - **Do**: Extract auth logic, add error handling, write unit tests, run linter, fix types
  - **Files**: src/auth.ts, src/utils/token.ts, tests/auth.test.ts, src/types.ts

GOOD:
- [ ] 3.1 Extract token validation into utility
  - **Do**:
    1. Create `src/utils/token.ts` with `validateToken(token: string): TokenPayload | null`
    2. Move JWT verify logic from `src/auth.ts` lines 45-62 into new file
    3. Update `src/auth.ts` to import and call `validateToken`
  - **Files**: src/utils/token.ts, src/auth.ts
  - **Done when**: Existing auth flow works identically after extraction
  - **Verify**: `pnpm check-types && pnpm test -- --grep auth`

**Example 4: Goal-Driven (imperative command vs. success criteria)**

BAD:
- [ ] 4.1 Add input validation
  - **Do**: Add validation to the form fields. Check email format, required fields, password strength.
  - **Files**: src/components/SignupForm.tsx
  - **Done when**: Validation is added
  - **Verify**: Validation is added

GOOD:
- [ ] 4.1 Add signup form validation with error states
  - **Do**:
    1. Add validation rules to `src/components/SignupForm.tsx`: email (regex), password (min 8, 1 uppercase, 1 number), name (required)
    2. Display inline error messages below each field on blur -> verify: error messages render
    3. Disable submit button until all fields valid -> verify: button disabled state toggles
  - **Files**: src/components/SignupForm.tsx
  - **Done when**: Form rejects invalid inputs with visible error messages; submit disabled until valid
  - **Verify**: `pnpm test -- --grep SignupForm` (write test first if missing: invalid email shows "Invalid email", short password shows "Min 8 characters")

**Example 5: TDD Triplet (non-greenfield bug fix)**

BAD:
- [ ] 1.1 Fix the login timeout bug
  - **Do**: Find the timeout code and fix it, then write a test
  - **Files**: src/auth.ts, tests/auth.test.ts
  - **Verify**: Tests pass

GOOD:
- [ ] 1.1 [RED] Failing test: login does not timeout after 30s
  - **Do**:
    1. Add test in `tests/auth.test.ts`: "should complete login within 30s timeout"
    2. Assert that `login()` resolves before 30000ms (currently fails due to bug)
  - **Files**: tests/auth.test.ts
  - **Done when**: Test exists AND fails with timeout error
  - **Verify**: `pnpm test -- --grep "login.*timeout" 2>&1 | grep -q "FAIL" && echo RED_PASS`
  - **Commit**: `test(auth): red - failing test for login timeout`

- [ ] 1.2 [GREEN] Fix login timeout
  - **Do**:
    1. Fix timeout handling in `src/auth.ts` — set proper timeout on HTTP request
  - **Files**: src/auth.ts
  - **Done when**: Login timeout test now passes
  - **Verify**: `pnpm test -- --grep "login.*timeout"`
  - **Commit**: `fix(auth): green - fix login timeout handling`

- [ ] 1.3 [YELLOW] Refactor: extract timeout config
  - **Do**:
    1. Extract hardcoded timeout to config constant in `src/auth.ts`
  - **Files**: src/auth.ts
  - **Done when**: Code is clean AND all auth tests pass
  - **Verify**: `pnpm test -- --grep "auth" && pnpm lint`
  - **Commit**: `refactor(auth): yellow - extract timeout to config`

<!-- ============================================================ -->
<!-- POC-FIRST WORKFLOW (use when Intent = GREENFIELD)            -->
<!-- ============================================================ -->

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [ ] 1.1 [P] {{Specific task name}}
  - **Do**: {{Exact steps to implement}}
  - **Files**: {{Exact file paths to create/modify}}
  - **Done when**: {{Explicit success criteria}}
  - **Verify**: {{Command to verify, e.g., `curl localhost:3000/api | jq .status`}}
  - **Commit**: `feat(scope): {{task description}}`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.2 [P] {{Another task}}
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
  - **Do**: Verify feature works end-to-end using automated tools (WebFetch, curl, browser automation, test runner)
  - **Done when**: Feature can be demonstrated working via automated verification
  - **Verify**: Run automated end-to-end verification (e.g., `curl API | jq`, browser automation script, or test command)
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

<!-- VE Tasks: VE0 (ui-map-init), VE1 (startup), VE2 (check), VE3 (cleanup) — generated from research.md Verification Tooling section -->
<!-- Skills field is REQUIRED on every VE task. task-planner: replace the comment placeholders below with actual platform-specific skills discovered in research.md (e.g., homeassistant-selector-map). Remove the HTML comment if no platform skills apply. -->

- [ ] VE0 [VERIFY] Build selector map (ui-map-init)
  - **Skills**: e2e, playwright-env, mcp-playwright, ui-map-init<!-- task-planner: append platform-specific skills here (e.g., homeassistant-selector-map) if research.md discovered them -->
  - **Do**: Follow `${CLAUDE_PLUGIN_ROOT}/skills/e2e/ui-map-init.skill.md` in full — open a fresh browser session, explore app routes, write `ui-map.local.md` to spec basePath.
  - **Verify**: `test -f {{basePath}}/ui-map.local.md && echo PASS`
  - **Done when**: `ui-map.local.md` exists with at least one route entry
  - **Commit**: None

- [ ] VE1 [VERIFY] E2E startup: launch dev server and verify health
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session<!-- task-planner: append platform-specific skills here if research.md discovered them -->
  - **Do**:
    1. Start dev server: `{{dev_cmd}}` (background, save PID to /tmp/ve-pids.txt)
    2. Wait for server ready: poll `{{health_endpoint}}` on port `{{port}}` until 200 (timeout 30s)
  - **Verify**: `curl -sf {{health_endpoint}} -o /dev/null && echo PASS`
  - **Done when**: Dev server running and health endpoint returns 200
  - **Commit**: None

- [ ] VE2 [VERIFY] E2E check: run critical flow verification
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session<!-- task-planner: append platform-specific skills here if research.md discovered them -->
  - **Do**:
    1. Run critical flow check: `{{critical_flow_cmd}}`
    2. Verify output matches expected behavior
  - **Verify**: `{{critical_flow_cmd}} && echo PASS`
  - **Done when**: Critical user flow completes successfully against running server
  - **Commit**: None

- [ ] VE3 [VERIFY] E2E cleanup: stop server and release resources
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session
  - **Do**:
    1. Kill processes by PID: `kill $(cat /tmp/ve-pids.txt) 2>/dev/null; sleep 2; kill -9 $(cat /tmp/ve-pids.txt) 2>/dev/null || true`
    2. Fallback port cleanup: `lsof -ti :{{port}} | xargs -r kill 2>/dev/null || true`
    3. Remove PID file: `rm -f /tmp/ve-pids.txt`
    4. Verify port free: `! lsof -ti :{{port}}`
  - **Verify**: `! lsof -ti :{{port}} && echo PASS`
  - **Done when**: No processes on port {{port}}, PID file removed
  - **Commit**: None

- [ ] 4.3 Merge after approval (optional - only if explicitly requested)
  - **Do**: Merge PR after approval and CI green
  - **Verify**: `gh pr merge --auto` or merge via GitHub UI
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

<!-- ============================================================ -->
<!-- TDD WORKFLOW (use when Intent = TRIVIAL/REFACTOR/MID_SIZED)  -->
<!-- ============================================================ -->

<!-- When generating tasks for a non-greenfield spec, use these TDD phases instead of the POC phases above -->

## Phase 1: Red-Green-Yellow Cycles

Focus: Test-driven implementation. Every change starts with a failing test.

- [ ] 1.1 [RED] Failing test: {{expected behavior A}}
  - **Do**:
    1. Write test asserting {{expected behavior}}
    2. Run test to confirm it fails with expected assertion error
  - **Files**: {{test file path}}
  - **Done when**: Test exists AND fails with expected assertion error
  - **Verify**: `{{test cmd}} -- --grep "{{test name}}" 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS`
  - **Commit**: `test(scope): red - failing test for {{behavior}}`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.2 [GREEN] Pass test: {{minimal implementation A}}
  - **Do**:
    1. Write minimum code to make the failing test pass
    2. Do NOT refactor, do NOT add extras
  - **Files**: {{impl file path}}
  - **Done when**: Previously failing test now passes
  - **Verify**: `{{test cmd}} -- --grep "{{test name}}"`
  - **Commit**: `feat(scope): green - implement {{behavior}}`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.3 [YELLOW] Refactor: {{cleanup A}}
  - **Do**:
    1. Refactor implementation while keeping all tests green
    2. Improve naming, extract helpers, remove duplication
  - **Files**: {{impl file, test file if needed}}
  - **Done when**: Code is clean AND all tests still pass
  - **Verify**: `{{test cmd}} && {{lint cmd}}`
  - **Commit**: `refactor(scope): yellow - clean up {{component}}`

- [ ] 1.4 [VERIFY] Quality checkpoint: {{lint cmd}} && {{typecheck cmd}} && {{test cmd}}
  - **Do**: Run quality commands and verify all pass
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors, all tests pass
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)

<!-- [P] is valid for independent [RED] tests, but NOT within a single R-G-Y triplet -->
<!-- Adjacent [RED] tests for independent behaviors can be [P] since they don't depend on each other -->
- [ ] 1.5 [P] [RED] Failing test: {{expected behavior B}}
  - **Do**:
    1. Write test asserting {{expected behavior B}}
    2. Run test to confirm it fails with expected assertion error
  - **Files**: {{test file path B}}
  - **Done when**: Test exists AND fails with expected assertion error
  - **Verify**: `{{test cmd}} -- --grep "{{test name B}}" 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS`
  - **Commit**: `test(scope): red - failing test for {{behavior B}}`
  - _Requirements: FR-2, AC-2.1_
  - _Design: Component B_

- [ ] 1.6 [P] [RED] Failing test: {{expected behavior C}}
  - **Do**:
    1. Write test asserting {{expected behavior C}}
    2. Run test to confirm it fails with expected assertion error
  - **Files**: {{test file path C}}
  - **Done when**: Test exists AND fails with expected assertion error
  - **Verify**: `{{test cmd}} -- --grep "{{test name C}}" 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS`
  - **Commit**: `test(scope): red - failing test for {{behavior C}}`
  - _Requirements: FR-3, AC-3.1_
  - _Design: Component C_

- [ ] 1.7 ...continue with [GREEN] for each, then next TDD triplet...

## Phase 2: Additional Testing

Focus: Integration and E2E tests beyond the unit tests written in Phase 1.

- [ ] 2.1 Integration tests for {{component interaction}}
  - **Do**: Create integration test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: Integration points tested across components
  - **Verify**: {{test cmd}} passes
  - **Commit**: `test(scope): add integration tests for {{component}}`
  - _Design: Test Strategy_

- [ ] 2.2 E2E tests (if UI)
  - **Do**: Create E2E test at {{path}}
  - **Files**: {{test file path}}
  - **Done when**: User flow tested end-to-end
  - **Verify**: {{e2e cmd}} passes
  - **Commit**: `test(scope): add e2e tests`
  - _Requirements: US-1_

- [ ] 2.3 [VERIFY] Quality checkpoint: {{lint cmd}} && {{typecheck cmd}} && {{test cmd}}
  - **Do**: Run all quality commands
  - **Verify**: All commands exit 0
  - **Done when**: All checks pass
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)

## Phase 3: Quality Gates

> (Same structure as POC Phase 4 above)

<!-- VE Tasks: VE0 (ui-map-init), VE1 (startup), VE2 (check), VE3 (cleanup) — generated from research.md Verification Tooling section -->
<!-- Skills field is REQUIRED on every VE task. task-planner: replace the comment placeholders below with actual platform-specific skills discovered in research.md (e.g., homeassistant-selector-map). Remove the HTML comment if no platform skills apply. -->

- [ ] VE0 [VERIFY] Build selector map (ui-map-init)
  - **Skills**: e2e, playwright-env, mcp-playwright, ui-map-init<!-- task-planner: append platform-specific skills here (e.g., homeassistant-selector-map) if research.md discovered them -->
  - **Do**: Follow `${CLAUDE_PLUGIN_ROOT}/skills/e2e/ui-map-init.skill.md` in full — open a fresh browser session, explore app routes, write `ui-map.local.md` to spec basePath.
  - **Verify**: `test -f {{basePath}}/ui-map.local.md && echo PASS`
  - **Done when**: `ui-map.local.md` exists with at least one route entry
  - **Commit**: None

- [ ] VE1 [VERIFY] E2E startup: launch dev server and verify health
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session<!-- task-planner: append platform-specific skills here if research.md discovered them -->
  - **Do**:
    1. Start dev server: `{{dev_cmd}}` (background, save PID to /tmp/ve-pids.txt)
    2. Wait for server ready: poll `{{health_endpoint}}` on port `{{port}}` until 200 (timeout 30s)
  - **Verify**: `curl -sf {{health_endpoint}} -o /dev/null && echo PASS`
  - **Done when**: Dev server running and health endpoint returns 200
  - **Commit**: None

- [ ] VE2 [VERIFY] E2E check: run critical flow verification
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session<!-- task-planner: append platform-specific skills here if research.md discovered them -->
  - **Do**:
    1. Run critical flow check: `{{critical_flow_cmd}}`
    2. Verify output matches expected behavior
  - **Verify**: `{{critical_flow_cmd}} && echo PASS`
  - **Done when**: Critical user flow completes successfully against running server
  - **Commit**: None

- [ ] VE3 [VERIFY] E2E cleanup: stop server and release resources
  - **Skills**: e2e, playwright-env, mcp-playwright, playwright-session
  - **Do**:
    1. Kill processes by PID: `kill $(cat /tmp/ve-pids.txt) 2>/dev/null; sleep 2; kill -9 $(cat /tmp/ve-pids.txt) 2>/dev/null || true`
    2. Fallback port cleanup: `lsof -ti :{{port}} | xargs -r kill 2>/dev/null || true`
    3. Remove PID file: `rm -f /tmp/ve-pids.txt`
    4. Verify port free: `! lsof -ti :{{port}}`
  - **Verify**: `! lsof -ti :{{port}} && echo PASS`
  - **Done when**: No processes on port {{port}}, PID file removed
  - **Commit**: None

## Phase 4: PR Lifecycle (Continuous Validation)

> (Same structure as POC Phase 5 above)

## Notes

- **TDD approach**: All implementation driven by failing tests first

## Dependencies

```
Phase 1 (TDD Cycles) → Phase 2 (Additional Tests) → Phase 3 (Quality) → Phase 4 (PR Lifecycle)
```
