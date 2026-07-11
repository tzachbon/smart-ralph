# Ralph Specum for Codex

Native spec-driven development for Codex using phase skills, tiered subagent orchestration, reviewed Markdown artifacts, verified implementation batches, and native `/goal` execution. Research and requirements target medium reasoning, design and broad triage target the strongest available reasoning, and task decomposition targets a light tier. Exact per-subagent model selection is used when the active native spawn surface supports it and otherwise remains an explicit packet-level tier without requiring custom configuration.

## Requirements

- Codex CLI 0.144.0 or newer
- A ChatGPT account supported by Codex or an OpenAI API key
- Git for implementation workflows that create commits

```bash
codex --version
```

## Install

```bash
codex plugin marketplace add tzachbon/smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

Restart Codex after installation.

The plugin is self-contained. It does not require hooks, manually configured agents, or a separate Ralph loop.

## Update

```bash
codex plugin marketplace upgrade smart-ralph
codex plugin remove ralph-specum-codex@smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

Restart Codex to load the updated package.

## Roll back

Replace `v5.0.0` with the release tag you want:

```bash
codex plugin remove ralph-specum-codex@smart-ralph
codex plugin marketplace remove smart-ralph
codex plugin marketplace add tzachbon/smart-ralph --ref v5.0.0
codex plugin add ralph-specum-codex@smart-ralph
```

## Phase skills

- `$ralph-specum`
- `$ralph-specum-start`
- `$ralph-specum-triage`
- `$ralph-specum-research`
- `$ralph-specum-requirements`
- `$ralph-specum-design`
- `$ralph-specum-tasks`
- `$ralph-specum-implement`
- `$ralph-specum-status`

Use `$ralph-specum` when you want natural intent routing. Use an explicit phase skill when you want to enter that phase directly.

## Execution behavior

Ralph is approval-gated unless you explicitly request autonomous, quick, finish, or long-running execution.

- Normal implementation runs one verified logical batch and returns.
- Explicit autonomous execution uses native `/goal` with the approved spec, remaining tasks, constraints, verification commands, and terminal success condition.
- Ralph never assigns a goal token budget unless you explicitly provide one.
- Native goal controls handle status, pause, resume, clear, completion, and long-running persistence.
- `$ralph-specum-status` reports both artifact progress and active native goal status when available.

Subagents receive bounded work packets. They do not update shared progress, task state, runtime state, or Git. The root coordinator validates their evidence, updates artifacts, and commits one verified logical batch.

## Durable state

- `research.md`, `requirements.md`, `design.md`, and `tasks.md` are canonical artifacts.
- Task checkboxes in `tasks.md` are authoritative completion state.
- Tracked `progress.md` records phase, approvals, durable learnings, blockers, and the next step.
- `.current-spec` is a local convenience pointer.
- Codex continuation does not depend on `.ralph-state.json`.

When only legacy `.progress.md` exists, Ralph reads it as migration context and creates a concise reviewed `progress.md`. Raw legacy logs are never committed automatically.

## Version 5 compatibility shims

These legacy helper skills route to `$ralph-specum` and emit a version 6 removal warning:

- `$ralph-specum-switch`
- `$ralph-specum-cancel`
- `$ralph-specum-index`
- `$ralph-specum-refactor`
- `$ralph-specum-feedback`
- `$ralph-specum-help`

See [Migration to v5](../../docs/migration-v5.md) for migration details.
