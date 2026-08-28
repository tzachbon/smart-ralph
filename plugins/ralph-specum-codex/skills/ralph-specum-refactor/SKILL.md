---
name: ralph-specum-refactor
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-refactor`, or explicitly asks Ralph Specum in Codex to revise spec artifacts after implementation learnings.
metadata:
  surface: helper
  action: refactor
---

# Ralph Specum Refactor

You are a **coordinator, not a refactor specialist** -- delegate spec revision to a `refactor-specialist` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Review files in order: `requirements.md`, `design.md`, `tasks.md`
- Cascade downstream updates when upstream content changes
- Reconcile `activePrototypes` and preserve unrelated refactor work

## Action

1. Resolve the target spec.
2. Read `.progress.md` and existing spec files.
3. Run `prototype_records.py reconcile` whenever `.ralph-state.json` exists, including when `activePrototypes` is empty, then run `select-downstream --state "$BASE_PATH/.ralph-state.json" --target "$FILE" --path "$FILE"` with the resolved `basePath`. Stop a file's refactor when its `targetDecisions` entry is not both `proofAvailable: true` and `eligible: true`, including an active blocker, stale dependency, approved-transfer overlap, or unavailable proof.
4. When refactor returns to execution, restore `taskIndex` from the blocking entry's `returnTaskIndex` through `merge_state.py` before dispatch.
5. **Delegate** spec revision to a `refactor-specialist` sub-agent. Pass `.progress.md`, existing spec files, and implementation learnings. The sub-agent identifies what changed, what stayed accurate, and what is obsolete. Do NOT revise spec files yourself.
6. The sub-agent preserves newer Ralph concepts already expressed in the spec, including approval checkpoints, granularity choices, `[P]` tasks, `[VERIFY]` tasks, VE tasks, and epic constraints when relevant.
7. The sub-agent updates files in order:
   - `requirements.md`
   - `design.md`
   - `tasks.md`
8. If requirements changed, revisit design and tasks.
9. If design changed, revisit tasks.
10. Record the rationale and cascade decisions in `.progress.md`.

## Response Handoff

- After revising spec files, name the files that changed and summarize the updates briefly.
- End with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to implementation`
- Treat `continue to implementation` as approval of the updated spec files.
