# Ralph Specum for Claude Code

Native spec-driven development for Claude Code. The plugin uses Claude slash commands, agents, teams, approval gates, and hooks.

## Requirements

- Claude Code 2.1.32 or newer
- Agent teams enabled when you want team delegation

```bash
claude --version
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Install

```bash
claude plugin marketplace add tzachbon/smart-ralph
claude plugin install ralph-specum@smart-ralph
```

Restart Claude Code, then run `/ralph-specum:start`.

## Update

```bash
claude plugin marketplace update smart-ralph
claude plugin update ralph-specum@smart-ralph
```

Restart Claude Code to apply the update.

## Roll back

Replace `v5.0.0` with the release tag you want:

```bash
rm -rf /tmp/smart-ralph
git clone --branch v5.0.0 --depth 1 https://github.com/tzachbon/smart-ralph.git /tmp/smart-ralph
claude plugin uninstall ralph-specum@smart-ralph
claude plugin marketplace remove smart-ralph
claude plugin marketplace add /tmp/smart-ralph
claude plugin install ralph-specum@smart-ralph
```

Restart Claude Code after rollback.

## Native surface

- `/ralph-specum:start`
- `/ralph-specum:triage`
- `/ralph-specum:research`
- `/ralph-specum:requirements`
- `/ralph-specum:design`
- `/ralph-specum:tasks`
- `/ralph-specum:implement`
- `/ralph-specum:status`

Claude runtime state is local and disposable. Durable workflow state lives in the spec Markdown artifacts.
