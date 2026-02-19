---
description: Generate implementation tasks from design
argument-hint: [spec-name]
allowed-tools: "*"
---

# Tasks Phase

You are generating implementation tasks for a specification. Running this command implicitly approves the design phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A TASK PLANNER.**

You MUST delegate ALL task planning to the `task-planner` subagent.
Do NOT write task breakdowns, verification steps, or tasks.md yourself.
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
2. Check the spec's design.md exists. If not, error: "Design not found. Run /ralph-specum:design first."
3. Check the spec's requirements.md exists
4. Read `.ralph-state.json`
5. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/design.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Tasks Generation".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```text
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview, Design Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal execution context needed)
- REFACTOR: 3-5 questions (understand execution impact)
- GREENFIELD: 5-10 questions (full execution context)
- MID_SIZED: 3-7 questions (balanced approach)

### Tasks Interview (Single-Question Flow)

**Interview Framework**: Apply standard single-question loop from `skills/interview-framework/SKILL.md`

### Phase-Specific Configuration

- **Phase**: Tasks Interview
- **Parameter Chain Mappings**: testingDepth, deploymentApproach, executionPriority
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`, `{technicalApproach}`, `{users}`, `{priority}`, `{architecture}`
- **Storage Section**: `### Tasks Interview (from tasks.md)`

### Tasks Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | What testing depth is needed for {goal}? | Required | `testingDepth` | Standard - unit + integration (Recommended) / Minimal - POC only, add tests later / Comprehensive - include E2E / Other |
| 2 | Deployment considerations for {goal}? | Required | `deploymentApproach` | Standard CI/CD pipeline / Feature flag needed / Gradual rollout required / Other |
| 3 | What's the execution priority for this work? | Required | `executionPriority` | Ship fast - POC first, polish later / Balanced - reasonable quality with speed / Quality first - thorough from the start / Other |
| 4 | Any other execution context? (or say 'done' to proceed) | Optional | `additionalTasksContext` | No, let's proceed / Yes, I have more details / Other |

### Store Tasks Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Tasks Interview (from tasks.md)
- Testing depth: [responses.testingDepth]
- Deployment approach: [responses.deploymentApproach]
- Execution priority: [responses.executionPriority]
- Additional execution context: [responses.additionalTasksContext]
[Any follow-up responses from "Other" selections]
```

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```text
Interview Context:
- Testing depth: [Answer]
- Deployment considerations: [Answer]
- Execution priority: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Tasks Generation (Team-Based)

<mandatory>
**Tasks generation uses Claude Code Teams for execution, matching the standard team lifecycle pattern.**

