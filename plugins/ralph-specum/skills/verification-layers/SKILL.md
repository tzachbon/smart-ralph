---
name: verification-layers
description: >-
  This skill should be used when the user asks about "verification layers",
  "task completion verification", "4-layer verification", "contradiction detection",
  "checkmark verification", "completion signal validation", or needs guidance on
  validating task completion before advancing state in spec-driven workflows.
version: 0.1.0
---

# Verification Layers Pattern

4-layer verification pattern to validate task completion before advancing taskIndex. All layers must pass before state is updated.

## Overview

CRITICAL: Run these 4 verifications BEFORE advancing taskIndex. All must pass.

```text
┌─────────────────────────────────────────────────────────────┐
│              4-LAYER VERIFICATION PIPELINE                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. CONTRADICTION Detection                                  │
│     └── No "requires manual" + TASK_COMPLETE                │
│                                                              │
│  2. UNCOMMITTED Changes Check                                │
│     └── spec files (tasks.md, .progress.md) committed       │
│                                                              │
│  3. CHECKMARK Verification                                   │
│     └── checkmark count == taskIndex + 1                    │
│                                                              │
│  4. COMPLETION Signal Verification                           │
│     └── explicit TASK_COMPLETE present                      │
│                                                              │
│  ═══════════════════════════════════════════════════════════│
│                                                              │
│  ALL PASS  ────►  Advance taskIndex                         │
│  ANY FAIL  ────►  Increment taskIteration, retry            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer 1: Contradiction Detection

Check spec-executor output for contradiction patterns that indicate false completion claims.

### Contradiction Phrases

Look for these phrases in the executor output:

- `"requires manual"`
- `"cannot be automated"`
- `"could not complete"`
- `"needs human"`
- `"manual intervention"`

### Detection Logic

```text
IF TASK_COMPLETE appears alongside ANY contradiction phrase:
  → REJECT the completion
  → Log: "CONTRADICTION: claimed completion while admitting failure"
  → Increment taskIteration and retry
```

### Example Contradiction

Bad output (should be rejected):
```text
The task requires manual verification but I completed the code changes.

TASK_COMPLETE
```

Good output (should pass):
```text
Task 2.1: Add verification layers - DONE
Verify: PASSED
Commit: abc1234

TASK_COMPLETE
```

---

## Layer 2: Uncommitted Spec Files Check

Before advancing, verify spec files are committed. Task is not truly complete until all changes are persisted.

### Check Command

```bash
git status --porcelain ./specs/$spec/tasks.md ./specs/$spec/.progress.md
```

### Detection Logic

```text
IF output is non-empty (uncommitted changes exist):
  → REJECT the completion
  → Log: "uncommitted spec files detected - task not properly committed"
  → Increment taskIteration and retry
```

### Rationale

All spec file changes must be committed before task is considered complete:
- `tasks.md` - must have checkmark `[x]` committed
- `.progress.md` - must have completion entry committed

This ensures progress survives context resets and session restarts.

---

## Layer 3: Checkmark Verification

Count completed tasks in tasks.md and verify it matches expected count.

### Check Command

```bash
grep -c '\- \[x\]' ./specs/$spec/tasks.md
```

### Expected Count Calculation

```text
expected_checkmarks = taskIndex + 1

(0-based index: task 0 complete = 1 checkmark)
```

### Detection Logic

```text
IF actual_count != expected_checkmarks:
  → REJECT the completion
  → Log: "checkmark mismatch: expected $expected, found $actual"
  → Increment taskIteration and retry
```

### Purpose

This layer detects:
- State manipulation (executor lying about completion)
- Incomplete task marking (forgot to mark `[x]`)
- Multiple tasks marked in single iteration

---

## Layer 4: Completion Signal Verification

Verify spec-executor explicitly output TASK_COMPLETE.

### Required Signal

```text
TASK_COMPLETE
```

### Detection Logic

```text
IF TASK_COMPLETE not present in output:
  → Do NOT advance
  → Log: "missing TASK_COMPLETE signal"
  → Increment taskIteration and retry
```

### Important Notes

- Must be explicit, not implied
- Partial completion is not valid
- Silent completion is not valid
- The signal must be unambiguous

---

## Verification Summary

All 4 layers must pass for task to be considered complete:

| Layer | Check | On Failure |
|-------|-------|------------|
| 1. Contradiction | No contradiction phrases with completion claim | Reject, retry |
| 2. Uncommitted | Spec files committed (no uncommitted changes) | Reject, retry |
| 3. Checkmark | Checkmark count matches expected taskIndex + 1 | Reject, retry |
| 4. Signal | Explicit TASK_COMPLETE signal present | Reject, retry |

### After All Pass

Only after all verifications pass, proceed to state update:
1. Increment taskIndex
2. Reset taskIteration to 1
3. Continue to next task or completion

---

## Implementation Pattern

```text
function verifyTaskCompletion(spec, taskIndex, executorOutput):

  # Layer 1: Contradiction Detection
  contradictions = ["requires manual", "cannot be automated",
                    "could not complete", "needs human", "manual intervention"]

  for phrase in contradictions:
    if phrase in executorOutput AND "TASK_COMPLETE" in executorOutput:
      return FAIL("CONTRADICTION: claimed completion while admitting failure")

  # Layer 2: Uncommitted Spec Files
  uncommitted = run("git status --porcelain ./specs/{spec}/tasks.md ./specs/{spec}/.progress.md")
  if uncommitted.length > 0:
    return FAIL("uncommitted spec files detected - task not properly committed")

  # Layer 3: Checkmark Verification
  actualCheckmarks = run("grep -c '\\- \\[x\\]' ./specs/{spec}/tasks.md")
  expectedCheckmarks = taskIndex + 1
  if actualCheckmarks != expectedCheckmarks:
    return FAIL("checkmark mismatch: expected {expected}, found {actual}")

  # Layer 4: Completion Signal
  if "TASK_COMPLETE" not in executorOutput:
    return FAIL("missing TASK_COMPLETE signal")

  return PASS
```

---

## Error Recovery

When any layer fails:

1. Log the specific failure reason
2. Increment `taskIteration` in state file
3. Check against `maxTaskIterations` limit
4. If under limit: retry the same task
5. If over limit: output error and stop

The retry mechanism allows transient failures to self-correct while preventing infinite loops.
