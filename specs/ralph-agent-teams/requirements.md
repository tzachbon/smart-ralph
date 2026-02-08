---
spec: ralph-agent-teams
phase: requirements
created: 2025-02-07T16:30:00Z
---

# Requirements: ralph-agent-teams

## Goal

Integrate agent teams into ralph-specum workflow phases (research, execution) to enable parallel task execution with shared task lists and inter-agent messaging, while ensuring reliable lifecycle management (create → delegate → shutdown → cleanup) and providing clear UX feedback for team operations.

## User Decisions

**From Goal Interview:**
- **Problem Type**: REFACTOR - Improve plugin architecture to use agent teams
- **Constraints**: Must integrate with existing ralph-specum codebase
- **Success**: Agent teams work for each ralph step with proper UX for creation/cleanup/startup

**From Requirements Interview:**
- **Primary Users**: End users via UI (users running ralph-specum commands)
- **Priority Tradeoffs**: Code quality and maintainability over development speed (clean architecture, proper lifecycle, robust error handling)
- **Reliability Requirement**: High - no resource leaks, graceful shutdown, proper cleanup on cancel/error

## User Stories

### US-1: Research Phase Team Creation
**As a** product manager
**I want to** create a research team with 3-5 parallel analysts
**So that** external research and codebase analysis completes faster with peer collaboration

**Acceptance Criteria:**
- [ ] AC-1.1: System creates team on `/ralph-specum:research` command execution
- [ ] AC-1.2: Team spawns 3-5 teammates based on research topic count (minimum 2: 1 research-analyst + 1 Explore)
- [ ] AC-1.3: Each teammate receives distinct research topic assignment
- [ ] AC-1.4: Teammates can exchange messages via SendMessage tool
- [ ] AC-1.5: System displays "Researching with N teammates..." message during team work
- [ ] AC-1.6: Team coordinator merges all teammate findings into research.md
- [ ] AC-1.7: Team shuts down after research merge completes

### US-2: Execution Phase Team Creation
**As a** developer
**I want to** create an execution team for parallel task batches
**So that** independent tasks execute concurrently with shared task coordination

**Acceptance Criteria:**
- [ ] AC-2.1: System creates team on `/ralph-specum:implement` when tasks.md contains [P] markers
- [ ] AC-2.2: Team spawns 2-3 executor teammates (configurable)
- [ ] AC-2.3: Teammates share single task list via TaskList tool
- [ ] AC-2.4: Teammates claim unblocked tasks automatically (via TaskUpdate owner field)
- [ ] AC-2.5: Teammates mark tasks complete after verification
- [ ] AC-2.6: Coordinator monitors team activity via idle notifications
- [ ] AC-2.7: Team shuts down after all tasks complete or max iterations reached

### US-3: Team Lifecycle Management
**As a** system
**I want to** manage team lifecycle across phases
**So that** no resource leaks occur and sessions transition cleanly

**Acceptance Criteria:**
- [ ] AC-3.1: System tracks active team in `.ralph-state.json` (teamName, teammateNames fields)
- [ ] AC-3.2: Phase transitions require current team shutdown before creating new team
- [ ] AC-3.3: System sends shutdown requests to all teammates before TeamDelete
- [ ] AC-3.4: TeamDelete only executes after all teammates approve shutdown
- [ ] AC-3.5: System clears team state from `.ralph-state.json` after deletion
- [ ] AC-3.6: Orphaned team detection occurs in stop-watcher.sh (checks `~/.claude/teams/`)

### US-4: Graceful Cancellation with Teams
**As a** user
**I want to** cancel execution with proper team cleanup
**So that** no orphaned processes or state remain

**Acceptance Criteria:**
- [ ] AC-4.1: `/ralph-specum:cancel` checks `.ralph-state.json` for active team
- [ ] AC-4.2: Cancel sends shutdown_request to all teammates if team exists
- [ ] AC-4.3: Cancel waits up to 10 seconds for teammate shutdown approval
- [ ] AC-4.4: If teammates don't respond, cancel proceeds with TeamDelete (forced cleanup)
- [ ] AC-4.5: Cancel removes spec directory and `.current-spec` after team cleanup
- [ ] AC-4.6: Cancel outputs team shutdown status in cleanup confirmation

### US-5: Team Visibility and Feedback
**As a** user
**I want to** see team activity and progress
**So that** I understand what parallel work is happening

