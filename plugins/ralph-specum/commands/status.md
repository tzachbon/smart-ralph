---
description: Show all specs and their current status
argument-hint: [--update-index]
allowed-tools: [Read, Bash, Glob, Task]
---

# Spec Status

You are showing the status of all specifications across all configured specs directories.

## Parse Arguments

From `$ARGUMENTS`:
- **--update-index**: Regenerate the spec index files before showing status

### Update Index Flag

If `--update-index` is present in `$ARGUMENTS`:

```bash
# Regenerate spec index files
./plugins/ralph-specum/hooks/scripts/update-spec-index.sh
```

This updates:
- `./specs/.index/index-state.json` - Machine-readable state
- `./specs/.index/index.md` - Human-readable summary

The index is also updated automatically when specs are created, completed, or deleted.

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
   - **Team name** (teamName field, if present)
   - **Teammate names** (teammateNames array, if present)
   - **Team phase** (teamPhase field: "research" or "execution", if present)

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

5. **If active team detected** (teamName field exists):
   - Display team name and phase
   - Display teammate count
   - If available, query TaskList for each teammate's status
   - Show idle/working state for each teammate

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
Team: <teamName or "none">
<If team active:>
Teammates: N active (<list of names>)
Status: <teammate-1>: idle | <teammate-2>: working on task X.Y
Related: auth-system (HIGH*), api-middleware (MEDIUM)
         * = may need update
         Use Shift+Up/Down to message teammates directly

### <spec-name-2>
Phase: <phase>
Progress: <completed>/<total> tasks
Files: [research] [requirements] [design] [tasks]
Team: <teamName or "none">
Related: <none or list>

### api-auth [packages/api/specs]
Phase: design
Progress: 0/0 tasks
Files: [x] research [x] requirements [x] design [ ] tasks
Team: research-api-auth-1234567890 (research phase)
Teammates: 3 active (analyst-1, analyst-2, code-explorer)
Status: analyst-1: idle | analyst-2: working | code-explorer: idle

### web-login [packages/web/specs]
Phase: research
Progress: 0/0 tasks
Files: [x] research [ ] requirements [ ] design [ ] tasks
Team: none

---

Index: ./specs/.index/index.md (run with --update-index to refresh)

Commands:
- /ralph-specum:switch <name> - Switch active spec
- /ralph-specum:new <name> - Create new spec
- /ralph-specum:<phase> - Run phase for active spec
- /ralph-specum:status --update-index - Refresh spec index
- /ralph-specum:team-status [spec-name] - Show team details
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
