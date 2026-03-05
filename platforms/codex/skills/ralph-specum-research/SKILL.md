---
name: ralph-specum-research
description: This skill should be used when the user asks to run or rerun the Ralph research phase in Codex, generate `research.md`, research an active spec, or mentions "$ralph-specum-research".
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
2. Read the goal, `.progress.md`, current state, and any indexed codebase context.
3. Write or rewrite `research.md` in the spec directory.
4. Merge state with `phase: "research"` and `awaitingApproval: true`.
5. Update `.progress.md` with the research summary, blockers, learnings, and next step.
6. If spec commits are enabled, commit only the spec artifacts.
7. In quick mode, continue directly into requirements.

## Output Shape

The result should identify existing code patterns, external references, constraints, related specs, risks, and a clear recommendation for the next phase.
