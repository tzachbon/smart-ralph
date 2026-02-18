---
name: ralph:start
description: Start a new spec-driven workflow or resume an existing one. Detects whether to create a fresh spec or pick up where you left off. Works in any AI coding tool.
---

# Start Spec Workflow

## Overview

The start skill is the entry point for spec-driven development. It handles two scenarios:

1. **New spec**: Creates a spec directory, initializes state files, and begins the workflow at the research phase.
2. **Resume existing spec**: Detects an active or named spec, reads its state, and continues from the current phase.

The spec workflow progresses through five phases in order:

```
research -> requirements -> design -> tasks -> implement
```

Each phase produces a markdown artifact in the spec directory. The implement phase executes tasks from `tasks.md` one at a time until all are complete.

### What Gets Created

For a new spec named `my-feature`, the start skill creates:

```
specs/
  .current-spec          # Points to the active spec name
  my-feature/
    .ralph-state.json    # Execution state (phase, progress, config)
    .progress.md         # Progress tracking, learnings, context
```

As you progress through phases, additional files appear:

```
specs/my-feature/
  research.md            # Phase 1 output
  requirements.md        # Phase 2 output
  design.md              # Phase 3 output
  tasks.md               # Phase 4 output (drives implementation)
```

---

## Steps

Follow these steps to start or resume a spec workflow.

### 1. Parse Arguments

Extract the following from the user's input:

- **name** (optional): Spec name in kebab-case (e.g., `user-auth`)
- **goal** (optional): A description of what to build (everything after the name, excluding flags)

If no name is provided, check for an active spec to resume. If no active spec exists, ask for a name and goal.

### 2. Check Git Branch

Before creating any files, verify the current branch:

```bash
CURRENT_BRANCH=$(git branch --show-current)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
```

- If on the default branch (main/master): create a feature branch `feat/<spec-name>` before proceeding.
- If on a feature branch: continue on the current branch.

### 3. Detect New vs Resume

```
If name is provided:
  Check if specs/<name>/ exists
    Exists + no --fresh flag -> Resume flow (step 6)
    Exists + --fresh flag    -> Delete existing, continue to New flow
    Does not exist           -> New flow (step 4)

If no name provided:
  Check specs/.current-spec for active spec
    Has active spec -> Resume flow (step 6)
    No active spec  -> Ask for name and goal, then New flow (step 4)
```

### 4. Create Spec Directory

```bash
SPECS_DIR="./specs"  # or custom directory from --specs-dir flag
mkdir -p "$SPECS_DIR/$NAME"
```

### 5. Initialize State Files

Write the execution state file:

```bash
# Write .ralph-state.json
cat > "$SPECS_DIR/$NAME/.ralph-state.json" << 'EOF'
{
  "source": "spec",
  "name": "<name>",
  "basePath": "<specs-dir>/<name>",
  "phase": "research",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "commitSpec": true
}
EOF
```

Write the progress tracking file:

```bash
# Write .progress.md
cat > "$SPECS_DIR/$NAME/.progress.md" << 'EOF'
# Progress: <name>

## Original Goal

<goal description provided by user>

## Completed Tasks

## Current Task
Awaiting first task

## Learnings

## Next
Research phase
EOF
```

Set the active spec pointer:

```bash
echo "<name>" > "$SPECS_DIR/.current-spec"
```

#### State File Format Reference

**`.ralph-state.json`** tracks execution state:

| Field | Type | Description |
|-------|------|-------------|
| `source` | string | `"spec"` for normal mode, `"plan"` for quick mode |
| `name` | string | Spec name (kebab-case) |
| `basePath` | string | Full path to spec directory |
| `phase` | string | Current phase: `research`, `requirements`, `design`, `tasks`, `execution` |
| `taskIndex` | number | Current task index (0-based) |
| `totalTasks` | number | Total tasks in tasks.md |
| `taskIteration` | number | Current retry count for the active task |
| `maxTaskIterations` | number | Max retries before blocking (default: 5) |
| `globalIteration` | number | Overall execution loop iteration count |
| `maxGlobalIterations` | number | Safety cap on total iterations (default: 100) |
| `commitSpec` | boolean | Whether to commit spec artifacts after generation |
| `awaitingApproval` | boolean | If true, wait for user before advancing to next phase |
| `relatedSpecs` | array | Specs related to this one (populated during research) |

**`.progress.md`** tracks human-readable progress:

