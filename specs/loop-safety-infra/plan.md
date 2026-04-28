# Spec: loop-safety-infra

Epic: specs/_epics/engine-roadmap-epic/epic.md

## Goal
Add Bmalph-style pre-loop git checkpoint, circuit breaker, per-task metrics, read-only detection, and CI snapshot tracking to the execution loop.

## Acceptance Criteria
1. Pre-loop git checkpoint stores SHA in .ralph-state.json
2. Circuit breaker stops after N consecutive failures (default 5) or N hours (default 48h)
3. `.metrics.jsonl` file exists after execution with per-task entries
4. Read-only detection at loop start via heartbeat write check
5. CI snapshot tracking: auto-detects CI commands, records global CI state

## Interface Contracts
### Reads
- `hooks/scripts/stop-watcher.sh` — current content for context
- `schemas/spec.schema.json` — current content for context
- `commands/implement.md` — current content for context

### Writes
- `references/loop-safety.md` — NEW FILE
- `hooks/scripts/checkpoint.sh` — NEW FILE
- `hooks/scripts/stop-watcher.sh` — append safety functions
- `schemas/spec.schema.json` — add `ciCommands: string[]`
- `commands/implement.md` — add pre-loop git checkpoint step

## Dependencies
Spec 1 (schema fields nativeTaskMap, nativeSyncEnabled, nativeSyncFailureCount)
