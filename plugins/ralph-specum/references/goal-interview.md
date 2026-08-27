# Goal Grill

> Used by: start.md

This reference defines the pre-research grill in normal mode. Quick mode skips it.

## Prerequisite

Classify intent first using `intent-classification.md`. Use intent to seed relevant design-tree branches, not to set a question count.

## Run the Grill

Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` in full.

The framework reads prior artifacts, the specification index, relevant domain context, and repository facts before it asks the user for decisions. It asks the whole user-decision frontier in numbered rounds and does not start research until the user confirms shared understanding.

## Goal Exploration Territory

Use these areas to seed the design tree. Add or remove branches as the evidence and answers require:

- **Problem** - pain point or need behind the goal
- **Constraints** - performance, compatibility, timeline, integration, or policy boundaries
- **Success** - observable behavior or evidence that proves the work succeeded
- **Scope** - explicit inclusions, exclusions, and deferred branches
- **Existing system** - related indexed specs, domain concepts, code paths, and reusable behavior
- **Approach** - viable implementation shapes and their trade-offs

## Bug-Fix Territory

For `BUG_FIX`, seed the tree with the causal chain instead of using a fixed questionnaire:

- reproduction steps and smallest failing command
- expected behavior and observed behavior
- regression point or relevant change history
- existing failing test or missing reproducer
- affected scope and required behavior preservation
- evidence that will prove the fix

Resolve repository facts through tests, code, configuration, logs, and git history. Ask the user only for experience or decisions that the repository cannot provide.

## Resolved Spec Location

`start.md` resolves spec location before creating the spec directory. Read that location as settled context and do not ask for it again during the goal grill.

## Store Goal Context

The interview framework appends each round to `.progress.md`. Keep intent metadata compact:

```markdown
## Interview Format
- Version: 2.0

## Intent Classification
- Type: [BUG_FIX|TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Keywords matched: [list of matched keywords]

## Interview Responses

### Goal Grill - Round 1
- Facts resolved: [fact and evidence]
- Decisions: [topic] -> [answer]
- Reproduction command: [exact command or manual steps, for BUG_FIX]
- Frontier after round: [remaining decisions or empty]

### Goal Grill - Confirmed
- Shared understanding: confirmed
- Chosen approach: [name] -- [one-line rationale]
- Spec location: [resolved directory]
```

## Pass Context to Research Team

Include the confirmed goal-grill context in each research task:

```text
Goal Grill Context:
[Include resolved facts, decisions, scope exclusions, domain language, and chosen approach from .progress.md]

Use this context to focus research. Do not reopen confirmed user decisions unless new evidence contradicts them.
```
