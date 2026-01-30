---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick] [--commit-spec] [--no-commit-spec]
allowed-tools: [Read, Write, Bash, Task, AskUserQuestion]
---

# Start

Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one.

## Branch Management (FIRST STEP)

<skill-reference>
**Apply skill**: `plugins/ralph-specum/skills/branch-management/SKILL.md`
Before creating any files, check git branch and handle appropriately. Use the branch-management skill for branch detection, creation, worktree setup, and naming conventions.

In quick mode, use Quick Mode Branch Handling (auto-create branch, no prompts).
</skill-reference>

## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: Optional spec name (kebab-case)
- **goal**: Everything after the name except flags (optional)
- **--fresh**: Force new spec without prompting if one exists
- **--quick**: Skip all spec phases, auto-generate artifacts, start execution immediately
- **--commit-spec**: Commit and push spec files after generation (default: true in normal mode, false in quick mode)
- **--no-commit-spec**: Explicitly disable committing spec files

### Commit Spec Flag Logic

```text
1. Check if --no-commit-spec in $ARGUMENTS -> commitSpec = false
2. Else if --commit-spec in $ARGUMENTS -> commitSpec = true
3. Else if --quick in $ARGUMENTS -> commitSpec = false (quick mode default)
4. Else -> commitSpec = true (normal mode default)
```

Examples:
- `/ralph-specum:start` -> Auto-detect: resume active or ask for new
- `/ralph-specum:start user-auth` -> Resume or create user-auth
- `/ralph-specum:start user-auth Add OAuth2` -> Create user-auth with goal
- `/ralph-specum:start user-auth --fresh` -> Force new, overwrite if exists
- `/ralph-specum:start "Build auth with JWT" --quick` -> Quick mode with goal string

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE regardless of mode.

**ALWAYS delegate to the appropriate subagent:**
| Work Type | Subagent |
|-----------|----------|
| Research | `research-analyst` |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Task Planning | `task-planner` |
| Artifact Generation (quick mode) | `plan-synthesizer` |
| Task Execution | `spec-executor` |
</mandatory>

<mandatory>
## CRITICAL: Stop After Each Subagent (Normal Mode)

In normal mode (no `--quick` flag), you MUST STOP your response after each subagent completes. The user must explicitly run the next command.

Exception: `--quick` mode runs all phases without stopping.
</mandatory>

## Detection Logic

```text
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
2. If no state file: check what files exist, determine last completed phase, ask continue or restart
3. If state file exists: read phase/task index, show status, continue

### Resume by Phase

| Phase | Action |
|-------|--------|
| research | Invoke research-analyst agent |
| requirements | Invoke product-manager agent |
| design | Invoke architect-reviewer agent |
| tasks | Invoke task-planner agent |
| execution | Invoke spec-executor for current task |

<mandatory>
## CRITICAL: Stop After Subagent Completes

After ANY subagent returns, read `.ralph-state.json`. If `awaitingApproval: true`, STOP IMMEDIATELY.
Do NOT invoke the next phase - user must run next command explicitly.
</mandatory>

## New Flow

1. If no name provided, ask for spec name (kebab-case)
2. If no goal provided, ask for goal description
3. Create spec directory: `./specs/$name/`
4. Update active spec: `echo "$name" > ./specs/.current-spec`
5. Ensure gitignore entries for `specs/.current-spec` and `**/.progress.md`
6. Initialize `.ralph-state.json` with phase "research"
7. Create `.progress.md` with goal

### Spec Scanner (Skip in Quick Mode)

<skill-reference>
**Apply skill**: `plugins/ralph-specum/skills/spec-scanner/SKILL.md`
Before conducting the Goal Interview, scan existing specs to find related work. This helps surface prior context and avoid duplicate effort.

Skip if --quick flag detected.
</skill-reference>

### Goal Interview (Skip in Quick Mode)

<skill-reference>
**Apply skill**: `plugins/ralph-specum/skills/intent-classification/SKILL.md`
Before asking interview questions, classify the user's goal to determine question depth (TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED).
</skill-reference>

Apply `plugins/ralph-specum/skills/interview-framework/SKILL.md` for single-question adaptive interview loop.

**Goal Interview Question Pool:**

| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What problem are you solving with this feature? | Required | `problem` |
| 2 | Any constraints or must-haves for this feature? | Required | `constraints` |
| 3 | How will you know this feature is successful? | Required | `success` |
| 4 | Any other context you'd like to share? (or say 'done') | Optional | `additionalContext` |

Store responses in `.progress.md` under `### Goal Interview (from start.md)`.

8. Invoke research-analyst agent with goal interview context
9. **STOP** - research-analyst sets awaitingApproval=true

## Quick Mode Flow

Triggered when `--quick` flag detected. Skips all spec phases and auto-generates artifacts.

### Quick Mode Input Detection

```text
1. TWO ARGS before --quick: name = first, goal/file = second
2. ONE ARG before --quick:
   a. FILE PATH (starts with ./ or /) -> read file as plan
   b. KEBAB-CASE NAME -> check ./specs/$name/plan.md
   c. GOAL STRING -> infer name from goal
3. ZERO ARGS with --quick: Error
```

### Name Inference

If no explicit name: take first 3 words of goal, kebab-case, max 30 chars.

### Quick Mode Execution

```text
1. Validate input (non-empty goal/plan)
2. Infer name from goal (if not provided)
3. Create spec directory: ./specs/$name/
4. Ensure gitignore entries
5. Write .ralph-state.json (source: "plan", phase: "tasks")
6. Write .progress.md with goal
7. Update .current-spec
8. Invoke plan-synthesizer agent via Task tool
9. After generation: update state phase="execution", read task count
10. If commitSpec: stage, commit, push spec files
11. Invoke spec-executor for task 1
```

### Quick Mode Validation

```text
1. ZERO ARGS CHECK -> Error: "Quick mode requires a goal or plan file"
2. FILE NOT FOUND -> Error: "File not found: $filePath"
3. EMPTY CONTENT CHECK -> Error: "Plan content is empty"
4. PLAN TOO SHORT WARNING (< 10 words) -> Warning but continue
5. NAME CONFLICT RESOLUTION -> Append -2, -3, etc. if exists
```

### Atomic Rollback

On generation failure: delete spec directory, restore .current-spec, display error.

## Quick Mode Uses Ralph Loop

After generating spec artifacts in quick mode, invoke ralph-loop:
```text
Skill: ralph-loop:ralph-loop
Args: Read ./specs/$spec/.coordinator-prompt.md and follow those instructions exactly. Output ALL_TASKS_COMPLETE when done. --max-iterations <calculated> --completion-promise ALL_TASKS_COMPLETE
```

## Status Display (on resume)

```text
Resuming: user-auth
Phase: execution
Progress: 3/8 tasks complete
Current: 2.1 Add error handling

Continuing...
```

## Output

**New spec:**
```text
Created spec 'user-auth' at ./specs/user-auth/

Starting research phase...
```

**Resume:**
```text
Resuming 'user-auth' at execution phase, task 4/8

Continuing task: 2.2 Extract retry logic
```

**Quick mode:**
```text
Quick mode: Created 'build-auth-with' at ./specs/build-auth-with/
Generated 4 artifacts from goal.
Starting task 1/N...
```
