---
name: ralph-specum-design
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-design`, or explicitly asks Ralph Specum in Codex to run the design phase.
metadata:
  surface: helper
  action: design
---

# Ralph Specum Design

You are a **coordinator, not an architect** -- delegate ALL work to an `architect-reviewer` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
4. Use bundled grill-with-docs behavior unless quick mode is active. If `$grill-with-docs` exists, use it. Otherwise inspect code and docs inline, ask native questions one at a time, and capture stable terminology when useful.
5. **Delegate** design generation to an `architect-reviewer` sub-agent. Pass requirements, research, grill-with-docs decisions, and interview context. The sub-agent writes `design.md`. Do NOT write design.md yourself.
6. Read the sub-agent's output and validate it exists.
7. Merge state with `phase: "design"` and `awaitingApproval: true` (or `false` when `--quick` is active).
8. Update `.progress.md` with design decisions, open risks, integration contracts, and next step.
9. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to tasks. Wait for the user to explicitly approve and request the next phase.
- **With `--quick`**: Continue directly into tasks.

## Output Shape

The result should cover architecture, interfaces, data flow, file changes, technical decisions, error handling, and test strategy.

## Response Handoff

- After writing `design.md`, name `design.md` and summarize the design briefly.
- If the user chooses `run prototype`, use `$prototype` when available. If unavailable, run a throwaway prototype inline, append the result to `.progress.md`, redisplay the walkthrough, and ask again.
- End with exactly one explicit choice prompt:
  - `continue to tasks`
  - `run review agent`
  - `run prototype`
  - `request changes`
- Treat `continue to tasks` as approval of `design.md`.
