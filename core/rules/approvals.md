# Approval contract

Research, requirements, design, and tasks require explicit user approval before
the next phase is treated as approved. Record the highest approved phase in the
`approved_through` field of `progress.md`.

Revising an approved artifact invalidates that artifact and all downstream
approvals. Move `approved_through` back to the last unchanged phase, record the
reason, and regenerate or review downstream artifacts before implementation.

Native quick or autonomous modes may streamline presentation, but they must not
invent approval. An adapter can proceed without another prompt only when the
user's request explicitly grants that scope.
