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

Failure to spawn multiple agents in parallel violates the core design of this command.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json` if it exists
3. Read `.progress.md` to understand the goal

## Interview (Skip if --quick)

<skill-reference>
**Apply skill**: `plugins/ralph-specum/skills/interview-framework/SKILL.md`
Use the interview framework for single-question adaptive interview loop.

**Phase-Specific Configuration:**
- **Phase**: Research Interview
- **Parameter Chain Mappings**: technicalApproach, knownConstraints, integrationPoints
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`
- **Storage Section**: `### Research Interview (from research.md)`

**Question Pool:**
| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What technical approach do you prefer? | Required | `technicalApproach` |
| 2 | Are there any known constraints or limitations? | Required | `knownConstraints` |
| 3 | Are there specific integration points to consider? | Required | `integrationPoints` |
| 4 | Any other technical context? (or say 'done') | Optional | `additionalTechContext` |

Store responses in `.progress.md` under `### Research Interview (from research.md)`.
</skill-reference>

## Execute Research (Parallel)

<skill-reference>
**Apply skill**: `plugins/ralph-specum/skills/parallel-research/SKILL.md`
Use the parallel research pattern to spawn multiple subagents for comprehensive research.

**PARALLEL EXECUTION IS MANDATORY - NO EXCEPTIONS**

Minimum: 2 agents (1 research-analyst + 1 Explore)
Standard: 3-4 agents (2-3 research-analyst + 1-2 Explore)
Complex: 5+ agents (3-4 research-analyst + 2-3 Explore)

**ALL agent Task calls MUST be in ONE message** to achieve true parallelism.
</skill-reference>

### Research Topics to Cover

1. **External Research** (research-analyst): Best practices, industry standards, libraries
2. **Codebase Analysis** (Explore): Existing patterns, dependencies, constraints
3. **Quality Commands** (Explore): lint, test, build, typecheck commands
4. **Related Specs** (Explore): Other specs that may overlap

### Output Files

Each agent writes to a unique file:
- `.research-[topic].md` (from research-analyst agents)
- `.research-codebase.md` (from Explore)
- `.research-quality.md` (from Explore)
- `.research-related-specs.md` (from Explore)

## Merge Results

After ALL parallel subagent tasks complete, merge results into unified `./specs/$spec/research.md`:

```markdown
# Research: $spec

## Executive Summary
[Synthesize key findings - 2-3 sentences]

## External Research
### Best Practices
### Prior Art
### Pitfalls to Avoid

## Codebase Analysis
### Existing Patterns
### Dependencies
### Constraints

## Related Specs
| Spec | Relevance | Relationship | May Need Update |

## Quality Commands
| Type | Command | Source |

## Feasibility Assessment
| Aspect | Assessment | Notes |

## Recommendations for Requirements

## Open Questions

## Sources
```

Delete partial research files after successful merge:
```bash
rm ./specs/$spec/.research-*.md
```

## Review & Feedback Loop (Skip if --quick)

After research is created, ask the user to review:

| # | Question | Key |
|---|----------|-----|
| 1 | Does the research cover all expected areas? | `researchCoverage` |
| 2 | Are the findings and recommendations helpful? | `findingsQuality` |
| 3 | Any areas to research further? | `additionalResearch` |
| 4 | Any other feedback? (or say 'approved') | `researchFeedback` |

Store responses in `.progress.md` under `### Research Review (from research.md)`.

If user requests changes: invoke appropriate subagents again, merge updated results, repeat review.

## Update State

After research completes and is approved:

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

Read `commitSpec` from `.ralph-state.json`. If true:

```bash
git add ./specs/$spec/research.md
git commit -m "spec($spec): add research findings"
git push -u origin $(git branch --show-current)
```

If commit/push fails, display warning but continue.

## Output

```text
Research phase complete for '$spec'.

Output: ./specs/$spec/research.md
[If commitSpec: "Spec committed and pushed."]

Related specs found:
  - <name> (<RELEVANCE>) - may need update

Next: Review research.md, then run /ralph-specum:requirements
```

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO REQUIREMENTS.**

(Exception: `--quick` mode auto-generates all artifacts without stopping.)

After displaying output, you MUST:
1. End your response immediately
2. Wait for user to review research.md
3. Only proceed when user explicitly runs `/ralph-specum:requirements`

DO NOT automatically invoke product-manager or run requirements phase.
</mandatory>
