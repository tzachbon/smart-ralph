---
spec: codex-plugin-sync
phase: research
created: 2026-04-07
---

# Research: codex-plugin-sync

## Executive Summary

The OpenAI Codex plugin system (launched March 2026) uses a `.codex-plugin/plugin.json` manifest with skills as the primary authoring format. The existing `platforms/codex/` distribution (v4.8.4) already ships 15 skills in the correct SKILL.md format but lacks a proper plugin wrapper. Creating a real Codex plugin at `plugins/ralph-specum-codex/` requires: adding `.codex-plugin/plugin.json`, migrating skills, adding custom agent TOML definitions, adding a marketplace entry, and closing content gaps from the v4.8.4-to-v4.9.1 delta. The Stop hook (needed for the execution loop) is experimental and behind a feature flag, making it the single highest-risk dependency.

## External Research

### Codex Plugin Specification

Entry point: `.codex-plugin/plugin.json` (only this file goes in `.codex-plugin/`; everything else at plugin root).

Manifest fields:
- Required: `name`, `version`, `description`
- Component paths: `skills` (./skills/), `mcpServers` (./.mcp.json), `apps` (./.app.json)
- Optional: `author`, `homepage`, `repository`, `license`, `keywords`, `interface` (marketplace UI metadata)

Plugin structure:
```
my-plugin/
  .codex-plugin/plugin.json
  skills/my-skill/SKILL.md
  .app.json
  .mcp.json
  assets/
```

Skills use the open Agent Skills standard (agentskills.io). Same SKILL.md format works across Codex, Claude Code, Gemini CLI, and Cursor.

Progressive disclosure: Level 1 (name+description pre-loaded), Level 2 (SKILL.md body on demand), Level 3 (referenced files on demand).

Invocation: `$skill-name` syntax (no slash commands in Codex).

### Custom Agents (Subagents)

TOML files under `.codex/agents/` (project-scoped) or `~/.codex/agents/` (personal):
```toml
name = "spec-executor"
description = "Executes implementation tasks"
developer_instructions = """..."""
model = "codex-1"
sandbox_mode = "workspace"
```

Config: `agents.max_threads = 6`, `agents.max_depth = 1`, `agents.job_max_runtime_seconds = 1800`.

Built-in agents: `default`, `worker`, `explorer`.

### Hooks (Experimental)

Requires `[features] codex_hooks = true` in config.toml. Disabled on Windows.

