---
spec: plan-source-feature
phase: research
created: 2026-01-13
---

# Research: plan-source-feature

## Executive Summary

The "plan source" feature allows users to skip spec phases (research, requirements, design) and start directly from task execution using their own plan (file or prompt). This is technically feasible with moderate effort. The schema already defines `source: "plan"` but no implementation exists. The key challenge is auto-generating spec artifacts from a user-provided plan without breaking the existing task-by-task execution loop.

## External Research

### Best Practices

- **Spec-driven development plugins** (cc-sdd, ShipSpec, Spec-Flow, claude-code-spec-workflow) all enforce sequential planning phases. None offer a "skip to tasks" feature from external plans. [GitHub cc-sdd](https://github.com/gotalab/cc-sdd), [Spec-Flow](https://github.com/marcusgoll/Spec-Flow)
- **Planning-execution separation** is considered critical. "Autonomous execution depends entirely on excellent grounding and planning. If you skip those phases, the agent will drift, hallucinate, and produce garbage." [Agentic Coding](https://agenticoding.ai/docs/methodology/lesson-3-high-level-methodology)
- **Plan Mode best practice**: "AI coding usually fails when LLMs are asked to plan and code at the same time. Give them one clearly defined task at a time." [Substack](https://agiinprogress.substack.com/p/mastering-claude-code-plan-mode-the)
- **Minimal planning acceptable** for small tasks: "Writing a new function? Use inline generation." [Medium](https://medium.com/@elisheba.t.anderson/building-with-ai-coding-agents-best-practices-for-agent-workflows-be1d7095901b)

### Prior Art

| Tool | Skip Planning? | External Plan Import? |
|------|----------------|----------------------|
| cc-sdd | No | No |
| ShipSpec | No | No |
| Spec-Flow | `/quick` for minor fixes only | No |
| claude-code-spec-workflow | Manual task selection via `/<name>-task-<id>` | Steering docs only |

No existing tool supports importing an external plan file and auto-generating spec artifacts. This would be a differentiating feature.

### Pitfalls to Avoid

1. **Drift and hallucination** if plan lacks sufficient detail. Auto-generated specs may not accurately represent user intent.
2. **Broken traceability**: Tasks generated from a plan won't have proper `requirements_refs` or `design_refs` unless artificially created.
3. **User expectation mismatch**: Users may expect "no interaction" but still need to verify auto-generated specs are correct.
4. **Incomplete plans**: User plans may lack verify commands, file paths, commit messages. System must fill these gaps or reject incomplete plans.

## Codebase Analysis

### Existing Patterns

**Schema already defines source types** (`/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/schemas/spec.schema.json`):
```json
"source": {
  "type": "string",
  "enum": ["spec", "plan", "direct"],
  "description": "Origin of tasks: spec (full workflow), plan (skip to tasks), direct (manual tasks.md)"
}
```
- `spec`: Current full workflow (research -> requirements -> design -> tasks -> execution)
- `plan`: Intended for "skip to tasks" (not implemented)
- `direct`: Manual tasks.md (not implemented)

**Current state initialization** (`/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/commands/new.md`):
- Always sets `"source": "spec"`
- Always starts at `"phase": "research"` (or requirements with `--skip-research`)

**Stop hook** (`/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/hooks/scripts/stop-handler.sh`):
- Only handles `execution` phase
- Other phases exit early (line 57: `if [[ "$PHASE" != "execution" ]]; then exit 0`)
- No special handling for different `source` values

**Start command** (`/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/commands/start.md`):
- Detection logic checks for existing spec directories
- Resume flow reads `.ralph-state.json` and continues from current phase
- No plan input handling

### Dependencies

| Dependency | Purpose | Relevant to Plan Source |
|------------|---------|------------------------|
| Task tool (subagent) | Invoke specialized agents | Yes, need for auto-generation |
| Bash | File operations, git | Yes |
| jq | JSON parsing in stop-handler | Yes |

### Constraints

1. **Schema is predefined**: Must work within existing state schema, cannot add arbitrary fields without schema update.
2. **Stop hook is shell-based**: Complex logic would require bash scripting or moving to different approach.
3. **Templates assume full workflow**: `requirements.md`, `design.md` templates expect user stories, acceptance criteria, mermaid diagrams. Auto-generation must produce these.
4. **POC-first workflow mandatory**: Task planner enforces 4-phase structure. Auto-generated tasks must follow this.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Schema supports it. Main work is new command + auto-gen logic |
| Effort Estimate | M | 2-4 days. New command, agent prompt engineering, testing |
| Risk Level | Medium | Auto-generated specs may not match user intent. Quality depends on plan detail |

## Recommended Approach

**Extend `/ralph-specum:start` with `--quick` flag.** Single entry point, minimal arguments, smart detection.

### Usage Examples

```bash
# Quick with goal string (AI generates spec name)
/ralph-specum:start "Build auth with JWT" --quick
# -> infers name "jwt-auth", auto-generates all specs, jumps to tasks

# Quick with explicit name
/ralph-specum:start my-feature "Build auth with JWT" --quick

# Quick with file path (auto-detected)
/ralph-specum:start ./my-plan.md --quick
# -> reads file, infers name from content

# Quick with existing plan in spec dir
/ralph-specum:start my-feature --quick
# -> if ./specs/my-feature/plan.md exists, uses it
```

### Smart Detection Logic

```
Input parsing for --quick mode:
    |
    +-- Two args before --quick?
    |   -> First is name, second is goal/file
    |
    +-- One arg before --quick?
        |
        +-- Looks like file path (./ or / or ends .md)?
        |   -> Read file, infer name from content
        |
        +-- Looks like kebab-case name?
        |   -> Use as name, check for existing plan.md
        |
        +-- Otherwise?
            -> Treat as goal string, infer name
```

### File Path Detection

A string is treated as a file path if:
- Starts with `./` or `/`
- Ends with `.md`
- Contains path separators and exists on disk

### Name Inference

When no explicit name provided, AI generates kebab-case name from:
- Goal string content (e.g., "Build auth with JWT" -> "jwt-auth")
- Plan file content (extract main topic/feature)

### Implementation Outline

```
/ralph-specum:start [name] [goal|file] --quick
    |
    v
1. Parse arguments, detect input type
    |
    v
2. If no name: infer from goal/file content
    |
    v
3. Create spec directory, set source="plan"
    |
    v
4. Auto-generate all spec artifacts in one pass:
   - research.md (brief, synthesized)
   - requirements.md (user stories, FR/NFR)
   - design.md (architecture from plan + codebase)
   - tasks.md (POC-first breakdown)
    |
    v
5. Set phase="tasks", show summary
    |
    v
6. User runs /ralph-specum:implement to start execution
```

### Auto-Generation Agent

Create `plan-synthesizer` agent (or extend existing agents) with:
- Input: User plan/goal + codebase context
- Output: All four spec artifacts in one pass
- Constraints: Must follow templates, maintain POC-first structure

## Technical Considerations

### Plan Input Validation

The system should validate plan input before processing:

| Validation | Required? | Handling |
|------------|-----------|----------|
| Non-empty content | Yes | Error if empty |
| Minimum detail level | Recommended | Warn if < 50 words |
| File existence (if path) | Yes | Error if file not found |
| Valid markdown | Optional | Proceed with raw text |

### Auto-Generation Quality

To ensure quality:
1. **Codebase analysis**: Agent should explore existing patterns before generating design.
2. **Explicit assumptions**: Generated specs should mark assumptions derived from plan.
3. **User review prompt**: After generation, prompt user to review before execution.

### State Transitions

```
source: "plan"
phase transitions: init -> tasks -> execution -> done

source: "spec" (current)
phase transitions: research -> requirements -> design -> tasks -> execution -> done
```

The stop hook already allows non-execution phases to exit. For plan source, we set phase directly to "tasks" or "execution" after auto-generation.

### Backwards Compatibility

- Existing specs with `source: "spec"` continue working unchanged.
- New `source: "plan"` specs have different phase flow but same execution loop.
- Progress tracking remains consistent.

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low-quality auto-generated specs | Tasks fail during execution | Medium | Add verification step, user review prompt |
| User plan lacks detail | Incomplete requirements/design | High | Provide plan template, validation, guidance |
| Traceability gaps | Cannot trace tasks to requirements | Medium | Auto-generate IDs, mark as "derived from plan" |
| Scope creep in auto-generation | Agent adds features not in plan | Low | Constrain agent prompt strictly |
| Conflicting patterns from codebase analysis | Design conflicts with existing code | Low | Prioritize existing patterns over new design |

## Recommendations for Requirements

1. **Define plan input formats**: Support both file path and inline prompt. Recommend providing a plan template.
2. **Require verification step**: After auto-generation, display summary and prompt user to proceed or edit.
3. **Mark auto-generated artifacts**: Add frontmatter field `generated: auto` to distinguish from human-written specs.
4. **Allow hybrid workflow**: User can run `/ralph-specum:plan`, review generated specs, then use normal commands to regenerate specific phases.
5. **Keep execution loop unchanged**: Plan source should produce same tasks.md format, enabling reuse of spec-executor agent.

## Open Questions

1. **Should auto-generated specs be editable before execution?** (Recommendation: Yes, allow user to modify before running implement)
2. **What minimum information must a plan contain?** (Recommendation: Goal statement + desired outcome. Everything else can be derived.)
3. **How detailed should auto-generated specs be?** (Recommendation: Functional but abbreviated. Focus on tasks.md quality.)
4. **Should we support structured plan formats (JSON/YAML)?** (Recommendation: Start with markdown/text, add structured formats later.)
5. **What happens if auto-generation fails partway?** (Recommendation: Rollback to clean state, show error, let user retry.)

## Sources

### External
- [cc-sdd GitHub](https://github.com/gotalab/cc-sdd)
- [Spec-Flow GitHub](https://github.com/marcusgoll/Spec-Flow)
- [ShipSpec GitHub](https://github.com/jsegov/shipspec-claude-code-plugin)
- [claude-code-spec-workflow GitHub](https://github.com/Pimzino/claude-code-spec-workflow)
- [Agentic Coding Four-Phase Workflow](https://agenticoding.ai/docs/methodology/lesson-3-high-level-methodology)
- [Claude Code Plan Mode Substack](https://agiinprogress.substack.com/p/mastering-claude-code-plan-mode-the)
- [AI Coding Agent Best Practices Medium](https://medium.com/@elisheba.t.anderson/building-with-ai-coding-agents-best-practices-for-agent-workflows-be1d7095901b)

### Internal
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/schemas/spec.schema.json` (state schema with source enum)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/commands/new.md` (current spec creation)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/commands/start.md` (entry point logic)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/commands/implement.md` (execution entry)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/hooks/scripts/stop-handler.sh` (execution loop)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/agents/spec-executor.md` (task execution)
- `/home/tzachb/Projects/ralph-specum/plugins/ralph-specum/agents/task-planner.md` (task generation)
- `/home/tzachb/Projects/ralph-specum/README.md` (workflow overview)
