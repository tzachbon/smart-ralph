---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: "*"
---

# Research Phase

You are running the research phase for a specification.

<mandatory>
**YOU ARE A COORDINATOR, NOT A RESEARCHER.**

You MUST delegate ALL research work to subagents:
- Use `Explore` subagent for fast codebase analysis (read-only, uses Haiku model)
- Use `research-analyst` subagent for web research (needs WebSearch/WebFetch)

Do NOT perform web searches, codebase analysis, or write research.md yourself.

**PARALLEL EXECUTION IS MANDATORY - ALWAYS.**
- Minimum: 2 agents (1 research-analyst + 1 Explore)
- Standard: 3-4 agents (2-3 research-analyst + 1-2 Explore)
- Complex: 5+ agents (3-4 research-analyst for different topics + 2-3 Explore)
- **ALL agent Task calls MUST be in ONE message** (not sequential messages)

**CRITICAL: You can and SHOULD spawn MULTIPLE research-analyst agents in parallel.**
- Each research-analyst should focus on a distinct research topic
- Example: GraphQL API + Caching strategies = 2 research-analyst agents in parallel
- Example: Auth patterns + Security best practices + API design = 3 research-analyst agents in parallel
- DO NOT limit yourself to just one research-analyst agent

Failure to spawn multiple agents in parallel violates the core design of this command.
</mandatory>

## Multi-Directory Resolution

This command uses the path resolver for dynamic spec path resolution:

**Path Resolver Functions**:
- `ralph_resolve_current()` - Resolves .current-spec to full path (handles bare name = ./specs/$name, full path = as-is)
- `ralph_find_spec(name)` - Find spec by name across all configured roots

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it
2. Otherwise, use `ralph_resolve_current()` to get the active spec path
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

The spec path is dynamically resolved - it may be in `./specs/` or any other configured specs directory.

## Validate

1. Check the resolved spec directory exists
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
| Simple, focused goal | 2 agents minimum: 1 research-analyst (web) + 1 Explore (codebase) |
| Goal spans multiple domains | 3-5 agents: 2-3 research-analyst (different topics) + 1-2 Explore |
| Goal involves external APIs + codebase | 2+ research-analyst for API docs/best practices + 1+ Explore for codebase |
| Goal touches multiple components | Multiple Explore agents (one per component) + multiple research-analyst (one per external topic) |
| Complex architecture question | 5+ agents: 3-4 research-analyst (different external topics) + 2-3 Explore (different code areas) |

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

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **Prior interview responses** to enable parameter chain (skip already-answered questions)

```text
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal technical context needed)
- REFACTOR: 3-5 questions (understand approach and risks)
- GREENFIELD: 5-10 questions (full technical context)
- MID_SIZED: 3-7 questions (balanced approach)

### Research Interview (Single-Question Flow)

**Interview Framework**: Apply standard single-question loop from `skills/interview-framework/SKILL.md`

### Phase-Specific Configuration

- **Phase**: Research Interview
- **Parameter Chain Mappings**: technicalApproach, knownConstraints, integrationPoints
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`
- **Variables Not Yet Available**: `{users}`, `{priority}` (populated in later phases)
- **Storage Section**: `### Research Interview (from research.md)`

### Research Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | What technical approach do you prefer for this feature? | Required | `technicalApproach` | Follow existing patterns in codebase (Recommended) / Introduce new patterns/frameworks / Hybrid - keep existing where possible / Other |
| 2 | Are there any known constraints or limitations? | Required | `knownConstraints` | No known constraints / Must work with existing API / Performance critical / Other |
| 3 | Are there specific integration points to consider? | Required | `integrationPoints` | Standard integration with existing services / New external dependencies required / Isolated component (minimal integration) / Other |
| 4 | Any other technical context for research? (or say 'done' to proceed) | Optional | `additionalTechContext` | No, let's proceed / Yes, I have more details / Other |

### Store Research Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Research Interview (from research.md)
- Technical approach: [responses.technicalApproach]
- Known constraints: [responses.knownConstraints]
- Integration points: [responses.integrationPoints]
- Additional technical context: [responses.additionalTechContext]
[Any follow-up responses from "Other" selections]
```

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```text
Interview Context:
- Technical approach: [Answer]
- Known constraints: [Answer]
- Integration points: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Research (Team-Based)

