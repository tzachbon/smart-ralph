# Migration Guide

## v2.x to v3.0.0

### What Changed

v3.0.0 removes the Ralph Loop plugin dependency by inlining the loop control logic into the stop-hook.

| Before (v2.x) | After (v3.0.0) |
|---------------|----------------|
| Ralph Loop plugin controls loop | Internal stop-hook controls loop |
| `/implement` invokes `/ralph-loop` skill | `/implement` writes state + coordinator prompt |
| `/cancel` calls `/cancel-ralph` + deletes state | `/cancel` deletes state files (stops loop) |
| Requires ralph-wiggum plugin | No external dependencies |

### Migration Steps

1. **Update Smart Ralph**
   ```bash
   /plugin update ralph-specum@smart-ralph
   ```

2. **Restart Claude Code**
   Required for plugin to reload.

3. **Remove Ralph Wiggum (optional)**
   The old dependency can be removed but isn't required - there are no conflicts:
   ```bash
   /plugin uninstall ralph-wiggum
   ```

4. **Verify**
   ```bash
   /ralph-specum:status
   ```

### Existing Specs

**No changes needed.** All spec files and state files use the same format.

### If You Have an Active Execution

1. Cancel the old loop state:
   ```bash
   /ralph-specum:cancel
   ```

2. Resume execution:
   ```bash
   /ralph-specum:implement
   ```

### Why This Change

- **Zero dependencies** - simpler installation (single plugin install)
- **Full control** - loop logic is now in one place (~50 lines of bash)
- **Same reliability** - same task format, same verification, same workflow

---

## v1.x to v2.0.0

### What Changed

v2.0.0 delegated task execution to the Ralph Loop plugin instead of using a custom stop-handler.

| Before (v1.x) | After (v2.0.0) |
|---------------|----------------|
| Built-in stop-handler controlled loop | Ralph Loop plugin controls loop |
| `/implement` managed iterations directly | `/implement` invokes `/ralph-loop` |
| `/cancel` deleted state files only | `/cancel` calls `/cancel-ralph` + deletes state |
| ~300 lines of bash for loop control | Thin wrapper around Ralph Loop |

### Migration Steps

This migration path is superseded by v3.0.0. If upgrading from v1.x, go directly to v3.0.0.

### Existing Specs

**No changes needed.** Spec files (research.md, requirements.md, design.md, tasks.md) use the same format. State files (.ralph-state.json, .progress.md) are compatible.

### If You Have an Active Execution

If you were mid-execution when upgrading:

1. Cancel the old loop state:
   ```bash
   /ralph-specum:cancel
   ```

2. Resume execution:
   ```bash
   /ralph-specum:implement
   ```

The new loop picks up from the last completed task.

### Troubleshooting

**Tasks not advancing**
- Check `.progress.md` for errors
- Verify spec-executor outputs `TASK_COMPLETE`
- Check task checkboxes in `tasks.md`

**Old stop-handler still running**
- If you had a local dev install, remove old plugin directory
- Reinstall from marketplace or GitHub
