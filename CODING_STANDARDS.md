# Coding standards

## Plugin components

Create or modify plugin components with the `plugin-dev` skills. Naming and style: [CONTRIBUTING.md](CONTRIBUTING.md#style-guide). Try a change with `claude --plugin-dir ./plugins/ralph-specum`, then `/ralph-specum:start test-feature Some test goal`; edits load on Claude Code restart, with no build step.

## Version bumps

Every change to a plugin's files bumps that plugin's version, once per set of related changes, in both `plugins/<plugin-name>/.claude-plugin/plugin.json` and its entry in `.claude-plugin/marketplace.json` (`ralph-specum-codex`: its `.codex-plugin/plugin.json`). Semantic versioning: patch for fixes, minor for features, major for breaking changes. Bump only the plugins you changed.

## Architecture

### Execution flow

1. **Spec phases**: `/ralph-specum:research`, `:requirements`, `:design` and `:tasks` each invoke a specialized agent that writes its markdown to `./specs/<spec-name>/`.
2. **Execution loop**: during `/ralph-specum:implement`, the stop hook reads `.ralph-state.json`, delegates each task to spec-executor via the Task tool, and outputs `ALL_TASKS_COMPLETE` when done. The loop needs no external plugin.
3. **Fresh context**: each task runs in isolation; progress persists in `.progress.md` and the task checkmarks in `tasks.md`.

### State files

- `./specs/.current-spec`: active spec name.
- `./specs/<name>/.ralph-state.json`: loop state (phase, taskIndex, iterations); deleted on completion.
- `./specs/<name>/.progress.md`: progress, learnings and context for agents.

### Epics (multi-spec orchestration)

Epics decompose a large feature into dependency-aware specs. `/ralph-specum:triage <goal>` creates or resumes one; `/ralph-specum:start` detects active epics and suggests the next unblocked spec. Flow: explore (research), brainstorm (triage-analyst), validate (research), finalize (output selection).

```
specs/
  .current-epic          # active epic name
  _epics/<epic-name>/
    epic.md              # triage output: vision, specs, dependency graph
    research.md          # exploration and validation research
    .epic-state.json     # progress across specs
    .progress.md         # learnings and decisions
```

### Workflow by intent

The task planner picks the workflow from the spec's intent: `GREENFIELD` runs POC-first; `TRIVIAL`, `REFACTOR` and `MID_SIZED` run TDD Red-Green-Yellow; `BUG_FIX` runs Bug TDD with a Phase 0 reproduction. Quality checkpoints land every 2-3 tasks throughout. Phases and their distribution: [phase-rules.md](plugins/ralph-specum/references/phase-rules.md).

### Task completion protocol

Spec-executor outputs `TASK_COMPLETE` for the coordinator to advance; the coordinator outputs `ALL_TASKS_COMPLETE` to end the loop. A task without `TASK_COMPLETE` retries up to `--max-task-iterations` (default 5), then stops with its error; with `--recovery-mode`, it instead gets fix tasks inserted after it, then retries, stopping at `maxFixTasksPerOriginal` or `maxFixTaskDepth`. Details: [failure-recovery.md](plugins/ralph-specum/references/failure-recovery.md).

## Key files

Under `plugins/ralph-specum/`:

- `commands/implement.md`: thin wrapper plus the coordinator prompt for the loop.
- `commands/cancel.md`: dual cleanup (cancel-ralph plus state file deletion).
- `hooks/scripts/stop-watcher.sh`: loop controller (outputs continuation prompts).
- `agents/spec-executor.md`: task execution rules, commit discipline.
- `agents/task-planner.md`: task format, quality checkpoints, POC workflow; sizing per level in `references/sizing-rules.md`.
- `templates/*.md`: spec file templates and their required structure.
