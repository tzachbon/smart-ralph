#!/usr/bin/env bats
set -e
# Interview Framework Content Tests
# Verifies that normal interviews use the fact-first grilling contract.

SKILL_FILE="plugins/ralph-specum/skills/interview-framework/SKILL.md"
ALGORITHM_FILE="plugins/ralph-specum/skills/interview-framework/references/algorithm.md"
EXAMPLES_FILE="plugins/ralph-specum/skills/interview-framework/references/examples.md"
DOMAIN_FILE="plugins/ralph-specum/skills/interview-framework/references/domain-modeling.md"
GOAL_GRILL="plugins/ralph-specum/references/goal-interview.md"
INTENT_FILE="plugins/ralph-specum/references/intent-classification.md"
START_COMMAND="plugins/ralph-specum/commands/start.md"
SPEC_SCANNER="plugins/ralph-specum/references/spec-scanner.md"
TASK_PLANNER="plugins/ralph-specum/agents/task-planner.md"
PHASE_COMMANDS=(
    "plugins/ralph-specum/commands/research.md"
    "plugins/ralph-specum/commands/requirements.md"
    "plugins/ralph-specum/commands/design.md"
    "plugins/ralph-specum/commands/tasks.md"
)

@test "grilling framework and references exist" {
    [ -f "$SKILL_FILE" ]
    [ -f "$ALGORITHM_FILE" ]
    [ -f "$EXAMPLES_FILE" ]
    [ -f "$DOMAIN_FILE" ]
}

@test "normal interview is the grill without an opt-in mode" {
    grep -q "Treat every normal-mode interview governed by this framework as a grill" "$SKILL_FILE"
    grep -q "Quick mode bypasses interview questions only" "$SKILL_FILE"
    ! grep -Eq '(interviewMode|grillMode)' "$SKILL_FILE" "$ALGORITHM_FILE" "$GOAL_GRILL" "${PHASE_COMMANDS[@]}"
}

@test "hard gate distinguishes critical decisions from administration" {
    grep -q "## Critical Decision Test" "$SKILL_FILE"
    grep -q "Exclude setup choices, administrative preferences" "$SKILL_FILE"
    grep -q "open-frontier" "$SKILL_FILE"
    grep -q "four-question maximum" "$ALGORITHM_FILE"
}

@test "control-only replies bare skip and approval retain distinct semantics" {
    grep -q "### Control-only reply" "$SKILL_FILE"
    grep -q "### Bare skip" "$SKILL_FILE"
    grep -q "## Final Approval" "$SKILL_FILE"
    grep -q "Approve and delegate" "$SKILL_FILE"
    grep -q "apply the changes" "$EXAMPLES_FILE"
}

@test "preflight reads the specification index and domain context" {
    grep -q '\.index/index\.md' "$SKILL_FILE"
    grep -q 'CONTEXT-MAP\.md' "$SKILL_FILE"
    grep -q 'CONTEXT\.md' "$SKILL_FILE"
    grep -q 'relevant indexed entries' "$SKILL_FILE"
    grep -q 'Goal Grill' "$START_COMMAND"
    grep -q "evidence for the grill's design tree" "$SPEC_SCANNER"
    grep -q 'defaultDir = ralph_get_default_dir()' "$SPEC_SCANNER"
    grep -q 'indexDir = "$defaultDir/.index"' "$SPEC_SCANNER"
}

@test "start resolves location and persists scanner results before the grill" {
    grep -q "If no goal is available yet" "$START_COMMAND"
    grep -q "Do not run keyword matching against an empty goal" "$START_COMMAND"
    grep -q 'If `scannerDeferred` is true' "$START_COMMAND"
    grep -q "Resolve the spec directory before creating files" "$START_COMMAND"
    grep -q "Carries the results into New Flow" "$START_COMMAND"
    grep -q 'do not create it here' "$SPEC_SCANNER"
    grep -q 'writes RELATED_SPECS into the initial state' "$SPEC_SCANNER"
    grep -q "do not ask for it again during the goal grill" "$GOAL_GRILL"
}

@test "framework separates discoverable facts from user decisions" {
    grep -q '\*\*Fact\*\*' "$SKILL_FILE"
    grep -q '\*\*Decision\*\*' "$SKILL_FILE"
    grep -q "Ask no repository fact as a user question" "$ALGORITHM_FILE"
}

