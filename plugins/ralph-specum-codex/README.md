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
codex plugin marketplace add tzachbon/smart-ralph \
  --sparse .agents/plugins \
  --sparse plugins/ralph-specum-codex
codex plugin add ralph-specum@smart-ralph
```

Start a new Codex task after installation.

<details>
<summary>Local development fallback</summary>

Use this only when testing local plugin edits.

```bash
rm -rf /tmp/smart-ralph
git clone https://github.com/tzachbon/smart-ralph.git /tmp/smart-ralph
mkdir -p ./plugins ./.agents/plugins
rm -rf -- ./plugins/ralph-specum-codex
cp -R /tmp/smart-ralph/plugins/ralph-specum-codex ./plugins/ralph-specum-codex
cp /tmp/smart-ralph/.agents/plugins/marketplace.json ./.agents/plugins/marketplace.json
codex plugin marketplace add .
codex plugin add ralph-specum@smart-ralph
rm -rf /tmp/smart-ralph
```

</details>

### Review the Stop hook

Codex enables hooks by default. In a new task, run `/hooks`, review the bundled Stop hook, and trust it if you want automatic task-by-task execution. Until the hook is trusted, run `$ralph-specum-implement` once per task manually. See `references/workflow.md` for the fallback workflow.

## Updating

For a Git-backed marketplace, pull the latest version with:

```bash
codex plugin marketplace upgrade smart-ralph
```

If you used the local development fallback, rerun those fallback commands from the project directory to replace the copied plugin. `codex plugin marketplace upgrade` does not refresh local marketplaces.

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
| `$ralph-specum-prototype` | Run or resume an optional prototype |
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

## Optional Prototypes

- After research or requirements, normal mode may suggest a prototype. Choose `decline and continue` to move to the next phase, or `continue to prototype` to test one question. Use `$ralph-specum-prototype` for a direct request from any main phase. Claude users invoke the matching `/ralph-specum:prototype` command.
- Quick mode runs one request after requirements. It asks no prototype questions, takes over the oldest design blocker or selects the highest-risk grounded question, and continues to design after every outcome.
- Codex delegates the builder to a child agent and stores its `agentId`. Source stays in a sibling worktree or eligible scratch directory. The current checkout does not switch. Quick mode copies no dirty work; normal mode transfers only paths the user approves.
- Choose `retained` to keep source. `ephemeral` allows deletion only after the normal exact-path confirmation or a reviewed quick cleanup receipt. Ralph publishes immutable records at `<resolved-basePath>/prototypes/<id>.md`; `$ralph-specum-start --resume <id>` and `$ralph-specum-prototype --resume <id>` resume active work, and `$ralph-specum-status` reports recovery and source state.
- Source, records, receipts, and quarantines remain local. A local commit does not permit a push, remote branch, PR inclusion, issue write, or record deletion. Authorize each remote action on its own.

## Hooks

The Stop hook (`hooks/stop-watcher.sh`) enables automatic task-by-task execution. It reads `.ralph-state.json` and outputs `{"decision":"block","reason":"Continue to task N/M"}` to keep the execution loop running.

Codex loads plugin hooks by default, but does not run an untrusted hook. Run `/hooks` in a new task to review and trust it. See `references/workflow.md` for the manual fallback.

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
