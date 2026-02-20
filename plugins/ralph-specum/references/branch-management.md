# Branch Management

> Used by: start.md, implement.md

This reference contains branch and worktree management logic executed as the first step of the start command, before any spec files are created.

## Step 1: Check Current Branch

```bash
git branch --show-current
```

## Step 2: Determine Default Branch

Check which is the default branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If that fails, assume `main` or `master` (check which exists):
```bash
git rev-parse --verify origin/main 2>/dev/null && echo "main" || echo "master"
```

## Step 3: Branch Decision Logic

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
   |   |   - Suggest: "Run /ralph-specum:research to start the research phase."
   |   |   - Continue to Parse Arguments
   |   |
   |   +-- If user chooses 2 (worktree):
   |   |   - Generate branch name from spec name: feat/$specName
   |   |   - Determine worktree path: ../<repo-name>-<spec-name> or prompt user
   |   |   - Create worktree: git worktree add <path> -b <branch-name>
   |   |   - Inform user: "Created worktree at '<path>' on branch '<branch-name>'"
   |   |   - IMPORTANT: Suggest user to cd to worktree and resume conversation there:
   |   |     "For best results, cd to '<path>' and start a new Claude Code session from there."
   |   |     "Then run /ralph-specum:research to begin."
   |   |   - STOP HERE - do not continue to Parse Arguments (user needs to switch directories)
   |   |
   |   +-- Continue to Parse Arguments
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
       |   - Continue to Parse Arguments
       |
       +-- If user chooses 2 (new branch):
       |   - Generate branch name from spec name: feat/$specName
       |   - If spec name not yet known, use temp name: feat/spec-work-<timestamp>
       |   - Create and switch: git checkout -b <branch-name>
       |   - Inform user: "Created branch '<branch-name>' for this work"
       |   - Continue to Parse Arguments
       |
       +-- If user chooses 3 (worktree):
           - Generate branch name from spec name: feat/$specName
           - Determine worktree path: ../<repo-name>-<spec-name> or prompt user
           - Create worktree: git worktree add <path> -b <branch-name>
           - Inform user: "Created worktree at '<path>' on branch '<branch-name>'"
           - IMPORTANT: Suggest user to cd to worktree and resume conversation there
           - STOP HERE - do not continue to Parse Arguments (user needs to switch directories)
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

## Quick Mode Branch Handling

In `--quick` mode, still perform branch check but skip the user prompt for non-default branches:
- If on default branch: auto-create feature branch in current directory (no worktree prompt in quick mode)
- If on non-default branch: stay on current branch (no prompt, quick mode is non-interactive)

## Worktree Setup

### State Files Copied to Worktree

- `$DEFAULT_SPECS_DIR/.current-spec` - Active spec name/path pointer
- `$SPEC_PATH/.ralph-state.json` - Loop state (phase, taskIndex, iterations)
- `$SPEC_PATH/.progress.md` - Progress tracking and learnings

**Note**: The spec may be in any configured specs_dir, not just `./specs/`. Use `ralph_resolve_current()` to get the full spec path.

These files are copied when:
1. The worktree is created via `git worktree add`
2. A spec is currently active (resolved via `ralph_resolve_current()`)
3. The source files exist in the main worktree

Copy uses non-overwrite semantics (skips if file already exists in target).

### Worktree Creation Script

```bash
# Get repo name for path suggestion
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Get default specs dir and resolve current spec path using path resolver
DEFAULT_SPECS_DIR=$(ralph_get_default_dir)  # e.g., "./specs"
SPEC_PATH=""
SPEC_NAME=""

# Resolve current spec (handles both bare names and full paths)
if SPEC_PATH=$(ralph_resolve_current 2>/dev/null); then
    SPEC_NAME=$(basename "$SPEC_PATH")
fi

# Default worktree path
WORKTREE_PATH="../${REPO_NAME}-${SPEC_NAME}"

# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"

# Copy spec state files to worktree (failures are warnings, not errors)
# Note: Always copy .current-spec from default specs dir
if [ -d "$DEFAULT_SPECS_DIR" ]; then
    mkdir -p "$WORKTREE_PATH/$DEFAULT_SPECS_DIR" || echo "Warning: Failed to create specs directory in worktree"

    # Copy .current-spec if exists (don't overwrite existing)
    if [ -f "$DEFAULT_SPECS_DIR/.current-spec" ] && [ ! -f "$WORKTREE_PATH/$DEFAULT_SPECS_DIR/.current-spec" ]; then
        cp "$DEFAULT_SPECS_DIR/.current-spec" "$WORKTREE_PATH/$DEFAULT_SPECS_DIR/.current-spec" || echo "Warning: Failed to copy .current-spec to worktree"
    fi
fi

# If spec path resolved, copy spec state files from that path
# (may be in non-default specs dir like ./packages/api/specs/my-feature)
if [ -n "$SPEC_PATH" ] && [ -d "$SPEC_PATH" ]; then
    # Create parent directory structure in worktree
    SPEC_PARENT_DIR=$(dirname "$SPEC_PATH")
    mkdir -p "$WORKTREE_PATH/$SPEC_PARENT_DIR" || echo "Warning: Failed to create spec parent directory in worktree"
    mkdir -p "$WORKTREE_PATH/$SPEC_PATH" || echo "Warning: Failed to create spec directory in worktree"

    # Copy state files (don't overwrite existing)
    if [ -f "$SPEC_PATH/.ralph-state.json" ] && [ ! -f "$WORKTREE_PATH/$SPEC_PATH/.ralph-state.json" ]; then
        cp "$SPEC_PATH/.ralph-state.json" "$WORKTREE_PATH/$SPEC_PATH/" || echo "Warning: Failed to copy .ralph-state.json to worktree"
    fi

    if [ -f "$SPEC_PATH/.progress.md" ] && [ ! -f "$WORKTREE_PATH/$SPEC_PATH/.progress.md" ]; then
        cp "$SPEC_PATH/.progress.md" "$WORKTREE_PATH/$SPEC_PATH/" || echo "Warning: Failed to copy .progress.md to worktree"
    fi
fi
```

### After Worktree Creation

Output clear guidance for the user:
```text
Created worktree at '<path>' on branch '<branch-name>'
Spec state files copied to worktree.

For best results, cd to the worktree directory and start a new Claude Code session from there:

  cd <path>
  claude

Then run /ralph-specum:research to begin the research phase.
```

STOP the command here - do not continue to Parse Arguments or create spec files.
The user needs to switch directories first to work in the worktree.
To clean up later: `git worktree remove <path>`
