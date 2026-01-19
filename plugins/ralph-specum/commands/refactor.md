---
description: Update spec files methodically after execution (requirements → design → tasks)
argument-hint: [spec-name] [--file=requirements|design|tasks]
allowed-tools: [Read, Write, Edit, Task, Bash, AskUserQuestion]
---

# Refactor Spec

You are helping a user update their specification files after execution. This command provides a methodical, file-by-file, section-by-section approach to updating specs.

<mandatory>
**YOU ARE A COORDINATOR, NOT A WRITER.**

You MUST:
1. Guide the user through reviewing each file
2. Ask specific questions about what needs updating
3. Delegate actual updates to the `refactor-specialist` subagent
4. Handle cascade updates when upstream files change

Do NOT write spec content yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name (not starting with `--`), use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:start first."

## Validate Spec Exists

1. Check `./specs/$spec/` directory exists
2. Read `.ralph-state.json` if exists
3. Identify which spec files exist:
   - `requirements.md`
   - `design.md`
   - `tasks.md`

If no spec files exist, error: "No spec files found. Run /ralph-specum:start first."

## Determine Refactor Scope

Check `$ARGUMENTS` for `--file=` flag:
- If `--file=requirements`: Only refactor requirements.md
- If `--file=design`: Only refactor design.md
- If `--file=tasks`: Only refactor tasks.md
- If no flag: Refactor all files in order (requirements → design → tasks)

## Initial Assessment

Before starting, gather context:

1. Read `.progress.md` to understand implementation learnings
2. Read each existing spec file to summarize current state
3. Present overview to user:

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

## File-by-File Refactoring

Process files in order: requirements → design → tasks

For each file that exists and is in scope:

### Step 1: Ask About This File

Use AskUserQuestion to determine if this file needs updates:

```
AskUserQuestion:
  questions:
    - question: "Do you want to update [filename]?"
      header: "[File]"
      options:
        - label: "Yes, review sections"
          description: "Go through section by section"
        - label: "Skip this file"
          description: "Move to next file"
        - label: "Major rewrite needed"
          description: "Significant changes required"
```

If "Skip", move to next file.
If "Major rewrite", note this for the specialist.

### Step 2: Section-by-Section Review

For each major section in the file, use AskUserQuestion:

#### Requirements Sections
```
AskUserQuestion:
  questions:
    - question: "Goal section - needs changes?"
      header: "Goal"
      options:
        - label: "Keep as-is"
          description: "Goal is still accurate"
        - label: "Update"
          description: "Goal needs modification"
    - question: "User Stories - changes needed?"
      header: "Stories"
      options:
        - label: "Keep all"
          description: "Stories are complete"
        - label: "Add stories"
          description: "Need new user stories"
        - label: "Modify stories"
          description: "Existing stories need updates"
        - label: "Remove stories"
          description: "Some stories are obsolete"
```

Continue with Functional Requirements, Non-Functional Requirements, Out of Scope, Dependencies, Success Criteria.

#### Design Sections
```
AskUserQuestion:
  questions:
    - question: "Architecture overview - needs changes?"
      header: "Architecture"
      options:
        - label: "Keep as-is"
          description: "Architecture is accurate"
        - label: "Update diagram"
          description: "Components changed"
        - label: "Major restructure"
          description: "Significant architecture changes"
    - question: "Components section - changes needed?"
      header: "Components"
      options:
        - label: "Keep all"
          description: "Components are complete"
        - label: "Add components"
          description: "New components needed"
        - label: "Modify components"
          description: "Existing components need updates"
        - label: "Remove components"
          description: "Some components are obsolete"
```

Continue with Data Flow, Technical Decisions, File Structure, Interfaces, Error Handling, Test Strategy.

#### Tasks Sections
```
AskUserQuestion:
  questions:
    - question: "Completed tasks - any need revisiting?"
      header: "Completed"
      options:
        - label: "All good"
          description: "Completed tasks are done"
        - label: "Some need rework"
          description: "Mark some tasks for rework"
    - question: "Need to add new tasks?"
      header: "New Tasks"
      options:
        - label: "No new tasks"
          description: "Task list is complete"
        - label: "Add tasks"
          description: "Need additional tasks"
```

Continue with Phase Structure, Task Dependencies, Verification Steps.

### Step 3: Gather Update Details

For each section marked for update, ask specific follow-up:

```
AskUserQuestion:
  questions:
    - question: "What specific changes for [section]?"
      header: "Details"
      options:
        - label: "I'll describe changes"
          description: "Let me type what needs changing"
        - label: "Based on learnings"
          description: "Use implementation learnings to guide updates"
        - label: "Remove outdated parts"
          description: "Just clean up obsolete content"
```

If user selects "I'll describe changes", wait for their text input before proceeding.

### Step 4: Delegate to Specialist

<mandatory>
Use the Task tool with `subagent_type: refactor-specialist` to make updates.
</mandatory>

```
Task:
  subagent_type: refactor-specialist
  prompt: |
    Refactor spec: $spec
    File: [filename]

    Current file content:
    [Include full file content]

    Implementation learnings:
    [Include relevant .progress.md content]

    Sections to update:
    [List sections marked for update with user's specific instructions]

    Update instructions:
    [User's detailed requirements for each section]

    Guidelines:
    - Make minimal, focused changes
    - Preserve valuable original content
    - Update cross-references if needed
    - Append refactoring log to .progress.md

    After updates, report:
    - REFACTOR_COMPLETE: [filename]
    - CASCADE_NEEDED: [list any downstream files that may need updates]
    - CASCADE_REASON: [why each file may need updates]
```

### Step 5: Handle Cascade Updates

After specialist completes, check for CASCADE_NEEDED:

If requirements.md was updated and CASCADE_NEEDED includes design:
```
AskUserQuestion:
  questions:
    - question: "Requirements changed. Update design.md to match?"
      header: "Cascade"
      options:
        - label: "Yes, update design"
          description: "Align design with new requirements"
        - label: "Skip design update"
          description: "Design is still valid"
        - label: "Regenerate design"
          description: "Create fresh design from new requirements"
```

If design.md was updated and CASCADE_NEEDED includes tasks:
```
AskUserQuestion:
  questions:
    - question: "Design changed. Update tasks.md to match?"
      header: "Cascade"
      options:
        - label: "Yes, update tasks"
          description: "Align tasks with new design"
        - label: "Skip tasks update"
          description: "Tasks are still valid"
        - label: "Regenerate tasks"
          description: "Create fresh task plan from new design"
```

If "Regenerate" is selected, delegate to the appropriate original agent (architect-reviewer for design, task-planner for tasks) instead of refactor-specialist.

## Update State

After all refactoring complete:

1. Update `.ralph-state.json`:
   - Keep existing phase
   - Reset `taskIndex` to 0 if tasks were modified
   - Set `awaitingApproval: true`

2. Update `.progress.md`:
   - Append refactoring summary

## Commit Changes (if enabled)

Read `commitSpec` from `.ralph-state.json`.

If `commitSpec` is true:

1. Stage all modified spec files:
   ```bash
   git add ./specs/$spec/
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): refactor specifications"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue.

## Output

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
