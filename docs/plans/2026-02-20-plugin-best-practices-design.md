# Plugin Best Practices Refresh — Design Document

**Date:** 2026-02-20
**Status:** Approved
**Replaces:** PR #79 (feat/refactor-plugins, stale)
**Scope:** Both ralph-specum and ralph-speckit plugins

## Context

PR #79 attempted to apply plugin-dev best practices but became stale (32 commits behind main). The branch had a revert at the end that restored full command/agent content after skill-reference simplification caused issues. This design starts fresh on current main.

## Goals

1. Fix metadata gaps across both plugins (color, version, examples)
2. Extract reusable procedural logic from bloated commands into internal reference files
3. Add superpowers-style task/team patterns (checklists, dispatch templates, sequential review)
4. Keep the `/` command namespace clean — no new user-facing skills

## Non-Goals

- Changing agent behavior or capabilities
- Adding new commands
- Modifying the execution loop mechanics (stop-hook, ralph-state.json)
- Upstream changes to Claude Code plugin system

## Three-Phase Approach

### Phase A: Metadata Compliance

Mechanical frontmatter changes, no behavioral impact.

**Agents (14 total: 8 ralph-specum + 6 ralph-speckit):**
Add `color` field using semantic color scheme:

| Role | Color | Agents |
|------|-------|--------|
| Analysis/Research | `blue` | research-analyst, spec-reviewer, spec-analyst |
| Execution | `green` | spec-executor (both plugins) |
| Planning/Design | `cyan` | architect-reviewer, task-planner, product-manager, plan-architect, constitution-architect |
| Validation/QA | `yellow` | qa-engineer (both plugins) |
| Transformation | `magenta` | refactor-specialist |

**Skills (10 total: 6 ralph-specum + 4 ralph-speckit):**
Add `version: 0.1.0` to all SKILL.md frontmatters.

**Commands:**
Add at least 2 `<example>` blocks to `feedback.md` (only command missing them).

### Phase B: Reference Extraction

Extract reusable procedural logic from the 3 largest commands into a `references/` directory at plugin root. Commands become thin orchestrators that Read reference files on-demand.

**Why references/ instead of skills/:**
- Skills are auto-discovered and shown in the `/` namespace — adding 11 would bloat it
- No `internal` or `hidden` frontmatter field exists in the plugin system
- References are loaded via standard Read tool — no custom mechanisms needed
- Progressive disclosure: reference only loaded when that code path executes

**New directory: `plugins/ralph-specum/references/`**

| Reference File | Source Command | Content |
|---------------|---------------|---------|
| `coordinator-pattern.md` | implement.md | Task delegation via Task tool, state management |
| `failure-recovery.md` | implement.md | Retry logic, fix-task generation, max iteration handling |
| `verification-layers.md` | implement.md | 4-layer verification after each task completion |
| `phase-rules.md` | implement.md | POC/Refactor/Testing/Quality phase behaviors |
| `commit-discipline.md` | implement.md + spec-executor | Commit conventions, message format, when to commit |
| `intent-classification.md` | start.md | Goal type detection (new spec vs resume vs quick) |
| `spec-scanner.md` | start.md | Spec directory discovery, matching, validation |
| `branch-management.md` | start.md | Branch creation, worktree setup, naming conventions |
| `parallel-research.md` | research.md | Multi-agent parallel dispatch for research topics |
| `quality-checkpoints.md` | task-planner agent | [VERIFY] task insertion rules, frequency, content |
| `quality-commands.md` | spec-executor agent | Package.json/Makefile command discovery and usage |

**How commands reference them:**

```markdown
## Execute Task Loop

1. Read `${CLAUDE_PLUGIN_ROOT}/references/coordinator-pattern.md` and follow the delegation pattern
2. On failure: Read `${CLAUDE_PLUGIN_ROOT}/references/failure-recovery.md`
3. After each task: Read `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md`
```

**Target command sizes after extraction:**

