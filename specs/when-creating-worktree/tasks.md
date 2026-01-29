---
spec: when-creating-worktree
phase: tasks
total_tasks: 7
created: 2026-01-29
generated: auto
---

# Tasks: when-creating-worktree

## Phase 1: Make It Work (POC)

Focus: Add state file copy after worktree creation. Minimal, working solution.

- [x] 1.1 Add state copy block after git worktree add
  - **Do**: Find the worktree creation section in start.md (around line 127). After `git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"`, add a bash code block that copies state files. The block should: (1) create specs/ dir in worktree, (2) copy .current-spec if exists, (3) copy spec state files if spec directory exists.
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: start.md contains state copy bash block after worktree creation
  - **Verify**: `grep -A 30 "git worktree add" plugins/ralph-specum/commands/start.md | grep -q "\.current-spec" && echo "PASS"`
  - **Commit**: `feat(start): copy spec state files to worktree`
  - _Requirements: FR-1, FR-2, FR-3, FR-4_
  - _Design: State Copy Block_

- [x] 1.2 Update user guidance to mention state copy
  - **Do**: In the worktree success message section (around line 132-146), add a note that state files were copied: "Spec state files copied to worktree."
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: User message mentions state files were copied
  - **Verify**: `grep -q "state.*copied\|copied.*state" plugins/ralph-specum/commands/start.md && echo "PASS"`
  - **Commit**: `docs(start): note state files copied to worktree`
  - _Requirements: AC-1.4_

- [x] 1.3 POC Checkpoint
  - **Do**: Verify feature works end-to-end by testing manually: (1) Create a spec with /ralph-specum:new test-worktree "Test goal", (2) Check state files exist, (3) Create worktree manually with git worktree add, (4) Verify state files copied
  - **Done when**: State files exist in worktree after creation
  - **Verify**: Manual inspection of worktree specs/ directory
  - **Commit**: `feat(start): complete POC for worktree state copy`

## Phase 2: Refactoring

After POC validated, clean up code.

- [x] 2.1 Handle edge case: SPEC_NAME not yet known
  - **Do**: The SPEC_NAME variable may be empty if user is creating worktree before naming spec. Add fallback to read from .current-spec if SPEC_NAME is empty but .current-spec exists.
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: State copy works even when SPEC_NAME is not explicitly provided
  - **Verify**: Code handles `[ -z "$SPEC_NAME" ]` case by reading .current-spec
  - **Commit**: `fix(start): handle missing SPEC_NAME in worktree state copy`
  - _Requirements: FR-5_
  - _Design: Error Handling_

- [x] 2.2 Add error handling for copy failures
  - **Do**: Wrap copy commands with proper error handling. Use `|| true` or explicit checks to prevent worktree creation from failing if copy fails. Add user-facing warning if copy fails.
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Copy failures produce warnings but don't block worktree creation
  - **Verify**: Code contains `|| echo` or `|| true` for copy commands
  - **Commit**: `fix(start): graceful error handling for state copy`
  - _Design: Error Handling_

## Phase 3: Testing

- [x] 3.1 Add verification steps to start.md documentation
  - **Do**: In the worktree section of start.md, add inline verification note explaining what files get copied and when
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Documentation explains state file copy behavior
  - **Verify**: `grep -q "\.ralph-state\.json\|\.progress\.md" plugins/ralph-specum/commands/start.md`
  - **Commit**: `docs(start): document worktree state copy behavior`

## Phase 4: Quality Gates

- [x] 4.1 Version bump plugin
  - **Do**: Bump version in plugin.json and marketplace.json. Use patch version increment.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Version numbers incremented in both files
  - **Verify**: `grep -q "version" plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Commit**: `chore(ralph-specum): bump version for worktree state copy`

## Notes

- **POC shortcuts taken**: Minimal error handling in 1.1, refined in 2.2
- **Production TODOs**: Consider adding state sync back from worktree (out of scope)
