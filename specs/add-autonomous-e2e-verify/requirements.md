---
generated: auto
---

# Requirements: Autonomous E2E Verification

## Goal

Add a final "Phase E2E" to the task planning and execution system that spins up real infrastructure (browsers, servers, simulators) and tests the built feature as a user would -- with a verify-fix-reverify loop until passing or max attempts exhausted.

## User Stories

### US-1: Quick-Mode Auto E2E Verification

**As a** developer running specs in quick mode
**I want** E2E verification tasks auto-appended after the final quality gate
**So that** every spec gets real-world validation without manual intervention

**Acceptance Criteria:**
- [ ] AC-1.1: When quickMode=true, VE tasks are generated without prompting the user
- [ ] AC-1.2: VE tasks appear after V6 (AC checklist) and before Phase 5 (PR Lifecycle)
- [ ] AC-1.3: At least one VE task spins up infrastructure (dev server, browser, simulator) relevant to the project type
- [ ] AC-1.4: A VE-cleanup task follows all VE tasks to teardown infrastructure (kill processes, close simulators)

### US-2: Normal-Mode Verification Prompt

**As a** developer running specs in normal mode
**I want** to be asked whether to add E2E verification and what approach to use
**So that** I can customize or skip verification when appropriate

**Acceptance Criteria:**
- [ ] AC-2.1: Tasks command prompts user: "Add E2E verification? (Y/n)" with default YES
- [ ] AC-2.2: If YES, suggest verification approach based on project type (web/API/mobile/CLI) and let user customize
- [ ] AC-2.3: If NO, skip VE task generation entirely -- no VE tasks in output
- [ ] AC-2.4: User's choice stored in .progress.md under "Tasks Interview" section

### US-3: Research Phase Tooling Discovery

**As a** research-analyst agent
**I want** to discover verification tooling during the research phase
**So that** VE tasks reference real, available tools instead of guesses

**Acceptance Criteria:**
- [ ] AC-3.1: Research phase includes a "Verification Tooling" section in research.md
- [ ] AC-3.2: Section lists discovered tools: dev server command, test runner, browser automation availability, port used, health endpoint (if API)
- [ ] AC-3.3: Detection is automated: check package.json scripts, Playwright/Puppeteer deps, existing E2E configs, Dockerfile, dev server scripts
- [ ] AC-3.4: If no verification tools found, section states "No automated E2E tooling detected" with manual alternatives

### US-4: VE Task Generation in Task Planner

**As a** task-planner agent
**I want** to generate VE (Verify E2E) tasks based on project type and discovered tooling
**So that** E2E verification is concrete, executable, and project-appropriate

**Acceptance Criteria:**
- [ ] AC-4.1: Task planner reads verification tooling from research.md to determine VE approach
- [ ] AC-4.2: VE tasks use the `[VERIFY]` tag and follow existing Do/Verify/Done when/Commit format
- [ ] AC-4.3: VE tasks are goal-type aware: web app -> browser check, API -> curl health/endpoint, CLI -> run command and check output, mobile -> simulator launch
- [ ] AC-4.4: VE-startup task starts infrastructure (e.g., `npm run dev &`, `docker-compose up -d`)
- [ ] AC-4.5: VE-check task(s) test critical user flows via automated commands
- [ ] AC-4.6: VE-cleanup task kills started processes and frees ports
- [ ] AC-4.7: Total VE tasks: 3-5 (startup + 1-3 checks + cleanup)

### US-5: Verify-Fix-Reverify Loop

**As a** coordinator (implement.md)
**I want** VE verification failures to trigger fix task generation and re-verification
**So that** E2E issues get automatically resolved without human intervention

