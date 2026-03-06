# Ralph Specum Workflow

## Entry Surface

| Claude surface | Codex surface |
|----------------|---------------|
| `/ralph-specum:start` | `$ralph-specum` or `$ralph-specum-start` |
| `/ralph-specum:new` | `$ralph-specum` or `$ralph-specum-start` |
| `/ralph-specum:research` | `$ralph-specum` or `$ralph-specum-research` |
| `/ralph-specum:requirements` | `$ralph-specum` or `$ralph-specum-requirements` |
| `/ralph-specum:design` | `$ralph-specum` or `$ralph-specum-design` |
| `/ralph-specum:tasks` | `$ralph-specum` or `$ralph-specum-tasks` |
| `/ralph-specum:implement` | `$ralph-specum` or `$ralph-specum-implement` |
| `/ralph-specum:status` | `$ralph-specum` or `$ralph-specum-status` |
| `/ralph-specum:switch` | `$ralph-specum` or `$ralph-specum-switch` |
| `/ralph-specum:cancel` | `$ralph-specum` or `$ralph-specum-cancel` |
| `/ralph-specum:index` | `$ralph-specum` or `$ralph-specum-index` |
| `/ralph-specum:refactor` | `$ralph-specum` or `$ralph-specum-refactor` |
| `/ralph-specum:feedback` | `$ralph-specum` or `$ralph-specum-feedback` |
| `/ralph-specum:help` | `$ralph-specum` or `$ralph-specum-help` |

## Normal Flow

1. Resolve current repo state, branch, and spec roots.
2. Start or resume a spec.
3. Wait for explicit direction to continue to research unless the user explicitly asked for quick or autonomous flow.
4. Create `research.md` and request approval, changes, or continuation to requirements.
5. Draft `requirements.md` and request approval, changes, or continuation to design.
6. Prepare `design.md` and request approval, changes, or continuation to tasks.
7. Compile `tasks.md` and request approval, changes, or continuation to implementation.
8. Implement tasks until complete or blocked.
9. Use `status`, `switch`, `cancel`, `index`, `refactor`, `feedback`, and `help` as needed.

## Start And New

- `new` is an alias within the start flow.
- Resolve the target spec by explicit path, exact name, or current spec.
- If the current branch is the default branch and the user wants isolation, offer:
  - feature branch in place
  - worktree with a feature branch
- If the user wants a worktree, stop after creating it and ask them to continue from the worktree.

## Quick Mode

Quick mode does not rely on Claude hooks. In Codex it means:

1. Create or resolve the spec.
2. Generate missing phase artifacts in order.
3. Count tasks.
4. Continue directly into implementation in the same run.
5. Persist `.ralph-state.json` after every task so a later run can resume.

Only use quick mode when the user explicitly asks Ralph to be autonomous, do it quickly, or continue without pauses.

## Implement

- Read `tasks.md`, `.progress.md`, and `.ralph-state.json`.
- Recompute task counts before execution.
- Process tasks in order.
- `[P]` tasks may be batched only when file sets do not overlap and verification is independent.
- `[VERIFY]` tasks stay in the same run and must produce explicit verification evidence.
- After each task:
  - mark checkbox
  - update state
  - update progress
  - commit using the task commit line unless task commits were explicitly disabled
- Remove `.ralph-state.json` only when all tasks are complete and verified.

## Cancel

Claude `cancel` deletes the spec directory. In Codex:

- confirm before deleting a spec directory
- allow a safer "stop but keep files" interpretation when the user asks to keep the spec
- always clear execution state when the user asks to stop execution

## Index

Index creates or updates:

- `specs/.index/index.md`
- `specs/.index/components/*.md`
- `specs/.index/external/*.md`

Use the canonical templates from `assets/templates/`.

## Refactor

Refactor updates existing spec artifacts after implementation learnings. Review files in order:

1. `requirements.md`
2. `design.md`
3. `tasks.md`

Cascade downstream updates when upstream requirements or design changes.

## Approval Prompt Shape

When a phase writes `research.md`, `requirements.md`, `design.md`, `tasks.md`, or refactored spec files outside quick mode:

- name the file or files that changed
- give a short summary
- end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to <named next step>`

Treat `continue to <named next step>` as approval of the current artifact.
