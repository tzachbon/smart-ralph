# PR Lifecycle

PR management and CI monitoring.

Loaded for: PR_COMMIT tasks.

---

## Completion Checklist

Output exactly `ALL_TASKS_COMPLETE` when:
- taskIndex >= totalTasks AND
- All tasks marked [x] in tasks.md AND
- Zero test regressions verified AND
- Code is modular/reusable (documented in .progress.md)

## Native Task Sync - Completion

Before outputting ALL_TASKS_COMPLETE:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Iterate all entries in `nativeTaskMap`
3. For any task not already `"completed"`: `TaskUpdate(taskId: nativeTaskMap[index], status: "completed")`
4. If any TaskUpdate fails: log warning, continue
5. Log "Native task sync finalized: N tasks synced" to .progress.md

**Original implementation from coordinator-pattern.md commit c20e962f:**

This is the "iterate-all-and-complete" logic that was lost during the refactor. The coordinator MUST complete ALL native tasks in the map when finishing, not just the current task.

**PSEUDOCODE WARNING**: The following is pseudo-code notation, NOT executable bash. `GetNativeTaskStatus` and `TaskUpdate` are Claude Code Tool calls, not shell commands. Do NOT copy-paste this into a shell.

Before iterating (pseudocode):
```text
synced_count=0
for task_id in nativeTaskMap.keys():
    native_id = nativeTaskMap[task_id]
    if native_id is not null:
        native_status = GetNativeTaskStatus(native_id)
        if native_status != "completed":
            TaskUpdate(taskId=native_id, status="completed")
            synced_count += 1
print "Native task sync finalized: $synced_count tasks synced"
```

OR as a reference bash-style sketch (pseudo-code, not executable):
```bash
# PSEUDOCODE ONLY - Do NOT execute (GetNativeTaskStatus and TaskUpdate are not shell commands)
# Sync all native tasks to completed before ALL_TASKS_COMPLETE
if [ "$(jq -r '.nativeSyncEnabled // false' "$SPEC_PATH/.ralph-state.json")" = "false" ]; then
    exit 0
fi

synced_count=0

for task_id in $(jq -r '.nativeTaskMap | keys[]' "$SPEC_PATH/.ralph-state.json"); do
    native_id=$(jq -r ".nativeTaskMap[\"$task_id\"] // \"\"" "$SPEC_PATH/.ralph-state.json")
    if [ -n "$native_id" ]; then
        # PSEUDOCODE: This would be TaskUpdate via Claude Code Tool
        # native_status=$(GetNativeTaskStatus "$native_id")
        # if [ "$native_status" != "completed" ]; then
        #     TaskUpdate taskId="$native_id" status="completed"
        #     synced_count=$((synced_count + 1))
        # fi
        # For now, just log the iteration
        :
    fi
done
echo "Native task sync finalized: $synced_count tasks synced" >> "$SPEC_PATH/.progress.md"
```

This ensures all native tasks are marked complete when the spec finishes, even tasks that were created via SPLIT/FOLLOWUP/ADJUST operations.

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

## PR Lifecycle Loop (Phase 5)

CRITICAL: Phase 5 is continuous autonomous PR management. Do NOT stop until all criteria met.

**Entry Conditions**:
- All Phase 1-4 tasks complete
- Phase 5 tasks detected in tasks.md

**Loop Structure**:
```text
PR Creation -> CI Monitoring -> Review Check -> Fix Issues -> Push -> Repeat
```

**Step 1: Create PR (if not exists)**

Delegate to spec-executor:
```text
Task: Create pull request

Do:
1. Verify not on default branch: git branch --show-current
2. Push branch: git push -u origin <branch>
3. Create PR: gh pr create --title "feat: <spec>" --body "<summary>"

Verify: gh pr view shows PR created
Done when: PR URL returned
Commit: None
```

**Step 2: CI Monitoring Loop**

```text
While (CI checks not all green):
  1. Wait 3 minutes (allow CI to start/complete)
  2. Check status: gh pr checks
  3. If failures:
     - Read failure details: gh run view --log-failed
     - Create new Phase 5.X task in tasks.md
     - Delegate new task to spec-executor with task index and Files list
     - Wait for TASK_COMPLETE
     - Push fixes (if not already pushed by spec-executor)
     - Restart wait cycle
  4. If pending:
     - Continue waiting
  5. If all green:
     - Proceed to Step 3
```

**Step 3: Review Comment Check**

```text
1. Fetch review states: gh pr view --json reviews
   - Parse for reviews with state "CHANGES_REQUESTED" or "PENDING"
   - For inline comments, use REST API: gh api repos/{owner}/{repo}/pulls/{number}/reviews
   - Or use review comments endpoint: gh api repos/{owner}/{repo}/pulls/{number}/comments
2. Parse for unresolved reviews/comments
3. If unresolved reviews/comments found:
   - Create tasks from reviews (add to tasks.md as Phase 5.X)
   - Delegate each to spec-executor
   - Wait for completion
   - Push fixes
   - Return to Step 2 (re-check CI)
4. If no unresolved reviews/comments:
   - Proceed to Step 4
```

**Step 4: Final Validation**

All must be true:
- All Phase 1-4 tasks complete (checked [x])
- All Phase 5 tasks complete
- CI checks all green
- No unresolved review comments
- Zero test regressions (all existing tests pass)
- Code is modular/reusable (verified in .progress.md)

**Step 5: Completion**

When all Step 4 criteria met:
1. Update .progress.md with final state
2. Delete .ralph-state.json
3. Get PR URL: `gh pr view --json url -q .url`
4. Output: ALL_TASKS_COMPLETE
5. Output: PR link

**Timeout Protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: Output error and STOP (do not output ALL_TASKS_COMPLETE)

**Error Handling**:
- If CI fails after 5 retry attempts: STOP with error
- If review comments cannot be addressed: STOP with error
- Document all failures in .progress.md Learnings

## Modification Request Handler

When spec-executor outputs `TASK_MODIFICATION_REQUEST`, parse and process the modification before continuing.

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/references/task-modification.md` for full modification operation handling (SPLIT/PREREQ/FOLLOWUP/ADJUST), task tree restructuring, state map updates, and Native Task Sync for modifications.
