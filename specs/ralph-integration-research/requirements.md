---
spec: ralph-integration-research
phase: requirements
created: 2026-01-22
---

# Requirements: Ralph Loop Dependency Removal

## Goal

Remove ralph-wiggum dependency by inlining stop-hook loop logic (~50 lines), reducing user setup from 2 plugin installs to 1 while maintaining all current functionality and improving robustness.

## User Decisions (from Interview)

| Decision | Response |
|----------|----------|
| Problem being solved | Remove dependencies, maximize robustness using industry best practices |
| Constraints | Must maintain current functionality, accept inlining ralph-loop logic internally |
| Success criteria | Users need fewer dependencies, simpler setup |
| Primary users | Plugin maintainers (us) and end users (people installing ralph-specum) |
| Priority tradeoffs | Robustness and reliability over feature additions |

## User Stories

### US-1: Zero-Dependency Installation

**As a** developer installing Smart Ralph
**I want to** install only the smart-ralph plugin
**So that** I can start using spec-driven development without hunting for dependencies

**Acceptance Criteria:**
- [ ] AC-1.1: `/plugin install ralph-specum@smart-ralph` works without prior plugin installs
- [ ] AC-1.2: No error messages about missing ralph-wiggum or ralph-loop
- [ ] AC-1.3: All commands functional immediately after install and restart

### US-2: Reliable Execution Loop

**As a** developer running `/ralph-specum:implement`
**I want to** have tasks execute until completion or max iterations
**So that** I don't need to manually re-run commands

**Acceptance Criteria:**
- [ ] AC-2.1: Stop hook blocks exit and continues execution when tasks remain
- [ ] AC-2.2: Stop hook allows exit when `ALL_TASKS_COMPLETE` detected in transcript
- [ ] AC-2.3: Stop hook respects `maxGlobalIterations` safety limit
- [ ] AC-2.4: No infinite loops - `stop_hook_active` flag checked
- [ ] AC-2.5: Loop terminates cleanly on completion (state file deleted)

### US-3: Graceful Cancellation

**As a** developer who needs to stop execution
**I want to** run `/ralph-specum:cancel` and have everything stop cleanly
**So that** I can resume later or start over without corrupt state

**Acceptance Criteria:**
- [ ] AC-3.1: `/cancel` stops execution immediately
- [ ] AC-3.2: State file `.ralph-state.json` deleted
- [ ] AC-3.3: Progress file `.progress.md` preserved
- [ ] AC-3.4: No orphaned processes or stuck hooks

### US-4: Consistent State Recovery

**As a** developer whose session was interrupted
**I want to** run `/ralph-specum:implement` and resume from where I left off
**So that** I don't lose completed work

**Acceptance Criteria:**
- [ ] AC-4.1: Implementation resumes from `taskIndex` in state file
- [ ] AC-4.2: Completed tasks (marked `[x]`) remain complete
- [ ] AC-4.3: Learnings in `.progress.md` accessible to resumed execution

### US-5: Clear Error Messages

**As a** developer encountering issues
**I want to** see actionable error messages
**So that** I know how to fix the problem

