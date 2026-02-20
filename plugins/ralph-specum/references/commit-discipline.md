# Commit Discipline

> Used by: implement.md, spec-executor agent

## Core Rule

Each task = one commit. This is non-negotiable.

## When to Commit

- Commit AFTER the task's Verify command passes
- Never commit failing code
- Always stage and commit spec files with every task commit

## Commit Message Format

Use the EXACT commit message from the task's `Commit` field. Tasks use conventional commits:

| Prefix | When |
|--------|------|
| `feat(scope):` | New feature |
| `fix(scope):` | Bug fix |
| `refactor(scope):` | Code restructuring |
| `test(scope):` | Adding tests |
| `docs(scope):` | Documentation |
| `chore(scope):` | Maintenance, quality checkpoints |

Include task reference in commit body if helpful.

### Special Commit Messages

- Quality checkpoints: `chore(scope): pass quality checkpoint` (only if fixes were needed)
- Spec progress updates: `chore(spec): update progress for task $taskIndex`
- Parallel batch progress: `chore(spec): merge parallel progress`
- Final completion: `chore(spec): final progress update for $spec`
- Fix tasks from recovery: `fix($scope): address $errorType from task $taskId`
- Review fix tasks: `fix($scope): address review finding from task $taskId`

## What to Include in Commits

### Task Files (from the task's Files section)

The actual implementation files listed in the task.

### Spec Tracking Files (CRITICAL - always include)

```bash
# Standard (sequential) execution:
git add <basePath>/tasks.md <basePath>/.progress.md

# Parallel execution (when progressFile provided):
git add <basePath>/tasks.md <basePath>/<progressFile>
```

- `tasks.md` - task checkmarks updated
- Progress file - either `.progress.md` (default) or progressFile (parallel)

Failure to commit spec files breaks progress tracking across sessions.

### Coordinator Spec File Commits

The coordinator commits spec tracking files after each state update:
```bash
git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
git diff --cached --quiet || git commit -m "chore(spec): update progress for task $taskIndex"
```

## What NOT to Include

- `.ralph-state.json` - never committed, managed by coordinator
- Lock files (`.tasks.lock`, `.git-commit.lock`) - temporary, cleaned up after batch
- Temp progress files (`.progress-task-*.md`) - merged into main .progress.md by coordinator

## File Locking for Parallel Commits

When running in parallel mode, use flock to prevent race conditions:

```bash
# tasks.md updates (marking [x]):
(
  flock -x 200
  sed -i 's/- \[ \] X.Y/- [x] X.Y/' "<basePath>/tasks.md"
) 200>"<basePath>/.tasks.lock"

# git commit operations:
(
  flock -x 200
  git add <files>
  git commit -m "<message>"
) 200>"<basePath>/.git-commit.lock"
```

- Use locking when progressFile parameter is provided (parallel mode)
- Sequential execution (no progressFile) does not need locking

## Branch Rules

- NEVER push directly to the default branch (main/master)
- Branch management is handled at startup via `/ralph-specum:start`
- Only push to feature branches: `git push -u origin <feature-branch-name>`
- If somehow on default branch during execution, STOP and alert the user

## State File Protection

The spec-executor must NEVER modify `.ralph-state.json`:
- Commands (start, implement, etc.) set phase transitions
- Coordinator (implement command loop) increments taskIndex after verified completion
- spec-executor: READ ONLY, never write

State file is verified against tasks.md checkmarks. Shortcuts are detected via checkmark mismatch (Layer 3 of verification).
