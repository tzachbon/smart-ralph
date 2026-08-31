# Requirements: contextual-approval-replies

## Problem Statement

Smart Ralph workflow users must repeat exact control phrases at approval gates even when exactly one action is explicitly pending. Evidence: [research.md](research.md) and GitHub issue #148.

## Goal

Accept a conservative, unambiguous natural-language affirmative only for one persisted approval action across both `ralph-specum` and `ralph-specum-codex`. Preserve the existing state, manifest, confirmation, delegation, and writer checks, while recording how each inferred approval was resolved.

## User Stories

### US-1: Approve one phase interview naturally

**As a** Smart Ralph workflow user
**I want to** approve the one pending phase-interview confirmation in natural language
**So that** I do not need to repeat a command-like phrase when my intent is clear

**Acceptance Criteria:**

- AC-1.1: Given a phase interview is `awaiting_confirmation` with exactly one pending confirmation ID, When the user replies `approve`, `yes`, `go ahead`, `do it`, or another unambiguous equivalent affirmative, Then the resolver records the reply and normalizes it to the existing `approve-and-delegate` confirmation path.
- AC-1.2: Given a phase interview is `awaiting_confirmation` with exactly one pending confirmation ID, When the resolver accepts an affirmative reply, Then the existing `confirm`, manifest validation, and `check-delegation` checks remain the authority before delegation occurs.
- AC-1.3: Given a phase interview has active decision questions, When the user sends an affirmative/control reply, Then `classify-reply` retains its current `control_only` behavior and no decision answer or approval is recorded.

### US-2: Advance one approved artifact naturally

**As a** Smart Ralph workflow user
**I want to** affirmatively approve an artifact that has one explicitly named next action
**So that** the workflow can continue without requiring the canonical wording

**Acceptance Criteria:**

- AC-2.1: Given an artifact approval gate persists exactly one valid action naming its next step, When the user sends an unambiguous affirmative such as `looks good, continue`, Then the artifact is approved and the existing path for that named action runs.
- AC-2.2: Given an artifact view offers multiple actions, When the user sends an affirmative reply without one persisted action descriptor, Then approval state is unchanged and the workflow asks one focused clarification.
- AC-2.3: Given an artifact gate is missing, stale, or invalid, When the user sends an affirmative reply, Then approval state is unchanged and the workflow asks one focused clarification.

### US-3: Authorize only a recorded revision

**As a** Smart Ralph workflow user
**I want to** authorize a requested revision naturally after feedback is recorded
**So that** the intended correction can be delegated without accidentally dispatching unrelated work

**Acceptance Criteria:**

- AC-3.1: Given exactly one persisted revision action has recorded revision feedback, When the user sends an unambiguous affirmative, Then the existing revision dispatch path runs and the artifact remains at its approval gate after the revision.
- AC-3.2: Given revision feedback has not been recorded, When the user sends an affirmative reply, Then no revision is dispatched, approval state is unchanged, and the workflow asks one focused clarification.
- AC-3.3: Given an approval gate is active, When the reply is a question, quotation or historical text, a revision request such as `revise this first`, unrelated, negated, mixed, or otherwise non-affirmative text, Then no approval action is inferred, approval state is unchanged, and the workflow asks one focused clarification.

### US-4: Audit and resume inferred approvals

**As a** Smart Ralph maintainer
**I want to** inspect and safely resume contextual approvals
**So that** authorization remains explainable and deterministic

**Acceptance Criteria:**