@test "framework asks the whole design-tree frontier in numbered rounds" {
    grep -q "Build the Design Tree" "$SKILL_FILE"
    grep -q "Ask the whole current frontier in one round" "$SKILL_FILE"
    grep -q 'Number each question (`Q1`, `Q2`' "$SKILL_FILE"
    grep -q "Ask every currently unblocked user decision in the same round" "$ALGORITHM_FILE"
}

@test "frontier rounds prefer AskUserQuestion and retain a text fallback" {
    grep -q 'Use `AskUserQuestion` for the round when the tool is available' "$SKILL_FILE"
    grep -q 'If `AskUserQuestion` is unavailable' "$SKILL_FILE"
    grep -q 'If `AskUserQuestion` is available' "$ALGORITHM_FILE"
    grep -q 'render the same numbered round in the response' "$ALGORITHM_FILE"
}

@test "each decision includes a grounded recommendation and bounded options" {
    grep -q "Give a recommended answer with a short rationale" "$SKILL_FILE"
    grep -q 'Provide 2-4 meaningful options' "$SKILL_FILE"
    grep -q '\[Recommended\]' "$EXAMPLES_FILE"
}

@test "completion requires an empty frontier and shared-understanding confirmation" {
    grep -q "design-tree frontier is empty" "$SKILL_FILE"
    grep -q "user confirms the resulting shared understanding" "$SKILL_FILE"
    grep -q "Advance no phase with an open frontier" "$ALGORITHM_FILE"
}

@test "domain modeling challenges language and updates context inline" {
    grep -q "Challenge a term that conflicts with the glossary" "$DOMAIN_FILE"
    grep -q "vague or overloaded words" "$DOMAIN_FILE"
    grep -q "concrete scenario" "$DOMAIN_FILE"
    grep -q "Read the relevant code" "$DOMAIN_FILE"
    grep -q "create it at that mapped path only when the first term" "$DOMAIN_FILE"
    grep -q "create a root.*only when the first project-specific domain term" "$DOMAIN_FILE"
    grep -q "Never fall back to the root" "$DOMAIN_FILE"
    grep -q "Write a resolved term during the round that resolves it" "$DOMAIN_FILE"
}

@test "grilling does not create ADRs" {
    grep -q "does not create ADRs" "$SKILL_FILE"
    grep -q "Do not create ADRs" "$DOMAIN_FILE"
    grep -q '`design\.md` remains' "$SKILL_FILE"
    ! grep -Eq 'ADR-FORMAT|docs/adr' "$SKILL_FILE" "$DOMAIN_FILE"
}

@test "goal and phase interviews all apply the grilling framework" {
    grep -q "skills/interview-framework/SKILL.md" "$GOAL_GRILL"

    for command in "${PHASE_COMMANDS[@]}"; do
        grep -q "skills/interview-framework/SKILL.md" "$command"
        grep -q "resolve the design-tree frontier" "$command"
    done
}

@test "fixed question counts and one-at-a-time traversal are absent" {
    files=("$SKILL_FILE" "$ALGORITHM_FILE" "$GOAL_GRILL" "$INTENT_FILE" "${PHASE_COMMANDS[@]}")

    ! grep -Eq 'TRIVIAL: [0-9]+-[0-9]+|GREENFIELD: [0-9]+-[0-9]+|Min questions:|Max questions:' "${files[@]}"
    ! grep -Eiq 'questions? one at a time|WHILE askedCount|askedCount >= minRequired|maxAllowed' "${files[@]}"
}

@test "bug task planning reads the goal grill reproduction command" {
    grep -q 'latest `Reproduction command:` entry in the goal grill' "$TASK_PLANNER"
    grep -q 'Goal Grill round' "$TASK_PLANNER"
    ! grep -Eq 'Q5|bug interview' "$TASK_PLANNER"
}

@test "plugin and marketplace versions match" {
    plugin_version=$(jq -r '.version' "plugins/ralph-specum/.claude-plugin/plugin.json")
    marketplace_version=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' ".claude-plugin/marketplace.json")

    [[ "$plugin_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    [ "$plugin_version" = "$marketplace_version" ]
    [ "$plugin_version" = "4.11.0" ]
}
