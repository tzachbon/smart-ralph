---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
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

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Design".

### Design Interview

Use AskUserQuestion to gather architecture and technology context:

```
AskUserQuestion:
  questions:
    - question: "What architecture style fits this feature?"
      options:
        - "Extend existing architecture (Recommended)"
        - "Create isolated module"
        - "Major refactor to support this"
        - "Other"
    - question: "Any technology constraints?"
      options:
        - "No constraints"
        - "Must use specific library/framework"
        - "Must avoid certain dependencies"
        - "Other"
```

### Adaptive Depth

If user selects "Other" for any question:
1. Ask a follow-up question to clarify using AskUserQuestion
2. Continue until clarity reached or 5 follow-up rounds complete
3. Each follow-up should probe deeper into the "Other" response

### Interview Context Format

After interview, format responses as:

```
Interview Context:
- Architecture style: [Answer]
- Technology constraints: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

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

[If interview was conducted, include:]
Interview Context:
$interview_context

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
10. Include interview responses in a "Design Inputs" section of design.md

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
