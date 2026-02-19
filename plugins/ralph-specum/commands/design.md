---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: "*"
---

# Design Phase

You are generating technical design for a specification. Running this command implicitly approves the requirements phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN ARCHITECT.**

You MUST delegate ALL design work to the `architect-reviewer` subagent.
Do NOT create architecture diagrams, technical decisions, or design.md yourself.
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
2. Check the spec's requirements.md exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
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

## Execute Design (Team-Based)

<mandatory>
**Design uses Claude Code Teams for execution, matching the standard team lifecycle pattern.**

You MUST follow the full team lifecycle below. Use `architect-reviewer` as the teammate subagent type.
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/design-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "design-$spec", description: "Design for $spec")
```

**Fallback**: If TeamCreate fails, log a warning and fall back to a direct `Task(subagent_type: architect-reviewer)` call without a team. Skip Steps 3-6 and 8, and delegate directly via bare Task call.

### Step 3: Create Tasks

```text
TaskCreate(
  subject: "Generate technical design for $spec",
  description: "Generate technical design for spec: $spec
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
    10. Include interview responses in a 'Design Inputs' section of design.md

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
    - Test strategy",
  activeForm: "Generating design"
)
```

### Step 4: Spawn Teammates

```text
Task(subagent_type: architect-reviewer, team_name: "design-$spec", name: "architect-1",
  prompt: "You are creating technical design for spec: $spec
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
    10. Include interview responses in a 'Design Inputs' section of design.md

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
  recipient: "architect-1",
  content: "Design complete, shutting down"
)
```

### Step 7: Collect Results

Read the generated `./specs/$spec/design.md` output from the teammate.

### Step 8: Clean Up Team

```text
TeamDelete()
```

This removes the team directory and task list for `design-$spec`. If TeamDelete fails, log a warning. Team files will be cleaned up on next invocation via the orphaned team check in Step 1.

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

### Design Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `designApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
1. Ask: "What would you like changed?"
2. Re-invoke architect-reviewer using the team pattern (cleanup-and-recreate)
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

**Re-invoke architect-reviewer with team lifecycle (cleanup-and-recreate):**

```text
Step A: Check for orphaned team
  Read ~/.claude/teams/design-$spec/config.json
  If exists: TeamDelete() to clean up

Step B: Create new team
  TeamCreate(team_name: "design-$spec", description: "Design update for $spec")

Step C: Create task
  TaskCreate(
    subject: "Update design for $spec",
    description: "Update design based on user feedback...",
    activeForm: "Updating design"
  )

Step D: Spawn teammate
  Task(subagent_type: architect-reviewer, team_name: "design-$spec", name: "architect-1",
    prompt: "You are updating the technical design for spec: $spec
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

      Focus on addressing the specific feedback while maintaining design quality.
      When done, mark your task complete via TaskUpdate.")

Step E: Wait for completion
  Monitor via TaskList and automatic messages

Step F: Shutdown & cleanup
  SendMessage(type: "shutdown_request", recipient: "architect-1", content: "Update complete")
  TeamDelete()
```

**After update, repeat review questions** (go back to "Design Review Question")

**Continue until approved:** Loop until user responds with approval

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
