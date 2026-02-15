# Configuration Bridge

The configuration bridge lets you maintain a single `ralph-config.json` at your project root and generate tool-specific configuration for Claude Code, OpenCode, and Codex CLI.

## Quick Start

1. Create `ralph-config.json` in your project root (see format below).
2. Run the generator:

```bash
bash adapters/config/generate-config.sh
```

3. Each enabled tool gets its configuration files created or updated.

## ralph-config.json Format

```json
{
  "$schema": "./adapters/config/ralph-config.schema.json",
  "spec_dirs": ["./specs"],
  "default_branch": "main",
  "commit_spec": true,
  "max_iterations": 100,
  "max_task_iterations": 5,
  "tools": {
    "claude_code": {
      "enabled": true,
      "plugin_dir": "./plugins/ralph-specum"
    },
    "opencode": {
      "enabled": true,
      "hooks_dir": "./adapters/opencode/hooks"
    },
    "codex": {
      "enabled": true,
      "skills_dir": "./.agents/skills",
      "generate_agents_md": true
    }
  }
}
```

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `spec_dirs` | string[] | `["./specs"]` | Directories where specs are stored. Supports monorepo layouts. |
| `default_branch` | string | `"main"` | Default git branch for PR targets and regression checks. |
| `commit_spec` | boolean | `true` | Whether to commit spec artifacts with task commits. |
| `max_iterations` | integer | `100` | Global execution loop iteration limit. |
| `max_task_iterations` | integer | `5` | Max retries per individual task. |
| `tools` | object | (all enabled) | Per-tool configuration. |

### Tool Settings

**claude_code**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Generate Claude Code configuration. |
| `plugin_dir` | string | `"./plugins/ralph-specum"` | Path to the Ralph plugin directory. |

**opencode**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Generate OpenCode configuration. |
| `hooks_dir` | string | `"./adapters/opencode/hooks"` | Path to OpenCode hooks directory. |

**codex**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `true` | Generate Codex CLI configuration. |
| `skills_dir` | string | `"./.agents/skills"` | Where Codex discovers SKILL.md files. |
| `generate_agents_md` | boolean | `true` | Generate AGENTS.md from the active spec's design.md. |

## What Gets Generated

### Claude Code

The generator validates that the plugin is already installed:

- Checks `<plugin_dir>/.claude-plugin/plugin.json` exists
- Logs confirmation or a warning if the plugin is missing
- Does not modify existing plugin files

### OpenCode

The generator creates or updates:

- **`opencode.json`** -- Adds a ralph-specum plugin entry pointing to the hooks directory
- **`.opencode/commands/`** -- Copies workflow SKILL.md files as `ralph-<name>.md` for command discovery
- **`.opencode/agents/`** -- Creates the directory for agent definitions

If `opencode.json` already exists, the generator adds the plugin entry without overwriting other settings.

### Codex CLI

The generator creates:

- **`<skills_dir>/ralph-<name>/SKILL.md`** -- Copies all 8 workflow skills for Codex discovery
- **`<skills_dir>/ralph-implement/SKILL.md`** -- Overrides with the Codex-specific implement skill (supports manual re-invocation loop)
- **`AGENTS.md`** -- (if `generate_agents_md` is true) Generated from the active spec's design.md using `generate-agents-md.sh`

## Options

### Custom config path

```bash
bash adapters/config/generate-config.sh --config ./my-config.json
```

### Dry run

Preview what would be generated without writing files:

```bash
bash adapters/config/generate-config.sh --dry-run
```

### Disable specific tools

Set `enabled: false` for any tool you don't use:

```json
{
  "tools": {
    "claude_code": { "enabled": true },
    "opencode": { "enabled": false },
    "codex": { "enabled": false }
  }
}
```

## Idempotency

The generator is safe to re-run. It:

- Creates directories only if they don't exist
- Overwrites SKILL.md copies (they're derived from the source, not user-edited)
- Adds plugin entries to opencode.json without duplicating them
- Never modifies existing Claude Code plugin files

## Monorepo Support

For monorepos with multiple spec directories:

```json
{
  "spec_dirs": ["./specs", "./packages/api/specs", "./packages/web/specs"]
}
```

The generator searches all spec directories when looking for the active spec (for AGENTS.md generation).

## Requirements

- **jq** -- JSON processor. Install with `brew install jq` (macOS) or `apt install jq` (Linux).
- The Ralph plugin must be installed at the configured `plugin_dir` for Claude Code validation.
- Workflow SKILL.md files must exist in `plugins/ralph-specum/skills/workflow/` for OpenCode/Codex skill copying.
