---
description: Start task execution loop
argument-hint: [--max-task-iterations 5] [--max-global-iterations 100] [--recovery-mode]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop.

## Checklist

Create a task for each item and complete in order:

1. **Validate prerequisites** -- check spec and tasks.md exist
2. **Parse arguments** -- extract flags and options
3. **Initialize state** -- write .ralph-state.json
4. **Execute task loop** -- delegate tasks via coordinator pattern
5. **Handle completion** -- cleanup and output ALL_TASKS_COMPLETE

## Step 1: Determine Active Spec and Validate

**Multi-Directory Resolution**: This command uses the path resolver for dynamic spec path resolution.
- `ralph_resolve_current()` -- resolves .current-spec to full path (bare name = ./specs/$name, full path = as-is)
- `ralph_find_spec(name)` -- find spec by name across all configured roots

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

**Resolve**:
1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it
2. Otherwise, use `ralph_resolve_current()` to get the active spec path
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

**Validate**:
1. Check the resolved spec directory exists
2. Check the spec's tasks.md exists. If not: error "Tasks not found. Run /ralph-specum:tasks first."
3. Set `$SPEC_PATH` to the resolved spec directory path. All references use this variable.

### Prototype Dispatch Gate

Before initialization or task dispatch:

1. Read `.ralph-state.json` and reconcile whenever state exists:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" reconcile --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json"
   ```
2. Parse `tasks.md` once into ordered top-level task rows before selection. A task row is an unindented checkbox outside fenced example blocks whose next token is a concrete numeric task ID, `V<number>`, `VE<number>`, or `VF`. Exclude nested and example checkboxes, completion criteria, and placeholder IDs. Derive every counter from that one ordered list:
   ```bash
   TASK_COUNTS=$(python3 - "$SPEC_PATH/tasks.md" <<'PY'
   import re
   import sys
   from pathlib import Path

   task_re = re.compile(r"^- \[(?P<mark>[ xX])\] (?P<id>(?:\d+(?:\.\d+)+|V\d+|VE\d+|VF))\b")
   rows = []
   fence = None
   for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
       stripped = line.lstrip()
       marker = stripped[:3]
       if marker in {"```", "~~~"}:
           fence = None if fence == marker else marker if fence is None else fence
           continue
       if fence is None:
           match = task_re.match(line)
           if match:
               rows.append(match.group("mark").lower() == "x")

   total = len(rows)
   completed = sum(rows)
   first_incomplete = next((index for index, done in enumerate(rows) if not done), total)
   print(f"{total}\t{completed}\t{first_incomplete}")
   PY
   )
   IFS=$'\t' read -r TOTAL COMPLETED FIRST_INCOMPLETE <<EOF
   $TASK_COUNTS
   EOF
   TASK_INDEX_TO_MERGE=$FIRST_INCOMPLETE
   TASK_INDEX=$TASK_INDEX_TO_MERGE
   ```
   `TOTAL` is the row count. `COMPLETED` is the completed count across all rows, regardless of order. `FIRST_INCOMPLETE` is the zero-based position of the first incomplete row, or `TOTAL` when all rows are complete. It is independent of `COMPLETED`, so non-prefix completion cases dispatch the earliest unchecked task. For fresh execution, keep `TASK_INDEX_TO_MERGE=$FIRST_INCOMPLETE`. On prototype return, read the relevant ID's `returnTaskIndex` from its reconciled active entry or immutable terminal record. Require a non-negative integer within the task list and verify that it identifies the first eligible incomplete task. Set both `TASK_INDEX_TO_MERGE` and `TASK_INDEX` to that validated value before selection.
3. When `activePrototypes` is nonempty or the `prototypes/` history directory exists, select for execution, the resolved dispatch task, and every declared path for that task:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" select-downstream --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json" --target execution --target "task:$TASK_INDEX" --path "<each declared current-task path>"
   ```
4. Stop before dispatch when `activeBlockers` targets execution or the resolved task, when `staleTaskIndexes` contains `TASK_INDEX`, or when `staleArtifacts` contains an upstream artifact required by that task. Report the prototype ID and route resume through `/ralph-specum:prototype --resume <id>`.
5. Preserve eligible work only when every matching `targetDecisions` entry has `proofAvailable: true` and `eligible: true`. Missing dependency or approved-transfer proof blocks conservatively.

