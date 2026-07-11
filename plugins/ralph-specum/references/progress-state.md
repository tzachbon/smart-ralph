# Progress State Contract

`progress.md` is the tracked, durable narrative for a spec. `tasks.md` checkboxes
are the sole source of truth for task completion. Never infer task completion
from progress prose or from adapter runtime state.

## Canonical File

- Path: `<basePath>/progress.md`
- Required frontmatter: `spec`, `phase`, `approved_through`, `updated`
- Update `phase`, `approved_through`, and `updated` whenever a phase changes or
  an approval is recorded.
- Commit `progress.md` with the related `tasks.md` update or verified logical
  batch.
- Keep `.current-spec` and `.ralph-state.json` adapter-local. They do not replace
  durable Markdown state.

## Version 5 Legacy Migration

Apply this migration only from a user-facing entry command after the target spec
has been resolved:

1. If `progress.md` exists, use it and do not read the legacy file.
2. If `progress.md` is absent and `<basePath>/.progress.md` exists, read the
   legacy file as read-only historical input.
3. Review the legacy content and rewrite only durable facts into a new canonical
   `progress.md`: original goal, current phase, approvals, decisions, verified
   learnings, verification evidence, and active blockers.
4. Do not copy the legacy file wholesale, rename it, edit it, delete it, stage
   it, or commit it. Do not copy it into worktrees.
5. Derive task completion only from `tasks.md` checkboxes. If legacy prose and
   `tasks.md` disagree, preserve `tasks.md` and record the discrepancy as a
   blocker in `progress.md`.
6. Leave the legacy file ignored and in place for rollback through version 5.

New specs always create `progress.md` directly from the canonical template and
never create a legacy file.
