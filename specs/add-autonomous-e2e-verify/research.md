# Research: add-autonomous-e2e-verify

## Executive Summary

Smart Ralph already has a robust quality checkpoint system ([VERIFY] tasks, V4-V6 final sequence, VF tasks for fixes) and the execution loop supports dynamic task insertion. The key gap is **autonomous end-to-end verification** — actually spinning up the built artifact and testing it as a real user would. The existing architecture (dynamic totalTasks, TASK_MODIFICATION_REQUEST, recovery mode fix tasks) provides all the primitives needed to implement a verify-fix-reverify loop. The main changes are: (1) modify the task-planner to add E2E verification tasks, (2) add user prompt for verification strategy in normal mode, (3) research and suggest verification tooling during the research phase, and (4) implement the verify-fix-reverify loop pattern in the coordinator.

## External Research

### Industry Patterns for Autonomous E2E Verification

**CI/CD Smoke Testing**: After deployment, CI pipelines commonly run smoke tests — lightweight E2E checks that verify the deployed service responds correctly. This includes hitting health endpoints, loading key pages, and running critical user flows.

**Canary Deployments**: Systems like Kubernetes canary deployments automatically verify new versions by routing a percentage of traffic and monitoring error rates. If errors spike, the deployment is rolled back automatically — a verify-fix-reverify pattern at infrastructure level.

**AI Agent Verification**: AI coding tools like Devin use a verify-then-fix loop:
1. Generate code changes
2. Run tests/build
3. If failure, analyze output, generate fix
4. Repeat until passing or max attempts reached

This is conceptually identical to our recovery mode but applied at the E2E level.

### Verify-Fix-Reverify Loop Pattern

The pattern has three components:
1. **Verify**: Run automated checks against the built artifact
2. **Diagnose**: If check fails, analyze the failure and identify root cause
3. **Fix**: Generate fix tasks and execute them
4. **Re-verify**: Re-run the same checks to confirm the fix

**Termination conditions**:
- All checks pass → done
- Max iterations reached → escalate to user
- Same failure repeats N times → different approach needed

### Prior Art in This Codebase

Ralph Specum already implements this pattern for individual tasks via:
- **Recovery mode** (failure-recovery.md): Auto-generates fix tasks when a task fails
- **VF tasks**: Verify-fix pattern for bug-fix goals
- **V6 AC checklist**: Verifies acceptance criteria are met

The gap: these verify at the code/test level, not at the "spin it up and use it" level.

### Pitfalls to Avoid
- **Flaky E2E tests**: Environment-dependent tests that pass sometimes and fail sometimes
- **Over-scoped verification**: Trying to test everything instead of critical paths
- **Missing cleanup**: Not shutting down dev servers, simulators, etc. after verification
- **Timeout spirals**: Verification takes too long, causing the loop to hit global iteration limits

## Codebase Analysis

### Task Planner Architecture

The task-planner generates tasks across 5 phases (POC → Refactor → Test → Quality Gates → PR Lifecycle). Key findings:

- **Phase distribution**: Phase 1 (POC) gets 50-60% of tasks, Phase 3 (Testing) gets 15-20%
- **Quality checkpoints**: [VERIFY] tasks every 2-3 tasks, delegated to qa-engineer
- **Final verification sequence**: V4 (local CI), V5 (remote CI), V6 (AC checklist)
- **Mandatory autonomy**: All verify fields must be automated commands (exit code 0 = pass)
- **Quick mode**: Skips interview and review but preserves all quality checkpoints

**Injection point for E2E verification**: After V6 (AC checklist), before ALL_TASKS_COMPLETE. New verification tasks (VE series) would be added as the final phase of verification.

### Execution Loop Capabilities

The execution loop fully supports dynamic task addition:

- **Dynamic totalTasks**: Can be incremented when new tasks are inserted
- **TASK_MODIFICATION_REQUEST**: Spec-executor can request ADD_FOLLOWUP tasks
- **Recovery mode**: Auto-generates fix tasks with nested support (up to 3 levels deep)
- **Fix task format**: `X.Y.N [FIX X.Y] Fix: <error summary>`

**Key integration point**: The coordinator's state update pattern already handles expanding totalTasks. A verify-fix-reverify loop would:
1. After V6 completes, insert VE (Verify E2E) tasks
2. VE tasks spin up infrastructure and run E2E checks
3. On VERIFICATION_FAIL, insert fix tasks + new VE task
4. Loop until VERIFICATION_PASS or max attempts

### Existing Quality Patterns

