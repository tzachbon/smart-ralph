---
description: Show all specs and their current status
argument-hint:
allowed-tools: [Read, Bash, Glob]
---

# Spec Status

You are showing the status of all specifications.

## Gather Information

1. Check if `./specs/` directory exists
2. Read `./specs/.current-spec` to identify active spec
3. List all subdirectories in `./specs/` (each is a spec)

## For Each Spec

For each spec directory found:

1. Read `.ralph-state.json` if exists to get:
   - Current phase
   - Task progress (taskIndex/totalTasks)
   - Iteration count

2. Check which files exist:
   - research.md
   - requirements.md
   - design.md
   - tasks.md

3. If tasks.md exists, count completed tasks:
   - Count lines matching `- [x]` pattern
   - Count lines matching `- [ ]` pattern

## Output Format

```
# Ralph Specum Status

Active spec: <name from .current-spec> (or "none")

## Specs

### <spec-name-1> [ACTIVE]
Phase: <phase>
Progress: <completed>/<total> tasks (<percentage>%)
Files: [research] [requirements] [design] [tasks]

### <spec-name-2>
Phase: <phase>
Progress: <completed>/<total> tasks
Files: [research] [requirements] [design] [tasks]

---

Commands:
- /ralph-specum:switch <name> - Switch active spec
- /ralph-specum:new <name> - Create new spec
- /ralph-specum:<phase> - Run phase for active spec
```

## Phase Display

Show phase status with indicators:
- research: "Research"
- requirements: "Requirements"
- design: "Design"
- tasks: "Tasks"
- execution: "Executing" with task progress

## File Indicators

For each file, show:
- [x] if file exists
- [ ] if file does not exist

Example: `Files: [x] research [x] requirements [ ] design [ ] tasks`
