# Loop Safety Infrastructure — Reference Documentation

## Decision Log

### Decision 1: Absolute Consecutive Count vs. Error-Percentage Model
**Rationale**: Simple consecutive count is easier to implement and reason about. Error-percentage models require tracking total tasks vs failures, which adds complexity without proportional benefit for the failure modes we're protecting against.

### Decision 2: No HALF_OPEN State
**Rationale**: The circuit breaker only has CLOSED and OPEN states. No automatic reset — human must explicitly reset via state file modification. This prevents premature resumption after repeated failures.

### Decision 3: Append-only to stop-watcher.sh
**Rationale**: stop-watcher.sh is a critical hook that runs on every task. Modifying existing code introduces regression risk. All new safety mechanisms are appended as functions at the end of the file.

### Decision 4: Heartbeat Always Runs (Including First Iteration)
**Rationale**: Filesystem health is a prerequisite for all other operations. Skipping the first iteration would miss early read-only filesystem errors.

### Decision 5: Manual Circuit Breaker Reset Only
**Rationale**: No timer-based or automatic reset. After a circuit breaker opens, the human must manually reset it by modifying `.ralph-state.json`. This ensures deliberate review of failure patterns.

### Decision 6: JSONL for Metrics, Not JSON Array
**Rationale**: JSONL (JSON Lines) allows atomic appends without file locking across process boundaries. JSON arrays would require read-modify-write cycles that are prone to corruption under concurrent access.

### Decision 6.5: jq Version Compatibility
**Rationale**: All scripts check for jq 1.5+ which supports `--arg`. On older systems, a warning is emitted but execution continues (graceful degradation).

### Decision 7: CI Discovery Scope Limited to `.github/workflows/*.yml` and `tests/*.bats`
**Rationale**: Narrow scope reduces false positives. Other CI systems (Jenkins, GitLab CI) are out of scope for this iteration.

## Recovery Procedures

### Circuit Breaker Recovery
1. Read `.ralph-state.json`
2. Inspect `circuitBreaker.trippedReason` for failure cause
3. Fix underlying issue
4. Manually reset: `jq '.circuitBreaker.state = "closed" | .circuitBreaker.consecutiveFailures = 0' .ralph-state.json > tmp && mv tmp .ralph-state.json`
5. Resume with `/ralph-specum:implement`

### Filesystem Health Recovery
1. Check filesystem: `mount | grep "$(df "$spec_dir" | tail -1 | awk '{print $1}')"`
2. If read-only: `sudo mount -o remount,rw /path/to/mount`
3. Or resume with `/ralph-specum:cancel` and re-run in a writable environment

### Checkpoint Recovery
1. If checkpoint SHA is null (no git repo or detached HEAD), checkpoint-rollback cannot proceed
2. Initialize git repo or checkout a branch first
3. Re-run checkpoint-create manually

## Configuration Defaults

| Parameter | Default | Description |
|-----------|---------|-------------|
| maxConsecutiveFailures | 5 | Circuit breaker trip threshold |
| maxSessionSeconds | 172800 | Session timeout (48 hours) |
| heartbeatTimeout | N/A | Heartbeat always runs, no timeout |
| filesystemHealthFailures | 3 | Full block after 3 consecutive failures |
| checkpointCommit | --no-verify | Checkpoint commit skips hooks |
| metricsFile | .metrics.jsonl | Per-spec metrics file |
| ciDiscoveryPaths | .github/workflows/*.yml, tests/*.bats | CI command sources |

## State File Fields

### checkpoint
```json
{
  "sha": "full-40-char-git-sha",
  "timestamp": "ISO-8601-UTC",
  "branch": "current-branch",
  "message": "checkpoint message"
}
```

### circuitBreaker
```json
{
  "state": "closed|open",
  "consecutiveFailures": 0,
  "sessionStartTime": "ISO-8601-UTC",
  "openedAt": "ISO-8601-UTC|null",
  "trippedReason": "string|null",
  "maxConsecutiveFailures": 5,
  "maxSessionSeconds": 172800
}
```

### filesystem Health
```json
{
  "filesystemHealthy": true,
  "filesystemHealthFailures": 0,
  "lastFilesystemCheck": "ISO-8601-UTC|null"
}
```

### ciCommands
```json
["command1", "command2", ...]
```
