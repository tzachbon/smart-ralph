---
spec: opencode-codex-support
phase: research
created: 2026-02-15
generated: auto
---

# Research: opencode-codex-support

## Executive Summary

Smart Ralph is tightly coupled to Claude Code's plugin system (plugin.json, markdown commands with YAML frontmatter, Task tool, TeamCreate/SendMessage, Stop hooks). Cross-tool support requires a layered approach: SKILL.md files as universal entry points (works everywhere), tool-specific adapters for execution loops, and a configuration bridge for tool-specific setup. The spec artifacts themselves are already tool-agnostic (markdown/JSON).

## Codebase Analysis

### Existing Patterns

- **Plugin manifest**: `plugins/ralph-specum/.claude-plugin/plugin.json` -- Claude Code-specific JSON manifest (v3.3.3)
- **Commands**: 16 markdown files in `plugins/ralph-specum/commands/` with YAML frontmatter (`description`, `argument-hint`, `allowed-tools`) -- Claude Code-specific format
- **Agents**: 8 markdown files in `plugins/ralph-specum/agents/` with `name`, `description`, `model` frontmatter -- Claude Code-specific Task tool delegation
- **Hooks**: `hooks/hooks.json` defines Stop + SessionStart hooks calling bash scripts -- Claude Code-specific hook system
- **Stop watcher**: `hooks/scripts/stop-watcher.sh` reads `.ralph-state.json`, outputs JSON `{decision: "block", reason: ...}` to continue execution loop -- Claude Code Stop hook protocol
- **Path resolver**: `hooks/scripts/path-resolver.sh` provides `ralph_resolve_current()`, `ralph_find_spec()`, `ralph_list_specs()` -- bash functions, portable
- **Skills (existing)**: 6 SKILL.md files in `plugins/ralph-specum/skills/` -- already cross-tool compatible format
- **Top-level skills**: Symlinks in `skills/` pointing to `.agents/skills/` -- separate from plugin skills
- **Templates**: `plugins/ralph-specum/templates/` -- markdown templates, already tool-agnostic
- **Schemas**: `plugins/ralph-specum/schemas/spec.schema.json` -- JSON Schema, tool-agnostic
- **State files**: `.ralph-state.json` and `.progress.md` -- JSON + markdown, already tool-agnostic

### Dependencies

- `jq` -- used by stop-watcher.sh and state management; available cross-platform
- `gh` CLI -- used for PR lifecycle; available cross-platform
- Claude Code `Task` tool -- primary delegation mechanism; NOT available in OpenCode/Codex
- Claude Code `TeamCreate`/`SendMessage` -- parallel research; NOT available in OpenCode/Codex
- Claude Code `Stop` hook protocol -- execution loop continuation; NOT available in OpenCode/Codex
- Claude Code `SessionStart` hook -- context loading; NOT available in OpenCode/Codex

### Constraints

- **Claude Code plugin format is proprietary**: YAML-frontmatter commands, hooks.json, Task tool, AskUserQuestion are all Claude Code-specific
- **OpenCode** has its own plugin system (JS/TS hooks: `tool.execute.after`, `session.idle`), commands (`.opencode/commands/`), and agents (`.opencode/agents/`)
- **Codex CLI** has no hook system, no custom commands, no custom agents -- most limited tool
- **SKILL.md** is the only format natively supported by all three tools
- Existing Claude Code users must see zero regression
- Spec artifacts (research.md, requirements.md, design.md, tasks.md, .progress.md, .ralph-state.json) must remain identical across tools

### Claude Code-Specific Dependencies in Current Architecture

| Component | Claude Code Feature Used | Portable? |
|-----------|-------------------------|-----------|
| Commands (start, implement, etc.) | YAML frontmatter markdown commands | No -- needs SKILL.md conversion |
| Agent delegation | Task tool with `subagent_type` | No -- needs adapter per tool |
| Execution loop | Stop hook + JSON output | No -- needs adapter per tool |
| Parallel research | TeamCreate/SendMessage | No -- needs adapter per tool |
| Context loading | SessionStart hook | No -- needs adapter per tool |
| Question asking | AskUserQuestion tool | No -- needs fallback per tool |
| Spec state files | .ralph-state.json / .progress.md | Yes -- JSON/markdown |
| Templates | Markdown files | Yes |
| Schemas | JSON Schema | Yes |
| Path resolution | Bash functions | Yes -- portable bash |

## Tool Capability Matrix

| Capability | Claude Code | OpenCode | Codex CLI |
|-----------|------------|----------|-----------|
| SKILL.md discovery | Yes | Yes | Yes |
| Custom commands | Yes (MD + frontmatter) | Yes (.opencode/commands/) | No |
| Custom agents | Yes (agents/ dir) | Yes (.opencode/agents/) | No (AGENTS.md only) |
| Hooks (Stop/Start) | Yes (hooks.json) | Yes (JS/TS hooks) | No |
| Subagent delegation | Task tool | Task tool variant | No |
| Team/parallel work | TeamCreate/SendMessage | Subagent system | No |
| MCP server support | Yes (.mcp.json) | Yes (opencode.json) | Yes (config.toml) |
| Progressive disclosure | Via skills | Via skills | Via skills |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | SKILL.md portability is straightforward; adapters are well-scoped |
| Effort Estimate | L | 8 core SKILL.md files + 3 adapter layers + config bridge + tests |
| Risk Level | Medium | Execution loop adaptation for Codex (no hooks) is the hardest part |

## Recommendations

1. Start with SKILL.md portability -- convert all 8 core commands to SKILL.md files. This provides immediate value across all tools with zero adapter work.
2. For execution loop in Codex: use progressive disclosure via SKILL.md. The skill guides the user through tasks one-by-one, reading .ralph-state.json and tasks.md to determine next step. No hooks needed.
3. For OpenCode: JS/TS plugin hooks provide near-parity with Claude Code. Implement `tool.execute.after` hook to replicate stop-watcher behavior.
4. Configuration bridge is a nice-to-have for Phase 2. Start with documented manual setup per tool.
5. AGENTS.md generation can be a simple transform of design.md key decisions -- low effort, high value for Codex.
6. Keep existing Claude Code plugin untouched. New SKILL.md files are additive.

## Open Questions

1. What version of OpenCode's plugin system is targeted? (JS/TS hooks API may vary)
2. Should the MCP server approach for Codex be a separate deliverable or included in this spec?
3. How should the SKILL.md files reference agent prompts -- inline or via file references?
