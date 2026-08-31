---
spec: contextual-approval-replies
phase: tasks
total_tasks: 18
created: 2026-08-31
generated: auto
---

# Tasks: contextual-approval-replies

Intent: MID_SIZED behavior change. Workflow: POC-first, as required by the repository workflow. Granularity: fine. This quick run is local-only: do not add push, PR, CI polling, merge, or issue-mutation tasks.

## Phase 1: Make It Work (POC)

- [x] 1.1 Define the persisted one-action approval model
  - **Do**:
    1. Add shared `approvalGate` and append-only `approvalAudit` schema definitions to the spec schema.
    2. Expose both optional fields on spec and epic state without making legacy states invalid.
    3. Require a nonblank gate ID, phase, kind, and action; require recorded feedback for a revision gate.
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`, `plugins/ralph-specum-codex/schemas/spec.schema.json`
  - **Done when**: Both schemas describe one optional current artifact/revision action and an audit entry containing the original reply, normalized action, and gate ID, while remaining byte-identical.
  - **Verify**: `cmp plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json && python3 -m json.tool plugins/ralph-specum/schemas/spec.schema.json >/dev/null`
  - **Commit**: `feat(gates): define contextual approval state`
  - _Requirements: FR-3, FR-5, FR-8; AC-2.1, AC-3.1, AC-4.1, AC-4.3_
  - _Design: Persisted approval context_

- [x] 1.2 Add the shared state-aware approval resolver
  - **Do**:
    1. Add `resolve-approval STATE --text TEXT` under the existing state lock and copy it byte-for-byte to both helpers.
    2. Derive only one live candidate from either the sole pending final-confirmation ID or an `awaitingApproval` descriptor for the current phase; reject zero, stale, malformed, or competing candidates.
    3. Recognize a finite affirmative grammar, reject questions, quotations/history, negation, revision requests, unrelated or mixed text, append the audit only on acceptance, and leave `classify-reply`, `confirm`, and delegation transitions unchanged.
  - **Files**: `plugins/ralph-specum/scripts/phase_gate.py`, `plugins/ralph-specum-codex/scripts/phase_gate.py`
  - **Done when**: The command returns either an accepted canonical action with a gate ID or a clarification result with no state mutation; accepted replies only append the required audit record.
  - **Verify**: `tmp="$(mktemp -d)" && trap 'rm -rf "$tmp"' EXIT && state="$tmp/state.json" && jq -n '{phase:"requirements",phaseInterview:{phase:"requirements",interviewId:"requirements-1",round:1,status:"awaiting_confirmation",askedDecisionIds:["final"],pendingDecisionIds:["final"],answeredDecisionIds:[],selectedApproach:"Keep the existing path",confirmationSource:null,bypassReason:null,assumptionsRecorded:[]}}' >"$state" && result="$(python3 plugins/ralph-specum/scripts/phase_gate.py resolve-approval "$state" --text 'looks good')" && jq -e '.decision == "accepted" and .action == "approve-and-delegate" and .gateId == "final"' <<<"$result" && jq -e '.approvalAudit == [{originalReply:"looks good",normalizedAction:"approve-and-delegate",gateId:"final"}]' "$state" && cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py`
  - **Commit**: `feat(gates): resolve contextual approval replies`
  - _Requirements: FR-1, FR-2, FR-4, FR-5, FR-6, FR-7, FR-8; AC-1.1, AC-1.2, AC-1.3, AC-2.2, AC-2.3, AC-3.2, AC-3.3, AC-4.1_
  - _Design: Shared phase-gate helper; Interfaces; Error Handling_

- [x] V1 [VERIFY] POC shared-gate checkpoint
  - **Do**: Run the existing state-transition regression suite and both byte-parity checks after the schema and helper POC.
  - **Files**: None (verification-only)
  - **Done when**: Existing gate behavior remains green and both mirrored artifacts are identical.
  - **Verify**: `bats tests/phase-gates.bats && cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py && cmp plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json`
  - **Commit**: `fix(gates): address POC regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-2, FR-4, FR-6, FR-7, FR-8; AC-1.2, AC-1.3, AC-2.2, AC-2.3, AC-3.2, AC-3.3, AC-4.3_
  - _Design: Existing Patterns to Follow; Security Considerations_

