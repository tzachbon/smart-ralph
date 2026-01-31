---
spec: refactor-plugins
phase: research
created: 2026-01-29
---

# Research: refactor-plugins

## Executive Summary

Analysis of `ralph-specum` and `ralph-speckit` plugins against plugin-dev skills best practices reveals both plugins are functional but have significant gaps. The research used:
1. All plugin-dev skills for best practice patterns
2. Official Claude Code plugins (plugin-dev, feature-dev, hookify, ralph-loop) as reference implementations

**Key findings:**
- **37 total issues** to fix across both plugins
- Agents: Missing `color` field (CRITICAL) and `<example>` blocks in descriptions (CRITICAL)
- Skills: Missing `version` field and some using incorrect description format
- Hooks: Missing `matcher` field in hook entries
- Commands: ralph-speckit has legacy `.claude/commands/` that need migration

## Official Plugin Reference Patterns

### Agent Pattern (from plugin-dev/agents/agent-creator.md)

```markdown
---
name: agent-creator
description: Use this agent when the user asks to "create an agent", "generate an agent", "build a new agent"... Examples:

<example>
Context: User wants to create a code review agent
user: "Create an agent that reviews code for quality issues"
assistant: "I'll use the agent-creator agent to generate the agent configuration."
<commentary>
User requesting new agent creation, trigger agent-creator to generate it.
</commentary>
</example>

model: sonnet
color: magenta
tools: ["Write", "Read"]
---
```

### Skill Pattern (from plugin-dev/skills/*)

```markdown
---
name: Skill Name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", "specific phrase 3". Include exact phrases users would say.
version: 0.1.0
---
```

### Hook Pattern (from ralph-loop/hooks/hooks.json)

```json
{
  "description": "Brief explanation of hooks",
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/script.sh"
          }
        ]
      }
    ]
  }
}
```

**Note:** `matcher` field is optional when hook applies to all events, but official plugins include it explicitly.

### Color Guidelines (from agent-development skill)

| Color | Use For |
|-------|---------|
| blue/cyan | Analysis, review, investigation |
| green | Generation, creation, success-oriented |
| yellow | Validation, warnings, caution |
| red | Security, critical analysis |
| magenta | Transformation, creative, refactoring |

---

## ralph-specum Gap Analysis

### Agents (8 total)

| Agent | color | <example> blocks | Issues |
|-------|-------|------------------|--------|
| research-analyst | MISSING | MISSING | 2 |
| product-manager | MISSING | MISSING | 2 |
| architect-reviewer | MISSING | MISSING | 2 |
| task-planner | MISSING | MISSING | 2 |
| spec-executor | MISSING | MISSING | 2 |
| plan-synthesizer | MISSING | MISSING | 2 |
| qa-engineer | MISSING | MISSING | 2 |
| refactor-specialist | MISSING | MISSING | 2 |

**Total Agent Issues: 16 CRITICAL**

**Recommended colors:**
- research-analyst: `blue` (investigation)
- product-manager: `cyan` (analysis)
- architect-reviewer: `blue` (review)
- task-planner: `cyan` (planning)
- spec-executor: `green` (execution)
- plan-synthesizer: `green` (generation)
- qa-engineer: `yellow` (validation)
- refactor-specialist: `magenta` (transformation)

### Skills (6 total)

| Skill | version | description format | Issues |
|-------|---------|-------------------|--------|
| communication-style | MISSING | OK (third-person) | 1 |
| delegation-principle | MISSING | OK (third-person) | 1 |
| interview-framework | MISSING | WRONG (not third-person) | 2 |
| reality-verification | MISSING | OK (third-person) | 1 |
| smart-ralph | MISSING | OK (third-person) | 1 |
| spec-workflow | MISSING | OK (third-person) | 1 |

**Total Skill Issues: 7 (6 HIGH + 1 CRITICAL)**

### Hooks (hooks/hooks.json)

| Entry | matcher field | Status |
|-------|--------------|--------|
| Stop | MISSING | NEEDS FIX |
| SessionStart | MISSING | NEEDS FIX |

**Total Hook Issues: 2 HIGH**

### Commands (13 total)

Commands follow best practices with proper frontmatter. No issues found.

---

## ralph-speckit Gap Analysis

### Agents (6 total)

| Agent | color | <example> blocks | Issues |
|-------|-------|------------------|--------|
| constitution-architect | MISSING | MISSING | 2 |
| spec-analyst | MISSING | MISSING | 2 |
| qa-engineer | MISSING | MISSING | 2 |
| spec-executor | MISSING | MISSING | 2 |
| plan-architect | MISSING | MISSING | 2 |
| task-planner | MISSING | MISSING | 2 |

**Total Agent Issues: 12 CRITICAL**

### Skills (4 total)

| Skill | version | description format | Issues |
|-------|---------|-------------------|--------|
| communication-style | MISSING | WRONG (not third-person) | 2 |
| delegation-principle | MISSING | WRONG (not third-person) | 2 |
| smart-ralph | MISSING | WRONG (not third-person) | 2 |
| speckit-workflow | MISSING | WRONG (not third-person) | 2 |

**Total Skill Issues: 8 CRITICAL**

### Hooks (hooks/hooks.json)

| Entry | matcher field | Status |
|-------|--------------|--------|
| Stop | MISSING | NEEDS FIX |

**Total Hook Issues: 1 HIGH**

