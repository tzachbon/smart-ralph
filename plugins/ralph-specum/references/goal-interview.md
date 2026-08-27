# Goal Grill

> Used by: start.md

Run the `start` phase interview only after the spec directory, `.ralph-state.json`, and `.progress.md` exist and skill discovery pass 1 has completed.

## Entry

1. Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md`.
2. Reload the full selected skill manifest and required current-work resources.
3. Record the load receipt for phase `start`.
4. Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`.

Classify intent first using `intent-classification.md`. Use intent to seed relevant design-tree branches, never to set a question count or completion threshold. The critical decision frontier determines the depth.

## Goal Territory

Use these topics only as candidate design-tree nodes. Add or remove branches as evidence and answers require, and ask them only when they pass the critical decision test:

- Problem or user need behind the goal.
- Observable outcome and acceptance boundary.
- Scope choice when two viable scopes materially change the research or artifact.
- Non-negotiable compatibility, security, performance, or rollout constraints.
- Risk or tradeoff ownership that cannot be inferred from existing project contracts.
- Existing-system boundaries, reusable behavior, and viable approaches.
- A material conflict between selected skill contracts.

Inspect the repository, configuration, existing specs, related specs, and supplied source material before asking. Do not ask about spec location, naming, framework, repository layout, commands, ticket metadata, or other setup facts.

For a bug, inspect existing tests, logs, issue text, and reproduction commands first. Ask only for missing reproduction or expected-behavior decisions that block a correct research brief.

Apply domain-language modeling throughout the grill. The spec location is already resolved; do not ask for it again during the goal grill.

## Final approval and delegation

Present the goal decision brief and require `Approve and delegate`. On approval:

1. Call `confirm` for phase `start`.
2. Run `check-delegation` with the current start interview and skill receipt.
3. Delegate the research team immediately in the same response.

Pass the approved decisions and complete selected-skill manifest to every artifact-producing research agent. Append a readable mirror to `.progress.md`:

```markdown
## Interview Format
- Version: 2.0

## Intent Classification
- Type: [BUG_FIX|TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Keywords matched: [list of matched keywords]

## Interview Responses

### Goal Grill - Round 1
- Facts resolved: [fact and evidence]
- Decisions: [topic] -> [answer]
- Reproduction command: [exact command or manual steps, for BUG_FIX]
- Frontier after round: [remaining decisions or empty]

### Goal Grill - Confirmed
- Shared understanding: confirmed
- Chosen approach: [name] -- [one-line rationale]
- Spec location: [resolved directory]
```

## Pass Context to Research Team

Include the confirmed goal-grill context in each research task:

```text
Goal Grill Context:
[Include resolved facts, decisions, scope exclusions, domain language, and chosen approach from .progress.md]

Use this context to focus research. Do not reopen confirmed user decisions unless new evidence contradicts them.
```
