---
name: parallel-research
description: This skill should be used when the user asks about "parallel research", "multi-agent spawning", "parallel execution", "concurrent subagents", "research merge algorithm", "spawn multiple agents", or needs guidance on executing research tasks in parallel using multiple subagents and merging their results.
version: 0.1.0
---

# Parallel Research Pattern

The parallel research pattern enables fast, comprehensive research by spawning multiple specialized subagents simultaneously and merging their results into a unified output.

## Core Principle

**Parallel execution is MANDATORY - NO EXCEPTIONS.**

Even for simple goals:
- Minimum: 2 agents (1 research-analyst + 1 Explore)
- Standard: 3-4 agents (2-3 research-analyst + 1-2 Explore)
- Complex: 5+ agents (3-4 research-analyst + 2-3 Explore)

**ALL agent Task calls MUST be in ONE message** to achieve true parallelism.

## Subagent Types

| Task Type | Subagent | Reason |
|-----------|----------|--------|
| Web search for best practices | `research-analyst` | Needs WebSearch/WebFetch tools |
| Library/API documentation | `research-analyst` | Needs web access |
| Codebase pattern analysis | `Explore` | Fast, read-only, optimized for code |
| Related specs discovery | `Explore` | Fast scanning of ./specs/ |
| Quality commands discovery | `Explore` | Fast package.json/Makefile analysis |
| File structure exploration | `Explore` | Fast, uses Haiku model |

## Pattern Components

### 1. Topic Analysis

Before spawning agents, identify distinct research topics:

```text
Research topics identified for parallel execution:
1. [Topic name] - [Agent type: research-analyst/Explore]
2. [Topic name] - [Agent type: research-analyst/Explore]
3. [Topic name] - [Agent type: research-analyst/Explore] (if applicable)
...
```

**Topic splitting guidelines:**

| Scenario | Recommendation |
|----------|----------------|
| Simple, focused goal | 2 agents: 1 research-analyst (web) + 1 Explore (codebase) |
| Goal spans multiple domains | 3-5 agents: 2-3 research-analyst + 1-2 Explore |
| Goal involves external APIs + codebase | 2+ research-analyst + 1+ Explore |
| Goal touches multiple components | Multiple Explore + multiple research-analyst |
| Complex architecture question | 5+ agents: 3-4 research-analyst + 2-3 Explore |

**IMPORTANT: Break external research into MULTIPLE research-analyst agents**
- If goal involves multiple external topics (e.g., "authentication + security"), spawn separate research-analyst agents for EACH topic
- Example: "Add OAuth with rate limiting" = 3 research-analyst agents (OAuth patterns, rate limiting strategies, security best practices)
- DO NOT combine multiple external topics into one research-analyst agent

### 2. Pre-Execution Checklist

Before spawning agents, verify:

- [ ] Listed at least 2 distinct research topics
- [ ] Assigned appropriate agent type (Explore or research-analyst) to each topic
- [ ] Prepared unique output file path for each agent (.research-*.md)
- [ ] Prepared all Task tool calls in your response (ready to send in ONE message)
- [ ] NOT written any code/searches yourself (coordinator does not implement)

### 3. Multi-Agent Spawning

**CRITICAL**: All Task tool calls MUST be in a SINGLE response message.

**WRONG (Sequential)** - Each Task call in separate message:
```text
Message 1: Task(subagent_type: research-analyst, topic: best practices)
[wait for result]
Message 2: Task(subagent_type: Explore, topic: codebase)
[wait for result]
```
Result: Agents run one after another = SLOW

**CORRECT (Parallel)** - All Task calls in ONE message:
```text
Message 1:
  Task(subagent_type: research-analyst, topic: best practices)
  Task(subagent_type: Explore, topic: codebase)
  Task(subagent_type: Explore, topic: quality commands)
[all agents start simultaneously]
```
Result: Agents run at the same time = FAST (2-3x faster)

### 4. Task Delegation Templates

**External Research (research-analyst):**

```yaml
subagent_type: research-analyst

You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: [SPECIFIC TOPIC]

Focus ONLY on web research for THIS specific topic:
1. WebSearch for best practices, industry standards
2. WebSearch for common pitfalls and gotchas
3. Research relevant libraries/frameworks
4. Document findings in ./specs/$spec/.research-[topic-name].md

Do NOT explore codebase - Explore agents handle that in parallel.
Do NOT research other topics - other research-analyst agents handle those.
```

**Codebase Analysis (Explore):**

```yaml
subagent_type: Explore
thoroughness: very thorough

Analyze codebase for spec: $spec
Output file: ./specs/$spec/.research-codebase.md

Tasks:
1. Find existing patterns related to [goal]
2. Identify dependencies and constraints
3. Check for similar implementations
4. Document architectural patterns used

Write findings to the output file with sections:
- Existing Patterns (with file paths)
- Dependencies
- Constraints
- Recommendations
```

