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

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal architecture context needed)
- REFACTOR: 3-5 questions (understand architecture impact)
- GREENFIELD: 5-10 questions (full architecture context)
- MID_SIZED: 3-7 questions (balanced approach)

### Design Interview (Single-Question Flow)

**Interview Framework**: Apply standard single-question loop from `skills/interview-framework/SKILL.md`

### Phase-Specific Configuration

- **Phase**: Design Interview
- **Parameter Chain Mappings**: architectureStyle, techConstraints, integrationApproach
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`, `{technicalApproach}`, `{users}`, `{priority}`
- **Storage Section**: `### Design Interview (from design.md)`

### Design Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | What architecture style fits this feature for {goal}? | Required | `architectureStyle` | Extend existing architecture (Recommended) / Create isolated module / Major refactor to support this / Other |
| 2 | Any technology constraints for {goal}? | Required | `techConstraints` | No constraints / Must use specific library/framework / Must avoid certain dependencies / Other |
| 3 | How should this integrate with existing systems? | Required | `integrationApproach` | Use existing APIs and interfaces / Create new integration layer / Minimal integration needed / Other |
| 4 | Any other design context? (or say 'done' to proceed) | Optional | `additionalDesignContext` | No, let's proceed / Yes, I have more details / Other |

### Store Design Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Design Interview (from design.md)
- Architecture style: [responses.architectureStyle]
- Technology constraints: [responses.techConstraints]
- Integration approach: [responses.integrationApproach]
- Additional design context: [responses.additionalDesignContext]
[Any follow-up responses from "Other" selections]
```

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```
Interview Context:
- Architecture style: [Answer]
- Technology constraints: [Answer]
- Integration approach: [Answer]
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

## Walkthrough (Before Review)

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP THIS SECTION.**

After design.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/design.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```
Design complete for '$spec'.
Output: ./specs/$spec/design.md

## What I Designed

**Approach**: [1-2 sentences from Overview - the core approach]

**Components**:
- [Component A]: [brief purpose]
- [Component B]: [brief purpose]
[list main components]

**Key Decisions**:
- [Decision 1]: [choice made]
- [Decision 2]: [choice made]

**Files**: [X] to create, [Y] to modify
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct design review using AskUserQuestion after design is created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Design Review Questions

After the design has been created by the architect-reviewer agent, ask the user to review it and provide feedback.

**Review Question Flow:**

1. **Read the generated design.md** to understand what was created
2. **Ask initial review questions** to confirm the design meets their expectations:

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | Does the architecture approach align with your expectations? | `architectureApproval` | Yes, looks good / Needs changes / I have questions / Walk me through them / Other |
| 2 | Are the technical decisions appropriate for your needs? | `technicalDecisionsApproval` | Yes, approved / Some concerns / Need changes / Walk me through them / Other |
| 3 | Is the component structure clear and suitable? | `componentStructureApproval` | Yes, clear / Needs refinement / Major changes needed / Walk me through them / Other |
| 4 | Any other feedback on the design? (or say 'approved' to proceed) | `designFeedback` | Approved, let's proceed / Yes, I have feedback / Walk me through them / Other |

### Store Design Review Responses

After review questions, append to `.progress.md` under a new section:

```markdown
### Design Review (from design.md)
- Architecture approval: [responses.architectureApproval]
- Technical decisions approval: [responses.technicalDecisionsApproval]
- Component structure approval: [responses.componentStructureApproval]
- Design feedback: [responses.designFeedback]
[Any follow-up responses from "Other" selections]
```

### Update Design Based on Feedback

<mandatory>
If the user provided feedback requiring changes (any answer other than "Yes, looks good", "Yes, approved", "Yes, clear", or "Approved, let's proceed"), you MUST:

1. Collect specific change requests from the user
2. Invoke architect-reviewer again with update instructions
3. Repeat the review questions after updates
4. Continue loop until user approves
</mandatory>

**Update Flow:**

If changes are needed:

1. **Ask for specific changes:**
   ```
   What specific changes would you like to see in the design?
   ```

2. **Invoke architect-reviewer with update prompt:**
   ```
   You are updating the technical design for spec: $spec
   Spec path: ./specs/$spec/

   Current design: ./specs/$spec/design.md

   User feedback:
   $user_feedback

   Your task:
   1. Read the existing design.md
   2. Understand the user's feedback and concerns
   3. Update the design to address the feedback
   4. Maintain consistency with requirements
   5. Update design.md with the changes
   6. Append update notes to .progress.md explaining what changed

   Focus on addressing the specific feedback while maintaining the overall design quality.
   ```

3. **After update, repeat review questions** (go back to "Design Review Questions")

4. **Continue until approved:** Loop until user responds with approval

## Update State

After design complete and approved:

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

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage design file:
   ```bash
   git add ./specs/$spec/design.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add technical design"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO TASKS.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:tasks`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:tasks`

DO NOT automatically invoke the task-planner or run the tasks phase.
</mandatory>