**Three verification types** in qa-engineer:
1. Command Verification (shell commands)
2. AC Checklist (requirements traceability)
3. VF (Verify Fix) for bug-fix goals

**Mock quality checks**: Auto-detects mock-only test anti-patterns

**Gaps identified**:
- No explicit E2E scenario verification beyond test commands
- No infrastructure spin-up/teardown for verification
- No user-facing verification (browser, simulator, etc.)
- VF tasks only apply to fix-type goals, not greenfield

## Verification Tooling (Runtime)

### Web Applications
- **Playwright**: Full browser automation, headless mode, CLI (`npx playwright test`). MCP servers exist (playwright-mcp) for Claude Code integration
- **Puppeteer**: Chrome/Chromium automation via Node.js
- **curl/httpie**: HTTP endpoint verification
- **Dev server management**: `lsof -i :PORT` to check ports, `npm run dev &` to start servers

### Mobile Applications
- **iOS Simulator**: `xcrun simctl boot "iPhone 15"`, `xcrun simctl install`, `xcrun simctl launch`
- **Android Emulator**: `emulator @device_name`, `adb install`, `adb shell am start`
- **Detox**: E2E testing for React Native (CLI-driven)

### APIs
- **curl**: `curl -sf http://localhost:3000/api/health`
- **httpie**: `http GET localhost:3000/api/endpoint`
- **newman**: CLI runner for Postman collections

### Email
- **MailHog**: Local SMTP trap with API (`curl localhost:8025/api/v2/messages`)
- **Mailtrap**: Cloud email testing with API

### General CLI Verification
- **Port checking**: `lsof -i :PORT`, `nc -z localhost PORT`
- **Process management**: `pgrep`, `kill`, background process management
- **Screenshot capture**: `screencapture` (macOS), Playwright screenshots
- **File existence**: `test -f`, `stat`, `find`

### MCP Servers for Verification
- **Playwright MCP**: Browser automation available as MCP server
- **Puppeteer MCP**: Alternative browser MCP server
- **Fetch MCP**: HTTP request making

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Task planner modification | **High feasibility** | Extend existing phase-rules.md and quality-checkpoints.md |
| Dynamic task insertion | **Already supported** | totalTasks dynamic, TASK_MODIFICATION_REQUEST exists |
| Verify-fix-reverify loop | **High feasibility** | Recovery mode pattern directly applicable |
| User prompt for verification | **Straightforward** | Follow existing quick-mode default patterns |
| Verification tooling research | **Medium complexity** | Research phase can discover project-specific tools |
| Infrastructure spin-up/teardown | **Medium complexity** | Need cleanup tasks to prevent orphaned processes |

**Overall Risk**: Low — builds on existing patterns (recovery mode, [VERIFY] tasks, dynamic totalTasks)
**Effort**: Medium (M) — touches task-planner, phase-rules, quality-checkpoints, coordinator-pattern, research phase

## Recommendations for Requirements

1. **Add "Phase E2E" after Phase 4**: New verification phase with VE (Verify E2E) tasks that spin up the built artifact and test it end-to-end
2. **Modify task-planner** to generate VE tasks based on goal type (web → browser, mobile → simulator, API → curl, email → mailhog check)
3. **Add verification strategy prompt**: In normal mode, ask user how they want to verify; in quick mode, auto-decide based on goal classification
4. **Extend research phase**: During research, actively discover verification tooling (existing test scripts, dev server commands, available MCP servers)
5. **Implement verify-fix-reverify loop**: When VE task fails, auto-generate fix tasks + new VE task, loop until pass or max attempts
6. **Add cleanup tasks**: After verification phase, add cleanup tasks (stop dev servers, close simulators, etc.)

## Open Questions

1. Should VE tasks run before or after the PR Lifecycle phase?
2. Should the verify-fix-reverify loop use existing recovery mode or a separate mechanism?
3. Maximum VE iterations before escalating to user?
4. Should verification research be a separate research topic or integrated into the existing research flow?

## Sources

- `plugins/ralph-specum/agents/task-planner.md` - Task planner agent definition
- `plugins/ralph-specum/references/phase-rules.md` - Phase workflow rules
- `plugins/ralph-specum/references/quality-checkpoints.md` - Quality checkpoint rules
- `plugins/ralph-specum/references/coordinator-pattern.md` - Coordinator pattern
- `plugins/ralph-specum/references/failure-recovery.md` - Failure recovery mode
- `plugins/ralph-specum/references/verification-layers.md` - 3-layer verification
- `plugins/ralph-specum/agents/qa-engineer.md` - QA engineer agent
- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` - Stop hook