**Acceptance Criteria:**
- [ ] AC-5.1: `/ralph-specum:status` displays active team name and teammate count
- [ ] AC-5.2: Status shows each teammate's current task (from TaskList owner field)
- [ ] AC-5.3: Status displays teammate idle/working state
- [ ] AC-5.4: Progress messages include teammate name when claiming/completeing tasks
- [ ] AC-5.5: System provides hint: "Use Shift+Up/Down to message teammates directly"
- [ ] AC-5.6: Errors include teammate name if specific agent caused failure

### US-6: Error Handling and Recovery
**As a** system
**I want to** handle teammate failures gracefully
**So that** partial failures don't block entire phase

**Acceptance Criteria:**
- [ ] AC-6.1: Failed teammate tasks retry up to maxTaskIterations (default: 5)
- [ ] AC-6.2: System spawns new teammate if original stops responding
- [ ] AC-6.3: Coordinator marks failed tasks as blocked if all retries exhausted
- [ ] AC-6.4: Team creation failures fall back to manual Task tool delegation
- [ ] AC-6.5: TeamDelete failures logged with tmux session IDs for manual cleanup
- [ ] AC-6.6: Unresponsive teammates detected after 5 minutes of idle + no task claim

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Research phase team creation | Must Have | AC-1.1 through AC-1.7 |
| FR-2 | Execution phase team creation | Must Have | AC-2.1 through AC-2.7 |
| FR-3 | Team state tracking in state file | Must Have | AC-3.1, AC-3.5 |
| FR-4 | Shutdown protocol before TeamDelete | Must Have | AC-3.2, AC-3.3, AC-3.4 |
| FR-5 | Orphaned team detection | Must Have | AC-3.6 |
| FR-6 | Cancel command team cleanup | Must Have | AC-4.1 through AC-4.6 |
| FR-7 | Status command team display | Should Have | AC-5.1, AC-5.2, AC-5.3, AC-5.4 |
| FR-8 | User messaging hint | Should Have | AC-5.5 |
| FR-9 | Teammate failure recovery | Must Have | AC-6.1, AC-6.2, AC-6.3 |
| FR-10 | Team creation fallback | Should Have | AC-6.4 |
| FR-11 | TeamDelete failure logging | Must Have | AC-6.5 |
| FR-12 | Unresponsive teammate detection | Should Have | AC-6.6 |
| FR-13 | Environment variable check | Should Have | System verifies CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 before team creation |
| FR-14 | Team size configuration | Could Have | Configurable teammate count per phase via plugin settings |
| FR-15 | Manual team cleanup command | Could Have | `/ralph-specum:cleanup-teams` command for orphaned teams |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Resource leak prevention | Orphaned tmux sessions | Zero after normal flow |
| NFR-2 | Graceful shutdown reliability | Successful cleanup rate | 100% (cancel/error paths) |
| NFR-3 | Team creation latency | Time to first teammate spawn | < 5 seconds |
| NFR-4 | State consistency | .ralph-state.json accuracy | 100% (teamName matches actual) |
| NFR-5 | Error message clarity | User understands failure | Actionable error with teammate name |
| NFR-6 | Token efficiency | Overhead vs. manual Task delegation | < 20% increase |
| NFR-7 | Backward compatibility | Existing specs without teams | 100% (fallback to Task tool) |
| NFR-8 | Code maintainability | Lifecycle complexity | Single responsibility per command |
| NFR-9 | Test coverage | Team lifecycle paths | 90%+ (create, delegate, shutdown, delete) |
| NFR-10 | Documentation completeness | Team integration examples | All phases documented |

## Glossary

- **Agent Team**: Claude Code feature for parallel execution with shared task lists and inter-agent messaging
- **Teammate**: Individual agent instance within a team (e.g., "researcher-1", "executor-2")
- **Team Lead**: Agent that creates the team and coordinates teammates (ralph-specum command agent)
- **Shutdown Protocol**: Process of sending shutdown_request to all teammates and waiting for approval before TeamDelete
- **Orphaned Team**: Team directory in `~/.claude/teams/` without corresponding state file entry
- **One Team Per Session**: Claude Code limitation - only one active team per session (phase)
- **Idle Notification**: System message when teammate stops (normal, waiting for input)
- **Task Claim**: Teammate sets owner field via TaskUpdate to indicate work in progress
- **Delegation Pattern**: Using Task tool to spawn subagents (legacy approach, pre-teams)
- **Shared Task List**: Single task directory (`~/.claude/tasks/{team-name}/`) accessible to all teammates

