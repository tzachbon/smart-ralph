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

### Parallel Reviewer Onboarding

Before starting execution, check if the user wants to run an external parallel reviewer:

**Ask the user:**
```
¿Vas a ejecutar un revisor externo paralelo durante esta implementación? [s/n]

Si dices sí:
- Se creará specs/<specName>/task_review.md (desde el template de FR-B1)
- Recibirás instrucciones para lanzar el revisor en una segunda sesión de Claude Code
- El spec-executor leerá automáticamente task_review.md en cada tarea
```

**If user answers YES:**
1. Copy `plugins/ralph-specum/templates/task_review.md` → `specs/<specName>/task_review.md`
2. Ask which quality principles to activate:
   ```
   ¿Qué principios de calidad quieres que el revisor enforece?

   Principios detectados en el codebase: <listar convenciones encontradas en el repo>
   Principios recomendados estándar:
   - SOLID (Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion)
   - DRY (Don't Repeat Yourself)
   - FAIL FAST (validaciones al inicio de funciones)
   - TDD (Red-Green-Refactor)

   ¿Cuáles quieres activar? ("todos", lista, o "ninguno adicional")
   ```
3. Write selected principles to `specs/<specName>/task_review.md` frontmatter:
   ```yaml
   <!-- reviewer-config
   principles: [SOLID, DRY, FAIL_FAST, TDD]
   codebase-conventions: <detectadas automáticamente>
   -->
   ```
4. Print onboarding instructions:
   ```
   Revisor externo configurado.

   Para lanzar el revisor en paralelo:
   1. Abre una segunda sesión de Claude Code en el mismo repositorio
   2. Carga el agente: @external-reviewer
   3. Dile: "Revisa la spec <specName> mientras spec-executor implementa"
   4. El revisor leerá y escribirá en specs/<specName>/task_review.md

   El spec-executor ya está configurado para leer task_review.md antes de cada tarea.
   Cuando el revisor marque algo como FAIL, spec-executor se detendrá y aplicará el fix.
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
   This covers: 3 layers (contradiction detection, TASK_COMPLETE signal, periodic artifact review via spec-reviewer). All must pass before advancing.

4. **Phase-specific behavior**: Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` and follow it.
   This covers: POC-first workflow (Phase 1-4), phase distribution, quality checkpoints, and phase-specific constraints.

5. **Commit conventions**: Read `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` and follow it.
   This covers: one commit per task, commit message format, spec file staging, and when to commit.

### Key Coordinator Behaviors (quick reference — see coordinator-pattern.md for authoritative details)

- **You are a COORDINATOR, not an implementer.** Delegate via Task tool. Never implement yourself.
- **Fully autonomous.** Never ask questions or wait for user input.
- **State-driven loop.** Read .ralph-state.json each iteration to determine current task.
- **Completion check.** If taskIndex >= totalTasks, verify all [x] marks, delete state file, output ALL_TASKS_COMPLETE.
- **Task delegation.** Extract full task block from tasks.md, delegate to spec-executor (or qa-engineer for [VERIFY] tasks).
- **After TASK_COMPLETE.** Run all 3 verification layers, then update state (advance taskIndex, reset taskIteration).
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
