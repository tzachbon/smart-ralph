---
spec: agent-chat-protocol
phase: requirements
created: 2026-04-07
---

# Requirements: agent-chat-protocol

## Summary

Create a bidirectional real-time chat channel between executor and reviewer based on filesystem, using FLOC (Floor Control for Agent Collaboration) signals to resolve 5 communication gaps: turn-taking, acknowledgment, intentional silence vs. problem detection, urgency escalation, and debate closure. The chat is human-readable, accumulates across the spec lifetime, and coexists with the existing formal `task_review.md` channel.

## User Stories

| ID | Who | Needs | Why | Priority |
|----|-----|-------|-----|----------|
| US-1 | executor | Turn-taking signal to request reviewer response | Avoid append collisions and ensure reviewer sees questions before executor advances | Must |
| US-2 | executor | Acknowledgment when reviewer reads OVER | Know whether to wait or proceed without blocking | Must |
| US-3 | reviewer | Ability to send HOLD before next task starts | Block executor pre-task for critical issues without mid-task interrupt | Must |
| US-4 | executor | Distinguish intentional silence from session death | Avoid false escalation when reviewer is working but quiet | Must |
| US-5 | reviewer | Heartbeat signal to confirm alive status | Executor knows reviewer is monitoring even during silence | Must |
| US-6 | reviewer | Ability to mark debate as resolved | Prevent executor from reopening closed discussions | Must |
| US-7 | reviewer | Pre-FAIL notification before formal write | Allow executor to respond or correct before formal rejection | Must |
| US-8 | executor/reviewer | Urgency escalation to break task boundary | Handle critical issues that cannot wait for task completion | Must |
| US-9 | executor/reviewer | Deadlock escalation to human | When neither agent can resolve a conflict | Must |
| US-10 | human | Read and intervene in chat at any time | Human voice is always final and can override any agent decision | Must |

## Functional Requirements

### FR-1: Chat Channel Existence

**Given** a spec is active **When** the reviewer is activated via interview-framework **Then** `chat.md` is created alongside `task_review.md` in `specs/<specName>/` **And** the channel is empty

**Given** `chat.md` does not exist **When** executor starts a task **Then** executor proceeds without reading chat (chat is optional)

**Given** `chat.md` exists but is empty **When** executor starts a task **Then** silence means UNKNOWN (no FLOC active yet)

**Given** `chat.md` has at least 1 message **When** executor starts a task **Then** FLOC protocol is active and all signals apply

### FR-2: Message Format

**Given** an agent writes to chat **When** composing a message **Then** format is:
```
### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>

<message body>
```

**And** `<SIGNAL>` is one of: OVER, ACK, CONTINUE, HOLD, STILL, ALIVE, CLOSE, URGENT, DEADLOCK, INTENT-FAIL

**And** message body is human-readable markdown (no raw JSON or structured data)

### FR-3: OVER Signal (Turn-Taking)

**Given** executor or reviewer writes OVER **When** they have a question or need response **Then** the message is blocking: writer expects a response within 1 task cycle **And** writer does NOT start new work until response received or timeout

**Given** OVER is sent **When** no response received within 1 task **Then** writer assumes CONTINUE and proceeds

**Exception**: If a HOLD is present in chat at the moment OVER times out, HOLD takes precedence — executor does not start the next task until HOLD is resolved, even if OVER auto-CONTINUE would otherwise apply.

**Given** reviewer receives OVER **When** responding **Then** response must be ACK (processing) or CLOSE (debate closed)

### FR-4: ACK Signal (Acknowledgment)

**Given** reviewer reads executor's message **When** processing requires time **Then** reviewer writes ACK within same task cycle to unblock executor

**And** ACK is non-blocking: executor proceeds after ACK

### FR-5: CONTINUE Signal (Proceed)

**Given** reviewer reads executor's message **When** no response needed **Then** reviewer writes CONTINUE to signal executor may proceed

**And** CONTINUE is non-blocking

### FR-6: HOLD Signal (Pre-Task Gate)

**Given** reviewer writes HOLD **When** executor is mid-task **Then** executor does NOT see HOLD until current task completes

**And** at next task boundary, executor reads chat.md BEFORE starting new task

**And** if HOLD present, executor waits for ACK or CONTINUE before proceeding

**Given** executor writes HOLD **When** reviewer is mid-review **Then** reviewer reads HOLD at next review cycle

**And** HOLD blocks task start only, NOT mid-execution

### FR-7: STILL Signal (Intentional Silence)

**Given** reviewer is working but cannot respond **When** sending a status update **Then** reviewer writes STILL to indicate intentionally silent

**And** STILL has 3-task TTL: after 3 consecutive tasks with no other signal, executor raises alarm

**And** STILL is non-blocking

### FR-8: ALIVE Signal (Heartbeat)

**Given** reviewer has been silent for 3 tasks **When** session is healthy **Then** reviewer writes ALIVE to confirm monitoring is active

**And** ALIVE resets STILL TTL counter

**And** ALIVE is non-blocking

