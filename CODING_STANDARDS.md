# Coding standards

## Plugin components

When creating or modifying plugin components, **ALWAYS** use the `plugin-dev` skills for guidance. Naming and style: [CONTRIBUTING.md](CONTRIBUTING.md#style-guide).

## Architecture

### Execution Flow

1. **Spec Phases**: Each command (`/ralph-specum:research`, `:requirements`, `:design`, `:tasks`) invokes a specialized agent to generate corresponding markdown in `./specs/<spec-name>/`
2. **Execution Loop**: During execution (`/ralph-specum:implement`), the stop-hook reads `.ralph-state.json`, delegates tasks to spec-executor via Task tool, and outputs `ALL_TASKS_COMPLETE` when done. The loop is self-contained (no external plugin required).
3. **Fresh Context**: Each task runs in isolation via Task tool. Progress persists in `.progress.md` and task checkmarks in `tasks.md`

### State Files

- `./specs/.current-spec` - Active spec name
- `./specs/<name>/.ralph-state.json` - Loop state (phase, taskIndex, iterations). Deleted on completion
- `./specs/<name>/.progress.md` - Progress tracking, learnings, context for agents

### Epics (Multi-Spec Orchestration)

Epics decompose large features into multiple dependency-aware specs.

**File structure:**
```
specs/
  .current-epic          # Points to active epic name
  _epics/
    <epic-name>/
      epic.md            # Triage output (vision, specs, dependency graph)
      research.md        # Exploration + validation research
      .epic-state.json   # Progress tracking across specs
      .progress.md       # Learnings and decisions
```

**Entry points:**
- `/ralph-specum:triage <goal>` -- create or resume an epic
- `/ralph-specum:start` -- detects active epics, suggests next unblocked spec

**Flow:** Explore (research) -> Brainstorm (triage-analyst) -> Validate (research) -> Finalize (output selection)

### POC-First Workflow (Mandatory)

All specs follow 4 phases:
1. **Phase 1: Make It Work** - POC validation, skip tests
2. **Phase 2: Refactoring** - Code cleanup
3. **Phase 3: Testing** - Unit, integration, e2e
4. **Phase 4: Quality Gates** - Lint, types, CI, PR

Quality checkpoints inserted every 2-3 tasks throughout all phases.

### Task Completion Protocol

Spec-executor must output `TASK_COMPLETE` for coordinator to advance. Coordinator outputs `ALL_TASKS_COMPLETE` to end the Ralph Loop. If task fails, retries up to 5 times then blocks with error.

## Key Files

- `commands/implement.md` - Thin wrapper + coordinator prompt for Ralph Loop
- `commands/cancel.md` - Dual cleanup (cancel-ralph + state file deletion)
- `hooks/scripts/stop-watcher.sh` - Execution loop controller (outputs continuation prompts)
- `agents/spec-executor.md` - Task execution rules, commit discipline
- `agents/task-planner.md` - Task format, quality checkpoint rules, POC workflow
- `templates/*.md` - Spec file templates with structure requirements