- [x] 1.3 Route Claude's shared gate contract through the resolver
  - **Do**:
    1. Keep `classify-reply` as the active-decision-frontier classifier.
    2. At final confirmation and artifact review, use `resolve-approval` only as a contextual fallback after the canonical choices.
    3. Document the one-descriptor rule, descriptor lifecycle, audit ownership, and reuse of canonical confirmation/delegation checks.
  - **Files**: `plugins/ralph-specum/references/normal-mode-gates.md`, `plugins/ralph-specum/skills/interview-framework/SKILL.md`, `plugins/ralph-specum/skills/interview-framework/references/algorithm.md`
  - **Done when**: Claude's common gate instructions distinguish active-question control replies from one-action contextual approvals and fail closed on ambiguity.
  - **Verify**: `bats tests/claude-phase-flow.bats`
  - **Commit**: `docs(gates): route Claude contextual approvals`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-6, FR-7; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-3.1, AC-3.3_
  - _Design: Data Flow; Existing Patterns to Follow_

- [x] 1.4 Route Codex's shared gate contract through the resolver
  - **Do**:
    1. Preserve control-only handling for open interview decisions.
    2. Document resolver-first contextual fallback at final confirmation and artifact review, including the existing `confirm` and `check-delegation` path after acceptance.
    3. State that a missing or multi-option artifact view has no descriptor and must ask one focused clarification.
  - **Files**: `plugins/ralph-specum-codex/skills/interview-framework-codex/SKILL.md`, `plugins/ralph-specum-codex/skills/interview-framework-codex/references/algorithm.md`, `plugins/ralph-specum-codex/references/workflow.md`
  - **Done when**: Codex's shared workflow has the same one-action, persisted-state boundary as the helper and does not broaden active-question semantics.
  - **Verify**: `bats tests/codex-phase-flow.bats`
  - **Commit**: `docs(gates): route Codex contextual approvals`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-6, FR-7; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-3.1, AC-3.3_
  - _Design: Data Flow; Error Handling; Edge Cases_

- [x] V2 [VERIFY] Shared-contract checkpoint
  - **Do**: Run both prompt-flow suites after wiring the shared approval contracts.
  - **Files**: None (verification-only)
  - **Done when**: Both surfaces retain their existing phase provenance and approval contracts while documenting the resolver boundary.
  - **Verify**: `bats tests/claude-phase-flow.bats tests/codex-phase-flow.bats`
  - **Commit**: `fix(gates): address shared contract regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-2, FR-4, FR-6, FR-7; AC-1.2, AC-1.3, AC-2.2, AC-3.2, AC-3.3_
  - _Design: Architecture; Security Considerations_

## Phase 2: Refactoring

- [x] 2.1 Align Claude start, triage, and research handoffs
  - **Do**:
    1. Replace only conflicting blanket control-only approval wording with the shared resolver rule.
    2. Preserve canonical choices and source-specific phase/interview/manifest checks.
    3. Set an artifact or revision descriptor only when that handoff has exactly one action; do not infer a multi-option prompt.
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/commands/triage.md`, `plugins/ralph-specum/commands/research.md`
  - **Done when**: These handoffs delegate or advance only through the persisted one-action resolver path and leave ambiguous replies for clarification.
  - **Verify**: `bats tests/claude-phase-flow.bats`
  - **Commit**: `docs(gates): align Claude early-phase handoffs`
  - _Requirements: FR-1, FR-3, FR-4, FR-7; AC-1.1, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3_
  - _Design: Persisted approval context; Data Flow_

