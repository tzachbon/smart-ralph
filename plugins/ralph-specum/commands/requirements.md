---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Requirements Phase

Generate requirements for a specification. Running this command implicitly approves the research phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A PRODUCT MANAGER.**
Delegate ALL requirements work to the `product-manager` subagent via Task tool.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json` and clear approval flag: `awaitingApproval: false`

## Gather Context

Read: `./specs/$spec/research.md` (if exists), `./specs/$spec/.progress.md`, original goal from progress file

## Interview

<skill-reference>
**Apply skill**: `skills/interview-framework/SKILL.md`
Use interview framework for single-question loop, parameter chain, and completion signals.
</skill-reference>

**Skip if --quick flag in $ARGUMENTS.**

### Requirements Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | Who are the primary users of this feature? | Required | `primaryUsers` | Internal devs / End users via UI / Both / Other |
| 2 | What priority tradeoffs for {goal}? | Required | `priorityTradeoffs` | Speed of delivery / Code quality / Feature completeness / Other |
| 3 | What defines success for this feature? | Required | `successCriteria` | Works as specified / High performance / User satisfaction / Other |
| 4 | Any other requirements context? (or 'done') | Optional | `additionalReqContext` | No, proceed / Yes, more details / Other |

Store responses in `.progress.md` under `### Requirements Interview (from requirements.md)`

## Execute Requirements

Use Task tool with `subagent_type: product-manager`:

```text
You are generating requirements for spec: $spec
Spec path: ./specs/$spec/

Context:
- Research: [research.md content if exists]
- Original goal: [from progress]
- Interview: [interview responses]

Create requirements.md with: user stories, acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, dependencies.
```

## Review Loop

**Skip if --quick flag.** Ask user to review generated requirements. If changes needed, invoke product-manager again with feedback and repeat until approved.

## Update State

Update `.ralph-state.json`: `{ "phase": "requirements", "awaitingApproval": true }`

## Commit Spec (if enabled)

If `commitSpec` is true in state: stage, commit (`spec($spec): add requirements`), push.

## Output

After requirements.md is created, read the generated file and extract key information for the walkthrough.

### Extract from requirements.md

1. **Goal Summary**: Read the project goal from `## Goal` or `## Overview` section
2. **User Stories**: Extract from `## User Stories` section:
   - Count total user stories (US-*)
   - List each story ID and title
   - Count acceptance criteria per story
3. **Functional Requirements**: Extract from `## Functional Requirements` section:
   - Count total FRs
   - Count by priority (High/Medium/Low)
4. **Non-Functional Requirements**: Extract from `## Non-Functional Requirements` section:
   - Count total NFRs

### Display Walkthrough

```text
Requirements phase complete for '$spec'.
Output: ./specs/$spec/requirements.md
[If commitSpec: "Spec committed and pushed."]

## Walkthrough

### Key Points
- **Goal**: [Goal summary from requirements]
- **User Stories**:
  | ID | Title | ACs |
  |----|-------|-----|
  | US-1 | [title] | [count] |
  | US-2 | [title] | [count] |
  [... for each user story]

### Metrics
| Metric | Value |
|--------|-------|
| User Stories | [count] |
| Functional Requirements | [count] (High: [n], Med: [n], Low: [n]) |
| Non-Functional Requirements | [count] |

### Review Focus
- Verify all user needs captured in user stories
- Check acceptance criteria are testable
- Confirm priority levels match business needs

Next: Review requirements.md, then run /ralph-specum:design
```

**Error handling**: If requirements.md cannot be read, display warning "Warning: Could not read requirements.md for walkthrough" and skip the Walkthrough section entirely - still show "Requirements phase complete" and the output path. If requirements.md exists but is missing sections or metrics cannot be extracted, show "N/A" for those fields and continue with available information. The command must complete successfully regardless of walkthrough extraction errors.
