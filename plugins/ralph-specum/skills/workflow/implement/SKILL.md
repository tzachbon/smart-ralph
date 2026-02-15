---
name: ralph:implement
description: Execute tasks from tasks.md sequentially — works with or without automation hooks
---

# Implement Phase

## Overview

The implement phase executes tasks from `tasks.md` one at a time, in order, until all are complete. Each task is self-contained with explicit steps (Do), file targets (Files), success criteria (Done when), a verification command (Verify), and a commit message (Commit).

Execution is driven by a state file (`.ralph-state.json`) that tracks which task to run next. After each task completes, the state advances. When all tasks finish, the state file is deleted and execution is complete.

This skill works in three modes:

1. **Fully automatic** -- Tools with hook systems (stop hooks, idle hooks) re-invoke this skill after each task completes. No user action needed.
2. **Semi-automatic** -- Tools with event hooks can trigger re-invocation programmatically after each task.
3. **Manual re-invocation** -- In tools without hooks, re-invoke this skill after each task to continue. The state file tracks progress so each invocation picks up where the last left off.

### Inputs

- `specs/<name>/tasks.md` -- Ordered task list with Do/Files/Done when/Verify/Commit format.
- `specs/<name>/.ralph-state.json` -- Execution state (taskIndex, totalTasks, iteration counters).
- `specs/<name>/.progress.md` -- Progress tracking, learnings, completed task history.

### Output

- Tasks marked `[x]` in `tasks.md` as they complete.
- Updated `.progress.md` with completion entries and learnings.
- One git commit per task using the task's Commit message.
- Deleted `.ralph-state.json` when all tasks finish (signals completion).

---

## Steps

### 1. Read Execution State

Read the state file to determine where to start:

```bash
SPEC_DIR="./specs/<name>"
cat "$SPEC_DIR/.ralph-state.json"
```

Key fields:

| Field | Description |
|-------|-------------|
| `taskIndex` | Current task to execute (0-based) |
| `totalTasks` | Total number of tasks in tasks.md |
| `taskIteration` | Retry count for the current task |
| `maxTaskIterations` | Max retries before stopping (default: 5) |
| `globalIteration` | Overall loop iteration count |
| `maxGlobalIterations` | Safety cap on total iterations (default: 100) |

If the state file is missing or corrupt, reinitialize it:

```bash
SPEC_DIR="./specs/<name>"
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_DIR/tasks.md")

jq -n \
  --arg name "<name>" \
  --arg basePath "$SPEC_DIR" \
  --argjson total "$TOTAL" \
  --argjson completed "$COMPLETED" \
  '{
    source: "spec",
    name: $name,
    basePath: $basePath,
    phase: "execution",
    taskIndex: $completed,
    totalTasks: ($total + $completed),
    taskIteration: 1,
    maxTaskIterations: 5,
    globalIteration: 1,
    maxGlobalIterations: 100
  }' > "$SPEC_DIR/.ralph-state.json"
```

### 2. Check Completion

Before doing anything else, check if all tasks are already done:

```bash
SPEC_DIR="./specs/<name>"
TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")
TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")

if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ]; then
  echo "All tasks complete"
  rm -f "$SPEC_DIR/.ralph-state.json"
  echo "ALL_TASKS_COMPLETE"
  exit 0
fi
```

If `taskIndex >= totalTasks`, delete the state file and report `ALL_TASKS_COMPLETE`. No further action needed.

### 3. Find the Current Task

Parse `tasks.md` to find the task at `taskIndex`. Tasks are numbered like `1.1`, `1.2`, `2.1`, etc. The taskIndex is 0-based, so taskIndex=0 is the first unchecked task.

To find the Nth unchecked task (0-indexed):

```bash
SPEC_DIR="./specs/<name>"
TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")

# Count checked tasks before current index to find the right line
# Tasks are in order; taskIndex counts from 0 across ALL tasks (checked + unchecked)
# Find the (taskIndex+1)th task line (matching both [ ] and [x])
TASK_LINE=$(grep -n '^\- \[[ x]\]' "$SPEC_DIR/tasks.md" | sed -n "$((TASK_INDEX + 1))p")
```

Extract the full task block: the task line plus all indented lines below it (lines starting with spaces that belong to the same task).

Read the task block and extract:
- **Task ID**: The `X.Y` number (e.g., `1.3`)
- **Do**: Steps to execute
- **Files**: Files to create or modify
- **Done when**: Success criteria
- **Verify**: Command that exits 0 on success
- **Commit**: Commit message to use

### 4. Execute the Task

Follow the Do steps exactly as written:

