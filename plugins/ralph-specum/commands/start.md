---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick]
argument-hint: [name] [goal] [--fresh] [--quick]
allowed-tools: [Read, Write, Bash, Task, AskUserQuestion]
---

# Start

Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one.

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE regardless of mode (normal or quick).

**NEVER do any of these yourself:**
- Write code or modify source files
- Perform research or analysis
- Generate spec artifacts (research.md, requirements.md, design.md, tasks.md)
- Execute task steps
- Run verification commands as part of task execution

**ALWAYS delegate to the appropriate subagent:**
| Work Type | Subagent |
|-----------|----------|
| Research | `research-analyst` |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Task Planning | `task-planner` |
| Artifact Generation (quick mode) | `plan-synthesizer` |
| Task Execution | `spec-executor` |

Quick mode does NOT exempt you from delegation - it only skips interactive phases.
</mandatory>

## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: Optional spec name (kebab-case)
- **goal**: Everything after the name except flags (optional)
- **--fresh**: Force new spec without prompting if one exists
- **--quick**: Skip all spec phases, auto-generate artifacts, start execution immediately
- **--quick**: Quick mode - auto-generate all specs and start execution

Examples:
- `/ralph-specum:start` -> Auto-detect: resume active or ask for new
- `/ralph-specum:start user-auth` -> Resume or create user-auth
- `/ralph-specum:start user-auth Add OAuth2` -> Create user-auth with goal
- `/ralph-specum:start user-auth --fresh` -> Force new, overwrite if exists
- `/ralph-specum:start "Build auth with JWT" --quick` -> Quick mode with goal string
- `/ralph-specum:start my-feature "Add logging" --quick` -> Quick mode with name+goal
- `/ralph-specum:start ./my-plan.md --quick` -> Quick mode with file input
- `/ralph-specum:start my-feature ./plan.md --quick` -> Quick mode with name+file
- `/ralph-specum:start my-feature --quick` -> Quick mode using existing plan.md

## Quick Mode Flow

When `--quick` flag detected, bypass interactive spec phases and auto-generate all artifacts.

### Quick Mode Input Detection

Parse arguments before `--quick` flag and classify input type:

```
Input Classification:

1. TWO ARGS before --quick:
   - First arg = spec name (must be kebab-case: ^[a-z0-9-]+$)
   - Second arg = goal string OR file path
   - Detect file path if: starts with "./" OR "/" OR ends with ".md"
   - Examples:
     - `my-feature "Add login" --quick` -> name=my-feature, goal="Add login"
     - `my-feature ./plan.md --quick` -> name=my-feature, file=./plan.md

2. ONE ARG before --quick:
   a. FILE PATH: starts with "./" OR "/" OR ends with ".md"
      - Read file content as plan
      - Infer name from plan content
      - Example: `./my-plan.md --quick` -> read file, infer name

   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Check if ./specs/$name/plan.md exists
      - If exists: use plan.md content, name=$name
      - If not exists: error "No plan.md found in ./specs/$name/. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - Example: `my-feature --quick` -> check ./specs/my-feature/plan.md

   c. GOAL STRING: anything else (contains spaces, uppercase, special chars)
      - Use as goal content
      - Infer name from goal
      - Example: `"Build auth with JWT" --quick` -> goal, infer name

3. ZERO ARGS with --quick:
   - Error: "Quick mode requires a goal or plan file"
```

### File Reading

When file path detected:
1. Validate file exists using Read tool
2. If not exists: error "File not found: $filePath"
3. Read file content
4. Strip frontmatter if present (content between --- markers at start)
5. If content empty after stripping: error "Plan content is empty. Provide a goal or non-empty file."
6. Use content as planContent

### Existing Plan Check

When kebab-case name provided without goal:
1. Check if `./specs/$name/plan.md` exists
2. If exists: read content, use as planContent
3. If not exists: error with guidance message

### Name Inference

If no explicit name provided, infer from goal:
1. Take first 3 words of goal
2. Convert to kebab-case (lowercase, spaces to hyphens)
3. Truncate to max 30 characters
4. Strip non-alphanumeric except hyphens

Example: "Build authentication with JWT tokens" -> "build-authentication-with"

### Quick Mode Execution

<mandatory>
**REMINDER: Even in quick mode, you MUST delegate ALL work to subagents.**
- Artifact generation → delegate to `plan-synthesizer` via Task tool
- Task execution → delegate to `spec-executor` via Task tool
- You only handle: directory creation, state file writes, and coordination
</mandatory>

```
1. Validate input (non-empty goal/plan)
   |
2. Infer name from goal (if not provided)
   |
3. Create spec directory: ./specs/$name/
   |
4. Write .ralph-state.json:
   {
     "source": "plan",
     "name": "$name",
     "basePath": "./specs/$name",
     "phase": "tasks",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100
   }
   |
5. Write .progress.md with original goal
   |
6. Update .current-spec: echo "$name" > ./specs/.current-spec
   |
7. Invoke plan-synthesizer agent via Task tool:
   Task: plan-synthesizer
   Input: goal="$goal", basePath="./specs/$name"
   |
8. After generation completes:
   - Update .ralph-state.json: phase="execution", taskIndex=0
   - Read tasks.md to get totalTasks count
   |
9. Display brief summary:
   Quick mode: Created spec '$name'
   Starting execution...
   |
10. Invoke spec-executor for task 1
```

