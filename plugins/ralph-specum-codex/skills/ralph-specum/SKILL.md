---
name: ralph-specum
description: Coordinate the native Ralph Specum workflow in Codex. Use when the user invokes `$ralph-specum`, asks Ralph Specum to route or run a phase, or requests spec-driven planning or implementation.
---

# Ralph Specum

Act as the root coordinator for a native Codex specification workflow.

## Load installed resources

Resolve these paths relative to this `SKILL.md`, not the consumer repository:

- `../../references/workflow.md`
- `../../references/state-contract.md`
- `../../references/path-resolution.md`
- `../../scripts/resolve_spec_paths.py`
- `../../scripts/count_tasks.py`
- `../../templates/`

Read only the references needed for the requested action.

## Route intent

Route start, triage, research, requirements, design, tasks, implement, and status intents to the matching first-class skill. Handle legacy switch, cancel, index, refactor, feedback, and help intents through this primary surface after showing the v5 deprecation warning.

## Coordinate natively

- Use native Codex subagents. Do not require custom agent TOML files.
- Give every subagent the bounded packet and require the five result headings defined in `../../references/workflow.md`.
- Require substantive spec phases to delegate. Use semantic reasoning tiers from the workflow: medium for research and requirements, strongest for design and triage, light for task decomposition, and medium for normal implementation.
- Run at most three read-only subagents, one write subagent, and three attempts per failed task.
- Keep the root coordinator as the only writer of `tasks.md`, `progress.md`, `.current-spec`, and Git state.
- Treat `tasks.md` checkboxes as completion truth.
- Commit one verified logical batch when commits are enabled.

## Autonomous intent

Use native `/goal` only when the user explicitly requests autonomous, quick, finish, or long-running execution. Build the goal from the resolved spec, remaining tasks, constraints, verification commands, and terminal success condition. Do not set a token budget unless the user explicitly gives one.

Without explicit autonomous intent, run one phase or one verified logical implementation batch and return normally.

Do not create adapter-local continuation state, install hooks, or implement a repeated-invocation loop.