- [x] 2.2 Align Claude downstream artifact handoffs
  - **Do**:
    1. Apply the same narrow fallback to requirements, design, and tasks artifact review clauses.
    2. Require recorded feedback before creating a revision descriptor or dispatching a revision.
    3. Clear or replace a descriptor only after the existing continuation or revision action succeeds.
  - **Files**: `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Contextual approval cannot choose among review, prototype, continuation, or revision options unless one live descriptor names the sole action.
  - **Verify**: `bats tests/claude-phase-flow.bats`
  - **Commit**: `docs(gates): align Claude downstream handoffs`
  - _Requirements: FR-1, FR-3, FR-4, FR-5, FR-7; AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3, AC-4.1_
  - _Design: Persisted approval context; Error Handling; Edge Cases_

- [x] V3 [VERIFY] Claude handoff checkpoint
  - **Do**: Run Claude's prompt-flow regression suite and verify no source-specific prompt bypasses the shared helper.
  - **Files**: None (verification-only)
  - **Done when**: The Claude suite passes and all six phase commands still use the normal gate contract.
  - **Verify**: `bats tests/claude-phase-flow.bats && rg -l 'resolve-approval|normal-mode-gates.md' plugins/ralph-specum/commands/{start,triage,research,requirements,design,tasks}.md | wc -l | rg -qx '6'`
  - **Commit**: `fix(gates): address Claude handoff regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-4, FR-6, FR-7; AC-1.2, AC-1.3, AC-2.2, AC-2.3, AC-3.2, AC-3.3_
  - _Design: Existing Patterns to Follow_

- [x] 2.3 Align Codex state, primary routing, and start handoffs
  - **Do**:
    1. Document the descriptor and audit fields in the state contract as helper-owned enforcement state.
    2. Make primary routing and start reference the shared one-action fallback without changing implement/refactor behavior.
    3. Preserve exact quick-mode rules and canonical choices.
  - **Files**: `plugins/ralph-specum-codex/references/state-contract.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md`
  - **Done when**: Codex state and entry routing describe the persisted descriptor lifecycle and never use chat history as authorization state.
  - **Verify**: `bats tests/codex-phase-flow.bats`
  - **Commit**: `docs(gates): align Codex entry handoffs`
  - _Requirements: FR-1, FR-3, FR-4, FR-5, FR-7; AC-1.1, AC-2.1, AC-2.2, AC-3.1, AC-3.2, AC-4.1, AC-4.2_
  - _Design: Persisted approval context; Interfaces_

- [ ] 2.4 Align Codex triage, research, and requirements handoffs
  - **Do**:
    1. Replace conflicting control-only artifact approval wording with the shared resolver fallback.
    2. Require one current descriptor for artifact advancement and recorded feedback for revision dispatch.
    3. Keep the current phase-specific check-delegation and fresh-writer packets authoritative.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-triage/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-research/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-requirements/SKILL.md`
  - **Done when**: Each Codex handoff fails closed for invalid, missing, or multi-action state and uses the helper result only to select an existing path.
  - **Verify**: `bats tests/codex-phase-flow.bats`
  - **Commit**: `docs(gates): align Codex early-phase handoffs`
  - _Requirements: FR-1, FR-3, FR-4, FR-7; AC-1.1, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3_
  - _Design: Data Flow; Error Handling_

- [ ] V4 [VERIFY] Codex early-handoff checkpoint
  - **Do**: Run Codex's prompt-flow suite after the state and early-phase handoff cleanup.
  - **Files**: None (verification-only)
  - **Done when**: The Codex suite passes and no prompt creates an alternate approval or writer path.
  - **Verify**: `bats tests/codex-phase-flow.bats`
  - **Commit**: `fix(gates): address Codex early-handoff regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-2, FR-4, FR-6, FR-7; AC-1.2, AC-1.3, AC-2.2, AC-3.2, AC-3.3_
  - _Design: Security Considerations_