- AC-4.1: Given the resolver accepts a contextual affirmative, When it persists the resolution, Then the state audit entry contains the original reply, normalized action, and active gate or confirmation ID.
- AC-4.2: Given a workflow resumes with a persisted approval descriptor and audit history, When it processes a reply, Then it uses the persisted single action rather than conversation history to determine authorization.
- AC-4.3: Given either shared helper or schema copy changes, When the focused Bats suite runs, Then both `ralph-specum` and `ralph-specum-codex` copies remain byte-for-byte identical and the contextual approval cases pass on both surfaces.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | The system MUST add a deterministic, state-aware approval resolver that accepts an affirmative only after proving exactly one valid pending action. | Must | AC-1.1, AC-2.1, AC-3.1 |
| FR-2 | The system MUST derive pre-delegation authorization from the sole pending confirmation ID and route it through the existing canonical `confirm` and delegation checks. | Must | AC-1.1, AC-1.2 |
| FR-3 | The system MUST persist one optional artifact or revision action descriptor before accepting contextual approval outside pre-delegation; a revision descriptor MUST exist only after feedback is recorded. | Must | AC-2.1, AC-3.1, AC-3.2 |
| FR-4 | The system MUST NOT infer authorization for active interview questions, questions, quotations or historical text, revision requests, unrelated, negated, mixed, missing, stale, invalid, or multi-action contexts; it MUST leave approval state unchanged and request one focused clarification. | Must | AC-1.3, AC-2.2, AC-2.3, AC-3.2, AC-3.3 |
| FR-5 | The system MUST append an approval audit entry containing `originalReply`, `normalizedAction`, and the resolved gate or confirmation ID for every inferred approval. | Must | AC-4.1 |
| FR-6 | The system MUST keep `classify-reply` unchanged for decision frontiers and MUST retain all canonical approval phrases. | Must | AC-1.3 |
| FR-7 | The system MUST reuse the existing confirmation, manifest, delegation, and writer checks after resolution and MUST NOT create an alternate authorization path. | Must | AC-1.2, AC-3.1 |
| FR-8 | The system MUST keep the shared helper and schema copies byte-for-byte identical, use no new NLP or runtime dependency, and update applicable plugin version metadata for the release. | Must | AC-4.3 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Authorization safety | Rejection cases with byte-for-byte unchanged approval state | 100% of the cases in AC-1.3, AC-2.2, AC-2.3, AC-3.2, and AC-3.3 are covered by Bats assertions. |
| NFR-2 | Backward compatibility | Existing decision-frontier and canonical confirmation checks | `bats tests/phase-gates.bats` passes without changing the documented `classify-reply` contract. |
| NFR-3 | Shared-surface consistency | Helper and schema parity | `cmp` succeeds for both helper copies and both schema copies; Claude and Codex prompt-flow Bats tests pass. |
| NFR-4 | Dependency footprint | New production dependencies | N/A: zero; use the existing Python standard library and Bats tooling. |

## Glossary

- **Approval action**: The one persisted action that a reply may authorize, either a pending phase-interview confirmation or an explicit artifact/revision action descriptor.
- **Approval descriptor**: The persisted artifact or revision record that names one current action and supplies its stable gate ID.
- **Approval audit entry**: The persisted record of an inferred approval's original reply, normalized action, and gate or confirmation ID.
- **Contextual affirmative**: A conservative natural-language reply that clearly accepts the one active approval action.

## Out of Scope

Default-scope rule: anything not listed here that falls under the Goal is in scope.

- Free-form NLP, machine-learning intent detection, or a new dependency for reply classification.
- Inferring approval from prompt wording, prior conversation, or multiple possible actions without one persisted action descriptor.
- Changing active interview-question semantics, weakening manifest/delegation/writer validation, or redesigning unrelated workflow gates.
- Adding new approval actions beyond pre-delegation, an explicitly named artifact next action, and a revision with recorded feedback.

## Dependencies

- The existing byte-identical `plugins/ralph-specum*/scripts/phase_gate.py` helpers and `schemas/spec.schema.json` files.
- Existing Claude and Codex approval contracts, including phase prompts/skills that present or consume an approval action.
- Existing Bats suites: `tests/phase-gates.bats`, `tests/claude-phase-flow.bats`, and `tests/codex-phase-flow.bats`.
- Applicable `ralph-specum` and `ralph-specum-codex` plugin version metadata.

## Success Criteria

- `approve`, `yes`, `go ahead`, `do it`, and `looks good, continue` take the existing path only when exactly one valid pending action exists.
- All listed rejection and ambiguity cases preserve approval state and produce one focused clarification.
- Accepted resolutions persist the original reply, normalized action, and gate or confirmation ID, and a resumed workflow uses that persisted context.
- `bats tests/phase-gates.bats`, `bats tests/claude-phase-flow.bats`, and `bats tests/codex-phase-flow.bats` pass; helper and schema parity checks pass.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| A permissive parser authorizes unintended work. | High | Fail closed unless one current persisted action and an unambiguous affirmative are proven; test every rejection class. |
| Artifact prompts expose more than one continuation path. | High | Persist no inferred action until one explicit descriptor exists; ask a focused clarification otherwise. |
| Claude and Codex behavior drifts. | Medium | Keep helper/schema copies identical and test both prompt-flow surfaces. |

## Unresolved Questions

- None. The affirmative grammar is deliberately conservative; unclear text must request clarification.
