---
description: Cancel active execution safely and optionally remove the spec
argument-hint: [spec-name-or-path]
allowed-tools: [Read, Bash, Task]
---

# Cancel Execution

You are canceling the active execution loop. Safe cancel preserves spec and prototype source. Full removal is a separate confirmed action.

## Multi-Directory Resolution

This command uses the path resolver for multi-root spec discovery:

```bash
# Source the path resolver (conceptual - commands use these patterns)
# ralph_find_spec(name)   - Find spec by name across all roots
# ralph_resolve_current() - Get current spec's full path
```

## Determine Target Spec

1. If `$ARGUMENTS` contains input:
   - If starts with `./` or `/`: treat as full path, validate it exists
   - Otherwise: treat as spec name, use `ralph_find_spec()` pattern to search
2. If no argument provided:
   - Use `ralph_resolve_current()` pattern to get active spec path from `.current-spec`
3. If no active spec and no argument, inform user there's nothing to cancel

### Handle Disambiguation

If spec name exists in multiple roots (exit code 2 from find):

```
Multiple specs named '$name' found:
1. ./specs/$name
2. ./packages/api/specs/$name

Specify: /ralph-specum:cancel ./packages/api/specs/$name
```

Do NOT automatically select one. User must specify the full path.

## Check State

1. Check if `$spec_path/.ralph-state.json` exists (where `$spec_path` is the resolved full path)
2. If not, inform user no active loop for this spec

## Read Current State

If state file exists, read and display:
- Current phase
- Task progress (taskIndex/totalTasks)
- Iteration count

Treat a missing `activePrototypes` field as an empty map.

## Cancel Active Prototypes First

If `activePrototypes` is non-empty, resolve `basePath` with `ralph_resolve_context` and run `prototype-records.py reconcile` before cancellation. At the next safe tool boundary, process active IDs in `created`, then ID order:

1. Read the active entry's `leaseToken`, then interrupt its live builder through `prototype-harness.py interrupt`; never stop an unrelated task or a running tool call. Release the lease only after the harness verifies that the recorded builder and its descendants stopped, using `locked-state.py release-lease --id "<id>" --lease-token "<active-entry leaseToken>"`. If interruption is unavailable, fails, or is unverified, retain the lease and active entry and stop cancellation for that ID.
2. Build a terminal record from the active entry with `status: terminal`, `verdict: cancelled`, `gateApproved: false`, the original question and blocking declaration, `returnPhase`, `returnTaskIndex`, timestamps, local branch and isolation pointers, and `sourceDisposition: retained`. Preserve partial implementation, run evidence, stale metadata, and downstream artifacts.
3. Render the record exclusively through `prototype-records.py render-candidate`. If its ID already has candidate or final bytes, preserve them and allocate a new publication ID whose record has `supersedes: ["<original-id>"]`; never overwrite either path.
4. Before review, persist the exact returned `candidateHash`. For the original ID, update its existing entry through compare-and-set `transition`. For a new superseding publication ID, reserve a separate entry through create-only `locked-state.py upsert-prototype --id "<publication-id>"`; copy the cancellation and recovery fields, set `candidateHash` to the exact rendered hash, and retain the original active entry unchanged. If reservation collides, preserve both entries and candidates and allocate another ID.
5. Give `spec-reviewer` the exact candidate bytes and source pointers. Continue only on `REVIEW_PASS`, then call `review-candidate` with the publication ID and exact candidate hash and call `publish` with the state path.
6. Re-read and parse the immutable final and verify that its hash matches the reviewed candidate. Publication removes its own active publication entry. When a superseding ID was used, remove the original active entry only after final verification succeeds; any review, publish, or verification failure retains the original entry.
7. Run reconciliation, then restore the recorded main `phase` and `taskIndex` through `locked-state.py merge` without changing unrelated state.

Cancellation never deletes a prototype worktree, scratch path, local branch, remote branch, partial implementation, or terminal record. Any later local deletion requires a separate confirmation naming the exact path and local branch. Remote deletion is never performed by this command.

## Cleanup

Safe cancel is the default. After every active prototype has a verified immutable `cancelled` record, delete only the execution state:

1. Re-read state with `locked-state.py list --state "$spec_path/.ralph-state.json"`. Continue only when `activePrototypes` is empty.

2. Delete the state file through the locked helper:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" delete-state --state "$spec_path/.ralph-state.json"
   ```

3. Keep the spec directory, terminal prototype records, progress, partial implementation, worktrees, and branches.

4. Keep `.current-spec` pointing at the preserved spec.

If the user explicitly requests full removal, show the resolved spec directory and every prototype isolation path and local branch. Ask for confirmation naming the exact spec directory. Only after that confirmation may the command remove that directory and clear `.current-spec` when it points to the target. Prototype isolation paths and branches need their own exact confirmations; never include them in a recursive spec cleanup or remove a remote branch.

4. Update the spec index after safe cancel or confirmed removal:
   ```bash
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```

## Output

```
Canceled execution for spec: $spec_name

Location: $spec_path
State before cancellation:
- Phase: <phase>
- Progress: <taskIndex>/<totalTasks> tasks
- Iterations: <globalIteration>

Cleanup:
- [x] Removed .ralph-state.json
- [x] Preserved spec directory ($spec_path)
- [x] Preserved prototype source and local branches

Immutable cancelled records: <paths or none>
Nothing else was removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```

## If No Active Loop

If there is no `.ralph-state.json`, report that there is no active loop. Do not remove the spec unless the user explicitly requested full removal and confirms the exact resolved directory.

```
No active execution loop found for spec: $spec_name

Location: $spec_path
Nothing was removed.

To start a new spec:
- Run /ralph-specum:new <name>
- Or /ralph-specum:start <name> <goal>
```