**Acceptance Criteria:**
- [ ] AC-5.1: When a VE task outputs VERIFICATION_FAIL, coordinator generates a fix task using the existing recovery mode pattern (fixTaskMap, X.Y.N format)
- [ ] AC-5.2: After fix task completes, the same VE task is retried
- [ ] AC-5.3: Max 3 verify-fix-reverify iterations per VE task (reuse maxFixTasksPerOriginal)
- [ ] AC-5.4: If max iterations exceeded, execution stops with error (same as existing recovery mode)
- [ ] AC-5.5: Fix tasks inherit the VE task's Files and Verify fields

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Task planner generates VE phase after V6, before PR Lifecycle | High | VE tasks present in tasks.md between V6 and Phase 5 |
| FR-2 | Research phase discovers verification tooling (dev server, test runner, browser deps) | High | research.md has "Verification Tooling" section with discovered commands |
| FR-3 | VE tasks follow [VERIFY] format and delegate to qa-engineer | High | qa-engineer receives and executes VE tasks |
| FR-4 | VE-startup task starts infrastructure with background process management | High | Dev server or equivalent running, port responsive |
| FR-5 | VE-cleanup task kills all started processes and frees ports | High | No orphaned processes after cleanup runs |
| FR-6 | VE failure triggers fix task via existing recovery mode pattern | High | Fix task inserted in tasks.md, totalTasks incremented |
| FR-7 | Quick mode auto-enables VE tasks, normal mode prompts user | Medium | Quick mode: no prompt; Normal mode: Y/n prompt |
| FR-8 | Tasks command passes verification strategy to task-planner delegation | Medium | Delegation prompt includes verification tooling context |
| FR-9 | VE tasks are project-type aware (web/API/CLI/mobile) | Medium | VE approach matches project type detected in research |
| FR-10 | phase-rules.md updated with E2E verification phase documentation | Medium | New phase documented between current V6 and PR Lifecycle |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | VE phase adds minimal task overhead | Task count increase | 3-5 VE tasks max per spec |
| NFR-2 | VE infrastructure startup timeout | Time to respond | 60 seconds max before marking FAIL |
| NFR-3 | Backward compatibility | Existing specs unaffected | Specs without VE tasks execute identically to today |
| NFR-4 | Cleanup reliability | Orphaned processes | Zero orphaned processes after VE-cleanup |
| NFR-5 | Recovery mode reuse | Code duplication | VE fix loop uses existing fixTaskMap/recovery patterns, no new loop mechanism |

## Glossary

- **VE task**: Verify E2E -- a [VERIFY] task that tests the built feature by spinning up real infrastructure
- **VE-startup**: VE sub-task that launches dev server, browser, simulator, or other infrastructure
- **VE-check**: VE sub-task that runs E2E assertions against running infrastructure
- **VE-cleanup**: VE sub-task that tears down all started infrastructure
- **Verify-fix-reverify**: Loop pattern where VE failure triggers fix task generation, then VE retries
- **Project type**: Classification of what was built: web app, API, CLI tool, mobile app, library

## Assumptions

1. The existing recovery mode (fixTaskMap, fix task generation, retry logic) is sufficient for VE failures -- no new loop mechanism needed
2. VE tasks use the [VERIFY] tag and delegate to qa-engineer, same as existing quality checkpoints
3. VE phase sits between V6 and Phase 5 (PR Lifecycle), not as a separate numbered phase -- it extends the existing final verification sequence
4. Research phase already runs before task planning, so tooling discovery results are available when tasks are generated
5. Infrastructure processes started by VE-startup can be managed via standard shell tools (lsof, kill, background processes)

## Out of Scope

- Visual regression testing (screenshot comparison)
- Performance benchmarking during E2E verification
- Multi-environment verification (staging, production)
- Custom user-defined verification scripts (beyond what research discovers)
- Parallel VE task execution (VE tasks run sequentially by nature)
- MCP server installation for verification (use only what's already available)
- Modifying the qa-engineer agent (VE tasks are standard [VERIFY] tasks)
- New agent creation (no "e2e-verifier" agent -- qa-engineer handles it)

## Dependencies

- Research phase must complete before tasks phase (already enforced by workflow)
- Recovery mode must be enabled for verify-fix-reverify to work (recoveryMode: true in state)
- Project must have discoverable verification tooling OR VE tasks fall back to basic checks (build succeeds, no runtime errors)

## Unresolved Questions

1. **VE task numbering**: Should VE tasks be VE1/VE2/VE3 (like V4/V5/V6) or use phase numbering (e.g., 4.5, 4.6)? Decision: Use VE prefix for consistency with V-series naming.
2. **Recovery mode dependency**: Should VE verify-fix-reverify require recoveryMode=true, or should it always be enabled for VE tasks? Decision: Always enabled for VE tasks -- VE failures are expected and recoverable.

## Success Criteria

- Every quick-mode spec generates VE tasks that exercise the built feature end-to-end
- VE tasks use real project tooling discovered during research (not hardcoded assumptions)
- At least one VE-check task per spec tests a critical user flow
- Verify-fix-reverify loop resolves at least basic VE failures without human intervention
- No orphaned infrastructure processes after spec completion
- Existing specs without VE tasks execute identically to current behavior

## Next Steps

1. Design the VE task template format and insertion point in phase-rules.md
2. Design research-analyst verification tooling discovery logic
3. Design tasks command user prompt flow for normal mode
4. Design coordinator integration for VE verify-fix-reverify loop
