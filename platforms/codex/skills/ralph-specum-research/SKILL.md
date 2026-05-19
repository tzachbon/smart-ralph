---
name: ralph-specum-research
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-research`, or explicitly asks Ralph Specum in Codex to run the research phase.
metadata:
  surface: helper
  action: research
---

# Ralph Specum Research

Use this for the research phase.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Respect `.claude/ralph-specum.local.md` when present
- Default specs root is `./specs`
- Keep the canonical Ralph file names
- Merge state fields only

## Action

1. Resolve the active spec. If none exists, stop and tell the user to start a spec first.
2. Read the goal, `.progress.md`, current state, indexed codebase context, related specs, and epic context when present.
3. If quick mode is not active, use bundled grill-with-docs behavior before writing `research.md`. If `$grill-with-docs` exists, use it. Otherwise inspect code and docs inline, ask native questions one at a time, and capture stable terminology when useful.
4. Write or rewrite `research.md` in the spec directory.
5. Merge state with `phase: "research"` and `awaitingApproval: true`.
6. Update `.progress.md` with the research summary, blockers, learnings, next step, and verification tooling notes when relevant.
7. If spec commits are enabled, commit only the spec artifacts.
8. In quick mode, continue directly into requirements.

## Output Shape

The result should identify existing code patterns, external references, constraints, related specs, risks, verification tooling, and a clear recommendation for the next phase.

## Response Handoff

- After writing `research.md`, name `research.md` and summarize the research briefly.
- After the walkthrough, offer `continue to requirements`, `run review agent`, `run prototype`, or `request changes`.
- If the user chooses `run prototype`, use `$prototype` when available. If unavailable, run a throwaway prototype inline, append the result to `.progress.md`, redisplay the walkthrough, and ask again.
- End with exactly one explicit choice prompt:
  - `continue to requirements`
  - `run review agent`
  - `run prototype`
  - `request changes`
- Treat `continue to requirements` as approval of `research.md`.
