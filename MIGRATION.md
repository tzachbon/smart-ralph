# Migration Guide

## v1.x to v2.0.0

### What Changed

v2.0.0 delegates task execution to the official Ralph Loop plugin instead of using a custom stop-handler.

| Before (v1.x) | After (v2.0.0) |
|---------------|----------------|
| Built-in stop-handler controlled loop | Ralph Loop plugin controls loop |
| `/implement` managed iterations directly | `/implement` invokes `/ralph-loop` |
| `/cancel` deleted state files only | `/cancel` calls `/cancel-ralph` + deletes state |
| ~300 lines of bash for loop control | Thin wrapper around Ralph Loop |

### Migration Steps

1. **Install Ralph Loop**
   ```bash
   /plugin install ralph-wiggum@claude-plugins-official
   ```

2. **Restart Claude Code**
   Required for plugin to load.

3. **Update Smart Ralph** (if installed from marketplace)
   ```bash
   /plugin update ralph-specum@smart-ralph
   ```

4. **Verify**
   ```bash
   /ralph-specum:status
   ```
   Should show your specs without errors.

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

**"Ralph Loop plugin not found"**
- Install it: `/plugin install ralph-wiggum@claude-plugins-official`
- Restart Claude Code

**"Loop state conflict"**
- Another Ralph loop may be active
- Run `/cancel-ralph` to reset Ralph Loop state
- Then `/ralph-specum:implement` to resume

**Tasks not advancing**
- Check `.progress.md` for errors
- Verify spec-executor outputs `TASK_COMPLETE`
- Check task checkboxes in `tasks.md`

**Old stop-handler still running**
- If you had a local dev install, remove old plugin directory
- Reinstall from marketplace or GitHub

### Why This Change

- Less code to maintain (deleted ~300 lines of bash)
- Official plugin gets updates and bug fixes from Anthropic
- Better reliability for the execution loop
- Cleaner separation of concerns
