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

## Step 2: Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)
- **--max-global-iterations**: Max total loop iterations (default: 100). Safety limit to prevent infinite execution loops.
- **--recovery-mode**: Enable iterative failure recovery (default: false). When enabled, failed tasks trigger automatic fix task generation instead of stopping.

## Step 3: Initialize Execution State

Count tasks using these exact commands:

```bash
TOTAL=$(grep -c -e '- \[.\]' "$SPEC_PATH/tasks.md" 2>/dev/null || echo 0)
COMPLETED=$(grep -c -e '- \[x\]' "$SPEC_PATH/tasks.md" 2>/dev/null || echo 0)
FIRST_INCOMPLETE=$((COMPLETED))
```

Key: Use `-e` flag so grep doesn't interpret the pattern's leading hyphen as an option.

**CRITICAL: Merge into existing state -- do NOT overwrite the file.**

Read the existing `.ralph-state.json` first, then **merge** the execution fields into it.
This preserves fields set by earlier phases (e.g., `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`).

Update `.ralph-state.json` by merging these fields into the existing object:
```json
{
  "phase": "execution",
  "taskIndex": "<first incomplete>",
  "totalTasks": "<count>",
  "taskIteration": 1,
  "repairIteration": 0,
  "failedStory": null,
  "originTaskIndex": null,
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

Use a jq merge pattern to preserve existing fields:
```bash
jq --argjson taskIndex <first_incomplete> \
   --argjson totalTasks <count> \
   --argjson maxTaskIter <parsed or 5> \
   --argjson recoveryMode <true|false> \
   --argjson maxGlobalIter <parsed or 100> \
   '
   . + {
     phase: "execution",
     taskIndex: $taskIndex,
     totalTasks: $totalTasks,
     taskIteration: 1,
     repairIteration: 0,
     failedStory: null,
     originTaskIndex: null,
     maxTaskIterations: $maxTaskIter,
     recoveryMode: $recoveryMode,
     maxFixTasksPerOriginal: 3,
     maxFixTaskDepth: 3,
     globalIteration: 1,
     maxGlobalIterations: $maxGlobalIter,
     fixTaskMap: {},
     modificationMap: {},
     maxModificationsPerTask: 3,
     maxModificationDepth: 2,
     awaitingApproval: false,
     nativeTaskMap: {},
     nativeSyncEnabled: true,
     nativeSyncFailureCount: 0
   }
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

**Preserved fields** (set by earlier phases, must NOT be removed):
- `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`

**Backwards Compatibility**: State files from earlier versions may lack new fields. The system handles missing fields gracefully with defaults (globalIteration: 1, maxGlobalIterations: 100, maxFixTaskDepth: 3, modificationMap: {}, maxModificationsPerTask: 3, maxModificationDepth: 2, nativeTaskMap: {}, nativeSyncEnabled: true, nativeSyncFailureCount: 0).

## Step 4: Execute Task Loop

### State Integrity Check (before loop starts)

Before delegating any task, verify state consistency:

```bash
COMPLETED=$(grep -c -e '- \[x\]' "$SPEC_PATH/tasks.md" 2>/dev/null || echo 0)
CURRENT_INDEX=$(jq '.taskIndex' "$SPEC_PATH/.ralph-state.json")
TOTAL=$(jq '.totalTasks' "$SPEC_PATH/.ralph-state.json")
```

**Drift Detection Logic:**

1. **If `CURRENT_INDEX < COMPLETED`**: state drift detected (state lags behind tasks.md)
   - Log: `"STATE DRIFT: taskIndex was $CURRENT_INDEX, corrected to $COMPLETED"`
   - Update: `jq --argjson idx "$COMPLETED" '.taskIndex = $idx' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"`

2. **If `CURRENT_INDEX > COMPLETED` and `CURRENT_INDEX < TOTAL`**: state ahead of tasks.md (possible unmarking)
   - Log: `"STATE WARNING: taskIndex $CURRENT_INDEX exceeds completed count $COMPLETED — tasks may have been unmarked intentionally"`
   - No correction: allow execution to continue with current state

