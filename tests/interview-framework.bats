#!/usr/bin/env bats
# Interview Framework Content Tests
# Verifies SKILL.md contains required algorithm sections and patterns.

SKILL_FILE="plugins/ralph-specum/skills/interview-framework/SKILL.md"
ALGORITHM_FILE="plugins/ralph-specum/skills/interview-framework/references/algorithm.md"
GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"

@test "SKILL.md exists" {
    [ -f "$SKILL_FILE" ]
}

@test "SKILL.md has critical decision test" {
    grep -q "## Critical Decision Test" "$SKILL_FILE"
}

@test "SKILL.md inspects facts and excludes administration" {
    grep -q "Inspect facts" "$SKILL_FILE"
    grep -q "Exclude setup choices, administrative preferences" "$SKILL_FILE"
}

@test "interview-framework opens and traverses the whole critical frontier" {
    grep -q "## Layered Frontier" "$SKILL_FILE"
    grep -q "open-frontier" "$SKILL_FILE"
    grep -q "four-question maximum" "$ALGORITHM_FILE"
}

@test "SKILL.md has recommended option pattern" {
    grep -q "(Recommended)" "$SKILL_FILE"
}

@test "SKILL.md has no intent-based question counts" {
    ! grep -q "TRIVIAL: 1-2" "$SKILL_FILE"
    ! grep -q "askedCount" "$ALGORITHM_FILE"
}

@test "SKILL.md has no Intent-Based Depth Scaling table" {
    ! grep -q "Intent-Based Depth Scaling" "$SKILL_FILE"
}

@test "SKILL.md limits each question to 2-4 options" {
    grep -q "Give 2-4 viable options" "$SKILL_FILE"
}

@test "SKILL.md requires explicit final approval" {
    grep -q "## Final Approval" "$SKILL_FILE"
    grep -q "Approve and delegate" "$SKILL_FILE"
}

@test "SKILL.md distinguishes control-only and bare skip" {
    grep -q "### Control-only reply" "$SKILL_FILE"
    grep -q "### Bare skip" "$SKILL_FILE"
}

@test "goal-interview.md does not prescribe setup questions" {
    grep -q "Do not ask about spec location" "$GOAL_INTERVIEW"
}

@test "goal-interview.md references the interview skill" {
    grep -q "skills/interview-framework/SKILL.md" "$GOAL_INTERVIEW"
}

@test "plugin.json version is 4.11.0" {
    grep -q '"version": "4.11.0"' "plugins/ralph-specum/.claude-plugin/plugin.json"
}

@test "marketplace.json ralph-specum version is 4.11.0" {
    version=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' ".claude-plugin/marketplace.json")
    [ "$version" = "4.11.0" ]
}
