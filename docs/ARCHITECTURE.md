# Ralph Specum — Complete Architecture Map

## 1. File Structure

```
plugins/ralph-specum/
├── .claude-plugin/plugin.json # Plugin manifest v4.9.3
├── agents/ # 9 subagent definitions (markdown)
│   ├── spec-executor.md # Task executor (autonomous implementation)
│   ├── task-planner.md # POC-first task breakdown generator
│   ├── qa-engineer.md # Verification agent (Playwright)
│   ├── research-analyst.md # Web search + codebase analysis
│   ├── product-manager.md # User stories + acceptance criteria
│   ├── architect-reviewer.md # Technical design document
│   ├── spec-reviewer.md # Artifact reviewer (rubric-based)
│   ├── triage-analyst.md # Feature decomposition for epics
│   └── refactor-specialist.md # Spec file refactorer
├── commands/ # 15 slash commands
│   ├── start.md # Smart orchestrator (auto-detects what to do)
│   ├── new.md # Create spec + optionally run research
│   ├── research.md # Run research-analyst on current spec
│   ├── requirements.md # Run product-manager on current spec
│   ├── design.md # Run architect-reviewer on current spec
│   ├── tasks.md # Run task-planner on current spec
│   ├── implement.md # Start execution loop (loop coordinator)
│   ├── verify.md # Run qa-engineer verification
│   ├── cancel.md # Cancel loop + cleanup
│   ├── triage.md # Epic decomposition
│   ├── epic.md # Resume epic tracking
│   ├── quick.md # Auto-generate all phases without stopping
│   ├── refactor.md # Refactor spec files
│   ├── review.md # Review spec artifacts
│   └── switch.md # Switch active spec
├── hooks/
│   ├── hooks.json # 3 hooks: Stop, SessionStart, PreToolUse
│   └── scripts/
│       ├── stop-watcher.sh # Loop controller (500+ lines)
│       ├── path-resolver.sh # Multi-directory spec discovery
│       ├── update-spec-index.sh # Spec index maintenance
│       ├── checkpoint.sh # Pre-loop git checkpoint (loop-safety-infra)
│       ├── write-metric.sh # Per-task metrics append (loop-safety-infra)
│       └── discover-ci.sh # CI command discovery (loop-safety-infra)
├── references/ # 20 internal reference documents
│   ├── coordinator-pattern.md # Coordinator logic bible
│   ├── failure-recovery.md # Recovery + repair loops
│   ├── verification-layers.md # 3-layer verification system
│   ├── quality-checkpoints.md # VE tasks + verify-fix-reverify loop
│   ├── triage-flow.md # Epic triage workflow
│   ├── branch-management.md # Git branch strategy
│   ├── design-rubric.md # Design document review rubric
│   ├── task-rubric.md # Tasks review rubric
│   ├── verification-rubric.md # Verification review rubric
│   ├── requirements-rubric.md # Requirements review rubric
│   ├── research-rubric.md # Research review rubric
│   ├── epic-rubric.md # Epic review rubric
│   ├── epic-coordinator.md # Epic workflow reference
│   ├── epic-decomposition.md # Triage decomposition patterns
│   ├── coordinator-signals.md # Signal catalog (15+ signals)
│   ├── e2e-chain.md # E2E Playwright skill chain
│   ├── context-auditor.md # Memory/context auditor
│   ├── role-contracts.md # File access matrix per agent (role-boundaries spec)
│   ├── loop-safety.md # Circuit breaker, checkpoint, metrics (loop-safety-infra spec)
│   └── collaboration-resolution.md # Agent collaboration protocol (pending spec)
├── templates/ # Spec file templates
│   ├── research.md
│   ├── requirements.md
│   ├── design.md
│   ├── tasks.md
│   └── epic.md
└── schemas/ # JSON schemas
    └── ralph-state.json

plugins/ralph-bmad-bridge/           # BMAD structural mapper plugin
├── .claude-plugin/plugin.json       # Plugin manifest v0.1.0
├── commands/
│   └── ralph-bmad-import.md         # /ralph-bmad:import <path> <spec-name>
├── scripts/
│   └── import.sh                    # Main mapper (985 lines, bash+jq)
└── tests/
    └── test-import.sh               # Test harness (13 tests: unit+integration+E2E)
```

