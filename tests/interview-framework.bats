#!/usr/bin/env bats
# Smart Ralph Plugin Content Tests
# Verifies agent files, commands, references, and templates contain required sections and protocols.

SKILL_FILE="plugins/ralph-specum/skills/interview-framework/SKILL.md"
ALGORITHM_FILE="plugins/ralph-specum/skills/interview-framework/references/algorithm.md"
GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"

EXTERNAL_REVIEWER="plugins/ralph-specum/agents/external-reviewer.md"
QA_ENGINEER="plugins/ralph-specum/agents/qa-engineer.md"
SPEC_EXECUTOR="plugins/ralph-specum/agents/spec-executor.md"
TASK_PLANNER="plugins/ralph-specum/agents/task-planner.md"
IMPLEMENT_CMD="plugins/ralph-specum/commands/implement.md"
COORDINATOR="plugins/ralph-specum/references/coordinator-pattern.md"
FAILURE_RECOVERY="plugins/ralph-specum/references/failure-recovery.md"
CHAT_TEMPLATE="plugins/ralph-specum/templates/chat.md"

# ============================================================================
# Interview Framework (legacy tests)
# ============================================================================

@test "SKILL.md exists" {
    [ -f "$SKILL_FILE" ]
}

@test "SKILL.md has Codebase-First Exploration section" {
    grep -q "## Codebase-First Exploration" "$SKILL_FILE"
}

@test "SKILL.md codebase-first section distinguishes facts from decisions" {
    grep -q "Codebase fact" "$SKILL_FILE"
    grep -q "User decision" "$SKILL_FILE"
}

@test "interview-framework has decision-tree traversal (not WHILE loop)" {
    grep -q "Decision-Tree" "$SKILL_FILE"
    grep -q "DECISION-TREE TRAVERSAL" "$ALGORITHM_FILE"
    ! grep -q "WHILE askedCount" "$SKILL_FILE"
    ! grep -q "WHILE askedCount" "$ALGORITHM_FILE"
}

@test "SKILL.md has [Recommended] label pattern" {
    grep -q "\[Recommended\]" "$SKILL_FILE"
}

@test "SKILL.md completion signal check has no minRequired guard" {
    ! grep -q "askedCount >= minRequired" "$SKILL_FILE"
}

@test "SKILL.md has no Intent-Based Depth Scaling table" {
    ! grep -q "Intent-Based Depth Scaling" "$SKILL_FILE"
}

@test "SKILL.md preserves Option Limit Rule" {
    grep -q "Option Limit Rule" "$SKILL_FILE"
}

@test "SKILL.md preserves Phase 2 PROPOSE APPROACHES" {
    grep -q "PROPOSE APPROACHES" "$SKILL_FILE"
}

@test "SKILL.md preserves Phase 3 CONFIRM & STORE" {
    grep -q "CONFIRM & STORE" "$SKILL_FILE"
}

@test "goal-interview.md does not contain duplicate codebase-first mandatory block" {
    ! grep -q "is this a codebase fact or a user decision" "$GOAL_INTERVIEW"
}

@test "goal-interview.md still references SKILL.md for adaptive dialogue" {
    grep -q "skills/interview-framework/SKILL.md" "$GOAL_INTERVIEW"
}

# ============================================================================
# Version consistency
# ============================================================================

@test "plugin.json version matches marketplace.json" {
    plugin_version=$(jq -r '.version' "plugins/ralph-specum/.claude-plugin/plugin.json")
    market_version=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' ".claude-plugin/marketplace.json")
    [ "$plugin_version" = "$market_version" ]
}

@test "plugin.json version is not 0.0.0 or empty" {
    version=$(jq -r '.version' "plugins/ralph-specum/.claude-plugin/plugin.json")
    [ "$version" != "0.0.0" ]
    [ -n "$version" ]
}

# ============================================================================
# External Reviewer (external-reviewer.md)
# ============================================================================

@test "external-reviewer.md has Section 1d — Supervisor Role" {
    grep -q "## Section 1d — Supervisor Role" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has NO duplicate Section 1c" {
    # There should be exactly one Section 1c (Human as Participant)
    count=$(grep -c "## Section 1c " "$EXTERNAL_REVIEWER" || true)
    [ "$count" -eq 1 ]
}

