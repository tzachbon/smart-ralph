# Ralph Specum for Codex

Spec-driven development plugin for OpenAI Codex. Full parity with the Claude Code ralph-specum plugin (v4.9.1).

Transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## Installation

### Step 1: Add marketplace entry

Create or update `$REPO_ROOT/.agents/plugins/marketplace.json`:

```json
{
  "name": "local-repo",
  "interface": { "displayName": "Local Plugins" },
  "plugins": [
    {
      "name": "ralph-specum-codex",
      "source": { "source": "local", "path": "./plugins/ralph-specum-codex" },
      "policy": { "installation": "AVAILABLE" },
      "category": "Productivity"
    }
  ]
}
```

### Step 2: Restart Codex

Restart Codex so it discovers the new marketplace entry.

### Step 3: Install the plugin

Open the plugin directory in Codex, find "ralph-specum-codex", and install it.

### Step 4: Enable hooks (recommended)

The execution loop uses the Stop hook to auto-advance through tasks. Add to `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Without hooks, you run `$ralph-specum-implement` manually for each task (see Manual Fallback in references/workflow.md).

### Step 5: Install agent configs (optional)

Copy agent templates from `agent-configs/*.toml.template` into your `.codex/config.toml`. See `agent-configs/README.md` for details.

## Migration from Old Skills (platforms/codex/)

If you previously installed Ralph Specum skills from `platforms/codex/skills/` via `$skill-installer`:

### Step 1: Remove old skills

```bash
# Remove each old skill (adjust path for your install location)
for skill in ralph-specum ralph-specum-start ralph-specum-triage ralph-specum-research ralph-specum-requirements ralph-specum-design ralph-specum-tasks ralph-specum-implement ralph-specum-status ralph-specum-switch ralph-specum-cancel ralph-specum-index ralph-specum-refactor ralph-specum-feedback ralph-specum-help; do
  rm -rf "$CODEX_HOME/skills/$skill" 2>/dev/null
  rm -rf "$HOME/.codex/skills/$skill" 2>/dev/null
done
```

### Step 2: Install the new plugin

Follow the Installation steps above. The new plugin replaces all 15 standalone skills with one installable package.

### Step 3: Update references

Update any scripts, docs, or automation that reference `platforms/codex/` paths to use `plugins/ralph-specum-codex/` instead.

### Step 4: Verify

Run `$ralph-specum-status` to confirm the plugin is active and can find your specs.

### What changed

| Before (skills) | After (plugin) |
|------------------|----------------|
| 15 separate skill installs | 1 plugin install |
| No marketplace entry | Discoverable via plugin directory |
| No hooks | Stop hook for auto-execution |
| Manual skill updates | Plugin version tracking |
| Skills at `platforms/codex/skills/` | Plugin at `plugins/ralph-specum-codex/` |

## What Ships

| Skill | Description |
|-------|-------------|
| `$ralph-specum` | Primary entry point, routing, bootstrap |
| `$ralph-specum-start` | Smart start (new or resume spec) |
| `$ralph-specum-research` | Parallel research phase |
| `$ralph-specum-requirements` | Requirements generation |
| `$ralph-specum-design` | Technical design |
| `$ralph-specum-tasks` | Task breakdown (fine/coarse) |
| `$ralph-specum-implement` | Task execution loop |
| `$ralph-specum-status` | Show all specs and progress |
| `$ralph-specum-switch` | Switch active spec |
| `$ralph-specum-cancel` | Cancel and cleanup |
| `$ralph-specum-triage` | Epic decomposition |
| `$ralph-specum-index` | Codebase indexing |
| `$ralph-specum-refactor` | Spec file updates |
| `$ralph-specum-feedback` | Submit feedback/bugs |
| `$ralph-specum-help` | Show help and workflow guide |

## Agent Configs (Optional)

9 agent templates in `agent-configs/` for specialized subagents: research-analyst, product-manager, architect-reviewer, task-planner, spec-executor, spec-reviewer, qa-engineer, refactor-specialist, triage-analyst.

See `agent-configs/README.md` for installation instructions.

## Hooks

The Stop hook (`hooks/stop-watcher.sh`) enables automatic task-by-task execution. It reads `.ralph-state.json` and outputs `{"decision":"block","reason":"Continue to task N/M"}` to keep the execution loop running.

Requires `[features] codex_hooks = true` in config.toml. See `references/workflow.md` for the manual fallback when hooks are disabled.

## Quick Start

```
$ralph-specum-start my-feature "Build a user authentication system"
```

This starts the spec-driven workflow: research, requirements, design, tasks, then implementation.

## Version

Current version: 4.9.1 (synced with Claude Code plugin)

Package manifest: `.codex-plugin/plugin.json`