### Quick Mode Validation

Before creating the spec, validate all inputs:

```
Validation Sequence:

1. ZERO ARGS CHECK (if no args before --quick)
   - Error: "Quick mode requires a goal or plan file"

2. FILE NOT FOUND (if file path detected)
   - If file not exists: "File not found: $filePath"

3. EMPTY CONTENT CHECK
   - If empty or whitespace only: "Plan content is empty. Provide a goal or non-empty file."

4. PLAN TOO SHORT WARNING (< 10 words)
   - If word count < 10: "Warning: Short plan may produce vague tasks"
   - Continue with warning displayed

5. NAME CONFLICT RESOLUTION
   - If ./specs/$name/ already exists:
     - Append -2, -3, etc. until unique name found
     - Display: "Created '$name-2' ($name already exists)"
```

### Atomic Rollback

On generation failure after spec directory created:

```
Rollback Procedure:

1. CAPTURE FAILURE
   - plan-synthesizer agent returns error or times out

2. DELETE SPEC DIRECTORY
   - rm -rf "./specs/$name"

3. RESTORE .current-spec
   - If previous spec was set, restore it

4. DISPLAY ERROR
   - "Generation failed: $errorReason. No spec created."
```

## Detection Logic

```
1. Check if name provided in arguments
   |
   +-- Yes: Check if ./specs/$name/ exists
   |   |
   |   +-- Exists + no --fresh: Ask "Resume '$name' or start fresh?"
   |   |   +-- Resume: Go to resume flow
   |   |   +-- Fresh: Delete existing, go to new flow
   |   |
   |   +-- Exists + --fresh: Delete existing, go to new flow
   |   |
   |   +-- Not exists: Go to new flow
   |
   +-- No: Check ./specs/.current-spec
       |
       +-- Has active spec: Go to resume flow
       |
       +-- No active spec: Ask for name and goal, go to new flow
```

## Resume Flow

1. Read `./specs/$name/.ralph-state.json`
2. If no state file (completed or never started):
   - Check what files exist (research.md, requirements.md, etc.)
   - Determine last completed phase
   - Ask: "Continue to next phase or restart?"
3. If state file exists:
   - Read current phase and task index
   - Show brief status:
     ```
     Resuming '$name'
     Phase: execution, Task 3/8
     Last: "Add error handling"
     ```
   - Continue from current phase

### Resume by Phase

| Phase | Action |
|-------|--------|
| research | Invoke research-analyst agent |
| requirements | Invoke product-manager agent |
| design | Invoke architect-reviewer agent |
| tasks | Invoke task-planner agent |
| execution | Invoke spec-executor for current task |

## New Flow

1. If no name provided, ask:
   - "What should we call this spec?" (validates kebab-case)
2. If no goal provided, ask:
   - "What is the goal? Describe what you want to build."
3. Create spec directory: `./specs/$name/`
4. Update active spec: `echo "$name" > ./specs/.current-spec`
5. Initialize `.ralph-state.json`:
   ```json
   {
     "source": "spec",
     "name": "$name",
     "basePath": "./specs/$name",
     "phase": "research",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100
   }
   ```
6. Create `.progress.md` with goal
7. Invoke research-analyst agent

## Quick Mode Flow

Triggered when `--quick` flag detected. Skips all spec phases and auto-generates artifacts.

```
1. Check if --quick flag present in $ARGUMENTS
   |
   +-- Yes: Extract args before --quick
   |   |
   |   +-- Two args: name = first, goal = second
   |   |
   |   +-- One arg: goal = first (infer name later)
   |   |
   |   +-- Zero args: Error "Quick mode requires a goal or plan"
   |
   +-- No: Continue to normal Detection Logic
```

### Quick Mode Steps (POC)

1. Parse args before `--quick`:
   - If two args: `name` = first arg (kebab-case), `goal` = second arg
   - If one arg: `goal` = arg, `name` = infer from goal (first 3 words, kebab-case, max 30 chars)
2. Validate non-empty goal
3. Create spec directory: `./specs/$name/`
4. Initialize `.ralph-state.json` with `source: "plan"`:
   ```json
   {
     "source": "plan",
     "name": "$name",
     "basePath": "./specs/$name",
     "phase": "tasks",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100
   }
   ```
5. Write `.progress.md` with goal
6. Update `.current-spec` with name
7. Invoke plan-synthesizer agent to generate all artifacts
8. After generation: update state `phase: "execution"`, read task count
9. Invoke spec-executor for task 1

## Status Display (on resume)

Before resuming, show brief status:

```
Resuming: user-auth
Phase: execution
Progress: 3/8 tasks complete
Current: 2.1 Add error handling

Continuing...
```

## Output

After detection and action:

**New spec:**
```
Created spec 'user-auth' at ./specs/user-auth/

Starting research phase...
```

**Resume:**
```
Resuming 'user-auth' at execution phase, task 4/8

Continuing task: 2.2 Extract retry logic
```

**Quick mode:**
```
Quick mode: Created 'build-auth-with' at ./specs/build-auth-with/
Generated 4 artifacts from goal.
Starting task 1/N...
```
