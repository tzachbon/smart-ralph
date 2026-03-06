# Ralph Specum for Codex

Installable Codex skills for Ralph Specum live in this package. This is the Codex distribution surface for this repo. It is not meant to be copied into a project root as-is.

## What Ships

- Primary skill: `$ralph-specum`
- Helper skills:
  - `$ralph-specum-start`
  - `$ralph-specum-triage`
  - `$ralph-specum-research`
  - `$ralph-specum-requirements`
  - `$ralph-specum-design`
  - `$ralph-specum-tasks`
  - `$ralph-specum-implement`
  - `$ralph-specum-status`
  - `$ralph-specum-switch`
  - `$ralph-specum-cancel`
  - `$ralph-specum-index`
  - `$ralph-specum-refactor`
  - `$ralph-specum-feedback`
  - `$ralph-specum-help`

## Recommended Install Sets

### Core Install

Install the primary skill only. This is the easiest path.

Prompt to send to Codex:

```text
Use $skill-installer to install the Smart Ralph Codex skill from repo `tzachbon/smart-ralph` at path `platforms/codex/skills/ralph-specum`.
```

In Codex, ask `$skill-installer` to install:

- repo: `tzachbon/smart-ralph`
- path: `platforms/codex/skills/ralph-specum`

Direct script form:

```bash
python3 "$CODEX_HOME/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --repo tzachbon/smart-ralph \
  --path platforms/codex/skills/ralph-specum
```

### Full Helper Bundle

Install the primary skill plus the explicit helper skills.

Prompt to send to Codex:

```text
Use $skill-installer to install the Smart Ralph Codex skills from repo `tzachbon/smart-ralph` at these paths:
- `platforms/codex/skills/ralph-specum`
- `platforms/codex/skills/ralph-specum-start`
- `platforms/codex/skills/ralph-specum-triage`
- `platforms/codex/skills/ralph-specum-research`
- `platforms/codex/skills/ralph-specum-requirements`
- `platforms/codex/skills/ralph-specum-design`
- `platforms/codex/skills/ralph-specum-tasks`
- `platforms/codex/skills/ralph-specum-implement`
- `platforms/codex/skills/ralph-specum-status`
- `platforms/codex/skills/ralph-specum-switch`
- `platforms/codex/skills/ralph-specum-cancel`
- `platforms/codex/skills/ralph-specum-index`
- `platforms/codex/skills/ralph-specum-refactor`
- `platforms/codex/skills/ralph-specum-feedback`
- `platforms/codex/skills/ralph-specum-help`
```

```bash
python3 "$CODEX_HOME/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --repo tzachbon/smart-ralph \
  --path \
    platforms/codex/skills/ralph-specum \
    platforms/codex/skills/ralph-specum-start \
    platforms/codex/skills/ralph-specum-triage \
    platforms/codex/skills/ralph-specum-research \
    platforms/codex/skills/ralph-specum-requirements \
    platforms/codex/skills/ralph-specum-design \
    platforms/codex/skills/ralph-specum-tasks \
    platforms/codex/skills/ralph-specum-implement \
    platforms/codex/skills/ralph-specum-status \
    platforms/codex/skills/ralph-specum-switch \
    platforms/codex/skills/ralph-specum-cancel \
    platforms/codex/skills/ralph-specum-index \
    platforms/codex/skills/ralph-specum-refactor \
    platforms/codex/skills/ralph-specum-feedback \
    platforms/codex/skills/ralph-specum-help
```

Restart Codex after installation.

## Optional Project Bootstrap

The package does not require project-local files. If a team wants repo-local guidance, copy these optional templates from the installed primary skill:

- `$CODEX_HOME/skills/ralph-specum/assets/bootstrap/AGENTS.md`
- `$CODEX_HOME/skills/ralph-specum/assets/bootstrap/ralph-specum.local.md`

Recommended destinations in the consumer repo:

- `AGENTS.md`
- `.claude/ralph-specum.local.md`

## Parity Notes

- Claude plugin manifests and hooks do not exist in Codex.
- Quick mode is expressed as one Codex run that generates missing artifacts and then continues into implementation.
- Claude stop-hook continuation is replaced by `.ralph-state.json` persistence and resume behavior.
- Task approval gates, `--tasks-size` granularity, VE verification tasks, and `[P]` or `[VERIFY]` task markers are part of the current Codex-facing guidance.
- Large efforts should route through triage first. Epic state lives under `specs/_epics/` with `specs/.current-epic` tracking the active epic.
- Branch and worktree decisions are still available, but they are handled conversationally instead of through Claude plugin prompts.
- Helper skills are explicit entrypoints. The primary skill remains the best default.
- Ralph does not self-advance by default. After each spec artifact, the user must approve it, request changes, or explicitly continue to the next step.
- Quick or autonomous flow happens only when the user explicitly asks for it.

## Maintainer Notes

- Skill sources live under `platforms/codex/skills/`.
- The primary skill contains the shared references, scripts, bootstrap assets, and canonical templates.
- Helper skills are standalone install units. They must not depend on files outside their own installed directory.