- [ ] 2.5 Align Codex design and tasks handoffs
  - **Do**:
    1. Apply the shared descriptor/fallback wording to design and tasks artifact reviews.
    2. Keep multi-option prototype/review branches descriptor-free until the coordinator has one explicit action.
    3. Keep revision feedback and fresh gated dispatch requirements intact.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-design/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-tasks/SKILL.md`
  - **Done when**: Design and task approval text cannot infer an action from a bare affirmative in a multi-option view.
  - **Verify**: `bats tests/codex-phase-flow.bats`
  - **Commit**: `docs(gates): align Codex downstream handoffs`
  - _Requirements: FR-1, FR-3, FR-4, FR-7; AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3_
  - _Design: Edge Cases; Existing Patterns to Follow_

## Phase 3: Testing

- [ ] 3.1 Add resolver behavior and state-safety coverage
  - **Do**:
    1. Add Bats cases for accepted pre-delegation, artifact, and recorded-feedback revision actions on both helpers.
    2. Assert original reply, normalized action, and gate ID audit fields; reload state to prove resume uses the live descriptor.
    3. Snapshot state around questions, quotes/history, negation, revision requests, unrelated/mixed text, missing/stale descriptors, and multiple actions to prove no mutation; retain the `classify-reply` control-only tests.
  - **Files**: `tests/phase-gates.bats`
  - **Done when**: Tests prove only one current persisted action can be inferred and helpers plus schemas remain byte-identical.
  - **Verify**: `bats tests/phase-gates.bats`
  - **Commit**: `test(gates): cover contextual approval resolution`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Test Strategy; Security Considerations_

- [ ] 3.2 Add Claude and Codex prompt-flow contract coverage
  - **Do**:
    1. Require both flow suites to find the resolver fallback, one-descriptor rule, revision-feedback precondition, and retained canonical confirmation path.
    2. Update the Codex release expectation to the patched version.
    3. Keep tests content-based and limited to the documented gate seams.
  - **Files**: `tests/claude-phase-flow.bats`, `tests/codex-phase-flow.bats`
  - **Done when**: Both prompt-flow suites fail if either surface restores a blanket rejection or bypasses state-backed approval.
  - **Verify**: `bats tests/claude-phase-flow.bats tests/codex-phase-flow.bats`
  - **Commit**: `test(gates): cover approval handoff contracts`
  - _Requirements: FR-3, FR-4, FR-6, FR-7, FR-8; AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3, AC-4.3_
  - _Design: Test Strategy; Existing Patterns to Follow_

- [ ] V5 [VERIFY] Contextual-approval test checkpoint
  - **Do**: Run all focused helper and prompt-flow suites after permanent coverage is in place.
  - **Files**: None (verification-only)
  - **Done when**: The accepted, rejected, ambiguity, audit, and resume seams are green on both plugin surfaces.
  - **Verify**: `bats tests/phase-gates.bats tests/claude-phase-flow.bats tests/codex-phase-flow.bats`
  - **Commit**: `fix(gates): address contextual approval regressions` (only if an in-scope fix is needed)
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Test Strategy_

## Phase 4: Quality Gates

- [ ] 4.1 Bump the affected plugin release metadata
  - **Do**:
    1. Bump the Claude plugin and marketplace entries from `4.12.0` to `4.12.1`.
    2. Bump the Codex plugin manifest from `4.12.0` to `4.12.1`.
    3. Do not change unrelated plugin metadata.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`
  - **Done when**: Every modified plugin's required release metadata agrees on `4.12.1`.
  - **Verify**: `test "$(jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json)" = 4.12.1 && test "$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json)" = 4.12.1 && test "$(jq -r .version plugins/ralph-specum-codex/.codex-plugin/plugin.json)" = 4.12.1`
  - **Commit**: `chore(plugins): bump contextual approval release`
  - _Requirements: FR-8; AC-4.3_
  - _Design: File Structure; Dependencies_

- [ ] V6 [VERIFY] Run the local release-quality gate
  - **Do**:
    1. Run the full Bats suite and both parity checks.
    2. Validate changed JSON and inspect whitespace errors.
    3. Report local completion only; do not push, create a PR, poll CI, merge, or mutate the issue.
  - **Files**: None (verification-only)
  - **Done when**: All local tests and parity checks pass, release JSON is valid, and the worktree has no whitespace errors.
  - **Verify**: `bats tests/*.bats && cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py && cmp plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json && python3 -m json.tool plugins/ralph-specum/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && python3 -m json.tool plugins/ralph-specum-codex/.codex-plugin/plugin.json >/dev/null && git diff --check`
  - **Commit**: `fix(gates): address local quality findings` (only if an in-scope fix is needed)
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3, AC-3.1, AC-3.2, AC-3.3, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Test Strategy; Security Considerations_

## Notes

- **POC scope**: Reuse the existing helper lock, atomic writer, normalizer, confirmation, and delegation checks. No new dependency, NLP layer, action list, or alternate authorization path is planned.
- **Remote lifecycle**: Skipped by exact quick mode; local verification is the terminal delivery gate.

## Dependencies

```text
1.1 -> 1.2 -> V1 -> 1.3/1.4 -> V2 -> 2.1/2.2 -> V3 -> 2.3/2.4 -> V4 -> 2.5 -> 3.1/3.2 -> V5 -> 4.1 -> V6
```
