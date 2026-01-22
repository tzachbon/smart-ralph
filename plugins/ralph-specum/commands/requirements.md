---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Requirements Phase

You are generating requirements for a specification. Running this command implicitly approves the research phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A PRODUCT MANAGER.**

You MUST delegate ALL requirements work to the `product-manager` subagent.
Do NOT write user stories, acceptance criteria, or requirements.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json`
3. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read available context:
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Original goal from conversation or progress file

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Requirements".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **Prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal user/priority context needed)
- REFACTOR: 3-5 questions (understand scope and priorities)
- GREENFIELD: 5-10 questions (full user and priority context)
- MID_SIZED: 3-7 questions (balanced approach)

### Requirements Interview (Single-Question Flow)

Use individual AskUserQuestion calls to gather user and priority context. This single-question flow enables adaptive questioning based on prior answers and context.

**Option Limit Rule**: Each question MUST have 2-4 options (max 4 for better UX). Keep most relevant options, combine similar ones.

**Parameter Chain Logic:**

Before asking each question, check if the answer already exists in .progress.md:

```
Parameter Chain:
  BEFORE asking any question:
    1. Parse .progress.md for existing answers
    2. Map question to semantic key:
       - "primary users" → users, primaryUsers
       - "priority tradeoffs" → priority, constraints
       - "success criteria" → success, successCriteria
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
- `{technicalApproach}` - Technical approach from Research Interview

If a variable is not found, use the original question text (graceful fallback).

**Single-Question Loop Structure:**

```
Initialize:
  askedCount = 0
  responses = {}
  intent = [from .progress.md Intent Classification]
  minRequired = intent.minQuestions (adjusted for requirements phase)
  maxAllowed = intent.maxQuestions (adjusted for requirements phase)
  completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

Requirements Question Pool (asked in order until completion):
  1. primaryUsers: "Who are the primary users of this feature?"
  2. priorityTradeoffs: "What priority tradeoffs should we consider for {goal}?"
  3. successCriteria: "What defines success for this feature?"
  4. finalQuestion: "Any other requirements context? (or say 'done' to proceed)" (always last, optional)

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

**Question 1: Primary Users**

```
AskUserQuestion:
  question: "Who are the primary users of this feature?"
  options:
    - "Internal developers only"
    - "End users via UI"
    - "Both developers and end users"
    - "Other"
```

Store response as `responses.primaryUsers`.

**Question 2: Priority Tradeoffs**

```
AskUserQuestion:
  question: "What priority tradeoffs should we consider for {goal}?"
  options:
    - "Prioritize speed of delivery"
    - "Prioritize code quality and maintainability"
    - "Prioritize feature completeness"
    - "Other"
```

Store response as `responses.priorityTradeoffs`.

**Question 3: Success Criteria**

```
AskUserQuestion:
  question: "What defines success for this feature?"
  options:
    - "Feature works as specified"
    - "High performance/reliability required"
    - "User satisfaction metrics"
    - "Other"
```

Store response as `responses.successCriteria`.

**Final Question: Additional Requirements Context (Optional)**

After reaching minRequired questions, ask final optional question:

```
AskUserQuestion:
  question: "Any other requirements context? (or say 'done' to proceed)"
  options:
    - "No, let's proceed"
    - "Yes, I have more details"
    - "Other"
```

Store response as `responses.additionalReqContext`.

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
3. **Include context from prior answers**: Reference earlier responses (from Goal Interview, Research Interview) to create continuity

**Follow-up questions should reference the specific 'Other' text.**

Example - if user types "Both internal tools and customer portal" for primary users:
```
AskUserQuestion:
  question: "You mentioned both internal tools and customer portal as users. Given your technical approach of '{technicalApproach}', which should we prioritize?"
  options:
    - "Internal tools first - validate with team"
    - "Customer portal first - external value"
    - "Build shared core for both simultaneously"
    - "Other"
```

Example - if user types "We need audit compliance" for success criteria:
```
AskUserQuestion:
  question: "You mentioned audit compliance as success criteria. Since your constraint is '{constraints}', what compliance framework applies?"
  options:
    - "SOC 2 Type II"
    - "GDPR / data privacy"
    - "Industry-specific (HIPAA, PCI, etc.)"
    - "Other"
```

**Do NOT use generic follow-ups like "Can you elaborate?" - always tailor to their specific response.**

### Store Requirements Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Requirements Interview (from requirements.md)
- Primary users: [responses.primaryUsers]
- Priority tradeoffs: [responses.priorityTradeoffs]
- Success criteria: [responses.successCriteria]
- Additional requirements context: [responses.additionalReqContext]
[Any follow-up responses from "Other" selections]
```

**Context Accumulator Instructions:**

1. Read existing .progress.md content
2. Append new "### Requirements Interview" subsection under "## Interview Responses"
3. Use semantic keys matching the question type
4. For "Other" follow-up responses, append with descriptive key
5. Format must be parseable for parameter chain checks in subsequent phases

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```
Interview Context:
- Primary users: [Answer]
- Priority tradeoffs: [Answer]
- Success criteria: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Requirements

<mandatory>
Use the Task tool with `subagent_type: product-manager` to generate requirements.
</mandatory>

Invoke product-manager agent with prompt:

```
You are generating requirements for spec: $spec
Spec path: ./specs/$spec/

Context:
- Research: [include research.md content if exists]
- Original goal: [from conversation or progress]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Analyze the goal and research findings
2. Create user stories with acceptance criteria
3. Define functional requirements (FR-*) with priorities
4. Define non-functional requirements (NFR-*)
5. Document glossary, out-of-scope items, dependencies
6. Output to ./specs/$spec/requirements.md
7. Include interview responses in a "User Decisions" section of requirements.md

Use the requirements.md template with frontmatter:
---
spec: $spec
phase: requirements
created: <timestamp>
---

Focus on:
- Testable acceptance criteria
- Clear priority levels
- Explicit success criteria
- Risk identification
```

## Update State

After requirements complete:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "requirements",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark research as implicitly approved
   - Set current phase to requirements

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage requirements file:
   ```bash
   git add ./specs/$spec/requirements.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add requirements"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```
Requirements phase complete for '$spec'.

Output: ./specs/$spec/requirements.md
[If commitSpec: "Spec committed and pushed."]

Next: Review requirements.md, then run /ralph-specum:design
```
