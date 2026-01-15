---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Research Phase

You are running the research phase for a specification.

<mandatory>
**YOU ARE A COORDINATOR, NOT A RESEARCHER.**

You MUST delegate ALL research work to the `research-analyst` subagent.
Do NOT perform web searches, codebase analysis, or write research.md yourself.
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
**BEFORE invoking any research-analyst, analyze the goal and identify distinct research topics.**

Break down the goal into independent research areas that can be explored in parallel. Consider:
- **External/Best Practices**: Industry standards, patterns, libraries to research online
- **Codebase Analysis**: Existing implementations, patterns, constraints in the project
- **Related Specs**: Other specs in ./specs/ that may overlap or be affected
- **Domain-Specific**: Any specialized topics that need focused research (APIs, protocols, frameworks)
- **Quality Commands**: Project lint/test/build commands discovery
</mandatory>

### Topic Splitting Guidelines

| Scenario | Recommendation |
|----------|----------------|
| Simple, focused goal | Single research-analyst invocation is fine |
| Goal spans multiple domains | Split into 2-4 topic-specific research tasks |
| Goal involves external APIs + codebase | Separate external research from internal analysis |
| Goal touches multiple components | Research each component area in parallel |
| Research needs web + codebase analysis | Can split if topics are distinct enough |
| External best practices needed | Always include a dedicated external research task for web search |

**Benefits of splitting:**
- Parallel execution = faster results
- Each sub-agent has focused context = better depth
- Results can be merged for comprehensive coverage

**When NOT to split:**
- Very simple, narrow goals
- Topics are tightly coupled and can't be researched independently
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
Use the Task tool with `subagent_type: research-analyst` to run research.

**IMPORTANT**: If you identified multiple distinct topics above, invoke research-analyst MULTIPLE TIMES IN PARALLEL by including multiple Task tool calls in a single message. This maximizes parallelism and research depth.
</mandatory>

### Single Topic Invocation

If the goal is simple or topics cannot be meaningfully split, invoke one research-analyst:

```
You are researching for spec: $spec
Spec path: ./specs/$spec/

Goal: [goal from .progress.md]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Search web for best practices, prior art, and patterns
2. Explore the codebase for existing related implementations
3. Scan ./specs/ for existing specs that relate to this goal
4. Document related specs in the "Related Specs" section
5. Discover quality commands (lint, test, build)
6. Assess technical feasibility
7. Create ./specs/$spec/research.md with your findings
8. Include interview responses in a "User Context" section of research.md

Use the research.md template structure:
- Executive Summary
- User Context (interview responses and user-provided constraints)
- External Research (best practices, prior art, pitfalls)
- Codebase Analysis (patterns, dependencies, constraints)
- Related Specs (table with relevance, relationship, mayNeedUpdate)
- Feasibility Assessment (table)
- Recommendations for Requirements
- Open Questions
- Sources

Remember: Never guess, always verify. Cite all sources.
```

### Multiple Topic Invocation (Preferred for Complex Goals)

<mandatory>
If you identified 2-4 distinct topics, invoke research-analyst MULTIPLE TIMES IN PARALLEL.
Each invocation should focus on ONE specific topic area.
</mandatory>

**Example: Goal involves "Add GraphQL API with caching"**

Invoke 3 research-analysts in parallel (all in ONE message with multiple Task tool calls):

**Task 1 - External Best Practices:**
```
You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: GraphQL API best practices and patterns

Focus ONLY on external research:
1. WebSearch for GraphQL best practices, schema design patterns
2. WebSearch for GraphQL caching strategies
3. Research popular GraphQL libraries for this stack
4. Document findings in ./specs/$spec/.research-external.md

Do NOT explore codebase or related specs - another agent handles that.
```

**Task 2 - Codebase Analysis:**
```
You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: Existing codebase patterns and constraints

Focus ONLY on internal research:
1. Explore existing API patterns in codebase
2. Check for existing caching implementations
3. Identify dependencies and constraints
4. Discover quality commands (lint, test, build)
5. Document findings in ./specs/$spec/.research-codebase.md

Do NOT do web searches - another agent handles that.
```

**Task 3 - Related Specs:**
```
You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: Related specs discovery

Focus ONLY on related specs:
1. Scan ./specs/ for all existing specs
2. Read each spec's .progress.md, research.md, requirements.md
3. Identify overlap, conflicts, specs that may need updates
4. Document findings in ./specs/$spec/.research-related-specs.md

Format as table with: Name, Relevance (High/Medium/Low), Relationship, mayNeedUpdate
```

## Merge Results (For Multi-Topic Research)

<mandatory>
After ALL parallel research-analyst tasks complete, YOU must merge results into a single research.md.
</mandatory>

If you invoked multiple research-analysts:

1. Read all partial research files (.research-external.md, .research-codebase.md, .research-related-specs.md, etc.)
2. Create unified `./specs/$spec/research.md` with standard structure:
   - Executive Summary (synthesize all findings)
   - External Research (from external research task)
   - Codebase Analysis (from codebase task)
   - Related Specs (from related specs task)
   - Feasibility Assessment (synthesize from all sources)
   - Quality Commands (from codebase task)
   - Recommendations for Requirements
   - Open Questions (consolidated)
   - Sources (all sources from all tasks)
3. Delete partial research files after merging
4. Ensure no duplicate information in merged document

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

## Output

```
Research phase complete for '$spec'.

Output: ./specs/$spec/research.md

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