### FR-9: CLOSE Signal (Debate Closure)

**Given** reviewer responds to OVER **When** debate is resolved **Then** reviewer writes CLOSE (not CONTINUE)

**And** CLOSE marks the specific thread as closed

**And** CLOSE does not prevent new OVER messages on new topics

### FR-10: URGENT Signal (Interrupt)

**Given** reviewer writes URGENT **When** critical issue cannot wait **Then** executor breaks task boundary after current qa-engineer delegation completes

**And** URGENT writer must be reviewer only (not executor)

**And** URGENT cannot interrupt during active qa-engineer Task tool call

### FR-11: INTENT-FAIL Signal (Pre-FAIL)

**Given** reviewer plans to write FAIL to task_review.md **When** executor could correct the issue **Then** reviewer writes INTENT-FAIL to chat first

**And** executor has 1 task cycle to respond before formal FAIL is written

**And** INTENT-FAIL includes the same fix_hint that will go in FAIL

### FR-12: DEADLOCK Signal (Human Escalation)

**Given** executor or reviewer cannot resolve a conflict **When** neither has domain authority **Then** writer writes DEADLOCK to chat

**And** human is notified (via coordinator output or separate mechanism)

**And** execution pauses until human resolves

### FR-13: Atomic Writes

**Given** two agents write to chat concurrently **When** writing messages **Then** writes must be atomic to prevent file corruption

**And** implementation uses flock-based exclusive access + `cat >>` for append: `flock` acquires exclusive lock, then `cat >>` appends safely

**Note**: `cat >>` WITHOUT flock is NOT atomic on concurrent writes — without locking, appends can interleave or overwrite each other

**And** NO bare `cat >>` without atomicity mechanism

### FR-14: chat.lastReadLine State

**Note**: `lastReadLine` is a line cursor, not a message index — messages in chat.md are multi-line (header line + blank line + body), so a line cursor accurately tracks position.

**Given** each agent tracks read position **When** reading chat **Then** lastReadLine stored in `chat` field inside `.ralph-state.json` as `chat.executor.lastReadLine` and `chat.reviewer.lastReadLine`

**And** state updates use atomic JSON write pattern: `jq --argjson idx N '.chat.executor.lastReadLine = $idx' .ralph-state.json > /tmp/state.json && mv /tmp/state.json .ralph-state.json`

**And** executor reads chat at task START only, using lastReadLine to find new messages since last read

## Non-Functional Requirements

### NFR-1: Atomic Writes (CRITICAL)

**Statement**: Concurrent filesystem writes from two agents MUST NOT corrupt chat.md

**Options**:
- **Option A — O_APPEND**: Unix `O_APPEND` flag ensures atomic append for writes < PIPE_BUF (~4KB). Simple but relies on OS atomicity guarantees. Safe for human-scale messages.
- **Option B — Temp file + rename**: Write to `chat.tmp.{agent}.{timestamp}`, then atomic `rename()` to final position. More explicit, works across broader file sizes, guaranteed atomic by filesystem.

**Decision**: Option B (temp file + rename). Explicit atomicity is more robust across file sizes and filesystem implementations. O_APPEND implicit behavior varies.

**Verification**: Concurrent write test: both agents append 100 messages simultaneously, verify zero corruption and zero lost messages.

### NFR-2: Performance

**Statement**: Chat read/write operations MUST complete within 1 second

**Metric**: File write latency (including atomic rename)
**Target**: < 500ms for typical message (~500 chars)
**Target**: < 1s for large message (~4KB)

### NFR-3: Chat Activation Threshold

**Statement**: Executor MUST NOT look for chat signals until chat.md exists with at least 1 message

**Rationale**: Preserves current behavior for specs without reviewer. Avoids executor blocking on non-existent optional channel.

### NFR-4: Coexistence with task_review.md

**Statement**: chat.md is parallel channel, NOT replacement. task_review.md remains authoritative for formal PASS/FAIL/WARNING decisions

**Implication**: All formal verification outcomes go to task_review.md. chat.md is for reasoning, debate, and informal coordination.

### NFR-5: Human Readability

**Statement**: All chat messages MUST be human-readable without tooling

**Format**: Markdown with signal prefix, timestamp, task reference. Human can read with `cat` or editor.

### NFR-6: Future Archival Compatibility

**Statement**: Chat format and location MUST support future rotation/archival without breaking protocol

**Design constraint**: Messages are append-only with immutable format. Rotation future: archive `chat-2026-04.md` and start new `chat.md`.

## Glossary

