---
name: ralph-specum-design
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-design`, or explicitly asks Ralph Specum in Codex to run the design phase.
metadata:
  surface: helper
  action: design
---

# Ralph Specum Design

Use this for the design phase.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
4. If quick mode is not active, use bundled grill-with-docs behavior before writing `design.md`. If `$grill-with-docs` exists, use it. Otherwise inspect code and docs inline, ask native questions one at a time, and capture stable terminology when useful.
5. Write or rewrite `design.md`.
6. Merge state with `phase: "design"` and `awaitingApproval: true`.
7. Update `.progress.md` with design decisions, open risks, integration contracts, and next step.
8. If spec commits are enabled, commit only the spec artifacts.
9. In quick mode, continue directly into tasks.

## Output Shape

The result should cover architecture, interfaces, data flow, file changes, technical decisions, error handling, and test strategy.

## Response Handoff

- After writing `design.md`, name `design.md` and summarize the design briefly.
- After the walkthrough, offer `continue to tasks`, `run review agent`, `run prototype`, or `request changes`.
- If the user chooses `run prototype`, use `$prototype` when available. If unavailable, run a throwaway prototype inline, append the result to `.progress.md`, redisplay the walkthrough, and ask again.
- End with exactly one explicit choice prompt:
  - `continue to tasks`
  - `run review agent`
  - `run prototype`
  - `request changes`
- Treat `continue to tasks` as approval of `design.md`.
