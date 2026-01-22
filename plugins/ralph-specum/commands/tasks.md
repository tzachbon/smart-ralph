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

## Update State

After tasks complete:

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

```text
Tasks phase complete for '$spec'.

Output: ./specs/$spec/tasks.md
Total tasks: <count>
[If commitSpec: "Spec committed and pushed."]

Next: Review tasks.md, then run /ralph-specum:implement to start execution
```
