# Research: Circuit Breaker for Execution Loop Safety

## 1. Circuit Breaker Pattern Fundamentals

The circuit breaker is a resilience pattern that prevents repeated operations likely to fail. It operates as a three-state finite state machine:

### States

**CLOSED** (normal operation)
- All requests pass through to the executor
- Failures are counted
- When failure count reaches threshold, transitions to OPEN

**OPEN** (blocking)
- All requests fail immediately without invoking the executor
- Returns an error/excption instantly, preserving system resources
- A timer runs; when it expires, transitions to HALF_OPEN

**HALF_OPEN** (probe)
- A limited number of probe requests are allowed through
- If probes succeed, transitions to CLOSED (failure counter resets)
- If any probe fails, transitions back to OPEN (timer restarts)

### State Transitions

```
                failure_threshold reached
  CLOSED -------------------------> OPEN
    ^                               |
    |  success_threshold reached     |  wait_timeout elapsed
    |                               v
    <----------------------- HALF_OPEN
```

This model applies directly to Smart Ralph's execution loop:
- **CLOSED** = normal task execution continues
- **OPEN** = execution loop is blocked, stop-watcher.sh outputs an escalation block
- **HALF_OPEN** = allow one task to proceed as a "probe"; if it succeeds, resume normal flow

## 2. Consecutive Failure Counting Strategies

### Strategy A: Simple Consecutive Counting

Track a counter that increments on each task failure and resets on success.

```
consecutiveFailures += 1 on task failure
consecutiveFailures = 0 on task success
trip when consecutiveFailures >= threshold (default: 5)
```

**Pros:** Simple, easy to implement in bash + JSON
**Cons:** A single success resets everything — an oscillating failure/success pattern never trips

### Strategy B: Sliding Window Counting

Track failures within a time window. Trip if failure rate within the window exceeds a threshold.

```
record: [ {timestamp, success: false}, {timestamp, success: true}, ... ]
count failures in last N minutes
trip when failure_rate >= threshold%
```

**Pros:** Handles oscillating patterns better; accounts for recency
**Cons:** More complex state; requires timestamp tracking per event

### Strategy C: Weighted Counting (Recommended)

Combine consecutive and time-weighted counting. Recent failures count more than older ones.

```
weight = { latest: 1.0, older: 0.5 }
trip when weighted_failure_count >= threshold
reset when success_count >= success_threshold
```

### Recommendation for Smart Ralph

**Strategy A (simple consecutive counting)** is the best fit because:
1. The execution loop processes tasks sequentially — there is no "parallel noise" that could create oscillating patterns
2. If a task fails 5 times consecutively, it is genuinely stuck (not transient)
3. The `taskIteration` field in `.ralph-state.json` already tracks per-task retry counts
4. The stop-watcher.sh already reads `taskIteration` and compares it against `maxTaskIterations`

The circuit breaker tracks **cross-task** consecutive failures, complementing the existing **per-task** retry limit:

- Per-task limit: 5 retries for task T3 (configurable via `maxTaskIterations`)
- Circuit breaker: 5 consecutive task failures across any tasks (new field)

## 3. Time-Based Timeout Patterns

### Hystrix Approach

Hystrix uses a `executionIsolationSemaphoreTimeoutMs` (default 1000ms). If execution exceeds this timeout, the call is aborted and counted as a failure. This is a **per-operation** timeout.

### resilience4j Approach

resilience4j uses `waitDurationInOpenState` (default 5s) — the cooldown period in the OPEN state before transitioning to HALF_OPEN. This is a **state-transition** timeout.

### Azure/Enterprise Approach

The Azure Architecture Center describes an adaptive timeout: "You can apply an increasing time-out timer to a circuit breaker. Place it in the Open state for a few seconds initially. If the failure isn't resolved, increase the timeout to a few minutes."

### Recommendation for Smart Ralph

Smart Ralph's loop operates at the session level, not the per-operation level. The relevant timeout is:

1. **Per-session timeout:** Maximum wall-clock time the entire spec execution can run before the circuit breaker trips (default: 48 hours). This prevents runaway execution if the loop gets stuck in a pattern that doesn't trigger the consecutive-failure count (e.g., alternating success/failure across different tasks).

