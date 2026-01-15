---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Requirements Phase

You are generating requirements for a specification. Running this command implicitly approves the research phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A PRODUCT MANAGER.**

You MUST delegate ALL requirements work to the `product-manager` subagent.
Do NOT write user stories, acceptance criteria, or requirements.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json`
3. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read available context:
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Original goal from conversation or progress file

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Requirements".

### Requirements Interview

Use AskUserQuestion to gather user and priority context:

```
AskUserQuestion:
  questions:
    - question: "Who are the primary users of this feature?"
      options:
        - "Internal developers only"
        - "End users via UI"
        - "Both developers and end users"
        - "Other"
    - question: "What priority tradeoffs should we consider?"
      options:
        - "Prioritize speed of delivery"
        - "Prioritize code quality and maintainability"
        - "Prioritize feature completeness"
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
- Primary users: [Answer]
- Priority tradeoffs: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Requirements

<mandatory>
Use the Task tool with `subagent_type: product-manager` to generate requirements.
</mandatory>

Invoke product-manager agent with prompt:

```
You are generating requirements for spec: $spec
Spec path: ./specs/$spec/

Context:
- Research: [include research.md content if exists]
- Original goal: [from conversation or progress]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Analyze the goal and research findings
2. Create user stories with acceptance criteria
3. Define functional requirements (FR-*) with priorities
4. Define non-functional requirements (NFR-*)
5. Document glossary, out-of-scope items, dependencies
6. Output to ./specs/$spec/requirements.md
7. Include interview responses in a "User Decisions" section of requirements.md

Use the requirements.md template with frontmatter:
---
spec: $spec
phase: requirements
created: <timestamp>
---

Focus on:
- Testable acceptance criteria
- Clear priority levels
- Explicit success criteria
- Risk identification
```

## Update State

After requirements complete:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "requirements",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark research as implicitly approved
   - Set current phase to requirements

## Output

```
Requirements phase complete for '$spec'.

Output: ./specs/$spec/requirements.md

Next: Review requirements.md, then run /ralph-specum:design
```
