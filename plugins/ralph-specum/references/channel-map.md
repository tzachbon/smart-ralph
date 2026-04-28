# Channel Map — Shared Filesystem Channels

> Reference document for protocol decisions, race condition audits, and new agent onboarding.
> When adding a new agent or a new shared file, update this map first.

## Purpose

Smart-ralph agents communicate exclusively via the filesystem. This document is the
authoritative contract for which agent reads and writes which channel, and when.
If a channel has more than one writer, it requires exclusive locking — see the
Locking Strategy column.

## Channel Registry

| Channel | Path | Writer(s) | Reader(s) | Timing | Locking |
|---------|------|-----------|-----------|--------|---------|
| **chat.md** | `<basePath>/chat.md` | coordinator, reviewer | coordinator, reviewer | Before/after every delegation (coordinator); each review cycle (reviewer) | `flock -e 200` on `chat.md.lock` — MANDATORY for all writes |
| **task_review.md** | `<basePath>/task_review.md` | reviewer only | coordinator (Pre-Delegation Check), spec-executor (External Review Protocol step 2b) | Each review cycle (write); before every delegation (read) | Single writer — no locking needed |
| **tasks.md** | `<basePath>/tasks.md` | spec-executor (marks `[x]`), reviewer (unmarks `[x]` on FAIL) | coordinator (taskIndex advance), reviewer (finds unreviewed tasks) | After each task completion (spec-executor write); on FAIL detection (reviewer write) | ⚠️ TWO WRITERS — `flock -e 201` on `tasks.md.lock` MANDATORY for reviewer unmark writes |
| **.progress.md** | `<basePath>/.progress.md` | coordinator, spec-executor, reviewer | coordinator, spec-executor | Continuous | Single logical writer per session (coordinator/executor share a session; reviewer is separate) — append-only reduces collision risk, but review intervention blocks use visible HTML comments as delimiters |
| **.ralph-state.json** | coordinator, spec-executor, reviewer, planning-agents | coordinator (all fields), spec-executor (`chat.executor.lastReadLine`), reviewer (`chat.reviewer.lastReadLine`, `external_unmarks`), planning-agents [`architect-reviewer`, `product-manager`, `research-analyst`, `task-planner`] (`awaitingApproval`) | coordinator, reviewer, spec-executor | Every state transition | coordinator owns all fields except `chat.reviewer.*`, `chat.executor.*`, and `external_unmarks` (reviewer-owned) and `awaitingApproval` (planning-agents-owned) — write via `jq` + `mv` atomic pattern |
| **chat.md.lock** | coordinator, reviewer | — | — | Created on first flock | Lock file only — never read for content |
| **tasks.md.lock** | reviewer | — | — | Created on first reviewer unmark | Lock file only — never read for content |

## Race Condition Risk Register

Channels with more than one writer are the only source of race conditions in this system.

### ⚠️ tasks.md — HIGH RISK

**Writers**: spec-executor (marks `[x]`) + reviewer (unmarks `[x]` on FAIL)

**Risk scenario**: coordinator reads tasks.md to advance taskIndex at the same moment
reviewer is writing an unmark. Without locking, coordinator sees a partially-written
file and may skip the unmark or advance taskIndex incorrectly.

**Mitigation**: reviewer MUST use `flock -e 201` on `tasks.md.lock` for ALL writes to tasks.md.
spec-executor writes only after the coordinator has delegated (sequential by design), so
spec-executor writes do not overlap with reviewer writes in normal operation. The lock
protects the coordinator-reads-while-reviewer-writes scenario.

**Fixed in**: external-reviewer.md v0.2.1 (Section 6b)

### ⚠️ chat.md — MEDIUM RISK (mitigated)

**Writers**: coordinator + reviewer (both append messages concurrently)

**Risk scenario**: without locking, two concurrent appends could interleave bytes,
producing a malformed message in chat.md.

**Mitigation**: ALL writes to chat.md use `flock -e 200` on `chat.md.lock`.
Both coordinator and reviewer use this pattern. See coordinator-pattern.md Chat Protocol
and external-reviewer.md Section 7.

**Fixed in**: coordinator-pattern.md (Chat Protocol), external-reviewer.md v0.2.0 (Section 7)

### ✅ .ralph-state.json — LOW RISK (ownership-partitioned)

**Writers**: coordinator (owns all fields), spec-executor (`chat.executor.lastReadLine`), reviewer (`chat.reviewer.*` and `external_unmarks`), planning-agents [`architect-reviewer`, `product-manager`, `research-analyst`, `task-planner`] (`awaitingApproval`)

**Risk**: coordinator, reviewer, spec-executor, and planning-agents may write simultaneously.

**Mitigation**: field ownership partitioning — each agent only touches its own fields via
the `jq` + `mv` atomic pattern. Overlapping writes on different fields via `jq` are safe
because `jq` reads the full file and writes a new file atomically via `mv`. In the worst
case a write is lost (last writer wins), but this only affects counters (lastReadLine,
external_unmarks, awaitingApproval) which self-correct on the next cycle.

## Locking Patterns

### chat.md — fd 200
```bash
(
  exec 200>"${basePath}/chat.md.lock"
  flock -e 200 || exit 1
  cat >> "${basePath}/chat.md" << 'MSGEOF'
<message content>
MSGEOF
) 200>"${basePath}/chat.md.lock"
```

### tasks.md — fd 201
```bash
(
  exec 201>"${basePath}/tasks.md.lock"
  flock -e 201 || exit 1
  sed -i "s/^- \[x\] ${TASK_ID} /- [ ] ${TASK_ID} /" "${basePath}/tasks.md"
) 201>"${basePath}/tasks.md.lock"
```

> Use different fd numbers (200 for chat, 201 for tasks) to allow both locks to be
> held simultaneously if needed without deadlock — they are independent resources.

## Adding a New Agent

Before adding a new agent to the system:

1. Identify which existing channels it will read — add it to the Reader(s) column
2. Identify which channels it will write — add it to the Writer(s) column
3. If it writes to a channel with an existing writer: add locking (pick the next available fd)
4. If it introduces a new shared channel: add a row to this table and a Risk Register entry
5. Update the relevant agent files to reference the new contract
6. > **Full boundary checklist**: See `references/role-contracts.md` for the complete access matrix, "Adding a New Agent" checklist (4 steps with template code blocks), and cross-spec dependency tracking. `references/role-contracts.md` is the single source of truth for agent read/write permissions.
