---
name: ralph-implement
description: Execute the next task from a Ralph spec — reads state, runs one task, advances state. Re-invoke for each subsequent task.
---

# Ralph Implement (Codex CLI)

## Overview

Executes tasks from a Ralph spec's `tasks.md` one at a time. Each invocation reads `.ralph-state.json` to find the current task, executes it, verifies it, commits changes, advances the state, and tells you to re-invoke for the next task.

This skill is designed for Codex CLI, which has no hook system. You drive the loop manually: invoke this skill, it completes one task, then you invoke it again. The state file ensures nothing is lost between invocations.

### Quick Reference

```
Invoke skill -> executes 1 task -> "Re-invoke for next task" -> repeat
                                    (or "ALL_TASKS_COMPLETE" when done)
```

---

## Steps

### 1. Locate the Active Spec

Find the spec directory. Check common locations:

```bash
# Check for .current-spec pointer
for DIR in ./specs ./packages/*/specs; do
  if [ -f "$DIR/.current-spec" ]; then
    SPEC_NAME=$(cat "$DIR/.current-spec")
    SPEC_DIR="$DIR/$SPEC_NAME"
    break
  fi
done
```

If no `.current-spec` file exists, look for directories containing `.ralph-state.json`:

```bash
find ./specs -name ".ralph-state.json" -maxdepth 2 2>/dev/null
```

Set `SPEC_DIR` to the directory containing the state file.

### 2. Read Execution State

```bash
cat "$SPEC_DIR/.ralph-state.json"
```

Extract the key fields:

```bash
TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")
TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")
TASK_ITERATION=$(jq -r '.taskIteration' "$SPEC_DIR/.ralph-state.json")
MAX_TASK_ITER=$(jq -r '.maxTaskIterations' "$SPEC_DIR/.ralph-state.json")
```

If the state file is missing or corrupt, reinitialize:

```bash
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_DIR/tasks.md")

jq -n \
  --arg name "$(basename "$SPEC_DIR")" \
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

### 3. Check for Completion

```bash
if [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ]; then
  rm -f "$SPEC_DIR/.ralph-state.json"
  echo "ALL_TASKS_COMPLETE"
fi
```

If `taskIndex >= totalTasks`: delete the state file and stop. All tasks are done. No further invocations needed.

### 4. Find the Current Task

Parse `tasks.md` to extract the task at `taskIndex` (0-based across all tasks, both checked and unchecked):

```bash
# Find the (taskIndex+1)th task line
TASK_LINE=$(grep -n '^\- \[[ x]\]' "$SPEC_DIR/tasks.md" | sed -n "$((TASK_INDEX + 1))p")
```

Read the full task block starting at that line (the task line plus all indented continuation lines below it). Extract these fields:

| Field | Description |
|-------|-------------|
| **Task ID** | The `X.Y` number (e.g., `2.3`) |
| **Do** | Numbered steps to execute |
| **Files** | Exact files to create or modify |
| **Done when** | Success criteria |
| **Verify** | Command that must exit 0 |
| **Commit** | Exact commit message to use |

Display the task to confirm what will be executed:

```
=== Task TASK_INDEX+1 of TOTAL_TASKS ===
Task ID: X.Y - Task Name
Do: ...
Files: ...
Done when: ...
Verify: ...
Commit: ...
================================
```

### 5. Execute the Task

Follow the **Do** steps exactly as written:

1. Execute each numbered step in order.
2. Only modify files listed in the **Files** section.
3. After all steps, check the **Done when** criteria.

### 6. Run Verification

Run the **Verify** command from the task. It must exit with code 0.

**If it passes**: proceed to step 7.

**If it fails**:
1. Read the error output.
2. Attempt to fix the issue.
3. Re-run verification.
4. If still failing, increment the retry counter:

```bash
jq '.taskIteration += 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/ralph-state.json && \
  mv /tmp/ralph-state.json "$SPEC_DIR/.ralph-state.json"
```

If `taskIteration > maxTaskIterations` (default 5), stop and report the failure. Do not advance to the next task.

### 7. Mark Complete, Commit, Advance State

After verification passes, do all three in sequence:

**a. Mark task done in tasks.md:**

```bash
TASK_ID="X.Y"  # Replace with actual task ID
sed -i '' "s/- \[ \] $TASK_ID /- [x] $TASK_ID /" "$SPEC_DIR/tasks.md"
# Linux: sed -i "s/- \[ \] $TASK_ID /- [x] $TASK_ID /" "$SPEC_DIR/tasks.md"
```

**b. Update .progress.md:**

Add to the `## Completed Tasks` section:

