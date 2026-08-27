---
name: interview-framework
description: This skill should be used when running any normal-mode interview before a spec phase, grilling the user to reach shared understanding, gathering requirements through dialogue, or resolving design decisions before delegating to a Ralph subagent. Covers fact-first discovery, design-tree frontier rounds, recommendations, domain language, and confirmation.
version: 0.3.0
user-invocable: false
---

# Interview Framework

Treat every normal-mode interview governed by this framework as a grill. Reach shared understanding before delegating research, requirements, design, or task planning.

Quick mode skips the interview. Do not weaken normal-mode grilling to imitate quick mode.

## Completion Contract

Do not proceed because the conversation feels sufficient or a question count has been reached. Proceed only when:

1. All discoverable facts required by the design tree have been resolved.
2. The design-tree frontier is empty.
3. Every branch is resolved or the user has explicitly placed it out of scope.
4. The user confirms the resulting shared understanding.

## Preflight: Find Facts Before Questions

Read the available project context before building the design tree:

1. Read the original goal, `.progress.md`, `.ralph-state.json`, and prior phase artifacts.
2. Resolve the default specs directory with `ralph_get_default_dir()` when available, otherwise use `./specs`. Read `<default-specs-dir>/.index/index.md` when it exists, then open only relevant indexed entries and related specs.
3. Read `CONTEXT-MAP.md` when it exists and follow it to the applicable `CONTEXT.md`. Otherwise read the root `CONTEXT.md` when present.
4. Inspect code, configuration, tests, and existing specs for any fact needed by the interview.

Classify every unknown:

- **Fact**: discoverable from the repository, tools, documentation, or existing artifacts. Resolve it with Explore or another read-only subagent. Never ask the user.
- **Decision**: a preference, priority, trade-off, boundary, or constraint that only the user can settle. Put it on the design tree.

Run independent fact lookups in parallel. A pending lookup blocks only the decisions that depend on it; ask the rest of the current frontier.

## Build the Design Tree

Map every decision as a node. Add dependency edges from foundational decisions to the decisions that require them.

Track each node as one of:

- `OPEN`: ready once its prerequisites resolve
- `INVESTIGATING`: waiting on a fact lookup
- `RESOLVED`: answered by evidence, the user, or a justified inference
- `OUT_OF_SCOPE`: explicitly excluded by the user

Define the **frontier** as every open decision whose prerequisites are resolved. Do not ask a decision that depends on another decision still open in the same round.

Use the calling command's exploration territory as a starting point, then add branches exposed by project context, prior answers, concrete scenarios, and code contradictions. Do not use fixed question counts or a canned questionnaire.

## Grill in Frontier Rounds

Ask the whole current frontier in one round:

1. Number each question (`Q1`, `Q2`, and so on).
2. Ground it in known facts and prior answers.
3. Give a recommended answer with a short rationale.
4. Provide 2-4 meaningful options, with the recommendation first and `Other` last.
5. Omit the recommendation label only when the options are symmetric.

Use `AskUserQuestion` for the round when the tool is available. Put the whole frontier in one call when it fits. If the frontier exceeds the tool limit, use multiple calls for that same round and wait for every frontier answer. If `AskUserQuestion` is unavailable, render the same numbered round in the response and wait for the user's answers. Advance the tree only after the user answers the round.

Format each question as:

```text
Q1 - <short title>: <context-aware decision question>

Recommendation: <recommended answer and rationale>
```

After the user answers the round:

1. Mark answered nodes resolved.
2. Record any justified inferences.
3. Add branches exposed by the answers.
4. Turn an `Other` response into a specific dependent question for the next frontier. Never ask a generic follow-up.
5. Recompute the frontier and start the next round.

Treat `done`, `skip`, or similar language as a request to narrow scope, not as an automatic exit. Show the remaining branches and require explicit confirmation before marking them out of scope.

## Model Domain Language During the Grill

Apply `references/domain-modeling.md` throughout the rounds.

- Challenge terms that conflict with `CONTEXT.md`.
- Replace fuzzy or overloaded words with a proposed canonical term.
- Use concrete boundary and edge-case scenarios to test the model.
- Check claims about current behavior against code.
- Update the applicable `CONTEXT.md` as soon as a domain term is resolved. Do not batch glossary work until the end.

Keep implementation details and technical decisions out of `CONTEXT.md`. This interview framework does not create ADRs; `design.md` remains the specification's technical-decision record.

## Store Progress After Every Round

Append each completed round to `.progress.md` under `## Interview Responses`. Record facts, decisions, explicit scope exclusions, and any glossary updates. Preserve earlier rounds.

```markdown
### <Phase> Grill - Round <N>
- Facts resolved: <fact and evidence>
- Decisions: <topic> -> <answer>
- Out of scope: <explicitly excluded branch, if any>
- Domain language: <canonical term and definition, if any>
- Frontier after round: <remaining unblocked decisions or empty>
```

Do not store a parallel interview mode or question counter in `.ralph-state.json`.

## Confirm Shared Understanding

When the frontier becomes empty, present a compact summary of settled decisions, scope boundaries, and the chosen approach. Ask the user to confirm it.

If the user corrects or extends the summary, reopen the affected branch and continue grilling. Delegate to the phase agent only after confirmation.

## References

- **`references/algorithm.md`** - Full fact-first design-tree and frontier-round algorithm
- **`references/domain-modeling.md`** - `CONTEXT.md` discovery, language challenges, scenarios, and inline glossary updates
- **`references/examples.md`** - Frontier-round and progress-storage examples
