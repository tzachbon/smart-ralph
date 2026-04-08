# Agent Config Templates

These are bootstrap templates for Codex custom agents used by Ralph Specum.

## How to Install

Codex agents are defined in `config.toml`. To add Ralph Specum agents:

1. Open your Codex config file:
   - User-level: `~/.codex/config.toml`
   - Project-level: `.codex/config.toml`

2. Open the `.toml.template` file for each agent you want to install

3. Copy the `[agents.ralph-specum-<name>]` block into your `config.toml`

4. Uncomment the `developer_instructions` field and fill in the system prompt from the corresponding Claude agent file at `plugins/ralph-specum/agents/<name>.md`

5. Restart Codex

## Example

```toml
# In ~/.codex/config.toml or .codex/config.toml

[agents.ralph-specum-spec-executor]
description = "Autonomous task implementer"
developer_instructions = """
You are a spec-executor. Implement the assigned task, verify it works,
commit the changes, and output TASK_COMPLETE when done.
"""
```

## Available Templates

| Template | Role |
|----------|------|
| `research-analyst.toml.template` | Web search, docs, codebase exploration |
| `product-manager.toml.template` | User stories, acceptance criteria |
| `architect-reviewer.toml.template` | Technical design, architecture |
| `task-planner.toml.template` | POC-first task breakdown |
| `spec-executor.toml.template` | Autonomous task implementation |
| `spec-reviewer.toml.template` | Read-only artifact validation |
| `qa-engineer.toml.template` | Verification task execution |
| `refactor-specialist.toml.template` | Section-by-section spec updates |
| `triage-analyst.toml.template` | Feature decomposition, epic creation |

## Notes

- Field names may vary by Codex version. Check the [Codex config reference](https://developers.openai.com/codex/config-reference) for the current field name (`developer_instructions` or `system_prompt`).
- Agent `max_threads` defaults to 6. Ralph Specum typically uses 1-3 concurrent agents.
- Set `max_depth = 1` to prevent recursive agent fan-out.
