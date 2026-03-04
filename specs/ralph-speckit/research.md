---
spec: ralph-speckit
phase: research
created: 2026-01-14T00:00:00Z
---

# Research: ralph-speckit

## Executive Summary

This research analyzes GitHub's spec-kit methodology and the existing ralph-specum plugin architecture to inform the development of ralph-speckit. The spec-kit approach introduces a constitution-first paradigm that treats specifications as the source of truth, inverting the traditional code-first development model. The ralph-speckit plugin will adapt these principles while maintaining the proven task-by-task execution loop from ralph-specum.

## External Research

### GitHub Spec-Kit Methodology

**Source**: [GitHub Spec-Kit Repository](https://github.com/github/spec-kit) | [GitHub Blog Article](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) | [Martin Fowler's Analysis](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)

#### Core Philosophy: Intent as Source of Truth

Spec-driven development (SDD) inverts the traditional power structure where code was king. As GitHub describes it: "Specifications don't serve code - code serves specifications." The methodology treats natural language specifications as executable artifacts that generate implementation.

#### Six Core Principles (from spec-driven.md)

1. **Specifications as Lingua Franca**: Specifications become the primary artifact; code becomes their expression
2. **Executable Specifications**: Requirements must be precise, complete, and unambiguous enough to generate working systems
3. **Continuous Refinement**: Consistency validation occurs continuously rather than as one-time approval gates
4. **Research-Driven Context**: Investigation gathers technical options and constraints throughout the process
5. **Bidirectional Feedback**: Production metrics inform future specification evolution
6. **Branching for Exploration**: Generate multiple implementation approaches from single specifications

#### Constitutional Foundation

Spec-kit introduces a "constitution" concept - project-level immutable principles that govern all development. Key constitutional articles include:

- **Library-First Principle**: Features begin as standalone, reusable components
- **CLI Interface Mandate**: All functionality exposes through command-line interfaces
- **Test-First Imperative**: Tests written and approved before implementation
- **Simplicity**: Maintain minimal project structure
- **Anti-Abstraction**: Use frameworks directly rather than wrapping them
- **Integration-First Testing**: Prefer real databases and services over mocks

#### Workflow Phases

| Phase | Command | Purpose |
|-------|---------|---------|
| Constitution | `/speckit.constitution` | Define governing principles (project-level, persistent) |
| Specify | `/speckit.specify` | Define WHAT and WHY (user stories, requirements) |
| Clarify (optional) | `/speckit.clarify` | Structured requirement validation |
| Plan | `/speckit.plan` | Technical architecture with chosen stack |
| Tasks | `/speckit.tasks` | Actionable breakdown by user story |
| Analyze (optional) | `/speckit.analyze` | Cross-artifact consistency check |
| Implement | `/speckit.implement` | Execute tasks sequentially |

#### Directory Structure (from spec-kit)

```
.specify/
  memory/
    constitution.md           # Project-level principles (persistent)
  scripts/                    # Helper scripts
  specs/
    [FEATURE-NUMBER]-[NAME]/  # e.g., 001-create-taskify
      spec.md                 # Requirements (WHAT/WHY)
      plan.md                 # Technical design (HOW)
      tasks.md                # Implementation tasks
      research.md             # Technical research
      contracts/              # API specs, schemas
  templates/                  # Document templates
```

### Key Differentiators from Ralph-Specum

| Aspect | Ralph-Specum | Spec-Kit/Ralph-SpecKit |
|--------|--------------|------------------------|
| Starting Point | Research phase | Constitution first |
| Directory | `./specs/<name>/` | `.speckit/specs/<id>-<name>/` |
| Memory | Per-spec in .progress.md | Project-level constitution.md |
| Feature ID | None | Numeric prefix (001, 002) |
| Research | Dedicated phase | Embedded in plan phase |
| Optional Phases | None | clarify, analyze, checklist |
| Phase Order | research > requirements > design > tasks | constitution > specify > plan > tasks |
| Focus | POC-first, 4-phase workflow | What/Why before How |

### Best Practices Discovered

1. **Separation of Intent and Implementation**: Human engineers define "what" and "why"; AI handles "how"
2. **Template-Driven Quality**: Templates enforce abstraction levels and completeness checklists
3. **Uncertainty Markers**: Explicit `[NEEDS CLARIFICATION]` tags prevent plausible assumptions
4. **Constitutional Compliance Gates**: Pre-implementation validation against principles
5. **Test-First Enforcement**: Contracts defined, tests written, tests confirmed failing before implementation

### Pitfalls to Avoid

1. **Premature Implementation Details**: Spec phase should focus on WHAT, not HOW
2. **Speculative Features**: All features must trace to concrete user stories
3. **Skipping Constitution**: Project principles must be defined before features
4. **Over-Abstraction**: Use frameworks directly rather than adding layers

## Codebase Analysis

### Existing Ralph-Specum Patterns

**Path**: `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/`

#### Plugin Structure

```
plugins/ralph-specum/
  .claude-plugin/plugin.json    # Manifest with name, version, description
  agents/                       # 7 agents: research-analyst, product-manager,
                               # architect-reviewer, task-planner, spec-executor,
                               # qa-engineer, plan-synthesizer
  commands/                     # 10 commands: start, research, requirements, design,
                               # tasks, implement, status, switch, cancel, help
  hooks/
    hooks.json                 # Stop hook configuration
    scripts/stop-handler.sh    # Core loop logic
  templates/                   # 5 templates: progress, research, requirements,
                               # design, tasks
  schemas/spec.schema.json     # JSON schema for state and document structure
```

#### Stop-Handler Pattern (Critical)

The stop-handler.sh at `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/hooks/scripts/stop-handler.sh` implements:

1. Reads `.current-spec` to get active spec name
2. Reads `.ralph-state.json` for execution state
3. Extracts last assistant message from transcript
4. Verifies `TASK_COMPLETE` signal
5. Advances `taskIndex` or retries with incremented `taskIteration`
6. Returns JSON: `{"decision": "block", "reason": "...", "systemMessage": "..."}`
7. Cleanup: Deletes state file and current-spec pointer on completion

**Key adaptation for speckit**: Change paths from `./specs/$CURRENT_SPEC/.ralph-state.json` to `.speckit/specs/$CURRENT_FEATURE/.speckit-state.json`

#### Agent Patterns

All agents follow this structure:

```markdown
---
name: agent-name
description: Description
tools: [list of allowed tools]
---

[System prompt with role definition]

## When Invoked
[Step-by-step workflow]

## Append Learnings
[Mandatory section for knowledge capture]

## Output Format
[Expected output structure]

## Final Step: Set Awaiting Approval
[State file update for phase completion]
```

#### Command Patterns

Commands follow this structure:

```markdown
---
description: What the command does
argument-hint: [expected arguments]
allowed-tools: [Read, Write, Bash, Task, etc.]
---

# Command Name

[Description]

## CRITICAL: Delegation Requirement
[Mandatory - commands coordinate, agents implement]

## Workflow
[Step-by-step logic]

## Output
[Expected output format]
```

#### State File Schema

From `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/schemas/spec.schema.json`:

```json
{
  "source": "spec|plan|direct",
  "name": "kebab-case-name",
  "basePath": "./specs/name",
  "phase": "research|requirements|design|tasks|execution",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "awaitingApproval": false
}
```

**Adaptation for speckit**: Add `featureId` field, change phases to `constitution|specify|plan|tasks|execution`

### Dependencies

The plugin uses Claude Code's built-in capabilities:
- **Task tool**: For delegating to subagents
- **Read/Write/Edit tools**: For file operations
- **Bash tool**: For command execution
- **Glob/Grep tools**: For codebase search
- **WebSearch/WebFetch**: For external research

No external npm/python dependencies required.

### Constraints

1. **No build step**: Plugin is markdown-based, changes take effect on Claude Code restart
2. **Hook system**: Uses Claude Code's stop hook for task loop
3. **State persistence**: JSON files in spec directory
4. **Transcript verification**: Stop handler reads transcript to verify completion signal

## Related Specs

No other specs found in `/Users/zachbonfil/projects/smart-ralph-speckit/specs/` (only `.current-spec` pointer file exists).

## Quality Commands

This is a Claude Code plugin project with no traditional build tooling:

| Type | Command | Source |
|------|---------|--------|
| Lint | Not applicable | Plugin is markdown-based |
| TypeCheck | Not applicable | No TypeScript |
| Test | Manual testing via Claude Code | Test with `claude --plugin-dir ./plugins/ralph-speckit` |
| Build | Not applicable | No build step |

**Local Verification**: Test plugin by running Claude Code with `--plugin-dir` flag and invoking commands.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | **High** | Clear adaptation path from ralph-specum patterns |
| Effort Estimate | **M-L** | ~30-40 files to create across agents, commands, templates, hooks |
| Risk Level | **Low** | Well-defined source (spec-kit) and reference (ralph-specum) |

### Complexity Breakdown

1. **Infrastructure** (Low effort): plugin.json, hooks.json, stop-handler.sh
2. **Templates** (Low effort): 6 templates following spec-kit format
3. **Agents** (Medium effort): 8 agents with detailed prompts
4. **Commands** (Medium effort): 12+ commands with logic
5. **Schema** (Low effort): Adapted from ralph-specum

## Recommendations for Requirements

### Must Have

1. **Constitution as First-Class Citizen**: Project-level constitution.md that persists across features
2. **Feature ID System**: Auto-incrementing numeric prefixes (001, 002, etc.)
3. **Adapted Directory Structure**: `.speckit/specs/<id>-<name>/` pattern
4. **Spec-Kit Phases**: constitution > specify > plan > tasks > implement
5. **Stop-Handler Adaptation**: Modified paths for speckit state files
6. **TASK_COMPLETE Protocol**: Maintain proven completion verification

### Should Have

1. **Optional Clarify Phase**: Structured requirement clarification
2. **Optional Analyze Phase**: Cross-artifact consistency checks
3. **Quality Checklist Generation**: From spec-kit's /speckit.checklist pattern
4. **Research Embedded in Plan**: Not as separate phase

### Could Have

1. **Migration Path from Ralph-Specum**: Command aliases or conversion tool
2. **Multiple Tech Stack Support**: Parallel planning for different stacks
3. **Constitution Versioning**: Track constitution changes over time

### Won't Have (Out of Scope)

1. **Full spec-kit CLI integration**: Plugin operates independently
2. **Python/uv dependencies**: Stay pure markdown/bash
3. **External database**: File-based state only

## Open Questions

1. **Constitution Initialization**: Should `/speckit:start` auto-prompt for constitution if none exists, or require explicit `/speckit:constitution` first?

2. **Feature ID Format**: Should IDs be 001, 002, or allow custom prefixes like sprint-001?

3. **Quick Mode**: Should ralph-speckit support `--quick` flag like ralph-specum for skipping phases?

4. **Branch Naming**: Spec-kit uses `<id>-<name>` for branches. Should we keep `feat/<id>-<name>` pattern for consistency with git conventions?

5. **Backward Compatibility**: Should speckit be able to read/migrate existing ralph-specum specs?

## Sources

### Official Documentation
- [GitHub Spec-Kit Repository](https://github.com/github/spec-kit)
- [GitHub Spec-Kit spec-driven.md](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [GitHub Blog: Spec-driven development with AI](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)

### Analysis Articles
- [Martin Fowler: Understanding Spec-Driven-Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- [Microsoft Developer Blog: Diving Into Spec-Driven Development](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [LogRocket: Exploring spec-driven development](https://blog.logrocket.com/github-spec-kit/)

### Codebase Files
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/.claude-plugin/plugin.json`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/hooks/scripts/stop-handler.sh`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/agents/spec-executor.md`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/agents/qa-engineer.md`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/commands/start.md`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/commands/implement.md`
- `/Users/zachbonfil/projects/smart-ralph-speckit/plugins/ralph-specum/schemas/spec.schema.json`
- `/Users/zachbonfil/projects/smart-ralph-speckit/RALPH-SPECKIT-PLAN.md`
