# Ralph Specum Project Guidance

Use Ralph Specum as the spec workflow for this repo.

## Preferred Entry Surface

- `$ralph-specum` for the general flow
- `$ralph-specum-start` to create, resume, or run in quick mode, then stop unless quick or autonomous flow was explicit
- `$ralph-specum-research`
- `$ralph-specum-requirements`
- `$ralph-specum-design`
- `$ralph-specum-tasks`
- `$ralph-specum-implement`
- `$ralph-specum-status`

## Project Contract

- Specs live in `./specs` unless `.claude/ralph-specum.local.md` defines `specs_dirs`
- `.current-spec` lives in the default specs root
- `.ralph-state.json` is transient execution state
- `.progress.md` persists learnings and blockers

## Flow

1. Start or resume a spec
2. Stop and ask whether to continue to research
3. Research
4. Approve the artifact, request changes, or continue to requirements
5. Requirements
6. Approve the artifact, request changes, or continue to design
7. Design
8. Approve the artifact, request changes, or continue to tasks
9. Tasks
10. Approve the artifact, request changes, or continue to implementation
11. Implement

Quick mode may generate missing artifacts and continue straight into implementation in one run only when the user explicitly asks for quick or autonomous flow.
