---
name: interview-framework
description: This skill should be used when a Ralph phase must identify critical user decisions, run a layered grill, persist partial answers, obtain explicit approval, or resume an interrupted phase interview before delegating artifact work.
version: 0.3.0
user-invocable: false
---

# Interview Framework

Run the approval-gated interview for `start`, `triage`, `research`, `requirements`, `design`, and `tasks`. Treat this skill and its references as the single source of truth for interview behavior. Phase commands supply exploration territory and artifact context; they do not redefine the algorithm.

## Entry Contract

Before each new or resumed interview:

1. Complete the applicable skill discovery pass from `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md`.
2. Reload this entire `SKILL.md`, `references/algorithm.md`, every selected skill body, and every selected skill resource required for the current work. Load `references/examples.md` only when an example is needed.
3. Record the load manifest with `phase_gate.py record-skill-load`.
4. Begin or resume the interview with the matching phase, interview ID, discovery revision, and context digest.

Block when this skill or the core algorithm reference cannot be loaded. Warn and continue when a domain skill fails to load. Put unresolved material conflicts in the first critical frontier.

## Critical Decision Test

Grill only a decision that meets both conditions:

- The answer cannot be established by inspecting the project, prior artifacts, configuration, or selected skill contracts.
- Different answers would materially change scope, observable behavior, architecture, risk acceptance, delivery sequencing, or the acceptance standard.

Inspect facts with read-only tools or an `Explore` agent. Exclude setup choices, administrative preferences, status questions, facts the repository can answer, and low-impact polish. Treat a prescribed task action in a loaded domain skill as reference material during preload; do not execute it until the phase has approval and delegation begins.

## Layered Frontier

Build a design tree from the phase territory. Each node contains a stable decision ID, dependencies, known evidence, viable options, recommendation, tradeoffs, and material consequences.

Ask the whole currently unblocked critical frontier. Use as many `AskUserQuestion` calls as needed, with at most four questions per call. Do not serialize independent questions one at a time. After each response:

1. Call `open-frontier` for every decision ID before the `AskUserQuestion` call.
2. Call deterministic `classify-reply` on the whole reply before applying any part of it.
3. Persist every answered decision immediately with `record-answer`.
4. Preserve unanswered pending decisions when the response is partial.
5. Recompute the frontier from new answers and inspected facts.
6. Ask the next unblocked frontier until no critical node remains open.

Each question must:

- Give 2-4 viable options.
- Put the recommended option first and label it `(Recommended)` unless the options are symmetric.
- State the recommendation rationale and the material tradeoff in the question or option description.
- Avoid straw-man alternatives and unnecessary flexibility.

See `references/algorithm.md` for the complete state machine.

## Reply Semantics

Classify the entire reply before applying it.

### Substantive reply

Apply text that answers one or more active decisions. Persist answered decisions and keep the rest open. A substantive answer can include control words without losing its decision content.

### Control-only reply

These replies do not answer any active decision by themselves:

- `apply the changes`
- `continue`
- `proceed`
- `go ahead`

Keep the active frontier open and ask it again. Do not infer defaults or approval from a control-only reply.

### Bare skip

Treat bare `skip`, after an active question, as authorization to default the remaining phase interview. Call `skip` with explicit defaults and assumptions; this moves to `awaiting_confirmation`, not a delegable terminal state. Continue to final approval and confirm decision ID `skip-confirmation`. A sentence that contains `skip` plus substantive decision text is a substantive reply, not bare skip.

## Final Approval

When the critical frontier is exhausted or skipped:

1. Present the decision brief: resolved decisions, recommended approach, tradeoffs, defaults, assumptions, and material conflicts.
2. Call `await-confirmation` with a stable confirmation decision ID and the proposed approach.
3. Ask one explicit approval question through `AskUserQuestion`:
   - `Approve and delegate (Recommended)`
   - `Revise decisions`
   - `Cancel`
4. Accept only an explicit approval selection. Control-only replies do not approve.
5. On approval, call `confirm --source approve-and-delegate`, run `check-delegation`, and delegate immediately in the same response. Do not ask another question or stop between approval and delegation.

When the user requests revisions, call one `revise` transition with every affected `--decision-id` before updating answers. Recompute any dependent frontier, return to final approval using the same confirmation ID, and keep the same interview record until the brief is approved again.

## Artifact Approval

Artifact review is a separate approval gate after delegation. `apply the changes` during artifact review means revise the artifact using the supplied feedback, redisplay the walkthrough, and remain in artifact approval. It never approves the artifact or advances the phase.

## Persistence

Use `phase_gate.py` transitions after each state change. Append a readable mirror to `.progress.md` without treating that Markdown as enforcement state:

```markdown
### <Phase> Interview
- <decision-id>: <answer>
- Defaults and assumptions: <text or none>
- Approved approach: <summary>
```

For triage, store enforcement state in the epic `.epic-state.json`. For spec phases, use `.ralph-state.json`.

## References

- `references/algorithm.md` - Critical-frontier state machine and reply handling.
- `references/examples.md` - Optional examples for frontier, partial-answer, skip, approval, and artifact revision cases.
