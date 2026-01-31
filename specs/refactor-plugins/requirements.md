---
spec: refactor-plugins
phase: requirements
created: 2026-01-29
---

# Requirements: Plugin Refactoring to Best Practices

## Goal

Refactor ralph-specum and ralph-speckit plugins to fully comply with plugin-dev skills best practices, fixing 61 identified issues across agents, skills, hooks, and commands.

## User Decisions

| Question | Response |
| -------- | -------- |
| Primary users | Both developers and end users |
| Priority tradeoffs | Prioritize thoroughness over speed |
| Success criteria | Full compliance + documentation (all issues fixed plus validation scripts and docs) |
| Problem statement | Improve all plugins according to plugin-dev skills best practices |
| Constraints | Use only plugin-dev skills to improve all plugins |

---

## User Stories

### US-1: Agent Color and Examples
**As a** plugin developer
**I want** all agents to have proper `color` and `<example>` blocks
**So that** Claude can correctly identify when to invoke each agent

**Acceptance Criteria:**
- [ ] AC-1.1: All 8 ralph-specum agents have `color` field in frontmatter
- [ ] AC-1.2: All 6 ralph-speckit agents have `color` field in frontmatter
- [ ] AC-1.3: All 14 agents have at least 2 `<example>` blocks in description
- [ ] AC-1.4: Each example follows Context/user/assistant/commentary format
- [ ] AC-1.5: Colors match semantic guidelines (blue=analysis, green=execution, yellow=validation, magenta=transformation)

### US-2: Skill Version and Description Format
**As a** plugin user
**I want** skills to have proper version and trigger-phrase descriptions
**So that** Claude correctly identifies when to use each skill

**Acceptance Criteria:**
- [ ] AC-2.1: All 6 ralph-specum skills have `version: 0.1.0` field
- [ ] AC-2.2: All 4 ralph-speckit skills have `version: 0.1.0` field
- [ ] AC-2.3: All skill descriptions use third-person format ("This skill should be used when...")
- [ ] AC-2.4: All skill descriptions include at least 3 trigger phrases in quotes
- [ ] AC-2.5: interview-framework skill description is rewritten in correct format

### US-3: Hook Matcher Fields
**As a** plugin developer
**I want** all hook entries to have explicit `matcher` field
**So that** hook configuration matches official plugin patterns

**Acceptance Criteria:**
- [ ] AC-3.1: ralph-specum hooks.json Stop entry has `matcher: "*"`
- [ ] AC-3.2: ralph-specum hooks.json SessionStart entry has `matcher: "*"`
- [ ] AC-3.3: ralph-speckit hooks.json Stop entry has `matcher: "*"`

### US-4: Command Migration and Fixes
**As a** ralph-speckit user
**I want** all commands consolidated in `commands/` with proper frontmatter
**So that** the plugin follows standard structure

**Acceptance Criteria:**
- [ ] AC-4.1: All 5 modern ralph-speckit commands have `name` field
- [ ] AC-4.2: All 9 legacy commands migrated from `.claude/commands/` to `commands/`
- [ ] AC-4.3: Duplicate implement.md resolved (keep one, remove other)
- [ ] AC-4.4: Legacy `.claude/commands/` directory removed
- [ ] AC-4.5: Migrated commands have proper frontmatter (name, description, allowed_tools)

### US-5: Validation and Documentation
**As a** plugin maintainer
**I want** validation scripts and updated documentation
**So that** future changes maintain compliance

**Acceptance Criteria:**
- [ ] AC-5.1: Validation script checks all agents have `color` field
- [ ] AC-5.2: Validation script checks all agents have `<example>` blocks
- [ ] AC-5.3: Validation script checks all skills have `version` field
- [ ] AC-5.4: Validation script checks all hooks have `matcher` field
- [ ] AC-5.5: CLAUDE.md updated with best practices reference

---

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Add `color` field to all 14 agents | P0 | Agents render with semantic colors |
| FR-2 | Add `<example>` blocks to all 14 agent descriptions | P0 | Each agent has 2+ examples with correct format |
| FR-3 | Fix skill descriptions to third-person format | P0 | All descriptions start with "This skill should be used when" |
| FR-4 | Add `version: 0.1.0` to all 10 skills | P1 | All skills report version in metadata |
| FR-5 | Add `matcher: "*"` to all hook entries | P1 | Hook config matches official patterns |
| FR-6 | Add `name` field to 5 ralph-speckit commands | P1 | Commands register with correct names |
| FR-7 | Migrate 9 legacy commands to `commands/` | P1 | All commands in standard location |
| FR-8 | Remove duplicate implement.md | P1 | Only one implement command exists |
| FR-9 | Create validation script | P2 | Script exits non-zero on compliance failures |
| FR-10 | Update CLAUDE.md documentation | P2 | Best practices documented |

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Backward compatibility | Breaking changes | 0 breaking changes to existing workflows |
| NFR-2 | Validation speed | Script runtime | < 5 seconds |
| NFR-3 | Code consistency | Style | Match official plugin-dev patterns exactly |

---

## Glossary

- **Agent**: Subagent definition (markdown file in `agents/`) invoked via Task tool
- **Skill**: Contextual knowledge (markdown in `skills/*/SKILL.md`) auto-loaded when relevant
- **Hook**: Event-driven action (JSON in `hooks/hooks.json`) triggered on lifecycle events
- **Command**: Slash command (markdown in `commands/`) invoked by user
- **Matcher**: Hook field specifying which events trigger the hook (`*` = all)
- **Frontmatter**: YAML metadata block at top of markdown files (between `---` markers)
- **Third-person description**: Format starting with "This skill/agent should be used when..."

---

## Out of Scope

- Adding new agents, skills, or commands
- Changing agent behavior or prompts beyond frontmatter fixes
- Adding `tools` restrictions to agents (noted in research but not required)
- Adding SessionStart hook to ralph-speckit (optional enhancement)
- Enhancing plugin.json with repository/homepage fields (nice-to-have)
- Performance optimization of plugins
- CI/CD integration of validation script

---

## Dependencies

- plugin-dev skills must be available for reference patterns
- Both plugins must be in working state before refactor
- No external service dependencies

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking agent triggering | High | Medium | Test each agent after color/example changes |
| Legacy command loss | High | Low | Backup before migration, verify all commands work |
| Skill trigger regression | Medium | Low | Test skill matching after description changes |

---

## Success Criteria

1. All 61 identified issues resolved
2. Validation script passes for both plugins
3. No regressions in existing plugin functionality
4. Both plugins match official plugin-dev patterns

---

## Unresolved Questions

- Should colors be unique per agent or grouped by function? (Recommendation: group by function per research.md)
- Should ralph-speckit get SessionStart hook? (Out of scope for this refactor)

---

## Next Steps

1. Run `/ralph-specum:design` to create technical design for implementation
2. Define file-by-file change plan for each component type
3. Create task breakdown with quality checkpoints