2. **Per-repair-loop timeout:** The existing repair iteration mechanism (max 2 iterations per verification failure) already handles this. The circuit breaker is a broader safety net.

3. **State-transition timeout:** When the circuit opens, it stays open until a human intervenes. There is no automatic HALF_OPEN transition because the executor is a deterministic AI agent — if it was stuck 5 tasks ago, it will likely be stuck again.

```
State transitions:
  CLOSED -> OPEN:    consecutive_failures >= 5  OR  session_duration >= 48h
  OPEN -> CLOSED:    manual reset only (human intervention)
  OPEN -> HALF_OPEN: not applicable (deterministic agent, no automatic probe)
```

## 4. How Other Frameworks Implement Circuit Breakers

### Apache Hystrix

```java
// Key configuration properties
hystrix.command.default.circuitBreaker.requestVolumeThreshold = 20    // min calls in window
hystrix.command.default.circuitBreaker.errorThresholdPercentage = 50   // error % to trip
hystrix.command.default.circuitBreaker.sleepWindowInMilliseconds = 5000 // cooldown
hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds = 1000
```

**Key design decisions:**
- Requires minimum number of calls before evaluating (avoids tripping on one-off failures)
- Uses error **percentage** rather than absolute count
- Sleep window (5s) before retrying
- Supports forced open/closed overrides for operator control

### resilience4j (Java)

```java
CircuitBreakerConfig config = CircuitBreakerConfig.custom()
    .failureRateThreshold(50)           // 50% failure rate threshold
    .slidingWindowSize(10)              // sliding window of 10 calls
    .slidingWindowType(TIME_BASED)      // or COUNT_BASED
    .minimumNumberOfCalls(10)           // min calls before evaluation
    .permittedNumberOfCallsInHalfOpenState(3)  // probe calls in HALF_OPEN
    .waitDurationInOpenState(Duration.ofSeconds(10))
    .automaticTransitionFromOpenToHalfOpenEnabled(true)
    .recordExceptions(Throwable.class)  // which exceptions count as failures
    .ignoreExceptions(IllegalArgumentException.class)  // which don't
```

