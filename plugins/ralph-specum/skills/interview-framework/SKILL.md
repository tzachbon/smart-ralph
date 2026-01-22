---
name: interview-framework
description: Standard single-question adaptive interview loop used across all spec phases
---

# Interview Framework

Canonical interview algorithm for all spec phases. Each phase references this skill instead of duplicating the ~50-line algorithm.

## Option Limit Rule

Each question MUST have 2-4 options (max 4 for better UX). Keep most relevant options, combine similar ones.

## Single-Question Loop Structure

```text
Initialize:
  askedCount = 0
  responses = {}
  intent = [from .progress.md Intent Classification]
  minRequired = intent.minQuestions (phase-adjusted)
  maxAllowed = intent.maxQuestions (phase-adjusted)
  completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

Loop:
  WHILE askedCount < maxAllowed:
    |
    +-- Select next question from phase-specific pool
    |
    +-- Apply question piping: replace {var} with values from .progress.md
    |
    +-- Check parameter chain: does answer exist in .progress.md?
    |   |
    |   +-- Yes: SKIP this question, continue to next
    |   |       Log: "Skipping [question] - already answered in previous phase"
    |   +-- No: Proceed to ask
    |
    +-- Ask single question:
    |   AskUserQuestion:
    |     question: "[Current question text with piped values]"
    |     options:
    |       - "[Option 1]"
    |       - "[Option 2]"
    |       - "[Option 3]"
    |       - "Other"
    |
    +-- Store response in responses[questionKey]
    |
    +-- askedCount++
    |
    +-- Check completion conditions:
    |   |
    |   +-- If askedCount >= minRequired AND user response matches completionSignal:
    |   |   -> EXIT loop (user signaled done)
    |   |
    |   +-- If askedCount >= minRequired AND currentQuestion == finalQuestion:
    |   |   -> EXIT loop (reached final optional question)
    |   |
    |   +-- If user selected "Other":
    |   |   -> Ask follow-up (see Adaptive Depth)
    |   |   -> DO NOT increment toward maxAllowed
    |   |
    |   +-- Otherwise:
    |       -> CONTINUE to next question
```

## Completion Signal Detection

After each response, check if user wants to end:

```text
userResponse = [last answer from AskUserQuestion]
if askedCount >= minRequired:
  for signal in completionSignals:
    if signal in userResponse.lower():
      -> EXIT interview loop
```

Completion signals: "done", "proceed", "skip", "enough", "that's all", "continue", "next"

## Adaptive Depth

If user selects "Other" for any question:

1. Ask context-specific follow-up (NEVER generic "elaborate")
2. Continue until clarity reached or 5 rounds complete
3. Each follow-up round uses single question focused on the "Other" response

### Context-Specific Follow-up Instructions

Follow-up questions MUST be context-specific, not generic. When user provides an "Other" response:

1. **Acknowledge the specific response**: Reference what the user actually typed, not just "[Other response]"
2. **Ask a probing question based on response content**: Analyze keywords in their response to form relevant follow-up
3. **Include context from prior answers**: Reference earlier responses to create continuity

**Do NOT use generic follow-ups like "Can you elaborate?" - always tailor to their specific response.**

Example - if user types "We need GraphQL support" for constraints:
```yaml
AskUserQuestion:
  question: "You mentioned needing GraphQL support. Is this for:
    - the entire API layer, or
    - specific endpoints only?
    Also, does this relate to your earlier goal of '{goal}'?"
  options:
    - "Full API layer - replace REST"
    - "Hybrid - GraphQL for new endpoints only"
    - "Specific queries for mobile clients"
    - "Other"
```

Example - if user types "Security is critical" for success criteria:
```yaml
AskUserQuestion:
  question: "You emphasized security is critical. Given your constraint of '{constraints}', which security aspects matter most?"
  options:
    - "Authentication and authorization"
    - "Data encryption at rest and in transit"
    - "Audit logging and compliance"
    - "Other"
```

## Context Accumulator Pattern

After each interview, update `.progress.md`:

1. Read existing .progress.md content
2. Append new interview subsection under "## Interview Responses"
3. Use semantic keys matching the question type
4. For "Other" responses, append with descriptive key
5. Format must be parseable for parameter chain

### Storage Format

```text
### [Phase] Interview (from [phase].md)
- [Key1]: [response1]
- [Key2]: [response2]
- [Key3]: [response3]
[Any follow-up responses from "Other" selections]
```

## Canonical Semantic Keys (camelCase standard)

| Phase | Key | Aliases |
|-------|-----|---------|
| start | problem | problem, issue |
| start | constraints | constraints, limitations |
| start | success | success, successCriteria |
| research | technicalApproach | approach, tech |
| research | knownConstraints | constraints |
| research | integrationPoints | integration |
| requirements | primaryUsers | users, audience |
| requirements | priorityTradeoffs | priority |
| requirements | successCriteria | success, kpis |
| design | architectureStyle | architecture |
| design | techConstraints | constraints |
| design | integrationApproach | integration |
| tasks | testingDepth | testing, testStrategy |
| tasks | deploymentApproach | deployment |
| tasks | executionPriority | priority |

## Parameter Chain Logic

Before asking any question, check if the answer already exists:

```text
Parameter Chain:
  BEFORE asking any question:
    1. Parse .progress.md for existing answers
    2. Map question to semantic key (see table above)
    3. If answer exists in prior responses:
       -> SKIP this question (do not ask again)
       -> Log: "Skipping [question] - already answered in previous phase"
    4. If no prior answer:
       -> Ask via AskUserQuestion
```

## Question Piping

Before asking each question, replace `{var}` placeholders with values from `.progress.md`:

| Variable | Source | Available From |
|----------|--------|----------------|
| `{goal}` | Original goal text | start.md |
| `{intent}` | Intent classification | start.md |
| `{problem}` | Problem description | start.md Goal Interview |
| `{constraints}` | Constraints | start.md Goal Interview |
| `{users}` | Primary users | requirements.md |
| `{priority}` | Priority tradeoffs | requirements.md |
| `{technicalApproach}` | Technical approach | research.md |
| `{architecture}` | Architecture style | design.md |

**Fallback Behavior**: If variable not found, use original question text (graceful fallback)
