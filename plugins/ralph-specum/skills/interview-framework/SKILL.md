---
name: interview-framework
description: This skill should be used when a Ralph phase must identify critical user decisions, run a layered grill, persist partial answers, obtain explicit approval, or resume an interrupted phase interview before delegating artifact work.
version: 0.3.0
user-invocable: false
---

# Interview Framework

Treat every normal-mode interview governed by this framework as a grill. Run the approval-gated interview for `start`, `triage`, `research`, `requirements`, `design`, and `tasks`. Treat this skill and its references as the single source of truth for interview behavior. Phase commands supply exploration territory and artifact context; they do not redefine the algorithm.

Quick mode bypasses interview questions only. It still requires current discovery, contract loading, bypass receipts, delegation checks, and artifact-agent load parity.

## Entry Contract

Before each new or resumed interview:

1. Complete the applicable skill discovery pass from `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md`.
2. Reload this entire `SKILL.md`, `references/algorithm.md`, `references/domain-modeling.md`, every selected skill body, and every selected skill resource required for the current work. Load `references/examples.md` only when an example is needed.
3. Record the load manifest with `phase_gate.py record-skill-load`.
4. Begin or resume the interview with the matching phase, interview ID, discovery revision, and context digest.

Block when this skill or the core algorithm reference cannot be loaded. Warn and continue when a domain skill fails to load. Put unresolved material conflicts in the first critical frontier.

## Critical Decision Test

Grill only a decision that meets both conditions:

- The answer cannot be established by inspecting the project, prior artifacts, configuration, or selected skill contracts.
- Different answers would materially change scope, observable behavior, architecture, risk acceptance, delivery sequencing, or the acceptance standard.

Inspect facts with read-only tools or an `Explore` agent. Exclude setup choices, administrative preferences, status questions, facts the repository can answer, and low-impact polish. Treat a prescribed task action in a loaded domain skill as reference material during preload; do not execute it until the phase has approval and delegation begins.

Before building the tree, read the goal, state, `.progress.md`, prior phase artifacts, the configured `.index/index.md`, and the applicable `CONTEXT.md` reached through `CONTEXT-MAP.md` when present. Open only relevant indexed entries. Inspect code, configuration, tests, and existing specs for every discoverable fact. Run independent read-only lookups in parallel; a pending fact blocks only the nodes that depend on it.

- **Fact**: discoverable from project evidence. Resolve it through inspection; never ask the user.
- **Decision**: a consequential preference, priority, boundary, or tradeoff only the user can settle. Put it on the design tree.

## Build the Design Tree and Traverse the Layered Frontier

Build a design tree from the phase territory. Each node contains a stable decision ID, dependencies, known evidence, viable options, recommendation, tradeoffs, and material consequences. Track nodes as open, investigating, resolved, or explicitly out of scope. The frontier contains every open critical decision whose prerequisites are resolved.

Ask the whole currently unblocked critical frontier. Use as many `AskUserQuestion` calls as needed, with at most four questions per call. Batch independent decisions together.

Before every `AskUserQuestion` call, call `open-frontier` for every decision ID in that batch.

After each response:

1. Call deterministic `classify-reply` on the whole reply before applying any part of it.
2. Persist every answered decision immediately with `record-answer`.
3. Preserve unanswered pending decisions when the response is partial.
4. Recompute the frontier from new answers and inspected facts.
5. Ask the next unblocked frontier until no critical node remains open.

Ask the whole current frontier in one round. Number each question (`Q1`, `Q2`, and so on). Use `AskUserQuestion` for the round when the tool is available. If `AskUserQuestion` is unavailable, render the same numbered round in the response and wait for the answers.

Turn an `Other` response into a specific dependent question in the next frontier. Never use a generic follow-up. Add branches exposed by concrete answers or contradictions, and remove branches that evidence resolves.

Each question must:

- Give 2-4 viable options.
- Put the recommended option first and label it `(Recommended)` unless the options are symmetric.
- State the recommendation rationale and the material tradeoff in the question or option description.
- Avoid straw-man alternatives and unnecessary flexibility.

Give a recommended answer with a short rationale. Provide 2-4 meaningful options. Require that the design-tree frontier is empty before final confirmation. Continue only when the user confirms the resulting shared understanding through the explicit approval choice.

See `references/algorithm.md` for the complete state machine.

## Domain Language

Apply `references/domain-modeling.md` during every grill. Challenge terms that conflict with the applicable `CONTEXT.md`, replace fuzzy or overloaded words with a proposed canonical term, and use boundary or edge-case scenarios to test the model. Record resolved domain terms promptly. Keep implementation details out of `CONTEXT.md`. This interview framework does not create ADRs; `design.md` remains the specification's technical-decision record.

## Reply Semantics

For an open decision frontier, classify the entire reply before applying it. `classify-reply` is the only parser at this point; do not use `resolve-approval` to answer active questions.

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
4. Handle the explicit choices first. A control-only reply does not approve an active question or bypass the canonical choice path.
5. Only when the reply is not a canonical choice, call `resolve-approval "$STATE" --text "$REPLY"`. Act only if it returns `accepted` for exactly one live `approve-and-delegate` action; resolver acceptance is not authorization by itself.
6. On canonical approval or accepted contextual approval, call `confirm --source approve-and-delegate`, run `check-delegation`, and delegate immediately in the same response. Do not ask another question or stop between approval and delegation.
7. On `clarification`, ask one focused approval question and do not mutate or advance the gate.

When the user requests revisions, call one `revise` transition with every affected `--decision-id` before updating answers. Recompute any dependent frontier, return to final approval using the same confirmation ID, and keep the same interview record until the brief is approved again.

## Artifact Approval

Artifact review is a separate approval gate after delegation. `apply the changes` during artifact review means revise the artifact using the supplied feedback, redisplay the walkthrough, and remain in artifact approval. It never approves the artifact or advances the phase.

Handle canonical artifact choices first. Only a view with `awaitingApproval` and exactly one current action may persist an `approvalGate`; it carries the action's stable ID, phase, kind, and action, while a revision gate also requires recorded feedback. A multi-option view persists no descriptor. Only after the canonical path may `resolve-approval` handle contextual text. On its accepted result, reuse the existing continuation or revision dispatch path; on `clarification`, leave state unchanged and ask one focused question. Clear or replace the descriptor only after that existing action succeeds. The helper owns append-only `approvalAudit` records (original reply, normalized action, gate ID); chat history is never authorization state.

## Persistence

Use `phase_gate.py` transitions after each state change. Append every completed frontier round to `.progress.md` without treating that Markdown as enforcement state:

```markdown
### <Phase> Grill - Round <N>
- Facts resolved: <fact and evidence>
- Decisions: <decision-id> -> <answer>
- Out of scope: <explicitly excluded branch or none>
- Domain language: <canonical term and definition or none>
- Frontier after round: <remaining unblocked decisions or empty>
```

For triage, store enforcement state in the epic `.epic-state.json`. For spec phases, use `.ralph-state.json`.

## References

- `references/algorithm.md` - Critical-frontier state machine and reply handling.
- `references/domain-modeling.md` - Required context discovery, language challenges, scenarios, and glossary updates.
- `references/examples.md` - Optional examples for frontier, partial-answer, skip, approval, and artifact revision cases.
