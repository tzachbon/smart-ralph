# Codex CLI Adapter for Smart Ralph

Enables the Smart Ralph spec-driven workflow in [Codex CLI](https://github.com/openai/codex). Since Codex has no hooks, custom commands, or custom agents, this adapter relies entirely on SKILL.md progressive disclosure and manual re-invocation.

## How It Works

Codex CLI can discover and invoke SKILL.md files placed in `.agents/skills/`. The Ralph implement skill reads `.ralph-state.json`, executes one task per invocation, advances the state, and tells you to re-invoke for the next task. You drive the loop; the state file tracks progress.

```
You invoke skill -> skill executes 1 task -> "Re-invoke for next task"
     ^                                              |
     |______________________________________________|
                   (repeat until done)
```

## Prerequisites

- [Codex CLI](https://github.com/openai/codex) installed
- `jq` installed (used for state file updates)
- A Ralph spec with `tasks.md` and `.ralph-state.json` already generated

## Setup

### 1. Copy the implement skill

Place the SKILL.md where Codex can discover it:

```bash
mkdir -p .agents/skills/ralph-implement
cp adapters/codex/skills/ralph-implement/SKILL.md .agents/skills/ralph-implement/SKILL.md
```

### 2. Generate AGENTS.md (optional)

AGENTS.md provides project-level context to Codex. Generate it from your spec's design.md:

**Using the generator script:**

```bash
bash plugins/ralph-specum/scripts/generate-agents-md.sh \
  --spec-path ./specs/<your-spec-name> \
  --output ./AGENTS.md
```

**Using the template manually:**

```bash
cp adapters/codex/AGENTS.md.template ./AGENTS.md
```

Then replace the `{{placeholders}}` with content from your spec's `design.md`:

| Placeholder | Source |
|-------------|--------|
| `{{spec_name}}` | Your spec name (e.g., `my-feature`) |
| `{{spec_path}}` | Path to spec directory (e.g., `./specs/my-feature`) |
| `{{architecture_section}}` | Architecture section from `design.md` |
| `{{conventions_section}}` | Existing Patterns / Components sections from `design.md` |
| `{{file_structure_section}}` | File Structure section from `design.md` |
| `{{decisions_section}}` | Technical Decisions table from `design.md` |

### 3. Verify skill discovery

Confirm Codex can find the skill:

```bash
ls .agents/skills/ralph-implement/SKILL.md
```

Codex should list `ralph-implement` when you ask it about available skills.

## Workflow Walkthrough

The full Ralph workflow consists of six phases. In Codex CLI, you run each phase by following the corresponding SKILL.md guidance. The universal SKILL.md files (in `plugins/ralph-specum/skills/workflow/`) provide instructions for all phases.

### Phase 1: Start

Create a new spec:

```
Spec name: my-feature
Goal: <describe what you want to build>
```

Create the spec directory and initialize state:

```bash
mkdir -p specs/my-feature
# Write .ralph-state.json with phase: "research"
# Write .progress.md with the goal
# Write .current-spec with "my-feature"
```

See `plugins/ralph-specum/skills/workflow/start/SKILL.md` for full details.

### Phase 2: Research

Read the goal from `.progress.md`, explore the codebase, search the web for relevant information, and write `research.md`.

See `plugins/ralph-specum/skills/workflow/research/SKILL.md`.

### Phase 3: Requirements

Read `research.md` and generate `requirements.md` with user stories, acceptance criteria, and FR/NFR tables.

See `plugins/ralph-specum/skills/workflow/requirements/SKILL.md`.

### Phase 4: Design

Read `requirements.md` and generate `design.md` with architecture, components, data flow, and technical decisions.

See `plugins/ralph-specum/skills/workflow/design/SKILL.md`.

### Phase 5: Tasks

Read `design.md` and generate `tasks.md` with the POC-first 4-phase task breakdown.

See `plugins/ralph-specum/skills/workflow/tasks/SKILL.md`.

### Phase 6: Implement

This is where the Codex adapter skill takes over. The `ralph-implement` skill handles task-by-task execution:

1. Invoke the `ralph-implement` skill.
2. It reads `.ralph-state.json`, finds the current task, and executes it.
3. After the task passes verification, it commits changes and advances the state.
4. It reports: **"Task X.Y complete. Re-invoke this skill for the next task."**
5. You invoke the skill again. Repeat until you see **"ALL_TASKS_COMPLETE"**.

Each invocation handles exactly one task. Progress is saved to `.ralph-state.json` between invocations, so you can stop and resume at any time.

## How Task Execution Works Without Hooks

In Claude Code and OpenCode, hooks automatically re-invoke the implement logic after each task. Codex CLI has no hooks, so the flow is manual:

| Tool | Continuation | User Action |
|------|-------------|-------------|
| Claude Code | Stop hook auto-continues | None (hands-free) |
| OpenCode | JS/TS hook auto-continues | None (hands-free) |
| **Codex CLI** | **State file persists** | **Re-invoke skill after each task** |

The state file (`.ralph-state.json`) is the coordination mechanism:

- `taskIndex` tracks which task to execute next (0-based).
- After each task, `taskIndex` is incremented.
- On the next invocation, the skill reads `taskIndex` and picks up where it left off.
- When `taskIndex >= totalTasks`, the state file is deleted and execution is complete.

No progress is lost between invocations. You can even switch tools mid-execution: start in Codex, continue in Claude Code (or vice versa).

## Directory Structure

After setup, your project should look like:

```
your-project/
  .agents/
    skills/
      ralph-implement/
        SKILL.md            # Codex implement skill
  AGENTS.md                 # Project context (optional)
  specs/
    .current-spec           # Points to active spec
    my-feature/
      research.md
      requirements.md
      design.md
      tasks.md
      .progress.md
      .ralph-state.json
```

## Troubleshooting

### Codex cannot find the skill

- Verify the file exists at `.agents/skills/ralph-implement/SKILL.md`.
- Ensure the file has valid YAML frontmatter (`name` and `description` fields).
- Restart Codex CLI to re-scan for skills.

### "No active spec" or missing state file

- Check that `specs/.current-spec` exists and contains the spec name.
- Check that `specs/<name>/.ralph-state.json` exists.
- If the state file is missing, reinitialize it (see the SKILL.md's "Initialize from tasks.md" section).

### Task verification keeps failing

- Read the error output from the Verify command.
- Check `.progress.md` Learnings section for hints from previous attempts.
- The skill retries up to 5 times by default. If all retries fail, it stops and documents the failure.

### taskIndex seems wrong

- Compare the number of `[x]` marks in `tasks.md` with `taskIndex` in `.ralph-state.json`.
- They should match. If they diverge, delete `.ralph-state.json` and reinitialize from `tasks.md`.

### Want to skip a task

Do not manually edit `taskIndex`. Instead, mark the task as `[x]` in `tasks.md`, then reinitialize the state file:

```bash
# After marking task(s) as [x] in tasks.md:
TOTAL=$(grep -c '^\- \[ \]' "$SPEC_DIR/tasks.md")
COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_DIR/tasks.md")
jq --argjson idx "$COMPLETED" --argjson total "$((TOTAL + COMPLETED))" \
  '.taskIndex = $idx | .totalTasks = $total' \
  "$SPEC_DIR/.ralph-state.json" > /tmp/ralph-state.json && \
  mv /tmp/ralph-state.json "$SPEC_DIR/.ralph-state.json"
```

### Switching between tools

Spec artifacts are tool-agnostic. You can:
- Start a spec in Codex CLI, continue in Claude Code or OpenCode.
- Start in Claude Code, continue in Codex CLI.
- The state file format is identical across all three tools.
