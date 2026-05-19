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
2. When quick mode is off, use bundled grill-with-docs behavior before the next phase artifact
3. Stop and ask whether to continue to research
4. Research
5. Walk through the artifact, then choose continue to requirements, run review agent, run prototype, or request changes. If `$prototype` is missing, run prototype behavior inline.
6. Requirements
7. Walk through the artifact, then choose continue to design, run review agent, run prototype, or request changes
8. Design
9. Walk through the artifact, then choose continue to tasks, run review agent, run prototype, or request changes
10. Tasks
11. Walk through the artifact, then choose continue to implementation, run review agent, or request changes
12. Implement

Quick mode may generate missing artifacts and continue straight into implementation in one run only when the user explicitly asks for quick or autonomous flow.
