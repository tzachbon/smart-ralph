# Durable state and legacy migration

`progress.md` is tracked project history. Its frontmatter must contain `spec`,
`phase`, `approved_through`, and `updated`. Its body contains durable decisions,
completion notes, learnings, blockers, verification evidence, and next actions.

`tasks.md` checkboxes are authoritative for task completion. If prose in
`progress.md` disagrees with a checkbox, the checkbox wins and the coordinator
repairs the prose during the next validated update.

For version 5 compatibility, when `progress.md` is absent and legacy
`.progress.md` exists:

1. Read the legacy file as migration input only.
2. Summarize durable goals, decisions, learnings, blockers, and evidence into a
   new `progress.md` based on the canonical template.
3. Reconcile task completion against `tasks.md`, not the legacy prose.
4. Review the summary before it becomes tracked history.
5. Never stage or commit the raw `.progress.md` log automatically.

The legacy file remains ignored and may be retained locally for rollback. New
workflow updates write only `progress.md`.
