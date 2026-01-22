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

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **Prior interview responses** to enable parameter chain (skip already-answered questions)

```text
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal user/priority context needed)
- REFACTOR: 3-5 questions (understand scope and priorities)
- GREENFIELD: 5-10 questions (full user and priority context)
- MID_SIZED: 3-7 questions (balanced approach)

### Requirements Interview (Single-Question Flow)

**Interview Framework**: Apply standard single-question loop from `skills/interview-framework/SKILL.md`

### Phase-Specific Configuration

- **Phase**: Requirements Interview
- **Parameter Chain Mappings**: primaryUsers, priorityTradeoffs, successCriteria
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`, `{technicalApproach}`
- **Variables Not Yet Available**: `{users}`, `{priority}` (populated by this phase)
- **Storage Section**: `### Requirements Interview (from requirements.md)`

### Requirements Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | Who are the primary users of this feature? | Required | `primaryUsers` | Internal developers only / End users via UI / Both developers and end users / Other |
| 2 | What priority tradeoffs should we consider for {goal}? | Required | `priorityTradeoffs` | Prioritize speed of delivery / Prioritize code quality and maintainability / Prioritize feature completeness / Other |
| 3 | What defines success for this feature? | Required | `successCriteria` | Feature works as specified / High performance/reliability required / User satisfaction metrics / Other |
| 4 | Any other requirements context? (or say 'done' to proceed) | Optional | `additionalReqContext` | No, let's proceed / Yes, I have more details / Other |

### Store Requirements Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Requirements Interview (from requirements.md)
- Primary users: [responses.primaryUsers]
- Priority tradeoffs: [responses.priorityTradeoffs]
- Success criteria: [responses.successCriteria]
- Additional requirements context: [responses.additionalReqContext]
[Any follow-up responses from "Other" selections]
```

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```text
Interview Context:
- Primary users: [Answer]
- Priority tradeoffs: [Answer]
- Success criteria: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Requirements

<mandatory>
Use the Task tool with `subagent_type: product-manager` to generate requirements.
</mandatory>

Invoke product-manager agent with prompt:

```text
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

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage requirements file:
   ```bash
   git add ./specs/$spec/requirements.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add requirements"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```text
Requirements phase complete for '$spec'.

Output: ./specs/$spec/requirements.md
[If commitSpec: "Spec committed and pushed."]

Next: Review requirements.md, then run /ralph-specum:design
```