**Quality Commands Discovery (Explore):**

```yaml
subagent_type: Explore
thoroughness: quick

Discover quality commands for spec: $spec
Output file: ./specs/$spec/.research-quality.md

Tasks:
1. Read package.json scripts section
2. Check for Makefile targets
3. Scan .github/workflows/*.yml for CI commands
4. Document lint, test, build, typecheck commands

Write findings as table: | Type | Command | Source |
```

**Related Specs Discovery (Explore):**

```yaml
subagent_type: Explore
thoroughness: medium

Scan related specs for: $spec
Output file: ./specs/$spec/.research-related-specs.md

Tasks:
1. List all directories in ./specs/ (each is a spec)
2. For each spec, read .progress.md for Original Goal
3. Read research.md/requirements.md summaries if exist
4. Identify overlaps, conflicts, specs needing updates

Write findings as table: | Name | Relevance | Relationship | mayNeedUpdate |
```

### 5. Results Merge Algorithm

After ALL parallel subagent tasks complete, merge results into unified output:

**Step 1: Collect partial files**

Read all files created by subagents:
- `.research-[topic-1].md`, `.research-[topic-2].md`, etc. (from research-analyst agents)
- `.research-codebase.md` (from Explore)
- `.research-quality.md` (from Explore)
- `.research-related-specs.md` (from Explore)

**Step 2: Create unified structure**

```markdown
# Research: $spec

## Executive Summary
[Synthesize key findings from ALL agents - 2-3 sentences]

## External Research
[Merge from ALL .research-[topic].md files from research-analyst agents]
### Best Practices
[From all research-analyst agents]
### Prior Art
[From all research-analyst agents]
### Pitfalls to Avoid
[From all research-analyst agents]

## Codebase Analysis
[From .research-codebase.md]
### Existing Patterns
### Dependencies
### Constraints

## Related Specs
[From .research-related-specs.md]
| Spec | Relevance | Relationship | May Need Update |

## Quality Commands
[From .research-quality.md]
| Type | Command | Source |

## Feasibility Assessment
[Synthesize from all sources]
| Aspect | Assessment | Notes |

## Recommendations for Requirements
[Consolidated recommendations]

## Open Questions
[Consolidated from all agents]

## Sources
[All URLs and file paths from all agents]
```

**Step 3: Cleanup**

Delete partial research files after successful merge:
```bash
rm ./specs/$spec/.research-*.md
```

**Step 4: Quality check**

Ensure:
- No duplicate information across sections
- Consistent formatting throughout
- All agent contributions represented
- Sources properly attributed

## Example: Complex Goal Pattern

**Goal**: "Add GraphQL API with caching"

This goal has TWO distinct external topics (GraphQL + Caching), spawn 5 agents:

| Agent # | Type | Focus | Output File |
|---------|------|-------|-------------|
| 1 | research-analyst | GraphQL best practices | .research-graphql.md |
| 2 | research-analyst | Caching strategies | .research-caching.md |
| 3 | Explore | Existing API patterns | .research-codebase.md |
| 4 | Explore | Quality commands | .research-quality.md |
| 5 | Explore | Related specs | .research-related-specs.md |

All 5 Task calls in ONE message for true parallel execution.

## Fail-Safe Rules

**"But This Goal is Simple..."**

Even trivial goals require parallel research:
- You're wrong - spawn at least 2 agents anyway
- Minimum: 1 Explore (codebase) + 1 research-analyst (web)
- Parallel execution is about SPEED, not complexity
- 2 agents in parallel = 2x faster than sequential

**There are ZERO exceptions to the parallel requirement.**

## Benefits

- 3-5 agents in parallel = up to 90% faster research
- Explore agents use Haiku model = very fast codebase analysis
- Each agent has focused context = better depth
- Results synthesized for comprehensive coverage

## When NOT to Split

- Topics are tightly coupled and depend on each other
- Splitting would create redundant searches

## Usage in Commands

Reference this skill in commands that need parallel research:

```markdown
<skill-reference>
**Apply skill**: `skills/parallel-research/SKILL.md`
Use the parallel research pattern to spawn multiple subagents for comprehensive research.
</skill-reference>
```

## Anti-Patterns

**DO NOT:**
- Spawn agents one at a time in separate messages (sequential execution)
- Combine multiple external topics into one research-analyst agent
- Skip codebase analysis even for "simple" goals
- Perform research yourself instead of delegating
- Merge results before ALL agents complete

**ALWAYS:**
- Analyze topics before spawning
- Use ONE message for ALL Task calls
- Assign unique output files to each agent
- Wait for ALL agents to complete before merging
- Clean up partial files after merge