<mandatory>
**Research uses Claude Code Teams for parallel execution, matching the standard team lifecycle pattern.**

**PARALLEL EXECUTION IS MANDATORY - NO EXCEPTIONS.**

You MUST follow the full team lifecycle below.
</mandatory>

### Pre-Step: Identify Research Topics (REQUIRED)

Analyze the goal and list AT LEAST 2 distinct research topics. Output the list to the user:

```
Research topics identified for parallel execution:
1. [Topic name] - [Agent type: research-analyst/Explore]
2. [Topic name] - [Agent type: research-analyst/Explore]
3. [Topic name] - [Agent type: research-analyst/Explore] (if applicable)
...
```

**Minimum requirement**: 2 topics minimum
- Topic 1: External/best practices (use research-analyst)
- Topic 2: Codebase patterns (use Explore)
- Additional topics: Domain-specific areas (spawn MULTIPLE research-analyst teammates), quality commands (Explore), related specs (Explore)

**IMPORTANT: Break external research into MULTIPLE research-analyst teammates**
- If the goal involves multiple external topics (e.g., "authentication + security"), spawn separate research-analyst teammates for EACH topic
- Example: "Add OAuth with rate limiting" → 3 research-analyst teammates (OAuth patterns, rate limiting strategies, security best practices)
- DO NOT combine multiple external topics into one research-analyst teammate

### Fail-Safe: "But This Goal is Simple..."

<mandatory>
**Even trivial goals require parallel research.**

If you think the goal is "too simple" for parallel research:
- You're wrong - spawn at least 2 teammates anyway
- Minimum: 1 Explore (codebase) + 1 research-analyst (web)
- Parallel execution is about SPEED, not complexity
- 2 teammates in parallel = 2x faster than sequential

**There are ZERO exceptions to the parallel requirement.**
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/research-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "research-$spec", description: "Parallel research for $spec")
```

**Fallback**: If TeamCreate fails, log a warning and fall back to direct `Task(subagent_type: research-analyst)` and `Task(subagent_type: Explore)` calls without a team. Skip Steps 3-6 and 8, and proceed directly to spawning agents via bare Task calls (the pre-team parallel pattern). The research output is the same either way.

### Step 3: Create Tasks

Create one TaskCreate per topic identified in the Pre-Step. Keep these brief — full prompts go in Step 4.

```text
For each topic:
  TaskCreate(
    subject: "[Topic name] research",
    description: "Research [topic] for $spec. Output: ./specs/$spec/.research-[topic-slug].md",
    activeForm: "Researching [topic]"
  )
```

**Output file naming**: `.research-[topic-slug].md` (e.g., `.research-oauth-patterns.md`, `.research-codebase.md`, `.research-quality.md`, `.research-related-specs.md`)

### Step 4: Spawn Teammates

<mandatory>
**ALL Task calls MUST be in ONE message to ensure true parallel execution.**

Spawn one teammate per task. Use the appropriate subagent_type:
- `research-analyst` for web/external research topics
- `Explore` for codebase analysis topics

Each Task call should include:
- `team_name: "research-$spec"` to join the team
- `name: "researcher-N"` or `"explorer-N"` for identification
- The full task description with spec path, output file, and context

**If you spawn teammates one at a time (separate messages), they run sequentially - THIS IS WRONG.**
**If you spawn all teammates in one message (multiple Task calls), they run in parallel - THIS IS CORRECT.**
</mandatory>

### Pre-Execution Checklist (REQUIRED)

Before spawning teammates, verify you have:
- [ ] Listed at least 2 distinct research topics
- [ ] Assigned appropriate agent type (Explore or research-analyst) to each topic
- [ ] Created TaskCreate for each topic
- [ ] Prepared unique output file path for each teammate (.research-*.md)
- [ ] Prepared all Task tool calls in your response (ready to send in ONE message)
- [ ] NOT written any code/searches yourself (you are a coordinator, not a researcher)

If all boxes are checked, proceed with spawning all teammates in ONE message.

### Teammate Spawning Pattern

Spawn all teammates in ONE message. Scale count by goal complexity (2 minimum, 5+ for complex goals). Each research-analyst handles ONE external topic; each Explore handles ONE codebase concern.

**Example** (2 teammates — adapt and add more as needed):

```text
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
    Do NOT explore codebase — Explore teammates handle that.
    When done, mark your task complete via TaskUpdate.")

