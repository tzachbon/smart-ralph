---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash]
---

# Design Phase

You are generating technical design for a specification. Running this command implicitly approves the requirements phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN ARCHITECT.**

You MUST delegate ALL design work to the `architect-reviewer` subagent.
Do NOT create architecture diagrams, technical decisions, or design.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/requirements.md` exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Existing codebase patterns (via exploration)

## Execute Design

<mandatory>
Use the Task tool with `subagent_type: architect-reviewer` to generate design.
</mandatory>

Invoke architect-reviewer agent with prompt:

```
You are creating technical design for spec: $spec
Spec path: ./specs/$spec/

Context:
- Requirements: [include requirements.md content]
- Research: [include research.md if exists]

Your task:
1. Read and understand all requirements
2. Explore the codebase for existing patterns to follow
3. Design architecture with mermaid diagrams
4. Define component responsibilities and interfaces
5. Document technical decisions with rationale
6. Plan file structure (create/modify)
7. Define error handling and edge cases
8. Create test strategy
9. Output to ./specs/$spec/design.md

Use the design.md template with frontmatter:
---
spec: $spec
phase: design
created: <timestamp>
---

Include:
- Architecture diagram (mermaid)
- Data flow diagram (mermaid sequence)
- Technical decisions table
- File structure matrix
- TypeScript interfaces
- Error handling table
- Test strategy
```

## Update State

After design complete:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "design",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark requirements as implicitly approved
   - Set current phase to design

## Output

```
Design phase complete for '$spec'.

Output: ./specs/$spec/design.md

Next: Review design.md, then run /ralph-specum:tasks
```
