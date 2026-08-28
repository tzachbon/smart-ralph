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
| Verification Tooling | `Explore` | Dev server, test runner, browser deps, E2E configs, ports |

**Minimum requirement**: 2 topics (1 research-analyst + 1 Explore). There are zero exceptions to the parallel requirement.

### Scaling by Complexity

| Scenario | Agent Count |
|----------|-------------|
| Simple, focused goal | 2 minimum: 1 research-analyst (web) + 1 Explore (codebase) |
| Goal spans multiple domains | 3-5: 2-3 research-analyst (different topics) + 1-2 Explore |
| Goal involves external APIs + codebase | 2+ research-analyst for API docs/best practices + 1+ Explore |
| Goal touches multiple components | Multiple Explore (one per component) + multiple research-analyst (one per external topic) |
| Complex architecture question | 5+: 3-4 research-analyst (different external topics) + 2-3 Explore (different code areas) |

**Note**: Verification Tooling discovery is always assigned to an Explore agent (codebase-only: package.json scripts, dependency detection, config file discovery).

### Topic Deduplication

- Each research-analyst handles ONE external topic; each Explore handles ONE codebase concern
- Break external research into MULTIPLE research-analyst teammates -- do NOT combine multiple external topics into one agent
- Example: "Add OAuth with rate limiting" becomes 3 research-analyst agents (OAuth patterns, rate limiting strategies, security best practices)
- When NOT to split: topics are tightly coupled and depend on each other, or splitting would create redundant searches

## Dispatch Pattern (Team-Based)

### Step 1: Clean Up Stale Team (MANDATORY FIRST ACTION)

Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase or interrupted run). Errors mean no team was active -- harmless, proceed.

### Step 2: Create Team

```text
TeamCreate(team_name: "research-$spec", description: "Parallel research for $spec")
```

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still failing, run `check-delegation` for each writer and use direct `Task(subagent_type: ...)` calls without a team. Preserve each writer's same complete gate packet and fresh unique artifact agent ID. The research output is the same either way.

### Step 3: Create Tasks

Create one `TaskCreate` per topic. Artifact-producing `research-analyst` topics use `$SPEC_PATH/.research-[topic-slug].md`. Read-only `Explore` topics return findings in their Task result and never write files.

```text
TaskCreate(
  subject: "[Topic name] research",
  description: "Research [topic] for $spec. Output: $SPEC_PATH/.research-[topic-slug].md",
  activeForm: "Researching [topic]"
)

TaskCreate(
  subject: "[Codebase concern] exploration",
  description: "Inspect [concern] for $spec. Return findings in the Task result. Read only; write no files.",
  activeForm: "Exploring [concern]"
)
```

### Step 4: Spawn Teammates (ALL in ONE Message)

ALL Task calls MUST be in ONE message to ensure true parallel execution. Before that batch, run `check-delegation` once per artifact-producing research teammate. Give every writer a unique artifact agent ID. Include the absolute state path, absolute `phase_gate.py` path, complete `[RALPH_PHASE_GATE]` identity tuple (`state`, `phase`, `interviewId`, `discoveryRevision`, `contextDigest`), verbatim selected-skill manifest, and complete approved decision brief. Require matching per-source load receipts and `check-agent-write` with the same identity before writing. Read-only `Explore` calls need no marker and may not write.

```text
Task(subagent_type: research-analyst, team_name: "research-$spec", name: "researcher-1",
  prompt: "You are a research teammate.
    Artifact agent ID: researcher-1
    [RALPH_PHASE_GATE marker]
    Absolute state path: [state]
    Absolute phase_gate.py path: [helper]
    Selected skill manifest: [full manifest]
    Approved decision brief: [full approved decision brief]
    Topic: [External best practices for topic]
    Spec: $spec | Path: $SPEC_PATH/
    Output: $SPEC_PATH/.research-[topic].md

    Goal context: [problem, constraints, success criteria from .progress.md]

    Instructions:
    1. WebSearch for best practices, industry standards, common pitfalls
    2. Research relevant libraries/frameworks
    3. Write findings to output file
    Do NOT explore codebase -- Explore teammates handle that.
    When done, mark your task complete via TaskUpdate.")

Task(subagent_type: Explore, team_name: "research-$spec", name: "explorer-1",
  prompt: "Analyze codebase for spec: $spec
    Find existing patterns, dependencies, constraints related to [goal].
    Return findings with sections: Existing Patterns, Dependencies, Constraints, Recommendations.
    Read only. Do not write or edit files.")
```

For more topics, add more `researcher-N` and `explorer-N` teammates in the same message.

### Step 5: Wait and Shutdown

- Wait for automatic teammate messages. Use `TaskList` to check progress.
- Timeout: If a teammate stalls, proceed with partial results and note incomplete topics.
- Send `shutdown_request` to each teammate after all tasks complete.
- Call `TeamDelete()` to clean up.

## Merging Results

After all parallel tasks complete, delegate the unified artifact to a fresh `research-analyst` merge teammate. Run `check-delegation` immediately before this Task. Include the absolute state and helper paths, complete marker identity tuple, verbatim selected-skill manifest, complete approved brief, fresh artifact agent ID, every partial artifact path, and all read-only Explore results. Require matching load receipts and `check-agent-write` before the merge writer creates `research.md`.

### Merge Process

1. **Read all partial inputs**: `.research-[topic-1].md` artifacts plus returned Explore findings for codebase, quality commands, verification tooling, and related specs.

2. **Create unified `$SPEC_PATH/research.md`** with this structure:

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
[From returned Explore findings for codebase patterns and constraints]
### Existing Patterns
### Dependencies
### Constraints

## Related Specs
[From returned Explore findings for related specs]
| Spec | Relevance | Relationship | May Need Update |

## Quality Commands
[From returned Explore findings for quality commands and verification tooling]
| Type | Command | Source |

## Feasibility Assessment
[Synthesize from all sources]
| Aspect | Assessment | Notes |

## Recommendations for Requirements

## Open Questions

## Sources
[All URLs and file paths from all agents]
```

3. **Delete partial files** after the merge agent successfully writes and validates `research.md`: remove only `$SPEC_PATH/.research-*.md` after resolving the exact matches.

4. **Quality check**: Ensure no duplicate information, consistent formatting.
