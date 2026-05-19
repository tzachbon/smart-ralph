# Ralph Specum for Codex

Spec-driven development plugin for OpenAI Codex. Full parity with the Claude Code ralph-specum plugin.

Transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## Prerequisites

- [OpenAI Codex CLI](https://github.com/openai/codex) installed: `npm install -g @openai/codex`
- A ChatGPT account (Plus, Pro, Team, Edu, or Enterprise) or an OpenAI API key

## Quick Start

After installing (see below), run:

```
$ralph-specum-start my-feature "Build a user authentication system"
```

This starts the spec-driven workflow: research, requirements, design, tasks, then implementation.

## Installation

```bash
codex plugin marketplace add tzachbon/smart-ralph --sparse .agents/plugins
```

Restart Codex after install.

<details>
<summary>Local development fallback</summary>

Use this only when testing local plugin edits.

```bash
rm -rf /tmp/smart-ralph
git clone https://github.com/tzachbon/smart-ralph.git /tmp/smart-ralph
mkdir -p ./plugins ./.agents/plugins
cp -R /tmp/smart-ralph/plugins/ralph-specum-codex ./plugins/ralph-specum-codex
cp /tmp/smart-ralph/.agents/plugins/marketplace.json ./.agents/plugins/marketplace.json
rm -rf /tmp/smart-ralph
```

</details>

### Enable hooks (recommended)

The Stop hook auto-advances through tasks during execution. Add to `~/.codex/config.toml`:

```toml
[features]
plugin_hooks = true
```

Without hooks, you run `$ralph-specum-implement` once per task manually (see `references/workflow.md` for the fallback workflow).

## Updating

Pull the latest version by re-running the install steps. These commands work from any directory.

```bash
codex plugin marketplace upgrade smart-ralph
```

Check your version in `.codex-plugin/plugin.json`. Compare against the [latest release](https://github.com/tzachbon/smart-ralph/releases).

## Agent configs (optional)

Copy templates from `agent-configs/*.toml.template` into your `.codex/config.toml` for specialized subagents. See `agent-configs/README.md`.

## Skills Reference

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

## Hooks

The Stop hook (`hooks/stop-watcher.sh`) enables automatic task-by-task execution. It reads `.ralph-state.json` and outputs `{"decision":"block","reason":"Continue to task N/M"}` to keep the execution loop running.

Requires `[features] plugin_hooks = true` in config.toml. See `references/workflow.md` for the manual fallback when hooks are disabled.

<details>
<summary>Migration from old skills (platforms/codex/)</summary>

If you previously installed Ralph Specum skills from `platforms/codex/skills/` via `$skill-installer`:

**Step 1: Remove old skills**

```bash
rm -rf ~/.codex/skills/ralph-specum*
```

**Step 2: Install the new plugin**

Follow the Installation steps above.

**Step 3: Update references**

Update any scripts, docs, or automation that reference `platforms/codex/` paths to use `plugins/ralph-specum-codex/` instead.

**Step 4: Verify**

Run `$ralph-specum-status` to confirm the plugin is active and can find your specs.

</details>

## Version

Check `.codex-plugin/plugin.json` for the current version.
