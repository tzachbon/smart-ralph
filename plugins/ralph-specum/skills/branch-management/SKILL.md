---
name: branch-management
description: This skill should be used when the user asks about "git branching", "create feature branch", "git worktree", "branch naming", "default branch detection", "branch workflow", or needs guidance on branch creation, worktree setup, naming conventions, and default branch handling for spec-driven development.
version: 0.1.0
---

# Branch Management

Branch workflow patterns for spec-driven development. Ensures work happens on feature branches, never on main/master.

## Check Current Branch

```bash
git branch --show-current
```

## Determine Default Branch

Check which is the default branch:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If that fails, check which exists:

```bash
git rev-parse --verify origin/main 2>/dev/null && echo "main" || echo "master"
```

## Branch Decision Logic

```text
1. Get current branch name
   |
   +-- ON DEFAULT BRANCH (main/master):
   |   |
   |   +-- Ask user for branch strategy:
   |   |   "Starting new spec work. How would you like to handle branching?"
   |   |   1. Create branch in current directory (git checkout -b)
   |   |   2. Create git worktree (separate directory)
   |   |
   |   +-- If user chooses 1 (current directory):
   |   |   - Generate branch name from spec name: feat/$specName
   |   |   - If spec name not yet known, use temp name: feat/spec-work-<timestamp>
   |   |   - Create and switch: git checkout -b <branch-name>
   |   |   - Inform user: "Created branch '<branch-name>' for this work"
   |   |
   |   +-- If user chooses 2 (worktree):
   |   |   - See Worktree Setup section below
   |   |   - STOP HERE after worktree creation (user needs to switch directories)
   |   |
   |   +-- Continue to next workflow step
   |
   +-- ON NON-DEFAULT BRANCH (feature branch):
       |
       +-- Ask user for preference:
       |   "You are currently on branch '<current-branch>'.
       |    Would you like to:
       |    1. Continue working on this branch
       |    2. Create a new branch in current directory
       |    3. Create git worktree (separate directory)"
       |
       +-- If user chooses 1 (continue):
       |   - Stay on current branch
       |   - Continue to next workflow step
       |
       +-- If user chooses 2 (new branch):
       |   - Generate branch name from spec name: feat/$specName
       |   - Create and switch: git checkout -b <branch-name>
       |
       +-- If user chooses 3 (worktree):
           - See Worktree Setup section below
           - STOP HERE after worktree creation
```

## Branch Naming Convention

When creating a new branch:
- Use format: `feat/<spec-name>` (e.g., `feat/user-auth`)
- If spec name contains special chars, sanitize to kebab-case
- If branch already exists, append `-2`, `-3`, etc.

Example:
```text
Spec name: user-auth
Branch: feat/user-auth

If feat/user-auth exists:
Branch: feat/user-auth-2
```

Sanitization rules:
- Convert to lowercase
- Replace spaces with hyphens
- Remove non-alphanumeric characters (except hyphens)
- Collapse multiple hyphens to single hyphen
- Trim leading/trailing hyphens

## Worktree Setup

Git worktrees allow working on multiple branches simultaneously in separate directories.

### When to Use Worktrees

- Long-running feature development that may need interruption
- Parallel work on multiple specs
- Preserving main branch checkout for quick fixes

### Worktree Creation

```bash
# Get repo name for path suggestion
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# If SPEC_NAME empty but .current-spec exists, read from it
if [ -z "$SPEC_NAME" ] && [ -f "./specs/.current-spec" ]; then
    SPEC_NAME=$(cat "./specs/.current-spec") || true
fi

# Default worktree path
WORKTREE_PATH="../${REPO_NAME}-${SPEC_NAME}"

# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"
```

### Copy Spec State Files to Worktree

When creating a worktree, copy state files so work can continue:

```bash
# Copy spec state files to worktree (failures are warnings, not errors)
if [ -d "./specs" ]; then
    mkdir -p "$WORKTREE_PATH/specs" || echo "Warning: Failed to create specs directory in worktree"

    # Copy .current-spec if exists (don't overwrite existing)
    if [ -f "./specs/.current-spec" ] && [ ! -f "$WORKTREE_PATH/specs/.current-spec" ]; then
        cp "./specs/.current-spec" "$WORKTREE_PATH/specs/.current-spec" || echo "Warning: Failed to copy .current-spec to worktree"
    fi

    # If spec name known, copy spec state files
    if [ -n "$SPEC_NAME" ] && [ -d "./specs/$SPEC_NAME" ]; then
        mkdir -p "$WORKTREE_PATH/specs/$SPEC_NAME" || echo "Warning: Failed to create spec directory in worktree"

        # Copy state files (don't overwrite existing)
        if [ -f "./specs/$SPEC_NAME/.ralph-state.json" ] && [ ! -f "$WORKTREE_PATH/specs/$SPEC_NAME/.ralph-state.json" ]; then
            cp "./specs/$SPEC_NAME/.ralph-state.json" "$WORKTREE_PATH/specs/$SPEC_NAME/" || echo "Warning: Failed to copy .ralph-state.json to worktree"
        fi

        if [ -f "./specs/$SPEC_NAME/.progress.md" ] && [ ! -f "$WORKTREE_PATH/specs/$SPEC_NAME/.progress.md" ]; then
            cp "./specs/$SPEC_NAME/.progress.md" "$WORKTREE_PATH/specs/$SPEC_NAME/" || echo "Warning: Failed to copy .progress.md to worktree"
        fi
    fi
fi
```

### State Files Copied

- `specs/.current-spec` - Active spec name pointer
- `specs/$SPEC_NAME/.ralph-state.json` - Loop state (phase, taskIndex, iterations)
- `specs/$SPEC_NAME/.progress.md` - Progress tracking and learnings

Copy uses non-overwrite semantics (skips if file already exists in target).

### Post-Worktree Instructions

After worktree creation, output clear guidance:

```text
Created worktree at '<path>' on branch '<branch-name>'
Spec state files copied to worktree.

For best results, cd to the worktree directory and start a new Claude Code session from there:

  cd <path>
  claude

Then run /ralph-specum:research to begin the research phase.
```

**STOP after worktree creation** - do not continue to next workflow steps. The user needs to switch directories first to work in the worktree.

### Worktree Cleanup

To clean up a worktree later:
```bash
git worktree remove <path>
```

## Quick Mode Branch Handling

In `--quick` mode, skip user prompts for non-default branches:

- If on default branch: auto-create feature branch in current directory (no worktree prompt)
- If on non-default branch: stay on current branch (no prompt, quick mode is non-interactive)

## Default Branch Protection

<mandatory>
NEVER push directly to the default branch (main/master). This is NON-NEGOTIABLE.

If you need to push changes:
1. First verify you're NOT on the default branch: `git branch --show-current`
2. If somehow on default branch, STOP and alert the user
3. Only push to feature branches: `git push -u origin <feature-branch-name>`

The only exception is if the user explicitly requests pushing to the default branch.
</mandatory>
