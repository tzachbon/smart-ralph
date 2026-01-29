---
spec: when-creating-worktree
phase: research
created: 2026-01-29
generated: auto
---

# Research: when-creating-worktree

## Executive Summary

Worktree creation in start.md currently creates a new git worktree but does not copy spec state files. The fix is straightforward: after `git worktree add`, copy relevant state files from source to worktree directory.

## Codebase Analysis

### Worktree Creation Location

File: `plugins/ralph-specum/commands/start.md` (lines 115-146)

```bash
# Current worktree creation pattern
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
WORKTREE_PATH="../${REPO_NAME}-${SPEC_NAME}"
git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"
```

After worktree creation, the command:
- Informs user of worktree path
- Suggests user cd to worktree
- STOPS (does not continue to Parse Arguments)

### State Files Requiring Copy

| File | Location | Purpose |
|------|----------|---------|
| `.current-spec` | `./specs/.current-spec` | Active spec name tracker |
| `.ralph-state.json` | `./specs/<name>/.ralph-state.json` | Execution state (phase, taskIndex, etc.) |
| `.progress.md` | `./specs/<name>/.progress.md` | Progress tracking, learnings, goal |

### Existing Patterns

**SessionStart Hook** (`hooks/scripts/load-spec-context.sh`):
- Reads `.current-spec` to detect active spec
- Reads `.ralph-state.json` for phase/task info
- Reads `.progress.md` for goal context
- All paths relative to `$CWD/specs/`

**Git Worktree Behavior**:
- Shared git history between main repo and worktree
- Separate working directory and index
- `specs/` directory is part of repo, gets cloned to worktree
- BUT: gitignored files (.current-spec, .progress.md, .ralph-state.json) are NOT copied

### Dependencies

- `git worktree add` - creates worktree
- Bash file copy commands (`cp`, `mkdir -p`)
- State files are gitignored (see `.gitignore` lines 1-4)

### Constraints

1. State files are gitignored - this is intentional (user-specific state)
2. Worktree may be created before or after spec creation
3. Need to handle case where spec directory doesn't exist yet in worktree
4. Must not overwrite existing state in worktree

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Simple file copy after worktree creation |
| Effort Estimate | S | 10-20 lines of bash |
| Risk Level | Low | No breaking changes, additive only |

## Recommendations

1. Add state file copy block after `git worktree add` in start.md
2. Copy `.current-spec` to `$WORKTREE_PATH/specs/`
3. Copy entire `./specs/<spec>/` contents if spec exists
4. Create `specs/` directory in worktree if needed
5. Add verification step to confirm copy succeeded
