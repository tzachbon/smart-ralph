---
name: interview-framework
description: Adaptive brainstorming-style dialogue for all spec phases (Understand, Propose Approaches, Confirm & Store)
version: 0.1.0
user-invocable: false
---

# Interview Framework

Adaptive brainstorming dialogue algorithm for all spec phases. Each phase command references this skill and provides its own **exploration territory** (phase-specific areas to probe).

## Option Limit Rule

Each question MUST have 2-4 options (max 4). Keep the most relevant options, combine similar ones.

## Intent-Based Depth Scaling

Read `.progress.md` for intent classification. Scale dialogue depth accordingly:

| Intent | Questions |
|--------|-----------|
| TRIVIAL | 1-2 |
| REFACTOR | 3-5 |
| MID_SIZED | 3-7 |
| GREENFIELD | 5-10 |

## Completion Signal Detection

After each response, check if user wants to end early:

```text
completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

if askedCount >= minRequired:
  for signal in completionSignals:
    if signal in userResponse.lower():
      -> SKIP remaining questions, move to PROPOSE APPROACHES
```

## 3-Phase Algorithm

### Phase 1: UNDERSTAND (Adaptive Dialogue)

```text
UNDERSTAND:
  1. Read all available context:
     - .progress.md (prior phase answers, intent, goal)
     - Prior artifacts (research.md, requirements.md, etc.)
     - Original goal text
  2. Read the exploration territory provided by the calling command
  3. Identify what is UNKNOWN vs what is already decided
     - If prior phases already covered a topic, SKIP it
     - Only ask about what still needs clarification
  4. Set depth from intent:
     - minRequired = intent.minQuestions
     - maxAllowed = intent.maxQuestions
  5. askedCount = 0

  WHILE askedCount < maxAllowed:
    |
    +-- Generate next question from context + exploration territory
    |   (Questions emerge from what you've learned so far, NOT from a fixed pool)
    |
    +-- Context-based skip check:
    |   Read .progress.md holistically. If this topic was already
    |   answered in a prior phase, SKIP it. Log: "Already covered: [topic]"
    |
    +-- Ask single question:
    |   AskUserQuestion:
    |     question: "[Context-aware question referencing prior answers]"
    |     options:
    |       - "[Option 1]"
    |       - "[Option 2]"
    |       - "[Option 3 if needed]"
    |       - "Other"
    |
    +-- askedCount++
    |
    +-- If user selected "Other":
    |   -> Ask context-specific follow-up (see Adaptive Depth below)
    |   -> DO NOT increment askedCount for follow-ups
    |
    +-- Check completion signals (see above)
    |
    +-- Decide: ask another question or move to PROPOSE APPROACHES
    |   (If you have enough context to propose meaningful approaches, move on)
```

**Key rules for question generation:**
- Each question builds on prior answers in THIS dialogue AND prior phases
- Reference specific things the user said ("You mentioned X — does that mean...")
- Never ask something .progress.md already answers
- Never ask generic questions — every question must be grounded in the user's context

### Phase 2: PROPOSE APPROACHES

```text
PROPOSE APPROACHES:
  1. Synthesize the dialogue into 2-3 distinct approaches
  2. Each approach MUST include:
     - Name (short label)
     - Description (1-2 sentences)
     - Trade-offs (pros and cons)
  3. Lead with your recommendation
  4. Present via AskUserQuestion:

  AskUserQuestion:
    question: "Based on our discussion, here are the approaches I see:

      **A) [Recommended] [Name]**
      [Description]. Trade-off: [pro] vs [con].

      **B) [Name]**
      [Description]. Trade-off: [pro] vs [con].

      **C) [Name]** (if applicable)
      [Description]. Trade-off: [pro] vs [con].

      Which approach fits best?"
    options:
      - "A) [Name]"
      - "B) [Name]"
      - "C) [Name]" (if applicable)
      - "Other"

  5. If user picks "Other":
     -> Ask what they'd change or combine
     -> Iterate until approach is confirmed (max 3 rounds)
  6. Store chosen approach as primary input for the subagent
```

**Approach rules:**
- Always present at least 2 approaches (never just 1)
- Maximum 3 approaches (more causes decision fatigue)
- The recommended approach goes first
- Trade-offs must be honest — no straw-man alternatives
- Apply YAGNI: strip unnecessary complexity from all approaches

### Phase 3: CONFIRM & STORE

```text
CONFIRM & STORE:
  1. Brief recap to the user:
     "Here's what I'll pass to the [agent name]:
      - [Key decision 1]
      - [Key decision 2]
      - [Chosen approach summary]
      Does this look right?"
  2. If user corrects something, update before storing
  3. Store in .progress.md (see Context Accumulator below)
  4. Proceed to subagent delegation
```

## Adaptive Depth (Other Responses)

If user selects "Other" for any question:

1. Ask a **context-specific** follow-up (NEVER generic "elaborate")
2. Continue until clarity is reached or 5 rounds complete
3. Each follow-up uses a single question focused on their response

**Follow-up questions MUST be context-specific, not generic.** When user provides an "Other" response:

1. **Acknowledge the specific response**: Reference what the user actually typed
2. **Ask a probing question based on response content**: Analyze keywords in their response
3. **Include context from prior answers**: Reference earlier responses to create continuity

**Do NOT use generic follow-ups like "Can you elaborate?" — always tailor to their specific response.**

Example — if user types "We need GraphQL support" for a technical approach question:
```yaml
AskUserQuestion:
  question: "You mentioned needing GraphQL support. Is this for the entire API layer, or specific endpoints only?"
  options:
    - "Full API layer - replace REST"
    - "Hybrid - GraphQL for new endpoints only"
    - "Specific queries for mobile clients"
    - "Other"
```

Example — if user types "Security is critical" for success criteria:
```yaml
AskUserQuestion:
  question: "You emphasized security is critical. Given your earlier constraints, which security aspects matter most?"
  options:
    - "Authentication and authorization"
    - "Data encryption at rest and in transit"
    - "Audit logging and compliance"
    - "Other"
```

## Context Accumulator Pattern

After each interview, update `.progress.md`:

1. Read existing .progress.md content
2. Append new section under "## Interview Responses"
3. Use descriptive keys that reflect what was actually discussed
4. Include the chosen approach

### Storage Format

```text
### [Phase] Interview (from [phase].md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] — [brief description]
[Any follow-up responses from "Other" selections]
```
