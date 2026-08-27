# Ralph Specum Project Guidance

Use Ralph Specum as the spec workflow for this repo.

## Preferred Entry Surface

- `$ralph-specum` for the general flow
- `$ralph-specum-start` to create, resume, or run in quick mode. Only exact `--quick` enables quick mode; exact `--interactive` clears it
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

1. Start or resume a spec, then grill critical goal decisions
2. Approve the phase plan and delegate research
3. Approve the artifact, request changes, or continue to requirements
4. Grill, approve, and delegate requirements
5. Approve the artifact, request changes, or continue to design
6. Grill, approve, and delegate design
7. Approve the artifact, request changes, or continue to tasks
8. Grill, approve, and delegate tasks
9. Approve the artifact, request changes, or continue to implementation
10. Implement

Exact `--quick` may generate missing artifacts and continue straight into implementation in one run. Natural-language requests and `-q` do not enable quick mode.
