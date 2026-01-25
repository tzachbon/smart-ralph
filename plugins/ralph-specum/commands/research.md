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

## Execute Research

<mandatory>
**PARALLEL EXECUTION IS MANDATORY - NO EXCEPTIONS**

You MUST follow this algorithm:

### Step 1: Identify Research Topics (REQUIRED)

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
- Additional topics: Domain-specific areas (spawn MULTIPLE research-analyst agents), quality commands (Explore), related specs (Explore)

**IMPORTANT: Break external research into MULTIPLE research-analyst agents**
- If the goal involves multiple external topics (e.g., "authentication + security"), spawn separate research-analyst agents for EACH topic
- Example: "Add OAuth with rate limiting" → 3 research-analyst agents (OAuth patterns, rate limiting strategies, security best practices)
- DO NOT combine multiple external topics into one research-analyst agent

### Step 2: Spawn ALL Agents in ONE Message (REQUIRED)

**CRITICAL**: You MUST include ALL Task tool calls in a SINGLE response message to ensure true parallel execution.

Use the appropriate subagent type for each topic:
- `subagent_type: Explore` - For codebase analysis (fast, read-only, Haiku model)
- `subagent_type: research-analyst` - For web research (needs WebSearch/WebFetch)

**If you spawn agents one at a time (separate messages), they run sequentially - THIS IS WRONG.**
**If you spawn all agents in one message (multiple Task calls), they run in parallel - THIS IS CORRECT.**

### Pre-Execution Checklist (REQUIRED)

Before spawning agents, verify you have:
- [ ] Listed at least 2 distinct research topics
- [ ] Assigned appropriate agent type (Explore or research-analyst) to each topic
- [ ] Prepared unique output file path for each agent (.research-*.md)
- [ ] Prepared all Task tool calls in your response (ready to send in ONE message)
- [ ] NOT written any code/searches yourself (you are a coordinator, not a researcher)

If all boxes are checked, proceed with Step 2 (spawn all agents in ONE message).
</mandatory>

### Fail-Safe: "But This Goal is Simple..."

<mandatory>
**Even trivial goals require parallel research.**

If you think the goal is "too simple" for parallel research:
- You're wrong - spawn at least 2 agents anyway
- Minimum: 1 Explore (codebase) + 1 research-analyst (web)
- Parallel execution is about SPEED, not complexity
- 2 agents in parallel = 2x faster than sequential

**There are ZERO exceptions to the parallel requirement.**
</mandatory>

### Minimum Parallel Pattern (Always Use)

Even for simple goals, spawn at least 2 agents in parallel:

```text
Task 1 (research-analyst - web): Search for best practices
Task 2 (Explore - codebase): Analyze existing patterns
```

**Example output before spawning:**
```
Research topics identified for parallel execution:
1. External best practices - research-analyst
2. Codebase analysis - Explore

Now spawning 2 research agents in parallel...
```

### Multi-Topic Pattern (Common Case)

For goals with multiple external topics, spawn MULTIPLE research-analyst agents:

```text
Task 1 (research-analyst): OAuth authentication patterns
Task 2 (research-analyst): Rate limiting strategies
Task 3 (research-analyst): Security best practices
Task 4 (Explore): Existing auth implementation
Task 5 (Explore): Quality commands discovery
```

**Example output before spawning:**
```
Research topics identified for parallel execution:
1. OAuth patterns - research-analyst
2. Rate limiting - research-analyst
3. Security practices - research-analyst
4. Existing auth code - Explore
5. Quality commands - Explore

Now spawning 5 research agents in parallel (3 research-analyst + 2 Explore)...
```

### Parallel Execution: Correct vs Incorrect

**WRONG (Sequential)** - Each Task call in separate message:
```
Message 1: Task(subagent_type: research-analyst, topic: best practices)
[wait for result]
Message 2: Task(subagent_type: Explore, topic: codebase)
[wait for result]
```
Result: Agents run one after another = SLOW

**CORRECT (Parallel)** - All Task calls in ONE message:
```
Message 1:
  Task(subagent_type: research-analyst, topic: best practices)
  Task(subagent_type: Explore, topic: codebase)
  Task(subagent_type: Explore, topic: quality commands)
[all agents start simultaneously]
```
Result: Agents run at the same time = FAST (2-3x faster)

### Standard Parallel Pattern (Recommended)

For most goals with diverse topics, spawn 3-4 agents in ONE message.

**CRITICAL: If the goal involves multiple external topics, spawn MULTIPLE research-analyst agents (one per topic).**

Example: "Add authentication with email notifications"
- research-analyst #1: Authentication patterns
- research-analyst #2: Email service best practices
- Explore #1: Existing auth/email code
- Explore #2: Quality commands