1. Read the Do section and execute each numbered step.
2. Only modify files listed in the Files section.
3. After executing all steps, check the Done when criteria.

### 5. Run Verification

Run the Verify command from the task:

```bash
# Example: the Verify field from the task
<verify-command-from-task>
```

The command must exit with code 0 for the task to pass.

**If verification passes**: proceed to step 6.

**If verification fails**:
1. Read the error output.
2. Attempt to fix the issue.
3. Re-run verification.
4. If still failing after reasonable attempts, document the error and increment the retry counter:

```bash
SPEC_DIR="./specs/<name>"
jq '.taskIteration += 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

If `taskIteration` exceeds `maxTaskIterations`, stop execution and document the failure in `.progress.md`. Do not continue to the next task.

### 6. Mark Task Complete

After verification passes, update the spec files:

**a. Mark the task as done in tasks.md**

Change `- [ ]` to `- [x]` for the completed task line:

```bash
SPEC_DIR="./specs/<name>"
TASK_ID="X.Y"  # The task number from step 3

# Replace the checkbox for this specific task
sed -i '' "s/- \[ \] $TASK_ID /- [x] $TASK_ID /" "$SPEC_DIR/tasks.md"
# On Linux, omit the '' after -i:
# sed -i "s/- \[ \] $TASK_ID /- [x] $TASK_ID /" "$SPEC_DIR/tasks.md"
```

**b. Update .progress.md**

Add the completed task to the `## Completed Tasks` section:

```markdown
- [x] X.Y Task name - <commit-hash>
```

Add any learnings discovered during execution to the `## Learnings` section.

Update `## Current Task` to reflect the next task (or "Awaiting next task" if re-invoking).

**c. Commit changes**

Use the exact commit message from the task's Commit field:

```bash
git add <files-from-task>
git add "$SPEC_DIR/tasks.md" "$SPEC_DIR/.progress.md"
git commit -m "<commit-message-from-task>"
```

Always include `tasks.md` and `.progress.md` in every commit to keep progress tracking in sync.

### 7. Advance State

After committing, update the state file to point to the next task:

```bash
SPEC_DIR="./specs/<name>"
jq '.taskIndex += 1 | .taskIteration = 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

This increments `taskIndex` by 1, resets `taskIteration` to 1 (fresh retry counter for next task), and increments `globalIteration`.

### 8. Check If Done or Continue

After advancing state, check if all tasks are now complete:

```bash
SPEC_DIR="./specs/<name>"
TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")
TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")

if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ]; then
  # All tasks done -- clean up
  rm -f "$SPEC_DIR/.ralph-state.json"
  echo "ALL_TASKS_COMPLETE"
else
  echo "Task complete. Next: task $TASK_INDEX of $TOTAL_TASKS"
  # Continue to next task (see Execution Modes below)
fi
```

**If all tasks are done**:
1. Verify all tasks are marked `[x]` in tasks.md.
2. Delete `.ralph-state.json` (execution is over).
3. Keep `.progress.md` (preserves learnings and history).
4. Report `ALL_TASKS_COMPLETE`.

**If tasks remain**: continue execution using the appropriate mode (see below).

---

## Advanced

### Execution Modes

Different tools handle the "continue to next task" step differently:

#### Claude Code (Automatic via Stop Hook)

Claude Code uses a stop hook that fires after each assistant turn. The hook reads `.ralph-state.json`, and if `taskIndex < totalTasks`, it outputs a continuation prompt that keeps the execution loop running. No user action needed.

Setup: The stop hook is pre-configured in the plugin. Invoke the implement command and it runs to completion hands-free.

#### OpenCode (Automatic via JS/TS Hooks)

OpenCode uses JavaScript/TypeScript plugin hooks. A `session.idle` or `tool.execute.after` hook reads `.ralph-state.json` and triggers the next task automatically.

Setup: Register the execution loop hook in your OpenCode plugin configuration. See the OpenCode adapter README for details.

#### Codex CLI (Manual Re-invocation)

Codex CLI has no hook system. After each task completes, re-invoke this skill to execute the next task.

Workflow:
1. Invoke this skill -- it executes the current task (one task per invocation).
2. When it reports the task is complete, invoke this skill again.
3. Repeat until you see `ALL_TASKS_COMPLETE`.

Each invocation reads `taskIndex` from `.ralph-state.json`, so it always picks up where the last invocation left off. Progress is never lost between invocations.

**Tip**: You can check progress at any time:
```bash
SPEC_DIR="./specs/<name>"
echo "Progress: $(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")/$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")"
```

### State File Format Reference

The `.ralph-state.json` file tracks all execution state:

```json
{
  "source": "spec",
  "name": "<spec-name>",
  "basePath": "./specs/<spec-name>",
  "phase": "execution",
  "taskIndex": 0,
  "totalTasks": 20,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100
}
```

| Field | Type | Description |
|-------|------|-------------|
| `source` | string | `"spec"` for normal mode, `"plan"` for quick mode |
| `name` | string | Spec name (kebab-case) |
| `basePath` | string | Path to spec directory |
| `phase` | string | Should be `"execution"` during implementation |
| `taskIndex` | number | 0-based index of the current task to execute |
| `totalTasks` | number | Total tasks in tasks.md (checked + unchecked) |
| `taskIteration` | number | Current retry count for the active task (resets to 1 after each task) |
| `maxTaskIterations` | number | Max retries before stopping (default: 5) |
| `globalIteration` | number | Overall execution loop iteration count |
| `maxGlobalIterations` | number | Safety cap on total iterations (default: 100) |

### State Update Commands (jq)

All state updates use `jq` to modify `.ralph-state.json` in place:

**Advance to next task** (after successful completion):
```bash
jq '.taskIndex += 1 | .taskIteration = 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

