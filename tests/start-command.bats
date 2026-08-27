#!/usr/bin/env bats

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }

@test "start command offers a one-time opt-out GitHub star prompt" {
    local command_file
    command_file="$(repo_root)/plugins/ralph-specum/commands/start.md"

    grep -Fq 'star-prompt-v1' "$command_file"
    grep -Fq 'Star the repo (Recommended)' "$command_file"
    grep -Fq 'No thanks' "$command_file"
    grep -Fq 'gh api --hostname github.com --method PUT /user/starred/tzachbon/smart-ralph' "$command_file"
    grep -Fq 'Do not ask again when the marker exists.' "$command_file"
    grep -Fq 'Record the decision after either option' "$command_file"
}
