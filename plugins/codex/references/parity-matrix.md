# Ralph Parity Matrix

## Command Mapping

| Claude feature | Codex equivalent | Translation note |
|----------------|------------------|------------------|
| Plugin manifest | Installable skill folder | Codex installs skill folders, not plugins |
| Slash commands | Primary and helper skills | Public surface moves from `/command` to `$skill` |
| Hook-driven loop | State-driven resume | `.ralph-state.json` replaces hook continuation |
| `start --quick` | Quick-mode intent in start or primary skill | Generate artifacts and continue in one session |
| `new` | Alias inside start | No separate install unit needed |
| `implement` | Same skill surface | Implementation continues until complete or blocked |
| `switch` | Same skill surface | Updates `.current-spec` |
| `cancel` | Same skill surface | Confirm before destructive spec delete |
| `index` | Same skill surface | Generate `specs/.index/` directly |
| `refactor` | Same skill surface | Update requirements, design, and tasks after learnings |
| `feedback` | Same skill surface | Use `gh` when available or fall back to issue URL |
| `help` | Same skill surface | Summarize flow and entrypoints |

## Behavior Translation

### Hooks

Claude:

- `SessionStart` loads context
- `Stop` continues execution

Codex:

- read repo state at skill start
- persist state after each phase or task
- resume on the next invocation

### Subagents

Claude uses subagents like `research-analyst` and `spec-executor`.

Codex skills should preserve the same responsibilities, but the skill itself may execute the work in one session instead of requiring Claude plugin subagent dispatch.

### Worktrees

Claude start has explicit worktree prompts. Codex should still support that behavior when the user wants isolation, but it stays conversational.

### Parallel Tasks

Claude can batch `[P]` tasks in one delegated message. Codex can do the same only when file overlap and verification risk are low. Otherwise fall back to sequential execution and say why.

## Version Delta (v4.8.4 -> v4.9.1)

Changes in the Claude plugin since the last Codex sync:

| Change | Category | Impact |
|--------|----------|--------|
| Added `epic.md` template | Templates | New file, was missing from Codex |
| Updated `tasks.md` template (192 -> 588 lines) | Templates | Added task writing guide, TDD workflow, intent-based selector |
| Updated `settings-template.md` (24 -> 79 lines) | Templates | Added extended docs, monorepo example |
| Added `spec-reviewer` agent | Agents | New rubric-based artifact reviewer |
| Added `qa-engineer` agent | Agents | New [VERIFY] task executor |
| Added `refactor-specialist` agent | Agents | New section-by-section spec updater |
| Added verification-layers to workflow | References | 3-layer verification protocol (contradiction, signal, review) |
| Added failure-recovery guidance | References | Fix-task generation, retry logic, recovery modes |
| Added intent classification | References | GREENFIELD/TRIVIAL/REFACTOR/MID_SIZED routing |
| Hook-driven execution path documented | References | Stop hook `{"decision":"block"}` format for Codex |
| Manual fallback path documented | References | Step-by-step re-invocation when hooks disabled |