Events: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`.

Stop hook for execution loop:
```json
{"decision": "block", "reason": "Run next task..."}
```

Limitation: `PreToolUse`/`PostToolUse` only intercept `Bash` tool calls currently.

### Marketplace Distribution

Repo-scoped: `$REPO_ROOT/.agents/plugins/marketplace.json`
```json
{
  "name": "local-repo",
  "plugins": [{
    "name": "ralph-specum-codex",
    "source": {"source": "local", "path": "./plugins/ralph-specum-codex"},
    "policy": {"installation": "AVAILABLE"}
  }]
}
```

Install cache: `~/.codex/plugins/cache/$MARKETPLACE/$PLUGIN/$VERSION/`

### Prior Art

- **gotalab/cc-sdd**: Spec-driven dev toolkit supporting 8 agents (Codex, Claude Code, Cursor, Gemini CLI, etc.). Same codebase adapts via flags. Directly comparable to Ralph Specum.
- **openai/codex-plugin-cc**: Official cross-agent delegation plugin (Claude Code -> Codex).
- **leonardsellem/codex-subagents-mcp**: Subagents (reviewer, debugger, security) exposed via MCP server.

### Pitfalls to Avoid

1. Stop hook is experimental. Design a fallback for when hooks are disabled.
2. `PreToolUse`/`PostToolUse` only intercept Bash. Cannot guard file edits.
3. No plugin-native state API. All state via file system.
4. `max_depth = 1` prevents recursive agent fan-out. Keep orchestration flat.

## Codebase Analysis

### Claude Plugin Feature Inventory (v4.9.1)

**14 commands**: start, new, research, requirements, design, tasks, implement, cancel, status, switch, triage, refactor, index, feedback, help

**9 agents**: research-analyst, product-manager, architect-reviewer, task-planner, spec-executor, spec-reviewer, qa-engineer, refactor-specialist, triage-analyst

**5 skills**: communication-style, interview-framework, reality-verification, smart-ralph, spec-workflow

**3 hooks**: PreToolUse (quick-mode-guard), Stop (stop-watcher), SessionStart (load-spec-context)

**10 templates**: research, requirements, design, tasks, progress, epic, component-spec, external-spec, index-summary, settings-template + 2 prompt templates

**15 references**: branch-management, commit-discipline, coordinator-pattern, failure-recovery, goal-interview, intent-classification, parallel-research, phase-rules, quality-checkpoints, quality-commands, quick-mode, sizing-rules, spec-scanner, triage-flow, verification-layers

**1 schema**: spec.schema.json (master JSON Schema for all state files)

### Existing Codex Platform (v4.8.4)

15 skills mirroring Claude commands, 4 references (workflow, state-contract, path-resolution, parity-matrix), 3 Python scripts, bootstrap assets, no plugin wrapper.

### Key Gaps (Codex Behind Claude)

| Gap | Severity | Detail |
|-----|----------|--------|
| No plugin wrapper | High | Missing `.codex-plugin/plugin.json` |
| No marketplace entry | High | Missing `.agents/plugins/marketplace.json` |
| Missing agents (qa-engineer, refactor-specialist, spec-reviewer) | Medium | Added in Claude after last Codex sync |
| tasks.md template diverged (588 vs 192 lines) | Medium | Missing task writing guide, TDD workflow |
| No verification layers | Medium | Claude has 3-layer protocol, Codex has none |
| No failure recovery docs | Medium | No retry/recovery behavior documented |
| No epic.md template | Low | Codex documents epic state but has no template |
| settings-template.md diverged (79 vs 24 lines) | Low | Missing extended docs |
| No intent classification | Low | Codex always uses POC-first |

### Codex-Specific Features to Preserve

- Python helper scripts (resolve_spec_paths.py, merge_state.py, count_tasks.py)
- openai.yaml agent metadata files
- `allow_implicit_invocation: false` gate
- Bootstrap assets (AGENTS.md, ralph-specum.local.md)
- Parity matrix reference

## Quality Commands

| Type | Command | Framework |
|------|---------|-----------|
| Test | `bats tests/*.bats` | BATS (Bash Automated Testing) |
| Codex tests | `bats tests/codex-platform.bats` | Tests skill structure, frontmatter, manifest |
| Codex script tests | `bats tests/codex-platform-scripts.bats` | Tests Python helper scripts |
| CI | `.github/workflows/bats-tests.yml` | Runs on push/PR to plugins/ or tests/ |
| CI | `.github/workflows/codex-version-check.yml` | Enforces version bump on platforms/codex/ changes |
| CI | `.github/workflows/plugin-version-check.yml` | Enforces version bump on plugins/ changes |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Plugin structure | High feasibility | Codex plugin format is well-documented, similar to Claude plugin |
| Skill migration | High feasibility | SKILL.md format is cross-platform, 15 skills already exist |
| Agent definitions | Medium feasibility | Need TOML conversion from markdown agents |
| Execution loop | Medium-High risk | Stop hook is experimental, behind feature flag |
| State management | High feasibility | File-based state carries over directly |
| Testing | High feasibility | BATS framework already in use, just update paths |
| Marketplace | High feasibility | Simple JSON entry |

## Recommendations for Requirements

1. Create `plugins/ralph-specum-codex/` with proper `.codex-plugin/plugin.json` manifest
2. Migrate all 15 skills from `platforms/codex/skills/` to `plugins/ralph-specum-codex/skills/`
3. Close content gaps: sync tasks.md template, add missing agent guidance, add epic.md template
4. Create custom agent TOML definitions for key agents (spec-executor, research-analyst, etc.)
5. Add Stop hook configuration for execution loop (with fallback guidance for when hooks are disabled)
6. Create `.agents/plugins/marketplace.json` for repo-scoped distribution
7. Update tests: new BATS file for the plugin, update CI workflows
8. Remove `platforms/codex/` after verification
9. Sync version to 4.9.1

## Open Questions

1. Should the Codex plugin support intent classification (TDD vs POC-first)? Or keep the deliberate simplification?
2. How to handle the execution loop fallback when Stop hooks are disabled?
3. Should custom agent TOMLs be bundled in the plugin or placed in `.codex/agents/`?
4. Should the parity matrix reference be preserved in the new plugin structure?

## Sources

### External
- https://developers.openai.com/codex/plugins
- https://developers.openai.com/codex/plugins/build
- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/hooks
- https://developers.openai.com/codex/config-reference
- https://agentskills.io
- https://github.com/openai/codex-plugin-cc
- https://github.com/openai/skills
- https://github.com/gotalab/cc-sdd

### Internal
- `plugins/ralph-specum/.claude-plugin/plugin.json` (v4.9.1)
- `platforms/codex/manifest.json` (v4.8.4)
- `platforms/codex/README.md`
- `platforms/codex/skills/ralph-specum/references/parity-matrix.md`
- `tests/codex-platform.bats`
- `tests/codex-platform-scripts.bats`
- `.github/workflows/bats-tests.yml`
- `.github/workflows/codex-version-check.yml`
