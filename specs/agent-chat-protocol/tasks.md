# Tasks: agent-chat-protocol

## Overview

Total tasks: 39 (original) + 15 (PR #9 fixes) = 54

**Intent Classification**: GREENFIELD — POC-first workflow (original); BUG_FIX (Phase 5)

**POC-first workflow**:
1. Phase 1: Make It Work (POC) - Validate idea end-to-end
2. Phase 2: Refactoring - Clean up code structure
3. Phase 3: Testing - Add unit/integration/e2e tests
4. Phase 4: Quality Gates - Local quality checks and PR creation

**Architecture note**: FLOC protocol is implemented as sections added to agent prompts (spec-executor.md, external-reviewer.md). Agents execute inline bash commands directly — they do NOT call external bash scripts. Chat reading/writing uses Read tool, Write tool, and Bash tool inline in the agent prompts.

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [x] 1.1 Create chat.md template file
  - **Do**:
    1. Create `plugins/ralph-specum/templates/chat.md` with format header containing signals legend table
    2. Include the message format: `### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>`
    3. Include signals legend table with all 10 signals (OVER, ACK, CONTINUE, HOLD, STILL, ALIVE, CLOSE, URGENT, DEADLOCK, INTENT-FAIL)
    4. Include example messages section showing OVER/ACK/CONTINUE/CLOSE patterns
    5. Add comment: `<!-- Messages accumulate here. Append only. Do not edit or delete. -->`
  - **Files**: `plugins/ralph-specum/templates/chat.md`
  - **Done when**: Template file exists with correct format and all 10 signals documented
  - **Verify**: `grep -c "OVER\|ACK\|CONTINUE\|HOLD\|STILL\|ALIVE\|CLOSE\|URGENT\|DEADLOCK\|INTENT-FAIL" plugins/ralph-specum/templates/chat.md`
  - **Commit**: `feat(chat-template): create chat.md template with FLOC signals legend`
  - _Requirements: FR-1, FR-2_
  - _Design: Chat Template section_

- [x] 1.2 Add chat field to .ralph-state.json schema
  - **Do**:
    1. Read current `.ralph-state.json` schema to understand state structure
    2. Add `chat` field to `.ralph-state.json` inside `specs/agent-chat-protocol/` with structure:
       ```json
       "chat": {
         "executor": { "lastReadIndex": 0, "lastSignal": null, "lastSignalTask": null, "stillTtl": 0 },
         "reviewer": { "lastReadIndex": 0, "lastSignal": null, "lastSignalTask": null, "pendingIntentFail": null }
       }
       ```
    3. Initialize this in the spec's `.ralph-state.json` if it exists, or create a new one
  - **Files**: `specs/agent-chat-protocol/.ralph-state.json`
  - **Done when**: `.ralph-state.json` contains `chat` field with per-agent subfields
  - **Verify**: `jq '.chat' specs/agent-chat-protocol/.ralph-state.json`
  - **Commit**: `feat(chat-state): add chat field to .ralph-state.json schema`
  - _Requirements: FR-14_
  - _Design: Per-Agent State section_

- [x] 1.3 Add Chat Protocol section to spec-executor.md — core infrastructure
  - **Do**:
    1. Read `plugins/ralph-specum/agents/spec-executor.md`
    2. Add new section "## Chat Protocol (FLOC)" after the "## External Review Protocol" section
    3. Add to the section:
       - **Chat file path**: `chat.md` in basePath
       - **Activation threshold**: chat.md exists AND has >= 1 message
       - **Read at task START**: Before starting each task, read chat.md using Read tool, parse new messages after lastReadIndex
       - **Atomic append pattern** (CRITICAL — chat.md is append-only):
         ```bash
         # Append atomically to chat.md using flock-based exclusive access
         (
           exec 200>"${basePath}/chat.md.lock"
           flock -e 200 || exit 1
           cat >> "${basePath}/chat.md" << 'MSGEOF'
         ### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>
         <message body>
         MSGEOF
         ) 200>"${basePath}/chat.md.lock"
         ```
         **IMPORTANT**: `cat >>` WITHOUT flock is also broken for concurrent writes — always use flock for exclusive access. **NEVER use `mv` to write to chat.md** — it overwrites the entire file.
       - **Update lastReadIndex**: After reading, update via atomic jq pattern:
         ```bash
         jq --argjson idx N '.chat.executor.lastReadIndex = $idx' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
         ```
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor.md contains Chat Protocol section with file paths, read-at-start logic, and atomic write pattern
  - **Verify**: `grep -c "Chat Protocol\|chat.md\|lastReadIndex\|atomic" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add Chat Protocol section with atomic read/write`
  - _Requirements: FR-1, FR-2, FR-13, FR-14_
  - _Design: Atomic Write Implementation section, Per-Agent State section_

- [x] 1.4 Add OVER and HOLD signals to spec-executor.md Chat Protocol
  - **Do**:
    1. Add to Chat Protocol section in spec-executor.md:
       - **OVER signal**: Blocking signal — after sending OVER, do not start new work until response or 1-task timeout
         - If timeout: auto-assume CONTINUE, proceed
         - Exception: if HOLD present at timeout, HOLD takes precedence — do not start next task
       - **HOLD signal**: Pre-task gate only — read at task START, never interrupt mid-task
         - If HOLD present in unread messages: block until ACK or CONTINUE received
         - Do NOT stop current task when HOLD received mid-execution
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: OVER blocking with timeout and HOLD pre-task gate implemented
  - **Verify**: `grep -c "OVER\|HOLD\|timeout\|pre-task" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add OVER and HOLD signal handling`
  - _Requirements: FR-3, FR-6_
  - _Design: FLOC Signal State Machine section_

- [x] 1.5 Add STILL TTL tracking to spec-executor.md Chat Protocol
  - **Do**:
    1. Add to Chat Protocol section in spec-executor.md:
       - **STILL TTL**: 3-task cycle counter
         - Decrement stillTtl when reviewer sends no signal for N consecutive tasks
         - When TTL reaches 0: raise alarm (deadlock suspicion)
         - ANY reviewer signal resets TTL to 3
       - **ALIVE signal**: When TTL would expire, if ALIVE appears, reset TTL to 3
       - Track in `.ralph-state.json` under `chat.executor.stillTtl`
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: STILL TTL tracking with alarm behavior implemented
  - **Verify**: `grep -c "stillTtl\|STILL\|TTL\|deadlock" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add STILL TTL tracking for deadlock prevention`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [x] 1.6 Add FLOC signal writers to spec-executor.md Chat Protocol
  - **Do**:
    1. Add to Chat Protocol section in spec-executor.md a "Signal Reference" subsection with inline bash commands for each signal:
       - **OVER**: `chat_write_signal "executor" "reviewer" "OVER" "<question>"`
       - **CONTINUE**: `chat_write_signal "executor" "reviewer" "CONTINUE" ""`
       - **HOLD**: `chat_write_signal "executor" "reviewer" "HOLD" "<reason>"`
       - **DEADLOCK**: `chat_write_signal "executor" "reviewer" "DEADLOCK" "<reason>"`
    2. Include the chat_write_signal function definition using atomic append pattern (cat >> as defined in task 1.3)
    3. Include timestamp helper using `date +%H:%M:%S`
    4. Include task-ID formatting from `.ralph-state.json` → taskIndex
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: All executor-side signal writers available as inline functions
  - **Verify**: `grep -c "chat_write_signal\|OVER\|CONTINUE\|HOLD\|DEADLOCK" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add FLOC signal writers to Chat Protocol`
  - _Requirements: FR-2, FR-3, FR-6, FR-12_
  - _Design: FLOC Signal State Machine section_

- [x] 1.7 Add chat reading to external-reviewer.md — core infrastructure
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Add new section "## Chat Protocol (FLOC)" at the end of the file (before Section 7 Never Do)
    3. Add to the section:
       - **Chat file path**: `chat.md` in basePath
       - **Read at review cycle**: After completing a review, read chat.md using Read tool
       - **Update lastReadIndex**: After reading, update via atomic jq pattern:
         ```bash
         jq --argjson idx N '.chat.reviewer.lastReadIndex = $idx' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
         ```
       - **Atomic write pattern**: Same temp file + rename as spec-executor
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: external-reviewer.md contains Chat Protocol section with read/write infrastructure
  - **Verify**: `grep -c "Chat Protocol\|chat.md\|lastReadIndex" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add Chat Protocol section infrastructure`
  - _Requirements: FR-1, FR-2, FR-13, FR-14_
  - _Design: Atomic Write Implementation section_

- [x] 1.8 Add OVER response signals to external-reviewer.md Chat Protocol
  - **Do**:
    1. Add to Chat Protocol section in external-reviewer.md:
       - **Read OVER**: Detect OVER signal in unread messages
       - **Respond within 1 task cycle**: ACK (processing) or CLOSE (debate resolved)
       - **ACK**: Non-blocking — executor proceeds after ACK
       - **CONTINUE**: Non-blocking — executor may proceed, no response needed
       - **CLOSE**: Debate resolved — marks thread as closed, does not reopen
    2. Include signal writer functions (same atomic pattern as executor)
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: OVER response signals (ACK/CONTINUE/CLOSE) implemented
  - **Verify**: `grep -c "ACK\|CONTINUE\|CLOSE\|OVER" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add OVER response signals`
  - _Requirements: FR-3, FR-4, FR-5, FR-9_
  - _Design: FLOC Signal State Machine section_

- [x] 1.9 Add STILL and ALIVE signals to external-reviewer.md Chat Protocol
  - **Do**:
    1. Add to Chat Protocol section in external-reviewer.md:
       - **STILL**: When intentionally silent but working — non-blocking
         - Has 3-task TTL: after 3 consecutive tasks with no signal, executor raises alarm
       - **ALIVE**: Heartbeat — every 3 tasks of silence to confirm healthy session
         - Resets STILL TTL counter
         - Non-blocking
    2. Include `stillTtl` tracking in state: decrement each task, reset on any signal
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: STILL and ALIVE signals implemented with TTL tracking
  - **Verify**: `grep -c "STILL\|ALIVE\|stillTtl" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add STILL and ALIVE signal implementation`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [x] 1.10 Add URGENT, INTENT-FAIL, DEADLOCK signals to external-reviewer.md
  - **Do**:
    1. Add to Chat Protocol section in external-reviewer.md:
       - **URGENT**: Critical issue that cannot wait — breaks task boundary
         - Cannot interrupt during active qa-engineer delegation (boundary is after Task tool returns)
         - Reviewer-only signal (not executor)
       - **INTENT-FAIL**: Pre-FAIL notification before writing FAIL to task_review.md
         - Executor has 1 task cycle to respond or correct
         - Must include same fix_hint that will go in FAIL
       - **DEADLOCK**: Human escalation — when neither agent can resolve conflict
         - Notifies human via coordinator output
         - Execution pauses until human resolves
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: URGENT, INTENT-FAIL, DEADLOCK signals implemented
  - **Verify**: `grep -c "URGENT\|INTENT-FAIL\|DEADLOCK" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add URGENT, INTENT-FAIL, DEADLOCK signals`
  - _Requirements: FR-10, FR-11, FR-12_
  - _Design: FLOC Signal State Machine section_

- [x] 1.11 Add `version:` field to external-reviewer.md
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Add `version: 0.1.0` to the frontmatter (after `color: purple`)
    3. This field is required for plugin versioning in Task 4.3
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: external-reviewer.md has `version:` field in frontmatter
  - **Verify**: `grep "^version:" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `chore(external-reviewer): add version field for plugin versioning`
  - _Requirements: Plugin versioning requirement from CLAUDE.md_

- [x] 1.12 Add chat.md creation to implement.md reviewer onboarding
  - **Do**:
    1. Read `plugins/ralph-specum/commands/implement.md`
    2. In "If user answers YES" block, after step that copies task_review.md template, add:
       - Copy `plugins/ralph-specum/templates/chat.md` → `specs/<specName>/chat.md`
    3. In the onboarding instructions printed to user, add:
       - "El revisor también leerá y escribirá en chat.md (coordinación FLOC en tiempo real)"
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md creates chat.md automatically when reviewer is activated
  - **Verify**: `grep -c "chat.md" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(implement): create chat.md on reviewer activation`
  - _Requirements: FR-1_

- [x] 1.13 [VERIFY] Quality Checkpoint: syntax and structure
  - **Do**: Verify all modified files have correct syntax and structure
  - **Verify**:
    - `jq '.' specs/agent-chat-protocol/.ralph-state.json && echo "STATE_OK"`
    - `grep -q "Chat Protocol" plugins/ralph-specum/agents/spec-executor.md && echo "EXEC_PROTOCOL_OK"`
    - `grep -q "Chat Protocol" plugins/ralph-specum/agents/external-reviewer.md && echo "REVIEWER_PROTOCOL_OK"`
    - `grep -q "version:" plugins/ralph-specum/agents/external-reviewer.md && echo "VERSION_OK"`
    - `grep -q "OVER\|ACK\|CONTINUE" plugins/ralph-specum/agents/spec-executor.md && echo "EXEC_SIGNALS_OK"`
    - `grep -q "ALIVE\|STILL\|INTENT-FAIL" plugins/ralph-specum/agents/external-reviewer.md && echo "REVIEWER_SIGNALS_OK"`
    - `grep -q "chat.md" plugins/ralph-specum/commands/implement.md && echo "IMPLEMENT_CHAT_OK"`
  - **Done when**: All checks pass with no errors
  - **Commit**: `chore: pass Phase 1 quality checkpoint`
  - _Requirements: NFR-1, NFR-2_

- [x] 1.14 Initialize chat.md in spec directory
  - **Do**:
    1. Copy `plugins/ralph-specum/templates/chat.md` to `specs/agent-chat-protocol/chat.md`
    2. Verify file exists and has correct format
  - **Files**: `specs/agent-chat-protocol/chat.md`
  - **Done when**: chat.md exists in spec directory with template content
  - **Verify**: `[ -f specs/agent-chat-protocol/chat.md ] && grep -q "Signals Legend" specs/agent-chat-protocol/chat.md`
  - **Commit**: `feat(chat-init): initialize chat.md in spec directory`
  - _Requirements: FR-1_
  - _Design: Chat Template section_

- [x] 1.15 POC test: executor writes OVER, reviewer responds ACK
  - **Do**:
    1. Set up test environment: create temp spec directory with chat.md and .ralph-state.json
    2. Simulate executor writes OVER to chat.md using inline bash (atomic write pattern)
    3. Simulate reviewer reads chat.md, responds with ACK using inline bash
    4. Verify both messages appear in chat.md with correct format
    5. Verify state file updated correctly (lastReadIndex for both agents)
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: OVER and ACK messages appear in chat.md with correct format
  - **Verify**: `grep "OVER\|ACK" specs/agent-chat-protocol/chat.md | wc -l`
  - **Commit**: `test(chat-poc): verify OVER/ACK bidirectional message flow`
  - _Requirements: FR-3, FR-4_
  - _Design: Signal Sequencing Rules section_

- [x] 1.16 POC test: HOLD pre-task gate blocks executor
  - **Do**:
    1. Create test scenario: executor starts task, reviewer sends HOLD
    2. Verify executor reads HOLD at task START only (not mid-task)
    3. Verify executor blocks until ACK or CONTINUE received
    4. Verify executor proceeds with current task when HOLD received mid-execution
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Executor correctly respects HOLD as pre-task gate
  - **Verify**: `grep -c "HOLD" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `test(chat-poc): verify HOLD pre-task gate semantics`
  - _Requirements: FR-6_
  - _Design: HOLD Signal section_

- [x] 1.17 POC test: STILL/ALIVE heartbeat cycle
  - **Do**:
    1. Simulate 3 tasks of reviewer silence
    2. Verify STILL TTL decrements on each task
    3. Verify ALIVE is sent when TTL would expire
    4. Verify ALIVE resets TTL to 3
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: ALIVE appears after 3 tasks of silence
  - **Verify**: `grep "ALIVE" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify STILL/ALIVE heartbeat cycle`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [x] 1.18 POC test: INTENT-FAIL 1-task window
  - **Do**:
    1. Simulate reviewer writes INTENT-FAIL to chat.md
    2. Verify executor has 1 task cycle to respond
    3. Verify FAIL written to task_review.md only after 1 task if not corrected
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: INTENT-FAIL appears in chat before FAIL in task_review.md
  - **Verify**: `grep "INTENT-FAIL" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify INTENT-FAIL 1-task window`
  - _Requirements: FR-11_
  - _Design: INTENT-FAIL Signal section_

- [x] 1.19 POC test: CLOSE thread resolution
  - **Do**:
    1. Simulate OVER exchange between executor and reviewer
    2. Simulate reviewer sends CLOSE to resolve thread
    3. Verify CLOSE appears in chat.md with correct format
    4. Verify new OVER on different topic still works
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: CLOSE appears in chat.md
  - **Verify**: `grep "CLOSE" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify CLOSE thread resolution`
  - _Requirements: FR-9_
  - _Design: CLOSE Signal section_

- [x] 1.20 POC Checkpoint: end-to-end signal flow
  - **Do**: Run a full POC demonstrating all major signals work:
    1. Executor sends OVER
    2. Reviewer sends ACK
    3. Reviewer sends CONTINUE
    4. Executor proceeds
    5. Reviewer sends HOLD
    6. Executor respects HOLD at next task
    7. Reviewer sends ACK
    8. Executor proceeds
  - **Done when**: All signals appear in correct order in chat.md
  - **Verify**: `grep -E "OVER|ACK|CONTINUE|HOLD" specs/agent-chat-protocol/chat.md`
  - **Commit**: `chore: complete POC validation`
  - _Requirements: FR-3, FR-4, FR-5, FR-6_

## Phase 2: Refactoring

After POC validated, clean up code.

- [x] 2.1 Refactor: extract message formatting helpers
  - **Do**:
    1. Add message format validation to spec-executor.md and external-reviewer.md
    2. Validate format: `### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>`
    3. Validate SIGNAL is one of 10 known signals
    4. Centralize timestamp and task-ID helpers
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Message format validated before writing
  - **Verify**: `grep "validate.*signal\|SIGNAL" plugins/ralph-specum/agents/spec-executor.md | wc -l`
  - **Commit**: `refactor(chat): add message format validation`
  - _Design: Error Handling section_

- [x] 2.2 Refactor: add error recovery for missing/corrupted files
  - **Do**:
    1. Add error recovery for missing chat.md (graceful skip — chat is optional)
    2. Add error recovery for corrupted state file (reset to defaults)
    3. Add error recovery for lastReadIndex > actual lines (reset to line count)
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Chat handling handles all error cases gracefully
  - **Verify**: `grep "missing\|corrupted\|graceful" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `refactor(chat): add error recovery for missing files`
  - _Design: Error Handling section_

- [x] 2.3 Refactor: add atomic write verification
  - **Do**:
    1. Add verification that temp file is removed after rename
    2. Add check that message appears in chat.md after write
    3. Add cleanup of orphaned temp files on error
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: No orphaned temp files remain after write
  - **Verify**: `ls /tmp/chat.tmp.* 2>/dev/null || echo "NO_ORPHANS"`
  - **Commit**: `refactor(chat): add atomic write verification`
  - _Requirements: NFR-1_
  - _Design: Error Handling section_

- [x] 2.4 [VERIFY] Quality Checkpoint: refactoring complete
  - **Do**: Verify all refactored sections are syntactically correct
  - **Verify**:
    - `grep -q "Chat Protocol" plugins/ralph-specum/agents/spec-executor.md && echo "EXEC_OK"`
    - `grep -q "Chat Protocol" plugins/ralph-specum/agents/external-reviewer.md && echo "REVIEWER_OK"`
  - **Done when**: All checks pass
  - **Commit**: `chore: pass Phase 2 quality checkpoint`

## Phase 3: Testing

- [x] 3.1 Integration test: concurrent writes (100 messages)
  - **Do**:
    1. Create test script `tests/chat-concurrent.sh`:
       - Both agents append 100 messages simultaneously
       - Verify zero corruption (valid format per message)
       - Verify zero lost messages (count matches)
    2. Use background processes in bash
    3. Include bats fallback: `command -v bats || echo "BATS_NOT_INSTALLED"`
  - **Files**: `tests/chat-concurrent.sh`
  - **Done when**: All integration tests pass with no corruption
  - **Verify**: `bash tests/chat-concurrent.sh`
  - **Commit**: `test(chat-concurrent): add concurrent writes integration test`
  - _Requirements: NFR-1_
  - _Design: Test Coverage Table - Concurrent writes_

- [x] 3.2 Integration test: HOLD pre-task gate behavior
  - **Do**:
    1. Create test script `tests/chat-hold-gate.sh`:
       - Executor respects HOLD at task START
       - Executor does NOT block mid-task (pre-task gate only)
       - Executor unblocks after ACK/CONTINUE
       - HOLD invisible until task boundary
    2. Include bats fallback
  - **Files**: `tests/chat-hold-gate.sh`
  - **Done when**: All integration tests pass
  - **Verify**: `bash tests/chat-hold-gate.sh`
  - **Commit**: `test(chat-hold): add HOLD pre-task gate integration test`
  - _Design: Test Coverage Table - HOLD pre-task gate_

- [x] 3.3 Integration test: INTENT-FAIL 1-task window
  - **Do**:
    1. Create test script `tests/chat-intent-fail.sh`:
       - INTENT-FAIL appears before FAIL
       - Executor has 1 task window to respond
       - FAIL written only after window expires
       - Corrected issue prevents FAIL
    2. Include bats fallback
  - **Files**: `tests/chat-intent-fail.sh`
  - **Done when**: All integration tests pass
  - **Verify**: `bash tests/chat-intent-fail.sh`
  - **Commit**: `test(chat-intent-fail): add INTENT-FAIL window integration test`
  - _Design: Test Coverage Table - INTENT-FAIL 1-task window_

- [x] 3.4 Integration test: Executor respects HOLD (not mid-task)
  - **Do**:
    1. Create test script `tests/chat-hold-behavior.sh`:
       - Executor proceeds with current task when HOLD received mid-execution
       - Executor blocks at next task if HOLD not resolved
       - Executor unblocks when ACK or CONTINUE received
    2. Include bats fallback
  - **Files**: `tests/chat-hold-behavior.sh`
  - **Done when**: All integration tests pass
  - **Verify**: `bash tests/chat-hold-behavior.sh`
  - **Commit**: `test(chat-hold): add executor respects HOLD not mid-task test`
  - _Design: Test Coverage Table - Executor respects HOLD (not mid-task)_

- [x] 3.5 Integration test: STILL/ALIVE heartbeat cycle
  - **Do**:
    1. Create test script `tests/chat-heartbeat.sh`:
       - STILL TTL decrements each task
       - ALIVE resets TTL to 3
       - ALIVE sent when TTL would expire
       - ANY signal resets STILL counter
    2. Include bats fallback
  - **Files**: `tests/chat-heartbeat.sh`
  - **Done when**: All integration tests pass
  - **Verify**: `bash tests/chat-heartbeat.sh`
  - **Commit**: `test(chat-heartbeat): add STILL/ALIVE heartbeat integration test`
  - _Design: Test Coverage Table - ALIVE resets STILL TTL_

- [x] 3.6 Integration test: chat format human-readable
  - **Do**:
    1. Create test script `tests/chat-format.sh`:
       - `cat chat.md` shows readable markdown
       - Each message has correct format header
       - Signals are human-readable (not encoded)
       - Human can read with standard tools
    2. Include bats fallback
  - **Files**: `tests/chat-format.sh`
  - **Done when**: All integration tests pass
  - **Verify**: `bash tests/chat-format.sh`
  - **Commit**: `test(chat-format): add human-readable format integration test`
  - _Requirements: NFR-5_
  - _Design: Test Coverage Table - Chat format human-readable_

- [x] 3.7 [VERIFY] Quality Checkpoint: all tests pass
  - **Do**: Run full test suite to verify all tests pass
  - **Verify**: `bash tests/chat-concurrent.sh && bash tests/chat-hold-gate.sh && bash tests/chat-intent-fail.sh && bash tests/chat-heartbeat.sh && bash tests/chat-format.sh && echo "ALL_TESTS_PASSED"`
  - **Done when**: All tests pass
  - **Commit**: `chore: pass Phase 3 quality checkpoint`

## Phase 4: Quality Gates

- [x] 4.1 Lint modified files
  - **Do**:
    1. Verify markdownlint on chat.md template
    2. Verify jq is available: `command -v jq || echo "JQ_NOT_INSTALLED"`
    3. Verify bash is available: `command -v bash || echo "BASH_NOT_INSTALLED"`
  - **Files**: `plugins/ralph-specum/templates/chat.md`
  - **Done when**: All linting checks pass with no errors
  - **Verify**: `command -v jq && echo "JQ_OK" && command -v bash && echo "BASH_OK"`
  - **Commit**: `chore: pass linting checks`
  - _Requirements: NFR-1, NFR-2_

- [x] 4.2 Update spec-executor.md version
  - **Do**:
    1. Read `plugins/ralph-specum/agents/spec-executor.md`
    2. Bump version in frontmatter (patch +0.0.1)
    3. Update version in marketplace.json entry for ralph-specum
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `.claude-plugin/marketplace.json`
  - **Done when**: Version bumped correctly
  - **Verify**: `grep "version:" plugins/ralph-specum/agents/spec-executor.md | head -1`
  - **Commit**: `chore: bump spec-executor version for chat protocol`
  - _Requirements: Plugin versioning requirement from CLAUDE.md_

- [x] 4.3 Update external-reviewer.md version
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Bump version in frontmatter (patch +0.0.1) — already has version: 0.1.0 from Task 1.11
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Version bumped correctly
  - **Verify**: `grep "version:" plugins/ralph-specum/agents/external-reviewer.md | head -1`
  - **Commit**: `chore: bump external-reviewer version for chat protocol`
  - _Requirements: Plugin versioning requirement from CLAUDE.md_

- [x] 4.4 [VERIFY] Final verification: all tasks complete
  - **Do**:
    1. Verify chat.md template exists and has correct format
    2. Verify chat state in .ralph-state.json works
    3. Verify spec-executor.md has Chat Protocol section with all signals
    4. Verify external-reviewer.md has FLOC signals with version field
    5. Run all integration tests
  - **Verify**:
    ```bash
    [ -f plugins/ralph-specum/templates/chat.md ] && \
    grep -q "Chat Protocol" plugins/ralph-specum/agents/spec-executor.md && \
    grep -q "Chat Protocol" plugins/ralph-specum/agents/external-reviewer.md && \
    grep -q "version:" plugins/ralph-specum/agents/external-reviewer.md && \
    grep -q "ALIVE\|STILL\|INTENT-FAIL" plugins/ralph-specum/agents/external-reviewer.md && \
    bash tests/chat-concurrent.sh && \
    echo "ALL_CHECKS_PASSED"
    ```
  - **Done when**: All verification checks pass
  - **Commit**: `chore: final verification complete`

- [x] 4.5 Create PR for agent-chat-protocol
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Stage all changes: chat template, spec-executor.md, external-reviewer.md, tests/
    4. Commit with descriptive message
    5. Push branch: `git push -u origin $(git branch --show-current)`
    6. Create PR using gh CLI
  - **Files**: All modified and created files
  - **Done when**: PR created with all changes
  - **Verify**: `gh pr view --json state | jq -r '.state'`
  - **Commit**: `feat(chat-protocol): implement FLOC-based bidirectional chat channel`
  - _Requirements: All functional requirements_

## Notes

- **POC shortcuts taken**: Direct temp-file+rename without fallback to O_APPEND; state stored in .ralph-state.json (not separate .chat-state files per design decision)
- **Agent architecture**: FLOC implemented as agent prompt sections, not external scripts — agents read chat.md directly using Read tool and write using Write/Bash tools inline
- **Production TODOs**: Chat archival rotation threshold not implemented; DEADLOCK human notification mechanism not specified

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality)
```

---

## Phase 5: PR #9 Review Fixes

> These tasks address review feedback from PR #9. Original Phase 1-4 tasks (above) are complete and left intact.

**Total**: 13 new tasks
**Intent**: BUG_FIX / REFACTOR — fix review feedback from PR #9
**Critical path**: CRITICAL issues (atomic write bug, issues 1-4) must be fixed in all 4 files before proceeding

### CRITICAL PATH: Atomic Write Bug

The atomic write strategy in the original spec is broken. `cat chat.md chat.tmp > chat.md.tmp && mv chat.md.tmp chat.md` causes lost updates when two agents write concurrently. The `mv chat.tmp chat.md` alternative overwrites the entire history.

**Correct fix**: `flock` for exclusive access + `cat >>` for safe append.

- [x] 5.1 [FIX] Fix atomic write pattern in design.md
  - **Do**:
    1. Read `specs/agent-chat-protocol/design.md` — find "Atomic Write Implementation" section
    2. Replace the broken pattern with `flock`-based atomic append:
       ```bash
       (
         exec 200>"$basePath/chat.md.lock"
         flock -e 200 || exit 1
         cat >> "$basePath/chat.md" << 'MSGEOF'
       ### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>
       <message body>
       MSGEOF
       ) 200>"$basePath/chat.md.lock"
       ```
    3. Rename `lastReadIndex` → `lastReadLine` throughout (messages are multi-line)
    4. Delete the "Alternative (Single Write)" section — `mv` overwrites, it does not append
    5. Fix "Concurrent Write Safety" to describe flock behavior
  - **Files**: `specs/agent-chat-protocol/design.md`
  - **Done when**: Atomic write uses flock, lastReadLine used, broken alternatives removed
  - **Verify**: `grep -n "flock\|lastReadLine" specs/agent-chat-protocol/design.md | head -10`
  - **Commit**: `fix(atomic-write): use flock for safe concurrent append`
  - _Review issues: CRITICAL #1 (line 247), CRITICAL #2 (line 217)_

- [x] 5.2 [FIX] Fix FR-13 in requirements.md
  - **Do**:
    1. Read `specs/agent-chat-protocol/requirements.md` — find FR-13 Atomic Writes
    2. Fix "rename to append position" — rename does NOT append, it overwrites
    3. Change to: "implementation uses flock-based exclusive access + cat >> for append"
    4. Clarify: "cat >> WITHOUT flock is NOT atomic on concurrent writes"
  - **Files**: `specs/agent-chat-protocol/requirements.md`
  - **Done when**: FR-13 correctly describes flock-based atomic append
  - **Verify**: `grep -n "flock\|atomic" specs/agent-chat-protocol/requirements.md | head -5`
  - **Commit**: `fix(requirements): clarify FR-13 atomic write — flock required`
  - _Review issue: CRITICAL #3 (line 143)_

- [x] 5.3 [FIX] Fix tasks.md task 1.3 atomic write pattern
  - **Do**:
    1. Read task 1.3 in `specs/agent-chat-protocol/tasks.md`
    2. Update the atomic append pattern to use flock (same as task 5.1)
    3. Add clarification: "cat >> WITHOUT flock is also broken for concurrent writes"
  - **Files**: `specs/agent-chat-protocol/tasks.md`
  - **Done when**: Task 1.3 describes flock-based atomic write
  - **Verify**: `grep -n "flock" specs/agent-chat-protocol/tasks.md | head -5`
  - **Commit**: `fix(tasks): add flock to atomic write pattern in task 1.3`
  - _Review issue: CRITICAL #4 (task 1.3)_

- [x] 5.4 [FIX] Fix external-reviewer.md atomic write pattern
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md` — find chat_write_signal function
    2. Replace bare `cat >>` with flock-based pattern:
       ```bash
       (
         exec 200>"${basePath}/chat.md.lock"
         flock -e 200 || exit 1
         cat "$tmpfile" >> "${basePath}/chat.md"
         rm -f "$tmpfile"
       ) 200>"${basePath}/chat.md.lock"
       ```
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: external-reviewer.md uses flock-based atomic append
  - **Verify**: `grep -n "flock" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `fix(external-reviewer): use flock for atomic chat append`
  - _Review issue: CRITICAL #4 (external-reviewer.md)_

- [x] 5.5 [VERIFY] Critical path: atomic write consistency across all 4 files
  - **Do**: Verify all 4 files now use consistent flock-based atomic write pattern
  - **Verify**:
    ```bash
    for f in specs/agent-chat-protocol/design.md specs/agent-chat-protocol/requirements.md specs/agent-chat-protocol/tasks.md plugins/ralph-specum/agents/external-reviewer.md; do
      echo "=== $f ===" && grep -l "flock" "$f" && echo "flock: OK" || echo "flock: MISSING"
    done
    ```
  - **Done when**: All 4 files contain flock
  - **Commit**: `chore: verify atomic write fix consistency`

### Phase 5.2: Inconsistencies

- [x] 5.6 [FIX] Fix design.md architecture diagram — remove .chat-state.*.json
  - **Do**:
    1. Read `specs/agent-chat-protocol/design.md` — Mermaid diagram
    2. Remove `.chat-state.executor.json` and `.chat-state.reviewer.json` boxes
    3. Add `.ralph-state.json` box showing per-agent state inside
  - **Files**: `specs/agent-chat-protocol/design.md`
  - **Done when**: Diagram shows `.ralph-state.json` (not separate `.chat-state.*.json`)
  - **Verify**: `grep -n "chat-state" specs/agent-chat-protocol/design.md`
  - **Commit**: `fix(design): update architecture diagram to use .ralph-state.json`
  - _Review issue: MAJOR #3 (line 96)_

- [x] 5.7 [FIX] Fix Component: Chat Channel section — remove .chat-state references
  - **Do**:
    1. Read `specs/agent-chat-protocol/design.md` — "Component: Chat Channel" section
    2. Change all `.chat-state.{agent}.json` references to `.ralph-state.json` → `chat.{executor|reviewer}`
    3. Change `lastReadIndex` → `lastReadLine` throughout
  - **Files**: `specs/agent-chat-protocol/design.md`
  - **Done when**: All .chat-state references removed from Chat Channel section
  - **Verify**: `grep "chat-state" specs/agent-chat-protocol/design.md`
  - **Commit**: `fix(design): remove .chat-state references, use .ralph-state.json`
  - _Review issue: MAJOR #3_
  - **Note**: Already fixed — task 5.6 update to architecture diagram propagated to entire file. Verification: `grep "chat-state" specs/agent-chat-protocol/design.md` returns no matches. `lastReadLine` already used throughout.

- [x] 5.8 [FIX] Rename lastReadIndex → lastReadLine across all spec files
  - **Do**:
    1. Replace all `lastReadIndex` with `lastReadLine` in design.md
    2. Replace all `lastReadIndex` with `lastReadLine` in requirements.md (FR-14 references it)
    3. Replace all `lastReadIndex` with `lastReadLine` in spec-executor.md agent (JSON field name)
    4. Replace all `lastReadIndex` with `lastReadLine` in external-reviewer.md agent (JSON field name)
    5. Add note: "lastReadLine is a line cursor, not message index — messages are multi-line (header + blank line + body)"
  - **Files**: `specs/agent-chat-protocol/design.md`, `specs/agent-chat-protocol/requirements.md`, `plugins/ralph-specum/agents/spec-executor.md`, `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: `lastReadIndex` gone from all 4 files, `lastReadLine` used with explanatory note
  - **Verify**:
    ```bash
    echo "=== design.md ===" && grep "lastReadIndex" specs/agent-chat-protocol/design.md || echo "CLEAN"
    echo "=== requirements.md ===" && grep "lastReadIndex" specs/agent-chat-protocol/requirements.md || echo "CLEAN"
    echo "=== spec-executor.md ===" && grep "lastReadIndex" plugins/ralph-specum/agents/spec-executor.md || echo "CLEAN"
    echo "=== external-reviewer.md ===" && grep "lastReadIndex" plugins/ralph-specum/agents/external-reviewer.md || echo "CLEAN"
    ```
  - **Commit**: `fix(design): rename lastReadIndex to lastReadLine across all spec files`
  - _Review issue: MAJOR #4 (line 130) — also covers requirements.md FR-14 and agent files_

- [x] 5.9 [FIX] Fix requirements.md — remove all .chat-state.*.json references
  - **Do**:
    1. Read `specs/agent-chat-protocol/requirements.md`
    2. Fix Dependencies table (around line 240): change "No change" to "Must modify"; remove "lastReadIndex stored separately"
    3. Fix FR-14 section (around lines 147-150): remove `.chat-state.executor.json` and `.chat-state.reviewer.json` references — these files do not exist, state is in `.ralph-state.json`
    4. Fix Dependency map section: remove `.chat-state.executor.json` and `.chat-state.reviewer.json` from the map
  - **Files**: `specs/agent-chat-protocol/requirements.md`
  - **Done when**: All `.chat-state.*.json` references gone from requirements.md; Dependencies table reflects `.ralph-state.json` design decision
  - **Verify**: `grep -n "chat-state" specs/agent-chat-protocol/requirements.md`
  - **Commit**: `fix(requirements): remove all .chat-state.*.json references — state in .ralph-state.json`
  - _Review issue: MAJOR #5 (line 240) — also covers lines 147-150 (FR-14 section) and Dependency map_

- [x] 5.10 [FIX] Fix design.md test runner inconsistency — remove vitest, use bats
  - **Do**:
    1. Read `specs/agent-chat-protocol/design.md` — Test Strategy section
    2. Remove vitest/TypeScript references (lines 356-361)
    3. Make bats the only test runner mentioned throughout
  - **Files**: `specs/agent-chat-protocol/design.md`
  - **Done when**: Only bats mentioned, no vitest references
  - **Verify**: `grep "vitest" specs/agent-chat-protocol/design.md && echo "STILL HAS vitest" || echo "CLEAN"`
  - **Commit**: `fix(design): remove vitest references, use bats consistently`
  - _Review issue: MAJOR #6 (lines 356-361 vs 418-429)_

- [x] 5.11 [FIX] Add language identifiers to fenced code blocks (markdownlint MD040)
  - **Do**:
    1. Read `specs/agent-chat-protocol/design.md`:
       - Line 278: ` ``` ` → ` ```bash `
       - Line 282: ` ``` ` → ` ```text `
       - Line 289: ` ``` ` → ` ```text `
       - Line 306: ` ``` ` → ` ```text `
    2. Read `specs/agent-chat-protocol/requirements.md`:
       - Line 43: ` ``` ` → ` ```text `
  - **Files**: `specs/agent-chat-protocol/design.md`, `specs/agent-chat-protocol/requirements.md`
  - **Done when**: All fenced code blocks have language identifiers
  - **Verify**: `grep -n "^```$" specs/agent-chat-protocol/design.md specs/agent-chat-protocol/requirements.md`
  - **Commit**: `fix(lint): add language identifiers to fenced code blocks`
  - _Review issues: MINOR #9, #10_

### Phase 5.3: external-reviewer.md Improvements

- [x] 5.12 [IMPROVE] Add tool permissions, Judge pattern, convergence detection, human as participant
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Add Section 1b — Tool Permissions (allowed/forbidden/conditional)
    3. Add Judge Pattern subsection — structured HOLD/DEADLOCK format with EVIDENCE required
    4. Add Convergence Detection — after 3 rounds without resolution, auto-escalate
    5. Add Human as Participant — human can use ACK/HOLD/CONTINUE, human voice always final
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: All 4 improvements present in external-reviewer.md
  - **Verify**:
    ```bash
    grep -c "Tools ALLOWED" plugins/ralph-specum/agents/external-reviewer.md
    grep -c "Judge Pattern" plugins/ralph-specum/agents/external-reviewer.md
    grep -c "Convergence Detection" plugins/ralph-specum/agents/external-reviewer.md
    grep -c "Human as Participant" plugins/ralph-specum/agents/external-reviewer.md
    ```
  - **Commit**: `feat(external-reviewer): add tool permissions, Judge pattern, convergence detection, human as participant`
  - _Review issues: Improvements A, B, C, D_

### Phase 5.4: Quality Gates

- [x] 5.13 [LINT] Run markdownlint on modified spec files
  - **Do**:
    1. Run markdownlint on: design.md, requirements.md
    2. Fix any MD040 or other lint errors
  - **Files**: `specs/agent-chat-protocol/design.md`, `specs/agent-chat-protocol/requirements.md`
  - **Done when**: No markdownlint errors
  - **Verify**: `command -v mdl && mdl specs/agent-chat-protocol/design.md || echo "MDL_SKIP"`
  - **Commit**: `chore: pass markdownlint on modified spec files`

- [ ] 5.14 [VERSION] Bump external-reviewer.md version for improvements
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md` frontmatter
    2. Bump version: 0.1.0 → 0.2.0 (minor — additive improvements)
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Version bumped to 0.2.0
  - **Verify**: `grep "^version:" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `chore(external-reviewer): bump version to 0.2.0 for reviewer improvements`

- [ ] 5.15 [PR] Update PR #9 with review fixes
  - **Do**:
    1. Stage all changes
    2. Commit: `fix(agent-chat-protocol): address PR #9 review feedback — atomic write bug, inconsistencies, reviewer improvements`
    3. Push to remote
  - **Files**: All modified files
  - **Done when**: Changes pushed and PR updated
  - **Commit**: `fix(agent-chat-protocol): address PR #9 review feedback`

## Review Issues Summary

| # | Issue | Severity | File(s) | Task |
|---|-------|----------|---------|------|
| 1 | Atomic write race condition | CRITICAL | design.md | 5.1 |
| 2 | lines=$(wc -l) before append | CRITICAL | design.md | 5.1 |
| 3 | FR-13 "rename to append" ambiguous | CRITICAL | requirements.md | 5.2 |
| 4 | Broken atomic patterns | CRITICAL | tasks.md, external-reviewer.md | 5.3, 5.4 |
| 5 | .chat-state.*.json vs .ralph-state.json | MAJOR | design.md | 5.6, 5.7 |
| 6 | lastReadIndex ambiguous (line ≠ message) | MAJOR | design.md | 5.8 |
| 7 | Dependencies table contradictory | MAJOR | requirements.md | 5.9 |
| 8 | vitest vs bats inconsistent | MAJOR | design.md | 5.10 |
| 9-10 | Code blocks without language id | MINOR | design.md, requirements.md | 5.11 |
| A | Tool permissions for reviewer | Improvement | external-reviewer.md | 5.12 |
| B | Judge pattern for structured escalation | Improvement | external-reviewer.md | 5.12 |
| C | Convergence detection (3 rounds) | Improvement | external-reviewer.md | 5.12 |
| D | Human as participant | Improvement | external-reviewer.md | 5.12 |
