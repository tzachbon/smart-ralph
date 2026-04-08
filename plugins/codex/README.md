# Ralph Specum for Codex

Spec-driven development plugin for OpenAI Codex. Full parity with the Claude Code ralph-specum plugin (v4.9.1).

Transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## Installation

Pick one of these two methods.

### Personal install (available in every project)

```bash
# Download and copy the plugin
git clone https://github.com/tzachbon/smart-ralph.git /tmp/smart-ralph
mkdir -p ~/.codex/plugins
cp -R /tmp/smart-ralph/plugins/codex ~/.codex/plugins/codex
rm -rf /tmp/smart-ralph

# Register in your personal marketplace
mkdir -p ~/.agents/plugins
cat > ~/.agents/plugins/marketplace.json << 'EOF'
{
  "name": "smart-ralph",
  "plugins": [{
    "name": "ralph-specum",
    "source": {"source": "local", "path": "~/.codex/plugins/codex"},
    "policy": {"installation": "AVAILABLE"},
    "category": "Productivity"
  }]
}
EOF
```

Restart Codex. Open the plugin directory. Install `ralph-specum`.

### Per-project install (one repo only)

```bash
# From your project root
git clone https://github.com/tzachbon/smart-ralph.git /tmp/smart-ralph
mkdir -p ./plugins
cp -R /tmp/smart-ralph/plugins/codex ./plugins/codex

# Add marketplace entry
mkdir -p ./.agents/plugins
cat > ./.agents/plugins/marketplace.json << 'EOF'
{
  "name": "smart-ralph",
  "plugins": [{
    "name": "ralph-specum",
    "source": {"source": "local", "path": "./plugins/codex"},
    "policy": {"installation": "AVAILABLE"},
    "category": "Productivity"
  }]
}
EOF
rm -rf /tmp/smart-ralph
```

Restart Codex. Open the plugin directory. Install `ralph-specum`.

### Enable hooks (recommended)

The Stop hook auto-advances through tasks during execution. Add to `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Without hooks, you run `$ralph-specum-implement` once per task manually (see `references/workflow.md` for the fallback workflow).

### Agent configs (optional)

Copy templates from `agent-configs/*.toml.template` into your `.codex/config.toml` for specialized subagents. See `agent-configs/README.md`.

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

Update any scripts, docs, or automation that reference `platforms/codex/` paths to use `plugins/codex/` instead.

### Step 4: Verify

Run `$ralph-specum-status` to confirm the plugin is active and can find your specs.

### What changed

| Before (skills) | After (plugin) |
|------------------|----------------|
| 15 separate skill installs | 1 plugin install |
| No marketplace entry | Discoverable via plugin directory |
| No hooks | Stop hook for auto-execution |
| Manual skill updates | Plugin version tracking |
| Skills at `platforms/codex/skills/` | Plugin at `plugins/codex/` |

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