@test "external-reviewer.md has Section 2 — Review Principles (Code)" {
    grep -q "## Section 2 — Review Principles" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has Spec Adaptation concepts" {
    # Spec Adaptation Protocol (L1/L2/L3) is a designed feature — test verifies scaffolding exists
    grep -q "spec deficiency" "$EXTERNAL_REVIEWER" || grep -q "SPEC-ADJUSTMENT" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has Red Flag Patterns escalation table" {
    grep -q "Red Flag Patterns" "$EXTERNAL_REVIEWER"
    grep -q "DEADLOCK to chat.md" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has mid-flight vs post-task detection" {
    grep -q "mid-flight" "$EXTERNAL_REVIEWER"
    grep -q "post-task" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has Convergence Detection (3 rounds)" {
    grep -q "convergence_rounds" "$EXTERNAL_REVIEWER"
    grep -q "3 rounds" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has E2E anti-pattern hard FAIL triggers" {
    grep -q "navigation-goto-internal" "$EXTERNAL_REVIEWER"
    grep -q "timing-fixed-wait" "$EXTERNAL_REVIEWER"
    grep -q "selector-invented" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has Aggressive Fallback with flock" {
    grep -q "Aggressive Fallback" "$EXTERNAL_REVIEWER"
    grep -q "flock -e 201" "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md has safe Python heredoc (not inline interpolation)" {
    # Should use env vars + heredoc, NOT python3 -c with ${} interpolation
    grep -q "python3 - <<'PY'" "$EXTERNAL_REVIEWER"
    ! grep -q 'python3 -c ".*\${WHAT_IS_WRONG}' "$EXTERNAL_REVIEWER"
}

@test "external-reviewer.md references implement.md Key Coordinator Behaviors" {
    grep -q "implement.md" "$EXTERNAL_REVIEWER"
    grep -q "Key Coordinator Behaviors" "$EXTERNAL_REVIEWER"
}

# ============================================================================
# QA Engineer (qa-engineer.md)
# ============================================================================

@test "qa-engineer.md has Section 0 — Review Integration" {
    grep -q "## Section 0 — Review Integration" "$QA_ENGINEER"
}

@test "qa-engineer.md reads task_review.md before verification" {
    grep -q "task_review.md" "$QA_ENGINEER"
    grep -q "Check task_review.md" "$QA_ENGINEER"
}

@test "qa-engineer.md reads chat.md for HOLD/DEADLOCK signals" {
    grep -q "chat.md" "$QA_ENGINEER"
    grep -q "HOLD" "$QA_ENGINEER"
    grep -q "DEADLOCK" "$QA_ENGINEER"
}

@test "qa-engineer.md has mid-flight vs post-task submode detection" {
    grep -q "mid-flight" "$QA_ENGINEER"
    grep -q "post-task" "$QA_ENGINEER"
}

@test "qa-engineer.md has Pre-existing Error Detection with git merge-base" {
    grep -q "Pre-existing Error Detection" "$QA_ENGINEER"
    grep -q "merge-base" "$QA_ENGINEER"
}

@test "qa-engineer.md does NOT emit VERIFICATION_PASS for pre-existing errors" {
    # Pre-existing errors should emit VERIFICATION_FAIL with spec-adjustment-pending
    # NOT VERIFICATION_PASS (which would mark task complete with non-zero exit)
    grep -q "spec-adjustment-pending" "$QA_ENGINEER"
}

@test "qa-engineer.md Execution Flow includes Section 0 step" {
    # Execution flow should reference Section 0 as step 0
    grep -q "Run Section 0" "$QA_ENGINEER"
}

@test "qa-engineer.md has Story Verification with escalation" {
    grep -q "Story Verification" "$QA_ENGINEER"
    grep -q "ESCALATION REQUIRED" "$QA_ENGINEER"
    grep -q "escalate_if" "$QA_ENGINEER"
}

@test "qa-engineer.md has VF (Verify Fix) task execution" {
    grep -q "VF Task" "$QA_ENGINEER"
    grep -q "BEFORE state" "$QA_ENGINEER"
    grep -q "AFTER state" "$QA_ENGINEER"
}

@test "qa-engineer.md has Mock Quality Check process" {
    grep -q "Mock Quality" "$QA_ENGINEER"
    grep -q "Mock declarations" "$QA_ENGINEER"
}

# ============================================================================
# Spec Executor (spec-executor.md)
# ============================================================================

@test "spec-executor.md has verify_tasks section" {
    grep -q "<verify_tasks>" "$SPEC_EXECUTOR"
    grep -q "</verify_tasks>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has root cause attribution in verify_tasks" {
    # Root cause attribution is embedded in the verify_tasks section, not a separate tag
    grep -q "Attribute the failure" "$SPEC_EXECUTOR"
    grep -q "git diff" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has exit_code_gate section" {
    grep -q "<exit_code_gate>" "$SPEC_EXECUTOR"
    grep -q "</exit_code_gate>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md exit_code_gate does git diff attribution" {
    # Should check git diff before classifying failure
    grep -A 10 "<exit_code_gate>" "$SPEC_EXECUTOR" | grep -q "git diff"
}

@test "spec-executor.md has chat protocol section" {
    grep -q "<chat>" "$SPEC_EXECUTOR"
    grep -q "</chat>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has external_review protocol section" {
    grep -q "<external_review>" "$SPEC_EXECUTOR"
    grep -q "</external_review>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has stuck detection with effectiveIterations" {
    grep -q "<stuck>" "$SPEC_EXECUTOR"
    grep -q "effectiveIterations" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has modification request with SPEC_ADJUSTMENT type" {
    grep -q "SPEC_ADJUSTMENT" "$SPEC_EXECUTOR"
    grep -q "SPLIT_TASK" "$SPEC_EXECUTOR"
    grep -q "ADD_PREREQUISITE" "$SPEC_EXECUTOR"
    grep -q "ADD_FOLLOWUP" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has ve_tasks with skill loading order" {
    grep -q "<ve_tasks>" "$SPEC_EXECUTOR"
    grep -q "playwright-env" "$SPEC_EXECUTOR"
    grep -q "mcp-playwright" "$SPEC_EXECUTOR"
    grep -q "playwright-session" "$SPEC_EXECUTOR"
    grep -q "ui-map-init" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has parallel execution section" {
    grep -q "<parallel>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has pr_lifecycle section" {
    grep -q "<pr_lifecycle>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has type_check section" {
    grep -q "<type_check>" "$SPEC_EXECUTOR"
}

@test "spec-executor.md has explore section" {
    grep -q "<explore>" "$SPEC_EXECUTOR"
}

# ============================================================================
# Task Planner (task-planner.md)
# ============================================================================

@test "task-planner.md has VE Tasks Skills: metadata requirement" {
    grep -q "Skills:" "$TASK_PLANNER"
    grep -q "VE Tasks must include" "$TASK_PLANNER"
}

@test "task-planner.md enforces checkbox format (not headings)" {
    grep -q "CHECKBOX MANDATORY" "$TASK_PLANNER"
    grep -q "grep -c" "$TASK_PLANNER"
}

@test "task-planner.md has POC-first workflow phases" {
    grep -q "Phase 1: Make It Work" "$TASK_PLANNER"
    grep -q "Phase 2: Refactoring" "$TASK_PLANNER"
}

@test "task-planner.md has TDD workflow with RED/GREEN/YELLOW" {
    grep -q "\[RED\]" "$TASK_PLANNER"
    grep -q "\[GREEN\]" "$TASK_PLANNER"
    grep -q "\[YELLOW\]" "$TASK_PLANNER"
}

@test "task-planner.md has Bug TDD with Phase 0" {
    grep -q "Phase 0" "$TASK_PLANNER"
    grep -q "Reproduce bug" "$TASK_PLANNER"
}

@test "task-planner.md has VF task generation for fix goals" {
    grep -q "VF Task" "$TASK_PLANNER"
    grep -q "Reality Check" "$TASK_PLANNER"
}

@test "task-planner.md has quality gate checkpoints every 2-3 tasks" {
    grep -q "2-3 tasks" "$TASK_PLANNER"
    grep -q "Quality Checkpoint" "$TASK_PLANNER"
}

@test "task-planner.md forbids manual verification patterns" {
    # task-planner should list these as FORBIDDEN patterns
    grep -q "No Manual Tasks" "$TASK_PLANNER"
    grep -q "FORBIDDEN" "$TASK_PLANNER"
    grep -q "Manually verify" "$TASK_PLANNER"  # Listed as forbidden, not as instruction
}

@test "task-planner.md has Test Coverage Table driven Phase 3" {
    grep -q "Test Coverage Table" "$TASK_PLANNER"
}

# ============================================================================
# Implement Command (implement.md)
# ============================================================================

@test "implement.md has coordinator reading task_review.md BEFORE delegating" {
    grep -q "Read task_review.md BEFORE delegating" "$IMPLEMENT_CMD"
}

@test "implement.md has coordinator reading chat.md BEFORE delegating" {
    grep -q "Read chat.md BEFORE delegating" "$IMPLEMENT_CMD"
}

@test "implement.md PENDING in task_review.md is blocking (not skip)" {
    # Should say "blocking" not "skip"
    grep -q "blocking" "$IMPLEMENT_CMD"
    ! grep -q "skip to next.*PENDING" "$IMPLEMENT_CMD"
}

@test "implement.md has independent verification (never trust executor)" {
    grep -q "Verify independently" "$IMPLEMENT_CMD"
    grep -q "FABRICATION" "$IMPLEMENT_CMD"
}

@test "implement.md has VE task Skills: validation" {
    grep -q "Validate VE task Skills:" "$IMPLEMENT_CMD"
    grep -q "Skills:.*missing" "$IMPLEMENT_CMD"
}

@test "implement.md has recovery-mode flag" {
    grep -q "\-\-recovery-mode" "$IMPLEMENT_CMD"
}

# ============================================================================
# Coordinator Pattern (coordinator-pattern.md)
# ============================================================================

@test "coordinator-pattern.md handles SPEC_ADJUSTMENT signal" {
    grep -q "SPEC-ADJUSTMENT" "$COORDINATOR"
}

@test "coordinator-pattern.md handles SPEC_DEFICIENCY signal" {
    grep -q "SPEC-DEFICIENCY" "$COORDINATOR"
}

@test "coordinator-pattern.md has SPEC_ADJUSTMENT auto-approve validation" {
    grep -q "proposedChange.field" "$COORDINATOR"
    grep -q "affectedTasks" "$COORDINATOR"
}

@test "coordinator-pattern.md handles qa-engineer TASK_MODIFICATION_REQUEST" {
    # Coordinator should check qa-engineer output for TASK_MODIFICATION_REQUEST
    grep -q "qa-engineer" "$COORDINATOR"
    grep -q "TASK_MODIFICATION_REQUEST" "$COORDINATOR"
}

@test "coordinator-pattern.md has parallel batch handling" {
    grep -q "Parallel Batch" "$COORDINATOR"
    grep -q "\[P\]" "$COORDINATOR"
}

# ============================================================================
# Failure Recovery (failure-recovery.md)
# ============================================================================

@test "failure-recovery.md has Fix Type Classification table" {
    grep -q "impl_bug" "$FAILURE_RECOVERY"
    grep -q "test_quality" "$FAILURE_RECOVERY"
    grep -q "env_issue" "$FAILURE_RECOVERY"
    grep -q "spec_ambiguity" "$FAILURE_RECOVERY"
    grep -q "flaky" "$FAILURE_RECOVERY"
}

# ============================================================================
# Chat Template (chat.md)
# ============================================================================

@test "chat.md template has complete Signal Legend" {
    grep -q "OVER" "$CHAT_TEMPLATE"
    grep -q "ACK" "$CHAT_TEMPLATE"
    grep -q "CONTINUE" "$CHAT_TEMPLATE"
    grep -q "HOLD" "$CHAT_TEMPLATE"
    grep -q "PENDING" "$CHAT_TEMPLATE"
    grep -q "DEADLOCK" "$CHAT_TEMPLATE"
    grep -q "INTENT-FAIL" "$CHAT_TEMPLATE"
    grep -q "SPEC-ADJUSTMENT" "$CHAT_TEMPLATE"
    grep -q "SPEC-DEFICIENCY" "$CHAT_TEMPLATE"
}

@test "chat.md template uses separated header format (not pipe-delimited)" {
    # New format: separate header line with **Signal** in body
    grep -q "### \[.*\] .\+ → .\+" "$CHAT_TEMPLATE"
    grep -q "\*\*Signal\*\*:" "$CHAT_TEMPLATE"
}

@test "chat.md template does NOT use old pipe-delimited format" {
    # Old format was: [agent → agent] HH:MM:SS | task-ID | SIGNAL
    # Should NOT appear as example or template
    ! grep -q "| task-[0-9]" "$CHAT_TEMPLATE"
}

@test "chat.md template has append-only rule" {
    grep -q "Append only" "$CHAT_TEMPLATE"
}

# ============================================================================
# Cross-file consistency
# ============================================================================

@test "All agents use basePath parameter (not hardcoded ./specs/)" {
    grep -q "basePath" "$EXTERNAL_REVIEWER"
    grep -q "basePath" "$QA_ENGINEER"
    grep -q "basePath" "$SPEC_EXECUTOR"
    grep -q "basePath" "$TASK_PLANNER"
}

@test "Signal format uses separated **Task**/**Signal** lines (not pipe)" {
    # All agents should use the new format
    ! grep -q "\*\*Task\*\:.*| \*\*Signal\*\:" "$EXTERNAL_REVIEWER"
    ! grep -q "\*\*Task\*\:.*| \*\*Signal\*\:" "$SPEC_EXECUTOR"
}

@test "qa-engineer does NOT emit TASK_COMPLETE (only VERIFICATION_* signals)" {
    # qa-engineer outputs VERIFICATION_PASS/FAIL/DEGRADED, not TASK_COMPLETE
    ! grep -q "TASK_COMPLETE" "$QA_ENGINEER"
}

@test "external-reviewer cannot modify implementation files" {
    grep -q "Never modify implementation files" "$EXTERNAL_REVIEWER"
}

@test "spec-executor cannot modify .ralph-state.json (except chat.lastReadLine)" {
    grep -q "Never modify .ralph-state.json" "$SPEC_EXECUTOR"
    grep -q "chat.lastReadLine" "$SPEC_EXECUTOR"
}
