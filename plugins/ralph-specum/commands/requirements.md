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

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct requirements review using AskUserQuestion after requirements are created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Requirements Review Questions

After the requirements have been created by the product-manager agent, ask the user to review them and provide feedback.

**Review Question Flow:**

1. **Read the generated requirements.md** to understand what was created
2. **Ask initial review questions** to confirm the requirements meet their expectations:

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | Do the user stories capture your intended functionality? | `userStoriesApproval` | Yes, complete / Missing some stories / Need refinement / Other |
| 2 | Are the acceptance criteria clear and testable? | `acceptanceCriteriaApproval` | Yes, clear / Need more details / Some are unclear / Other |
| 3 | Are the priorities and scope appropriate? | `prioritiesApproval` | Yes, appropriate / Need adjustment / Missing items / Other |
| 4 | Any other feedback on the requirements? (or say 'approved' to proceed) | `requirementsFeedback` | Approved, let's proceed / Yes, I have feedback / Other |

### Store Requirements Review Responses

After review questions, append to `.progress.md` under a new section:

```markdown
### Requirements Review (from requirements.md)
- User stories approval: [responses.userStoriesApproval]
- Acceptance criteria approval: [responses.acceptanceCriteriaApproval]
- Priorities approval: [responses.prioritiesApproval]
- Requirements feedback: [responses.requirementsFeedback]
[Any follow-up responses from "Other" selections]
```

### Update Requirements Based on Feedback

<mandatory>
If the user provided feedback requiring changes (any answer other than "Yes, complete", "Yes, clear", "Yes, appropriate", or "Approved, let's proceed"), you MUST:

1. Collect specific change requests from the user
2. Invoke product-manager again with update instructions
3. Repeat the review questions after updates
4. Continue loop until user approves
</mandatory>

**Update Flow:**

If changes are needed:

1. **Ask for specific changes:**
   ```
   What specific changes would you like to see in the requirements?
   ```

2. **Invoke product-manager with update prompt:**
   ```
   You are updating the requirements for spec: $spec
   Spec path: ./specs/$spec/

   Current requirements: ./specs/$spec/requirements.md

   User feedback:
   $user_feedback

   Your task:
   1. Read the existing requirements.md
   2. Understand the user's feedback and concerns
   3. Update the requirements to address the feedback
   4. Maintain consistency with research findings
   5. Update requirements.md with the changes
   6. Append update notes to .progress.md explaining what changed

   Focus on addressing the specific feedback while maintaining requirements quality.
   ```

3. **After update, repeat review questions** (go back to "Requirements Review Questions")

4. **Continue until approved:** Loop until user responds with approval

## Update State

After requirements complete and approved:

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
