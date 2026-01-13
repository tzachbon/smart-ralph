---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash]
---

# Research Phase

You are running the research phase for a specification.

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
3. Assess technical feasibility
4. Create ./specs/$spec/research.md with your findings

Use the research.md template structure:
- Executive Summary
- External Research (best practices, prior art, pitfalls)
- Codebase Analysis (patterns, dependencies, constraints)
- Feasibility Assessment (table)
- Recommendations for Requirements
- Open Questions
- Sources

Remember: Never guess, always verify. Cite all sources.
```

## Update State

After research completes:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "research",
     ...
   }
   ```

2. Update `.progress.md` with research completion status

## Output

```
Research phase complete for '$spec'.

Output: ./specs/$spec/research.md

Next: Review research.md, then run /ralph-specum:requirements
```
