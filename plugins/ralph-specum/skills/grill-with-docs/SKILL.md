---
name: grill-with-docs
description: This skill should be used when Ralph Specum needs to question a phase plan against project docs, code terminology, CONTEXT.md, or ADR decisions before generating research, requirements, design, or tasks.
version: 0.1.0
---

# Grill With Docs

Stress-test the active Ralph phase against the repo language and existing decisions before artifact generation.

## Workflow

1. Inspect existing docs first:
   - `CONTEXT-MAP.md`
   - `CONTEXT.md`
   - `docs/adr/`
   - phase artifacts in the active spec
   - nearby code when the answer may already exist
2. If the code or docs answer the question, use that evidence and do not ask.
3. If ambiguity remains, ask one native question at a time.
4. Give the recommended answer first.
5. Resolve dependencies between decisions before moving to the next question.
6. Capture stable terminology in `CONTEXT.md` as decisions settle.
7. Create ADRs only when the decision is hard to reverse, surprising without context, and based on a real tradeoff.

## Question Rules

- Ask one question at a time.
- Use native question UI when available.
- Provide 2 to 3 choices.
- Put the recommended choice first.
- Add a short impact note for each choice.
- Do not ask if codebase inspection can answer.
- Stop when the phase has enough context to proceed.

## CONTEXT.md Rules

Use `CONTEXT.md` only as a glossary.

Include:
- terms
- role names
- domain relationships
- boundary definitions

Do not include:
- implementation details
- task plans
- architecture choices
- scratch notes

## ADR Rules

Create an ADR only when all are true:

1. Cost to change later is meaningful.
2. Future reader would wonder why.
3. Alternatives existed and one was chosen for a reason.

If any condition is false, skip ADR.
