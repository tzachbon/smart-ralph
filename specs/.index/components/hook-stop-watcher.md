---
type: component-spec
generated: true
source: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
hash: 03374bb5
category: hooks
indexed: 2026-03-03T00:00:00Z
---

# stop-watcher hook

## Purpose
Loop controller for Ralph Specum task execution continuation. Reads execution state, detects ALL_TASKS_COMPLETE in transcript, handles quick mode guard, validates task completion against tasks.md, outputs block JSON to continue execution when tasks remain, and cleans up orphaned temp files.

## Location
`plugins/ralph-specum/hooks/scripts/stop-watcher.sh`

## Public Interface

### Exports
- Stop hook script

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Check settings | ralph-specum.local.md | Skip if plugin disabled |
| Resolve current spec | path-resolver.sh, .current-spec | Find active spec directory with multi-directory support |
| Race condition guard | stat, mtime | Wait if state file modified in last 2 seconds |
| Transcript completion check | transcript_path, ALL_TASKS_COMPLETE | Detect completion signal in transcript (500-line + 20-line fallback) |
| Epic state update | .epic-state.json | Mark spec completed in epic when ALL_TASKS_COMPLETE detected |
| Validate state JSON | jq | Block with error on corrupt state file |
| Quick mode guard | quickMode, phase | Block stop during non-execution phases in quick mode |
| Global iteration limit | globalIteration, maxGlobalIterations | Stop execution if max iterations reached |
| Completion verification | taskIndex, totalTasks, tasks.md | Cross-check state against unchecked tasks in tasks.md |
| Loop continuation | block JSON, task block extraction | Output coordinator resume prompt with current task |
| Parallel group detection | [P] marker, consecutive tasks | Detect and bundle parallel task groups (max 5) |
| Cleanup temp files | .progress-task-*.md | Remove orphaned files older than 60 minutes |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- jq for JSON parsing
- sed for settings extraction
- awk for task block extraction from tasks.md
- find for temp file cleanup
- stat for race condition detection
- path-resolver.sh for spec directory resolution
- .ralph-state.json for execution state
- specs/.current-spec for active spec
- transcript_path for completion detection
- .epic-state.json for epic integration

## AI Context
**Keywords**: stop-watcher hook loop-controller execution continuation block-json quick-mode-guard transcript-detection parallel-group epic-state completion-verification race-condition cleanup
**Related files**: plugins/ralph-specum/commands/implement.md, plugins/ralph-specum/commands/cancel.md, plugins/ralph-specum/hooks/scripts/path-resolver.sh
