---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Research Phase

You are running the research phase for a specification.

<mandatory>
**YOU ARE A COORDINATOR, NOT A RESEARCHER.**

You MUST delegate ALL research work to subagents:
- Use `Explore` subagent for fast codebase analysis (read-only, uses Haiku model)
- Use `research-analyst` subagent for web research (needs WebSearch/WebFetch)

Do NOT perform web searches, codebase analysis, or write research.md yourself.

**PARALLEL EXECUTION IS MANDATORY for complex goals.** Spawn 3-5 subagents in a single message to maximize speed.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json` if it exists
3. Read `.progress.md` to understand the goal

## Analyze Research Topics

<mandatory>
**BEFORE invoking any subagents, analyze the goal and identify distinct research topics.**

Break down the goal into independent research areas that can be explored in parallel. Consider:
- **External/Best Practices**: Industry standards, patterns, libraries to research online → `research-analyst`
- **Codebase Analysis**: Existing implementations, patterns, constraints → `Explore` (fast, read-only)
- **Related Specs**: Other specs in ./specs/ that may overlap → `Explore` (fast, read-only)
- **Domain-Specific**: Specialized topics needing focused research → `research-analyst` for web, `Explore` for code
- **Quality Commands**: Project lint/test/build commands discovery → `Explore` (fast, read-only)
</mandatory>

### Subagent Selection Guide

| Task Type | Subagent | Reason |
|-----------|----------|--------|
| Web search for best practices | `research-analyst` | Needs WebSearch/WebFetch tools |
| Library/API documentation | `research-analyst` | Needs web access |
| Codebase pattern analysis | `Explore` | Fast, read-only, optimized for code |
| Related specs discovery | `Explore` | Fast scanning of ./specs/ |
| Quality commands discovery | `Explore` | Fast package.json/Makefile analysis |
| File structure exploration | `Explore` | Fast, uses Haiku model |
| Cross-referencing (code vs docs) | Both in parallel | Divide by source type |

### Topic Splitting Guidelines

| Scenario | Recommendation |
|----------|----------------|
| Simple, focused goal | 2 agents minimum: 1 Explore (codebase) + 1 research-analyst (web) |
| Goal spans multiple domains | Split into 3-5 topic-specific tasks |
| Goal involves external APIs + codebase | Separate: research-analyst for API docs, Explore for codebase |
| Goal touches multiple components | Multiple Explore agents, one per component |
| Complex architecture question | 3-5 agents: multiple Explore + research-analyst for external |

**Benefits of parallel execution:**
- 3-5 agents in parallel = up to 90% faster research
- Explore agents use Haiku model = very fast codebase analysis
- Each agent has focused context = better depth
- Results synthesized for comprehensive coverage

**When NOT to split:**
- Topics are tightly coupled and depend on each other
- Splitting would create redundant searches

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Research".

### Research Interview

Use AskUserQuestion to gather technical context:

```
AskUserQuestion:
  questions:
    - question: "What technical approach do you prefer for this feature?"
      options:
        - "Follow existing patterns in codebase (Recommended)"
        - "Introduce new patterns/frameworks"
        - "Hybrid - keep existing where possible"
        - "Other"
    - question: "Are there any known constraints or limitations?"
      options:
        - "No known constraints"
        - "Must work with existing API"
        - "Performance critical"
        - "Other"
```

### Adaptive Depth

If user selects "Other" for any question:
1. Ask a follow-up question to clarify using AskUserQuestion
2. Continue until clarity reached or 5 follow-up rounds complete
3. Each follow-up should probe deeper into the "Other" response

### Interview Context Format

After interview, format responses as:

```
Interview Context:
- Technical approach: [Answer]
- Known constraints: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Research

<mandatory>
**SPAWN MULTIPLE SUBAGENTS IN PARALLEL** using the Task tool in a single message.

Use the appropriate subagent type:
- `subagent_type: Explore` - For codebase analysis (fast, read-only, Haiku model)
- `subagent_type: research-analyst` - For web research (needs WebSearch/WebFetch)

**CRITICAL**: Include ALL Task tool calls in ONE message to ensure parallel execution.
</mandatory>

### Minimum Parallel Pattern (Always Use)

Even for simple goals, spawn at least 2 agents in parallel:

```
Task 1 (Explore - codebase): Analyze existing patterns
Task 2 (research-analyst - web): Search for best practices
```

### Standard Parallel Pattern (Recommended)

For most goals, spawn 3-4 agents in ONE message:

**Task 1 - External Research (research-analyst):**
```
subagent_type: research-analyst

You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: External best practices and patterns

Focus ONLY on web research:
1. WebSearch for best practices, industry standards
2. WebSearch for common pitfalls and gotchas
3. Research relevant libraries/frameworks for this stack
4. Document findings in ./specs/$spec/.research-external.md

Do NOT explore codebase - Explore agents handle that in parallel.
```

