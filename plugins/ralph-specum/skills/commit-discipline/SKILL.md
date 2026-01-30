---
name: commit-discipline
description: This skill should be used when the user asks about "commit message format", "spec file commits", "commit frequency", "task commit rules", "parallel commit locking", "git commit discipline", or needs guidance on how to properly commit changes during spec task execution.
version: 0.1.0
---

# Commit Discipline

Commit discipline ensures consistent, traceable progress through spec execution. Each task produces exactly one commit with a specific format and required files.

## Core Rules

<mandatory>
ALWAYS commit spec files with every task commit. This is NON-NEGOTIABLE.
</mandatory>

| Rule | Description |
|------|-------------|
| One task = one commit | Each completed task produces exactly one commit |
| Commit AFTER verify | Only commit after the Verify command passes |
| Use EXACT message | Use the commit message from the task's Commit line |
| Never commit failing code | All checks must pass before committing |
| Include spec files | Always stage tasks.md and progress file |

## Required Spec Files

Every task commit MUST include these spec files:

```bash
# Standard (sequential) execution:
git add ./specs/<spec>/tasks.md ./specs/<spec>/.progress.md

# Parallel execution (when progressFile provided):
git add ./specs/<spec>/tasks.md ./specs/<spec>/<progressFile>
```

### Why Spec Files Matter

- `tasks.md` - Contains the `[x]` checkmark marking task complete
- `.progress.md` - Contains learnings, completed task history, context for future tasks

**Failure to commit spec files breaks progress tracking across sessions.**

The coordinator and stop-hook verify task completion by reading these files. If they're not committed, the task appears incomplete despite implementation being done.

## Commit Message Format

Use the **exact** message from the task's Commit line:

```markdown
- [ ] 1.1 Task name
  - **Commit**: `feat(component): add new feature`
```

Commit with:
```bash
git commit -m "feat(component): add new feature"
```

### Conventional Commit Prefixes

| Prefix | Use Case |
|--------|----------|
| `feat` | New functionality |
| `fix` | Bug fixes |
| `refactor` | Code changes without behavior change |
| `chore` | Maintenance, cleanup |
| `docs` | Documentation only |
| `test` | Test additions/changes |

### Optional: Task Reference in Body

For traceability, include task reference in commit body:

```bash
git commit -m "feat(auth): add login validation

Task: 1.3 from specs/user-auth/tasks.md"
```

## Commit Workflow

```
1. Task execution complete
   |
2. Run Verify command → must PASS
   |
3. Mark task [x] in tasks.md
   |
4. Update progress file with completion
   |
5. Stage ALL files:
   - Task implementation files
   - ./specs/<spec>/tasks.md
   - Progress file
   |
6. Commit with exact message from task
   |
7. Output TASK_COMPLETE
```

## Standard Commit Example

```bash
# After task 1.2 passes verification

# 1. Stage implementation files
git add src/components/Button.tsx src/styles/button.css

# 2. Stage spec files (REQUIRED)
git add ./specs/ui-components/tasks.md ./specs/ui-components/.progress.md

# 3. Commit with task message
git commit -m "feat(ui): add Button component"
```

## Parallel Execution Locking

When running in parallel mode (progressFile provided), multiple executors may commit simultaneously. Use `flock` to serialize git operations.

### Why Locking

- Multiple executors can race to update tasks.md
- Git operations are not atomic
- Without locking, commits can conflict or corrupt state

### tasks.md Updates

```bash
(
  flock -x 200
  # Read tasks.md, update checkmark, write back
  sed -i '' 's/- \[ \] X.Y/- [x] X.Y/' "./specs/<spec>/tasks.md"
) 200>"./specs/<spec>/.tasks.lock"
```

### Git Commit Operations

```bash
(
  flock -x 200
  git add <files>
  git commit -m "<message>"
) 200>"./specs/<spec>/.git-commit.lock"
```

### Flock Explanation

| Element | Purpose |
|---------|---------|
| `flock -x 200` | Exclusive lock on file descriptor 200 |
| `200>file.lock` | Connect fd 200 to lock file |
| Subshell `(...)` | Lock released when subshell exits |

### When to Use Locking

| Mode | Locking Required |
|------|------------------|
| Sequential execution (no progressFile) | No |
| Parallel execution (progressFile set) | Yes |

### Lock Files

| Lock File | Protects |
|-----------|----------|
| `.tasks.lock` | tasks.md writes |
| `.git-commit.lock` | git add/commit operations |

Lock files are cleaned up by the coordinator after batch completion.

## VERIFY Task Commits

`[VERIFY]` checkpoint tasks have special commit rules:

1. Always include spec files in commits
2. If qa-engineer made fixes, commit those files too
3. Use commit message from task, or `chore(qa): pass quality checkpoint` if fixes were needed

```bash
# After VERIFICATION_PASS with fixes
git add ./specs/<spec>/tasks.md ./specs/<spec>/.progress.md
git add src/fixed-file.ts  # if qa-engineer fixed something
git commit -m "chore(qa): pass quality checkpoint"
```

## Common Mistakes

**Mistake 1: Forgetting spec files**
```bash
# WRONG - missing spec files
git add src/feature.ts
git commit -m "feat: add feature"

# CORRECT - includes spec files
git add src/feature.ts ./specs/my-spec/tasks.md ./specs/my-spec/.progress.md
git commit -m "feat: add feature"
```

**Mistake 2: Committing before verify passes**
```
# WRONG workflow
Implement → Commit → Run Verify (fails) → Fix → Commit again

# CORRECT workflow
Implement → Run Verify (fails) → Fix → Run Verify (passes) → Commit once
```

**Mistake 3: Wrong commit message**
```bash
# Task says: Commit: `feat(auth): add login`

# WRONG
git commit -m "Added login feature"

# CORRECT
git commit -m "feat(auth): add login"
```

**Mistake 4: Committing failing code**
```
# WRONG - committing without verify
git commit -m "feat: partial implementation"  # tests fail

# CORRECT - only commit after verify passes
npm test && git commit -m "feat: complete implementation"
```

## Usage in Agents

Reference this skill for commit guidance:

```markdown
<skill-reference>
**Apply skill**: `skills/commit-discipline/SKILL.md`
Follow commit discipline rules for message format and required files.
</skill-reference>
```

## Verification

The stop-hook enforces commit discipline through:

1. **Uncommitted files check** - Rejects if spec files not committed
2. **Checkmark verification** - Validates task is marked `[x]` in tasks.md

False completion (claiming TASK_COMPLETE without proper commit) WILL be caught and retried.
