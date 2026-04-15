# Native Task Sync Algorithm

Native Task Sync patterns for bidirectional sync between tasks.md and Claude Code's native task system.

Reference: plugins/ralph-specum/references/coordinator-pattern.md lines 756-908

---

## Graceful Degradation Pattern

For all Native Task Sync operations:

```
On success: reset nativeSyncFailureCount to 0
On failure: increment nativeSyncFailureCount
If count >= 3: set nativeSyncEnabled = false, log warning
```

This pattern prevents cascading failures when native task sync is unavailable or broken.

---

## Native Task Sync - Pre-Delegation

Before delegating the current task:

```bash
# Skip if sync is disabled
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    echo "Native Task Sync disabled, skipping"
    exit 0
fi

# Skip if nativeTaskMap is missing
if ! jq -e '.nativeTaskMap' "$SPEC_PATH/.ralph-state.json" >/dev/null 2>&1; then
    echo "nativeTaskMap not found, skipping"
    exit 0
fi

# Look up native task ID
nativeTaskId=$(jq -r ".nativeTaskMap[$taskIndex] // \"\"" "$SPEC_PATH/.ralph-state.json")

if [ -n "$nativeTaskId" ]; then
    # Format activeForm per FR-12
    activeForm="Executing $taskIndex $TASK_TITLE"

    # Update native task status
    TaskUpdate taskId="$nativeTaskId" status="in_progress" activeForm="$activeForm" 2>/dev/null || \
    { echo "Warning: TaskUpdate failed for $nativeTaskId"; nativeSyncFailureCount=$((nativeSyncFailureCount + 1)); }

    # Check graceful degradation
    if [ "$nativeSyncFailureCount" -ge 3 ]; then
        echo "Warning: Sync failures >= 3, disabling native sync"
        jq '.nativeSyncEnabled = false' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
        mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
    fi
fi
```

---

## Native Task Sync - Bidirectional Check

Before each task delegation, reconcile tasks.md with native task state:

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

if ! jq -e '.nativeTaskMap' "$SPEC_PATH/.ralph-state.json" >/dev/null 2>&1; then
    exit 0
fi

# Scan tasks.md for completed tasks
completedTasks=$(grep -oE '\- \[x\] [0-9]+\.[0-9]+' "$SPEC_PATH/tasks.md" | awk '{print $3}')

# For each completed task in tasks.md, check native state
for task_id in $completedTasks; do
    native_id=$(jq -r ".nativeTaskMap[\"$task_id\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
    if [ -n "$native_id" ]; then
        # Check native task status (pseudo-code, depends on Claude Code API)
        native_status=$(GetNativeTaskStatus "$native_id")
        if [ "$native_status" != "completed" ]; then
            TaskUpdate taskId="$native_id" status="completed" 2>/dev/null || \
            { echo "Warning: TaskUpdate failed"; }
        fi
    fi
done
```

---

## Native Task Sync - Parallel

When parallel [P] group starts:

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

if ! jq -e '.nativeTaskMap' "$SPEC_PATH/.ralph-state.json" >/dev/null 2>&1; then
    exit 0
fi

# For each taskIndex in parallelGroup.taskIndices
for task_id in "${parallelGroup[taskIndices[@]}]"; do
    native_id=$(jq -r ".nativeTaskMap[\"$task_id\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
    if [ -n "$native_id" ]; then
        activeForm="Executing [P] $task_id $TASK_TITLE"
        # ALL TaskUpdate calls in ONE message (parallel tool calls)
        TaskUpdate taskId="$native_id" status="in_progress" activeForm="$activeForm"
    fi
done
```

---

## Native Task Sync - Failure

On task failure (any task type):

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

native_id=$(jq -r ".nativeTaskMap[\"$taskIndex\"] // \"\"" "$SPEC_PATH/.ralph-state.json")

if [ -n "$native_id" ]; then
    TaskUpdate taskId="$native_id" status="todo" 2>/dev/null || \
    {
        echo "Warning: TaskUpdate failed for $native_id"
        nativeSyncFailureCount=$((nativeSyncFailureCount + 1))
        if [ "$nativeSyncFailureCount" -ge 3 ]; then
            echo "Warning: Sync failures >= 3, disabling native sync"
            jq '.nativeSyncEnabled = false' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
            mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
        fi
    }
fi
```

---

## Native Task Sync - Completion

Before outputting ALL_TASKS_COMPLETE:

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

synced_count=0

# Iterate all entries in nativeTaskMap
for task_id in $(jq -r '.nativeTaskMap | keys[]' "$SPEC_PATH/.ralph-state.json"); do
    native_id=$(jq -r ".nativeTaskMap[\"$task_id\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
    if [ -n "$native_id" ]; then
        # Check if already completed
        native_status=$(GetNativeTaskStatus "$native_id")
        if [ "$native_status" != "completed" ]; then
            TaskUpdate taskId="$native_id" status="completed" 2>/dev/null && \
            synced_count=$((synced_count + 1))
        fi
    fi
done

echo "Native task sync finalized: $synced_count tasks synced" >> "$SPEC_PATH/.progress.md"
```

---

## Native Task Sync - Modification

When TASK_MODIFICATION_REQUEST is processed and new tasks are inserted into tasks.md:

### SPLIT_TASK

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

original_id=$(jq -r ".nativeTaskMap[\"$originalTaskId\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
if [ -n "$original_id" ]; then
    TaskUpdate taskId="$original_id" status="completed"
fi

# For each new split task
for new_task_id in "${newTaskIds[@]}"; do
    new_native_id=$(TaskCreate subject="$newTaskTitle" description="$newTaskDescription" activeForm="$newTaskActiveForm")
    jq --arg key "$new_task_id" --arg val "$new_native_id" \
       '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
       mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
done
```

### ADD_PREREQUISITE

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

prereq_native_id=$(TaskCreate subject="$prereqTitle" description="$prereqDescription" activeForm="$prereqActiveForm")
jq --arg key "$prereqTaskId" --arg val "$prereq_native_id" \
   '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
   mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"

# Mark original task as blocked by prerequisite
original_id=$(jq -r ".nativeTaskMap[\"$originalTaskId\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
if [ -n "$original_id" ]; then
    TaskUpdate taskId="$original_id" addBlockedBy="$prereq_native_id"
fi
```

### ADD_FOLLOWUP

```bash
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

followup_native_id=$(TaskCreate subject="$followupTitle" description="$followupDescription" activeForm="$followupActiveForm")
jq --arg key "$followupTaskId" --arg val "$followup_native_id" \
   '.nativeTaskMap[$key] = $val' "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
   mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
```
