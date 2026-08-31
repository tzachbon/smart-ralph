# Tasks: Codex phase interviews as a hard gate

## Overview

Total tasks: 6

This is a targeted TDD contract change: add one red coordinator-matrix Bats seam, make the existing Codex skill contracts satisfy it, bump the required patch version, then run both existing Bats suites. Do not add a helper, hook, dependency, or state-machine behavior.

## Completion Criteria

- The primary fallback plus `start`, `triage`, `research`, `requirements`, `design`, and `tasks` explicitly fail closed before dispatch, transition, or target-artifact write unless the current delegation gate succeeds.
- Normal failed-gate recovery uses a fresh manifest/interview identity only on the next explicit invocation; a valid in-progress interview still resumes.
- Only exact `--quick` bypasses questions and final approval; discovery, manifest, parent delegation, load receipts, and `check-agent-write` remain required.
- `tests/codex-phase-flow.bats` and unchanged `tests/phase-gates.bats` pass.
- The Codex manifest is `4.12.3`; the separate Claude marketplace remains package-owned.

## Phase 1: Red-Green Contract Change

- [x] 1.1 [RED] Add the hard-transition coordinator matrix regression
  - **Do**:
    1. Extend the existing `phase_skills` text-contract pattern in `tests/codex-phase-flow.bats` with one table-driven Bats assertion covering the shared framework, primary fallback, and the six affected helper skills.
    2. Require the matrix to prove: failed normal-mode `check-delegation` stops before state transition, child dispatch, or target-artifact write; the next explicit invocation takes fresh recovery; valid in-progress resumes remain valid; exact `--quick` retains all provenance and writer checks; and triage keeps `.epic-state.json` for every writer.
    3. Change the existing manifest assertion to require the planned Codex `4.12.3` version without coupling it to the separate Claude marketplace.
  - **Files**: `tests/codex-phase-flow.bats`
  - **Done when**: One coordinator-matrix test fails against the current wording for the missing hard-transition and recovery contract, while `tests/phase-gates.bats` is not edited.
  - **Verify**: `bats tests/codex-phase-flow.bats` exits nonzero because the new matrix is red.
  - **Commit**: `test(codex): add hard-gate contract regression`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-6; AC-1.1, AC-1.2, AC-2.1, AC-2.2, AC-2.3_
  - _Design: Test Strategy, Shared interview framework, Affected coordinator contracts_

- [x] 1.2 [GREEN] Define the shared hard-transition invariant and fallback coverage
  - **Do**:
    1. Add one concise invariant to the Codex interview framework: run the current delegation check immediately before each affected transition or child dispatch, and stop on failure before state mutation, dispatch, or target-artifact write.
    2. In the algorithm, state the same fail-closed boundary, preserve the existing last pre-write `check-agent-write`, and define fresh-next-explicit-invocation recovery without changing helper semantics or exact quick authorization.
    3. Make the primary fallback apply that invariant only to `start`, `triage`, `research`, `requirements`, `design`, and `tasks`; leave `implement` and `refactor` unchanged.
  - **Files**: `plugins/ralph-specum-codex/skills/interview-framework-codex/SKILL.md`, `plugins/ralph-specum-codex/skills/interview-framework-codex/references/algorithm.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`
  - **Done when**: The shared source of truth and primary fallback make a failed gate terminal for that invocation, preserve matching partial-interview resumes, and keep exact quick narrow.
  - **Verify**: `bats tests/codex-phase-flow.bats` remains red only until the affected helper-skill entries in tasks 1.3 and 1.4 are updated.
  - **Commit**: `docs(codex): define hard interview transition gate`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5; AC-1.2, AC-2.1, AC-2.2_
  - _Design: Shared interview framework, Existing phase-gate helper_

