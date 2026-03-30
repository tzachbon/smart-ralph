#!/usr/bin/env bats
# Interview Framework Content Tests
# Verifies SKILL.md contains required algorithm sections and patterns.

SKILL_FILE="plugins/ralph-specum/skills/interview-framework/SKILL.md"
ALGORITHM_FILE="plugins/ralph-specum/skills/interview-framework/references/algorithm.md"
GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"

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
    # SKILL.md references decision-tree in heading
    grep -q "Decision-Tree" "$SKILL_FILE"
    # Full pseudocode in algorithm.md
    grep -q "DECISION-TREE TRAVERSAL" "$ALGORITHM_FILE"
    # WHILE loop should be gone from both
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

@test "plugin.json version is 4.9.1" {
    grep -q '"version": "4.9.1"' "plugins/ralph-specum/.claude-plugin/plugin.json"
}

@test "marketplace.json ralph-specum version is 4.9.1" {
    version=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' ".claude-plugin/marketplace.json")
    [ "$version" = "4.9.1" ]
}
