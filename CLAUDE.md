# CLAUDE.md

Smart Ralph is a Claude Code plugin for spec-driven development: it turns a feature request into specs (research, requirements, design, tasks), then executes them task by task with fresh context per task.

## ⛔ CRITICAL SAFETY RULES

Merging a PR, closing a PR, deleting a remote branch or any other destructive action needs the user's explicit permission for that action. Without it, stay within fixing conflicts, pushing changes and creating PRs. Unsure? The answer is no until the user says yes.

## Karpathy Coding Rules

For all agents and generated code:

1. **Think Before Coding**: state assumptions; when the ask is unclear or has several readings, present them and ask; name a simpler approach when one exists.
2. **Simplicity First**: build only what was asked, with no single-use abstractions or speculative configurability; rewrite what a senior engineer would call overcomplicated.
3. **Surgical Changes**: trace every changed line to the request; match existing style; remove only dead code your change created.
4. **Goal-Driven Execution**: turn the ask into a verifiable check (a reproducing test for a bug, tests for invalid input, tests passing before and after a refactor), then loop until it passes.

## Task granularity

`--tasks-size` sets how finely tasks are split; set on `start`, it carries through:

```bash
/ralph-specum:start my-spec Goal --tasks-size coarse
/ralph-specum:tasks --tasks-size fine
```

- `fine` (default): 40-60+ small tasks with [VERIFY] checkpoints every 2-3 tasks.
- `coarse`: 10-20 larger tasks, no intermediate [VERIFY]; ~3-5x fewer tokens in sequential execution.

## Changing the plugins

Before changing plugin code (commands, agents, hooks, skills, templates, schemas, the stop-hook loop or state files), read [CODING_STANDARDS.md](CODING_STANDARDS.md): version bumps, local testing, architecture and key files.