## Step 2: Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)
- **--max-global-iterations**: Max total loop iterations (default: 100). Safety limit to prevent infinite execution loops.
- **--recovery-mode**: Enable iterative failure recovery (default: false). When enabled, failed tasks trigger automatic fix task generation instead of stopping.

## Step 3: Initialize Execution State

Use `TOTAL`, `COMPLETED`, `FIRST_INCOMPLETE`, and `TASK_INDEX_TO_MERGE` from the Prototype Dispatch Gate. Do not recalculate or replace the validated dispatch index after selection.

**CRITICAL: Merge into existing state -- do NOT overwrite the file.**

Read the existing `.ralph-state.json` first, then **merge** the execution fields into it.
This preserves fields set by earlier phases (e.g., `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`).

Update `.ralph-state.json` by merging these fields into the existing object:
```json
{
  "phase": "execution",
  "taskIndex": "<resolved dispatch index>",
  "totalTasks": "<count>",
  "taskIteration": 1,
  "maxTaskIterations": "<parsed from --max-task-iterations or default 5>",
  "recoveryMode": "<true if --recovery-mode flag present, false otherwise>",
  "maxFixTasksPerOriginal": 3,
  "maxFixTaskDepth": 3,
  "globalIteration": 1,
  "maxGlobalIterations": "<parsed from --max-global-iterations or default 100>",
  "fixTaskMap": {},
  "modificationMap": {},
  "maxModificationsPerTask": 3,
  "maxModificationDepth": 2,
  "awaitingApproval": false,
  "nativeTaskMap": {},
  "nativeSyncEnabled": true,
  "nativeSyncFailureCount": 0
}
```

Use the locked helper to merge every execution field while preserving existing and unknown fields:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
  --state "$SPEC_PATH/.ralph-state.json" \
  --set "phase=execution" \
  --set "taskIndex=$TASK_INDEX_TO_MERGE" \
  --set "totalTasks=$TOTAL" \
  --set "taskIteration=1" \
  --set "maxTaskIterations=$MAX_TASK_ITERATIONS" \
  --set "recoveryMode=$RECOVERY_MODE" \
  --set "maxFixTasksPerOriginal=3" \
  --set "maxFixTaskDepth=3" \
  --set "globalIteration=1" \
  --set "maxGlobalIterations=$MAX_GLOBAL_ITERATIONS" \
  --json 'fixTaskMap={}' \
  --json 'modificationMap={}' \
  --set "maxModificationsPerTask=3" \
  --set "maxModificationDepth=2" \
  --set "awaitingApproval=false" \
  --json 'nativeTaskMap={}' \
  --set "nativeSyncEnabled=true" \
  --set "nativeSyncFailureCount=0"
```

**Preserved fields** (set by earlier phases, must NOT be removed):
- `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`

**Backwards Compatibility**: State files from earlier versions may lack new fields. The system handles missing fields gracefully with defaults (globalIteration: 1, maxGlobalIterations: 100, maxFixTaskDepth: 3, modificationMap: {}, maxModificationsPerTask: 3, maxModificationDepth: 2, nativeTaskMap: {}, nativeSyncEnabled: true, nativeSyncFailureCount: 0).

## Step 4: Execute Task Loop

After writing the state file, output the coordinator prompt below. This starts the execution loop.
The stop-hook will continue the loop by blocking stops and prompting the coordinator to check state.

### Coordinator Prompt

Output this prompt directly to start execution:

```text
You are the execution COORDINATOR for spec: $spec
```

Then Read and follow these references in order. They contain the complete coordinator logic:

1. **Core delegation pattern**: Read `${CLAUDE_PLUGIN_ROOT}/references/coordinator-pattern.md` and follow it.
   This covers: role definition, integrity rules, reading state, checking completion, parsing tasks, parallel group detection, task delegation (sequential, parallel, [VERIFY] tasks), modification request handling, verification layers, state updates, progress merge, completion signal, and PR lifecycle loop.

2. **Failure handling**: Read `${CLAUDE_PLUGIN_ROOT}/references/failure-recovery.md` and follow it.
   This covers: parsing failure output, fix task generation, fix task limits and depth checks, iterative recovery orchestrator, fix task insertion into tasks.md, fixTaskMap state tracking, and progress logging for fix chains.

3. **Verification after each task**: Read `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md` and follow it.
   This covers: 3 layers (contradiction detection, TASK_COMPLETE signal, periodic artifact review via spec-reviewer). All must pass before advancing.

4. **Phase-specific behavior**: Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` and follow it.
   This covers: POC-first workflow (Phase 1-4), phase distribution, quality checkpoints, and phase-specific constraints.

