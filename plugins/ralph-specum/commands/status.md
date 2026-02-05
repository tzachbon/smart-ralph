---
description: Show all specs and their current status
argument-hint:
allowed-tools: [Read, Bash, Glob, Task]
---

# Spec Status

You are showing the status of all specifications across all configured specs directories.

## Multi-Directory Resolution

This command uses the path resolver to discover specs from all configured directories.

**Path Resolver Functions**:
- `ralph_list_specs()` - Returns all specs as `name|path` pairs
- `ralph_resolve_current()` - Resolves .current-spec to full path

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

## Gather Information

1. Use `ralph_list_specs()` to enumerate all specs from all configured directories
2. Use `ralph_resolve_current()` to identify the active spec path
3. Group specs by their root directory

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

4. If `.ralph-state.json` has `relatedSpecs`:
   - List related specs with relevance
   - Mark those with `mayNeedUpdate: true` with asterisk

## Output Format

Group specs by their root directory. Show `[dir-path]` suffix for specs NOT in the default `./specs` directory.

```
# Ralph Specum Status

Active spec: <name from .current-spec> (or "none")

## Specs

### <spec-name-1> [ACTIVE]
Phase: <phase>
Progress: <completed>/<total> tasks (<percentage>%)
Files: [research] [requirements] [design] [tasks]
Related: auth-system (HIGH*), api-middleware (MEDIUM)
         * = may need update

### <spec-name-2>
Phase: <phase>
Progress: <completed>/<total> tasks
Files: [research] [requirements] [design] [tasks]
Related: <none or list>

### api-auth [packages/api/specs]
Phase: design
Progress: 0/0 tasks
Files: [x] research [x] requirements [x] design [ ] tasks

### web-login [packages/web/specs]
Phase: research
Progress: 0/0 tasks
Files: [x] research [ ] requirements [ ] design [ ] tasks

---

Commands:
- /ralph-specum:switch <name> - Switch active spec
- /ralph-specum:new <name> - Create new spec
- /ralph-specum:<phase> - Run phase for active spec
```

**Directory Context Rules**:
- Specs in default `./specs/` directory: No suffix
- Specs in other directories: Show `[dir-path]` suffix (e.g., `[packages/api/specs]`)
- Active spec: Always shows `[ACTIVE]` tag regardless of directory

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
