---
spec: contextual-approval-replies
phase: research
created: 2026-08-31
---

# Research: contextual-approval-replies

## Executive Summary

Issue #148 is feasible with a small shared extension: both plugin copies have byte-identical `phase_gate.py` helpers and schemas, and the existing helper already makes the pre-delegation confirmation ID authoritative. Today it intentionally classifies `yes`, `go ahead`, and similar replies as control-only everywhere; contextual approval should therefore be a separate, state-aware resolver rather than a broader global phrase list.

Artifact approval needs one new persisted active-gate descriptor because `awaitingApproval` is only a boolean and does not identify one next action. Keep `confirm`, manifest validation, `check-delegation`, and `check-agent-write` unchanged after the resolver chooses a valid action.

## External Research

### Best Practices

- [Issue #148](https://github.com/tzachbon/smart-ralph/issues/148) is the primary behavior contract: accept an unambiguous affirmative only when exactly one explicit pending action exists; ask for clarification without mutating state otherwise.
- The issue requires an audit record containing the original reply, normalized action, and active gate or confirmation ID. It explicitly excludes questions, revision requests, unrelated messages, quoted text, and historical text from inferred approval.
- No new NLP dependency is warranted. The requested safety boundary is better served by a conservative deterministic resolver that first proves the active state permits exactly one action.

### Prior Art

- The current shared classifier deliberately treats fixed affirmative/control phrases as `control_only` ([helper](https://github.com/tzachbon/smart-ralph/blob/main/plugins/ralph-specum/scripts/phase_gate.py#L30-L49), [classifier](https://github.com/tzachbon/smart-ralph/blob/main/plugins/ralph-specum/scripts/phase_gate.py#L801-L815)). Preserve that behavior for an active interview frontier.
- `confirm` already rejects a non-pending confirmation ID and noncanonical source before transitioning the interview, so a resolver can normalize a valid contextual reply to the existing canonical path instead of weakening validation ([confirmation transition](https://github.com/tzachbon/smart-ralph/blob/main/plugins/ralph-specum/scripts/phase_gate.py#L866-L901)).

### Pitfalls to Avoid

- Do not turn `yes` or `go ahead` into globally substantive text; that would change active-question semantics and could record an answer where none was given.
- Do not let prompts independently decide intent. Both surfaces repeat gate language, so prompt-only changes will drift and cannot provide durable audit or resume behavior.
- Do not infer an artifact next step when the prompt still offers more than one action, such as continuing to the next phase, opening a prototype, or running review.

## Codebase Analysis

### Existing Patterns

| Area | Finding | Implication |
|---|---|---|
| Shared helper | `plugins/ralph-specum/scripts/phase_gate.py` and `plugins/ralph-specum-codex/scripts/phase_gate.py` are byte-identical. | Implement once, then copy identically; `tests/phase-gates.bats` enforces parity. |
| Interview confirmation | `phaseInterview.status == "awaiting_confirmation"` requires exactly one pending decision ID, and `confirm` requires that ID plus `approve-and-delegate`. | The pre-delegation resolver can use the pending confirmation ID as its authoritative active gate. |
| Artifact approval | Both state schemas expose `awaitingApproval`, but no action ID, target phase, revision-feedback flag, or reply audit field. | A boolean alone cannot safely decide what an affirmative reply authorizes or support resume. |
| Prompt contracts | Claude centralizes gates in `references/normal-mode-gates.md`; Codex centralizes them in `references/workflow.md` and `references/state-contract.md`. Individual phase commands/skills restate artifact behavior. | Put semantics in the shared resolver and shared contracts, then remove or align only conflicting local statements. |
| Revision flow | Both surfaces say `apply the changes` delegates only already-recorded feedback, otherwise asks one focused question. No state field currently records that feedback as pending. | Persist a revision action only after feedback has been recorded; an affirmative before that must not dispatch a revision. |

### Recommended Minimal State Model

Use optional, additive state fields so legacy state remains valid and explicit existing choices still work:

```json
{
  "approvalGate": {
    "id": "artifact:research:continue-to-requirements",
    "kind": "artifact",
    "action": "continue-to-requirements"
  },
  "approvalAudit": [
    {
      "originalReply": "looks good, continue",
      "normalizedAction": "continue-to-requirements",
      "gateId": "artifact:research:continue-to-requirements"
    }
  ]
}
```

For pre-delegation, the resolver can derive the gate from the one pending `phaseInterview` confirmation ID. For artifact advancement and revision dispatch, the coordinator must first persist exactly one `approvalGate`; without one, the resolver returns an unresolved/ambiguous result and the coordinator asks a focused question. Clear or replace the active gate atomically only after the selected action succeeds.

### Dependencies

- Python standard library only; the existing helper already uses `argparse`, JSON, locking, and atomic state writes.
- Existing Bats tests and `jq` fixtures cover both helper copies and schema parity.
- No new package or service is required.

### Constraints

- `classify-reply` must retain its existing `bare_skip` / `control_only` / `substantive` contract for open interview decisions.
- The resolver must inspect current persisted state, not conversation history, before accepting text. It must reject questions, quoted/historical references, concrete revision requests, and mixed/unclear replies.
- Multi-action contexts must leave approval state unchanged and prompt for one clarification.
- `phase_gate.py` validates manifest provenance and controls atomic state writes; do not move those checks into prompt instructions or bypass them after resolution.
- The schema and helper copies are byte-identical today, and the test suite requires them to remain so.

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|---|---|---|---|
| `adaptive-interview` | Medium | Earlier work on contextual, resumable interview behavior. | No |
| `goal-interview` | High | Established coordinator-side interviews and pre-delegation approval before artifact agents. | No |
| `adopt-grill-me-interview` | High | Established the shared interview-framework/algorithm as the source of truth. | No |
| `optional-prototype-phase` | Medium | Explains why artifact prompts can have multiple continuation actions and therefore cannot infer by default. | No |

### Coordination Notes

This change should preserve the separation established by the prior interview specs: coordinator resolves intent, `phase_gate.py` validates and persists it, and artifact agents remain gated writers. No prior spec artifact requires revision; their patterns identify the shared files and test locations to reuse.

## Quality Commands

| Scope | Command |
|---|---|
| Focused resolver/state tests | `bats tests/phase-gates.bats` |
| Claude prompt-flow checks | `bats tests/claude-phase-flow.bats` |
| Codex prompt-flow checks | `bats tests/codex-phase-flow.bats` |
| Full CI-equivalent Bats suite | `bats tests/*.bats` |
| Parity smoke check | `cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py` |

The CI workflow runs `bats tests/*.bats`. Any plugin-source change requires a version increase: Claude `ralph-specum` must keep `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` aligned; Codex must increase `plugins/ralph-specum-codex/.codex-plugin/plugin.json`. All currently show `4.12.0`.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|---|---|---|
| Technical Viability | High | Existing confirmation and write/delegation checks are reusable. |
| Effort Estimate | M | Shared helper/schema/test changes plus focused contract alignment on two plugin surfaces. |
| Risk Level | Medium | Incorrect classification could authorize work; fail closed on absent, stale, or multi-action state. |

## Recommendations for Requirements

1. Add one shared `phase_gate.py` resolver command that reads state and the original reply, recognizes only a conservative unambiguous affirmative for one active gate, records the audit entry, and returns a normalized action. Keep `classify-reply` unchanged for open decision frontiers.
2. Make the active action explicit in state for artifact advancement and recorded-feedback revision dispatch. An affirmative with no active descriptor, no recorded feedback, or more than one possible action must not mutate state.
3. Route a resolved pre-delegation approval through the existing `confirm --source approve-and-delegate`, then the existing delegation check; route a resolved revision through the existing fresh gated writer flow. Do not create an alternate authorization path.
4. Update the shared Claude and Codex approval contracts first, then align only phase-specific wording that still says affirmative controls never approve. Keep the canonical choices supported.
5. Add Bats coverage for accepted paraphrases, rejection/quoted/question cases, multiple actions, audit fields, duplicate helper/schema parity, and a reload/resume case that proves the persisted gate remains authoritative.

## Open Questions

- Define the conservative affirmative grammar for equivalent text beyond the issue examples. Recommendation: accept only clear, present-tense acceptance/action statements after state proves one action; prefer a clarification when a reply contains a question, quotation, negation, revision instruction, or unrelated clause.
- For artifact views offering optional prototype or review routes, decide whether the coordinator persists a single default continuation action before accepting free text or presents a clarification. The issue's one-action rule favors clarification until one action is active.

## Sources

### External

- [GitHub issue #148](https://github.com/tzachbon/smart-ralph/issues/148) - requested behavior, safety boundary, and acceptance criteria.
- [Current shared classifier](https://github.com/tzachbon/smart-ralph/blob/main/plugins/ralph-specum/scripts/phase_gate.py#L801-L815) - current global control-only behavior.
- [Current phase-gate tests](https://github.com/tzachbon/smart-ralph/blob/main/tests/phase-gates.bats#L589-L617) - existing expected control-only semantics.
- [Codex approval contract](https://github.com/tzachbon/smart-ralph/blob/main/plugins/ralph-specum-codex/references/workflow.md#L168-L187) - separate pre-delegation and artifact gates.

### Codebase

- `plugins/ralph-specum/scripts/phase_gate.py` and `plugins/ralph-specum-codex/scripts/phase_gate.py` - identical deterministic gate implementation.
- `plugins/ralph-specum/schemas/spec.schema.json` and `plugins/ralph-specum-codex/schemas/spec.schema.json` - identical current state schema without reply-audit fields.
- `plugins/ralph-specum/references/normal-mode-gates.md` - Claude shared gate prompt contract.
- `plugins/ralph-specum-codex/references/workflow.md` and `plugins/ralph-specum-codex/references/state-contract.md` - Codex shared workflow and state contract.
- `tests/phase-gates.bats`, `tests/claude-phase-flow.bats`, `tests/codex-phase-flow.bats`, and `.github/workflows/bats-tests.yml` - existing verification conventions.
