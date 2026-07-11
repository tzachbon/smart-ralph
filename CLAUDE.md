# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⛔ CRITICAL SAFETY RULES

1. **NEVER merge PRs without explicit user permission** — If unsure whether to merge, the answer is NO
2. **NEVER close PRs without explicit user permission** — Only fix conflicts, push changes, create PRs
3. **NEVER delete branches on remote without explicit user permission**
4. **Ask before any destructive action** — When in doubt, ask the user

## Karpathy Coding Rules

Four rules for all agents and code generation. Non-negotiable.

### 1. Think Before Coding
- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations? Present them, don't pick silently.
- Simpler approach exists? Say so. Push back when warranted.
- Something unclear? Stop. Name what's confusing. Ask.

### 2. Simplicity First
- No features beyond what was asked.
- No abstractions for single-use code.
- No speculative "flexibility" or "configurability".
- 200 lines that could be 50? Rewrite.
- Test: "Would a senior engineer say this is overcomplicated?"

### 3. Surgical Changes
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd do it differently.
- Remove only dead code YOUR changes created.
- Every changed line must trace to the user's request.

### 4. Goal-Driven Execution
- "Add validation" -> Write tests for invalid inputs, make them pass.
- "Fix the bug" -> Write reproducing test, make it pass.
- "Refactor X" -> Ensure tests pass before and after.
- Define success criteria. Loop until verified.

## Overview

Smart Ralph provides native Claude Code and Codex plugins backed by a shared specification core. Both transform feature requests into reviewed research, requirements, design, tasks, and verified implementation while using their own platform-native orchestration.

## Development

```bash
# Test the Claude plugin locally
claude --plugin-dir ./plugins/ralph-specum

# Test the workflow
/ralph-specum:start test-feature Some test goal

# Verify generated shared assets
python3 scripts/sync-core-assets.py --check
```

### Task Granularity

Control task count with `--tasks-size`:

```bash
/ralph-specum:tasks --tasks-size coarse    # 10-20 larger tasks, no intermediate [VERIFY]
/ralph-specum:tasks --tasks-size fine       # 40-60+ small tasks with [VERIFY] checkpoints (default)
/ralph-specum:start my-spec Goal --tasks-size coarse  # Set early, carries through
```

Fine is the default. Coarse reduces token consumption ~3-5x for sequential execution.

