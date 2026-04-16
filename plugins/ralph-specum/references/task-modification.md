# Task Modification

Task modification operations (SPLIT/PREREQ/FOLLOWUP/ADJUST).

Loaded for: SPLIT, PREREQ, FOLLOWUP, ADJUST tasks.

**Native Task Sync** (completion, modification operations):
See coordinator-core.md 'Native Task Sync - After Completion' section.

### Native Task Sync - Modification

When TASK_MODIFICATION_REQUEST is processed and new tasks are inserted into tasks.md:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For SPLIT_TASK:
   - `TaskUpdate` original task status: `"completed"`
   - For each new split task: `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")`, add returned ID to `nativeTaskMap`
3. For ADD_PREREQUISITE:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for prerequisite, add returned ID to `nativeTaskMap`
   - `TaskUpdate` original task with `addBlockedBy: [prerequisite task ID]`
4. For ADD_FOLLOWUP:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for followup, add returned ID to `nativeTaskMap`
5. Update `nativeTaskMap` in .ralph-state.json with new entries
6. Re-indexing: rebuild `nativeTaskMap` to match the updated tasks.md order.
   - Parse tasks.md in order after insertion.
   - Keep existing native task IDs for unchanged task identities (match by task ID pattern `X.Y` in subject, not title alone).
   - Assign newly created IDs to inserted tasks at their actual indices.
   - Persist the fully re-keyed map to .ralph-state.json.
7. If any TaskCreate/TaskUpdate fails: log warning, continue

Before outputting:
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json (cleanup execution state)
3. Keep .progress.md (preserve learnings and history)
4. **Cleanup orphaned temp progress files** (from interrupted parallel batches):
   ```bash
   find "$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true
   ```
5. **Update Spec Index** (marks spec as completed):
   ```bash
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```
6. **Commit all remaining spec changes** (progress, tasks, index):
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): final progress update for $spec"
   ```
7. Check for PR and output link if exists: `gh pr view --json url -q .url 2>/dev/null`

This signal terminates the Ralph Loop.

**PR Link Output**: If a PR was created during execution, output the PR URL after ALL_TASKS_COMPLETE:
```text
ALL_TASKS_COMPLETE

PR: https://github.com/owner/repo/pull/123
```

Do NOT output ALL_TASKS_COMPLETE if tasks remain incomplete.
Do NOT output TASK_COMPLETE (that's for spec-executor only).

## Modification Request Handler

When spec-executor outputs `TASK_MODIFICATION_REQUEST`, parse and process the modification before continuing.

**Detection**:

Check executor output for the literal string `TASK_MODIFICATION_REQUEST` followed by a JSON code block.

**Parse Modification Request**:

Extract the JSON payload:
```json
{
  "type": "SPLIT_TASK" | "ADD_PREREQUISITE" | "ADD_FOLLOWUP",
  "originalTaskId": "X.Y",
  "reasoning": "...",
  "proposedTasks": ["markdown task block", "..."]
}
```

**Validate Request**:

1. Read `modificationMap` from .ralph-state.json
2. Count: `modificationMap[originalTaskId].count` (default 0)
3. If count >= 3: REJECT, log "Max modifications (3) reached for task $taskId" in .progress.md, skip modification
4. Depth check: count dots in proposed task IDs. If dots > 3 (depth > 3 levels): REJECT
5. For SPLIT_TASK/ADD_PREREQUISITE/ADD_FOLLOWUP: verify proposed tasks have required fields: Do, Files, Done when, Verify, Commit
6. For SPEC_ADJUSTMENT: verify `proposedChange` has `field`, `original`, `amended`, `affectedTasks`; and `investigation` is non-empty

**Process by Type**:

**SPLIT_TASK**:
1. Mark original task [x] in tasks.md (executor completed what it could)
2. Insert all proposedTasks after original task block using Edit tool
3. Update totalTasks += proposedTasks.length in state
4. Update modificationMap
5. Set taskIndex to first inserted sub-task
6. Log in .progress.md: "Split task $taskId into N sub-tasks: [ids]. Reason: $reasoning"

**ADD_PREREQUISITE**:
1. Do NOT mark original task complete
2. Insert proposedTask BEFORE current task block using Edit tool
3. Update totalTasks += 1 in state
4. Update modificationMap
5. Reset taskIteration to 1 in .ralph-state.json (prerequisite is a new task, original task gets a fresh attempt)
6. Delegate prerequisite task to spec-executor
7. After prereq completes: retry original task with taskIteration=1
8. Log in .progress.md: "Added prerequisite $prereqId before $taskId. Reason: $reasoning"

**ADD_FOLLOWUP**:
1. Original task should already be marked [x] (executor outputs TASK_COMPLETE too)
2. Insert proposedTask after current task block using Edit tool
3. Update totalTasks += 1 in state
4. Update modificationMap
5. Normal advancement -- followup will be picked up as next task
6. Log in .progress.md: "Added followup $followupId after $taskId. Reason: $reasoning"

**SPEC_ADJUSTMENT**:
1. Validate scope — auto-approve if ALL of the following:
   - `proposedChange.field` is `"Verify"` or `"Done when"` (task criteria fields only, not acceptance criteria)
   - `investigation` field is non-empty (agent gathered evidence)
   - `proposedChange.affectedTasks.length` ≤ `totalTasks / 2` (not a wholesale spec rewrite)
2. If **auto-approved**:
   a. For each task ID in `affectedTasks`: edit that task's `Verify:` or `Done when:` field in tasks.md to `proposedChange.amended` using Edit tool.
   b. Log in `.progress.md` under `## Spec Adjustments`:
      ```
      - [SPEC-ADJUSTMENT] task $originalTaskId → amended $field for tasks $affectedTasks
        Reason: $reasoning
        Evidence: $investigation
        Original: $original
        Amended: $amended
      ```
   c. Continue execution — the next delegation will use the amended criteria. Do NOT count against `modificationMap` limit.
3. If **not auto-approved** (field is not Verify/Done-when, no investigation, or scope too large):
   a. Write `SPEC-DEFICIENCY` to chat.md via atomic append with the full proposal and why it cannot be auto-applied.
   b. Set `awaitingHumanInput: true` in `.ralph-state.json`.
   c. Halt execution until human responds.

**Parallel Batch Interaction**:
- If current task is in a [P] batch and executor requests modification: break out of parallel batch
- Re-evaluate remaining [P] tasks as sequential after modification
- This prevents inserting tasks mid-batch which would corrupt parallel execution

**Update State (modificationMap)**:

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

> **Note**: Set `PROPOSED_COUNT` to the number of proposed tasks (e.g., `PROPOSED_COUNT=$(echo "$PROPOSED_TASKS" | jq 'length')`). For SPLIT_TASK this is N (the number of sub-tasks), for ADD_PREREQUISITE and ADD_FOLLOWUP this is 1.

**Insertion Algorithm** (same pattern as fix task insertion):

1. Read tasks.md
2. Locate target task by ID pattern: `- [ ] $taskId` or `- [x] $taskId`
3. Find task block end (next `- [ ]`, `- [x]`, `## Phase`, or EOF)
4. For ADD_PREREQUISITE: insert before task block start
5. For SPLIT_TASK/ADD_FOLLOWUP: insert after task block end
6. Use Edit tool with old_string/new_string