## 2. Complete Execution Order

### 2.1 Entry: `/ralph-specum:start`

`commands/start.md` — Smart orchestrator that auto-detects current phase and runs the right command.

**Detection Logic:**
```
IF .current-epic exists → run epic coordinator
ELIF .current-spec exists → detect phase from .ralph-state.json
  → phase=research    → run research.md
  → phase=requirements → run requirements.md
  → phase=design      → run design.md
  → phase=tasks       → run tasks.md
  → phase=implement   → run implement.md (restart loop)
ELSE → run new.md (create new spec)
```

### 2.2 Phase 1: Research (`commands/research.md`)

```
User or start.md
    → Task tool: research-analyst subagent
        • Web search: best practices, prior art
        • Codebase Explore: existing patterns
        • Feasibility assessment
        → Output: $basePath/research.md
    → .ralph-state.json updated: phase="requirements"
    → STOP (awaiting user approval)
```

### 2.3 Phase 2: Requirements (`commands/requirements.md`)

```
User runs /ralph-specum:requirements
    → Task tool: product-manager subagent
        • Generate user stories (ASRB format: As a/So that/Requirements)
        • Populate Verification Contract per story
        • Append learnings to .progress.md
        → Output: $basePath/requirements.md
    → .ralph-state.json updated: phase="design", awaitingApproval=true
    → STOP (awaiting user approval)
```

### 2.4 Phase 3: Design (`commands/design.md`)

```
User runs /ralph-specum:design
    → Task tool: architect-reviewer subagent
        • Generate design.md with Test Strategy (MANDATORY section)
        • Design components, data models, API contracts
        • Output: $basePath/design.md
    → .ralph-state.json updated: phase="tasks", awaitingApproval=true
    → STOP (awaiting user approval)
```

### 2.5 Phase 4: Tasks (`commands/tasks.md`)

```
User runs /ralph-specum:tasks
    → Task tool: task-planner subagent
        • POC-first task breakdown (Phase 1: Make It Work)
        • Phase 2: Refactoring
        • Phase 3: Testing (VE + E2E tasks)
        • Phase 4: Quality Gates
        • Quality checkpoints every 2-3 tasks
        → Output: $basePath/tasks.md
    → .ralph-state.json updated: phase="implement", taskIndex=0
    → STOP (awaiting user approval)
```

### 2.6 Phase 5: Implementation Loop (`commands/implement.md`)

```
User runs /ralph-specum:implement
    → STOP HOOK activates (hooks.json: Stop)
    → stop-watcher.sh reads .ralph-state.json
    → LOOP begins:
        Coordinator (implement.md) sends task to spec-executor via Task tool
            spec-executor:
                1. Reads task from tasks.md
                2. Executes code changes
                3. For VE tasks: qa-engineer runs Playwright
                4. Outputs: TASK_COMPLETE / TASK_MODIFICATION_REQUEST / ESCALATE
            stop-watcher.sh:
                - Reads transcript for signals (EXECUTOR_START, TASK_COMPLETE, SPEC_COMPLETE, etc.)
                - Detects ESCALATE → runs failure-recovery.md logic
                - Detects SPEC_COMPLETE → outputs "ALL_TASKS_COMPLETE" → ends loop
                - Else → outputs continuation prompt → loop continues
        Coordinator receives signal:
            TASK_COMPLETE → taskIndex++ → next task
            TASK_MODIFICATION_REQUEST → regenerate task → taskIteration++
            ESCALATE → recovery flow → repairIteration++
            ALL_TASKS_COMPLETE → .ralph-state.json deleted → loop ends
```

