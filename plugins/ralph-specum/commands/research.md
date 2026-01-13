---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash]
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

## Execute Research

<mandatory>
Use the Task tool with `subagent_type: research-analyst` to run the research phase.
</mandatory>

Invoke research-analyst agent with prompt:

```
You are researching for spec: $spec
Spec path: ./specs/$spec/

Goal from user conversation or existing progress file.

Your task:
1. Search web for best practices, prior art, and patterns
2. Explore the codebase for existing related implementations
3. Scan ./specs/ for existing specs that relate to this goal
4. Document related specs in the "Related Specs" section
5. Assess technical feasibility
6. Create ./specs/$spec/research.md with your findings

Use the research.md template structure:
- Executive Summary
- External Research (best practices, prior art, pitfalls)
- Codebase Analysis (patterns, dependencies, constraints)
- Related Specs (table with relevance, relationship, mayNeedUpdate)
- Feasibility Assessment (table)
- Recommendations for Requirements
- Open Questions
- Sources

Remember: Never guess, always verify. Cite all sources.
```

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
