---
description: Start spec-driven development loop. Creates specs from goal, executes tasks with smart compaction between phases.
argument-hint: "goal description" [--mode interactive|auto] [--dir ./spec-dir] [--max-iterations 10] [--force-restart]
---

# Ralph Specum Loop

You are starting a spec-driven development loop with smart compaction and sub-agent delegation.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **goal**: The quoted goal description (required)
- **mode**: `interactive` (default) or `auto`
- **dir**: Spec directory path (default: `./spec`)
- **max-iterations**: Max loop iterations (default: `10`)
- **force-restart**: Enable force quit and restart between phases/tasks (default: `false`)

### Force Restart Mode

When `--force-restart` is enabled:
- After all spec phases complete (requirements, design, tasks), Claude will **quit completely**
- A restart marker file (`.ralph-restart`) is created with resume context
- Use the `restart-runner.sh` script to automatically relaunch Claude with fresh context
- This is useful for context management when working on large features

**Usage with restart runner:**
```bash
# Terminal 1: Run the restart runner (monitors and relaunches Claude)
./hooks/scripts/restart-runner.sh ./spec

# Terminal 2: Or run Claude manually and it will quit when phases complete
claude "/ralph-specum \"my feature\" --mode auto --force-restart"
```

## Initialize

1. **Derive feature name from goal**:
   - Convert goal to kebab-case (lowercase, spaces/special chars to hyphens)
   - Truncate to max 50 characters
   - Remove leading/trailing hyphens
   - Example: `"Add user authentication with JWT"` → `add-user-authentication-with-jwt`

2. **Create feature directory**: `<dir>/<feature-name>/`
   - The full path for all spec files is `<dir>/<feature-name>/`

3. Check for existing `.ralph-state.json` in the feature directory
   - If exists: Resume from current state
   - If not: Initialize new state

4. Initialize `.ralph-state.json`:
```json
{
  "mode": "<mode>",
  "goal": "<goal description>",
  "featureName": "<feature-name>",
  "specPath": "<dir>/<feature-name>",
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
  "maxIterations": <max-iterations>,
  "forceRestart": <force-restart>
}
```

5. Initialize `.ralph-progress.md` from template in `<specPath>/`

## Workflow

**ALWAYS read `.ralph-progress.md` first on each iteration.**

<mandatory>
Use the Task tool with specialized sub-agents for each phase. Never skip sub-agent delegation when the agent exists.
</mandatory>

### Compaction Between Phases (Auto Mode)

<mandatory>
In auto mode, you MUST run `/compact` after completing each phase to manage context.
</mandatory>

After each phase completes in auto mode:
1. Update `.ralph-progress.md` with phase results
2. Update `.ralph-state.json` to advance phase
3. Output `PHASE_COMPLETE: <phase>`
4. **Run `/compact`** with phase-specific preservation:

| After Phase | Compact Command |
|-------------|-----------------|
| Requirements | `/compact preserve: user stories, acceptance criteria (AC-*), functional requirements (FR-*), non-functional requirements (NFR-*), glossary. Read <specPath>/.ralph-progress.md for context.` |
| Design | `/compact preserve: architecture decisions, component boundaries, file paths, patterns. Read <specPath>/.ralph-progress.md for context.` |
| Tasks | `/compact preserve: task list with IDs, dependencies, quality gates. Read <specPath>/.ralph-progress.md for context.` |
| Per Task | `/compact preserve: current task context, verification results. Read <specPath>/.ralph-progress.md for completed tasks.` |

5. After compaction, **immediately read `.ralph-progress.md`** to restore context
6. Continue to next phase

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
   - Output: `<specPath>/requirements.md`

2. Agent creates requirements.md with:
   - User stories with acceptance criteria
   - Functional requirements (FR-*) with priorities
   - Non-functional requirements (NFR-*)
   - Glossary, out-of-scope, dependencies