**Retry current task** (after verification failure):
```bash
jq '.taskIteration += 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

**Initialize execution state** (merging into existing state file):
```bash
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_DIR/tasks.md")

jq --argjson taskIndex "$COMPLETED" \
   --argjson totalTasks "$((TOTAL + COMPLETED))" \
   '. + {
     phase: "execution",
     taskIndex: $taskIndex,
     totalTasks: $totalTasks,
     taskIteration: 1,
     maxTaskIterations: 5,
     globalIteration: 1,
     maxGlobalIterations: 100
   }' "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && \
   mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

### Task Format Reference

Every task in `tasks.md` follows this format:

```markdown
- [ ] X.Y Task name
  - **Do**: Numbered steps to implement
  - **Files**: Exact file paths to create or modify
  - **Done when**: Explicit success criteria
  - **Verify**: Automated command that exits 0 on success
  - **Commit**: `type(scope): description`
```

### Commit Discipline

Every task produces exactly one commit:

1. Stage the files listed in the task's Files section.
2. Also stage `tasks.md` and `.progress.md` (progress tracking).
3. Use the exact commit message from the task's Commit field.
4. Never commit failing code -- verification must pass first.

### Error Handling

**Verification failure**: Fix the issue, re-run verification. If it fails after multiple attempts, increment `taskIteration`. If `taskIteration > maxTaskIterations`, stop and document the failure.

**Missing state file**: Reinitialize from `tasks.md` by counting checked/unchecked tasks (see step 1).

**Missing tasks.md**: Cannot proceed. Run the tasks phase first to generate the task list.

**Global iteration limit**: If `globalIteration >= maxGlobalIterations`, stop execution. This is a safety valve to prevent infinite loops.

### Single-Task Invocation Pattern (for tools without hooks)

When your tool does not support automatic continuation, follow this pattern for each invocation:

```
1. Read .ralph-state.json -> get taskIndex
2. If taskIndex >= totalTasks -> ALL_TASKS_COMPLETE (delete state file)
3. Parse task at taskIndex from tasks.md
4. Execute Do steps
5. Run Verify command
6. If pass:
   a. Mark task [x] in tasks.md
   b. Update .progress.md
   c. Commit changes
   d. Advance taskIndex in state file
   e. Report: "Task X.Y complete. Re-invoke to continue."
7. If fail:
   a. Increment taskIteration in state file
   b. If under retry limit: attempt fix, re-verify
   c. If over retry limit: report failure, stop
```

Each invocation handles exactly one task. The state file ensures no task is skipped or repeated across invocations.

### Completion Checklist

Before reporting `ALL_TASKS_COMPLETE`, verify:

- [ ] All tasks marked `[x]` in tasks.md
- [ ] All commits made (one per task)
- [ ] `.progress.md` updated with all completed tasks and learnings
- [ ] `.ralph-state.json` deleted (execution state cleaned up)
- [ ] No uncommitted changes in spec files

### Anti-Patterns

- **Never skip verification** -- Every task must pass its Verify command before being marked complete.
- **Never modify files outside the task's Files list** -- Stay within scope.
- **Never commit without verification** -- Failing code should never be committed.
- **Never advance taskIndex without completing the current task** -- Tasks are sequential for a reason.
- **Never delete .progress.md** -- It preserves learnings across the entire spec lifecycle.
- **Never hardcode taskIndex** -- Always read it from `.ralph-state.json`.
