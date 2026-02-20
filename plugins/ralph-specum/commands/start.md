---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick] [--commit-spec] [--no-commit-spec] [--specs-dir <path>]
allowed-tools: "*"
---

# Smart Start

Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one.

## Checklist

Create a task for each item and complete in order:

1. **Handle branch** -- check git branch, create/switch if needed
2. **Parse input** -- extract name, goal, flags from $ARGUMENTS
3. **Classify intent** -- determine what user wants (new spec, resume, quick mode)
4. **Scan existing specs** -- find matching or related specs
5. **Route to action** -- invoke appropriate flow (new, resume, or quick mode)

## Step 1: Branch Management (FIRST STEP)

<mandatory>
Before creating any files or directories, check the current git branch and handle appropriately.
</mandatory>

Read `${CLAUDE_PLUGIN_ROOT}/references/branch-management.md` and follow the full branch decision logic.

**Summary**: Checks current branch, determines if on default branch (main/master), and prompts user for branch strategy (new branch, worktree, or continue). In quick mode, auto-creates branch on default or stays on current. If worktree chosen, STOP here -- user must cd to worktree first.

## Step 2: Parse Input and Classify Intent

Read `${CLAUDE_PLUGIN_ROOT}/references/intent-classification.md` and follow the detection logic.

**Summary**: Extracts name, goal, and flags (--fresh, --quick, --commit-spec, --no-commit-spec, --specs-dir) from $ARGUMENTS. Classifies whether this is a new spec, resume, or quick mode. Determines commit spec behavior. Routes to the appropriate flow below.

### Quick Mode Check

If `--quick` flag detected in $ARGUMENTS, skip to **Step 5: Quick Mode Flow**.

## Step 3: Scan Existing Specs

Read `${CLAUDE_PLUGIN_ROOT}/references/spec-scanner.md` and follow the scanning algorithm and index hint logic.

<mandatory>
**Skip spec scanner and index hint if --quick flag detected in $ARGUMENTS.**
</mandatory>

**Summary**: Scans ./specs/ directory (and all configured specs_dirs) for related specs using keyword matching. Displays related specs with relevance scores. Shows index hint if codebase indexing not yet done. Stores relatedSpecs in .ralph-state.json for use during interview.

## Step 4: Route to Action

Based on detection logic from Step 2:

### Resume Flow

1. Read `$specPath/.ralph-state.json`
2. If no state file -- check which files exist, determine last phase, ask "Continue or restart?"
3. If state file exists -- read phase/taskIndex, show brief status, continue from current phase

**Status Display:**
```text
Resuming: $name
Phase: $phase
Progress: $completed/$total tasks complete
Current: $currentTask

Continuing...
```

**Resume by Phase:**

| Phase | Action |
|-------|--------|
| research | Create research team, spawn parallel teammates, merge results |
| requirements | Invoke product-manager agent |
| design | Invoke architect-reviewer agent |
| tasks | Invoke task-planner agent |
| execution | Invoke spec-executor for current task |

### New Flow

1. If no name provided, ask: "What should we call this spec?" (validates kebab-case)
2. If no goal provided, ask: "What is the goal? Describe what you want to build."
3. Determine spec directory:
   ```text
   specsDir = (--specs-dir if valid) OR (interview response) OR ralph_get_default_dir()
   basePath = "$specsDir/$name"
   ```
4. Create spec directory: `mkdir -p "$basePath"`
5. Update .current-spec (bare name for default dir, full path for non-default)
6. Ensure gitignore entries for specs/.current-spec and **/.progress.md
7. Initialize `.ralph-state.json`:
   ```json
   {
     "source": "spec", "name": "$name", "basePath": "$basePath",
     "phase": "research", "taskIndex": 0, "totalTasks": 0,
     "taskIteration": 1, "maxTaskIterations": 5,
     "globalIteration": 1, "maxGlobalIterations": 100,
     "commitSpec": true, "quickMode": false
   }
   ```
8. Create `.progress.md` with goal
9. Update Spec Index: `./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet`
10. **Goal Interview** -- Read `${CLAUDE_PLUGIN_ROOT}/references/goal-interview.md` and follow brainstorming dialogue
11. **Team Research Phase** -- Read `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md` and follow the dispatch pattern
12. **STOP** -- After merge and state update (awaitingApproval=true), display walkthrough and wait for user

### Research Walkthrough (Normal Mode Only)

<mandatory>
**WALKTHROUGH IS REQUIRED IN NORMAL MODE - DO NOT SKIP.**

After research.md is created, display:

```text
Research complete for '$name'.
Output: $basePath/research.md

## What I Found

**Summary**: [1-2 sentences from Executive Summary]

**Key Recommendations**:
1. [First recommendation]
2. [Second recommendation]
3. [Third recommendation]

**Feasibility**: [High/Medium/Low] | **Risk**: [High/Medium/Low] | **Effort**: [S/M/L/XL]
```

Then STOP. Output: `-> Next: Run /ralph-specum:requirements`
End response immediately.
</mandatory>

## Step 5: Quick Mode Flow

Read `${CLAUDE_PLUGIN_ROOT}/references/quick-mode.md` and follow the full quick mode execution sequence.

**Summary**: Validates input, infers name, creates spec directory, initializes state with quickMode=true, then runs all phases sequentially (research, requirements, design, tasks) delegating to subagents with Quick Mode Directive. Each artifact gets a review loop (max 3 iterations). After all artifacts generated, transitions to execution and invokes spec-executor for task 1.

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE regardless of mode.

**NEVER do any of these yourself:**
- Write code or modify source files
- Perform research or analysis
- Generate spec artifacts (research.md, requirements.md, design.md, tasks.md)
- Execute task steps
- Run verification commands as part of task execution

**ALWAYS delegate to the appropriate subagent:**

| Work Type | Subagent |
|-----------|----------|
| Research | Research Team (multiple parallel teammates) |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Task Planning | `task-planner` |
| Artifact Review | `spec-reviewer` |
| Task Execution | `spec-executor` |

Quick mode does NOT exempt you from delegation -- it only skips interactive phases.
</mandatory>

<mandatory>
## CRITICAL: Stop After Each Subagent (Normal Mode)

After ANY subagent returns in normal mode (no `--quick` flag):

1. Wait for subagent to return
2. Read `$basePath/.ralph-state.json`
3. If `awaitingApproval: true`: STOP IMMEDIATELY
4. Output a brief status message
5. **END YOUR RESPONSE**

**DO NOT:**
- Invoke another subagent in the same response
- Continue to the next phase automatically
- Ask if the user wants to continue

**The user must explicitly run the next command.** This gives them time to review artifacts.

Exception: `--quick` mode runs all phases without stopping.
</mandatory>

## Quick Mode Execution (Stop-Hook)

In quick mode, after generating spec artifacts, execution uses the self-contained stop-hook loop for autonomous task completion. The stop-hook automatically continues by delegating tasks to spec-executor until `ALL_TASKS_COMPLETE` is output.

## Output Examples

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

**Quick mode with --specs-dir:**
```text
Quick mode: Created 'api-auth' at ./packages/api/specs/api-auth/
Generated 4 artifacts from goal.
Starting task 1/N...
```
