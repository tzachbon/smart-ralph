# OpenCode Adapter for Smart Ralph

Execution loop adapter that enables the Smart Ralph spec-driven workflow inside [OpenCode](https://opencode.ai). Mirrors the Claude Code stop-hook behavior using OpenCode's JS/TS plugin system.

## What This Does

When a Ralph spec is in the `execution` phase, this hook fires on `session.idle` and `tool.execute.after` events. It reads `.ralph-state.json`, determines if tasks remain, and injects a continuation prompt so the session keeps processing tasks automatically -- no manual re-invocation needed.

The logic mirrors `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` from the Claude Code plugin, translated into TypeScript.

## Prerequisites

- [OpenCode](https://opencode.ai) installed and configured
- Node.js 18+ (for TypeScript execution)
- A project with Ralph spec files (`specs/<name>/tasks.md`, `.ralph-state.json`, etc.)

## Installation

1. Copy the adapter into your project:

```bash
cp -r adapters/opencode/ .opencode/plugins/ralph/
```

Or symlink it:

```bash
mkdir -p .opencode/plugins
ln -s ../../adapters/opencode .opencode/plugins/ralph
```

2. Register the plugin in your `opencode.json`:

```jsonc
{
  "plugins": [
    {
      "name": "ralph-execution-loop",
      "path": ".opencode/plugins/ralph/hooks/execution-loop.ts",
      "hooks": ["session.idle", "tool.execute.after"]
    }
  ]
}
```

## Configuration

### Spec Directories

By default the adapter looks for specs in `./specs/`. To configure custom directories (e.g. for monorepos), create `.claude/ralph-specum.local.md` at the project root:

```markdown
---
enabled: true
specs_dirs: ["./specs", "./packages/api/specs"]
---
```

The adapter reads this file the same way the Claude Code plugin does, so configuration is shared between tools.

### Disabling the Plugin

Set `enabled: false` in the settings file to disable the execution loop without removing the plugin:

```markdown
---
enabled: false
---
```

## How the Execution Loop Works

1. **Detect active spec** -- reads `.current-spec` from the specs directory to find which spec is active.
2. **Read state** -- parses `.ralph-state.json` for phase, taskIndex, totalTasks, and iteration counters.
3. **Skip non-execution phases** -- if the phase is not `execution`, the hook does nothing.
4. **Check completion** -- if `taskIndex >= totalTasks`, signals that all tasks are done and the state file should be cleaned up.
5. **Inject continuation prompt** -- outputs a structured prompt with the spec name, task index, iteration count, and resume instructions. This prompt tells the session to delegate the next task to `spec-executor`.
6. **Cleanup** -- removes orphaned `.progress-task-*.md` temp files older than 60 minutes.

### Safety Guards

- **Global iteration limit**: stops after `maxGlobalIterations` (default 100) to prevent infinite loops.
- **Plugin disable check**: respects the `enabled: false` setting.
- **Transcript detection**: checks for `ALL_TASKS_COMPLETE` in the transcript as a backup termination signal.
- **Corrupt state handling**: gracefully returns "continue" if the state file is missing or invalid JSON.

## Hook Result Format

The hook returns one of:

```typescript
// No action needed (no active spec, wrong phase, etc.)
{ decision: "continue" }

// Inject continuation prompt to keep executing tasks
{
  decision: "block",
  reason: "Continue spec: my-feature (Task 3/10, Iter 5)\n...",
  systemMessage: "Ralph iteration 5 | Task 3/10"
}
```

## Example opencode.json (Full)

```jsonc
{
  "model": "claude-sonnet-4-20250514",
  "plugins": [
    {
      "name": "ralph-execution-loop",
      "path": ".opencode/plugins/ralph/hooks/execution-loop.ts",
      "hooks": ["session.idle", "tool.execute.after"]
    }
  ],
  "skills": {
    "directories": [
      "plugins/ralph-specum/skills"
    ]
  }
}
```

This configuration:
- Registers the execution loop hook for automatic task continuation
- Makes Ralph SKILL.md files discoverable for workflow commands (start, research, requirements, design, tasks, implement, status, cancel)

## Troubleshooting

### Hook not firing

- Verify the plugin path in `opencode.json` is correct relative to the project root.
- Check that `opencode.json` is in the project root directory.
- Confirm OpenCode supports the `session.idle` and `tool.execute.after` hook events.

### Tasks not advancing

- Check `.ralph-state.json` exists and has `"phase": "execution"`.
- Verify `.current-spec` file exists in the specs directory and contains the spec name.
- Look at stderr output for `[ralph-opencode]` log lines indicating what the hook detected.

### Infinite loop / too many iterations

- The hook respects `maxGlobalIterations` (default 100). If hit, check `.progress.md` for repeated failures.
- Set `enabled: false` in settings to stop the loop, then investigate.

### State file errors

- If `.ralph-state.json` is corrupt, delete it and re-run the implement workflow to reinitialize.
- The hook gracefully skips unreadable state files (returns `{ decision: "continue" }`).
