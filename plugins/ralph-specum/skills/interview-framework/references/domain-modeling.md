# Domain Modeling During Grilling

Use domain modeling to sharpen project language while the design tree is active.

## Locate the Applicable Context

1. Resolve the repository root.
2. If `CONTEXT-MAP.md` exists, read it and select the context that owns the current capability. If the mapped `CONTEXT.md` does not exist, create it at that mapped path only when the first term for that context is resolved.
3. Otherwise read the root `CONTEXT.md` when present.
4. If neither file exists, create a root `CONTEXT.md` only when the first project-specific domain term becomes resolved. Never fall back to the root when `CONTEXT-MAP.md` names the owning context. Do not create an empty placeholder during preflight.
5. If multiple contexts could own the term and repository evidence cannot decide, add context ownership to the user-decision frontier.

## Work the Language

- Challenge a term that conflicts with the glossary in the same round.
- Replace vague or overloaded words with a proposed canonical term.
- Invent a concrete scenario when a relationship, boundary, lifecycle, or ownership rule remains fuzzy.
- Read the relevant code when the user describes current behavior. Surface any contradiction as evidence for the next frontier.
- Keep general programming terms out of the domain glossary.

## Update CONTEXT.md Inline

Write a resolved term during the round that resolves it. Do not wait until the interview ends.

Use this format:

```markdown
# <Context Name>

<One or two sentences describing the context.>

## Language

**<Canonical Term>**:
<One or two sentences defining what the concept is.>
_Avoid_: <conflicting or discouraged alternatives>
```

Apply these rules:

- Pick one canonical term.
- Define what the concept is, not how code implements it.
- Keep definitions to one or two sentences.
- List competing names under `_Avoid_` when doing so prevents future ambiguity.
- Preserve unrelated glossary entries and existing context structure.

Do not store requirements, implementation details, task notes, or technical decisions in `CONTEXT.md`. Do not create ADRs from the interview framework; keep technical decisions in the spec's `design.md`.