- [x] 1.3 [GREEN] Apply the invariant to fresh, triage, and direct research dispatch
  - **Do**:
    1. Update the start contract so fresh and resumed research dispatch cannot run after a failed normal-mode gate and the next explicit invocation creates a fresh identity only after that failure.
    2. Update triage so its existing `.epic-state.json` flow applies the same stop rule before every artifact-producing child, without changing its read-only exploration or multi-writer behavior.
    3. Update direct research dispatch to stop before the research writer, phase transition, or target artifact when the current delegation check fails.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-triage/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-research/SKILL.md`
  - **Done when**: Fresh start, resumed start, triage, and direct research explicitly rely on the shared fail-closed boundary while preserving their existing packet, identity, and exact-quick behavior.
  - **Verify**: `bats tests/codex-phase-flow.bats` continues to exercise the matrix and remains red only for the downstream helper contracts and version until their planned tasks complete.
  - **Commit**: `docs(codex): gate start triage and research dispatch`
  - _Requirements: FR-2, FR-3, FR-4, FR-5, FR-6; AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2_
  - _Design: Affected coordinator contracts, Data Flow, Edge Cases_

- [x] 1.4 [GREEN] Apply the invariant to downstream phase dispatch
  - **Do**:
    1. Update requirements, design, and tasks coordinator contracts to stop before their existing writer dispatch, transition, or target artifact when `check-delegation` fails.
    2. Keep each existing child packet, unique dispatch identity, `check-agent-write` pre-write guard, artifact-approval behavior, prototype selection, and exact quick behavior unchanged.
    3. Do not edit `phase_gate.py`, artifact-agent templates, hooks, schemas, or `tests/phase-gates.bats`.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-requirements/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-design/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-tasks/SKILL.md`
  - **Done when**: Every direct downstream coordinator named in the matrix has an explicit fail-closed delegation boundary and no alternate quick-mode bypass.
  - **Verify**: `bats tests/codex-phase-flow.bats` passes except for the intentional version assertion pending task 1.5.
  - **Commit**: `docs(codex): gate downstream phase dispatch`
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6; AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3_
  - _Design: Affected coordinator contracts, Error Handling, Test Strategy_

- [x] 1.5 [GREEN] Bump the Codex plugin patch version
  - **Do**:
    1. Change the Codex plugin manifest version from `4.12.2` to `4.12.3`.
    2. Finish the Bats manifest assertion added in task 1.1 so it checks the Codex manifest carries that patch version.
  - **Files**: `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, `tests/codex-phase-flow.bats`
  - **Done when**: The Codex manifest and its Bats regression assertion agree on exactly `4.12.3`.
  - **Verify**: `bats tests/codex-phase-flow.bats` exits 0.
  - **Commit**: `chore(codex): bump plugin version to 4.12.3`
  - _Requirements: FR-7; Release validation_
  - _Design: File Structure_

## Phase 2: Quality Checkpoint

- [x] 2.1 [VERIFY] Run the unchanged helper suite and the coordinator regression suite
  - **Do**:
    1. Run the two existing Bats files together.
    2. Confirm `tests/phase-gates.bats` has no source diff and the Codex helper remains byte-identical to the Claude helper.
    3. Confirm the matrix proves the normal, direct, resumed, triage, and exact-quick cases without adding a runtime enforcement mechanism.
  - **Files**: `tests/phase-gates.bats` (read-only verification), `tests/codex-phase-flow.bats` (read-only verification)
  - **Done when**: Both suites pass and the only implementation changes are the planned Codex Markdown contracts, one Bats seam, and the Codex manifest version bump.
  - **Verify**: `bats tests/phase-gates.bats tests/codex-phase-flow.bats`
  - **Commit**: `test(codex): verify hard interview gate`
  - _Requirements: FR-5, FR-6, FR-7; NFR-1, NFR-2, NFR-3_
  - _Design: Test Strategy, Dependencies_

## Dependencies

`1.1 -> 1.2 -> 1.3 -> 1.4 -> 1.5 -> 2.1`