3. Update `.ralph-progress.md` with phase status
4. Output: `PHASE_COMPLETE: requirements`
5. **Auto mode only**: Run `/compact preserve: user stories, acceptance criteria (AC-*), functional requirements (FR-*), non-functional requirements (NFR-*), glossary. Read <specPath>/.ralph-progress.md for context.`
6. Read `.ralph-progress.md` to restore context, then continue to Design phase

### Phase: Design

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the architect-reviewer agent prompt.
</mandatory>

1. Invoke architect-reviewer agent with:
   - Approved requirements from `<specPath>/requirements.md`
   - Existing codebase patterns (if applicable)
   - Output: `<specPath>/design.md`

2. Agent creates design.md with:
   - Architecture overview with mermaid diagrams
   - Component design and interfaces
   - Data flow diagrams
   - Technical decisions with rationale
   - File structure matrix
   - Test strategy

3. Update `.ralph-progress.md`
4. Output: `PHASE_COMPLETE: design`
5. **Auto mode only**: Run `/compact preserve: architecture decisions, component boundaries, file paths, patterns. Read <specPath>/.ralph-progress.md for context.`
6. Read `.ralph-progress.md` to restore context, then continue to Tasks phase

### Phase: Tasks

<mandatory>
Use Task tool with `subagent_type: general-purpose` and include the task-planner agent prompt.
ALL specs MUST follow POC-first workflow.
</mandatory>

1. Invoke task-planner agent with:
   - Requirements from `<specPath>/requirements.md`
   - Design from `<specPath>/design.md`
   - Output: `<specPath>/tasks.md`

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
7. **Auto mode only**: Run `/compact preserve: task list with IDs, dependencies, quality gates. Read <specPath>/.ralph-progress.md for context.`
8. Read `.ralph-progress.md` to restore context, then continue to Execution phase

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
6. **Auto mode only**: Run `/compact preserve: current task context, verification results. Read <specPath>/.ralph-progress.md for completed tasks.`
7. Read `.ralph-progress.md` to restore context, then continue to next task

## Default PR Workflow

<mandatory>
By default, when working on a non-default branch, the final task is ALWAYS to create a Pull Request:
1. **Detect branch**: Check if current branch is not main/master/default
2. **If on feature branch**: PR creation is the expected final deliverable
3. **Unless explicitly stated otherwise**: Always end with PR creation and CI verification
</mandatory>

### PR Workflow Steps

When on a feature branch (non-default):

1. **Local Quality Gates** (before PR):
   - Run type check: `pnpm check-types` or project equivalent
   - Run linter: `pnpm lint` or project equivalent
   - Run all tests: `pnpm test` or project equivalent
   - All must pass before proceeding

2. **Create Pull Request**:
   - Push branch: `git push -u origin <branch-name>`
   - Create PR using gh CLI: `gh pr create --title "<title>" --body "<body>"`
   - If gh CLI unavailable, provide manual PR creation instructions

3. **Verify CI on GitHub** (using gh CLI if available):
   - Wait for CI: `gh pr checks <pr-number> --watch`
   - Or poll status: `gh pr checks <pr-number>`
   - All CI checks must be green before considering complete
   - If CI fails, fix issues locally and push again

4. **Final Status**:
   - PR is ready for review when all CI checks pass
   - Do NOT auto-merge unless explicitly requested

### Branch Detection

```bash
# Get current branch
current_branch=$(git branch --show-current)

# Get default branch
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
# Fallback: check for main or master
if [ -z "$default_branch" ]; then
  default_branch=$(git branch -r | grep -E 'origin/(main|master)$' | head -1 | sed 's@.*origin/@@')
fi

# Check if on feature branch
if [ "$current_branch" != "$default_branch" ]; then
  echo "On feature branch - PR workflow applies"
fi
```

## Completion

When all tasks are done:
1. Verify all quality gates passed
2. **If on feature branch**: Ensure PR is created and CI is green
3. Delete `.ralph-progress.md`
4. Delete `.ralph-state.json`
5. Output: `RALPH_COMPLETE`

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