You MUST follow the full team lifecycle below. Use `task-planner` as the teammate subagent type.
ALL specs MUST follow POC-first workflow.
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/tasks-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "tasks-$spec", description: "Task planning for $spec")
```

**Fallback**: If TeamCreate fails, log a warning and fall back to a direct `Task(subagent_type: task-planner)` call without a team. Skip Steps 3-6 and 8, and delegate directly via bare Task call.

### Step 3: Create Tasks

```text
TaskCreate(
  subject: "Generate implementation tasks for $spec",
  description: "Generate implementation tasks for spec: $spec
    Spec path: ./specs/$spec/

    Context:
    - Requirements: [include requirements.md content]
    - Design: [include design.md content]

    [If interview was conducted, include:]
    Interview Context:
    $interview_context

    Your task:
    1. Read requirements and design thoroughly
    2. Break implementation into POC-first phases:
       - Phase 1: Make It Work (POC) - validate idea, skip tests
       - Phase 2: Refactoring - clean up code
       - Phase 3: Testing - unit, integration, e2e
       - Phase 4: Quality Gates - lint, types, CI
    3. Create atomic, autonomous-ready tasks
    4. Each task MUST include:
       - **Do**: Exact implementation steps
       - **Files**: Exact file paths to create/modify
       - **Done when**: Explicit success criteria
       - **Verify**: Command to verify completion
       - **Commit**: Conventional commit message
       - _Requirements: references_
       - _Design: references_
    5. Count total tasks
    6. Output to ./specs/$spec/tasks.md
    7. Include interview responses in an 'Execution Context' section of tasks.md

    Use the tasks.md template with frontmatter:
    ---
    spec: $spec
    phase: tasks
    total_tasks: <count>
    created: <timestamp>
    ---

    Critical rules:
    - Tasks must be executable without human interaction
    - Each task = one commit
    - Verify command must be runnable
    - POC phase allows shortcuts, later phases clean up",
  activeForm: "Generating tasks"
)
```

### Step 4: Spawn Teammates

```text
Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1",
  prompt: "You are a task planning teammate for spec: $spec
    Spec path: ./specs/$spec/

    Context:
    - Requirements: [include requirements.md content]
    - Design: [include design.md content]

    [If interview was conducted, include:]
    Interview Context:
    $interview_context

    Your task:
    1. Read requirements and design thoroughly
    2. Break implementation into POC-first phases:
       - Phase 1: Make It Work (POC) - validate idea, skip tests
       - Phase 2: Refactoring - clean up code
       - Phase 3: Testing - unit, integration, e2e
       - Phase 4: Quality Gates - lint, types, CI
    3. Create atomic, autonomous-ready tasks
    4. Each task MUST include:
       - **Do**: Exact implementation steps
       - **Files**: Exact file paths to create/modify
       - **Done when**: Explicit success criteria
       - **Verify**: Command to verify completion
       - **Commit**: Conventional commit message
       - _Requirements: references_
       - _Design: references_
    5. Count total tasks
    6. Output to ./specs/$spec/tasks.md
    7. Include interview responses in an 'Execution Context' section of tasks.md

    Use the tasks.md template with frontmatter:
    ---
    spec: $spec
    phase: tasks
    total_tasks: <count>
    created: <timestamp>
    ---

    Critical rules:
    - Tasks must be executable without human interaction
    - Each task = one commit
    - Verify command must be runnable
    - POC phase allows shortcuts, later phases clean up

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
  recipient: "planner-1",
  content: "Tasks complete, shutting down"
)
```

### Step 7: Collect Results

Read the generated `./specs/$spec/tasks.md` output from the teammate.

### Step 8: Clean Up Team

```text
TeamDelete()
```

This removes the team directory and task list for `tasks-$spec`. If TeamDelete fails, log a warning. Team files will be cleaned up on next invocation via the orphaned team check in Step 1.

## Artifact Review

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

**Skip review if `--quick` flag detected in `$ARGUMENTS`.** If `--quick` is present, skip directly to "Walkthrough (Before Review)".
</mandatory>

After task-planner completes tasks.md and before presenting the walkthrough, invoke the `spec-reviewer` agent to validate the artifact.

### Review Loop

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read ./specs/$spec/tasks.md content
  2. Invoke spec-reviewer via Task tool (see delegation prompt below)
  3. Parse the last line of spec-reviewer output for signal:
     - If output contains "REVIEW_PASS":
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Break loop, proceed to Walkthrough
     - If output contains "REVIEW_FAIL" AND iteration < 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Extract "Feedback for Revision" from reviewer output
       c. Re-invoke task-planner with revision prompt (see below)
       d. Re-read updated tasks.md
       e. iteration = iteration + 1
       f. Continue loop
     - If output contains "REVIEW_FAIL" AND iteration >= 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Append warnings to .progress.md (see Graceful Degradation below)
       c. Break loop, proceed to Walkthrough
     - If output contains NEITHER signal (reviewer error):
       a. Treat as REVIEW_PASS (permissive)
       b. Log review iteration to .progress.md with status "REVIEW_PASS (no signal)"
       c. Break loop, proceed to Walkthrough
```

### Review Iteration Logging

After each review iteration (regardless of outcome), append to `./specs/$spec/.progress.md`:

```markdown
### Review: tasks (Iteration $iteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings from spec-reviewer output]
- Action: [revision applied / warnings appended / proceeded]
```

Where:
- **Status**: The actual signal from the reviewer (REVIEW_PASS or REVIEW_FAIL)
- **Findings**: A brief summary of the reviewer's findings (2-3 bullet points max)
- **Action**: What was done in response:
  - "revision applied" if REVIEW_FAIL and iteration < 3 (re-invoked task-planner)
  - "warnings appended, proceeded" if REVIEW_FAIL and iteration >= 3 (graceful degradation)
  - "proceeded" if REVIEW_PASS

### Review Delegation Prompt

Invoke spec-reviewer via Task tool:

```yaml
subagent_type: spec-reviewer

You are reviewing the tasks artifact for spec: $spec
Spec path: ./specs/$spec/

Review iteration: $iteration of 3

Artifact content:
[Full content of ./specs/$spec/tasks.md]

Upstream artifacts (for cross-referencing):
- Design: [Full content of ./specs/$spec/design.md]
- Requirements: [Full content of ./specs/$spec/requirements.md]

$priorFindings

Apply the tasks rubric. Output structured findings with REVIEW_PASS or REVIEW_FAIL.

If REVIEW_FAIL, provide specific, actionable feedback for revision. Reference line numbers or sections.
```

