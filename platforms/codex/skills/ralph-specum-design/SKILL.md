---
name: ralph-specum-design
description: This skill should be used when the user asks to generate Ralph design docs in Codex, write `design.md`, approve requirements and move to design, or mentions "$ralph-specum-design".
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
4. Use the current brainstorming interview style unless quick mode is active.
5. Write or rewrite `design.md`.
6. Merge state with `phase: "design"` and `awaitingApproval: true`.
7. Update `.progress.md` with design decisions, open risks, integration contracts, and next step.
8. If spec commits are enabled, commit only the spec artifacts.
9. In quick mode, continue directly into tasks.

## Output Shape

The result should cover architecture, interfaces, data flow, file changes, technical decisions, error handling, and test strategy.
