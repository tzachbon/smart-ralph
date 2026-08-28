---
description: Update spec files methodically after execution (requirements -> design -> tasks)
argument-hint: [spec-name] [--file=requirements|design|tasks]
allowed-tools: [Read, Write, Edit, Task, Bash, AskUserQuestion]
---

# Refactor Spec

Update specification files after execution. You are a **coordinator, not a writer** -- delegate actual updates to the `refactor-specialist` subagent.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read existing files and learnings
2. **Determine scope** -- which files to refactor (from --file flag or all)
3. **File-by-file review** -- section-by-section review with user for each file
4. **Delegate updates** -- dispatch refactor-specialist for each file
5. **Handle cascades** -- propagate changes downstream if needed
6. **Finalize** -- update state, commit

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json` if exists
5. Identify which spec files exist: `requirements.md`, `design.md`, `tasks.md`
6. If no spec files exist, error: "No spec files found. Run /ralph-specum:start first."
7. Read `.progress.md` to understand implementation learnings

### Prototype Refactor Gate

Before scope selection or refactor dispatch:

1. Read `.ralph-state.json`. When `activePrototypes` is absent or empty, keep the existing refactor path unchanged.
2. When active entries exist, reconcile and select records with the resolved `basePath`:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" reconcile --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json"
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py" select-downstream --base-path "$SPEC_PATH" --state "$SPEC_PATH/.ralph-state.json"
   ```
3. Stop a file's refactor dispatch when `activeBlockers` targets that file or transition, when its task index appears in `staleTaskIndexes`, or when `staleArtifacts` contains the file or an upstream dependency.
4. Preserve eligible files when the selector proves no dependency on the active prototype, stale artifact, stale task index, or approved transfer path.
5. When refactor resumes execution, restore `taskIndex` from the relevant entry's `returnTaskIndex` before task dispatch.

## Step 2: Determine Scope & Present Overview

Check `$ARGUMENTS` for `--file=` flag:
- `--file=requirements`: Only requirements.md
- `--file=design`: Only design.md
- `--file=tasks`: Only tasks.md
- No flag: All files in order (requirements -> design -> tasks)

Present overview to user:
```
Spec: $spec

Files to review:
- requirements.md: [exists/missing] - [brief summary: X user stories, Y requirements]
- design.md: [exists/missing] - [brief summary: X components, Y decisions]
- tasks.md: [exists/missing] - [brief summary: X tasks, Y completed]

Implementation learnings from .progress.md:
- [Key learning 1]
- [Key learning 2]
```

## Step 3: File-by-File Review

Process files in order: requirements -> design -> tasks. For each file in scope:

### Ask About This File

Use AskUserQuestion: "Do you want to update [filename]?" with options:
- **Yes, review sections** -- go through section by section
- **Skip this file** -- move to next
- **Major rewrite needed** -- note for specialist

If "Skip", move to next file.

### Section-by-Section Review

For each major section in the file, use AskUserQuestion to determine if it needs changes:

**Requirements sections**: Goal, User Stories (keep/add/modify/remove), Functional Requirements, Non-Functional Requirements, Out of Scope, Dependencies, Success Criteria.

**Design sections**: Architecture overview (keep/update diagram/major restructure), Components (keep/add/modify/remove), Data Flow, Technical Decisions, File Structure, Interfaces, Error Handling, Test Strategy.

**Tasks sections**: Completed tasks (all good/some need rework), New tasks (none/add), Phase Structure, Task Dependencies, Verification Steps.

### Gather Update Details

For sections marked for update, ask: "What specific changes for [section]?" with options:
- **I'll describe changes** -- wait for text input
- **Based on learnings** -- use implementation learnings to guide updates
- **Remove outdated parts** -- clean up obsolete content

## Step 4: Delegate to Specialist

<mandatory>
Use `Task(subagent_type: refactor-specialist)` for each file update.

Include in prompt:
- Full current file content
- Relevant `.progress.md` learnings
- Sections to update with user's specific instructions
- Guidelines: minimal focused changes, preserve valuable content, update cross-references

Specialist reports: `REFACTOR_COMPLETE: [filename]` and `CASCADE_NEEDED: [downstream files]` with reasons.
</mandatory>

## Step 5: Handle Cascade Updates

After specialist completes, check for CASCADE_NEEDED:

**If requirements changed** and cascade includes design: Ask user "Requirements changed. Update design.md to match?" (Yes / Skip / Regenerate)

**If design changed** and cascade includes tasks: Ask user "Design changed. Update tasks.md to match?" (Yes / Skip / Regenerate)

If "Regenerate" selected, delegate to the original agent (architect-reviewer for design, task-planner for tasks) instead of refactor-specialist.

## Step 6: Finalize

### Update State

1. Merge through `locked-state.py` without supplying `phase`, so the existing phase and unknown fields remain unchanged:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "awaitingApproval=true"
   # If tasks changed, run a second locked merge with --set "taskIndex=0".
   ```
2. Append refactoring summary to `.progress.md`

### Commit (if enabled)

Read `commitSpec` from `.ralph-state.json`. If true:
```bash
git add ./specs/$spec/
git commit -m "spec($spec): refactor specifications"
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Output

```
Refactoring complete for '$spec'.

Updated files:
- [list of files updated with brief change summary]

Cascade updates:
- [any cascade updates made]

[If commitSpec: "Changes committed and pushed."]

Next steps:
- Review updated spec files
- Run /ralph-specum:implement to continue execution (if tasks were modified)
```
