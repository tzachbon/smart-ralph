---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick|--interactive] [--commit-spec] [--no-commit-spec] [--specs-dir <path>] [--tasks-size fine|coarse]
allowed-tools: "*"
---

# Smart Start

Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one.

## Checklist

Create a task for each item and complete in order:

1. **Parse mode** -- recognize exact `--quick` or `--interactive`
2. **Handle branch** -- check git branch, create/switch if needed
3. **Parse input** -- extract name, goal, and remaining flags
4. **Set up spec** -- create or resolve state before discovery
5. **Run gates** -- discover skills, load contracts, grill, and get approval
6. **Delegate** -- gate the research team, then require artifact approval

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` before starting. It is authoritative for mode, discovery, preload, interview, and delegation enforcement.

## Step 0: Parse Mode Tokens

Tokenize `$ARGUMENTS`. Recognize only exact `--quick` and `--interactive` tokens. If both occur, stop with: `ERROR: --quick and --interactive cannot be used together.` The aliases `-q`, substring matches, and natural-language requests do not select quick mode.

## Step 1: Branch Management (FIRST STEP)

<mandatory>
Before creating any files or directories, check the current git branch and handle appropriately.
</mandatory>

Read `${CLAUDE_PLUGIN_ROOT}/references/branch-management.md` and follow the full branch decision logic.

**Summary**: Checks current branch, determines if on default branch (main/master), and prompts user for branch strategy (new branch, worktree, or continue). Only an exact `--quick` token enables the non-interactive branch choice. If worktree is chosen, STOP here so the user can enter it.

## Step 2: Parse Input and Classify Intent

Read `${CLAUDE_PLUGIN_ROOT}/references/intent-classification.md` and follow the detection logic.

**Summary**: Extracts name, goal, and flags (--fresh, --quick, --commit-spec, --no-commit-spec, --specs-dir, --tasks-size) from $ARGUMENTS. Classifies whether this is a new spec, resume, or quick mode. Determines commit spec behavior. Routes to the appropriate flow below.

### Quick Mode Check

If the exact `--quick` token is present, skip to **Step 5: Quick Mode Flow**. Exact `--interactive` selects the normal flow.

## Step 3: Scan Existing Specs

Read `${CLAUDE_PLUGIN_ROOT}/references/spec-scanner.md` and follow the scanning algorithm and index hint logic.

<mandatory>
**Skip spec scanner and index hint only when the exact `--quick` token is present.**
</mandatory>

**Summary**: Scans ./specs/ directory (and all configured specs_dirs) for related specs using keyword matching. Displays related specs with relevance scores. Shows index hint if codebase indexing not yet done. Stores relatedSpecs in .ralph-state.json for use during interview.

## Step 3.5: Epic Detection

Check if there is an active epic:

```bash
EPIC_FILE="./specs/.current-epic"
if [ -f "$EPIC_FILE" ]; then
  EPIC_NAME=$(cat "$EPIC_FILE" | tr -d '[:space:]')
  # Validate kebab-case to prevent path injection
  if [[ "$EPIC_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    EPIC_STATE="./specs/_epics/$EPIC_NAME/.epic-state.json"
  else
    echo "Warning: Invalid epic name '$EPIC_NAME' in .current-epic, ignoring"
    EPIC_NAME=""
    EPIC_STATE=""
  fi
fi
```

**If active epic exists AND no specific spec name was provided in $ARGUMENTS**:
1. Read `.epic-state.json`
2. First check for any spec with status "in_progress" -- if found, suggest resuming it
3. Otherwise find specs with status "pending" whose dependencies are all "completed"
4. Display brief epic status:
   ```text
   Active epic: $EPIC_NAME (N/M specs complete)
   Next unblocked: <spec-name> -- <goal>
   ```
5. Ask user: "Start this spec, or work on something else?"
   - If user accepts: set `name` and `goal` from the epic's spec definition, set `epicName` in context, continue to Step 4 (New Flow) with pre-populated values
   - If user declines: continue normal Step 4 routing

**If no active epic AND goal appears complex** (multiple distinct components, cross-cutting concerns, user mentions "big" or "large"):
- Suggest: "This looks like it might need multiple specs. Want to run `/triage` instead?"
- If user accepts: invoke `/ralph-specum:triage` with no positional args and let triage collect epic-name + goal interactively. STOP.
- If user declines: continue normal Step 4 routing.

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
| research | Run the research command flow, including discovery/preload/interview approval |
| requirements | Run the requirements command flow, including missing pass 2 discovery |
| design | Run the design command flow and reload all selected contracts |
| tasks | Run the tasks command flow and reload all selected contracts |
| execution | Invoke spec-executor for current task |

For resumed artifact phases, do not delegate from this table directly. Follow the named command's full gate sequence first.

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
6. Ensure gitignore entries for specs/.current-spec, specs/.current-epic, and **/.progress.md
7. Initialize `.ralph-state.json`:
   ```json
   {
     "source": "spec", "name": "$name", "goal": "$goal", "basePath": "$basePath",
     "phase": "research", "taskIndex": 0, "totalTasks": 0,
     "taskIteration": 1, "maxTaskIterations": 5,
     "globalIteration": 1, "maxGlobalIterations": 100,
     "commitSpec": true, "quickMode": false,
     "discoveredSkills": []
   }
   ```
   If this spec was suggested by an active epic, also include:
   ```json
   "epicName": "$EPIC_NAME"
   ```
   in the initial state, and pre-populate the goal and acceptance criteria from `epic.md`.

   **`--tasks-size` handling**: If `--tasks-size` flag is present in `$ARGUMENTS`:
   - If value is `fine` or `coarse`: add `"granularity": "<value>"` to the JSON above
   - If value is invalid (not `fine` or `coarse`): warn the user (`⚠️ Invalid --tasks-size value "<value>", defaulting to fine`) and add `"granularity": "fine"`
   - If `--tasks-size` flag is absent: omit the `granularity` field entirely (do not add it)
8. Create `.progress.md` with goal.
9. Normalize persistent mode with `phase_gate.py mode`. Exact `--quick` enables it, exact `--interactive` clears it, and no flag resets legacy invalid state.
10. Update Spec Index: `./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet`.
11. Run skill discovery pass 1 from `normal-mode-gates.md` after setup.
12. In normal mode, reload the selected contracts and run the goal grill from `${CLAUDE_PLUGIN_ROOT}/references/goal-interview.md` with phase `start`. Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for the explicit approval selection.
13. Immediately after approval, run `check-delegation` and execute the gated Team Research Phase from `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md`. Pass the gate marker and full skill manifest to every `research-analyst` Task. Read-only `Explore` Tasks remain allowed.
14. After research completes, run skill discovery pass 2 from `normal-mode-gates.md`. Do not delegate requirements yet.
15. Display the research walkthrough and enter artifact approval.

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

Ask for explicit artifact approval with `Approve`, `Run review`, and `Request changes` choices. `apply the changes` applies pending feedback through a freshly identified gated research agent, redisplays the walkthrough, and stays in this approval gate. Ask one focused question only when no feedback is pending. After explicit approval, set `awaitingApproval: true`, display `-> Next: Run /ralph-specum:requirements`, and stop.
</mandatory>

## Step 5: Quick Mode Flow

Read `${CLAUDE_PLUGIN_ROOT}/references/quick-mode.md` and follow the full quick mode execution sequence.

Normalize the new state with `phase_gate.py mode "$STATE" --quick`. Every bypassed phase still completes applicable discovery, reloads selected contracts, records a current manifest, calls `begin-interview`, and calls `check-delegation`. Quick mode bypasses only the interview questions and approval.

**Summary**: Validates input, infers name, creates spec directory, initializes state with quickMode=true, then runs all phases sequentially (research, requirements, design, tasks) delegating to subagents with Quick Mode Directive. Each artifact gets a review loop (max 3 iterations). After all artifacts generated, transitions to execution and invokes spec-executor for task 1.

**IMPORTANT**: Each phase MUST be tracked as a native Claude task via `TaskCreate` / `TaskUpdate`. Create a task at phase start (with `activeForm` for spinner text), mark it completed when the phase finishes. This provides visible progress in the UI. See quick-mode.md steps 11-15 for the exact pattern.

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

After ANY subagent returns when the normalized state is interactive:

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
