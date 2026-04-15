# State Update Pattern

jq state merge patterns for updating .ralph-state.json atomically.

Reference: plugins/ralph-specum/references/coordinator-pattern.md line 642

---

## Update lastReadLine After Reading chat.md

After reading chat.md to process new messages, update the executor's last read line:

```bash
LINES=$(wc -l < "$SPEC_PATH/chat.md")
jq --argjson idx "$LINES" '.chat.executor.lastReadLine = $idx' \
  "$SPEC_PATH/.ralph-state.json" > /tmp/state.json && \
  mv /tmp/state.json "$SPEC_PATH/.ralph-state.json"
```

---

## Update State with Multiple Fields

Common pattern for updating state with multiple fields atomically:

```bash
jq --arg taskIndex "$TASK_INDEX" \
   --arg taskIteration "$TASK_ITERATION" \
   --arg globalIteration "$GLOBAL_ITERATION" \
   '
   .taskIndex = $taskIndex |
   .taskIteration = $taskIteration |
   .globalIteration = $globalIteration
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

---

## Increment Counter

Increment a counter field (e.g., nativeSyncFailureCount, taskIteration):

```bash
jq '.nativeSyncFailureCount += 1' \
  "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
  mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

---

## Set Boolean Flag

Set a boolean flag (e.g., nativeSyncEnabled, awaitingHumanInput):

```bash
jq '.nativeSyncEnabled = false' \
  "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
  mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

---

## Update Object Field

Update a nested object field (e.g., chat.executor.lastReadLine):

```bash
jq '.chat.executor.lastReadLine = 123' \
  "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
  mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

---

## Atomic Merge with Verification

Verify JSON is valid before replacing:

```bash
if jq empty "$SPEC_PATH/.ralph-state.json" 2>/dev/null; then
  jq --arg newField "$NEW_VALUE" '. + {newField: $newField}' \
    "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
    mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
else
  echo "ERROR: Invalid JSON in .ralph-state.json"
  exit 1
fi
```

---

## Update modificationMap

Update modificationMap when a task is modified:

```bash
jq --arg taskId "$TASK_ID" \
   --arg modId "$MOD_TASK_ID" \
   --arg reason "$REASONING" \
   --arg type "$MOD_TYPE" \
   --argjson delta "$PROPOSED_COUNT" \
   '
   .modificationMap //= {} |
   .modificationMap[$taskId] //= {count: 0, modifications: []} |
   .modificationMap[$taskId].count += 1 |
   .modificationMap[$taskId].modifications += [{id: $modId, type: $type, reason: $reason}] |
   .totalTasks += $delta
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

---

## Update nativeTaskMap

Add a new task ID to nativeTaskMap:

```bash
jq --arg taskIndex "$TASK_INDEX" \
   --arg taskId "$TASK_ID" \
   '.nativeTaskMap[$taskIndex] = $taskId' \
   "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```
