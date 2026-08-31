---
spec: codex-phase-interview-hard-gate
phase: research
created: 2026-08-31
---

# Research: codex-phase-interview-hard-gate

## Executive Summary

Issue [#149](https://github.com/tzachbon/smart-ralph/issues/149) is feasible without a new hook, middleware layer, dependency, or change to the shared `phase_gate.py` state machine. The helper already rejects missing, partial, stale, and mismatched interviews, permits only the exact `--quick` bypass, and can clear a partial interview when the coordinator records a fresh manifest identity.

The gap is the Codex coordinator contract: the gate is described in several Markdown skills, but no runtime entrypoint automatically invokes it, and the current contract does not make the failed-check/fresh-next-invocation branch explicit at every transition. Make that one transition invariant the shared source of truth, have every affected coordinator apply it immediately before dispatch or transition, and lock it down with the existing Bats seams.

## External Research

### Best Practices

- [Issue #149](https://github.com/tzachbon/smart-ralph/issues/149) requires a fail-closed normal-mode interview gate across fresh, direct, resumed, and applicable triage paths; exact `--quick` remains the sole bypass.
- [Issue #148](https://github.com/tzachbon/smart-ralph/issues/148) is deliberately separate: it concerns interpreting approval replies after a gate is active, not whether the gate may be skipped.

### Prior Art

- `plugins/ralph-specum-codex/scripts/phase_gate.py` already owns mode normalization, interview validation, parent delegation checks, and child writer checks. Reuse it rather than introducing a second enforcement mechanism.
- The Codex and Claude `phase_gate.py` files are byte-identical. Changing the helper would expand this Codex-only fix into cross-plugin behavior.

### Pitfalls to Avoid

- Do not make `awaitingApproval` the authority; `references/state-contract.md` explicitly says it is insufficient alone.
- Do not broaden quick mode. `quick_is_authorized` accepts only `quickMode: true` plus `quickAuthorization.source == "--quick"`.
- Do not rely on the Stop hook: `hooks/stop-watcher.sh` exits unless `phase == "execution"`, so it cannot guard phase interviews.

## Codebase Analysis

### Reproducible Gate Seam

The helper was exercised against temporary copies of the current state:

| Scenario | `check-delegation` result |
|----------|---------------------------|
| Complete normal interview | allowed (`path: interview`) |
| Missing interview | `INTERVIEW_MISSING` |
| Collecting/partial interview | `INTERVIEW_INCOMPLETE` |
| Wrong interview identity | `INTERVIEW_STALE` |
| Current exact quick receipt | allowed (`path: quick`) |

For a collecting interview with the same identity, `begin-interview` currently returns `resumed: true`. Recording a manifest with a fresh `interviewId` clears that old `phaseInterview` through `record-skill-load`, then `begin-interview` starts a new `collecting` interview. This is the existing helper path needed for the selected fresh-next-invocation recovery policy.

The current red-capable contract assertion also fails for the primary coordinator and all six affected helper skills because none contains an explicit invariant equivalent to: a failed gate stops before phase-state mutation, child dispatch, or target-artifact write. `tests/codex-phase-flow.bats` is the correct permanent home for that assertion.

### Root-Cause Evidence

`phase_gate.py` itself fails closed: it validates terminal interview status and tuple provenance in `check-delegation` (lines 963-984), validates writer provenance and receipts in `check-agent-write` (987-1021), clears an incompatible quick receipt during mode normalization (639-673), and removes the prior interview when a manifest fingerprint changes (676-702).

The affected Codex paths describe these calls but leave enforcement to coordinator compliance:

| Entry point | Current path | Required hard boundary |
|-------------|--------------|------------------------|
| `$ralph-specum-start` | fresh/new/resume, then `research-analyst` | Gate before research dispatch; after a failed gate, next explicit start uses a fresh identity. |
| `$ralph-specum` | primary fallback for start, triage, research, requirements, design, tasks | Must apply the same rule when a helper skill is not selected. |
| `$ralph-specum-research` | direct research writer dispatch | Gate before `research-analyst`. |
| `$ralph-specum-requirements` | direct requirements writer dispatch | Gate before `product-manager`. |
| `$ralph-specum-design` | direct design writer dispatch | Gate before `architect-reviewer`. |
| `$ralph-specum-tasks` | direct tasks writer dispatch | Gate before `task-planner`. |
| `$ralph-specum-triage` | epic-state coordinator with multiple writers | Gate before every artifact-producing child; preserve `.epic-state.json` behavior. |

The primary fallback lists the affected routes in `skills/ralph-specum/SKILL.md:35-57`; the helper paths are in each named skill's `## Action` section. `references/workflow.md:25-46` is the shared coordinator description. The only executable hook is the Stop hook and it protects execution only, so it cannot close this gap.

### Existing Patterns

- `interview-framework-codex/references/algorithm.md` already defines the immutable identity tuple, exact quick behavior, contract reload, `check-delegation`, and `check-agent-write` order.
- Artifact agents already receive the helper, state path, identity tuple, manifest, and unique dispatch identity; they must reload receipts and pass `check-agent-write` before writing.
- `tests/phase-gates.bats` tests helper-level provenance, nonterminal rejection, exact quick behavior, resume behavior, writer receipts, triage state, and the six-phase matrix. `tests/codex-phase-flow.bats` currently verifies phrases across coordinator skills and agent templates.

### Dependencies

- No new dependency is needed.
- Bats is not installed locally; CI provisions it. Use the existing CI command shape: `bats tests/phase-gates.bats tests/codex-phase-flow.bats`.

### Constraints

- Preserve the existing state, manifest, context-digest, parent-delegation, and artifact-agent receipt checks.
- Preserve matching partial-interview resume unless the invocation has crossed the explicitly selected failed-gate recovery boundary; that boundary must record a fresh manifest identity before `begin-interview`.
- Any Codex plugin file change requires a patch version bump in `plugins/ralph-specum-codex/.codex-plugin/plugin.json`; the separate Claude marketplace entry remains unchanged.

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| `goal-interview` | High | Earlier phase-interview design and terminology. | Review only; update if its recovery semantics conflict. |
| `adopt-grill-me-interview` | Medium | Its requirements note that a minimum interview floor was advisory, which is adjacent to this hard-gate requirement. | Review terminology only. |
| `requirements-process-improvements` | Low | Documents quick-mode defaults and phase artifacts. | No expected change. |

### Coordination Notes

No related spec is recorded in the current state. Keep #149 scoped to Codex phase-entry and writer enforcement; do not combine it with #148's contextual approval parsing.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Existing helper supports the required fail-closed checks and fresh-identity reset. |
| Effort Estimate | S | Shared contract wording, targeted coordinator references, Bats coverage, and required version metadata. |
| Risk Level | Medium | A vague recovery rule could break legitimate partial-interview resume or accidentally widen quick mode. |

## Recommendations for Requirements

1. Add one shared hard-transition rule to the Codex interview framework: before each affected coordinator transition or child dispatch, run the current `check-delegation`; before every artifact write, run the current `check-agent-write`; on any nonzero result, stop without mutating phase state, dispatching, or writing the target artifact.
2. Define recovery precisely: a failed missing/stale/partial/mismatched normal-mode gate does not continue in that invocation. On the next explicit affected-phase invocation, issue a fresh `interviewId`, record a fresh manifest (which clears the prior interview through existing `record-skill-load` behavior), then begin a new interview. Exact quick follows the existing bypass receipt path and still runs discovery, manifest, delegation, and writer checks.
3. Extend `tests/codex-phase-flow.bats` with the transition invariant for the primary fallback plus start, triage, research, requirements, design, and tasks. Extend `tests/phase-gates.bats` with the fresh-identity recovery case, while retaining current tests for direct, resumed, stale, and exact-quick helper behavior. Run both Bats files in CI.

## Open Questions

- None blocking: the user selected the existing helper as the enforcement boundary and the fresh-next-explicit-invocation recovery policy.
- During implementation, decide the shortest non-duplicated placement for the shared rule, then make the entrypoint matrix test prove every coordinator loads it.

## Sources

- https://github.com/tzachbon/smart-ralph/issues/149 — issue statement and acceptance criteria.
- https://github.com/tzachbon/smart-ralph/issues/148 — separate approval-language issue.
- `plugins/ralph-specum-codex/scripts/phase_gate.py:489-558,639-702,761-793,963-1021` — exact quick, invalidation, interview start, delegation, and writer checks.
- `plugins/ralph-specum-codex/skills/interview-framework-codex/SKILL.md` and `references/algorithm.md` — shared contract and agent gate sequence.
- `plugins/ralph-specum-codex/skills/ralph-specum*/SKILL.md` and `plugins/ralph-specum-codex/references/workflow.md` — coordinator entrypoints.
- `plugins/ralph-specum-codex/hooks/stop-watcher.sh:57-64` — execution-only Stop hook boundary.
- `tests/phase-gates.bats` and `tests/codex-phase-flow.bats` — existing regression seams.
