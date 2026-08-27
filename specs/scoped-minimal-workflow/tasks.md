---
spec: scoped-minimal-workflow
phase: tasks
total_tasks: 15
created: 2026-08-27
generated: auto
---

# Tasks: scoped-minimal-workflow

Intent: MID_SIZED. Workflow: TDD. Granularity: coarse because the prompt-only change fits the 8-15 task range and the user explicitly requested minimal implementation.

## Phase 1: Red-Green Cycles

- [x] 1.1 [RED] Failing contract tests: bind scope before research
  - **Do**:
    1. Create Bats tests for all six scope labels in normal and quick intake.
    2. Assert quick binding occurs before reproduction and research.
    3. Assert `/new` routes through the normal goal interview.
  - **Files**: `tests/workflow-guardrails.bats`
  - **Done when**: The tests fail against the base prompts for the expected missing contract.
  - **Verify**: `! bats tests/workflow-guardrails.bats`
  - **Commit**: `test(scope): red - require scope binding before research`
  - _Requirements: FR-1, FR-2, FR-3, FR-4; AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5_

- [x] 1.2 [GREEN] Pass scope-intake tests
  - **Do**:
    1. Persist the six-field block in normal goal intake.
    2. Bind quick input before work or disable quick mode and set the approval gate.
    3. Route `/new` through the existing goal interview before research.
  - **Files**: `plugins/ralph-specum/references/goal-interview.md`, `plugins/ralph-specum/references/quick-mode.md`, `plugins/ralph-specum/commands/new.md`
  - **Done when**: Task 1.1 tests pass and no intake path begins work before scope binding.
  - **Verify**: `bats tests/workflow-guardrails.bats`
  - **Commit**: `feat(scope): green - bind authorization before research`
  - _Requirements: FR-1, FR-2, FR-3, FR-4; AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5_

- [x] V1 [VERIFY] Scope-intake checkpoint
  - **Do**: Run the new contract test and the existing interview suite.
  - **Files**: None
  - **Done when**: Both suites exit 0.
  - **Verify**: `bats tests/workflow-guardrails.bats tests/interview-framework.bats`
  - **Commit**: `chore(scope): pass intake checkpoint` (only if fixes are needed)
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-10_

- [x] 1.3 [RED] Failing contract tests: stop execution on scope expansion
  - **Do**:
    1. Add assertions for the executor pre-mutation comparison and escalation signal.
    2. Add assertions for coordinator approval, rejection, unchanged counters, and task-modification bounds.
    3. Add an assertion that adjacent issues remain learnings.
  - **Files**: `tests/workflow-guardrails.bats`
  - **Done when**: The added assertions fail against the base prompts for the expected missing contract.
  - **Verify**: `! bats tests/workflow-guardrails.bats`
  - **Commit**: `test(scope): red - require execution boundary checks`
  - _Requirements: FR-7, FR-8, FR-9; AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7_

- [x] 1.4 [GREEN] Pass execution-boundary tests
  - **Do**:
    1. Make task-planner keep task contracts and discoveries inside the envelope.
    2. Make spec-executor check scope before mutation and emit the escalation signal.
    3. Make coordinator handle both user decisions and bound automatic task changes.
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Task 1.3 assertions pass; escalation changes no task or failure counter before a user decision.
  - **Verify**: `bats tests/workflow-guardrails.bats`
  - **Commit**: `feat(scope): green - stop at the authorization boundary`
  - _Requirements: FR-7, FR-8, FR-9; AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7_

- [x] V2 [VERIFY] Execution-boundary checkpoint
  - **Do**: Run the new contract test plus integration and existing approval-stop coverage.
  - **Files**: None
  - **Done when**: Every suite exits 0.
  - **Verify**: `bats tests/workflow-guardrails.bats tests/integration.bats tests/stop-hook.bats`
  - **Commit**: `chore(scope): pass execution checkpoint` (only if fixes are needed)
  - _Requirements: FR-7, FR-8, FR-9, FR-10_

- [x] 1.5 [RED] Failing contract tests: prefer current mechanisms
  - **Do**:
    1. Assert the same four choices appear in order in architect, planner, and executor prompts.
    2. Assert avoidable dependencies and unjustified single-use abstractions are rejected.
    3. Assert required safety and verification behavior remains mandatory.
    4. Assert no source-skill path, import, or named source-skill heading appears in Ralph Specum.
  - **Files**: `tests/workflow-guardrails.bats`
  - **Done when**: The added assertions fail against the base prompts for the expected missing contract.
  - **Verify**: `! bats tests/workflow-guardrails.bats`
  - **Commit**: `test(planning): red - require reuse before new code`
  - _Requirements: FR-5, FR-6, FR-10; AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-4.2_

- [ ] 1.6 [GREEN] Pass minimal-implementation tests
  - **Do**:
    1. Add the ordered choice to architect-reviewer, task-planner, and spec-executor.
    2. Add planner completion checks for dependencies and abstractions.
    3. Keep task and verification boundaries stronger than the minimality rule.
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`, `plugins/ralph-specum/agents/task-planner.md`, `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Task 1.5 assertions pass with no new skill, reference, dependency, or production file.
  - **Verify**: `bats tests/workflow-guardrails.bats`
  - **Commit**: `feat(planning): green - prefer current mechanisms`
  - _Requirements: FR-5, FR-6; AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5_

- [ ] V3 [VERIFY] Prompt-contract checkpoint
  - **Do**: Run the new contract and all focused workflow suites.
  - **Files**: None
  - **Done when**: Every focused suite exits 0.
  - **Verify**: `bats tests/workflow-guardrails.bats tests/interview-framework.bats tests/integration.bats tests/stop-hook.bats`
  - **Commit**: `chore(workflow): pass prompt-contract checkpoint` (only if fixes are needed)
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10_

