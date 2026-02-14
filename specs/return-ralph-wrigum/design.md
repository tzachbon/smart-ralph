---
spec: return-ralph-wrigum
phase: design
created: 2026-02-14
generated: auto
---

# Design: return-ralph-wrigum

## Overview

Revert the self-contained loop mechanism to use Ralph Wiggum's `/ralph-loop` command. implement.md becomes a thin wrapper that constructs a coordinator prompt and invokes `/ralph-loop`. stop-watcher.sh reverts to passive logging/cleanup. cancel.md adds `/cancel-ralph` invocation. All v3.0.0 improvements (recovery mode, fix-task generation, parallel execution, verification layers) are preserved in the coordinator prompt passed to ralph-loop.

## Architecture

```
BEFORE (v3.1.1 - Current, self-contained):

implement.md ──► Write .ralph-state.json ──► Output coordinator prompt directly
                                                    │
stop-watcher.sh ──► Read state ──► Output continuation prompt ──► Loop continues
                                   (LOOP CONTROLLER)

AFTER (v4.0.0 - With Ralph Wiggum):

implement.md ──► Write .ralph-state.json ──► /ralph-loop "<coordinator-prompt>"
                                                    │
ralph-wiggum stop-hook ──► Re-inject prompt each iteration ──► Loop continues
                                   (LOOP CONTROLLER)

stop-watcher.sh ──► Read state ──► Log to stderr ──► Cleanup orphans
                                   (PASSIVE OBSERVER)
```

## Components

### Component 1: implement.md (Thin Wrapper)

**Purpose**: Validate prerequisites, build coordinator prompt, invoke Ralph Wiggum loop

**Responsibilities**:
- Read spec from `.current-spec` (multi-directory resolution)
- Validate prerequisites (spec dir, tasks.md, Ralph Wiggum dependency)
- Parse arguments (--max-task-iterations, --max-global-iterations, --recovery-mode)
- Initialize `.ralph-state.json` with execution state
- Calculate max-iterations for Ralph Wiggum
- Construct coordinator prompt with full orchestration logic
- Invoke `/ralph-loop "<prompt>" --max-iterations N --completion-promise "ALL_TASKS_COMPLETE"`

**Key Changes from Current**:
- ADD: Ralph Wiggum dependency check section
- ADD: `/ralph-loop` invocation with arguments
- KEEP: All coordinator logic (state reading, task parsing, delegation, verification, parallel, recovery)
- KEEP: Multi-directory resolution
- KEEP: Argument parsing (--max-task-iterations, --max-global-iterations, --recovery-mode)
- REMOVE: Direct prompt output (replaced by ralph-loop invocation)
- CHANGE: "Start Execution" section becomes ralph-loop invocation instead of inline prompt output

**Max Iterations Calculation**:
```
maxIterations = totalTasks * maxTaskIterations * 2
```
The 2x buffer accounts for retries, verification failures, and fix-task generation.

**Ralph Wiggum Invocation**:
```
/ralph-loop "<coordinator-prompt>" --max-iterations $maxIterations --completion-promise "ALL_TASKS_COMPLETE"
```

**Dependency Check**:
```markdown
## Check Ralph Wiggum Dependency

Before invoking /ralph-loop, verify the Ralph Wiggum plugin is installed.

If /ralph-loop is not available:

ERROR: Ralph Wiggum plugin required but not installed.

Install the dependency:
  /plugin install ralph-wiggum@claude-plugins-official

Then retry:
  /ralph-specum:implement
```

### Component 2: stop-watcher.sh (Passive Observer)

**Purpose**: Log execution state and clean up orphaned files (NO loop control)

**Responsibilities**:
- Read `.ralph-state.json` for logging purposes
- Log current state to stderr (spec name, task progress, iteration)
- Clean orphaned `.progress-task-*.md` files older than 60 minutes
- Detect ALL_TASKS_COMPLETE in transcript (backup termination)
- Validate state file JSON integrity
- Check plugin enabled/disabled setting

**What to REMOVE**:
- The `cat <<EOF ... EOF` block that outputs continuation prompts (lines 144-161 in current)
- The `if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]` block that outputs prompts

**What to KEEP**:
- jq availability check
- CWD extraction from hook input
- Path resolver sourcing
- Settings file check (enabled/disabled)
- Spec path resolution via `ralph_resolve_current`
- State file existence check
- Race condition safeguard (stat/sleep)
- ALL_TASKS_COMPLETE transcript detection
- State file JSON validation
- State reading for logging (phase, taskIndex, totalTasks, taskIteration)
- Global iteration limit check (output ERROR, exit 0)
- Logging line: `echo "[ralph-specum]..." >&2`
- Orphaned temp file cleanup

### Component 3: cancel.md (Dual Cleanup)

**Purpose**: Cancel Ralph Wiggum loop AND clean up spec state

**Responsibilities**:
- Resolve target spec (from arguments or `.current-spec`)
- Invoke `/cancel-ralph` to stop Ralph Wiggum loop
- Delete `.ralph-state.json`
- Remove spec directory (`rm -rf $spec_path`)
- Clear `.current-spec` marker
- Update Spec Index
- Report cancellation status

**Key Changes from Current**:
- ADD: `/cancel-ralph` invocation via Skill tool before file cleanup
- KEEP: All existing file cleanup logic
- KEEP: Multi-directory resolution
- KEEP: Spec Index update

### Component 4: Version and Documentation

**Purpose**: Signal breaking change and document dependency

**Changes**:
- plugin.json: version 3.1.1 -> 4.0.0
- marketplace.json: version 3.1.1 -> 4.0.0
- README.md: Add Ralph Wiggum dependency section, installation instructions
- CLAUDE.md: Update Dependencies section

