# Goal Interview

> Used by: start.md

Run the `start` phase interview only after the spec directory, `.ralph-state.json`, and `.progress.md` exist and skill discovery pass 1 has completed.

## Entry

1. Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md`.
2. Reload the full selected skill manifest and required current-work resources.
3. Record the load receipt for phase `start`.
4. Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`.

Do not use intent-based question counts. The critical decision frontier determines the depth.

## Goal Territory

Use these topics only as candidate design-tree nodes. Ask them only when they pass the critical decision test:

- Observable outcome and acceptance boundary.
- Scope choice when two viable scopes materially change the research or artifact.
- Non-negotiable compatibility, security, performance, or rollout constraints.
- Risk or tradeoff ownership that cannot be inferred from existing project contracts.
- A material conflict between selected skill contracts.

Inspect the repository, configuration, existing specs, related specs, and supplied source material before asking. Do not ask about spec location, naming, framework, repository layout, commands, ticket metadata, or other setup facts.

For a bug, inspect existing tests, logs, issue text, and reproduction commands first. Ask only for missing reproduction or expected-behavior decisions that block a correct research brief.

## Final approval and delegation

Present the goal decision brief and require `Approve and delegate`. On approval:

1. Call `confirm` for phase `start`.
2. Run `check-delegation` with the current start interview and skill receipt.
3. Delegate the research team immediately in the same response.

Pass the approved decisions and complete selected-skill manifest to every artifact-producing research agent. Append a readable mirror to `.progress.md`:

```markdown
### Goal Interview
- <decision-id>: <answer>
- Defaults and assumptions: <text or none>
- Approved approach: <summary>
```
