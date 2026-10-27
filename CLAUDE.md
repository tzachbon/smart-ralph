# CLAUDE.md

Smart Ralph is a Claude Code plugin for spec-driven development. It transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## ⛔ CRITICAL SAFETY RULES

1. **NEVER merge PRs without explicit user permission** — If unsure whether to merge, the answer is NO
2. **NEVER close PRs without explicit user permission** — Only fix conflicts, push changes, create PRs
3. **NEVER delete branches on remote without explicit user permission**
4. **Ask before any destructive action** — When in doubt, ask the user

## Karpathy Coding Rules

Four rules for all agents and code generation. Non-negotiable.

### 1. Think Before Coding
- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations? Present them, don't pick silently.
- Simpler approach exists? Say so. Push back when warranted.

### 2. Simplicity First
- No features beyond what was asked.
- No abstractions for single-use code.
- No speculative "flexibility" or "configurability".
- 200 lines that could be 50? Rewrite.
- Test: "Would a senior engineer say this is overcomplicated?"

### 3. Surgical Changes
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd do it differently.
- Remove only dead code YOUR changes created.
- Every changed line must trace to the user's request.

### 4. Goal-Driven Execution
- "Add validation" -> Write tests for invalid inputs, make them pass.
- "Fix the bug" -> Write reproducing test, make it pass.
- "Refactor X" -> Ensure tests pass before and after.
- Define success criteria. Loop until verified.

## Development

```bash
# Test plugin locally
claude --plugin-dir ./plugins/ralph-specum

# Test the workflow
/ralph-specum:start test-feature Some test goal
```

### Task Granularity

Control task count with `--tasks-size`:

```bash
/ralph-specum:tasks --tasks-size coarse    # 10-20 larger tasks, no intermediate [VERIFY]
/ralph-specum:tasks --tasks-size fine       # 40-60+ small tasks with [VERIFY] checkpoints (default)
/ralph-specum:start my-spec Goal --tasks-size coarse  # Set early, carries through
```

Fine is the default. Coarse reduces token consumption ~3-5x for sequential execution.

> **⚠️ CRITICAL: Version bumps are REQUIRED for ANY plugin change**
>
> When making ANY changes to plugin files (commands, agents, hooks, templates, schemas):
> 1. **ALWAYS bump the version** in BOTH files for the modified plugin:
>    - `plugins/<plugin-name>/.claude-plugin/plugin.json` (the plugin you're modifying)
>    - `.claude-plugin/marketplace.json` (update the corresponding plugin entry)
> 2. Use semantic versioning: patch (fixes), minor (features), major (breaking)
> 3. Bump once per set of related changes (not per commit)
> 4. Only update the version for plugins you actually modified

No build step required. Changes take effect on Claude Code restart.

## Context pointers

- Before changing plugin code (commands, agents, hooks, skills, templates, schemas, the stop-hook loop or state files), read [CODING_STANDARDS.md](CODING_STANDARDS.md): `plugin-dev` skills, style, architecture and key files.
