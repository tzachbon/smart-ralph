# Parallel Research

> Used by: research.md

## Coordinator Role

The research command is a **coordinator, not a researcher**. It MUST delegate ALL research work to subagents:
- `Explore` subagent for fast codebase analysis (read-only, uses Haiku model)
- `research-analyst` subagent for web research (needs WebSearch/WebFetch)

The coordinator never performs web searches, codebase analysis, or writes research.md content itself.

## Topic Identification

Before invoking any subagents, analyze the goal and break it into independent research areas:

| Category | Agent Type | Examples |
|----------|-----------|----------|
| External/Best Practices | `research-analyst` | Industry standards, patterns, libraries |
| Codebase Analysis | `Explore` | Existing implementations, patterns, constraints |
| Related Specs | `Explore` | Other specs in ./specs/ that may overlap |
| Domain-Specific (web) | `research-analyst` | Specialized topics needing focused web research |
| Domain-Specific (code) | `Explore` | Specialized topics needing codebase exploration |
| Quality Commands | `Explore` | Project lint/test/build commands discovery |

**Minimum requirement**: 2 topics (1 research-analyst + 1 Explore). There are zero exceptions to the parallel requirement.

### Scaling by Complexity

| Scenario | Agent Count |
|----------|-------------|
| Simple, focused goal | 2 minimum: 1 research-analyst (web) + 1 Explore (codebase) |
| Goal spans multiple domains | 3-5: 2-3 research-analyst (different topics) + 1-2 Explore |
| Goal involves external APIs + codebase | 2+ research-analyst for API docs/best practices + 1+ Explore |
| Goal touches multiple components | Multiple Explore (one per component) + multiple research-analyst (one per external topic) |
| Complex architecture question | 5+: 3-4 research-analyst (different external topics) + 2-3 Explore (different code areas) |

### Topic Deduplication

- Each research-analyst handles ONE external topic; each Explore handles ONE codebase concern
- Break external research into MULTIPLE research-analyst teammates -- do NOT combine multiple external topics into one agent
- Example: "Add OAuth with rate limiting" becomes 3 research-analyst agents (OAuth patterns, rate limiting strategies, security best practices)
- When NOT to split: topics are tightly coupled and depend on each other, or splitting would create redundant searches

## Dispatch Pattern (Team-Based)

### Step 1: Check for Orphaned Team

Read `~/.claude/teams/research-$spec/config.json`. If it exists, call `TeamDelete()` to clean up from a previous interrupted session.

### Step 2: Create Team

```
TeamCreate(team_name: "research-$spec", description: "Parallel research for $spec")
```

**Fallback**: If TeamCreate fails, fall back to direct `Task(subagent_type: ...)` calls without a team. The research output is the same either way.

### Step 3: Create Tasks

One `TaskCreate` per topic. Output file naming: `.research-[topic-slug].md` (e.g., `.research-oauth-patterns.md`, `.research-codebase.md`, `.research-quality.md`).

```
TaskCreate(
  subject: "[Topic name] research",
  description: "Research [topic] for $spec. Output: ./specs/$spec/.research-[topic-slug].md",
  activeForm: "Researching [topic]"
)
```

### Step 4: Spawn Teammates (ALL in ONE Message)

ALL Task calls MUST be in ONE message to ensure true parallel execution. Spawning one at a time across separate messages runs them sequentially.

```
Task(subagent_type: research-analyst, team_name: "research-$spec", name: "researcher-1",
  prompt: "You are a research teammate.
    Topic: [External best practices for topic]
    Spec: $spec | Path: ./specs/$spec/
    Output: ./specs/$spec/.research-[topic].md

    Goal context: [problem, constraints, success criteria from .progress.md]

    Instructions:
    1. WebSearch for best practices, industry standards, common pitfalls
    2. Research relevant libraries/frameworks
    3. Write findings to output file
    Do NOT explore codebase -- Explore teammates handle that.
    When done, mark your task complete via TaskUpdate.")

Task(subagent_type: Explore, team_name: "research-$spec", name: "explorer-1",
  prompt: "Analyze codebase for spec: $spec
    Output: ./specs/$spec/.research-codebase.md
    Find existing patterns, dependencies, constraints related to [goal].
    Write findings to output file with sections: Existing Patterns, Dependencies, Constraints, Recommendations.")
```

For more topics, add more `researcher-N` and `explorer-N` teammates in the same message.

### Step 5: Wait and Shutdown

- Wait for automatic teammate messages. Use `TaskList` to check progress.
- Timeout: If a teammate stalls, proceed with partial results and note incomplete topics.
- Send `shutdown_request` to each teammate after all tasks complete.
- Call `TeamDelete()` to clean up.

## Merging Results

After ALL parallel tasks complete, the coordinator merges results into a single `research.md`.

### Merge Process

1. **Read all partial files**: `.research-[topic-1].md`, `.research-codebase.md`, `.research-quality.md`, `.research-related-specs.md`, etc.

2. **Create unified `./specs/$spec/research.md`** with this structure:

```markdown
# Research: $spec

## Executive Summary
[Synthesize key findings from ALL agents - 2-3 sentences]

## External Research
[Merge from ALL .research-[topic].md files created by research-analyst agents]
### Best Practices
### Prior Art
### Pitfalls to Avoid

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

## Open Questions

## Sources
[All URLs and file paths from all agents]
```

3. **Delete partial files** after successful merge: `rm ./specs/$spec/.research-*.md`

4. **Quality check**: Ensure no duplicate information, consistent formatting.
