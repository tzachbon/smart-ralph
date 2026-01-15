---
spec: goal-interview
phase: research
created: 2026-01-15
---

# Research: goal-interview

## Executive Summary

This spec aims to add exhaustive user interviews to the Ralph Specum workflow using Claude Code's AskUserQuestion tool. The primary challenge is that AskUserQuestion is NOT available in subagents (Task tool), meaning interviews must occur at the coordinator level (commands), not within agents. The solution requires restructuring how phases work: commands must conduct interviews BEFORE delegating to subagents, passing gathered context to agents for synthesis.

## External Research

### AskUserQuestion Tool Capabilities

**Sources**: [Claude Code System Prompts](https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/tool-description-askuserquestion.md), [SmartScope Blog](https://smartscope.blog/en/generative-ai/claude/claude-code-askuserquestion-tool-guide/)

- Supports 1-4 questions per call with 2-4 options each
- Users can always select "Other" for custom text input
- Set `multiSelect: true` to allow multiple selections
- Place recommended options first with "(Recommended)" label
- 60-second timeout per call
- **Critical**: NOT available in subagents spawned via Task tool

**Use Cases**:
1. Gather preferences and requirements
2. Clarify ambiguous instructions
3. Get decisions on implementation choices
4. Offer directional alternatives

### Requirements Elicitation Best Practices

**Sources**: [Bridging the Gap](https://www.bridging-the-gap.com/what-questions-do-i-ask-during-requirements-elicitation/), [SEI CMU](https://www.sei.cmu.edu/blog/eliciting-and-analyzing-unstated-requirements/)

**Framework**: How, Where, When, Who, What, Why questions
- "What assumptions am I making about this feature?"
- "What if [alternative scenario] happens?"
- "What other questions should I be asking?" (yields unexpected insights)
- "Why?" as versatile follow-up (from vague to specific, symptom to cause)

**KJ Method** for unstated requirements:
1. Evaluate existing knowledge
2. Design open-ended probing questions
3. Conduct interviews
4. Analyze output for context/need statements
5. Affinitize responses
6. Identify unstated needs
7. Kano analysis (must-haves, satisfiers, delighters)

**Key Insight**: "People don't know what they want until you show it to them" - users may sense problems but not explicitly recognize them as addressable issues.

### Interview Convergence Pattern

**Sources**: [Teaching Agile](https://teachingagile.com/sdlc/requirement-analysis/effective-requirements-gathering-techniques-and-tips), [Requirements Gathering GeeksforGeeks](https://www.geeksforgeeks.org/software-engineering/requirements-gathering-introduction-processes-benefits-and-tools/)

- Requirements gathering is inherently iterative
- Continue probing until requirements stabilize
- Use prototypes/examples to surface hidden assumptions
- Iterative engagement builds rapport and understanding

### Pitfalls to Avoid

- Putting users in defensive position with direct "why" questions
- Treating AI output as final without verification
- Skipping verification of assumptions
- Groupthink in interview design
- Ignoring non-verbal cues (N/A for text-based interviews)

## Codebase Analysis

### Current Architecture

**Location**: `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/`

**Workflow Flow**:
```
Command (coordinator) --> Task tool --> Agent (subagent)
     |                                      |
     +-- Has AskUserQuestion               +-- NO AskUserQuestion
```

### Existing Tools Field Usage

**Agents with "tools" field** (to be removed):
| File | Current tools | Notes |
|------|---------------|-------|
| `agents/research-analyst.md` | `tools: [Read, Write, Edit, Glob, Grep, WebFetch, WebSearch, Task]` | Line 5 |
| `agents/product-manager.md` | `tools: [Read, Write, Edit, Glob, Grep, WebSearch, Task]` | Line 5 |
| `agents/architect-reviewer.md` | `tools: [Read, Write, Edit, Bash, Glob, Grep, Task]` | Line 5 |
| `agents/task-planner.md` | `tools: [Read, Write, Edit, Glob, Grep, Task]` | Line 5 |
| `agents/plan-synthesizer.md` | `tools: [Read, Write, Edit, Glob, Grep, Task]` | Line 6 |
| `agents/spec-executor.md` | No tools field | Already correct |

**Commands with "allowed-tools" field** (correct pattern):
| File | allowed-tools | Notes |
|------|---------------|-------|
| `commands/research.md` | `[Read, Write, Task, Bash]` | Line 4 |
| `commands/requirements.md` | `[Read, Write, Task, Bash]` | Line 4 |
| `commands/design.md` | `[Read, Write, Task, Bash]` | Line 4 |
| `commands/tasks.md` | `[Read, Write, Task, Bash]` | Line 4 |
| `commands/implement.md` | `[Read, Write, Edit, Task, Bash]` | Line 4 |
| `commands/start.md` | `[Read, Write, Bash, Task, AskUserQuestion]` | Line 5, includes AskUserQuestion |
| `commands/new.md` | `[Bash, Write, Task, AskUserQuestion]` | Line 4, includes AskUserQuestion |
| `commands/status.md` | `[Read, Bash, Glob, Task]` | Line 4 |
| `commands/cancel.md` | `[Read, Bash, Task]` | Line 4 |
| `commands/switch.md` | `[Read, Write, Bash, Glob, Task]` | Line 4 |

**Observation**: Only `start.md` and `new.md` currently have AskUserQuestion in allowed-tools. To implement interviews in all phases, commands need AskUserQuestion added.

### Current AskUserQuestion Usage

**In `commands/new.md`** (lines 26-31):
```markdown
<mandatory>
The goal MUST be captured before proceeding:
1. If goal text was provided in arguments, use it
2. If NO goal text provided, use AskUserQuestion to ask:
   "What is the goal for this spec? Describe what you want to build or achieve."
3. Store the goal verbatim in .progress.md under "Original Goal"
</mandatory>
```

**In `commands/start.md`** (lines 48-88):
- Branch strategy questions (1-3 options for default/non-default branches)

Current usage is minimal and focused on logistics, not requirements elicitation.

### Delegation Pattern

Commands follow a strict coordinator pattern:
1. Parse arguments
2. Validate state
3. Gather minimal context
4. Delegate ALL work to subagents via Task tool
5. Update state after subagent returns

This pattern must be extended: commands should conduct interviews BEFORE delegation, then pass interview results to subagents.

### Dependencies

- Task tool for subagent delegation (existing)
- AskUserQuestion tool (needs to be added to more commands)
- State file `.ralph-state.json` for tracking interview progress
- `.progress.md` for storing interview results

### Constraints

1. **AskUserQuestion not in subagents**: This is the primary architectural constraint. Interviews MUST happen in commands, not agents.

2. **60-second timeout**: Long interview sessions need multiple AskUserQuestion calls.

3. **1-4 questions per call, 2-4 options each**: Must batch questions strategically.

4. **Quick mode should skip interviews**: The `--quick` flag should bypass interactive interviews.

## Related Specs

| Spec | Relevance | Relationship | mayNeedUpdate |
|------|-----------|--------------|---------------|
| add-skills-doc | Low | Tangential - SKILL.md files for command discovery | false |
| plan-source-feature | Medium | Added --quick mode which should skip interviews | false |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | AskUserQuestion exists, just needs integration at command level |
| Effort Estimate | M | 5-6 agent files to modify, 4 command files to extend |
| Risk Level | Medium | Timeout handling, interview convergence logic complexity |

## Implementation Strategy

### Phase-Specific Interview Questions

**Research Phase** (discover unknowns):
- Technical implementation preferences
- Similar systems user has experience with
- Known constraints or limitations
- Success criteria beyond the obvious

**Requirements Phase** (clarify expectations):
- User types and personas
- Edge cases and error scenarios
- Priority tradeoffs
- Non-functional requirements (performance, security)

**Design Phase** (validate approach):
- Architecture preferences
- Technology constraints
- Integration requirements
- UI/UX preferences (if applicable)

**Tasks Phase** (confirm execution plan):
- Testing requirements
- Deployment considerations
- Quality gate thresholds

### Interview Workflow Pattern

```
Command receives invocation
    |
    v
Read existing context (.progress.md, previous phase files)
    |
    v
Determine interview questions based on:
  - Phase type
  - Goal complexity
  - Missing information gaps
    |
    v
[Interview Loop]
  |
  +-> AskUserQuestion(questions)
  |       |
  |       v
  |   Process responses
  |       |
  |       v
  |   Identify follow-up needs
  |       |
  |       +-- More questions needed? --> Loop
  |       |
  |       +-- Requirements converged? --> Exit loop
    |
    v
Store interview results in .progress.md
    |
    v
Delegate to subagent with full context
```

### Convergence Criteria

Interview should continue until:
1. User explicitly says "done" or "that's all"
2. No new significant information in last 2 responses
3. All predefined question categories covered
4. Maximum iteration count reached (configurable, suggest 5)

### State Tracking

Add to `.ralph-state.json`:
```json
{
  "interviewState": {
    "questionsAsked": 12,
    "categoriesCovered": ["technical", "ux", "constraints"],
    "convergenceScore": 0.8,
    "lastNewInfo": "2026-01-15T10:30:00Z"
  }
}
```

## Recommendations for Requirements

1. **Interview in Commands, Not Agents**: Due to AskUserQuestion limitation in subagents, interviews must be conducted at command level before delegation.

2. **Phase-Specific Question Sets**: Define question templates for each phase (research, requirements, design, tasks) focusing on different aspects.

3. **Convergence Detection**: Implement heuristic to detect when interview has gathered sufficient information (user signals completion, no new info, categories covered).

4. **Quick Mode Bypass**: Ensure `--quick` flag skips all interactive interviews.

5. **Context Accumulation**: Store interview results in `.progress.md` so subsequent phases can reference earlier answers.

6. **Remove "tools" from Agents**: Delete the `tools:` frontmatter line from all agent files (5 files affected).

7. **Add AskUserQuestion to Phase Commands**: Add AskUserQuestion to allowed-tools for research.md, requirements.md, design.md, tasks.md.

## Open Questions

1. **Timeout Handling**: How to handle 60-second timeout gracefully? Suggest auto-selecting "(Recommended)" option if user doesn't respond.

2. **Interview Length**: Should there be a maximum number of questions per phase? Suggest 8-12 questions maximum to avoid fatigue.

3. **Resumability**: If session disconnects mid-interview, how to resume? State file should track progress.

4. **Question Templating**: Should questions be stored in separate template files or inline in commands?

## Files to Modify

### Agents (remove "tools" field):
1. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/research-analyst.md`
2. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/product-manager.md`
3. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/architect-reviewer.md`
4. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/task-planner.md`
5. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/plan-synthesizer.md`

### Commands (add AskUserQuestion + interview logic):
1. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/commands/research.md`
2. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/commands/requirements.md`
3. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/commands/design.md`
4. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/commands/tasks.md`

### Templates (new files):
1. `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/templates/interview-questions.md` (optional, for question templates)

## Sources

- [Claude Code AskUserQuestion Tool Guide](https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/tool-description-askuserquestion.md)
- [SmartScope: Claude Code AskUserQuestion Guide](https://smartscope.blog/en/generative-ai/claude/claude-code-askuserquestion-tool-guide/)
- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Bridging the Gap: Requirements Elicitation Questions](https://www.bridging-the-gap.com/what-questions-do-i-ask-during-requirements-elicitation/)
- [SEI CMU: Eliciting Unstated Requirements](https://www.sei.cmu.edu/blog/eliciting-and-analyzing-unstated-requirements/)
- [GitHub Issue #28](https://github.com/tzachbon/smart-ralph/issues/28)
- Codebase files: `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/agents/*.md`
- Codebase files: `/home/tzachb/Projects/ralph-specum-goal-interview/plugins/ralph-specum/commands/*.md`
