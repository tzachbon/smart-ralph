# Interview Algorithm (3-Phase)

Detailed pseudocode for the adaptive brainstorming dialogue algorithm.

## Phase 1: UNDERSTAND (Decision-Tree)

```text
UNDERSTAND:
  1. Read all available context:
     - .progress.md (prior phase answers, intent, goal)
     - Prior artifacts (research.md, requirements.md, etc.)
     - Original goal text
  2. Read the exploration territory provided by the calling command
  3. Identify what is UNKNOWN vs what is already decided
     - If prior phases already covered a topic, mark it RESOLVED. Skip it.
  4. Build the question tree:
     nodes = []
     for each area in exploration_territory:
       nodes.append({ topic: area, status: OPEN, dependency: [], finding: null })
     # Dependency ordering: if topic B requires knowing topic A first,
     # set B.dependency = [A]. Do not ask B until A is RESOLVED.

  DECISION-TREE TRAVERSAL:
    while any node.status == OPEN:
      # Select next node: first OPEN node whose dependencies are all RESOLVED
      node = next_unblocked_open_node(nodes)
      if node is null: break  # All remaining nodes are blocked (shouldn't happen)

      # Codebase-first check
      if node.topic is a codebase FACT (not a user decision):
        finding = explore_codebase(node.topic)
        node.status = RESOLVED
        node.finding = finding
        log: "Discovered: [topic] -> [finding]"
        continue

      # Ask user
      recommended = derive_recommendation(node.topic, context, prior_answers)
      AskUserQuestion:
        question: "[Context-aware question]. [Recommended: recommended.rationale]"
        options:
          - "[Recommended] [recommended.option]"
          - "[Alternative 1]"
          - "[Alternative 2 if needed]"
          - "Other"

      node.status = RESOLVED
      node.finding = user_answer

      # Resolve any dependent nodes that this answer makes obvious
      for dep_node in nodes where node in dep_node.dependency:
        if dep_node can be inferred from node.finding:
          dep_node.status = RESOLVED
          dep_node.finding = inferred_value
          log: "Inferred: [dep_topic] -> [inferred_value]"

      # Completion signal check
      if user_answer contains completion_signal:
        break

    -> Move to PROPOSE APPROACHES
```

**Key rules for question generation:**
- Each question builds on prior answers in THIS dialogue AND prior phases
- Reference specific things the user said ("You mentioned X, does that mean...")
- Never ask something .progress.md already answers
- Never ask generic questions. Every question must be grounded in the user's context.
- If you have enough context to propose meaningful approaches, stop and move on. Do not exhaust every open node mechanically.

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
- Trade-offs must be honest. No straw-man alternatives.
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
