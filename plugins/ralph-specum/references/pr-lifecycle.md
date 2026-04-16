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

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/references/task-modification.md` for full modification operation handling (SPLIT/PREREQ/FOLLOWUP/ADJUST), task tree restructuring, and state map updates.

**Native Task Sync - Modification**:

When TASK_MODIFICATION_REQUEST is processed and new tasks are inserted into tasks.md:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For SPLIT_TASK:
   - `TaskUpdate` original task status: `"completed"`
   - For each new split task: `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")`, add returned ID to `nativeTaskMap`
3. For ADD_PREREQUISITE:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for prerequisite, add returned ID to `nativeTaskMap`
   - `TaskUpdate` original task with `addBlockedBy: [prerequisite task ID]`
