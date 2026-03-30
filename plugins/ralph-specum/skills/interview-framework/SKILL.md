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

## Recommendation Format

Every question asked via `AskUserQuestion` in Phase 1 leads with the recommended option (except when options are symmetric, in which case `[Recommended]` may be omitted):

```yaml
AskUserQuestion:
  question: "[Context-aware question referencing prior answers]. [One sentence rationale for the recommendation.]"
  options:
    - "[Recommended] [Option text -- the AI's suggested answer]"
    - "[Alternative 1]"
    - "[Alternative 2 if needed]"
    - "Other"
```

Rules:
- `[Recommended]` is a label prefix on the first option only.
- The rationale sits in the question text, not the option label.
- Option count still 2-4 max (Option Limit Rule preserved).
- If there is no meaningful recommendation (truly symmetric choice), omit the `[Recommended]` label rather than placing it arbitrarily.

Example:

```yaml
AskUserQuestion:
  question: "Where should the spec live? You only have one specs directory configured, so the default is fine unless you want to reorganize."
  options:
    - "[Recommended] ./specs/ (default)"
    - "Let me configure a different path"
    - "Other"
```

## Codebase-First Exploration

Before asking any question, determine whether the answer is a **codebase fact** or a **user decision**:

- **Codebase fact**: something discoverable by reading code, config, or existing specs (e.g., which framework is used, whether an interface already exists, what a file currently does). Use the Explore agent to find it. Never ask the user.
- **User decision**: a preference, priority, trade-off, or constraint that only the user can answer (e.g., which approach to take, what the success criteria are, what's in scope). Ask via AskUserQuestion.

Only ask what you cannot discover yourself.

## Completion Signal Detection

After each response, check if user wants to end early:

```text
completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

tokens = tokenize(userResponse.lower())  # split on whitespace/punctuation
for signal in completionSignals:
  if signal in tokens:  # exact token match, not substring
    -> SKIP remaining questions, move to PROPOSE APPROACHES
```

## 3-Phase Algorithm

### Phase 1: UNDERSTAND (Decision-Tree)

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
- Each question builds on prior answers in this dialogue AND prior phases.
- Reference specific things the user said ("You mentioned X - does that mean...").
- Never ask something `.progress.md` already answers.
- Never ask a generic question. Every question must be grounded in the user's context.
- If you have enough context to propose meaningful approaches, stop and move on. Do not exhaust every open node mechanically.

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
- Trade-offs must be honest. No straw-man alternatives.
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
- Chosen approach: [name] - [brief description]
[Any follow-up responses from "Other" selections]
```
