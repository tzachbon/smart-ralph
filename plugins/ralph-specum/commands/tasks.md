---
description: Generate implementation tasks from design
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Tasks Phase

You are generating implementation tasks for a specification. Running this command implicitly approves the design phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A TASK PLANNER.**

You MUST delegate ALL task planning to the `task-planner` subagent.
Do NOT write task breakdowns, verification steps, or tasks.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
3. Check `./specs/$spec/requirements.md` exists
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

## Execute Tasks Generation

<mandatory>
Use the Task tool with `subagent_type: task-planner` to generate tasks.
ALL specs MUST follow POC-first workflow.
</mandatory>

Invoke task-planner agent with prompt:

```text
You are creating implementation tasks for spec: $spec
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
7. Include interview responses in an "Execution Context" section of tasks.md

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
```

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct tasks review using AskUserQuestion after tasks are created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Tasks Review Questions

After the tasks have been created by the task-planner agent, ask the user to review them and provide feedback.

**Review Question Flow:**

1. **Read the generated tasks.md** to understand what was planned
2. **Ask initial review questions** to confirm the tasks meet their expectations:

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | Does the task breakdown cover all necessary work? | `taskCoverage` | Yes, comprehensive / Missing some tasks / Need more granularity / Other |
| 2 | Are the task phases (POC, Refactor, Test, Quality) appropriate? | `taskPhases` | Yes, good structure / Adjust phases / Different approach needed / Other |
| 3 | Are the verification steps clear and executable? | `verificationSteps` | Yes, clear / Need more details / Some are unclear / Other |
| 4 | Any other feedback on the tasks? (or say 'approved' to proceed) | `tasksFeedback` | Approved, let's proceed / Yes, I have feedback / Other |

### Store Tasks Review Responses

After review questions, append to `.progress.md` under a new section:

```markdown
### Tasks Review (from tasks.md)
- Task coverage: [responses.taskCoverage]
- Task phases: [responses.taskPhases]
- Verification steps: [responses.verificationSteps]
- Tasks feedback: [responses.tasksFeedback]
[Any follow-up responses from "Other" selections]
```

### Update Tasks Based on Feedback

<mandatory>
If the user provided feedback requiring changes (any answer other than "Yes, comprehensive", "Yes, good structure", "Yes, clear", or "Approved, let's proceed"), you MUST:

1. Collect specific change requests from the user
2. Invoke task-planner again with update instructions
3. Repeat the review questions after updates
4. Continue loop until user approves
</mandatory>

**Update Flow:**

If changes are needed:

1. **Ask for specific changes:**
   ```
   What specific changes would you like to see in the tasks?
   ```

2. **Invoke task-planner with update prompt:**
   ```
   You are updating the implementation tasks for spec: $spec
   Spec path: ./specs/$spec/

   Current tasks: ./specs/$spec/tasks.md

   User feedback:
   $user_feedback

   Your task:
   1. Read the existing tasks.md
   2. Understand the user's feedback and concerns
   3. Update the tasks to address the feedback
   4. Maintain POC-first workflow structure
   5. Update tasks.md with the changes
   6. Update total_tasks count in frontmatter
   7. Append update notes to .progress.md explaining what changed

   Focus on addressing the specific feedback while maintaining task quality.
   ```

3. **After update, repeat review questions** (go back to "Tasks Review Questions")

4. **Continue until approved:** Loop until user responds with approval

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

## Output

After tasks.md is created and approved, read the generated file and extract key information for the walkthrough.

### Extract from tasks.md

1. **Total Task Count**: Read `total_tasks` from frontmatter
2. **Phase Breakdown**: Count tasks (`- [ ]`) under each phase header:
   - Phase 1 (POC): Count tasks under `## Phase 1: Make It Work (POC)`
   - Phase 2 (Refactor): Count tasks under `## Phase 2: Refactoring`
   - Phase 3 (Testing): Count tasks under `## Phase 3: Testing`
   - Phase 4 (Quality): Count tasks under `## Phase 4: Quality Gates`
3. **POC Checkpoint**: Find the last task in Phase 1 - this marks POC completion
4. **Estimated Commits**: Same as total task count (each task = one commit)

### Display Walkthrough

```text
Tasks phase complete for '$spec'.

Output: ./specs/$spec/tasks.md
[If commitSpec: "Spec committed and pushed."]

## Walkthrough

### Key Points
- **POC Completion**: Task [X.Y] marks end of POC phase - feature demonstrable at that point
- **Phase Breakdown**:
  | Phase | Tasks | Focus |
  |-------|-------|-------|
  | 1. POC | [count] | Validate idea works |
  | 2. Refactor | [count] | Clean up code |
  | 3. Testing | [count] | Add test coverage |
  | 4. Quality | [count] | CI and PR |

### Metrics
| Metric | Value |
|--------|-------|
| Total Tasks | [total_tasks from frontmatter] |
| Estimated Commits | [total_tasks] |

### Review Focus
- Verify POC tasks prove the core idea
- Check each task has clear Done when criteria
- Verify commands can run autonomously
- Review quality checkpoints are reasonable

Next: Review tasks.md, then run /ralph-specum:implement to start execution
```

**Error handling**: If tasks.md is missing sections or data cannot be extracted, show "N/A" for those fields and continue with available information.