## Out of Scope

- Agent teams for requirements phase (single product-manager works well)
- Agent teams for design phase (single architect-reviewer works well)
- Agent teams for tasks phase (single task-planner works well)
- Persistent teams across multiple phases (violates one-team-per-session)
- Visual team UI in terminal (text-based feedback only)
- Automatic team creation on plugin load (manual via commands only)
- Team activity split-pane view (use Shift+Up/Down for messaging)
- Custom teammate types beyond existing subagents (research-analyst, spec-executor, etc.)
- Distributed teams across multiple machines (single machine only)

## Dependencies

| ID | Dependency | Type | Criticality |
|----|------------|------|-------------|
| D-1 | Claude Code agent teams API | External | Must Have |
| D-2 | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 env var | External | Must Have |
| D-3 | TeamCreate tool availability | External | Must Have |
| D-4 | SendMessage tool availability | External | Must Have |
| D-5 | TeamDelete tool availability | External | Must Have |
| D-6 | TaskList/TaskGet/TaskUpdate tools | External | Must Have |
| D-7 | Existing ralph-specum commands (research.md, implement.md, cancel.md) | Internal | Must Have |
| D-8 | .ralph-state.json schema extension | Internal | Must Have |
| D-9 | stop-watcher.sh orphan detection logic | Internal | Should Have |
| D-10 | Plugin settings schema for team configuration | Internal | Could Have |

## Success Criteria

1. **Reliability**: Zero resource leaks after 100 consecutive spec executions (team creation → work → shutdown → delete)
2. **Graceful Cancellation**: 100% successful cleanup when user interrupts active team (verified via `~/.claude/teams/` directory check)
3. **Backward Compatibility**: All existing specs run without modification (fallback to Task tool if teams unavailable)
4. **Performance**: Research phase completes 30% faster with 3-5 teammates vs. sequential Task calls
5. **Error Clarity**: 95% of users can identify which teammate failed from error message (via teammate name)
6. **Code Quality**: Team lifecycle logic isolated to single responsibility functions (< 50 lines per lifecycle phase)
7. **Documentation**: All ralph-specum commands include team integration examples in docstring

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| TeamDelete hangs if teammate unresponsive | High | Medium | Implement 10-second timeout + forced cleanup |
| Orphaned tmux sessions accumulate | High | Medium | stop-watcher.sh detection + manual cleanup command |
| One-team-per-session breaks parallel phases | High | Low | Create/shutdown team per phase, not per spec |
| Token cost spike with large teams | Medium | High | Default to 2-3 teammates, document cost implications |
| User confusion during teammate failures | Medium | Medium | Error messages include teammate name + action steps |
| Race conditions in task claiming | Medium | Low | Use TaskUpdate atomic operations, test with 5+ teammates |
| State file desynchronization | High | Low | Validate teamName against `~/.claude/teams/` on every phase transition |
| Claude Code API changes break integration | High | Low | Version lock agent teams requirement, document API version |

## Unresolved Questions

- Should team size be user-configurable per phase or fixed? (Default: 3 for research, 2 for execution)
- How to handle teammate rejection of shutdown request? (Default: Wait 10s then force delete)
- Should we add visual progress bars for parallel teammates? (Deferred: Out of scope for v1)
- What happens if Claude Code session terminates abruptly during team work? (Mitigation: stop-watcher.sh detection on next start)
- Should requirements/design phases use single-person teams for consistency? (Decision: No, single-agent is sufficient)
- How to display teammate messages in terminal output? (Decision: Prefix with "[teammate-name]" for clarity)

## Next Steps

1. Design state file schema extensions (teamName, teammateNames fields) with validation
2. Create team lifecycle helper functions (createTeam, shutdownTeam, cleanupTeam, detectOrphans)
3. Implement research phase team integration in research.md command
4. Implement execution phase team integration in implement.md coordinator
5. Add team cleanup to cancel.md command
6. Extend status.md to display team information
7. Write tests for team lifecycle paths (create, delegate, shutdown, delete, error paths)
8. Document agent teams integration in README and command docstrings
9. Create fallback logic for environments without agent teams enabled
10. Add orphaned team detection to stop-watcher.sh
