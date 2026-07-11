# Ralph Specum Project Guidance

Use Ralph Specum's native Codex skills for specification work.

## Entry points

- `$ralph-specum` for routing and the full workflow
- `$ralph-specum-start` to create or resume a spec
- `$ralph-specum-triage` for a dependency-heavy effort
- `$ralph-specum-research`, `$ralph-specum-requirements`, `$ralph-specum-design`, and `$ralph-specum-tasks` for explicit phase control
- `$ralph-specum-implement` for an approved implementation batch
- `$ralph-specum-status` for artifact, task, and native goal status

## Project contract

- Specs live in `./specs` unless `.codex/ralph-specum.local.md` defines `specs_dirs`.
- `.current-spec` is a local selector in the default root.
- `progress.md` is tracked durable context.
- `tasks.md` checkboxes are implementation truth.
- Do not create adapter-local continuation state or hooks.

## Orchestration

- The root coordinator alone updates shared spec state and Git.
- Native subagents receive bounded work packets and never commit.
- Use at most three concurrent read-only subagents and one write subagent.
- Commit one verified logical batch.
- Without explicit autonomous intent, implementation completes one batch and returns.
- With explicit autonomous, quick, finish, or long-running intent, use native `/goal` without a token budget unless the user supplied one.