## Data Flow

```
User: /ralph-specum:implement
         │
         ▼
implement.md:
  1. Validate spec exists, tasks.md exists
  2. Check Ralph Wiggum plugin available
  3. Parse arguments
  4. Write .ralph-state.json
  5. Calculate maxIterations
  6. /ralph-loop "<coordinator-prompt>" --max-iterations N --completion-promise "ALL_TASKS_COMPLETE"
         │
         ▼
Ralph Wiggum:
  1. Creates .claude/ralph-loop.local.md
  2. Injects coordinator prompt
         │
         ▼
Claude processes coordinator prompt:
  1. Read .ralph-state.json for taskIndex
  2. Parse tasks.md for current task
  3. Delegate to spec-executor via Task tool
  4. spec-executor completes, outputs TASK_COMPLETE
  5. Coordinator verifies (4 layers), updates state
         │
         ▼
Claude attempts to exit
         │
         ▼
Ralph Wiggum stop-hook:
  - Checks completion-promise not found
  - Increments iteration
  - Re-injects coordinator prompt
         │
stop-watcher.sh (our hook, PASSIVE):
  - Logs state to stderr
  - Cleans orphaned files
  - Does NOT output anything to stdout
         │
         ▼
Loop continues until ALL_TASKS_COMPLETE or max-iterations
         │
         ▼
Coordinator outputs ALL_TASKS_COMPLETE
  - Ralph Wiggum detects completion-promise
  - Deletes .claude/ralph-loop.local.md
  - Loop terminates
```

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Stop-watcher role | Delete entirely vs. make passive | Make passive | Preserves logging, cleanup, and ALL_TASKS_COMPLETE backup detection |
| Coordinator prompt location | Separate file vs. inline in implement.md | Inline in implement.md | Matches v2.0.0 pattern, single file to maintain |
| Hook conflict resolution | Remove our Stop hook vs. make passive | Make passive | Keep SessionStart hook; passive Stop hook adds value (logging + cleanup) |
| Version bump | 3.2.0 vs 4.0.0 | 4.0.0 | Breaking change: requires external dependency |
| Max iterations | Fixed vs. dynamic | Dynamic (totalTasks * maxTaskIterations * 2) | Matches v2.0.0 approach, accounts for retries |
| Test strategy | Delete loop tests vs. update | Update to verify passive behavior | Ensures no regression in passive mode |

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/commands/implement.md` | Modify | Add Ralph Wiggum dependency check, change output to /ralph-loop invocation |
| `plugins/ralph-specum/commands/cancel.md` | Modify | Add /cancel-ralph invocation before file cleanup |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Modify | Remove loop control output, keep logging + cleanup |
| `plugins/ralph-specum/.claude-plugin/plugin.json` | Modify | Version 3.1.1 -> 4.0.0 |
| `.claude-plugin/marketplace.json` | Modify | Version 3.1.1 -> 4.0.0 |
| `README.md` | Modify | Add Ralph Wiggum dependency, breaking change docs |
| `CLAUDE.md` | Modify | Update Dependencies section |
| `tests/stop-hook.bats` | Modify | Update tests for passive stop-watcher |

## Error Handling

| Error | Handling | User Impact |
|-------|----------|-------------|
| Ralph Wiggum not installed | Fail fast with install instructions | "ERROR: Ralph Wiggum plugin required. Install via /plugin install ralph-wiggum@claude-plugins-official" |
| Hook conflict (both outputting) | stop-watcher outputs nothing to stdout | No conflict - only Ralph Wiggum controls loop |
| --max-iterations=N bug | Document space syntax in implement.md | Implementation uses correct space syntax |
| State file corruption | stop-watcher logs warning, Ralph Wiggum continues | Loop continues with recovery prompt |
| ALL_TASKS_COMPLETE not detected | Ralph Wiggum max-iterations safety | Loop terminates at max iterations |

## Existing Patterns to Follow

- **Coordinator-worker**: Task tool delegation to spec-executor/qa-engineer (preserve)
- **Fresh context per task**: Task tool isolation (preserve)
- **State-driven execution**: .ralph-state.json source of truth (preserve)
- **4-layer verification**: Contradiction, uncommitted, checkmarks, signal (preserve in coordinator prompt)
- **POC-first phases**: Tasks follow 4-phase structure
- **Conventional commits**: feat/fix/refactor/chore/test/docs prefixes
- **Version bump protocol**: Both plugin.json AND marketplace.json updated together

## Hook Coexistence

Both Ralph Wiggum and our plugin register Stop hooks. Claude Code runs ALL registered Stop hooks on session stop.

**Order of execution** (both fire):
1. Ralph Wiggum stop-hook: Checks completion, re-injects prompt or allows exit
2. Our stop-watcher.sh: Logs state, cleans up orphans, outputs nothing

**No conflict** because:
- Our stop-watcher.sh will NOT output anything to stdout (passive)
- Only Ralph Wiggum's stop-hook outputs continuation prompts
- Our stop-watcher.sh writes only to stderr (logging)
- SessionStart hook (load-spec-context.sh) is unaffected

## Migration Notes

### For Users

1. Install Ralph Wiggum before upgrading:
   ```
   /plugin install ralph-wiggum@claude-plugins-official
   ```
2. Existing in-progress specs may need re-initialization with `/ralph-specum:implement`
3. `/cancel` now also calls `/cancel-ralph`

### Breaking Changes from v3.1.1

1. **Requires Ralph Wiggum plugin**: Must be installed separately
2. **Stop-watcher passive**: No longer controls execution loop
3. **State coexistence**: `.claude/ralph-loop.local.md` added by Ralph Wiggum
