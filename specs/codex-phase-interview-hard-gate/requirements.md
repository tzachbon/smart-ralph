---
spec: codex-phase-interview-hard-gate
phase: requirements
created: 2026-08-31
source: research.md
---

# Requirements: codex-phase-interview-hard-gate

## Problem Statement

Codex coordinators can describe, but not consistently enforce, the required phase interview. A normal-mode phase can therefore dispatch work, write an artifact, or transition despite a missing, stale, partial, mismatched, or unapproved interview. Evidence: `research.md` and issue #149.

## Goal

Make the existing `phase_gate.py` checks the hard, shared transition boundary for every Codex phase entry point that requires an interview. Preserve exact `--quick` as the sole question-and-approval bypass without weakening any provenance or artifact-writer checks.

## User Stories

### US-1: Safe normal phase execution

**As a** Smart Ralph user
**I want** every normal Codex phase to wait for a valid interview and my explicit approval
**So that** no phase work starts without my decisions.

**Acceptance Criteria:**

- AC-1.1: Given a fresh normal `start`, when its interview is not terminal and explicitly approved, then it does not delegate, write a phase artifact, or transition.
- AC-1.2: Given a direct or resumed gated phase with a missing, stale, partial, mismatched, or unapproved interview, when it reaches a transition or writer dispatch, then it stops before that action.
- AC-1.3: Given any affected entry point, including applicable `triage`, when the current interview tuple is valid and approved, then it may proceed through the existing delegation flow.

### US-2: Predictable recovery and quick mode

**As a** Smart Ralph user
**I want** an invalid interview state to recover predictably and quick mode to remain narrow
**So that** safety does not make the workflow ambiguous or broaden bypasses.

**Acceptance Criteria:**

- AC-2.1: Given a normal-mode gate failure, when I explicitly invoke that affected phase again, then it starts a fresh interview identity and does not reuse the failed state.
- AC-2.2: Given exact `--quick`, when a gated phase runs, then it bypasses only interview questions and final approval while still completing discovery, manifest loading, parent delegation, child-load receipt, and child-write checks.
- AC-2.3: Given `-q`, a misspelling, a natural-language shortcut, or any non-exact flag, when a phase starts, then it does not enable the quick bypass.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | The Codex interview framework MUST define one shared hard-transition invariant: run the current `check-delegation` before every affected phase transition or child dispatch, and run the current `check-agent-write` before every artifact write. A failed check stops the action. | Must | AC-1.1, AC-1.2, AC-1.3 |
| FR-2 | The primary fallback plus `start`, `triage`, `research`, `requirements`, `design`, and `tasks` MUST apply that invariant at their existing coordinator boundaries. Triage MUST use its existing epic-state behavior. | Must | AC-1.2, AC-1.3 |
| FR-3 | A failed normal-mode gate for missing, stale, partial, or mismatched interview state MUST fail closed without state transition, dispatch, or target-artifact write. The next explicit invocation MUST create a fresh manifest/interview identity before beginning the interview. | Must | AC-1.2, AC-2.1 |
| FR-4 | Exact `--quick` MUST remain the only bypass and MUST retain existing discovery, skill-manifest, context-digest, delegation, and child writer-receipt checks. | Must | AC-2.2, AC-2.3 |
| FR-5 | Existing state, manifest, context-digest, parent-delegation, and `check-agent-write` validation semantics MUST remain unchanged. | Must | AC-1.3, AC-2.2 |
| FR-6 | One Bats regression seam in `tests/codex-phase-flow.bats` MUST reproduce the bypass contract and cover fresh normal start, direct phase, resumed phase, and exact quick mode across the affected coordinator matrix. | Must | AC-1.1, AC-1.2, AC-2.2, AC-2.3 |
| FR-7 | The Codex plugin patch version MUST be bumped once in both `plugins/ralph-specum-codex/.codex-plugin/plugin.json` and `.claude-plugin/marketplace.json`. | Must | Release validation |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Minimality | New enforcement mechanisms or dependencies | 0; reuse `phase_gate.py` and existing coordinator contracts |
| NFR-2 | Safety | Invalid normal-mode gate paths that reach dispatch, write, or transition | 0 in the Bats regression matrix |
| NFR-3 | Compatibility | Existing phase-gate Bats checks | All existing checks continue to pass unchanged |

## Glossary

- **Hard transition gate**: The shared pre-dispatch and pre-write rule that prevents work until the current phase gate check succeeds.
- **Identity tuple**: The matching `phase`, `interviewId`, `discoveryRevision`, and `contextDigest` values that prove a current interview and manifest.
- **Fresh recovery**: Starting a new manifest and interview identity on the next explicit invocation after a normal-mode gate failure.
- **Exact quick mode**: The path authorized only by the literal `--quick` flag; it skips interview interaction, not provenance checks.

## Out of Scope

- Adding a new hook, middleware layer, dependency, or separate phase-gate state machine.
- Changing the byte-identical Claude plugin helper or broadening this Codex-only fix.
- Changing #148's natural-language approval parsing behavior.
- Changing implementation/execution-loop behavior outside the interview-gated phases.

## Dependencies

- Existing `plugins/ralph-specum-codex/scripts/phase_gate.py` validation and recovery behavior.
- Existing `tests/codex-phase-flow.bats` Bats test seam and CI Bats provisioning.
- Required Codex plugin and marketplace manifest version metadata.

## Success Criteria

- The one regression seam proves that fresh, direct, resumed, and exact-quick paths retain or enforce the hard gate as specified.
- Every affected normal-mode coordinator stops before delegation, artifact writing, or phase transition unless the current interview has explicit approval.
- No new dependency, hook, middleware, or helper state-machine behavior is introduced.
- Both required plugin manifests carry the same single patch-version bump.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Fresh recovery accidentally replaces a valid partial-interview resume. | Medium | Limit fresh recovery to failed stale/partial/missing/mismatched gate paths; preserve matching in-progress resumes. |
| Quick mode expands beyond exact `--quick`. | High | Reuse the existing exact-authorization validation and assert non-exact variants remain interactive. |
| Per-entrypoint wording drifts. | Medium | Put the invariant in the shared interview framework and enforce it through the single coordinator-matrix Bats seam. |

## Unresolved Questions

- None.