**Task 2 - Codebase Analysis (Explore - fast):**
```
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

**Task 3 - Quality Commands Discovery (Explore - fast):**
```
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

**Task 4 - Related Specs Discovery (Explore - fast):**
```
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

### Complex Goal Pattern (3-5 Agents)

**Example: Goal involves "Add GraphQL API with caching"**

Spawn 5 agents in ONE message:

| Agent # | Type | Focus | Output File |
|---------|------|-------|-------------|
| 1 | research-analyst | GraphQL best practices (web) | .research-graphql.md |
| 2 | research-analyst | Caching strategies (web) | .research-caching.md |
| 3 | Explore | Existing API patterns (code) | .research-codebase.md |
| 4 | Explore | Quality commands | .research-quality.md |
| 5 | Explore | Related specs | .research-related-specs.md |

**Task 1 - GraphQL Best Practices (research-analyst):**
```
subagent_type: research-analyst

Topic: GraphQL API best practices
Output: ./specs/$spec/.research-graphql.md

1. WebSearch: "GraphQL schema design best practices 2024"
2. WebSearch: "GraphQL resolvers performance patterns"
3. Research popular GraphQL libraries (Apollo, Yoga, etc.)
4. Document best practices, patterns, pitfalls
```

**Task 2 - Caching Strategies (research-analyst):**
```
subagent_type: research-analyst

Topic: Caching strategies for GraphQL
Output: ./specs/$spec/.research-caching.md

1. WebSearch: "GraphQL caching strategies 2024"
2. WebSearch: "DataLoader patterns best practices"
3. Research cache invalidation approaches
4. Document caching patterns and recommendations
```

**Task 3 - Codebase Analysis (Explore):**
```
subagent_type: Explore
thoroughness: very thorough

Topic: Existing API and caching patterns in codebase
Output: ./specs/$spec/.research-codebase.md

1. Search for existing API implementations
2. Find any caching code or patterns
3. Identify relevant dependencies
4. Document patterns with file paths
```

**Task 4 - Quality Commands (Explore):**
```
subagent_type: Explore
thoroughness: quick

Topic: Quality commands discovery
Output: ./specs/$spec/.research-quality.md

1. Check package.json scripts
2. Check Makefile if exists
3. Check CI workflow commands
4. Output as table: Type | Command | Source
```

**Task 5 - Related Specs (Explore):**
```
subagent_type: Explore
thoroughness: medium

Topic: Related specs discovery
Output: ./specs/$spec/.research-related-specs.md

1. Scan ./specs/ for existing specs
2. Read each spec's progress and requirements
3. Identify overlaps with GraphQL/caching goal
4. Output as table: Name | Relevance | Relationship | mayNeedUpdate
```

## Merge Results (After Parallel Research)

<mandatory>
After ALL parallel subagent tasks complete, YOU must merge results into a single research.md.
</mandatory>

### Merge Process

1. **Read all partial research files** created by subagents:
   - `.research-external.md` (from research-analyst)
   - `.research-graphql.md`, `.research-caching.md` (domain-specific, from research-analyst)
   - `.research-codebase.md` (from Explore)
   - `.research-quality.md` (from Explore)
   - `.research-related-specs.md` (from Explore)

2. **Create unified `./specs/$spec/research.md`** with standard structure:
   ```markdown
   # Research: $spec

   ## Executive Summary
   [Synthesize key findings from ALL agents - 2-3 sentences]

   ## External Research
   [Merge from .research-external.md and domain-specific files]
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
   [Consolidated recommendations]

   ## Open Questions
   [Consolidated from all agents]

   ## Sources
   [All URLs and file paths from all agents]
   ```

3. **Delete partial research files** after successful merge:
   ```bash
   rm ./specs/$spec/.research-*.md
   ```

4. **Quality check**: Ensure no duplicate information, consistent formatting

## Update State

After research completes:

1. Parse "Related Specs" table from research.md
2. Update `.ralph-state.json`:
   ```json
   {
     "phase": "research",
     "awaitingApproval": true,
     "relatedSpecs": [
       {"name": "...", "relevance": "high", "reason": "...", "mayNeedUpdate": true}
     ]
   }
   ```
3. Update `.progress.md` with research completion

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage research file:
   ```bash
   git add ./specs/$spec/research.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add research findings"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```
Research phase complete for '$spec'.

Output: ./specs/$spec/research.md
[If commitSpec: "Spec committed and pushed."]

Related specs found:
  - <name> (<RELEVANCE>) - may need update
  - <name> (<RELEVANCE>)

Next: Review research.md, then run /ralph-specum:requirements
```

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO REQUIREMENTS.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After displaying the output above, you MUST:
1. End your response immediately
2. Wait for the user to review research.md
3. Only proceed to requirements when user explicitly runs `/ralph-specum:requirements`

DO NOT automatically invoke the product-manager or run the requirements phase.
The user needs time to review research findings before proceeding.
</mandatory>
