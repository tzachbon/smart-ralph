# Research: adaptive-interview

## Executive Summary

The current interview system uses static, hardcoded questions across 5 phases (goal, research, requirements, design, tasks) that don't adapt based on context, conversation history, or existing specs. Research reveals three proven approaches: **parameter chain pattern** (ask only for missing info), **question piping** (reference prior answers), and **branching logic** (conditional paths). A hybrid approach combining rule-based context injection with AI-generated follow-ups is recommended.

## External Research

### Best Practices

| Practice | Description | Source |
|----------|-------------|--------|
| Parameter Chain | Ask "do we have X? If not, ask for it" - eliminates showing all combinations | Master of Code |
| Question Piping | Insert previous answers into follow-up questions | QuestionScout |
| Context Preservation | Reference earlier conversation, maintain state | PatternFly |
| Limited Choices | Max 5 options per question - users forget middle options | PatternFly |
| Explain "Why" | Frame questions in terms of value for user | PatternFly |

### Prior Art

| Approach | Pros | Cons | Best Use Case |
|----------|------|------|---------------|
| Branching Logic | Predictable, testable | Rigid, maintenance heavy | Known flows |
| AI-Generated | Highly adaptive, natural | Unpredictable, harder to test | Exploratory research |
| Template-Based | Consistent, easy to maintain | Less adaptive | Standardized interviews |
| **Hybrid** | Best of all worlds | More complex to implement | Production systems |

### Pitfalls to Avoid

- **Lack of context awareness** - biggest issue; users frustrated by repetition
- **Over-complex branching** - logic errors, hard to maintain
- **Generic scripted responses** - feels robotic
- **Using open text as branching triggers** - unpredictable behavior
- **No escalation path** - users stuck in loops when AI can't help
- **Too many choices** - cognitive overload

## Codebase Analysis

### Existing Patterns

| Location | File | Lines | Questions |
|----------|------|-------|-----------|
| Goal Interview | commands/start.md | 528-584 | 3 questions: problem type, constraints, success criteria |
| Research Interview | commands/research.md | 80-131 | 2 questions: technical approach, constraints |
| Requirements Interview | commands/requirements.md | 37-88 | 2 questions: primary users, priority tradeoffs |
| Design Interview | commands/design.md | 39-90 | 2 questions: architecture style, tech constraints |
| Tasks Interview | commands/tasks.md | 40-91 | 2 questions: testing depth, deployment |

### Current Adaptive Mechanism

All interviews have an "Adaptive Depth" feature when user selects "Other":
- Ask follow-up question to clarify
- Continue until clarity reached OR 5 rounds complete
- Generic follow-up template: "You mentioned [Other response]. Can you elaborate?"

**Limitation**: Follow-ups don't branch based on which option was selected, questions don't reference prior phases.

### Available Context (Not Currently Used)

| Phase | Available Data | Currently Used? |
|-------|----------------|-----------------|
| Research | `.progress.md` with goal | Partially |
| Requirements | `research.md` findings | No |
| Design | `requirements.md`, `research.md` | No |
| Tasks | All prior artifacts | No |
| All | Related specs in `./specs/` | No |

### Constraints

1. **No cross-phase memory** - Each interview starts fresh
2. **No spec awareness** - Questions don't consider existing related specs
3. **Static question templates** - Same questions for all projects
4. **No question branching** - Follow-ups are generic, not option-specific
5. **Quick mode bypasses all** - `--quick` flag skips interviews entirely
6. **No interviews during execution** - spec-executor cannot use AskUserQuestion

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| goal-interview | VERY HIGH | Parent - implements the interview system being improved | YES - ensure context properly passed |
| parallel-task-execution | MEDIUM | Infrastructure - [P] markers for parallel tasks | NO |
| qa-verification | MEDIUM | Infrastructure - [VERIFY] task pattern | NO |
| implement-ralph-wiggum | MEDIUM | Execution framework dependency | NO |
| plan-source-feature | LOW | --quick mode workflow | NO |
| ralph-speckit | LOW | Alternative plugin, similar patterns | MAYBE - coordinate approach |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| CI Check | Version verification | `.github/workflows/plugin-version-check.yml` |
| CI Check | Spec file validation | `.github/workflows/spec-file-check.yml` |
| Plugin Test | `claude --plugin-dir ./plugins/ralph-specum` | CLAUDE.md |
| Workflow Test | `/ralph-specum:start test-feature` | CLAUDE.md |

Note: This is a Claude Code plugin - no traditional build/test stack (no package.json scripts, Jest, ESLint).

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Complexity | Medium | Requires reading prior artifacts, but markdown parsing is straightforward |
| Breaking Changes | Low | Can add context-awareness without changing question structure |
| Testing | Manual | Plugin testing via Claude Code CLI workflow |
| Dependencies | None | Uses existing AskUserQuestion tool |
| Risk | Low | Changes are additive, won't break existing behavior |

## Recommendations for Requirements

1. **Implement parameter chain pattern** - Check what's already known from prior phases before asking
2. **Add question piping** - Reference prior answers in question text (e.g., "You mentioned {goal}...")
3. **Enable spec awareness** - Read related specs from `./specs/` to inform questions
4. **Phase-specific context** - Each phase reads prior artifacts to adapt questions
5. **Hybrid approach** - Keep core template questions, add conditional branches, use AI for depth
6. **Avoid over-engineering** - Start with rule-based context injection, proven and testable

## Open Questions

1. Should questions be generated dynamically by AI or use enhanced templates with context slots?
2. How much context from related specs should influence questions (summaries vs full content)?
3. Should the "Other" follow-up mechanism use more sophisticated prompting?
4. Should interview responses accumulate across phases in `.progress.md`?

## Sources

### External
- [PatternFly Conversation Design](https://www.patternfly.org/patternfly-ai/conversation-design/)
- [Master of Code - Parameter Chain Pattern](https://masterofcode.com/blog/conversational-design-series-3-the-parameter-chain-design-pattern)
- [QuestionScout - Conditional Logic Guide](https://www.questionscout.com/blog/conditional-logic-in-forms-a-complete-guide)
- [Apriorit - Context-Aware Chatbots](https://www.apriorit.com/dev-blog/context-aware-chatbot-development)
- [Maze - UX Survey Questions](https://maze.co/guides/ux-surveys/questions/)

### Codebase
- `plugins/ralph-specum/commands/start.md:528-584` - Goal interview
- `plugins/ralph-specum/commands/research.md:80-131` - Research interview
- `plugins/ralph-specum/commands/requirements.md:37-88` - Requirements interview
- `plugins/ralph-specum/commands/design.md:39-90` - Design interview
- `plugins/ralph-specum/commands/tasks.md:40-91` - Tasks interview