```markdown
- [x] X.Y Task name - <commit-hash>
```

Add any learnings to the `## Learnings` section.

**c. Commit changes:**

```bash
git add <files-from-task-Files-section>
git add "$SPEC_DIR/tasks.md" "$SPEC_DIR/.progress.md"
git commit -m "<commit-message-from-task-Commit-field>"
```

Always include `tasks.md` and `.progress.md` in every commit.

**d. Advance the state file:**

```bash
jq '.taskIndex += 1 | .taskIteration = 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/ralph-state.json && \
  mv /tmp/ralph-state.json "$SPEC_DIR/.ralph-state.json"
```

### 8. Report and Prompt Re-invocation

After advancing state, check if all tasks are now complete:

```bash
NEW_INDEX=$(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")
TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")

if [ "$NEW_INDEX" -ge "$TOTAL_TASKS" ]; then
  rm -f "$SPEC_DIR/.ralph-state.json"
  echo "ALL_TASKS_COMPLETE -- all tasks executed, verified, and committed."
else
  echo "Task $TASK_ID complete ($NEW_INDEX/$TOTAL_TASKS done)."
  echo ""
  echo ">>> Re-invoke this skill to execute the next task. <<<"
fi
```

**This is the critical step for Codex CLI**: since there are no hooks, you must explicitly re-invoke this skill to continue. The state file tracks progress, so each invocation picks up exactly where the last one left off.

---

## Advanced

### State File Format

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

| Field | Description |
|-------|-------------|
| `taskIndex` | 0-based index of the next task to execute |
| `totalTasks` | Total tasks (checked + unchecked) |
| `taskIteration` | Retry count for current task (resets to 1 after each task) |
| `maxTaskIterations` | Max retries before stopping (default: 5) |
| `globalIteration` | Overall loop counter |
| `maxGlobalIterations` | Safety cap (default: 100) |

### All jq State Commands

**Advance to next task:**
```bash
jq '.taskIndex += 1 | .taskIteration = 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/ralph-state.json && \
  mv /tmp/ralph-state.json "$SPEC_DIR/.ralph-state.json"
```

**Retry current task:**
```bash
jq '.taskIteration += 1 | .globalIteration += 1' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/ralph-state.json && \
  mv /tmp/ralph-state.json "$SPEC_DIR/.ralph-state.json"
```

**Initialize from tasks.md:**
```bash
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_DIR/tasks.md")

jq -n \
  --arg name "$(basename "$SPEC_DIR")" \
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

### Check Progress Between Invocations

```bash
SPEC_DIR="./specs/<name>"
echo "Progress: $(jq -r '.taskIndex' "$SPEC_DIR/.ralph-state.json")/$(jq -r '.totalTasks' "$SPEC_DIR/.ralph-state.json")"
```

### Task Format Reference

Every task in `tasks.md` follows this structure:

```markdown
- [ ] X.Y Task name
  - **Do**: Numbered steps to implement
  - **Files**: Exact file paths to create or modify
  - **Done when**: Explicit success criteria
  - **Verify**: Automated command that exits 0 on success
  - **Commit**: `type(scope): description`
```

### Error Recovery

**State file missing**: Reinitialize from `tasks.md` using the initialize command above. It counts checked/unchecked tasks to set the correct `taskIndex`.

**Verification keeps failing**: Check the error output, fix the root cause. If blocked, document the issue in `.progress.md` Learnings section and stop.

**Wrong taskIndex**: Compare the number of `[x]` marks in `tasks.md` with `taskIndex` in the state file. They should match. If they diverge, reinitialize.

**tasks.md missing**: Cannot proceed. Run the tasks phase first (use the `ralph:tasks` skill).

### Anti-Patterns

- Never skip verification -- every task must pass its Verify command.
- Never modify files outside the task's Files list.
- Never commit without passing verification first.
- Never advance taskIndex without completing the current task.
- Never delete .progress.md -- it preserves learnings across the spec lifecycle.
- Never hardcode taskIndex -- always read from `.ralph-state.json`.

### Why Manual Re-invocation?

Codex CLI does not support hooks, stop events, or automatic continuation. The state file (`.ralph-state.json`) acts as the coordination mechanism:

1. Each invocation reads the state, executes one task, writes updated state.
2. Between invocations, the state file persists on disk.
3. No progress is lost -- you can stop and resume at any time.
4. The same spec can be started in Codex and continued in another tool (or vice versa).
