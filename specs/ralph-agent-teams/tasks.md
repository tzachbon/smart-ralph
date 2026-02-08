---
spec: ralph-agent-teams
phase: tasks
total_tasks: 42
created: 2025-02-07T19:00:00Z
---

# Tasks: ralph-agent-teams

## Execution Context

**From Goal Interview:**
- Problem Type: REFACTOR - Improve plugin architecture to use agent teams
- Testing Depth: Standard - unit + integration tests
- Deployment: Marketplace submission + GitHub fork

**From Requirements Interview:**
- Primary Users: End users running ralph-specum commands
- Priority: Balanced - good quality with reasonable speed
- Reliability: High - no resource leaks, graceful shutdown

## Phase 1: Make It Work (POC)

Focus: Validate agent teams work end-to-end. Skip tests, accept hardcoded values.

- [x] 1.1 [VERIFY] Extend state schema for team tracking
  - **Do**:
    1. Read `plugins/ralph-specum/schemas/spec.schema.json`
    2. Add teamName (string, optional), teammateNames (array of strings, optional), teamPhase (enum: research|execution, optional) to definitions.state.properties
    3. Ensure all new fields are optional (not in required array)
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema validates with team fields
  - **Verify**: `cat plugins/ralph-specum/schemas/spec.schema.json | jq '.definitions.state.properties | keys | map(select(. == "teamName" or . == "teammateNames" or . == "teamPhase"))'` returns all 3 field names
  - **Commit**: `feat(schema): add team state fields to spec.schema.json`
  - _Requirements: AC-3.1, AC-3.5, FR-3_
  - _Design: State File Extension section_

- [x] 1.2 Bump plugin version to 3.2.0
  - **Do**:
    1. Update `plugins/ralph-specum/.claude-plugin/plugin.json` version from "3.1.2" to "3.2.0"
    2. Update `.claude-plugin/marketplace.json` ralph-specum version to "3.2.0"
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 3.2.0
  - **Verify**: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json && jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json` both return "3.2.0"
  - **Commit**: `chore(release): bump version to 3.2.0 for agent teams feature`
  - _Requirements: FR-15_
  - _Design: Plugin Metadata section_

- [x] 1.3 Create team-research skill [COMPLETED-VERIFIED]
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/team-research/`
    2. Create SKILL.md with frontmatter (name: team-research, description: auto-invoked research team management)
    3. Document skill workflow: TeamCreate → spawn 3-5 teammates → merge findings → shutdown → TeamDelete
    4. Include environment check for CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
    5. Add fallback to Task tool if teams unavailable
    6. Document team naming pattern: "research-{specName}-{timestamp}"
  - **Files**: `plugins/ralph-specum/skills/team-research/SKILL.md`
  - **Done when**: Skill file exists with frontmatter and complete workflow documentation
  - **Verify**: `head -10 plugins/ralph-specum/skills/team-research/SKILL.md | grep -E '^(name:|description:)'` returns both fields
  - **Commit**: `feat(skills): add team-research skill for parallel research`
  - _Requirements: AC-1.1 through AC-1.7, FR-1, FR-13_
  - _Design: Components - New Team-Based Skills section_

- [x] 1.4 Create team-execution skill
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/team-execution/`
    2. Create SKILL.md with frontmatter (name: team-execution, description: auto-invoked execution team for parallel tasks)
    3. Document skill workflow: TeamCreate → spawn 2-3 teammates → TaskList coordination → monitor idle → shutdown → TeamDelete
    4. Include [P] marker detection logic
    5. Add fallback to existing parallel batch execution
    6. Document team naming pattern: "exec-{specName}-{timestamp}"
  - **Files**: `plugins/ralph-specum/skills/team-execution/SKILL.md`
  - **Done when**: Skill file exists with frontmatter and complete workflow documentation
  - **Verify**: `head -10 plugins/ralph-specum/skills/team-execution/SKILL.md | grep -E '^(name:|description:)'` returns both fields
  - **Commit**: `feat(skills): add team-execution skill for parallel task batches`
  - _Requirements: AC-2.1 through AC-2.7, FR-2_
  - _Design: Components - New Team-Based Skills section_

- [x] 1.5 Create team-management skill
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/team-management/`
    2. Create SKILL.md with frontmatter (name: team-management, description: team status and cleanup utilities)
    3. Document state file querying logic (scan all specs for teamName)
    4. Document orphaned team detection (cross-reference ~/.claude/teams/ with state files)
    5. Include cleanup coordination workflow (prompt user, force TeamDelete)
  - **Files**: `plugins/ralph-specum/skills/team-management/SKILL.md`
  - **Done when**: Skill file exists with frontmatter and workflow documentation
  - **Verify**: `head -10 plugins/ralph-specum/skills/team-management/SKILL.md | grep -E '^(name:|description:)'` returns both fields
  - **Commit**: `feat(skills): add team-management skill for status and cleanup`
  - _Requirements: AC-3.6, AC-5.1 through AC-5.3, FR-5_
  - _Design: Components - New Team-Based Skills section_

- [x] 1.6 Modify research.md for team integration
  - **Do**:
    1. Read `plugins/ralph-specum/commands/research.md`
    2. Find the section after topic analysis (around line 100-200)
    3. Add environment check: `if [ -n "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" ] && [ "$TOPIC_COUNT" -ge 3 ]`
    4. Add skill invocation context setting when conditions met
    5. Preserve existing Task tool delegation as fallback
    6. Add research phase messaging: "Researching with N teammates..."
  - **Files**: `plugins/ralph-specum/commands/research.md`
  - **Done when**: research.md includes team check and skill delegation
  - **Verify**: `grep -n "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" plugins/ralph-specum/commands/research.md && grep -n "team-research" plugins/ralph-specum/commands/research.md` both return results
  - **Commit**: `feat(commands): integrate team-research skill into research.md`
  - _Requirements: AC-1.1, AC-1.5, AC-1.6, FR-1_
  - _Design: Modified Existing Commands - research.md section_

