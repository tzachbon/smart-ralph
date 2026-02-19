---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: "*"
---

# Requirements Phase

You are generating requirements for a specification. Running this command implicitly approves the research phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A PRODUCT MANAGER.**

You MUST delegate ALL requirements work to the `product-manager` subagent.
Do NOT write user stories, acceptance criteria, or requirements.md yourself.
</mandatory>

## Multi-Directory Resolution

This command uses the path resolver for dynamic spec path resolution:

**Path Resolver Functions**:
- `ralph_resolve_current()` - Resolves .current-spec to full path (handles bare name = ./specs/$name, full path = as-is)
- `ralph_find_spec(name)` - Find spec by name across all configured roots

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it
2. Otherwise, use `ralph_resolve_current()` to get the active spec path
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

The spec path is dynamically resolved - it may be in `./specs/` or any other configured specs directory.

## Validate

1. Check the resolved spec directory exists
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

## Execute Requirements (Team-Based)

<mandatory>
**Requirements uses Claude Code Teams for execution, matching the standard team lifecycle pattern.**

You MUST follow the full team lifecycle below. Use `product-manager` as the teammate subagent type.
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/requirements-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "requirements-$spec", description: "Requirements for $spec")
```

**Fallback**: If TeamCreate fails, log a warning and fall back to a direct `Task(subagent_type: product-manager)` call without a team. Skip Steps 3-6 and 8, and delegate directly via bare Task call.

### Step 3: Create Tasks

```text
TaskCreate(
  subject: "Generate requirements for $spec",
  description: "Generate requirements for spec: $spec
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
    7. Include interview responses in a 'User Decisions' section of requirements.md

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
    - Risk identification",
  activeForm: "Generating requirements"
)
```

### Step 4: Spawn Teammates

```text
Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1",
  prompt: "You are a requirements teammate for spec: $spec
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
    7. Include interview responses in a 'User Decisions' section of requirements.md

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

    When done, mark your task complete via TaskUpdate.")
```

### Step 5: Wait for Completion

Monitor teammate progress via TaskList and automatic teammate messages:

```text
1. Teammate sends a message automatically when task is complete or needs help
2. Messages are delivered automatically to you (no polling needed)
3. Use TaskList to check progress if needed
4. Wait until the task shows status: "completed"
```

**Timeout**: If the teammate does not complete within a reasonable period, check TaskList status and log the error. Consider retrying with a direct Task call if the team-based approach stalls.

### Step 6: Shutdown Teammates

```text
SendMessage(
  type: "shutdown_request",
  recipient: "pm-1",
  content: "Requirements complete, shutting down"
)
```

### Step 7: Collect Results

Read the generated `./specs/$spec/requirements.md` output from the teammate.

### Step 8: Clean Up Team

```text
TeamDelete()
```

This removes the team directory and task list for `requirements-$spec`. If TeamDelete fails, log a warning. Team files will be cleaned up on next invocation via the orphaned team check in Step 1.

## Walkthrough (Before Review)

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP THIS SECTION.**

After requirements.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/requirements.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```
Requirements complete for '$spec'.
Output: ./specs/$spec/requirements.md

## What I Created

**Goal**: [1 sentence summary of the goal]

**User Stories** ([count] total):
- US-1: [title]
- US-2: [title]
- US-3: [title]
[list all, keep titles brief]

**Requirements**: [X] functional, [Y] non-functional
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct requirements review using AskUserQuestion after requirements are created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Requirements Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `requirementsApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
1. Ask: "What would you like changed?"
2. Re-invoke product-manager using the team pattern (cleanup-and-recreate)
3. Re-display walkthrough
4. Ask approval question again
5. Loop until approved

<mandatory>
**Feedback Loop Team Pattern: Cleanup-and-Recreate**

When the user requests changes, do NOT reuse the existing team or send messages to completed teammates.
Instead, use the cleanup-and-recreate approach for each feedback iteration:

1. `TeamDelete()` the current team (cleanup previous session)
2. `TeamCreate()` a new team with the same name (fresh team for re-invocation)
3. `TaskCreate` with updated prompt including user feedback
4. Spawn new teammate, wait for completion, shutdown, `TeamDelete`

This is simpler and more reliable than trying to reuse teams or message completed teammates.
Each feedback iteration gets a completely fresh team context.
</mandatory>

**Re-invoke product-manager with team lifecycle (cleanup-and-recreate):**

```text
Step A: Check for orphaned team
  Read ~/.claude/teams/requirements-$spec/config.json
  If exists: TeamDelete() to clean up

Step B: Create new team
  TeamCreate(team_name: "requirements-$spec", description: "Requirements update for $spec")

Step C: Create task
  TaskCreate(
    subject: "Update requirements for $spec",
    description: "Update requirements based on user feedback...",
    activeForm: "Updating requirements"
  )

Step D: Spawn teammate
  Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1",
    prompt: "You are updating the requirements for spec: $spec
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
      When done, mark your task complete via TaskUpdate.")

Step E: Wait for completion
  Monitor via TaskList and automatic messages

Step F: Shutdown & cleanup
  SendMessage(type: "shutdown_request", recipient: "pm-1", content: "Update complete")
  TeamDelete()
```

**After update, repeat review questions** (go back to "Requirements Review Question")

**Continue until approved:** Loop until user responds with approval

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

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO DESIGN.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:design`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:design`

DO NOT automatically invoke the architect-reviewer or run the design phase.
</mandatory>
