---
description: Generate implementation tasks from design
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Tasks Phase

You are generating implementation tasks for a specification. Running this command implicitly approves the design phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A TASK PLANNER.**

You MUST delegate ALL task planning to the `task-planner` subagent.
Do NOT write task breakdowns, verification steps, or tasks.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
3. Check `./specs/$spec/requirements.md` exists
4. Read `.ralph-state.json`
5. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/design.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Tasks Generation".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview, Design Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal execution context needed)
- REFACTOR: 3-5 questions (understand execution impact)
- GREENFIELD: 5-10 questions (full execution context)
- MID_SIZED: 3-7 questions (balanced approach)

### Tasks Interview (Single-Question Flow)

Use individual AskUserQuestion calls to gather execution and deployment context. This single-question flow enables adaptive questioning based on prior answers and context.

**Option Limit Rule**: Each question MUST have 2-4 options (max 4 for better UX). Keep most relevant options, combine similar ones.

**Parameter Chain Logic:**

Before asking each question, check if the answer already exists in .progress.md:

```
Parameter Chain:
  BEFORE asking any question:
    1. Parse .progress.md for existing answers
    2. Map question to semantic key:
       - "testing depth" → testingDepth, testing, testStrategy
       - "deployment considerations" → deployment, deploymentApproach, rollout
       - "execution priority" → priority, executionPriority
    3. If answer exists in prior responses:
       → SKIP this question (do not ask again)
       → Log: "Skipping [question] - already answered in previous phase"
    4. If no prior answer:
       → Ask via AskUserQuestion
```

**Question Piping:**

Before asking each question, replace {var} placeholders with values from .progress.md:
- `{goal}` - Original goal text
- `{intent}` - Intent classification (TRIVIAL, REFACTOR, etc.)
- `{problem}` - Problem description from Goal Interview
- `{constraints}` - Constraints from prior interviews
- `{users}` - Primary users from Requirements Interview
- `{priority}` - Priority tradeoffs from Requirements Interview
- `{technicalApproach}` - Technical approach from Research Interview
- `{architecture}` - Architecture style from Design Interview

If a variable is not found, use the original question text (graceful fallback).

**Single-Question Loop Structure:**

```
Initialize:
  askedCount = 0
  responses = {}
  intent = [from .progress.md Intent Classification]
  minRequired = intent.minQuestions (adjusted for tasks phase)
  maxAllowed = intent.maxQuestions (adjusted for tasks phase)
  completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

Tasks Question Pool (asked in order until completion):
  1. testingDepth: "What testing depth is needed for {goal}?"
  2. deploymentApproach: "Deployment considerations for {goal}?"
  3. executionPriority: "What's the execution priority for this work?"
  4. finalQuestion: "Any other execution context? (or say 'done' to proceed)" (always last, optional)

Loop:
  WHILE askedCount < maxAllowed:
    |
    +-- Select next question from pool
    |
    +-- Apply question piping: replace {var} with values from .progress.md
    |
    +-- Check parameter chain: does answer exist in .progress.md?
    |   |
    |   +-- Yes: SKIP this question, continue to next
    |   +-- No: Proceed to ask
    |
    +-- Ask single question:
    |   ```
    |   AskUserQuestion:
    |     question: "[Current question text with piped values]"
    |     options:
    |       - "[Option 1]"
    |       - "[Option 2]"
    |       - "[Option 3]"
    |       - "Other"
    |   ```
    |
    +-- Store response in responses[questionKey]
    |
    +-- askedCount++
    |
    +-- Check completion conditions:
    |   |
    |   +-- If askedCount >= minRequired AND user response matches completionSignal:
    |   |   → EXIT loop (user signaled done)
    |   |
    |   +-- If askedCount >= minRequired AND currentQuestion == finalQuestion:
    |   |   → EXIT loop (reached final optional question)
    |   |
    |   +-- If user selected "Other":
    |   |   → Ask follow-up (see Adaptive Depth)
    |   |   → DO NOT increment toward maxAllowed
    |   |
    |   +-- Otherwise:
    |       → CONTINUE to next question
```

**Question 1: Testing Depth**

```
AskUserQuestion:
  question: "What testing depth is needed for {goal}?"
  options:
    - "Standard - unit + integration (Recommended)"
    - "Minimal - POC only, add tests later"
    - "Comprehensive - include E2E"
    - "Other"
```

Store response as `responses.testingDepth`.

**Question 2: Deployment Considerations**

```
AskUserQuestion:
  question: "Deployment considerations for {goal}?"
  options:
    - "Standard CI/CD pipeline"
    - "Feature flag needed"
    - "Gradual rollout required"
    - "Other"
```

Store response as `responses.deploymentApproach`.

**Question 3: Execution Priority**

```
AskUserQuestion:
  question: "What's the execution priority for this work?"
  options:
    - "Ship fast - POC first, polish later"
    - "Balanced - reasonable quality with speed"
    - "Quality first - thorough from the start"
    - "Other"
```

Store response as `responses.executionPriority`.

