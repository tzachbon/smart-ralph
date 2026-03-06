---
name: ralph-specum-cancel
description: This skill should be used when the user asks to cancel Ralph execution in Codex, stop a Ralph run, clear Ralph state, delete a Ralph spec, or mentions "$ralph-specum-cancel".
metadata:
  surface: helper
  action: cancel
---

# Ralph Specum Cancel

Use this to stop execution and optionally remove a spec.

## Contract

- Resolve the target by explicit path, exact name, or `.current-spec`
- Always clear execution state when the user wants to stop execution
- Confirm before deleting a spec directory
- Do not guess on ambiguous names

## Action

1. Resolve the target spec. If none exists, report that there is nothing to cancel.
2. Read `.ralph-state.json` when present and summarize the current phase and progress.
3. Safe cancel is the default. Delete `.ralph-state.json` only and keep the spec files unless the user asked for full removal.
4. If the user wants full removal, confirm first, then delete the spec directory and clear `.current-spec` when it points to that spec.
5. If the removed spec belongs to the active epic, keep epic files intact unless the user explicitly asked to remove epic planning too.
6. Report exactly what was removed.