| Term | Definition |
|------|------------|
| FLOC | Floor Control for Agent Collaboration — signal-based protocol for turn-taking, acknowledgment, and status in bidirectional agent chat |
| OVER | Blocking signal: writer is done speaking, awaiting response. Timeout = 1 task cycle then assume CONTINUE |
| ACK | Non-blocking signal: writer has read message and is processing. Unblocks waiting writer |
| CONTINUE | Non-blocking signal: writer has read message, no response needed, proceed |
| HOLD | Blocking signal: pre-task gate. Executor reads this BEFORE starting next task, not during current task |
| STILL | Non-blocking signal: writer is intentionally silent (working). 3-task TTL then triggers alarm |
| ALIVE | Non-blocking signal: periodic heartbeat confirming session is healthy. Sent every 3 tasks of silence |
| CLOSE | Response to OVER: debate resolved, thread closed. Does not reopen |
| URGENT | Breaks task boundary: critical issue requiring immediate attention. Reviewer-only. Cannot interrupt during active qa-engineer delegation |
| INTENT-FAIL | Reviewer pre-announcement: plans to write FAIL, executor has 1 task cycle to respond first |
| DEADLOCK | Both agents cannot resolve: human needed for arbitration |
| Turn-taking | Gap #1: explicit handoff signal when one agent stops speaking and another can respond |
| Acknowledgment | Gap #2: sender knows receiver read the message |
| Silence differentiation | Gap #3: distinguishing "working silently OK" from "session died" |
| Urgency escalation | Gap #4: mechanism to interrupt task boundary for critical issues |
| Debate closure | Gap #5: marking threads as resolved so they don't stay open forever |
| Pre-task gate | HOLD semantics: signal read at task START only, not during execution |
| lastReadLine | Per-agent line cursor tracking read position in chat.md (multi-line messages require line cursor, not message index) |

## Out of Scope

- Chat search/filter/query tooling (human reads with `grep`, no built-in query language)
- Automatic chat rotation/archival (deferred until size becomes issue; design supports it)
- Integration with external notification systems (Slack, email, etc.)
- Voice/video communication
- Chat message editing or deletion (append-only for simplicity)
- Multi-party chat beyond executor + reviewer (qa-engineer excluded as sub-agent)
- Persistent session management across Claude Code restarts (filesystem state persists, agent session is fresh per invocation)

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| `spec-executor.md` | Must modify | Add Chat Protocol section: read chat at task start, respect HOLD signal |
| `external-reviewer.md` | Must modify | Implement FLOC signals, send ALIVE/INTENT-FAIL |
| `task_review.md` template | No change | Remains authoritative formal channel |
| `.ralph-state.json` schema | No change (No change — lastReadLine stored in .chat-state.executor.json and .chat-state.reviewer.json) | Optional per-agent lastReadLine stored separately |
| reviewer-subagent spec | Related | Defines external-reviewer agent that implements FLOC |
| iterative-failure-recovery spec | Related | OVER timeout interacts with effectiveIterations |

## Verification Contract

**Project type**: backend (no UI surfaces — filesystem API only, chat.md reads/writes; qa-engineer verifies agent file behavior, not browser-based UI)

**Entry points**:
- `spec-executor.md` — reads `chat.md` at task boundary (before each new task)
- `external-reviewer.md` — writes FLOC signals to `chat.md`, reads at review cycles
- Coordinator — monitors for DEADLOCK and URGENT signals for human notification

**Observable signals**:

PASS looks like:
- `chat.md` exists in spec directory after reviewer activation
- Messages appear with correct format: `### [executor → reviewer] 14:32:05 | task-2.4 | OVER`
- Executor respects HOLD: does not start next task until ACK/CONTINUE
- ALIVE appears every 3 tasks of reviewer silence
- INTENT-FAIL appears before any FAIL written to task_review.md

FAIL looks like:
- Append collision: garbled message text or missing lines
- Executor starts task despite HOLD present (pre-task gate not respected)
- No ALIVE after 3 tasks of silence (false positive deadlock alarm)
- FAIL written to task_review.md without prior INTENT-FAIL in chat
- Executor proceeds on OVER without timeout response within 1 task

**Hard invariants**:
- task_review.md is NEVER written by executor (reviewer-only)
- HOLD never interrupts mid-task execution (pre-task gate only)
- URGENT never arrives during active qa-engineer Task tool call
- qa-engineer is NEVER a chat participant
- Human intervention is always possible and always final

**Seed data**:
- Spec must have at least one task in `tasks.md`
- Reviewer must be activated (chat.md created by interview-framework)
- Executor must have read at least one prior task

**Dependency map**:
- `specs/<specName>/chat.md` — shared by executor and reviewer
- `specs/<specName>/task_review.md` — reviewer writes formal decisions
- `.chat-state.executor.json` — executor read position
- `.chat-state.reviewer.json` — reviewer read position

**Escalate if**:
- DEADLOCK signal appears — human must arbitrate
- URGENT during qa-engineer delegation — wait for delegation to complete
- Append corruption detected — stop both agents, human must repair chat.md

## Unresolved Questions

- **Chat archival trigger**: At what size (line count, file size, date) should chat.md be rotated? Deferred decision — design supports rotation but threshold not defined.

## Next Steps

1. Review requirements with user for approval
2. Proceed to design phase: specify chat.md template format, state file schema, and atomic write implementation details
3. Implement FLOC signals in external-reviewer.md agent
4. Implement chat read at task boundary in spec-executor.md agent
