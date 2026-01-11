---
description: Approve current phase and continue to next (interactive mode only).
argument-hint: [--dir ./spec-dir]
---

# Approve Phase

Approve the current phase and continue to the next phase.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **dir**: Spec directory path (default: `./spec`)

## Actions

1. Read `.ralph-state.json` from spec directory
2. Verify mode is `interactive`
3. Mark current phase as approved in `phaseApprovals`
4. Advance to next phase:
   - requirements → design
   - design → tasks
   - tasks → execution

5. Update `.ralph-state.json`
6. Trigger compaction with phase-specific preservation:

### Compaction by Phase

**After Requirements:**
```
/compact preserve: user stories, acceptance criteria (AC-*), functional requirements (FR-*), non-functional requirements (NFR-*), glossary terms. Read .ralph-progress.md for context.
```

**After Design:**
```
/compact preserve: architecture decisions, component boundaries, file paths to modify, patterns. Read .ralph-progress.md for context.
```

**After Tasks:**
```
/compact preserve: task list with IDs, dependencies, quality gates. Read .ralph-progress.md for context.
```

7. Output: "Phase approved. Continuing to <next_phase>..."

## Interactive Flow

When a phase completes in interactive mode, you can:
1. **Discuss/revise**: Give feedback, Claude will update the phase docs
2. **Approve**: Run this command to advance to next phase with compaction

No need to approve if you want to keep iterating on current phase.

## Error Cases

- If no state file: "No active Ralph loop. Start with /ralph-specum."
- If mode is `auto`: "Approval not needed in autonomous mode."
- If already in execution: "All phases approved. Execution in progress."