Task(subagent_type: Explore, team_name: "research-$spec", name: "explorer-1",
  prompt: "Analyze codebase for spec: $spec
    Output: ./specs/$spec/.research-codebase.md
    Find existing patterns, dependencies, constraints related to [goal].
    Write findings to output file with sections: Existing Patterns, Dependencies, Constraints, Recommendations.")
```

For more topics, add more `researcher-N` (web) and `explorer-N` (code/quality/related-specs) teammates in the same message.

### Step 5: Wait for Completion

Wait for automatic teammate messages. Use TaskList to check progress. Proceed when ALL tasks are completed.

**Timeout**: If a teammate stalls, proceed with partial results and note incomplete topics in the merge step.

### Step 6: Shutdown Teammates

Send `shutdown_request` to each teammate via SendMessage after all tasks complete.

### Step 7: Collect Results

Proceed to "Merge Results" below to synthesize all teammate outputs into research.md.

### Step 8: Clean Up Team

Call `TeamDelete()`. If it fails, log a warning — orphaned teams are cleaned up in Step 1 on next run.

## Merge Results (After Parallel Research)

<mandatory>
After ALL parallel subagent tasks complete, YOU must merge results into a single research.md.
</mandatory>

### Merge Process

1. **Read all partial research files** created by subagents:
   - `.research-[topic-1].md`, `.research-[topic-2].md`, etc. (from multiple research-analyst agents)
   - Example: `.research-graphql.md`, `.research-caching.md`, `.research-auth.md` (from research-analyst agents)
   - `.research-codebase.md` (from Explore)
   - `.research-quality.md` (from Explore)
   - `.research-related-specs.md` (from Explore)

2. **Create unified `./specs/$spec/research.md`** with standard structure:
   ```markdown
   # Research: $spec

   ## Executive Summary
   [Synthesize key findings from ALL agents (all research-analyst + all Explore) - 2-3 sentences]

   ## External Research
   [Merge from ALL .research-[topic].md files created by research-analyst agents]
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

3. **Delete partial research files** after successful merge:
   ```bash
   rm ./specs/$spec/.research-*.md
   ```

4. **Quality check**: Ensure no duplicate information, consistent formatting

## Artifact Review

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

**Skip review if `--quick` flag detected in `$ARGUMENTS`.** If `--quick` is present, skip directly to "Walkthrough (Before Review)".
</mandatory>

After merging research.md and before presenting the walkthrough, invoke the `spec-reviewer` agent to validate the artifact.

### Review Loop

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read ./specs/$spec/research.md content
  2. Invoke spec-reviewer via Task tool (see delegation prompt below)
  3. Parse the last line of spec-reviewer output for signal:
     - If output contains "REVIEW_PASS":
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Break loop, proceed to Walkthrough
     - If output contains "REVIEW_FAIL" AND iteration < 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Extract "Feedback for Revision" from reviewer output
       c. Re-invoke research-analyst with revision prompt (see below)
       d. Re-read research.md (now updated by research-analyst)
       e. iteration = iteration + 1
       f. Continue loop
     - If output contains "REVIEW_FAIL" AND iteration >= 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Append warnings to .progress.md (see Graceful Degradation below)
       c. Break loop, proceed to Walkthrough
     - If output contains NEITHER signal (reviewer error):
       a. Treat as REVIEW_PASS (permissive)
       b. Log review iteration to .progress.md with status "REVIEW_PASS (no signal)"
       c. Break loop, proceed to Walkthrough
```

### Review Iteration Logging

After each review iteration (regardless of outcome), append to `./specs/$spec/.progress.md`:

```markdown
### Review: research (Iteration $iteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings from spec-reviewer output]
- Action: [revision applied / warnings appended / proceeded]
```

Where:
- **Status**: The actual signal from the reviewer (REVIEW_PASS or REVIEW_FAIL)
- **Findings**: A brief summary of the reviewer's findings (2-3 bullet points max)
- **Action**: What was done in response:
  - "revision applied" if REVIEW_FAIL and iteration < 3 (re-invoked research-analyst)
  - "warnings appended, proceeded" if REVIEW_FAIL and iteration >= 3 (graceful degradation)
  - "proceeded" if REVIEW_PASS

### Review Delegation Prompt

Invoke spec-reviewer via Task tool:

```yaml
subagent_type: spec-reviewer

You are reviewing the research artifact for spec: $spec
Spec path: ./specs/$spec/

Review iteration: $iteration of 3

Artifact content:
[Full content of ./specs/$spec/research.md]

Upstream artifacts (for cross-referencing):
[None - research is the first artifact]

$priorFindings

Apply the research rubric. Output structured findings with REVIEW_PASS or REVIEW_FAIL.

If REVIEW_FAIL, provide specific, actionable feedback for revision. Reference line numbers or sections.
```

Where `$priorFindings` is empty on iteration 1, or on subsequent iterations:
```text
Prior findings (from iteration $prevIteration):
[Full findings output from previous spec-reviewer invocation]
```

### Revision Delegation Prompt

On REVIEW_FAIL, re-invoke research-analyst with feedback:

```yaml
subagent_type: research-analyst

You are revising the research for spec: $spec
Spec path: ./specs/$spec/

Current artifact: ./specs/$spec/research.md

Reviewer feedback (iteration $iteration):
$reviewerFindings

Your task:
1. Read the current research.md
2. Address each finding from the reviewer
3. Update the artifact to resolve all issues
4. Write the revised content to ./specs/$spec/research.md

Focus on the specific issues flagged. Do not rewrite sections that passed review.
```

After the research-analyst returns, re-read `./specs/$spec/research.md` (now updated) and loop back to invoke spec-reviewer again.

### Graceful Degradation

If max iterations (3) reached without REVIEW_PASS, append to `./specs/$spec/.progress.md`:

```markdown
### Review Warning: research
- Max iterations (3) reached without REVIEW_PASS
- Proceeding with best available version
- Outstanding issues: [list from last REVIEW_FAIL findings]
```

Then proceed to Walkthrough.

### Error Handling

- **Reviewer fails to output signal**: treat as REVIEW_PASS (permissive) and log with status "REVIEW_PASS (no signal)"
- **Phase agent fails during revision**: retry the revision once; if it fails again, use the original artifact and proceed
- **Iteration counter edge cases**: if iteration is missing or invalid, default to 1

## Walkthrough (Before Review)

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP THIS SECTION.**

After research.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/research.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```
Research complete for '$spec'.
Output: ./specs/$spec/research.md

## What I Found

**Summary**: [1-2 sentences from Executive Summary - the core finding]

**Key Recommendations**:
1. [First recommendation]
2. [Second recommendation]
3. [Third recommendation]

**Feasibility**: [High/Medium/Low] | **Risk**: [High/Medium/Low] | **Effort**: [S/M/L/XL]
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct research review using AskUserQuestion after research is created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Research Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `researchApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
<!-- NOTE: Research feedback uses direct Task calls intentionally.
     Only requirements/design/tasks use the cleanup-and-recreate team pattern for re-invocations. -->
1. Ask: "What would you like changed?"
2. Invoke appropriate subagents with the feedback
3. Re-display walkthrough
4. Ask approval question again
5. Loop until approved

   Example prompt:
   ```
   You are conducting additional research for spec: $spec
   Spec path: ./specs/$spec/

   Current research: ./specs/$spec/research.md

   User feedback:
   $user_feedback

   Your task:
   1. Read the existing research.md
   2. Understand what additional information is needed
   3. Conduct focused research on the requested areas
   4. Output to ./specs/$spec/.research-additional.md

   Focus on addressing the specific gaps identified by the user.
   ```

3. **Merge updated results** into research.md

4. **After update, repeat review questions** (go back to "Research Review Questions")

5. **Continue until approved:** Loop until user responds with approval

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

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO REQUIREMENTS.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:requirements`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:requirements`

DO NOT automatically invoke the product-manager or run the requirements phase.
</mandatory>