| Section | Purpose |
|---------|---------|
| `## Original Goal` | The user's goal description |
| `## Completed Tasks` | Checked-off tasks with commit hashes |
| `## Current Task` | What is being worked on now |
| `## Learnings` | Accumulated insights across tasks |
| `## Next` | What comes after the current task |

**`.current-spec`** is a simple text file containing either:
- A bare spec name (e.g., `my-feature`) when using the default specs directory
- A full path (e.g., `./packages/api/specs/my-feature`) when using a non-default directory

### 6. Resume Flow

When resuming an existing spec:

1. Read `.ralph-state.json` to determine the current phase and task index.
2. If no state file exists, check which artifact files are present to infer the last completed phase.
3. Display a brief status:
   ```
   Resuming '<name>'
   Phase: <current phase>
   Progress: <taskIndex>/<totalTasks> tasks complete
   ```
4. Continue from the current phase.

### 7. Begin Research Phase

After initialization, the workflow proceeds to the research phase:

1. Analyze the goal and break it into 2-5 research topics.
2. Research each topic (codebase analysis, external research, feasibility).
3. Merge findings into `research.md`.
4. Update state: set `phase: "research"` and `awaitingApproval: true`.

After research completes, stop and wait for the user to advance to the requirements phase.

### 8. Conduct Goal Interview (Normal Mode)

Before research, ask clarifying questions to refine the goal:

1. **What problem are you solving?** (Fixing a bug / Adding functionality / Improving behavior)
2. **Any constraints or must-haves?** (Integration requirements, performance needs)
3. **How will you know it is successful?** (Tests pass, users complete workflow, metrics met)
4. **Any other context?** (Optional, user can say "done" to proceed)

Store responses in `.progress.md` under an `## Interview Responses` section. Skip the interview in quick mode.

---

## Advanced Options

### Quick Mode (`--quick`)

Skip all interactive phases and auto-generate artifacts from a goal or plan file.

```
start <name> <goal> --quick
start <goal> --quick
start <name> ./plan.md --quick
```

Quick mode behavior:
- Skips the goal interview
- Skips the spec scanner for related specs
- Sets `source: "plan"` and `phase: "tasks"` in state file
- Delegates to a plan synthesizer to generate all artifacts (research.md, requirements.md, design.md, tasks.md)
- After generation, sets `phase: "execution"` and begins task execution immediately
- Does NOT commit spec files by default (override with `--commit-spec`)

#### Input Detection in Quick Mode

```
Two args before --quick:
  First arg = spec name (kebab-case), second = goal or file path

One arg before --quick:
  File path (starts with ./ or / or ends with .md) -> read as plan
  Kebab-case name -> look for existing specs/<name>/plan.md
  Anything else -> treat as goal string, infer name from first 3 words

Zero args with --quick:
  Error: "Quick mode requires a goal or plan file"
```

### Force Fresh (`--fresh`)

If a spec with the given name already exists, `--fresh` deletes it and starts over without prompting.

```
start my-feature --fresh
```

### Custom Specs Directory (`--specs-dir`)

Create the spec in a specific directory instead of the default `./specs/`:

```
start my-feature --specs-dir ./packages/api/specs
```

The directory must be in the configured `specs_dirs` list. When using a non-default directory, `.current-spec` stores the full path instead of just the name.

### Commit Spec (`--commit-spec` / `--no-commit-spec`)

Control whether spec artifacts are committed and pushed after generation:

```
start my-feature --commit-spec       # Force commit (even in quick mode)
start my-feature --no-commit-spec    # Disable commit (even in normal mode)
```

Default behavior:
- Normal mode: commit is enabled
- Quick mode: commit is disabled

### Branch Management

The start skill checks the git branch before creating files:

- **On default branch**: Creates `feat/<spec-name>` and switches to it.
- **On feature branch**: Stays on the current branch by default.
- **Quick mode**: Auto-creates branch if on default branch; stays on current branch if on feature branch (no prompts).

### Rollback on Failure

If artifact generation fails after the spec directory was created:

1. Delete the spec directory.
2. Restore the previous `.current-spec` value.
3. Report the error.

### Spec Workflow Phases Reference

| Phase | Artifact | Purpose |
|-------|----------|---------|
| research | `research.md` | Codebase analysis, external research, feasibility assessment |
| requirements | `requirements.md` | User stories, acceptance criteria, functional/non-functional requirements |
| design | `design.md` | Architecture, components, data flow, technical decisions |
| tasks | `tasks.md` | POC-first 4-phase task breakdown with Do/Files/Done when/Verify/Commit format |
| implement | (none) | Execute tasks sequentially, mark complete, update progress |