5. **Commit conventions**: Read `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` and follow it.
   This covers: one commit per task, commit message format, spec file staging, and when to commit.

### Key Coordinator Behaviors (quick reference — see coordinator-pattern.md for authoritative details)

- **You are a COORDINATOR, not an implementer.** Delegate via Task tool. Never implement yourself.
- **Fully autonomous.** Never ask questions or wait for user input.
- **State-driven loop.** Read .ralph-state.json each iteration to determine current task.
- **Completion check.** If taskIndex >= totalTasks, verify all [x] marks. If `activePrototypes` is nonempty, keep the state file and finish or cancel those entries before completion. Delete state only after the active map is empty, then output ALL_TASKS_COMPLETE.
- **Task delegation.** Extract full task block from tasks.md, delegate to spec-executor (or qa-engineer for [VERIFY] tasks).
- **After TASK_COMPLETE.** Run all 3 verification layers, then update state (advance taskIndex, reset taskIteration).
- **On failure.** Parse failure output, increment taskIteration. If recovery-mode: generate fix task. If max retries exceeded: error and stop.
- **Modification requests.** If TASK_MODIFICATION_REQUEST in output, process SPLIT_TASK / ADD_PREREQUISITE / ADD_FOLLOWUP per coordinator-pattern.md.
- **Remote lifecycle.** Apply the Prototype Evidence Push Gate before a push-dependent PR, CI, review, or issue path. When the gate skips or denies the push, end the dependent remote lifecycle path: do not run `gh pr create`, `gh pr merge`, `gh pr checks`, `gh pr view`, `gh api`, `gh run`, `gh issue`, remote review polling, issue writes, or later remote steps that depend on that push. Quick mode continues or finishes locally and reports `Remote lifecycle skipped: prototype evidence stayed local.` Preserve the normal remote lifecycle only after the gate completes the push.

### Error States (never output ALL_TASKS_COMPLETE)

- Missing/corrupt state file: error and suggest re-running /ralph-specum:implement
- Missing tasks.md: error and suggest running /ralph-specum:tasks
- Missing spec directory: error and suggest running /ralph-specum:new
- Max retries exceeded: error with failure details, suggest manual fix then resume
- Max fix task depth/count exceeded (recovery mode): error with fix history

## Step 5: Completion

When all tasks complete (taskIndex >= totalTasks):
1. Verify all tasks marked [x] in tasks.md
2. Reconcile prototype records. If `activePrototypes` is nonempty, keep `.ralph-state.json`, report the remaining IDs, and stop before `ALL_TASKS_COMPLETE`.
3. Re-read state with `locked-state.py list --state "$SPEC_PATH/.ralph-state.json"`. Only when `activePrototypes` is empty, delete state through `locked-state.py delete-state --state "$SPEC_PATH/.ralph-state.json"`.
4. Keep .progress.md (preserve learnings and history)
5. Cleanup orphaned temp progress files: `find "$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true`
6. Update spec index: `./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet`
7. Commit remaining spec changes:
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): final progress update for $spec"
   ```
8. Check for a PR link with `gh pr view --json url -q .url 2>/dev/null` only when the Prototype Evidence Push Gate completed the branch push. If the gate skipped or denied the push, skip this dependent remote lookup.
9. Output: ALL_TASKS_COMPLETE (and PR link if exists)

## Output on Start

```text
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
