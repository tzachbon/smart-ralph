# Troubleshooting

Common issues and solutions for Smart Ralph.

---

## Installation Issues

### Codex skill not found

Ralph Specum v5 installs as one native Codex plugin. Codex 0.144.0 or newer is required.

**Use:**
```bash
codex --version
codex plugin marketplace add tzachbon/smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

Restart Codex after installation. See the [Codex quickstart](plugins/ralph-specum-codex/README.md).

---

### Codex bootstrap files missing

Project-local bootstrap files are optional in Codex. The plugin requires no custom agent TOML or Stop hook.

**Installed locations:**
```text
<installed-plugin>/assets/bootstrap/AGENTS.md
<installed-plugin>/assets/bootstrap/ralph-specum.local.md
```

Copy them into a consumer repo only if you want repo-local guidance.

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

This error comes from an obsolete pre-v5 installation that passed coordinator text through shell arguments.

**Solution:**

Upgrade to Smart Ralph v2.0.1+ which writes the prompt to the state file directly instead of passing it through CLI arguments.

```bash
/plugin uninstall ralph-specum
/plugin install ralph-specum@smart-ralph
```

---

### Task keeps failing / Max iterations reached

After three failed attempts, Ralph stops the current task and records the blocker.

**Solutions:**

1. Check `progress.md` in your spec folder for error details
2. Fix the issue manually
3. Resume with `/ralph-specum:implement`

**Common causes:**
- Missing dependencies
- Failing tests that need manual intervention
- Ambiguous task instructions

---

### Codex goal already active

Use native goal status to inspect it. Pause, resume, or clear it with native goal controls before starting another autonomous run. Normal `$ralph-specum-implement` does not create a goal.

---

### Task marked complete but work not done

The spec-executor may have output `TASK_COMPLETE` prematurely.

**Solutions:**

1. Check the task checkbox in `tasks.md` - uncheck it if needed
2. Review `progress.md` for what was actually completed
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

In Codex, use `$ralph-specum` or `$ralph-specum-start`, then approve the current artifact, request changes, or explicitly continue to the matching next step.

If the work was triaged into an epic, check `./specs/.current-epic` and resume the next unblocked spec rather than creating a new one.

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

Current task plans may also include:
- `[P]` markers for tasks safe to run in parallel
- `[VERIFY]` checkpoints
- VE tasks for end-to-end verification
- fine or coarse granularity depending on `--tasks-size`

In Codex, the same concepts are exposed through `$ralph-specum-tasks` and `$ralph-specum-implement`.

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
   - Contents of `progress.md`, plus legacy `.progress.md` only when migration is involved
   - Claude Code version