3. **If `CURRENT_INDEX == COMPLETED`**: normal state, no action needed

---

### Parallel Reviewer Onboarding

Before starting execution, check if the user wants to run an external parallel reviewer:

**Ask the user:**
```
Will you run an external parallel reviewer during this implementation? [y/n]

If yes:
- A file specs/<specName>/task_review.md will be created from the FR-B1 template
- You will receive instructions to launch the reviewer in a second Claude Code session
- The spec-executor will automatically read task_review.md before each task
```

**If user answers YES:**
1. Copy `plugins/ralph-specum/templates/task_review.md` → `specs/<specName>/task_review.md`
2. Copy `plugins/ralph-specum/templates/chat.md` → `specs/<specName>/chat.md`
3. Ask which quality principles to activate:
   ```
   Which quality principles should the reviewer enforce?

   Principles detected in the codebase: <list detected conventions>
   Recommended standard principles:
   - SOLID (Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion)
   - DRY (Don't Repeat Yourself)
   - FAIL FAST (validate early in functions)
   - TDD (Red-Green-Refactor)

   Which do you want to enable? ("all", a comma-separated list, or "none")
   ```
3. Write selected principles to `specs/<specName>/task_review.md` frontmatter:
   ```yaml
   <!-- reviewer-config
   principles: [SOLID, DRY, FAIL_FAST, TDD]
   codebase-conventions: <detected automatically>
   -->
   ```
4. Print onboarding instructions:
   ```
   External reviewer configured.

   To launch the reviewer in parallel:
   1. Open a second Claude Code session in the same repository
   2. Load the agent: @external-reviewer
   3. Tell it: "Review spec <specName> while spec-executor implements"
   4. The reviewer will read and write to specs/<specName>/task_review.md and chat.md (FLOC-based coordination in real time)

   The spec-executor is already configured to read task_review.md before each task.
   The reviewer will also read and write chat.md (FLOC coordination in real time).
   When the reviewer marks an item as FAIL, the spec-executor will stop and apply the fix.
   ```

**If user answers NO:** continue normal flow without creating task_review.md.

---

After writing the state file (and optionally setting up external reviewer), output the coordinator prompt below. This starts the execution loop.
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
   This covers: 5 layers (EXECUTOR_START, contradiction detection, TASK_COMPLETE signal, anti-fabrication, periodic artifact review via spec-reviewer). All must pass before advancing.

