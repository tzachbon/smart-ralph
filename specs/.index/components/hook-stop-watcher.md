---
type: component-spec
generated: true
source: plugins/ralph-specum/hooks/scripts/stop-watcher.sh
hash: a1b2c3d4
category: hooks
indexed: 2026-02-05T15:28:01+02:00
---

# stop-watcher hook

## Purpose
Logging-only watcher for Ralph Specum Stop events. Logs current execution state to stderr and cleans up orphaned temp progress files. Does NOT control loop execution (Ralph Loop manages that).

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
| Read state | .ralph-state.json | Get current task index, phase |
| Log state | stderr | Output current execution status |
| Cleanup temp files | .progress-task-*.md | Remove orphaned files >60min old |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- jq for JSON parsing
- sed for settings extraction
- find for temp file cleanup
- .ralph-state.json for state
- specs/.current-spec for active spec

## AI Context
**Keywords**: stop-watcher hook logging cleanup temp-files progress-task parallel execution-state
**Related files**: plugins/ralph-specum/commands/implement.md, plugins/ralph-specum/commands/cancel.md