| Command | Current Lines | Target Lines | Reduction |
|---------|--------------|-------------|-----------|
| implement.md | 1557 | ~250 | ~84% |
| start.md | 1552 | ~300 | ~81% |
| index.md | 1388 | ~250 | ~82% |
| research.md | 672 | ~150 | ~78% |
| design.md | 508 | ~150 | ~70% |
| tasks.md | 510 | ~150 | ~71% |
| requirements.md | 480 | ~150 | ~69% |
| refactor.md | 333 | ~150 | ~55% |

### Phase C: Task/Team Patterns

Add superpowers-style workflow patterns for progress visibility and quality.

#### C1: Checklist-to-Tasks Pattern

Phase commands define checklists that Claude creates as `TaskCreate` tasks:

```markdown
## Checklist

Create a task for each of these items and complete them in order:

1. Gather context — read spec goal, existing files
2. Run parallel research — dispatch research-analyst agents
3. Synthesize findings — merge results into research.md
4. Review output — invoke spec-reviewer for quality gate
```

This gives users visibility into progress via the task list UI.

Applied to: research.md, requirements.md, design.md, tasks.md, implement.md, refactor.md

#### C2: Subagent Dispatch Templates

**New directory: `plugins/ralph-specum/templates/prompts/`**

Instead of embedding full subagent prompts inline in commands, extract them into template files with placeholders:

| Template | Used By | Placeholders |
|----------|---------|-------------|
| `executor-prompt.md` | implement coordinator | `{SPEC_NAME}`, `{TASK_TEXT}`, `{TASK_INDEX}`, `{CONTEXT}` |
| `reviewer-prompt.md` | implement coordinator | `{SPEC_NAME}`, `{TASK_TEXT}`, `{IMPLEMENTER_REPORT}` |
| `research-prompt.md` | research.md | `{SPEC_NAME}`, `{GOAL}`, `{TOPIC}`, `{EXISTING_SPECS}` |

Commands read templates and fill placeholders before dispatching via Task tool.

#### C3: Sequential Review Pattern

After each task in the implement loop, add a review step:

1. **Executor** completes task → outputs `TASK_COMPLETE`
2. **Reviewer** validates work (spec-reviewer agent) → outputs `REVIEW_PASS` or `REVIEW_FAIL`
3. On `REVIEW_FAIL` → re-dispatch executor with feedback

Configurable: skip review in `--quick` mode, run in normal mode.

## Final Directory Structure

```
plugins/ralph-specum/
├── .claude-plugin/
│   └── plugin.json              # Version bump
├── agents/                      # +color field (8 files)
├── commands/                    # Slimmed orchestrators (14 files)
├── hooks/                       # No changes
├── skills/                      # +version field (6 SKILL.md files)
├── references/                  # NEW: Internal reusable logic (11 files)
│   ├── coordinator-pattern.md
│   ├── failure-recovery.md
│   ├── verification-layers.md
│   ├── phase-rules.md
│   ├── commit-discipline.md
│   ├── intent-classification.md
│   ├── spec-scanner.md
│   ├── branch-management.md
│   ├── parallel-research.md
│   ├── quality-checkpoints.md
│   └── quality-commands.md
├── templates/
│   ├── prompts/                 # NEW: Subagent dispatch templates (3 files)
│   │   ├── executor-prompt.md
│   │   ├── reviewer-prompt.md
│   │   └── research-prompt.md
│   └── *.md                     # Existing spec file templates
└── schemas/                     # No changes
```

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Read tool adds latency vs inline content | Only load references when that code path executes; keep critical-path logic inline if < 50 lines |
| References may drift from commands | Each reference file documents which commands use it; validate during PR review |
| Dispatch template placeholders could break | Templates use clear `{PLACEHOLDER}` syntax with comments; commands validate context before dispatch |
| Sequential review slows execution | Skip review in `--quick` mode; only run in normal mode |
| ralph-speckit also needs updates | Apply same Phase A metadata fixes; Phase B/C are ralph-specum only (ralph-speckit is simpler) |

## Success Criteria

- All 14 agents have `color` field
- All 10 skills have `version` field
- All commands have 2+ example blocks
- implement.md, start.md, index.md each under 300 lines
- 11 reference files created and used by commands
- 3 dispatch template files created
- Phase commands use TaskCreate for progress tracking
- Implement loop includes optional review step
- No new entries in `/` skill namespace
