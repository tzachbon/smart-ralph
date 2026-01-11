---
description: Start spec-driven development loop. Creates specs from goal, executes tasks with smart compaction between phases.
argument-hint: "goal description" [--mode interactive|auto] [--dir ./spec-dir] [--max-iterations 10]
---

# Ralph Specum Loop

You are starting a spec-driven development loop with smart compaction and sub-agent delegation.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **goal**: The quoted goal description (required)
- **mode**: `interactive` (default) or `auto`
- **dir**: Spec directory path (default: `./spec`)
- **max-iterations**: Max loop iterations (default: `10`)

## Initialize

1. Create the spec directory if it doesn't exist
2. Check for existing `.ralph-state.json` in the spec directory
   - If exists: Resume from current state
   - If not: Initialize new state

3. Initialize `.ralph-state.json`:
```json
{
  "mode": "<mode>",
  "goal": "<goal description>",
  "specPath": "<dir>",
  "phase": "requirements",
  "taskIndex": 0,
  "totalTasks": 0,
  "currentTaskName": "",
  "phaseApprovals": {
    "requirements": false,
    "design": false,
    "tasks": false
  },
  "iteration": 1,
  "maxIterations": <max-iterations>
}
```

4. Initialize `.ralph-progress.md` from template

## Workflow

**ALWAYS read `.ralph-progress.md` first on each iteration.**

<mandatory>
Use the Task tool with specialized sub-agents for each phase. Never skip sub-agent delegation when the agent exists.
</mandatory>

### Sub-Agent Selection

| Phase | Primary Agent | Purpose |
|-------|---------------|---------|
| Requirements | `product-manager` | User stories, acceptance criteria, business value |
| Design | `architect-reviewer` | Architecture, patterns, technical decisions |
| Tasks | `task-planner` | POC-first breakdown, quality gates |
| Execution | `spec-executor` | Autonomous task implementation |

### Phase: Requirements

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the product-manager agent prompt.
</mandatory>

1. Invoke product-manager agent with:
   - User's goal description
   - Any constraints discussed
   - Output: `<dir>/requirements.md`

2. Agent creates requirements.md with:
   - User stories with acceptance criteria
   - Functional requirements (FR-*) with priorities
   - Non-functional requirements (NFR-*)
   - Glossary, out-of-scope, dependencies

3. Update `.ralph-progress.md` with phase status
4. Output: `PHASE_COMPLETE: requirements`

### Phase: Design

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the architect-reviewer agent prompt.
</mandatory>

1. Invoke architect-reviewer agent with:
   - Approved requirements from `<dir>/requirements.md`
   - Existing codebase patterns (if applicable)
   - Output: `<dir>/design.md`

2. Agent creates design.md with:
   - Architecture overview with mermaid diagrams
   - Component design and interfaces
   - Data flow diagrams
   - Technical decisions with rationale
   - File structure matrix
   - Test strategy

3. Update `.ralph-progress.md`
4. Output: `PHASE_COMPLETE: design`

### Phase: Tasks

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the task-planner agent prompt.
ALL specs MUST follow POC-first workflow.
</mandatory>

1. Invoke task-planner agent with:
   - Requirements from `<dir>/requirements.md`
   - Design from `<dir>/design.md`
   - Output: `<dir>/tasks.md`

2. Agent creates tasks.md with POC-first phases:
   - **Phase 1: Make It Work** - POC validation
   - **Phase 2: Refactoring** - Code cleanup
   - **Phase 3: Testing** - Unit/integration/e2e
   - **Phase 4: Quality Gates** - Lint, types, CI

3. Each task includes:
   - **Do**: Exact steps
   - **Files**: Paths to modify
   - **Done when**: Success criteria
   - **Verify**: Command to verify
   - **Commit**: Conventional commit message
   - _Requirements/Design references_

4. Update `.ralph-state.json` with `totalTasks`
5. Update `.ralph-progress.md`
6. Output: `PHASE_COMPLETE: tasks`

### Phase: Execution

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the spec-executor agent prompt.
Execute tasks autonomously with NO human interaction.
</mandatory>

For each task:
1. Invoke spec-executor agent with:
   - Current task from tasks.md
   - Progress from `.ralph-progress.md`
   - Relevant spec context

2. Agent executes:
   - Reads Do section, executes exactly
   - Modifies only Files listed
   - Checks Done when criteria
   - Runs Verify command
   - Commits with task's Commit message
   - Updates progress

3. Update `.ralph-progress.md`:
   - Mark task as `[x]`
   - Add any learnings
   - Update current goal to next task

4. Update `.ralph-state.json` with `taskIndex`
5. Output: `TASK_COMPLETE: <task_number>`

## Completion

When all tasks are done:
1. Verify all quality gates passed
2. Delete `.ralph-progress.md`
3. Delete `.ralph-state.json`
4. Output: `RALPH_COMPLETE`

## Loop Control

- Max iterations: configurable via `--max-iterations` (default: 10)
- Completion promise: `RALPH_COMPLETE`
- The stop hook handles continuation based on phase/task status

## Important Rules

1. **Always read `.ralph-progress.md` first** after any compaction
2. **Always use sub-agents** for specialized work
3. **Update progress file before any phase/task transition**
4. **Append learnings immediately** when discovered
5. **Never skip the progress file update** before stopping
6. **POC first** - validate idea before production quality

## Anti-Patterns

- Never assume context is preserved after compaction
- Never skip sub-agent delegation
- Never mark task complete without verification
- Never compact without updating progress file first
- Never mix POC and production code without Phase 2

--max-iterations <max-iterations> --completion-promise RALPH_COMPLETE