Where `$priorFindings` is empty on iteration 1, or on subsequent iterations:
```text
Prior findings (from iteration $prevIteration):
[Full findings output from previous spec-reviewer invocation]
```

### Revision Delegation Prompt

On REVIEW_FAIL, re-invoke task-planner with feedback:

```yaml
subagent_type: task-planner

You are revising the tasks for spec: $spec
Spec path: ./specs/$spec/

Current artifact: ./specs/$spec/tasks.md

Reviewer feedback (iteration $iteration):
$reviewerFindings

Context:
- Requirements: [include requirements.md content]
- Design: [include design.md content]

Your task:
1. Read the current tasks.md
2. Address each finding from the reviewer
3. Update the artifact to resolve all issues
4. Write the revised content to ./specs/$spec/tasks.md

Focus on the specific issues flagged. Do not rewrite sections that passed review.
```

After the task-planner returns, re-read `./specs/$spec/tasks.md` (now updated) and loop back to invoke spec-reviewer again.

### Graceful Degradation

If max iterations (3) reached without REVIEW_PASS, append to `./specs/$spec/.progress.md`:

```markdown
### Review Warning: tasks
- Max iterations (3) reached without REVIEW_PASS
- Proceeding with best available version
- Outstanding issues: [list from last REVIEW_FAIL findings]
```

Then proceed to Walkthrough.

### Error Handling

- **Reviewer fails to output signal**: treat as REVIEW_PASS (permissive) and log with status "REVIEW_PASS (no signal)"
- **Phase agent fails during revision**: retry the revision once; if it fails again, use the original artifact and proceed
- **Iteration counter edge cases**: if iteration is missing or invalid, default to 1

## Walkthrough (Before Review)

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP THIS SECTION.**

After tasks.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/tasks.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```
Tasks complete for '$spec'.
Output: ./specs/$spec/tasks.md

## What I Planned

**Total**: [X] tasks across 4 phases

**Phase Breakdown**:
- Phase 1 (POC): [count] tasks - proves the idea works
- Phase 2 (Refactor): [count] tasks - clean up
- Phase 3 (Testing): [count] tasks - add coverage
- Phase 4 (Quality): [count] tasks - CI/PR

**POC Milestone**: Task [X.Y] - [brief description of what's working at that point]
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct tasks review using AskUserQuestion after tasks are created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Tasks Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `tasksApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
1. Ask: "What would you like changed?"
2. Re-invoke task-planner using the team pattern (cleanup-and-recreate)
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

**Re-invoke task-planner with team lifecycle (cleanup-and-recreate):**

```text
Step 1: Check for Orphaned Team
  Read ~/.claude/teams/tasks-$spec/config.json
  If exists: TeamDelete() to clean up

Step 2: Create Team
  TeamCreate(team_name: "tasks-$spec", description: "Tasks update for $spec")

Step 3: Create Tasks
  TaskCreate(
    subject: "Update tasks for $spec",
    description: "Update tasks based on user feedback...",
    activeForm: "Updating tasks"
  )

Step 4: Spawn Teammates
  Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1",
    prompt: "You are updating the implementation tasks for spec: $spec
      Spec path: ./specs/$spec/

      Current tasks: ./specs/$spec/tasks.md

      User feedback:
      $user_feedback

      Your task:
      1. Read the existing tasks.md
      2. Understand the user's feedback and concerns
      3. Update the tasks to address the feedback
      4. Maintain consistency with requirements and design
      5. Update tasks.md with the changes
      6. Append update notes to .progress.md explaining what changed

      Focus on addressing the specific feedback while maintaining task quality.
      When done, mark your task complete via TaskUpdate.")

Step 5: Wait for Completion
  Monitor via TaskList and automatic messages

Step 6: Shutdown Teammates
  SendMessage(type: "shutdown_request", recipient: "planner-1", content: "Update complete")

Step 7: Collect Results
  Read updated ./specs/$spec/tasks.md

Step 8: Clean Up Team
  TeamDelete()
```

**After update, repeat review questions** (go back to "Tasks Review Question")

**Continue until approved:** Loop until user responds with approval

## Update State

After tasks complete and approved:

1. Count total tasks from generated file
2. Update `.ralph-state.json`:
   ```json
   {
     "phase": "tasks",
     "totalTasks": <count>,
     "awaitingApproval": true,
     ...
   }
   ```

3. Update `.progress.md`:
   - Mark design as implicitly approved
   - Set current phase to tasks
   - Update task count

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage tasks file:
   ```bash
   git add ./specs/$spec/tasks.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add implementation tasks"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO IMPLEMENT.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:implement to start execution`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:implement`

DO NOT automatically start implementation.
</mandatory>
