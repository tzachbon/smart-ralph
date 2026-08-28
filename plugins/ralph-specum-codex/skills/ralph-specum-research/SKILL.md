---
name: ralph-specum-research
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-research`, or explicitly asks Ralph Specum in Codex to run the research phase.
metadata:
  surface: helper
  action: research
---

# Ralph Specum Research

You are a **coordinator, not a researcher** -- delegate ALL work to a `research-analyst` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Respect `.claude/ralph-specum.local.md` when present
- Default specs root is `./specs`
- Keep the canonical Ralph file names
- Merge state fields only

## Action

1. Resolve the active spec. If none exists, stop and tell the user to start a spec first.
2. Read the goal, `.progress.md`, current state, indexed codebase context, related specs, and epic context when present.
3. Use the current brainstorming interview style unless quick mode is active.
4. **Delegate** research generation to a `research-analyst` sub-agent. Pass the goal, existing context, and interview results. The sub-agent writes `research.md` in the spec directory. Do NOT write research.md yourself.
5. Read the sub-agent's output and validate it exists.
6. Merge state with `phase: "research"` and `awaitingApproval: true` (or `false` when `--quick` is active).
7. Update `.progress.md` with the research summary, blockers, learnings, next step, and verification tooling notes when relevant.
8. If spec commits are enabled, commit only the spec artifacts.
9. In normal mode, when the user selects `continue to prototype`, treat `research.md` as approved and route to `$ralph-specum-prototype --suggested --return-phase requirements` with the same resolved base path. Let that skill own prototype behavior and its return handoff.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and choice prompt. Do NOT continue until the user selects the requirements or prototype route.
- **With `--quick`**: Continue directly into requirements. Do not request a prototype from research; quick mode has one post-requirements request only.

## Output Shape

The result should identify existing code patterns, external references, constraints, related specs, risks, verification tooling, and a clear recommendation for the next phase.

## Response Handoff

- After writing `research.md`, name `research.md` and summarize the research briefly.
- End with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to requirements`
  - `continue to prototype`
- Treat `continue to requirements` as approval of `research.md`.
- Treat `continue to prototype` as approval of `research.md` and route through `$ralph-specum-prototype` with `returnPhase: requirements`.
