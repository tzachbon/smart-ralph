---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Design Phase

You are generating technical design for a specification. Running this command implicitly approves the requirements phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN ARCHITECT.**

You MUST delegate ALL design work to the `architect-reviewer` subagent.
Do NOT create architecture diagrams, technical decisions, or design.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/requirements.md` exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Existing codebase patterns (via exploration)

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Design".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal architecture context needed)
- REFACTOR: 3-5 questions (understand architecture impact)
- GREENFIELD: 5-10 questions (full architecture context)
- MID_SIZED: 3-7 questions (balanced approach)

### Design Interview (Single-Question Flow)

Use individual AskUserQuestion calls to gather architecture and technology context. This single-question flow enables adaptive questioning based on prior answers and context.

**Option Limit Rule**: Each question MUST have 2-4 options (max 4 for better UX). Keep most relevant options, combine similar ones.

**Parameter Chain Logic:**

Before asking each question, check if the answer already exists in .progress.md:

```
Parameter Chain:
  BEFORE asking any question:
    1. Parse .progress.md for existing answers
    2. Map question to semantic key:
       - "architecture style" → architecture, architectureStyle
       - "technology constraints" → constraints, techConstraints
       - "integration approach" → integration, integrationApproach
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

If a variable is not found, use the original question text (graceful fallback).

**Single-Question Loop Structure:**

```
Initialize:
  askedCount = 0
  responses = {}
  intent = [from .progress.md Intent Classification]
  minRequired = intent.minQuestions (adjusted for design phase)
  maxAllowed = intent.maxQuestions (adjusted for design phase)
  completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

Design Question Pool (asked in order until completion):
  1. architectureStyle: "What architecture style fits this feature for {goal}?"
  2. techConstraints: "Any technology constraints for {goal}?"
  3. integrationApproach: "How should this integrate with existing systems?"
  4. finalQuestion: "Any other design context? (or say 'done' to proceed)" (always last, optional)

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

**Question 1: Architecture Style**

```
AskUserQuestion:
  question: "What architecture style fits this feature for {goal}?"
  options:
    - "Extend existing architecture (Recommended)"
    - "Create isolated module"
    - "Major refactor to support this"
    - "Other"
```

Store response as `responses.architectureStyle`.

**Question 2: Technology Constraints**

```
AskUserQuestion:
  question: "Any technology constraints for {goal}?"
  options:
    - "No constraints"
    - "Must use specific library/framework"
    - "Must avoid certain dependencies"
    - "Other"
```

Store response as `responses.techConstraints`.

**Question 3: Integration Approach**

```
AskUserQuestion:
  question: "How should this integrate with existing systems?"
  options:
    - "Use existing APIs and interfaces"
    - "Create new integration layer"
    - "Minimal integration needed"
    - "Other"
```

Store response as `responses.integrationApproach`.

**Final Question: Additional Design Context (Optional)**

After reaching minRequired questions, ask final optional question:

```
AskUserQuestion:
  question: "Any other design context? (or say 'done' to proceed)"
  options:
    - "No, let's proceed"
    - "Yes, I have more details"
    - "Other"
```

Store response as `responses.additionalDesignContext`.

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
3. **Include context from prior answers**: Reference earlier responses (from Goal, Research, Requirements Interviews) to create continuity

**Follow-up questions should reference the specific 'Other' text.**

Example - if user types "Microservices with event sourcing" for architecture style:
```
AskUserQuestion:
  question: "You mentioned microservices with event sourcing. Given your users are '{users}' and priority is '{priority}', which event store approach fits?"
  options:
    - "Kafka for high throughput events"
    - "EventStoreDB for event-sourced aggregates"
    - "Simple database with outbox pattern"
    - "Other"
```

Example - if user types "Must avoid vendor lock-in" for technology constraints:
```
AskUserQuestion:
  question: "You want to avoid vendor lock-in. Since your technical approach is '{technicalApproach}', how strict is this requirement?"
  options:
    - "Strict - only open source, self-hostable"
    - "Moderate - cloud-agnostic but managed OK"
    - "Flexible - minimize but accept some lock-in"
    - "Other"
```

**Do NOT use generic follow-ups like "Can you elaborate?" - always tailor to their specific response.**

### Store Design Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Design Interview (from design.md)
- Architecture style: [responses.architectureStyle]
- Technology constraints: [responses.techConstraints]
- Integration approach: [responses.integrationApproach]
- Additional design context: [responses.additionalDesignContext]
[Any follow-up responses from "Other" selections]
```

**Context Accumulator Instructions:**

1. Read existing .progress.md content
2. Append new "### Design Interview" subsection under "## Interview Responses"
3. Use semantic keys matching the question type
4. For "Other" follow-up responses, append with descriptive key
5. Format must be parseable for parameter chain checks in subsequent phases

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```
Interview Context:
- Architecture style: [Answer]
- Technology constraints: [Answer]
- Integration approach: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Design

<mandatory>
Use the Task tool with `subagent_type: architect-reviewer` to generate design.
</mandatory>

Invoke architect-reviewer agent with prompt:

```
You are creating technical design for spec: $spec
Spec path: ./specs/$spec/

Context:
- Requirements: [include requirements.md content]
- Research: [include research.md if exists]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Read and understand all requirements
2. Explore the codebase for existing patterns to follow
3. Design architecture with mermaid diagrams
4. Define component responsibilities and interfaces
5. Document technical decisions with rationale
6. Plan file structure (create/modify)
7. Define error handling and edge cases
8. Create test strategy
9. Output to ./specs/$spec/design.md
10. Include interview responses in a "Design Inputs" section of design.md

Use the design.md template with frontmatter:
---
spec: $spec
phase: design
created: <timestamp>
---

Include:
- Architecture diagram (mermaid)
- Data flow diagram (mermaid sequence)
- Technical decisions table
- File structure matrix
- TypeScript interfaces
- Error handling table
- Test strategy
```

## Update State

After design complete:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "design",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark requirements as implicitly approved
   - Set current phase to design

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage design file:
   ```bash
   git add ./specs/$spec/design.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add technical design"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```text
Design phase complete for '$spec'.

Output: ./specs/$spec/design.md
[If commitSpec: "Spec committed and pushed."]

Next: Review design.md, then run /ralph-specum:tasks
```