**Task 1 - External Research Topic A (research-analyst #1):**
```yaml
subagent_type: research-analyst

You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: [FIRST EXTERNAL TOPIC - e.g., Authentication patterns]

Focus ONLY on web research for THIS specific topic:
1. WebSearch for best practices, industry standards
2. WebSearch for common pitfalls and gotchas
3. Research relevant libraries/frameworks
4. Document findings in ./specs/$spec/.research-[topic-name].md

Do NOT explore codebase - Explore agents handle that in parallel.
Do NOT research other topics - other research-analyst agents handle those.
```

**Task 2 - External Research Topic B (research-analyst #2):**
```yaml
subagent_type: research-analyst

You are researching for spec: $spec
Spec path: ./specs/$spec/
Topic: [SECOND EXTERNAL TOPIC - e.g., Email service patterns]

Focus ONLY on web research for THIS specific topic:
1. WebSearch for best practices for this topic
2. WebSearch for common pitfalls
3. Research relevant libraries/tools
4. Document findings in ./specs/$spec/.research-[topic-name].md

Do NOT explore codebase - Explore agents handle that in parallel.
Do NOT research other topics - other research-analyst agents handle those.
```

**Task 3 - Codebase Analysis (Explore - fast):**
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

**Task 4 - Quality Commands Discovery (Explore - fast):**
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

**Task 5 - Related Specs Discovery (Explore - fast):**
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

### Complex Goal Pattern (5+ Agents)

**Example: Goal involves "Add GraphQL API with caching"**

**CRITICAL: This goal has TWO distinct external topics (GraphQL + Caching), so spawn TWO research-analyst agents (one per topic).**

Spawn 5 agents in ONE message (2 research-analyst + 3 Explore):

| Agent # | Type | Focus | Output File |
|---------|------|-------|-------------|
| 1 | research-analyst | GraphQL best practices (web) | .research-graphql.md |
| 2 | research-analyst | Caching strategies (web) | .research-caching.md |
| 3 | Explore | Existing API patterns (code) | .research-codebase.md |
| 4 | Explore | Quality commands | .research-quality.md |
| 5 | Explore | Related specs | .research-related-specs.md |

**Task 1 - GraphQL Best Practices (research-analyst):**
```yaml
subagent_type: research-analyst

Topic: GraphQL API best practices
Output: ./specs/$spec/.research-graphql.md

1. WebSearch: "GraphQL schema design best practices 2024"
2. WebSearch: "GraphQL resolvers performance patterns"
3. Research popular GraphQL libraries (Apollo, Yoga, etc.)
4. Document best practices, patterns, pitfalls
```

**Task 2 - Caching Strategies (research-analyst):**
```yaml
subagent_type: research-analyst

Topic: Caching strategies for GraphQL
Output: ./specs/$spec/.research-caching.md

1. WebSearch: "GraphQL caching strategies 2024"
2. WebSearch: "DataLoader patterns best practices"
3. Research cache invalidation approaches
4. Document caching patterns and recommendations
```

**Task 3 - Codebase Analysis (Explore):**
```yaml
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
```yaml
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
```yaml
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

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct research review using AskUserQuestion after research is created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Research Review Questions

After the research has been created and merged by the subagents, ask the user to review it and provide feedback.

**Review Question Flow:**

1. **Read the generated research.md** to understand what was found
2. **Ask initial review questions** to confirm the research meets their expectations:

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | Does the research cover all the areas you expected? | `researchCoverage` | Yes, comprehensive / Missing some areas / Need more depth / Other |
| 2 | Are the findings and recommendations helpful? | `findingsQuality` | Yes, very helpful / Somewhat helpful / Need more details / Other |
| 3 | Are there any specific areas you'd like researched further? | `additionalResearch` | No, looks complete / Yes, I have specific areas / Other |
| 4 | Any other feedback on the research? (or say 'approved' to proceed) | `researchFeedback` | Approved, let's proceed / Yes, I have feedback / Other |

### Store Research Review Responses

After review questions, append to `.progress.md` under a new section:

```markdown
### Research Review (from research.md)
- Research coverage: [responses.researchCoverage]
- Findings quality: [responses.findingsQuality]
- Additional research needed: [responses.additionalResearch]
- Research feedback: [responses.researchFeedback]
[Any follow-up responses from "Other" selections]
```

### Update Research Based on Feedback

<mandatory>
If the user provided feedback requiring changes (any answer other than "Yes, comprehensive", "Yes, very helpful", "No, looks complete", or "Approved, let's proceed"), you MUST:

1. Collect specific change requests from the user
2. Invoke appropriate subagents again with additional research instructions
3. Merge updated results
4. Repeat the review questions after updates
5. Continue loop until user approves
</mandatory>

**Update Flow:**

If changes are needed:

1. **Ask for specific changes:**
   ```
   What specific areas would you like researched further or what changes would you like to see?
   ```

2. **Invoke appropriate subagents with update prompt:**
   - Use `research-analyst` for additional web research
   - Use `Explore` for additional codebase analysis

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

## Output

```text
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