**Key design decisions:**
- Two sliding window modes: count-based (fixed number of calls) or time-based (calls in last N seconds)
- Half-open state is automatic (after wait duration) or manual (requires trigger)
- Fine-grained exception classification (some exceptions trip, others don't)
- Half-open state permits limited probe calls (default 3)

### Polly (.NET / The Polly Project)

```csharp
var circuitBreaker = Policy
    .Handle<HttpRequestException>()
    .CircuitBreaker(
        exceptionsAllowedBeforeBreaking: 5,
        durationOfBreak: TimeSpan.FromSeconds(30),
        onBreak: (ex, breakDelay) => LogBreak(ex, breakDelay),
        onReset: () => LogReset()
    );
```

**Key design decisions:**
- Fluent API for composition
- Events for state transitions (on_break, on_reset)
- Supports advanced patterns: fallback, retry, bulkhead isolation
- `BulkheadParallel` variant for concurrent request limiting

### Go stdlib (x/exp/sync)

Go's standard library does not include a circuit breaker. Popular third-party implementations like `sony/gobreaker` use:

```go
settings := Settings{
    Name:          "MyCircuitBreaker",
    Timeout:       100 * time.Millisecond,
    MaxRequests:   3,
    Rate:          1.0,
    Interval:      100 * time.Millisecond,
}
cb := New(settings)
```

**Key design decisions:**
- Sliding window based on time intervals
- Maximum concurrent requests (bulkhead pattern)
- Rate-based failure tracking

### Key Takeaways for Smart Ralph

| Feature | Hystrix | resilience4j | Polly | Smart Ralph |
|---------|---------|-------------|-------|-------------|
| Failure threshold | Error % (50%) | Error % (50%) | Absolute count (5) | Absolute count (5) |
| Min calls before eval | 20 | 10 | N/A | N/A (sequential) |
| Time-based window | No | Yes (sliding) | No | No (session-level) |
| Automatic recovery | Yes (5s sleep) | Yes (configurable) | No | No (manual) |
| Half-open state | Yes | Yes | No | No (not needed) |
| Force open/reset | Yes | Yes | Yes | Yes (manual) |
| Exception classification | Yes | Yes | Yes | N/A |
| Concurrency support | Semaphore | Bulkhead | Policy composition | N/A (sequential) |

## 5. State Tracking: Where to Store Failure Counts and Timestamps

### Option A: Inline in `.ralph-state.json`

Add circuit breaker fields directly to the existing state file:

```json
{
  "circuitBreaker": {
    "state": "closed",
    "consecutiveFailures": 0,
    "lastFailureAt": null,
    "sessionStartTime": "2026-04-26T10:00:00Z",
    "openedAt": null,
    "trippedReason": null
  }
}
```

**Pros:** Single source of truth, already read by stop-watcher.sh, no new files
**Cons:** Clutters state schema, couples circuit breaker to spec state

### Option B: Separate file `.circuit-breaker.json`

```json
{
  "state": "closed",
  "consecutiveFailures": 0,
  "lastFailureAt": null,
  "sessionStartTime": "2026-04-26T10:00:00Z",
  "openedAt": null,
  "trippedReason": null,
  "specName": "prompt-diet-refactor"
}
```

**Pros:** Clean separation of concerns, independent lifecycle
**Cons:** Two state files to coordinate, risk of desync

### Option C: Appendix in `.progress.md`

Append circuit breaker state as a section in the progress file.

**Pros:** Human-readable, no extra file
**Cons:** Harder to parse programmatically, not JSON

### Recommendation: Option A (inline in `.ralph-state.json`)

The circuit breaker is tightly coupled to spec execution. Inline state keeps everything in one file that stop-watcher.sh already reads. The fields should be:

```json
"circuitBreaker": {
  "state": "closed",              // closed | open | manual_reset_requested
  "consecutiveFailures": 0,        // incremented per failed task
  "sessionStartTime": 1745673600,  // epoch seconds (ISO in human-readable output)
  "openedAt": null,               // epoch seconds when circuit opened
  "trippedReason": null,          // "consecutive_failures" | "session_timeout"
  "maxConsecutiveFailures": 5,    // configurable threshold
  "maxSessionSeconds": 172800     // 48 hours in seconds, configurable
}
```

## 6. Recovery Strategies

### Recovery from OPEN State

In distributed systems, automatic recovery (HALF_OPEN) works because external services may heal on their own. For Smart Ralph, the "service" is the spec-executor AI agent, which is deterministic. If it failed 5 tasks in a row, it will fail again unless:

1. The spec itself was corrected (tasks.md updated)
2. The environment was fixed
3. A human reviewed and intervened

**Recovery flow:**

```
1. Circuit is OPEN → stop-watcher.sh outputs ESCALATION block
2. Human reviews:
   a. Read .progress.md for failure details
   b. Read tasks.md at the failing task index
   c. Decide: fix spec, skip task, or modify tasks
3. Human resets circuit:
   a. Edit .ralph-state.json: circuitBreaker.state = "closed"
   b. Edit: circuitBreaker.consecutiveFailures = 0
   c. Edit: circuitBreaker.openedAt = null
   d. Edit: circuitBreaker.trippedReason = null
4. Resume: /ralph-specum:implement
```

### Manual Override Commands

Two manual override states:

1. **`manual_reset_requested`** — Human signals "I've fixed the issue, try again"
   - stop-watcher.sh sees this state and allows execution to proceed
   - Circuit breaker starts counting from zero again
   - If it trips again, output escalation with `circuit_breaker_retripped: true`

2. **`manual_skip`** — Human signals "skip the current task, continue"
   - Task index advances by 1, consecutiveFailures resets to 0
   - Used when a task is fundamentally broken and needs spec revision

### Reset API (for human intervention)

The stop-watcher.sh should provide clear reset instructions:

```
## Recovery
1. Edit .ralph-state.json:
   - Set circuitBreaker.state = "closed"
   - Set circuitBreaker.consecutiveFailures = 0
   - Set circuitBreaker.openedAt = null
   - Set circuitBreaker.trippedReason = null
2. Resume with /ralph-specum:implement
```

## 7. Recommendations for stop-watcher.sh Implementation

### Placement

Add circuit breaker logic **after** the global iteration limit check (line ~460) and **before** the role boundaries validation (line ~494). This ensures:
- It runs on every loop iteration
- It does not block during phase generation (research, requirements, etc.)
- It does not interfere with the existing global iteration safety net

### Pseudocode

```bash
# === Circuit Breaker Check ===
CB_STATE_FILE="$CWD/$SPEC_PATH/.ralph-state.json"

# Read circuit breaker state (inline in state file)
CB_STATE=$(jq -r '.circuitBreaker.state // "closed"' "$CB_STATE_FILE" 2>/dev/null)
CB_FAILURES=$(jq -r '.circuitBreaker.consecutiveFailures // 0' "$CB_STATE_FILE" 2>/dev/null)
CB_OPENED_AT=$(jq -r '.circuitBreaker.openedAt // null' "$CB_STATE_FILE" 2>/dev/null)
CB_REASON=$(jq -r '.circuitBreaker.trippedReason // null' "$CB_STATE_FILE" 2>/dev/null)
CB_MAX_FAILURES=$(jq -r '.circuitBreaker.maxConsecutiveFailures // 5' "$CB_STATE_FILE" 2>/dev/null)
CB_MAX_SECONDS=$(jq -r '.circuitBreaker.maxSessionSeconds // 172800' "$CB_STATE_FILE" 2>/dev/null)
CB_SESSION_START=$(jq -r '.circuitBreaker.sessionStartTime // empty' "$CB_STATE_FILE" 2>/dev/null)

NOW=$(date +%s)

case "$CB_STATE" in
    "closed")
        # Check trip conditions
        
        # Condition 1: Consecutive failures
        if [ "$CB_FAILURES" -ge "$CB_MAX_FAILURES" ]; then
            jq --argjson now "$NOW" \
               '.circuitBreaker.state = "open" |
                .circuitBreaker.openedAt = $now |
                .circuitBreaker.trippedReason = "consecutive_failures"' \
               "$CB_STATE_FILE" > /tmp/cb_tmp.json && mv /tmp/cb_tmp.json "$CB_STATE_FILE"
            
            ESCALATE_REASON="..."  # escalation block
            jq -n --arg reason "$ESCALATE_REASON" ... # output block
            exit 0
        fi
        
        # Condition 2: Session timeout
        if [ -n "$CB_SESSION_START" ]; then
            SESSION_AGE=$((NOW - CB_SESSION_START))
            if [ "$SESSION_AGE" -ge "$CB_MAX_SECONDS" ]; then
                jq --arg now "$NOW" \
                   '.circuitBreaker.state = "open" |
                    .circuitBreaker.openedAt = $now |
                    .circuitBreaker.trippedReason = "session_timeout"' \
                   "$CB_STATE_FILE" > /tmp/cb_tmp.json && mv /tmp/cb_tmp.json "$CB_STATE_FILE"
                
                ESCALATE_REASON="..."  # escalation block
                jq -n --arg reason "$ESCALATE_REASON" ... # output block
                exit 0
            fi
        fi
        ;;
    
    "open")
        # Circuit already open — this should not be reached during normal execution
        # stop-watcher.sh should have exited after opening. If we get here,
        # it means the state was manually modified but not fully reset.
        # Allow exit to prevent infinite blocking.
        echo "[ralph-specum] Circuit breaker is OPEN (reason: $CB_REASON)" >&2
        exit 0
        ;;
esac

# === On Task Completion: Update Circuit Breaker State ===
# (This runs in the coordinator after TASK_COMPLETE signal)
# 
# On TASK_COMPLETE with status=pass:
#   CB_FAILURES = 0 (reset consecutive failures)
#
# On TASK_COMPLETE with status=fail or on retry exhaustion:
#   CB_FAILURES += 1
#
# On ESCALATE or loop abort:
#   No state change (failures persist)
```

### Integration with Existing Retry Mechanism

The circuit breaker tracks **cross-task** consecutive failures. It should be updated in coordination with the stop-watcher.sh's own logic:

```
On VERIFICATION_FAIL detected:
  → repair loop runs
  → On repair success: reset circuit consecutiveFailures = 0
  → On repair exhaustion: increment circuit consecutiveFailures += 1

On task-level failure (taskIteration >= maxTaskIterations):
  → spec-executor ESCALATEs
  → stop-watcher.sh increments circuit consecutiveFailures += 1
  
On TASK_COMPLETE (pass):
  → reset circuit consecutiveFailures = 0
```

### Escalation Block Format

When the circuit opens, output:

```json
{
  "decision": "block",
  "reason": "[ralph-specum] CIRCUIT BREAKER OPEN — tripped after 5 consecutive task failures\n\n## State\nSpec: $SPEC_NAME | Consecutive failures: 5/5 | Reason: consecutive_failures | Session age: 2h15m\n\n## What happened\nThe execution loop has failed 5 consecutive tasks. This is not a single-task issue — the spec as a whole is stuck.\n\n## Action required from human\n1. Read $SPEC_PATH/.progress.md — review all recent failures\n2. Read $SPEC_PATH/tasks.md — identify the failure pattern\n3. Check $SPEC_PATH/requirements.md — verify the spec is feasible\n4. Decide: fix spec, revise tasks, or cancel execution\n5. Reset circuit breaker:\n   - Set circuitBreaker.state = \"closed\"\n   - Set circuitBreaker.consecutiveFailures = 0\n   - Set circuitBreaker.openedAt = null\n   - Set circuitBreaker.trippedReason = null\n6. Resume with /ralph-specum:implement",
  "systemMessage": "Ralph-specum: circuit breaker OPEN (5 consecutive failures)"
}
```

### Configurable Defaults

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxConsecutiveFailures` | 5 | Tasks that must fail consecutively to trip |
| `maxSessionSeconds` | 172800 (48h) | Maximum session wall-clock time |
| `state` | "closed" | Initial state |
| `sessionStartTime` | current epoch | Set on first execution |

These values are read from `.ralph-state.json` but can be set during spec initialization by the coordinator (implement.md).

### Edge Cases to Handle

1. **State file corruption:** If `jq` fails to read circuit breaker fields, default to "closed" with 0 failures (graceful degradation, same as existing error handling)

2. **Session restart:** If a session ends and resumes, `sessionStartTime` persists in the state file. This means the 48h timer is **absolute** (wall-clock from spec start), not relative to last task completion. This is intentional — a 48h timer that resets on each task completion would defeat the purpose.

3. **Multiple specs in parallel:** If parallel execution is active, each spec has its own `.ralph-state.json` and thus its own circuit breaker. No cross-spec circuit breaking is needed.

4. **Epic-level execution:** When specs run as part of an epic, the circuit breaker is **per-spec**, not per-epic. The epic-level failure detection is handled by `.epic-state.json` and the spec dependency graph.

5. **Phase transitions:** The circuit breaker only applies during the "execution" phase. During research/requirements/design/tasks phases, there is no task failure to count. The stop-watcher.sh already gates on `PHASE = "execution"` for most checks.

6. **Manual intervention during OPEN:** If a human modifies the state file while the circuit is open, the stop-watcher.sh should allow exit (not re-block) to avoid infinite blocking. The human can then resume normally.

## 8. Implementation Checklist

1. [ ] Add `circuitBreaker` schema definition to `spec.schema.json`
2. [ ] Initialize circuit breaker fields in coordinator's state file creation (implement.md)
3. [ ] Add circuit breaker check in stop-watcher.sh after global iteration check
4. [ ] Add circuit breaker state update on TASK_COMPLETE (in coordinator)
5. [ ] Add circuit breaker state update on VERIFICATION_FAIL/REPAIR exhaustion
6. [ ] Update escalation blocks with circuit breaker state information
7. [ ] Add circuit breaker reset instructions to all escalation messages
8. [ ] Test: verify circuit opens after 5 consecutive failures
9. [ ] Test: verify circuit opens after 48h session
10. [ ] Test: verify manual reset allows resumption
11. [ ] Test: verify circuit breaker is disabled for non-execution phases
12. [ ] Test: verify circuit breaker does not interfere with repair loops
