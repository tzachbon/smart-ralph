---
name: prototype
description: This skill should be used when Ralph Specum needs a throwaway prototype to validate research, requirements, or design before continuing to the next spec phase.
version: 0.1.0
---

# Prototype

Build throwaway proof code to answer one question before committing to the next phase.

## Pick The Question

Identify the question from the current artifact and upstream context:

- Logic or state model question: build a small terminal prototype.
- UI or interaction question: build several small UI variants in the app's existing routing style.
- Ambiguous question: inspect nearby code. Default to logic for backend modules and UI for pages or components.

State the prototype question at the top of the artifact.

## Rules

1. Mark prototype files as throwaway.
2. Put prototype code close to the related module or route.
3. Use one command to run it.
4. Keep state in memory unless the question is about persistence.
5. Skip tests and polish.
6. Show the relevant state after each action or variant switch.
7. Do not leave prototype code as production code.

## Result Capture

After prototype work, append to `progress.md`:

```markdown
## Prototype Result
- Question: <question answered>
- Artifact: <path or command>
- Result: <what was learned>
- Decision: <continue, revise artifact, or delete prototype>
```

Then redisplay the current phase walkthrough and ask the phase gate question again.