**Acceptance Criteria:**
- [ ] AC-5.1: Missing state file shows "Run /ralph-specum:implement to reinitialize"
- [ ] AC-5.2: Corrupt state file shows specific corruption details
- [ ] AC-5.3: Max retries shows task number and attempt count

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Stop hook returns `{"decision": "block", "reason": "..."}` when tasks incomplete | P0 | Exit code 0 + JSON on stdout; hook blocks session exit |
| FR-2 | Stop hook allows exit when `ALL_TASKS_COMPLETE` in transcript | P0 | grep transcript for signal; return empty/exit 0 |
| FR-3 | Stop hook checks `stop_hook_active` to prevent infinite loops | P0 | First check in hook; exit 0 immediately if true |
| FR-4 | Stop hook reads phase from `.ralph-state.json` | P0 | Only block when phase = "execution" |
| FR-5 | Coordinator prompt written directly (no skill invocation) | P0 | implement.md outputs prompt, not skill call |
| FR-6 | Cancel command cleans state without skill invocation | P0 | cancel.md deletes files directly, no /cancel-ralph |
| FR-7 | State file includes `maxGlobalIterations` field | P1 | Safety limit enforced by stop hook |
| FR-8 | Stop hook tracks iteration count for safety limit | P1 | Increment `globalIteration` on each loop |
| FR-9 | README removes ralph-wiggum dependency documentation | P1 | Installation shows single plugin install |
| FR-10 | Coordinator prompt includes focus recitation (todo pattern) | P2 | Last section recites current task focus |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Stop hook execution time | Latency | < 100ms per invocation |
| NFR-2 | Hook reliability | Success rate | 100% correct decision (block vs allow) |
| NFR-3 | State file size | Storage | < 1KB JSON |
| NFR-4 | Backward compatibility | Breaking changes | 0 spec file format changes |
| NFR-5 | Code addition | Lines | ~50-80 lines total in stop-watcher.sh |

## Glossary

| Term | Definition |
|------|------------|
| **Stop hook** | Claude Code hook triggered when session attempts to exit |
| **Coordinator** | The prompt that orchestrates task delegation via Task tool |
| **spec-executor** | Sub-agent that executes individual tasks |
| **Task tool** | Claude Code tool that spawns sub-agents with fresh context |
| **`stop_hook_active`** | Flag in hook input; true if hook already running (prevent recursion) |
| **Transcript path** | File path in hook input containing session conversation |
| **ALL_TASKS_COMPLETE** | Signal indicating all tasks finished; terminates loop |
| **TASK_COMPLETE** | Signal from spec-executor indicating single task finished |

## Out of Scope

- Context compaction improvements (todo pattern is P2, compaction is future)
- Dynamic task re-prioritization (not in current design)
- Multi-spec parallel execution (separate feature)
- Changes to spec-executor, qa-engineer, or Task tool delegation
- Changes to 4-layer verification (contradiction, uncommitted, checkmark, signal)
- Migration tooling for existing users (v2.0 users already have ralph-loop)

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| Claude Code hooks system | Platform | Stable, documented |
| `jq` command | Runtime | Optional (graceful fallback) |
| `grep` command | Runtime | Standard Unix |
| `.ralph-state.json` schema | Internal | Existing, add `globalIteration` field |

## Risk Identification

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Stop hook exit code 2 bug | Loop halts unexpectedly | Medium | Use exit 0 + JSON pattern (industry proven) |
| Infinite loop from hook recursion | Session hangs | Low | Check `stop_hook_active` first |
| Transcript not available | Can't detect completion | Low | Fallback to allowing exit |
| State file corruption mid-loop | Lost progress | Low | Validate JSON before reading |
| Breaking change for v2.0 users | User confusion | Medium | Document migration (remove ralph-wiggum) |

## Success Criteria

1. **Installation simplicity**: Single `/plugin install` command works
2. **Functional parity**: All existing commands work identically
3. **Robustness**: Loop completes or errors cleanly (no hangs)
4. **No regressions**: 4-layer verification, parallel tasks, VERIFY tasks all work
5. **Clean removal**: README and implement.md have no ralph-wiggum references

## Implementation Checklist (for Design Phase)

Files to modify:
- [ ] `hooks/scripts/stop-watcher.sh` - Add loop logic (~50 lines)
- [ ] `commands/implement.md` - Remove skill invocation, keep coordinator prompt
- [ ] `commands/cancel.md` - Remove skill invocation
- [ ] `README.md` - Remove ralph-wiggum dependency docs
- [ ] `CLAUDE.md` - Update dependency reference

Files unchanged:
- `agents/spec-executor.md` - Task execution unchanged
- `agents/qa-engineer.md` - VERIFY tasks unchanged
- `commands/*.md` (other) - No loop involvement

## Next Steps

1. Review requirements with stakeholder
2. Generate technical design specifying stop-hook implementation details
3. Create task breakdown following POC-first methodology
4. Execute implementation
