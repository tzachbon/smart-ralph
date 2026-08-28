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

## Prototype Evidence Push Gate

Run this gate immediately before every push, including batched task pushes, CI fixes, review fixes, first branch publication, and PR creation:

1. Resolve the exact target remote and branch. Inspect the commits the push would add to that target with `git log --format= --name-only <remote-target>..HEAD -- '**/prototypes/*.md' | sed '/^$/d' | sort -u`. For a new target branch, identify its actual remote base first; stop before pushing if the outbound range cannot be determined.
2. When the list is empty, preserve the existing non-prototype push behavior.
3. When the list contains prototype records, normal mode stops at this push boundary and requires separate explicit authorization naming every exact record path. `commitSpec`, task execution, and generic branch, PR, or push approval authorize no prototype record.
4. When the gate skips or denies the push, end the dependent remote lifecycle path. Do not run `gh pr create`, `gh pr merge`, `gh pr checks`, `gh pr view`, `gh api`, `gh run`, `gh issue`, remote review polling, issue writes, or any later remote step that depends on that push.
5. Quick mode asks no question and skips the push. Keep all commits local, continue or finish locally, and report `Remote lifecycle skipped: prototype evidence stayed local.`
6. When the gate permits and completes the push, preserve the existing normal remote lifecycle.
7. Never push an isolated `prototype/<spec>/<id>` source branch.

Re-run the inspection after any new commit and immediately before the push. The authorization covers only the named record paths in that outbound range. `commitSpec` remains local commit authorization.

## State File Protection

The spec-executor must NEVER modify `.ralph-state.json`:
- Commands (start, implement, etc.) set phase transitions
- Coordinator (implement command loop) increments taskIndex after verified completion
- spec-executor: READ ONLY, never write

State file is verified via contradiction detection and signal verification (Layers 1-2 of verification).