> **⚠️ CRITICAL: Version bumps are REQUIRED for ANY plugin change**
>
> When making ANY changes to plugin files (commands, agents, hooks, templates, schemas):
> 1. **ALWAYS bump the version** in BOTH files for the modified plugin:
>    - `plugins/<plugin-name>/.claude-plugin/plugin.json` (the plugin you're modifying)
>    - `.claude-plugin/marketplace.json` (update the corresponding plugin entry)
> 2. Use semantic versioning: patch (fixes), minor (features), major (breaking)
> 3. Bump once per set of related changes (not per commit)
> 4. Only update the version for plugins you actually modified

Shared core changes require `python3 scripts/sync-core-assets.py` and a version bump for both generated plugin packages. Native adapter changes require a version bump only for the modified plugin.

### Plugin Development Skills (ALWAYS USE)

When creating or modifying plugin components, **ALWAYS** use the `plugin-dev` skills for guidance:

- `/plugin-dev:plugin-structure` - Plugin manifest, directory layout, component organization
- `/plugin-dev:command-development` - Creating slash commands with frontmatter
- `/plugin-dev:skill-development` - Creating skills with progressive disclosure
- `/plugin-dev:agent-development` - Creating subagents with system prompts
- `/plugin-dev:hook-development` - Creating hooks (PreToolUse, PostToolUse, Stop, etc.)
- `/plugin-dev:mcp-integration` - Integrating MCP servers into plugins
- `/plugin-dev:plugin-settings` - Plugin configuration with .local.md files
- `/plugin-dev:create-plugin` - Guided end-to-end plugin creation workflow

**Example:** Before adding a new command, run `/plugin-dev:command-development` to ensure correct frontmatter and structure.

## Architecture

### Product Structure

```
core/                            # Canonical artifacts, schemas, rules, validators, fixtures
plugins/ralph-specum/            # Self-contained native Claude Code plugin
plugins/ralph-specum-codex/      # Self-contained native Codex plugin
scripts/sync-core-assets.py      # Generates shared assets into both packages
```

### Execution Flow

1. **Shared phases**: Research, requirements, design, and tasks produce the canonical Markdown artifacts in `./specs/<spec-name>/`.
2. **Claude execution**: Claude commands delegate to Claude agents and may use the Claude Stop hook for explicit autonomous execution.
3. **Codex execution**: Codex phase skills delegate to native subagents. Explicit autonomous execution uses native `/goal`; normal implementation completes one verified logical batch.
4. **Root ownership**: Subagents return evidence and changed files. The root coordinator alone updates shared state and Git.

### State Files

- `./specs/.current-spec` - Local active spec pointer
- `./specs/<name>/progress.md` - Tracked phase, approval, learnings, blockers, and next step
- `./specs/<name>/tasks.md` - Authoritative task completion checkboxes
- `./specs/<name>/.ralph-state.json` - Disposable Claude runtime state when hook continuation is active
- `./specs/.current-epic` - Active epic name
- `./specs/_epics/<name>/.epic-state.json` - Epic progress (which specs are done/pending/blocked)

### Epics (Multi-Spec Orchestration)

Epics decompose large features into multiple dependency-aware specs.

**File structure:**
```
specs/
  .current-epic          # Points to active epic name
  _epics/
    <epic-name>/
      epic.md            # Triage output (vision, specs, dependency graph)
      research.md        # Exploration + validation research
      .epic-state.json   # Progress tracking across specs
      progress.md        # Tracked learnings and decisions
```

**Entry points:**
- `/ralph-specum:triage <goal>` -- create or resume an epic
- `/ralph-specum:start` -- detects active epics, suggests next unblocked spec

**Flow:** Explore (research) -> Brainstorm (triage-analyst) -> Validate (research) -> Finalize (output selection)

### Agents

| Agent | File | Purpose |
|-------|------|---------|
| research-analyst | `agents/research-analyst.md` | Web search, codebase analysis |
| product-manager | `agents/product-manager.md` | User stories, acceptance criteria |
| architect-reviewer | `agents/architect-reviewer.md` | Technical design, architecture |
| task-planner | `agents/task-planner.md` | POC-first task breakdown |
| spec-executor | `agents/spec-executor.md` | Autonomous task implementation |
| triage-analyst | `agents/triage-analyst.md` | Feature decomposition, epic creation |

### POC-First Workflow (Mandatory)

All specs follow 4 phases:
1. **Phase 1: Make It Work** - POC validation, skip tests
2. **Phase 2: Refactoring** - Code cleanup
3. **Phase 3: Testing** - Unit, integration, e2e
4. **Phase 4: Quality Gates** - Lint, types, CI, PR

Quality checkpoints inserted every 2-3 tasks throughout all phases.

### Task Completion Protocol

Subagents return `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. The coordinator validates the result, updates `tasks.md` and `progress.md`, and commits one verified logical batch. A task receives at most three attempts before the workflow stops with a blocker.

### Dependencies

Each v5 plugin is self-contained after installation. The shared core is build-time source material, not a runtime dependency. Claude hooks use `${CLAUDE_PLUGIN_ROOT}`. Codex uses native goals and does not register a Stop hook.

## Key Files

- `core/` - Canonical cross-platform artifact contract
- `plugins/ralph-specum/` - Claude-native commands, agents, and hooks
- `plugins/ralph-specum-codex/` - Codex-native phase skills and subagent coordination
- `scripts/sync-core-assets.py` - Shared asset generation and drift checking
