# Workflow contract

Ralph Specum produces durable Markdown artifacts in this order:

1. `research.md`
2. `requirements.md`
3. `design.md`
4. `tasks.md`
5. `progress.md`

A platform adapter may skip an artifact only when its native workflow records
the reason in `progress.md`. Approval gates still apply to every artifact that
is produced.

Task checkboxes in `tasks.md` are the authoritative implementation completion
state. `progress.md` records decisions, phase approval, evidence, blockers, and
the next action. Runtime continuation state is adapter-local and disposable.

The root coordinator is the only writer of `tasks.md`, `progress.md`, and Git
history. Delegated agents return evidence for coordinator validation and must
not update shared workflow state or create commits.