### Commands

**Modern commands (5 in `commands/`):**
| Command | name field | Status |
|---------|-----------|--------|
| start.md | MISSING | NEEDS FIX |
| status.md | MISSING | NEEDS FIX |
| switch.md | MISSING | NEEDS FIX |
| cancel.md | MISSING | NEEDS FIX |
| implement.md | MISSING | NEEDS FIX |

**Legacy commands (9 in `.claude/commands/`):**
- speckit.analyze.md
- speckit.checklist.md
- speckit.clarify.md
- speckit.constitution.md
- speckit.implement.md (DUPLICATE!)
- speckit.plan.md
- speckit.specify.md
- speckit.tasks.md
- speckit.taskstoissues.md

**Total Command Issues: 5 missing name + 9 need migration + 1 duplicate**

---

## Summary of All Issues

| Plugin | Component | Critical | High | Total |
|--------|-----------|----------|------|-------|
| ralph-specum | Agents | 16 | 0 | 16 |
| ralph-specum | Skills | 1 | 6 | 7 |
| ralph-specum | Hooks | 0 | 2 | 2 |
| ralph-speckit | Agents | 12 | 0 | 12 |
| ralph-speckit | Skills | 8 | 0 | 8 |
| ralph-speckit | Hooks | 0 | 1 | 1 |
| ralph-speckit | Commands | 0 | 15 | 15 |
| **TOTAL** | | **37** | **24** | **61** |

---

## Sample Fixes

### Agent Fix Example (research-analyst.md)

**Current:**
```yaml
---
name: research-analyst
description: This agent should be used to "research a feature"...
model: inherit
---
```

**Fixed:**
```yaml
---
name: research-analyst
description: This agent should be used to "research a feature", "analyze feasibility", "explore codebase", "find existing patterns", "gather context before requirements". Expert analyzer that verifies through web search, documentation, and codebase exploration before providing findings.

<example>
Context: User wants to add authentication to their app
user: "I need to add OAuth support"
assistant: "Let me research OAuth best practices and analyze your codebase for existing auth patterns."
<commentary>
Research-analyst is triggered to explore OAuth implementations and codebase patterns before requirements phase.
</commentary>
</example>

<example>
Context: User starting new spec
user: "/ralph-specum:research"
assistant: "Starting research phase. I'll analyze best practices and your codebase."
<commentary>
Research-analyst is explicitly invoked via the research command.
</commentary>
</example>

model: inherit
color: blue
---
```

### Skill Fix Example (interview-framework/SKILL.md)

**Current:**
```yaml
---
name: interview-framework
description: Standard single-question adaptive interview loop used across all spec phases
---
```

**Fixed:**
```yaml
---
name: interview-framework
description: This skill should be used when implementing "interview questions", "adaptive interview loop", "single-question flow", "parameter chain", "question piping", or building interview flows for spec phases.
version: 0.1.0
---
```

### Hooks Fix Example (hooks/hooks.json)

**Current:**
```json
"Stop": [
  {
    "hooks": [...]
  }
]
```

**Fixed:**
```json
"Stop": [
  {
    "matcher": "*",
    "hooks": [...]
  }
]
```

---

## Recommendations for Requirements

### Priority 1: Critical (Must Fix)

1. **Add `color` to all 14 agents** across both plugins
2. **Add `<example>` blocks to all 14 agent descriptions**
3. **Add `matcher` to all hook entries** in both plugins
4. **Fix skill descriptions** to use third-person format with trigger phrases

### Priority 2: High (Should Fix)

5. **Add `version: 0.1.0`** to all 10 skills
6. **Add `name` field** to ralph-speckit commands
7. **Migrate legacy commands** from `.claude/commands/` to `commands/`
8. **Remove duplicate** implement.md in ralph-speckit

### Priority 3: Nice to Have

9. **Enhance plugin.json** with repository, homepage, full author info
10. **Create validation script** to check plugin compliance

---

## Open Questions

1. Should we use unique colors for each agent or group by function?
2. Should we add `tools` restrictions to limit agent access?
3. Should ralph-speckit get a SessionStart hook like ralph-specum?

---

## Sources

### Plugin-Dev Skills
- plugin-structure/SKILL.md - Directory layout, manifest format
- agent-development/SKILL.md - Agent frontmatter requirements
- skill-development/SKILL.md - Skill frontmatter requirements
- hook-development/SKILL.md - Hook configuration format
- command-development/SKILL.md - Command frontmatter format

### Official Plugin References
- plugin-dev/agents/agent-creator.md - Agent with color and examples
- feature-dev/agents/code-architect.md - Agent with tools restriction
- ralph-loop/hooks/hooks.json - Hooks with matcher field
- hookify/skills/writing-rules/SKILL.md - Skill with version

### Analyzed Files
- plugins/ralph-specum/agents/*.md (8 files)
- plugins/ralph-specum/skills/*/SKILL.md (6 files)
- plugins/ralph-specum/hooks/hooks.json
- plugins/ralph-specum/commands/*.md (13 files)
- plugins/ralph-speckit/agents/*.md (6 files)
- plugins/ralph-speckit/skills/*/SKILL.md (4 files)
- plugins/ralph-speckit/hooks/hooks.json
- plugins/ralph-speckit/commands/*.md (5 files)
- plugins/ralph-speckit/.claude/commands/*.md (9 files)