No YELLOW task is planned. The GREEN changes extend existing prose owners and need no extraction; create a YELLOW task only if the diff itself introduces duplication.

## Phase 2: Additional Testing

- [ ] 2.1 [VERIFY] Run focused workflow regression
  - **Do**: Run the start, interview, integration, and stop-hook suites with the new contract test.
  - **Files**: None
  - **Done when**: Every focused suite exits 0 with no test modification needed.
  - **Verify**: `bats tests/workflow-guardrails.bats tests/start-command.bats tests/interview-framework.bats tests/integration.bats tests/stop-hook.bats`
  - **Commit**: `fix(workflow): address focused regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-10; AC-4.1, AC-4.2_

## Phase 3: Quality Gates

- [ ] 3.1 Bump Ralph Specum to 4.11.0
  - **Do**:
    1. Set the Claude plugin manifest version to `4.11.0`.
    2. Set the Ralph Specum marketplace entry to `4.11.0`.
    3. Confirm the Codex plugin has no diff.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both scoped entries equal `4.11.0` and `plugins/ralph-specum-codex` remains unchanged.
  - **Verify**: `test "$(jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json)" = "4.11.0" && test "$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json)" = "4.11.0" && git diff --exit-code origin/main -- plugins/ralph-specum-codex`
  - **Commit**: `chore(ralph-specum): bump version to 4.11.0`
  - _Requirements: FR-11; AC-4.3_

- [ ] V4 [VERIFY] Full local release checks
  - **Do**:
    1. Run the full Bats suite and inspect status for generated spec-index changes.
    2. Validate both modified JSON files.
    3. Run diff, ASCII, and banned-phrase checks on changed prose.
    4. Run the documented local plugin smoke test.
  - **Files**: None
  - **Done when**: All local commands pass, the plugin loads, changed prose passes ASCII and banned-phrase scans, and no generated spec-index file changed.
  - **Verify**: `bats tests/*.bats && python3 -m json.tool plugins/ralph-specum/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && git diff --check && test -z "$(git status --short | rg 'specs/\.index' || true)" && ! git diff --unified=0 origin/main -- '*.md' | rg '^\+.*(robust|seamless|dive in|delve|it.s worth noting|comprehensive|leverage)' && ! git diff --unified=0 origin/main -- '*.md' | LC_ALL=C rg '[^ -~]' && claude --plugin-dir ./plugins/ralph-specum -p '/ralph-specum:help'`
  - **Commit**: `fix(workflow): address local release failures` (only if an in-scope fix is needed)
  - _Requirements: FR-10, FR-11; AC-4.1, AC-4.2, AC-4.3_

- [ ] V5 [VERIFY] Create pull request and pass every triggered workflow
  - **Do**:
    1. Push `codex/scoped-minimal-workflow` and open a PR against `main` using the repository template.
    2. Wait for every triggered GitHub workflow, not only required checks.
    3. Fix only failures caused by this branch, then push and recheck.
  - **Files**: None unless a triggered check identifies an in-scope defect in a file already listed in tasks 1.2, 1.4, 1.6, or 3.1
  - **Done when**: The PR is open and every entry in `statusCheckRollup` has a successful conclusion.
  - **Verify**: `PR=$(gh pr view --json number --jq .number) && gh pr checks "$PR" --watch && gh pr view "$PR" --json statusCheckRollup --jq 'all(.statusCheckRollup[]; .conclusion == "SUCCESS")'`
  - **Commit**: `fix(workflow): address CI findings` (only if an in-scope fix is needed)
  - _Requirements: FR-12; AC-4.4_

- [ ] V6 [VERIFY] Acceptance-criteria checklist
  - **Do**: Map AC-1.1 through AC-4.3 to a passing command, diff line, or GitHub check. AC-4.4 remains the Phase 4 completion gate.
  - **Files**: `specs/scoped-minimal-workflow/requirements.md`, `specs/scoped-minimal-workflow/tasks.md`
  - **Done when**: AC-1.1 through AC-4.3 have current evidence and no criterion relies on an unsupported compliance claim.
  - **Verify**: `bats tests/workflow-guardrails.bats && git diff --check && gh pr view --json statusCheckRollup`
  - **Commit**: `chore(workflow): record acceptance evidence` (only if spec evidence changes)
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-12_

## Phase 4: PR Lifecycle

- [ ] 4.1 Resolve all in-scope review threads
  - **Do**:
    1. Query every review thread with pagination state.
    2. Apply and verify only fixes that fit the Scope Envelope; escalate any broader request.
    3. Reply when needed and resolve the thread after its fix is present.
    4. Recheck CI and review threads after each push until both gates pass.
  - **Files**: None for monitoring; an in-scope review fix may touch only a file already listed in tasks 1.2, 1.4, 1.6, 3.1, or `tests/workflow-guardrails.bats`
  - **Done when**: Every triggered check is successful, `hasNextPage` is false, and the unresolved review-thread list is empty.
  - **Verify**: `PR=$(gh pr view --json number --jq .number) && gh pr checks "$PR" && test -z "$(gh api graphql --paginate -F owner=tzachbon -F name=smart-ralph -F number="$PR" -f query='query($owner:String!,$name:String!,$number:Int!,$endCursor:String){repository(owner:$owner,name:$name){pullRequest(number:$number){reviewThreads(first:100,after:$endCursor){nodes{isResolved} pageInfo{hasNextPage endCursor}}}}}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)')"`
  - **Commit**: `fix(workflow): resolve review findings` (only if an in-scope fix is needed)
  - _Requirements: FR-12; AC-4.4_
