# Interview Algorithm (3-Phase)

Detailed pseudocode for the adaptive brainstorming dialogue algorithm.

## Phase 1: UNDERSTAND (Adaptive Dialogue)

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
    |   -> Ask context-specific follow-up (see Adaptive Depth in SKILL.md)
    |   -> DO NOT increment askedCount for follow-ups
    |
    +-- Check completion signals (see SKILL.md)
    |
    +-- Decide: ask another question or move to PROPOSE APPROACHES
    |   (If you have enough context to propose meaningful approaches, move on)
```

**Key rules for question generation:**
- Each question builds on prior answers in THIS dialogue AND prior phases
- Reference specific things the user said ("You mentioned X -- does that mean...")
- Never ask something .progress.md already answers
- Never ask generic questions -- every question must be grounded in the user's context

## Phase 2: PROPOSE APPROACHES

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
- Trade-offs must be honest -- no straw-man alternatives
- Apply YAGNI: strip unnecessary complexity from all approaches

## Phase 3: CONFIRM & STORE

```text
CONFIRM & STORE:
  1. Brief recap to the user:
     "Here's what I'll pass to the [agent name]:
      - [Key decision 1]
      - [Key decision 2]
      - [Chosen approach summary]
      Does this look right?"
  2. If user corrects something, update before storing
  3. Store in .progress.md (see Context Accumulator in SKILL.md)
  4. Proceed to subagent delegation
```