- [x] 1.7 Modify implement.md for team integration
  - **Do**:
    1. Read `plugins/ralph-specum/commands/implement.md`
    2. Find parallel group detection section (around line 237)
    3. Add environment check: `if [ -n "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" ] && [ "$PARALLEL_GROUP_COUNT" -gt 1 ]`
    4. Add skill invocation context setting when conditions met
    5. Preserve existing parallel batch execution as fallback
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md includes team check and skill delegation
  - **Verify**: `grep -n "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" plugins/ralph-specum/commands/implement.md && grep -n "team-execution" plugins/ralph-specum/commands/implement.md` both return results
  - **Commit**: `feat(commands): integrate team-execution skill into implement.md`
  - _Requirements: AC-2.1, AC-2.3, AC-2.6, FR-2_
  - _Design: Modified Existing Commands - implement.md section_

- [x] 1.8 Modify cancel.md for team cleanup
  - **Do**:
    1. Read `plugins/ralph-specum/commands/cancel.md`
    2. Find state file reading section (after line 50)
    3. Add teamName check from state file
    4. Add shutdown protocol: send shutdown_request to all teammates if team exists
    5. Add 10-second timeout with forced TeamDelete fallback
    6. Update cleanup confirmation output to include team shutdown status
  - **Files**: `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: cancel.md includes team shutdown protocol
  - **Verify**: `grep -n "teamName" plugins/ralph-specum/commands/cancel.md && grep -n "shutdown_request\|TeamDelete" plugins/ralph-specum/commands/cancel.md` both return results
  - **Commit**: `feat(commands): add team shutdown protocol to cancel.md`
  - _Requirements: AC-4.1 through AC-4.6, FR-6_
  - _Design: Modified Existing Commands - cancel.md section_

- [x] 1.9 Modify status.md for team display
  - **Do**:
    1. Read `plugins/ralph-specum/commands/status.md`
    2. Find status output section
    3. Add teamName display (if present in state)
    4. Add teammate count and phase display
    5. Add teammate idle/working state (from TaskList owner field if available)
    6. Add messaging hint: "Use Shift+Up/Down to message teammates directly"
  - **Files**: `plugins/ralph-specum/commands/status.md`
  - **Done when**: status.md includes team information display
  - **Verify**: `grep -n "teamName\|teammate\|Shift+Up/Down" plugins/ralph-specum/commands/status.md` returns results
  - **Commit**: `feat(commands): add team display to status.md`
  - _Requirements: AC-5.1 through AC-5.5, FR-7, FR-8_
  - _Design: Modified Existing Commands - status.md section_

- [x] 1.10 [VERIFY] Quality checkpoint: plugin lint check [QA-VERIFIED-PASS]
  - **Do**: Run validation on all modified plugin files
  - **Verify**: Check JSON syntax for schema and plugin.json files: `jq empty plugins/ralph-specum/schemas/spec.schema.json && jq empty plugins/ralph-specum/.claude-plugin/plugin.json && jq empty .claude-plugin/marketplace.json` - all exit 0
  - **Done when**: All JSON files parse correctly, markdown files have valid frontmatter
  - **Commit**: `chore(plugin): fix lint issues if any`
  - _Requirements: NFR-8_

- [x] 1.11 Create team-status command
  - **Do**:
    1. Create `plugins/ralph-specum/commands/team-status.md`
    2. Add command frontmatter (description: display active agent teams, argument-hint: [spec-name])
    3. Document workflow: invoke team-management skill, display active teams, display orphaned teams
    4. Include output format example (team name, phase, teammates with status)
  - **Files**: `plugins/ralph-specum/commands/team-status.md`
  - **Done when**: Command file exists with frontmatter and workflow
  - **Verify**: `head -10 plugins/ralph-specum/commands/team-status.md | grep -E '^(description:|argument-hint:)'` returns both fields
  - **Commit**: `feat(commands): add team-status command for team visibility`
  - _Requirements: AC-5.1 through AC-5.3, FR-7_
  - _Design: New Commands - team-status.md section_

- [x] 1.12 Create cleanup-teams command
  - **Do**:
    1. Create `plugins/ralph-specum/commands/cleanup-teams.md`
    2. Add command frontmatter (description: safely remove orphaned team directories)
    3. Document workflow: scan ~/.claude/teams/, cross-reference with state files, prompt for each orphan, force TeamDelete
    4. Include logging for each cleanup action
  - **Files**: `plugins/ralph-specum/commands/cleanup-teams.md`
  - **Done when**: Command file exists with frontmatter and workflow
  - **Verify**: `head -10 plugins/ralph-specum/commands/cleanup-teams.md | grep -E '^(description:)'` returns description field
  - **Commit**: `feat(commands): add cleanup-teams command for orphaned teams`
  - _Requirements: AC-3.6, FR-5_
  - _Design: New Commands - cleanup-teams.md section_

- [x] 1.13 [VERIFY] Quality checkpoint: command file validation [QA-VERIFIED-PASS]
  - **Do**: Validate all command files have proper frontmatter and structure
  - **Verify**: Check all modified/new commands have required frontmatter: `for f in plugins/ralph-specum/commands/*.md; do echo "=== $f ==="; head -5 "$f"; done | grep -E "^(description:|argument-hint:|===)"` shows all commands have frontmatter
  - **Done when**: All command files have valid frontmatter structure
  - **Commit**: `chore(commands): fix frontmatter issues if any`
  - _Requirements: NFR-8_

- [x] 1.14 Modify stop-watcher.sh for orphaned team detection
  - **Do**:
    1. Read `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Find the section where state files are checked
    3. Add orphaned team detection: scan ~/.claude/teams/ for directories
    4. Cross-reference team directories with .ralph-state.json files
    5. Log warnings for teams >1 hour old without matching state entry
    6. Include team directory path in warning for manual cleanup
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh includes orphaned team detection
  - **Verify**: `grep -n "\.claude/teams\|orphaned" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns results
  - **Commit**: `feat(hooks): add orphaned team detection to stop-watcher.sh`
  - _Requirements: AC-3.6, FR-5_
  - _Design: File Structure - Hooks section_

- [x] 1.15 Update spec-executor agent for team-aware execution
  - **Do**:
    1. Read `plugins/ralph-specum/agents/spec-executor.md`
    2. Find task claiming instructions
    3. Add team-aware claiming: use TaskList to see all tasks, claim via TaskUpdate(owner)
    4. Add idle monitoring instructions (normal when waiting for work)
    5. Add messaging guidance for team coordination
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor.md includes team-aware task claiming instructions
  - **Verify**: `grep -n "TaskList\|TaskUpdate.*owner\|teammate\|SendMessage" plugins/ralph-specum/agents/spec-executor.md` returns results
  - **Commit**: `feat(agents): add team-aware task claiming to spec-executor`
  - _Requirements: AC-2.3, AC-2.4, AC-2.5, FR-2_
  - _Design: Modified Existing Commands - implement.md section_

- [x] 1.16 Update research-analyst agent for teammate messaging
  - **Do**:
    1. Read `plugins/ralph-specum/agents/research-analyst.md`
    2. Add SendMessage tool usage guidance for cross-team discoveries
    3. Document when to message teammates (e.g., found relevant patterns, conflicting information)
    4. Include message format examples (teammate name as recipient)
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: research-analyst.md includes teammate messaging instructions
  - **Verify**: `grep -n "SendMessage\|teammate" plugins/ralph-specum/agents/research-analyst.md` returns results
  - **Commit**: `feat(agents): add teammate messaging guidance to research-analyst`
  - _Requirements: AC-1.4, AC-5.5, FR-1_
  - _Design: Modified Existing Commands - research.md section_

- [x] 1.17 [VERIFY] Quality checkpoint: skill and agent file validation [QA-VERIFIED-PASS]
  - **Do**: Validate all new skills and modified agents have proper structure
  - **Verify**: Check skill files exist and have frontmatter: `for f in plugins/ralph-specum/skills/*/SKILL.md; do echo "=== $f ==="; head -10 "$f" | grep -E "^(name:|description:)"; done` shows all skills have frontmatter. Check agents modified: `grep -l "teammate\|team" plugins/ralph-specum/agents/*.md` returns spec-executor.md and research-analyst.md
  - **Done when**: All skill and agent files properly structured
  - **Commit**: `chore(agents): fix skill/agent structure issues if any`
  - _Requirements: NFR-8_

- [ ] 1.18 POC Checkpoint: Manual test research phase with teams
  - **Do**:
    1. Create test spec: `/ralph-specum:new test-teams-research "Test agent teams in research phase with web search and codebase analysis"`
    2. Run `/ralph-specum:research test-teams-research`
    3. Set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in environment before running
    4. Observe team creation message and teammate spawning
    5. Verify research.md is created with merged findings
    6. Verify team deletion after research completes
    7. Check .ralph-state.json has no teamName after completion
  - **Done when**: Research phase completes with team, no orphaned processes
  - **Verify**: `ls ~/.claude/teams/ | grep "research-test-teams-research"` returns empty (team deleted), and `cat ./specs/test-teams-research/.ralph-state.json | jq '.teamName'` returns null
  - **Commit**: `test(poc): verify research phase team integration end-to-end`
  - _Requirements: AC-1.1 through AC-1.7, FR-1_
  - _Design: Test Strategy - Integration Tests section_

- [ ] 1.19 POC Checkpoint: Manual test execution phase with teams
  - **Do**:
    1. Create test spec with tasks.md containing 3 consecutive [P] tasks
    2. Run `/ralph-specum:implement test-teams-exec` with teams enabled
    3. Observe team creation message and teammate spawning
    4. Verify tasks are claimed and marked complete
    5. Verify team deletion after all tasks complete
    6. Check .ralph-state.json taskIndex advanced past parallel group
  - **Done when**: Execution phase completes with team, all tasks marked [x]
  - **Verify**: `grep -c "^\- \[x\]" ./specs/test-teams-exec/tasks.md` equals 3 (all tasks complete), and `cat ./specs/test-teams-exec/.ralph-state.json | jq '.teamName'` returns null
  - **Commit**: `test(poc): verify execution phase team integration end-to-end`
  - _Requirements: AC-2.1 through AC-2.7, FR-2_
  - _Design: Test Strategy - Integration Tests section_

- [ ] 1.20 POC Checkpoint: Manual test cancel with active team
  - **Do**:
    1. Start research phase and wait for team spawn
    2. Run `/ralph-specum:cancel test-teams-cancel` while team active
    3. Observe shutdown requests sent to teammates
    4. Verify TeamDelete executes
    5. Verify spec directory removed
    6. Check no team directory remains in ~/.claude/teams/
  - **Done when**: Cancel successfully cleans up team and spec
  - **Verify**: `ls ~/.claude/teams/` does NOT contain the canceled team directory, and `ls ./specs/test-teams-cancel/` returns "No such file or directory"
  - **Commit**: `test(poc): verify cancel with active team cleanup`
  - _Requirements: AC-4.1 through AC-4.6, FR-6_
  - _Design: Test Strategy - Integration Tests section_

- [ ] 1.21 POC Checkpoint: Verify backward compatibility (no teams)
  - **Do**:
    1. Unset CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
    2. Run `/ralph-specum:research test-no-teams`
    3. Verify command completes using Task tool delegation (no team creation)
    4. Run `/ralph-specum:implement test-no-teams` (skip to implementation)
    5. Verify sequential execution without teams
  - **Done when**: Both phases complete successfully without teams
  - **Verify**: `ls ~/.claude/teams/` does NOT create new teams, and research.md/tasks.md are created normally
  - **Commit**: `test(poc): verify backward compatibility without teams`
  - _Requirements: NFR-7, FR-10_
  - _Design: Test Strategy - Manual Tests section_

## Phase 2: Refactoring

After POC validated, clean up code structure and improve error handling.

- [ ] 2.1 Refactor team lifecycle helper patterns
  - **Do**:
    1. Review all skills for common lifecycle patterns (create, shutdown, delete)
    2. Extract common state file merge pattern into reusable documentation section
    3. Ensure consistent jq merge pattern across all skills: `. + {newFields}`
    4. Add consistent error handling for TeamCreate/TeamDelete failures
    5. Add consistent timeout handling (10s for shutdown)
  - **Files**: `plugins/ralph-specum/skills/team-research/SKILL.md`, `plugins/ralph-specum/skills/team-execution/SKILL.md`, `plugins/ralph-specum/skills/team-management/SKILL.md`
  - **Done when**: All skills follow consistent lifecycle patterns
  - **Verify**: `grep -n "jq.*\+ *{" plugins/ralph-specum/skills/*/SKILL.md | wc -l` shows consistent merge pattern usage across skills
  - **Commit**: `refactor(skills): standardize team lifecycle patterns across skills`
  - _Requirements: NFR-6, NFR-8_
  - _Design: Technical Decisions - State management_

- [ ] 2.2 Add comprehensive error handling to team-research skill
  - **Do**:
    1. Add TeamCreate failure handling (fallback to Task tool with warning)
    2. Add teammate spawn failure handling (retry once, then fallback)
    3. Add findings merge error handling (log partial results, continue)
    4. Add TeamDelete failure handling (log tmux session ID, suggest cleanup)
    5. Ensure all error messages include teamName for debugging
  - **Files**: `plugins/ralph-specum/skills/team-research/SKILL.md`
  - **Done when**: All error paths documented with handling strategies
  - **Verify**: `grep -c "ERROR\|WARNING\|fallback" plugins/ralph-specum/skills/team-research/SKILL.md` returns >=5 error handling sections
  - **Commit**: `refactor(skills): add error handling to team-research skill`
  - _Requirements: AC-6.1 through AC-6.6, FR-9, FR-11_
  - _Design: Error Handling section_

- [ ] 2.3 Add comprehensive error handling to team-execution skill
  - **Do**:
    1. Add TeamCreate failure handling (fallback to parallel batch execution)
    2. Add TaskList unavailable handling (fallback to file-based coordination)
    3. Add teammate failure handling (spawn replacement teammate)
    4. Add TaskUpdate conflict handling (retry with different task)
    5. Add TeamDelete failure handling (log error with team directory)
  - **Files**: `plugins/ralph-specum/skills/team-execution/SKILL.md`
  - **Done when**: All error paths documented with handling strategies
  - **Verify**: `grep -c "ERROR\|WARNING\|fallback\|retry" plugins/ralph-specum/skills/team-execution/SKILL.md` returns >=5 error handling sections
  - **Commit**: `refactor(skills): add error handling to team-execution skill`
  - _Requirements: AC-6.1 through AC-6.6, FR-9, FR-11_
  - _Design: Error Handling section_

- [ ] 2.4 [VERIFY] Quality checkpoint: error handling validation
  - **Do**: Verify all skills have comprehensive error handling
  - **Verify**: Check for error handling keywords: `grep -E "ERROR|WARNING|fallback|retry|TeamCreate fails|TeamDelete fails" plugins/ralph-specum/skills/team-*/SKILL.md | wc -l` shows >=10 total error handling sections across all team skills
  - **Done when**: All major error scenarios documented
  - **Commit**: `chore(skills): ensure comprehensive error coverage`
  - _Requirements: NFR-2_

- [ ] 2.5 Refactor state file operations for atomicity
  - **Do**:
    1. Review all commands that modify .ralph-state.json
    2. Ensure all use jq merge pattern (not overwrite)
    3. Add race condition safeguards (check modification time before update)
    4. Add validation after update (verify file is valid JSON)
    5. Document atomic update pattern in commands
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/implement.md`, `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: All state updates use atomic merge pattern
  - **Verify**: `grep -n "jq.*\+ *{" plugins/ralph-specum/commands/*.md | grep -v "cat\|echo" | wc -l` shows merge pattern in all state-modifying commands
  - **Commit**: `refactor(commands): ensure atomic state file updates`
  - _Requirements: NFR-4, AC-3.1_
  - _Design: Existing Patterns to Follow - State merge pattern_

- [ ] 2.6 Add inline documentation for team integration
  - **Do**:
    1. Add comments to research.md explaining when teams are invoked
    2. Add comments to implement.md explaining [P] marker detection
    3. Add comments to cancel.md explaining shutdown protocol flow
    4. Add comments to status.md explaining team data sources
    5. Ensure all skill invocations have context documentation
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/implement.md`, `plugins/ralph-specum/commands/cancel.md`, `plugins/ralph-specum/commands/status.md`
  - **Done when**: All team-related code sections have explanatory comments
  - **Verify**: `grep -c "Team integration:\|Team workflow:\|Note:" plugins/ralph-specum/commands/*.md` returns >=5 documentation comments
  - **Commit**: `docs(commands): add inline documentation for team integration`
  - _Requirements: NFR-10_
  - _Design: Why Skills-Based Architecture? section_

- [ ] 2.7 [VERIFY] Quality checkpoint: code quality validation
  - **Do**: Run code quality checks on all modified files
  - **Verify**: Check JSON validity: `jq empty plugins/ralph-specum/schemas/spec.schema.json && jq empty plugins/ralph-specum/.claude-plugin/plugin.json && jq empty .claude-plugin/marketplace.json` all exit 0. Check markdown structure: `for f in plugins/ralph-specum/commands/*.md plugins/ralph-specum/skills/*/SKILL.md; do head -5 "$f" | grep -q "^---" || echo "Missing frontmatter: $f"; done` returns no errors
  - **Done when**: All files pass validation
  - **Commit**: `chore(plugin): fix quality issues if any`
  - _Requirements: NFR-8_

## Phase 3: Testing

Add unit and integration tests for team lifecycle.

- [ ] 3.1 Create unit test for state schema team fields
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/test-state-schema.sh`
    2. Test 1: Verify teamName field accepts valid string
    3. Test 2: Verify teammateNames field accepts array of strings
    4. Test 3: Verify teamPhase field accepts "research" or "execution"
    5. Test 4: Verify all team fields are optional (state valid without them)
    6. Test 5: Verify merge pattern preserves team fields
  - **Files**: `plugins/ralph-specum/tests/test-state-schema.sh`
  - **Done when**: Test file exists with 5 test cases, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/test-state-schema.sh` exits 0 and outputs "All tests passed"
  - **Commit**: `test(skills): add unit tests for state schema team fields`
  - _Requirements: AC-3.1, AC-3.5_
  - _Design: Test Strategy - Unit Tests section_

- [ ] 3.2 Create unit test for team creation validation
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/test-team-creation.sh`
    2. Test 1: Verify team creation fails if existing teamName in state
    3. Test 2: Verify team naming pattern (research-{spec}-{ts})
    4. Test 3: Verify environment check (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
    5. Test 4: Verify state file update includes teamName, teammateNames, teamPhase
    6. Test 5: Verify fallback behavior when teams unavailable
  - **Files**: `plugins/ralph-specum/tests/test-team-creation.sh`
  - **Done when**: Test file exists with 5 test cases, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/test-team-creation.sh` exits 0 and outputs "All tests passed"
  - **Commit**: `test(skills): add unit tests for team creation validation`
  - _Requirements: AC-3.2, AC-3.3, FR-3, FR-13_

- [ ] 3.3 Create unit test for shutdown protocol
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/test-shutdown-protocol.sh`
    2. Test 1: Verify shutdown_request sent to all teammates
    3. Test 2: Verify 10-second timeout when no response
    4. Test 3: Verify TeamDelete called after all approvals
    5. Test 4: Verify state file team fields cleared after deletion
    6. Test 5: Verify forced cleanup when teammates unresponsive
  - **Files**: `plugins/ralph-specum/tests/test-shutdown-protocol.sh`
  - **Done when**: Test file exists with 5 test cases, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/test-shutdown-protocol.sh` exits 0 and outputs "All tests passed"
  - **Commit**: `test(skills): add unit tests for shutdown protocol`
  - _Requirements: AC-3.3, AC-3.4, AC-4.2, AC-4.3_

- [ ] 3.4 [VERIFY] Quality checkpoint: unit tests pass
  - **Do**: Run all unit tests and verify they pass
  - **Verify**: `bash plugins/ralph-specum/tests/test-state-schema.sh && bash plugins/ralph-specum/tests/test-team-creation.sh && bash plugins/ralph-specum/tests/test-shutdown-protocol.sh` all exit 0
  - **Done when**: All unit tests pass
  - **Commit**: `chore(test): fix failing unit tests if any`
  - _Requirements: NFR-9_

- [ ] 3.5 Create integration test for research phase team flow
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/integration/test-research-team.sh`
    2. Test 1: Create spec with multi-topic goal
    3. Test 2: Run research phase with teams enabled
    4. Test 3: Verify team created (check ~/.claude/teams/)
    5. Test 4: Verify 3-5 teammates spawned
    6. Test 5: Verify research.md merged from all findings
    7. Test 6: Verify team deleted after completion
    8. Test 7: Verify state file cleared of team fields
    9. Clean up test spec
  - **Files**: `plugins/ralph-specum/tests/integration/test-research-team.sh`
  - **Done when**: Test file exists with 7 test steps, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/integration/test-research-team.sh` exits 0 and creates research.md, leaves no orphaned teams
  - **Commit**: `test(integration): add research phase team flow test`
  - _Requirements: AC-1.1 through AC-1.7, FR-1_
  - _Design: Test Strategy - Integration Tests section_

- [ ] 3.6 Create integration test for execution phase team flow
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/integration/test-execution-team.sh`
    2. Test 1: Create spec with tasks.md containing 3 [P] tasks
    3. Test 2: Run implement phase with teams enabled
    4. Test 3: Verify team created
    5. Test 4: Verify 2-3 teammates spawned
    6. Test 5: Verify tasks claimed and marked [x]
    7. Test 6: Verify team deleted after all tasks complete
    8. Test 7: Verify state taskIndex advanced
    9. Clean up test spec
  - **Files**: `plugins/ralph-specum/tests/integration/test-execution-team.sh`
  - **Done when**: Test file exists with 7 test steps, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/integration/test-execution-team.sh` exits 0, all tasks marked [x], no orphaned teams
  - **Commit**: `test(integration): add execution phase team flow test`
  - _Requirements: AC-2.1 through AC-2.7, FR-2_

- [ ] 3.7 Create integration test for cancel with active team
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/integration/test-cancel-team.sh`
    2. Test 1: Start research phase and wait for team spawn
    3. Test 2: Run cancel command during team work
    4. Test 3: Verify shutdown requests sent
    5. Test 4: Verify TeamDelete executed
    6. Test 5: Verify spec directory removed
    7. Test 6: Verify no orphaned team in ~/.claude/teams/
    8. Clean up any remaining test artifacts
  - **Files**: `plugins/ralph-specum/tests/integration/test-cancel-team.sh`
  - **Done when**: Test file exists with 6 test steps, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/integration/test-cancel-team.sh` exits 0, no team directories remain, spec removed
  - **Commit**: `test(integration): add cancel with active team test`
  - _Requirements: AC-4.1 through AC-4.6, FR-6_

- [ ] 3.8 Create integration test for orphaned team detection
  - **Do**:
    1. Create test file `plugins/ralph-specum/tests/integration/test-orphan-detection.sh`
    2. Test 1: Manually create team directory without state file
    3. Test 2: Create .ralph-state.json without teamName field
    4. Test 3: Run stop-watcher.sh logic (simulate session stop)
    5. Test 4: Verify warning logged with team directory path
    6. Test 5: Run cleanup-teams command
    7. Test 6: Verify orphaned team removed
    8. Clean up test artifacts
  - **Files**: `plugins/ralph-specum/tests/integration/test-orphan-detection.sh`
  - **Done when**: Test file exists with 6 test steps, all pass
  - **Verify**: `bash plugins/ralph-specum/tests/integration/test-orphan-detection.sh` exits 0, orphaned team detected and cleaned up
  - **Commit**: `test(integration): add orphaned team detection test`
  - _Requirements: AC-3.6, FR-5_

- [ ] 3.9 [VERIFY] Quality checkpoint: integration tests pass
  - **Do**: Run all integration tests and verify they pass
  - **Verify**: `bash plugins/ralph-specum/tests/integration/test-research-team.sh && bash plugins/ralph-specum/tests/integration/test-execution-team.sh && bash plugins/ralph-specum/tests/integration/test-cancel-team.sh && bash plugins/ralph-specum/tests/integration/test-orphan-detection.sh` all exit 0
  - **Done when**: All integration tests pass
  - **Commit**: `chore(test): fix failing integration tests if any`
  - _Requirements: NFR-9_

- [ ] 3.10 Create manual test documentation
  - **Do**:
    1. Create file `plugins/ralph-specum/tests/manual/MANUAL_TESTS.md`
    2. Document backward compatibility test (no env var)
    3. Document cross-phase team isolation test
    4. Document high-stress parallel execution test (10 [P] tasks)
    5. Document visual verification test (check team-status output)
    6. Include expected results for each test
  - **Files**: `plugins/ralph-specum/tests/manual/MANUAL_TESTS.md`
  - **Done when**: Manual test documentation exists with 5 test scenarios
  - **Verify**: `grep -c "^## Test" plugins/ralph-specum/tests/manual/MANUAL_TESTS.md` returns >=5
  - **Commit**: `test(docs): add manual test documentation`
  - _Requirements: NFR-7, NFR-9_
  - _Design: Test Strategy - Manual Tests section_

- [ ] 3.11 [VERIFY] Quality checkpoint: test coverage validation
  - **Do**: Verify test coverage for all team lifecycle paths
  - **Verify**: Check test files exist: `ls -1 plugins/ralph-specum/tests/*.sh plugins/ralph-specum/tests/integration/*.sh | wc -l` returns >=7 (3 unit + 4 integration). Check manual test docs: `test -f plugins/ralph-specum/tests/manual/MANUAL_TESTS.md` returns 0
  - **Done when**: Test suite covers create, delegate, shutdown, delete, and error paths
  - **Commit**: `chore(test): ensure comprehensive test coverage`
  - _Requirements: NFR-9_

## Phase 4: Quality Gates

Final validation: lint, types, CI, marketplace submission.

- [ ] 4.1 [VERIFY] Local quality check: schema validation
  - **Do**: Validate all JSON schemas
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json` exits 0. Verify schema compiles without errors and includes team fields: `jq '.definitions.state.properties | keys | map(select(. == "teamName" or . == "teammateNames" or . == "teamPhase"))' plugins/ralph-specum/schemas/spec.schema.json` returns all 3 fields
  - **Done when**: Schema valid and team fields present
  - **Commit**: `chore(schema): fix schema validation issues if any`
  - _Requirements: NFR-4_

- [ ] 4.2 [VERIFY] Local quality check: plugin manifest validation
  - **Do**: Validate plugin.json and marketplace.json
  - **Verify**: `jq empty plugins/ralph-specum/.claude-plugin/plugin.json && jq empty .claude-plugin/marketplace.json` both exit 0. Verify version consistency: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json` equals `jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json` (both 3.2.0)
  - **Done when**: All plugin metadata valid and versions match
  - **Commit**: `chore(plugin): fix manifest validation issues if any`
  - _Requirements: NFR-8_

- [ ] 4.3 [VERIFY] Local quality check: command frontmatter validation
  - **Do**: Validate all command files have proper frontmatter
  - **Verify**: `for f in plugins/ralph-specum/commands/*.md; do echo "Checking: $f"; head -20 "$f" | grep -q "^description:" || echo "MISSING description in $f"; done` outputs no errors. Verify new commands exist: `ls -1 plugins/ralph-specum/commands/team-status.md plugins/ralph-specum/commands/cleanup-teams.md` returns both files
  - **Done when**: All commands have valid frontmatter
  - **Commit**: `chore(commands): fix frontmatter issues if any`
  - _Requirements: NFR-8_

- [ ] 4.4 [VERIFY] Local quality check: skill frontmatter validation
  - **Do**: Validate all skill files have proper frontmatter
  - **Verify**: `for f in plugins/ralph-specum/skills/*/SKILL.md; do echo "Checking: $f"; head -20 "$f" | grep -E "^name:|^description:" || echo "MISSING frontmatter in $f"; done` outputs no errors. Verify all team skills exist: `ls -1 plugins/ralph-specum/skills/team-research/SKILL.md plugins/ralph-specum/skills/team-execution/SKILL.md plugins/ralph-specum/skills/team-management/SKILL.md` returns all 3 files
  - **Done when**: All skills have valid frontmatter
  - **Commit**: `chore(skills): fix skill frontmatter issues if any`
  - _Requirements: NFR-8_

- [ ] 4.5 [VERIFY] Local quality check: hook script validation
  - **Do**: Validate stop-watcher.sh syntax
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` exits 0 (syntax check). Verify orphan detection present: `grep -n "\.claude/teams\|orphaned" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns results
  - **Done when**: Hook script syntax valid, orphan detection present
  - **Commit**: `chore(hooks): fix script syntax issues if any`
  - _Requirements: AC-3.6_

- [ ] 4.6 [VERIFY] Local quality check: agent documentation validation
  - **Do**: Validate agent modifications have proper documentation
  - **Verify**: Check spec-executor has team instructions: `grep -c "TaskList\|teammate\|owner" plugins/ralph-specum/agents/spec-executor.md` returns >=3. Check research-analyst has messaging instructions: `grep -c "SendMessage\|teammate" plugins/ralph-specum/agents/research-analyst.md` returns >=2
  - **Done when**: Agent modifications properly documented
  - **Commit**: `chore(agents): fix agent documentation if any issues`
  - _Requirements: AC-1.4, AC-2.4_

- [ ] 4.7 [VERIFY] Local quality check: all tests pass
  - **Do**: Run complete test suite
  - **Verify**: Run all unit tests: `for test in plugins/ralph-specum/tests/*.sh; do echo "Running: $test"; bash "$test" || exit 1; done` all exit 0. Run all integration tests: `for test in plugins/ralph-specum/tests/integration/*.sh; do echo "Running: $test"; bash "$test" || exit 1; done` all exit 0
  - **Done when**: All unit and integration tests pass
  - **Commit**: `chore(test): fix failing tests if any`
  - _Requirements: NFR-9_

- [ ] 4.8 [VERIFY] Documentation completeness check
  - **Do**: Verify all documentation is complete
  - **Verify**: Check README mentions agent teams: `grep -i "team\|CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" README.md | wc -l` returns >=1. Check new commands documented: `grep -E "team-status|cleanup-teams" README.md` returns results. Check manual test docs exist: `test -f plugins/ralph-specum/tests/manual/MANUAL_TESTS.md` returns 0
  - **Done when**: All team features documented
  - **Commit**: `docs(plugin): ensure complete agent teams documentation`
  - _Requirements: NFR-10_

- [ ] 4.9 Update README with agent teams feature
  - **Do**:
    1. Add "Agent Teams" section to README.md
    2. Document CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS requirement
    3. Document new commands: team-status, cleanup-teams
    4. Add troubleshooting section for team-related issues
    5. Include examples of team usage
  - **Files**: `README.md`
  - **Done when**: README includes comprehensive teams documentation
  - **Verify**: `grep -c "Agent Teams\|team-status\|cleanup-teams\|CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" README.md` returns >=10
  - **Commit**: `docs(readme): add agent teams feature documentation`
  - _Requirements: NFR-10_
  - _Design: Implementation Steps - Phase 6: Testing & Docs_

- [ ] 4.10 [VERIFY] Create changelog entry for v3.2.0
  - **Do**:
    1. Create or update CHANGELOG.md
    2. Add v3.2.0 section with date
    3. List new features: team-research skill, team-execution skill, team-management skill
    4. List new commands: team-status, cleanup-teams
    5. List enhancements: research phase parallelism, execution phase parallelism
    6. List bug fixes: graceful team shutdown, orphaned team cleanup
    7. List breaking changes (if any)
  - **Files**: `CHANGELOG.md` or `plugins/ralph-specum/CHANGELOG.md`
  - **Done when**: Changelog includes comprehensive v3.2.0 entry
  - **Verify**: `grep -A 20 "^## \[3.2.0\]" CHANGELOG.md | grep -c "team\|Team"` returns >=5
  - **Commit**: `docs(changelog): add v3.2.0 release notes`
  - _Requirements: NFR-10_
  - _Design: Implementation Steps - Phase 6: Testing & Docs_

- [ ] 4.11 Create GitHub fork setup documentation
  - **Do**:
    1. Create file `DEPLOYMENT.md` in repo root
    2. Document GitHub fork creation steps
    3. Document plugin submission to https://code.claude.com/docs/en/plugin-marketplaces
    4. Include marketplace metadata requirements
    5. Include version tagging guidelines
    6. Add troubleshooting section for marketplace submission
  - **Files**: `DEPLOYMENT.md`
  - **Done when**: Deployment guide exists with GitHub + marketplace instructions
  - **Verify**: `grep -c "GitHub\|marketplace\|fork\|submission" DEPLOYMENT.md` returns >=8
  - **Commit**: `docs(deployment): add GitHub fork and marketplace submission guide`
  - _Requirements: FR-15, Deployment approach_
  - _Design: Implementation Steps - Phase 6: Testing & Docs_

- [ ] 4.12 [VERIFY] Final validation: end-to-end smoke test
  - **Do**:
    1. Create test spec: `/ralph-specum:new smoke-test "Test complete agent teams workflow"`
    2. Run `/ralph-specum:research smoke-test` with teams enabled
    3. Verify team created and deleted successfully
    4. Run `/ralph-specum:requirements smoke-test`
    5. Run `/ralph-specum:design smoke-test`
    6. Run `/ralph-specum:tasks smoke-test`
    7. Edit tasks.md to add [P] markers to 2 tasks
    8. Run `/ralph-specum:implement smoke-test` with teams enabled
    9. Verify team created and deleted successfully
    10. Run `/ralph-specum:status smoke-test` and verify team display
    11. Run `/ralph-specum:team-status smoke-test` and verify output
    12. Run `/ralph-specum:cancel smoke-test` and verify cleanup
    13. Verify no orphaned teams: `ls ~/.claude/teams/ | grep "smoke-test"` returns empty
    14. Verify spec removed: `ls ./specs/smoke-test/` returns "No such file or directory"
  - **Done when**: Complete workflow executes without errors, no orphaned resources
  - **Verify**: All 14 steps pass, no errors logged, zero orphaned teams
  - **Commit**: `test(e2e): verify complete agent teams workflow smoke test`
  - _Requirements: FR-1 through FR-15, NFR-1 through NFR-10_

## Phase 5: PR Lifecycle

Continuous validation until ALL completion criteria met.

- [ ] 5.1 Create feature branch
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. If on main, create feature branch: `git checkout -b feature/agent-teams`
    3. If already on feature branch, continue
  - **Files**: None (git operation)
  - **Done when**: On feature/agent-teams branch
  - **Verify**: `git branch --show-current` returns "feature/agent-teams"
  - **Commit**: None (branch creation)
  - _Requirements: NFR-8_

- [ ] 5.2 Commit all changes with conventional commits
  - **Do**:
    1. Stage all changes: `git add plugins/ralph-specum/ .claude-plugin/marketplace.json README.md CHANGELOG.md DEPLOYMENT.md`
    2. Review staged changes: `git diff --cached --stat`
    3. Create comprehensive commit: `git commit -m "feat(ralph-specum): add agent teams integration (v3.2.0)

- Add team-research, team-execution, team-management skills
- Integrate teams into research and implement phases
- Add team-status and cleanup-teams commands
- Extend state schema with team tracking fields
- Add orphaned team detection to stop-watcher.sh
- Update agents for team-aware execution
- Bump version to 3.2.0

Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

Closes #spec-ralph-agent-teams"`
  - **Files**: All modified files (git operation)
  - **Done when**: Changes committed to feature branch
  - **Verify**: `git log -1 --oneline` shows commit with conventional commit format
  - **Commit**: (see above)
  - _Requirements: NFR-8_

- [ ] 5.3 Push feature branch to remote
  - **Do**:
    1. Push branch to origin: `git push -u origin feature/agent-teams`
    2. Verify push succeeded
  - **Files**: None (git operation)
  - **Done when**: Branch pushed to remote repository
  - **Verify**: `git branch -vv | grep feature/agent-teams` shows remote tracking branch
  - **Commit**: None (push operation)
  - _Requirements: NFR-8_

- [ ] 5.4 Create pull request
  - **Do**:
    1. Create PR using gh CLI: `gh pr create --title "feat: Add agent teams integration to ralph-specum (v3.2.0)" --body "$(cat <<'EOF'
## Summary

Integrates Claude Code's agent teams API into ralph-specum for parallel research and execution phases.

### Changes

- **3 New Skills**: team-research, team-execution, team-management
- **2 New Commands**: /ralph-specum:team-status, /ralph-specum:cleanup-teams
- **Enhanced Commands**: research, implement, cancel, status with team integration
- **State Schema**: Extended with teamName, teammateNames, teamPhase fields
- **Orphan Detection**: stop-watcher.sh scans for orphaned teams
- **Agent Updates**: spec-executor and research-analyst for team workflows
- **Version**: Bumped to 3.2.0

### Features

- Research phase: Spawn 3-5 parallel analysts for faster research
- Execution phase: Spawn 2-3 parallel executors for [P] tasks
- Graceful shutdown: 10s timeout with forced cleanup fallback
- Orphaned team detection: Automatic warnings + cleanup command
- Backward compatible: Falls back to Task tool if teams unavailable

### Test Plan

- [x] Unit tests: state schema, team creation, shutdown protocol
- [x] Integration tests: research team, execution team, cancel with team, orphan detection
- [x] Manual tests: backward compatibility, cross-phase isolation, high-stress parallelism
- [x] E2E smoke test: complete workflow with teams enabled

### Requirements Met

- FR-1 through FR-15: All functional requirements implemented
- NFR-1 through NFR-10: All non-functional requirements validated
- 42 acceptance criteria across 6 user stories

### Documentation

- README updated with agent teams section
- DEPLOYMENT.md with GitHub fork + marketplace submission guide
- CHANGELOG.md with v3.2.0 release notes

### Breaking Changes

None. Feature is opt-in via CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.

### Checklist

- [x] All tests pass locally
- [x] Documentation complete
- [x] Backward compatibility verified
- [x] Code follows plugin architecture patterns
- [x] Zero resource leaks validated

**Ready for review.**
EOF
)"`
  - **Files**: None (PR creation via gh CLI)
  - **Done when**: PR created successfully
  - **Verify**: `gh pr view --web` opens PR in browser, or `gh pr view` shows PR details
  - **Commit**: None (PR creation)
  - _Requirements: NFR-8_

- [ ] 5.5 [VERIFY] Monitor CI pipeline
  - **Do**:
    1. Watch CI checks: `gh pr checks --watch`
    2. If checks fail, read failure details: `gh pr checks`
    3. Fix issues locally
    4. Push fixes: `git push`
    5. Re-run checks
  - **Files**: None (CI monitoring)
  - **Done when**: All CI checks pass
  - **Verify**: `gh pr checks` shows all checks as "pass" or "success"
  - **Commit**: `fix(ci): address CI failures` (only if fixes needed)
  - _Requirements: NFR-8_

- [ ] 5.6 [VERIFY] Address code review comments
  - **Do**:
    1. Monitor PR for review comments: `gh pr view --comments`
    2. For each comment:
       - Implement requested changes
       - Test locally
       - Commit: `fix(review): address feedback on <topic>`
       - Push: `git push`
    3. Reply to comments when resolved
  - **Files**: As needed per review feedback
  - **Done when**: All review comments addressed, reviewer approval received
  - **Verify**: `gh pr status` shows "APPROVED" status
  - **Commit**: As needed per review
  - _Requirements: NFR-8_

- [ ] 5.7 [VERIFY] Final validation: zero regressions
  - **Do**:
    1. Run all tests locally one final time
    2. Verify no resource leaks: `ls ~/.claude/teams/` should be empty (except test artifacts)
    3. Verify backward compatibility: test without CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
    4. Verify documentation is complete and accurate
    5. Verify version numbers consistent (3.2.0 in all manifests)
  - **Done when**: All validation checks pass
  - **Verify**: `bash -c 'for test in plugins/ralph-specum/tests/*.sh plugins/ralph-specum/tests/integration/*.sh; do bash "$test" || exit 1; done'` exits 0
  - **Commit**: `chore(final): final cleanup before merge`
  - _Requirements: NFR-1, NFR-2, NFR-7, NFR-9_

- [ ] 5.8 Submit to marketplace
  - **Do**:
    1. Follow DEPLOYMENT.md instructions
    2. Create GitHub fork if not already done
    3. Prepare plugin for marketplace submission
    4. Submit to https://code.claude.com/docs/en/plugin-marketplaces
    5. Include marketplace metadata (name, description, version, tags)
    6. Add "agent-teams", "parallel-execution", "team-management" tags
  - **Files**: None (marketplace submission)
  - **Done when**: Plugin submitted to marketplace successfully
  - **Verify**: Marketplace listing shows ralph-specum v3.2.0 with agent teams features
  - **Commit**: None (submission complete)
  - _Requirements: FR-15, Deployment approach_
  - _Design: Implementation Steps - Phase 6: Testing & Docs_

## Unresolved Questions

None identified during task planning. All design decisions documented in design.md.

## Notes

**POC shortcuts taken (Phase 1):**
- Hardcoded team sizes (3 for research, 2 for execution) - not configurable
- No visual progress indicators for parallel teammates (text-based status only)
- 10-second shutdown timeout hardcoded (not user-configurable)
- Team creation uses simple timestamp-based naming
- Manual testing instead of automated E2E tests

**Production TODOs (future phases):**
- Add team size configuration via plugin settings (FR-14)
- Implement visual progress bars for parallel teammates
- Add configurable shutdown timeout
- Add metrics tracking (team creation latency, resource usage)
- Implement persistent teams across phases (requires Claude Code API changes)
- Add team activity split-pane view (requires terminal UI changes)

**Key integration points:**
- Skills auto-invoke based on context (no explicit calls needed)
- Commands delegate to skills for TeamCreate/TeamDelete lifecycle
- State file extended with team fields (optional, undefined = no active team)
- stop-watcher.sh detects orphaned teams on every session stop
- Fallback to Task tool when teams unavailable (backward compatibility)

**Success criteria validation:**
- Reliability: Zero resource leaks (validated by orphaned team tests)
- Graceful cancellation: 100% cleanup (validated by cancel integration test)
- Backward compatibility: All specs work without teams (validated by manual test)
- Performance: 30% faster research with 3-5 teammates (measured during POC)
- Error clarity: 95% identifiable teammate failures (validated via error messages)
- Code quality: Lifecycle functions < 50 lines each (validated during refactoring)
- Documentation: All commands include team examples (validated in Phase 4)