**Loop repeats until ALL_TASKS_COMPLETE signal detected.**

## 3. Agent Details

### 3.1 spec-executor (`agents/spec-executor.md`)

Autonomous task implementation. Receives a single task from tasks.md and executes it.

**Inputs:**
- Current task from tasks.md
- Full spec context (research.md, requirements.md, design.md)
- .progress.md learnings

**Outputs (signals in transcript):**
- `EXECUTOR_START` — Task started
- `TASK_COMPLETE` — Task succeeded
- `TASK_MODIFICATION_REQUEST` — Needs different approach
- `ESCALATE` — Unrecoverable, needs coordinator
- `SPEC_COMPLETE` — All tasks done

**Rules:**
- Max 5 task iterations before ESCALATE
- Must commit after every task (commit message discipline)
- VE task failures: spec-executor itself calls qa-engineer for re-verification
- No retries for same failing approach

### 3.2 qa-engineer (`agents/qa-engineer.md`)

Verification agent. Runs Playwright E2E tests for VE (Verification Executive) tasks.

**Verification Contract Gates:**
- `fullstack` → loads full Playwright E2E chain
- `frontend` → loads Playwright with SPA verification
- `api-only` → API verification (no browser)
- `cli` → CLI verification
- `library` → unit/integration tests

**Signals:**
- `VERIFICATION_PASS` — Test passed
- `VERIFICATION_FAIL` — Test failed (implementation issue)
- `VERIFICATION_DEGRADED` — Test quality compromised (flaky, env issue)

### 3.3 task-planner (`agents/task-planner.md`)

POC-first task breakdown generator.

**Workflow (POC-first, mandatory):**
1. **Phase 1: Make It Work** — POC, NO tests
2. **Phase 2: Refactoring** — Code cleanup
3. **Phase 3: Testing** — Unit, integration, E2E
4. **Phase 4: Quality Gates** — Lint, types, CI, PR

**Quality Checkpoints:**
- VE tasks inserted every 2-3 implementation tasks
- VE = Verification Executive (Playwright E2E)
- verify-fix-reverify loop: VE fail → fix → VE again → pass

**Task Format:**
```
### T-n: [Task name]
[What to do]
[Completion criteria]
[Files to modify]
```

### 3.4 research-analyst (`agents/research-analyst.md`)

Web search + codebase exploration agent.

**Tools used:**
- WebSearch for best practices and prior art
- Explore subagent for codebase patterns

**Output:** research.md with findings and recommendations

### 3.5 product-manager (`agents/product-manager.md`)

User stories and acceptance criteria generator.

**User Story Format (ASRB — NOT Given/When/Then):**
```markdown
### US-1: [Story Title]
**As a** [user type]
**I want to** [action/capability]
**So that** [benefit/value]

**Acceptance Criteria:**
- [ ] AC-1.1: [Specific, testable criterion]
- [ ] AC-1.2: [Specific, testable criterion]
```

**Verification Contract (gates Playwright usage):**
- Project type (fullstack/frontend/api-only/cli/library)
- Entry points (specific routes/endpoints)
- Observable signals (PASS/FAIL looks like)
- Hard invariants (must never break)
- Seed data requirements
- Dependency map (shared state with other specs)

### 3.6 architect-reviewer (`agents/architect-reviewer.md`)

Technical design document generator.

**Mandatory Sections:**
- **Test Strategy** — Mandatory. Uses Test Double Taxonomy:
  - Dummy, Fake, Stub, Spy, Mock
  - Real Object, Test Adapter
  - Where each applies in the architecture
- Components, data models, API contracts
- Trade-offs and assumptions

### 3.7 spec-reviewer (`agents/spec-reviewer.md`)

Artifact reviewer using rubric-based validation.

