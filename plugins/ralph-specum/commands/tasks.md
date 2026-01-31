---
description: Generate implementation tasks from design
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Tasks Phase

Generate implementation tasks for a specification. Running this command implicitly approves the design phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A TASK PLANNER.**
Delegate ALL task planning to the `task-planner` subagent via Task tool.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/design.md` exists. If not, error: "Design not found. Run /ralph-specum:design first."
3. Check `./specs/$spec/requirements.md` exists
4. Read `.ralph-state.json` and clear approval flag: `awaitingApproval: false`

## Gather Context

Read: `./specs/$spec/requirements.md`, `./specs/$spec/design.md`, `./specs/$spec/research.md` (if exists), `./specs/$spec/.progress.md`

## Interview

<skill-reference>
**Apply skill**: `skills/interview-framework/SKILL.md`
Use interview framework for single-question loop, parameter chain, and completion signals.
</skill-reference>

**Skip if --quick flag in $ARGUMENTS.**

### Tasks Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | What testing depth for {goal}? | Required | `testingDepth` | Standard unit+integration / Minimal POC only / Comprehensive E2E / Other |
| 2 | Deployment considerations for {goal}? | Required | `deploymentApproach` | Standard CI/CD / Feature flag / Gradual rollout / Other |
| 3 | What's the execution priority? | Required | `executionPriority` | Ship fast POC / Balanced quality+speed / Quality first / Other |
| 4 | Any other execution context? (or 'done') | Optional | `additionalTasksContext` | No, proceed / Yes, more details / Other |

Store responses in `.progress.md` under `### Tasks Interview (from tasks.md)`

## Execute Tasks Generation

Use Task tool with `subagent_type: task-planner`:

```text
You are creating implementation tasks for spec: $spec
Spec path: ./specs/$spec/

Context:
- Requirements: [requirements.md content]
- Design: [design.md content]
- Interview: [interview responses]

Create tasks.md with POC-first phases:
- Phase 1: Make It Work (POC)
- Phase 2: Refactoring
- Phase 3: Testing
- Phase 4: Quality Gates

Each task MUST include: Do, Files, Done when, Verify, Commit, Requirements refs, Design refs.
```

## Review Loop

**Skip if --quick flag.** Ask user to review generated tasks. If changes needed, invoke task-planner again with feedback and repeat until approved.

## Update State

Count total tasks, then update `.ralph-state.json`: `{ "phase": "tasks", "totalTasks": <count>, "awaitingApproval": true }`

## Commit Spec (if enabled)

If `commitSpec` is true in state: stage, commit (`spec($spec): add implementation tasks`), push.

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

**Error handling**: If tasks.md cannot be read, display warning "Warning: Could not read tasks.md for walkthrough" and skip the Walkthrough section entirely - still show "Tasks phase complete" and the output path. If tasks.md exists but is missing sections or data cannot be extracted, show "N/A" for those fields and continue with available information. The command must complete successfully regardless of walkthrough extraction errors.
