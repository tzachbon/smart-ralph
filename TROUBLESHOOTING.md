# Troubleshooting

Common issues and solutions for Smart Ralph.

---

## Installation Issues

### "Ralph Loop plugin not found"

Smart Ralph v2.0.0+ requires the Ralph Loop plugin as a dependency.

**Solution:**
```bash
/plugin install ralph-wiggum@claude-plugins-official
```

Then restart Claude Code.

---

### "stop-handler.sh: No such file or directory"

```
Stop hook error: Failed with non-blocking status code: bash: .../hooks/scripts/stop-handler.sh: No such file or directory
```

This error occurs when you have an old plugin installation (v1.x) that references `stop-handler.sh`, which was renamed to `stop-watcher.sh` in v2.0.0.

**Solutions:**

1. **Reinstall the plugin** (recommended):
   ```bash
   /plugin uninstall ralph-specum
   /plugin install ralph-specum@smart-ralph
   ```

2. **Remove stale installation** if you have a local dev copy:
   ```bash
   # Remove old plugin directory
   rm -rf /path/to/old/ralph-specum-plugin
   ```

3. **Manual fix** - update `hooks/hooks.json` in your old installation:
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stop-watcher.sh"
             }
           ]
         }
       ]
     }
   }
   ```

---

## Execution Issues

### "command not found: You" or shell parsing errors

```
(eval):5: command not found: You
(eval):cd:6: too many arguments
```

This error occurs when the ralph-loop skill's setup script receives the coordinator prompt as unquoted shell arguments, causing the shell to interpret the prompt text as commands.

**Solution:**

Upgrade to Smart Ralph v2.0.1+ which writes the prompt to the state file directly instead of passing it through CLI arguments.

```bash
/plugin uninstall ralph-specum
/plugin install ralph-specum@smart-ralph
```

---

### Task keeps failing / Max iterations reached

After max iterations (default: 5), the Ralph Loop stops to prevent infinite loops.

**Solutions:**

1. Check `.progress.md` in your spec folder for error details
2. Fix the issue manually
3. Resume with `/ralph-specum:implement`

**Common causes:**
- Missing dependencies
- Failing tests that need manual intervention
- Ambiguous task instructions

---

### "Loop state conflict"

Another Ralph loop may already be running in this session.

**Solution:**
```bash
# Cancel the existing loop
/cancel-ralph

# Then retry
/ralph-specum:implement
```

---

### Task marked complete but work not done

The spec-executor may have output `TASK_COMPLETE` prematurely.

**Solutions:**

1. Check the task checkbox in `tasks.md` - uncheck it if needed
2. Review `.progress.md` for what was actually completed
3. Run `/ralph-specum:implement` to retry

---

## State Issues

### Want to start over completely

```bash
# Cancel and cleanup
/ralph-specum:cancel

# Delete the spec folder if you want a fresh start
rm -rf ./specs/your-spec-name

# Start fresh
/ralph-specum:new your-spec-name Your goal here
```

---

### Resume existing spec

Just run `/ralph-specum:start` - it auto-detects existing specs and continues where you left off.

If you want to force a specific spec:
```bash
/ralph-specum:switch spec-name
/ralph-specum:implement
```

---

### State file corrupted

If `.ralph-state.json` gets corrupted:

```bash
# View current state
cat ./specs/your-spec-name/.ralph-state.json

# Delete and restart execution
rm ./specs/your-spec-name/.ralph-state.json
/ralph-specum:implement
```

---

## Spec Phase Issues

### Research taking too long

The research-analyst agent searches the web and analyzes your codebase. For large codebases, this can take time.

**Solutions:**
- Be more specific in your goal description
- Skip research with `--skip-research` flag on start command

---

### Design doesn't match requirements

Re-run the design phase:
```bash
/ralph-specum:design
```

The architect-reviewer will regenerate the design based on current requirements.

---

### Tasks don't follow POC-first pattern

The task-planner should generate tasks in 4 phases:
1. Make It Work (POC)
2. Refactoring
3. Testing
4. Quality Gates

If tasks are out of order, re-run:
```bash
/ralph-specum:tasks
```

---

## Plugin Development Issues

### Changes not taking effect

Claude Code caches plugin files. After making changes:

1. Restart Claude Code completely
2. Or use `--plugin-dir` flag to load fresh:
   ```bash
   claude --plugin-dir ./plugins/ralph-specum
   ```

---

### Hook not triggering

Check that `hooks/hooks.json` is valid JSON and properly formatted:

```bash
cat plugins/ralph-specum/hooks/hooks.json | jq .
```

---

## Still stuck?

1. Check [MIGRATION.md](MIGRATION.md) if upgrading from v1.x
2. Open an issue: https://github.com/tzachbon/smart-ralph/issues
3. Include:
   - Error message
   - Contents of `.ralph-state.json`
   - Contents of `.progress.md`
   - Claude Code version