**Rubrics (each is a reference doc):**
- research-rubric.md
- requirements-rubric.md
- design-rubric.md
- task-rubric.md
- verification-rubric.md
- epic-rubric.md

**Output:** `REVIEW_PASS` or `REVIEW_FAIL`

### 3.8 triage-analyst (`agents/triage-analyst.md`)

Feature decomposition for epic creation.

**Output:** epic.md with:
- Vision
- Specs list with sizes (XS/S/M/L/XL)
- Dependency graph
- Interface contracts between specs

### 3.9 refactor-specialist (`agents/refactor-specialist.md`)

Spec file refactorer. Incrementally updates spec files after spec changes.

## 4. Hooks Details

### 4.1 Stop Hook (stop-watcher.sh)

**500+ line loop controller.** Activated when spec-executor or coordinator outputs a signal.

**Core Logic:**
1. Read `.ralph-state.json`
2. Scan transcript for signals
3. Determine next action based on state + signal
4. Output continuation prompt or ALL_TASKS_COMPLETE

**Signal Detection (from transcript text):**
- `EXECUTOR_START` — spec-executor began
- `TASK_COMPLETE` — task succeeded
- `TASK_MODIFICATION_REQUEST` — needs different approach
- `ESCALATE` — unrecoverable
- `SPEC_COMPLETE` — all done
- `VERIFICATION_*` — QA result
- `REPAIR_*` — recovery state

**Recovery Flow:**
- impl_bug → create fix task → spec-executor
- env_issue → env fix → retry same task
- spec_ambiguity → ESCALATE → human
- flaky → retry VE

### 4.2 SessionStart Hook (load-spec-context)

Loads active spec context on session start.

**Logic:**
1. Check for .current-spec
2. Read .ralph-state.json
3. Summarize spec state for user

### 4.3 PreToolUse Hook (quick-mode-guard)

Blocks commands unless `--quick` flag provided when `awaitingApproval=true`.

## 5. Skills Framework

### 5.1 E2E Chain (`references/e2e-chain.md`)

Full Playwright E2E verification skill chain:

```
e2e
├── e2e-core           # Browser automation fundamentals
├── e2e-navigation     # Page navigation, routing
├── e2e-waiting        # Async waiting, assertions
├── e2e-assertions     # Complex assertions
├── e2e-mobile         # Responsive testing
├── e2e-performance   # Metrics collection
└── e2e-accessibility # A11y verification
```

**Loaded gated by Verification Contract project type:**
- `fullstack` → full chain
- `frontend` → SPA verification
- `api-only` → API verification (no browser)
- `cli` → CLI verification
- `library` → unit/integration

### 5.2 Context Auditor (`references/context-auditor.md`)

Memory/context auditor for long sessions. Detects context bloat and suggests consolidation.

### 5.3 Role Contracts (`references/role-contracts.md`)

File access matrix defining which agent can read/write which files. Enforced by agent prompts and state integrity hook.

| Agent | Can Write | Cannot Write |
|-------|-----------|--------------|
| spec-executor | Source code, tests, .progress.md | .ralph-state.json, task_review.md, chat.md |
| external-reviewer | task_review.md, chat.md, .progress.md (intervention) | Source code, .ralph-state.json |
| qa-engineer | test-results/ | .ralph-state.json, tasks.md, task_review.md |
| coordinator | .ralph-state.json, tasks.md | Source code, task_review.md |

### 5.4 Loop Safety (`references/loop-safety.md`)

Circuit breaker, pre-loop git checkpoint, per-task metrics, and read-only detection for the execution loop.

- **Checkpoint**: `checkpoint.sh` creates git commit before execution starts
- **Circuit breaker**: Stop after N consecutive failures or M hours elapsed
- **Metrics**: `write-metric.sh` appends per-task timing and iteration count
- **Read-only detection**: Heartbeat write check to detect stuck agents
- **CI discovery**: `discover-ci.sh` auto-detects project CI commands