4. **Phase-specific behavior**: Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` and follow it.
   This covers: POC-first workflow (Phase 1-4), phase distribution, quality checkpoints, and phase-specific constraints.

5. **Commit conventions**: Read `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` and follow it.
   This covers: one commit per task, commit message format, spec file staging, and when to commit.

### Key Coordinator Behaviors (quick reference — see coordinator-pattern.md for authoritative details)

- **You are a COORDINATOR, not an implementer.** Delegate via Task tool. Never implement yourself.
- **Fully autonomous.** Never ask questions or wait for user input.
- **State-driven loop.** Read .ralph-state.json each iteration to determine current task.
- **MANDATORY: Read task_review.md BEFORE delegating.** Before every task delegation, read `<basePath>/task_review.md` if it exists. If the current task is marked FAIL, DO NOT delegate—add a fix task first. If marked PENDING, treat it as a blocking state: do not delegate or advance to another task until the review is resolved.
- **MANDATORY: Mechanical HOLD check BEFORE delegation.** Before delegating, run:
  ```bash
  grep -c '^\[HOLD\]$\|^\[PENDING\]$\|^\[URGENT\]$' "$SPEC_PATH/chat.md" 2>/dev/null
  ```
  If count > 0 (active signals found): block delegation immediately. Log to `.progress.md`: `"COORDINATOR BLOCKED: active HOLD/PENDING/URGENT signal in chat.md for task $taskIndex"`.
  
  When signals are resolved (by external-reviewer or coordinator), the signal line is changed to `[RESOLVED]` (e.g., `[HOLD]` → `[RESOLVED]`). This marker is not matched by the grep check.

- **MANDATORY: Read chat.md BEFORE delegating.** Before every task delegation, read `<basePath>/chat.md` for signals from external-reviewer. Obey HOLD, PENDING, DEADLOCK signals immediately—do not delegate if blocked.
- **CRITICAL: Verify independently, never trust executor.** The executor may FABRICATE verification results (claimed tests passed when they failed, claimed coverage when coverage was 0%). 
  - **Rule**: NEVER trust pasted verification output from spec-executor. ALWAYS run the verify command independently.
  - Extract verify command from tasks.md → run it yourself → compare actual result with claimed result.
  - If executor claimed "PASSED" but command exits non-zero → REJECT, increment taskIteration, log "FABRICATION detected".
  - This is non-negotiable: executor has fabricated results multiple times in past.
- **CI snapshot separation.** Task Verify commands (task-scoped) and global CI commands (project-wide linting, type-checking) must be reported separately. Both must pass. If task Verify passes but global CI fails: log `"TASK VERIFY PASS but GLOBAL CI FAIL"` to `.progress.md`, do NOT advance taskIndex. **Note**: Specific CI command discovery is deferred to Spec 4. The coordinator should check for available project CI commands if they exist.
- **Completion check.** If taskIndex >= totalTasks, verify all [x] marks, delete state file, output ALL_TASKS_COMPLETE.
- **Task delegation.** Extract full task block from tasks.md, delegate to spec-executor (or qa-engineer for [VERIFY] tasks).
  - **MANDATORY: Validate VE task Skills: field before delegating to qa-engineer.** If the task has a `[VERIFY]` tag AND contains "VE", "E2E", "browser", or "playwright" in its description:
    - Check that the task body contains a `**Skills**:` or `**Skills:**` field with at least `e2e` or `playwright-env`.
    - If `Skills:` is missing or empty: DO NOT delegate. DO NOT advance to the next task. DO NOT mark complete.
      Log: `"VE task T<taskIndex> missing Skills: field. Cannot delegate to qa-engineer without skill metadata."`
      Generate a fix task to populate the Skills: field, then re-run this task. If unable to generate the fix task, halt with error.
    - **Why**: qa-engineer loads skills from the `Skills:` field. Without it, the agent runs with no E2E context and will produce incorrect verifications.
- **After TASK_COMPLETE.** Run all 5 verification layers, then update state (advance taskIndex, reset taskIteration).
- **On failure.** Parse failure output, increment taskIteration. If recovery-mode: generate fix task. If max retries exceeded: error and stop.
- **Modification requests.** If TASK_MODIFICATION_REQUEST in output, process SPLIT_TASK / ADD_PREREQUISITE / ADD_FOLLOWUP per coordinator-pattern.md.

### Error States (never output ALL_TASKS_COMPLETE)

- Missing/corrupt state file: error and suggest re-running /ralph-specum:implement
- Missing tasks.md: error and suggest running /ralph-specum:tasks
- Missing spec directory: error and suggest running /ralph-specum:new
- Max retries exceeded: error with failure details, suggest manual fix then resume
- Max fix task depth/count exceeded (recovery mode): error with fix history

## Step 5: Completion

When all tasks complete (taskIndex >= totalTasks):
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json
3. Keep .progress.md (preserve learnings and history)
4. Cleanup orphaned temp progress files: `find "$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true`
5. Update spec index: `./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet`
6. Commit remaining spec changes:
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): final progress update for $spec"
   ```
7. Check for PR link: `gh pr view --json url -q .url 2>/dev/null`
8. Output: ALL_TASKS_COMPLETE (and PR link if exists)

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
