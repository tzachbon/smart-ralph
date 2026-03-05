# Ralph Specum Project Guidance

Use Ralph Specum as the spec workflow for this repo.

## Preferred Entry Surface

- `$ralph-specum` for the general flow
- `$ralph-specum-start` to create, resume, switch, or run quick mode
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
2. Research
3. Requirements
4. Design
5. Tasks
6. Implement

Quick mode may generate missing artifacts and continue straight into implementation in one run.