## 5.5 BMAD Bridge Plugin (`plugins/ralph-bmad-bridge/`)

Structural mapper that converts BMAD planning artifacts into smart-ralph spec files using deterministic bash+jq parsing (no LLM).

**Command**: `/ralph-bmad:import <bmad-project-path> <spec-name>`

**Mapping**:
| BMAD Artifact | smart-ralph Output | Parser |
|---------------|-------------------|--------|
| `prd.md` (FRs) | `requirements.md` (FR table + User Stories) | `parse_prd_frs()` |
| `prd.md` (NFRs) | `requirements.md` (NFR table with ### subsections) | `parse_prd_nfrs()` |
| `epics.md` | `tasks.md` (Phase 1 tasks with BDD criteria) | `parse_epics()` |
| `architecture.md` | `design.md` (Technical Decisions + File Structure) | `parse_architecture()` |
| — | `.ralph-state.json` (with correct totalTasks) | `write_state()` |

**Input validation**: Path traversal protection, spec name regex (`^[a-z](-?[a-z0-9]+)*$`), BMAD root must be within project root.

**Test harness**: 13 tests (unit + integration + E2E) in `tests/test-import.sh`.

## 6. State Files

### 6.1 `.ralph-state.json`

```json
{
  "source": "spec",
  "name": "spec-name",
  "basePath": "./specs/spec-name",
  "phase": "implement",
  "taskIndex": 3,
  "totalTasks": 17,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "repairIteration": 0,
  "maxRepairIterations": 2,
  "recoveryMode": false,
  "awaitingApproval": false
}
```

**Phase values:** research → requirements → design → tasks → implement

**Key fields:**
- `taskIndex` — current task (0-indexed)
- `taskIteration` — retries for current task (max 5)
- `repairIteration` — repair loop count (max 2)
- `recoveryMode` — signals recovery flow
- `awaitingApproval` — blocks non-quick commands

### 6.2 `.progress.md`

```
---
spec: spec-name
basePath: ./specs/spec-name
phase: implement
task: 3/17
updated: 2026-04-04
---

## Original Goal
[What we're building]

## Completed Tasks
- [x] T-1: Task name
- [x] T-2: Task name

## Current Task
T-3: Task name

## Learnings
- Discovery from implementation

## Blockers
- None currently

## Next
Continue with T-4
```

### 6.3 Spec Index (`specs/.spec-index.json`)

Auto-generated index of all specs across all roots.

Updated by `update-spec-index.sh` after new spec creation or cancellation.

## 7. Command Summary Table

| Command | Phase | Stops? | Subagent |
|---------|-------|--------|----------|
| `/ralph-specum:new` | — | Yes | research-analyst (optional) |
| `/ralph-specum:start` | Auto | Auto | Auto-detects |
| `/ralph-specum:research` | 1 | Yes | research-analyst |
| `/ralph-specum:requirements` | 2 | Yes | product-manager |
| `/ralph-specum:design` | 3 | Yes | architect-reviewer |
| `/ralph-specum:tasks` | 4 | Yes | task-planner |
| `/ralph-specum:implement` | 5 | Loop | spec-executor |
| `/ralph-specum:verify` | VE | No | qa-engineer |
| `/ralph-specum:cancel` | — | — | — |
| `/ralph-specum:triage` | Epic | Yes | triage-analyst |
| `/ralph-specum:quick` | All | No | All phases |
| `/ralph-specum:refactor` | Any | Yes | refactor-specialist |
| `/ralph-specum:review` | Any | Yes | spec-reviewer |
| `/ralph-specum:switch` | — | No | path-resolver |
| `/ralph-specum:epic` | Epic | Yes | triage-analyst |

## 8. Recovery Loop Flow

```
TASK_COMPLETE (fail) → stop-watcher detects → classification:
    impl_bug      → create fix task → spec-executor (same taskIteration+1)
    env_issue     → fix env → retry same task
    spec_ambiguity → ESCALATE → human intervention
    flaky         → retry VE (qa-engineer again)

taskIteration >= 5 → ESCALATE → human
repairIteration >= 2 → hard block → human
```

**Note:** `repairIteration` is effectively dead code — when taskIteration exhausts (5), ESCALATE fires before the repair loop runs.

## 9. User Story Flow

```
product-manager generates requirements.md
    → User Stories (ASRB format)
    → Verification Contract per story
        → project type (fullstack/frontend/api-only/cli/library)
        → entry points
        → observable signals (PASS/FAIL)
        → hard invariants
        → seed data
        → dependency map
        → escalate conditions

task-planner reads requirements.md
    → Generates VE tasks for E2E verification
    → VE tasks use Playwright skills (gated by project type)
    → E2E chain: e2e-core → e2e-navigation → e2e-waiting → e2e-assertions → e2e-mobile → e2e-performance → e2e-accessibility

spec-executor executes VE tasks
    → qa-engineer runs Playwright
    → Outputs: VERIFICATION_PASS / VERIFICATION_FAIL / VERIFICATION_DEGRADED
    → spec-executor handles failures (retry or ESCALATE)
```

## 10. Coordination Issues (veredictos tras análisis contra-código)

**Verificado contra:** `stop-watcher.sh`, `spec-executor.md`, `qa-engineer.md`, `coordinator-pattern.md`, `implement.md`

### CRITICAL

1. **ESCALATE sin handler centralizado → PARCIAL CIERTO (menos grave)**
   stop-watcher solo detecta `ALL_TASKS_COMPLETE`, `VERIFICATION_FAIL`, `VERIFICATION_DEGRADED`. No detecta `ESCALATE` directamente — el coordinator lo lee del output de spec-executor. Gap real: skills de Playwright pueden emitir ESCALATE sin `VERIFICATION_FAIL` previo.

2. **repairIteration código muerto → FALSO**
   Son dos capas separadas: spec-executor gestiona `taskIteration` (max 5) internamente en su retry loop; stop-watcher gestiona `repairIteration` (max 2) en Phase 3. No son competidores — son capas secuenciales. ✓

### ALTA

3. **Mock quality failure mal clasificado → CIERTO → FIXED** ✅
   Los 4 categorías (impl_bug/env_issue/spec_ambiguity/flaky) no cubren "test quality insufficient".
   **Fix aplicado:** añadida categoría `test_quality` + handler en `stop-watcher.sh` (líneas 375-384):
   - Si qa-engineer detecta mock quality issues → delegar test-rewrite task, NO implementation fix

### MEDIA

4. **recoveryMode inconsistencia → CIERTO (bajo impacto)**
   `coordinator-pattern.md` no menciona `recoveryMode`. Stop-watcher lo lee del state file y lo inyecta en el prompt. Gap documental, no funcional.

5. **DEGRADED doble detección → CIERTO → FIXED** ✅
   spec-executor emite `ESCALATE (reason: verification-degraded)` al recibir `VERIFICATION_DEGRADED`. stop-watcher también detecta DEGRADED en transcript y emite su propio bloqueo.
   **Fix aplicado:** `stop-watcher.sh` ahora detecta si `ESCALATE (verification-degraded)` ya está en transcript antes de emitir su bloqueo adicional.

6. **TEST STRATEGY gap → CIERTO (parcialmente cerrado)**
   El PR actual añadió bloque `<mandatory>` en `architect-reviewer.md` con checklist. Lo que queda: no hay validación externa de que architect-reviewer completó la tabla antes de que spec-executor la consuma.

7. **TASK_MODIFICATION_REQUEST no resetea taskIteration → CIERTO → FIXED** ✅
   ADD_PREREQUISITE: la tarea original no avanza pero taskIteration se acumula.
   **Fix aplicado:** `coordinator-pattern.md` — añadido reset de `taskIteration` a 1 antes de reintentar la tarea original tras completar el prerrequisito.

### BAJA

8. **repairIteration inaccesible al coordinator → CIERTO (por diseño)**
   El coordinator recibe `globalIteration` en el prompt, no `repairIteration`. Solo stop-watcher lo sabe. Limitación real, pero por diseño.

9. **VE mock quality blind spot → CIERTO**
   qa-engineer hace mock quality checks automáticamente, pero en VE tasks spec-executor carga skills y genera tests de forma diferente. No hay mecanismo para que qa-engineer vea los skills cargados.

10. **fixTaskMap sin cleanup → NO VERIFICABLE**
    `failure-recovery.md` no existe en este branch. El archivo de código referenced no existe para verificar esta claim.

11. **SPEC_COMPLETE vs ALL_TASKS_COMPLETE → CIERTO**
    SPEC_COMPLETE = spec-executor (cuando todas las tareas de tasks.md checked). ALL_TASKS_COMPLETE = coordinator (señal de fin de loop). No es bug — son actores distintos — pero la documentación es confusa.

12. **Nombres de señales inconsistentes → MENOR**
    Las señales usan mayúsculas consistentes. ESCALATE sin prefijo es correcto — el coordinator lo consume directamente, no necesita detección por stop-watcher.

13. **Parallel modification undefined taskIteration → CIERTO (edge case raro)**
    stop-watcher maneja grupos [P] pero no documenta qué pasa si una tarea del batch emite TASK_MODIFICATION_REQUEST. ADD_PREREQUISITE rompe el batch (líneas 718-720 de coordinator-pattern.md), pero no hay doc de este comportamiento.

14. **Regression sweep naming confuso → CIERTO (cosmético)**
    Nombres variados en distintos archivos. No causa bugs.

15. **retry vs fix ambiguo → PARCIAL CIERTO**
    ADD_PREREQUISITE no resetea taskIteration —fix hecho en #7—. No hay tagging formal [FIX] en tasks generadas.

---

**Resumen fixes aplicados:**
- #3: `stop-watcher.sh` — añadida clasificación `test_quality`
- #5: `stop-watcher.sh` — evitada doble detección DEGRADED
- #7: `coordinator-pattern.md` — reset taskIteration en ADD_PREREQUISITE

## 11. Signal Catalog

Assembled from stop-watcher.sh detection logic and spec-executor.md output formats. `coordinator-signals.md` referenced in ARCHITECTURE.md original does not exist.

| Signal | Origin | Consumed by | stop-watcher detects? |
|--------|--------|-------------|----------------------|
| EXECUTOR_START | spec-executor | coordinator | No |
| TASK_COMPLETE | spec-executor | coordinator | No |
| TASK_MODIFICATION_REQUEST | spec-executor | coordinator | No |
| ESCALATE | spec-executor | coordinator | No (read from output) |
| SPEC_COMPLETE | spec-executor | coordinator | No |
| VERIFICATION_PASS | qa-engineer | spec-executor | Yes (Phase 3) |
| VERIFICATION_FAIL | qa-engineer | spec-executor | Yes (Phase 3) |
| VERIFICATION_DEGRADED | qa-engineer | spec-executor | Yes (Phase 3) |
| REVIEW_PASS | spec-reviewer | coordinator | No |
| REVIEW_FAIL | spec-reviewer | coordinator | No |
| EXECUTOR_REPAIR | spec-executor | coordinator | No |
| EXECUTOR_RETRY | spec-executor | coordinator | No |
| TASK_REVISION | coordinator | coordinator | No |
| REPAIR_ESCALATE | stop-watcher | (internal) | Internal only |
| ALL_TASKS_COMPLETE | coordinator | stop-watcher | Yes (primary) |
| RECOVERY_MODE | stop-watcher | coordinator | Via prompt only |

---

*Generated 2026-04-04 from codebase analysis, revised after counter-analysis review*