**Final Question: Additional Execution Context (Optional)**

After reaching minRequired questions, ask final optional question:

```
AskUserQuestion:
  question: "Any other execution context? (or say 'done' to proceed)"
  options:
    - "No, let's proceed"
    - "Yes, I have more details"
    - "Other"
```

Store response as `responses.additionalTasksContext`.

**Completion Signal Detection:**

After each response, check if user wants to end the interview:
- If response contains any of: "done", "proceed", "skip", "enough", "that's all", "continue", "next"
- AND askedCount >= minRequired
- THEN exit the interview loop

### Adaptive Depth

If user selects "Other" for any question:
1. Ask a follow-up question to clarify using AskUserQuestion
2. Continue until clarity reached or 5 follow-up rounds complete
3. Each follow-up should probe deeper into the "Other" response

**Context-Specific Follow-up Instructions:**

Follow-up questions MUST be context-specific, not generic. When user provides an "Other" response:

1. **Acknowledge the specific response**: Reference what the user actually typed, not just "[Other response]"
2. **Ask a probing question based on response content**: Analyze keywords in their response to form relevant follow-up
3. **Include context from prior answers**: Reference earlier responses (from Goal, Research, Requirements, Design Interviews) to create continuity

**Follow-up questions should reference the specific 'Other' text.**

Example - if user types "Need contract tests with partners" for testing depth:
```
AskUserQuestion:
  question: "You mentioned contract tests with partners. Given your architecture is '{architecture}' and integration approach is '{integrationApproach}', which contract testing tool?"
  options:
    - "Pact for consumer-driven contracts"
    - "OpenAPI spec validation"
    - "Custom schema validation layer"
    - "Other"
```

Example - if user types "Blue-green with database migration" for deployment:
```
AskUserQuestion:
  question: "You want blue-green deployment with database migration. Since your priority is '{priority}', how should we handle the migration?"
  options:
    - "Zero-downtime with expand-contract pattern"
    - "Brief maintenance window acceptable"
    - "Shadow writes during transition period"
    - "Other"
```

**Do NOT use generic follow-ups like "Can you elaborate?" - always tailor to their specific response.**

### Store Tasks Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Tasks Interview (from tasks.md)
- Testing depth: [responses.testingDepth]
- Deployment approach: [responses.deploymentApproach]
- Execution priority: [responses.executionPriority]
- Additional execution context: [responses.additionalTasksContext]
[Any follow-up responses from "Other" selections]
```

**Context Accumulator Instructions:**

1. Read existing .progress.md content
2. Append new "### Tasks Interview" subsection under "## Interview Responses"
3. Use semantic keys matching the question type
4. For "Other" follow-up responses, append with descriptive key
5. Format must be parseable for parameter chain checks in subsequent phases

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```
Interview Context:
- Testing depth: [Answer]
- Deployment considerations: [Answer]
- Execution priority: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Tasks Generation

<mandatory>
Use the Task tool with `subagent_type: task-planner` to generate tasks.
ALL specs MUST follow POC-first workflow.
</mandatory>

Invoke task-planner agent with prompt:

```
You are creating implementation tasks for spec: $spec
Spec path: ./specs/$spec/

Context:
- Requirements: [include requirements.md content]
- Design: [include design.md content]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Read requirements and design thoroughly
2. Break implementation into POC-first phases:
   - Phase 1: Make It Work (POC) - validate idea, skip tests
   - Phase 2: Refactoring - clean up code
   - Phase 3: Testing - unit, integration, e2e
   - Phase 4: Quality Gates - lint, types, CI
3. Create atomic, autonomous-ready tasks
4. Each task MUST include:
   - **Do**: Exact implementation steps
   - **Files**: Exact file paths to create/modify
   - **Done when**: Explicit success criteria
   - **Verify**: Command to verify completion
   - **Commit**: Conventional commit message
   - _Requirements: references_
   - _Design: references_
5. Count total tasks
6. Output to ./specs/$spec/tasks.md
7. Include interview responses in an "Execution Context" section of tasks.md

Use the tasks.md template with frontmatter:
---
spec: $spec
phase: tasks
total_tasks: <count>
created: <timestamp>
---

Critical rules:
- Tasks must be executable without human interaction
- Each task = one commit
- Verify command must be runnable
- POC phase allows shortcuts, later phases clean up
```

## Update State

After tasks complete:

1. Count total tasks from generated file
2. Update `.ralph-state.json`:
   ```json
   {
     "phase": "tasks",
     "totalTasks": <count>,
     "awaitingApproval": true,
     ...
   }
   ```

3. Update `.progress.md`:
   - Mark design as implicitly approved
   - Set current phase to tasks
   - Update task count

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage tasks file:
   ```bash
   git add ./specs/$spec/tasks.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add implementation tasks"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```
Tasks phase complete for '$spec'.

Output: ./specs/$spec/tasks.md
Total tasks: <count>
[If commitSpec: "Spec committed and pushed."]

Next: Review tasks.md, then run /ralph-specum:implement to start execution
```
