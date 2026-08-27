#!/usr/bin/env bats

set -e

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }
plugin_root() { echo "$(repo_root)/plugins/ralph-specum-codex"; }

phase_skills() {
    cat <<'EOF'
ralph-specum-start
ralph-specum-triage
ralph-specum-research
ralph-specum-requirements
ralph-specum-design
ralph-specum-tasks
EOF
}

@test "codex phase flow: manifest is 4.11.0 and core interview skill is internal" {
    local root
    root="$(plugin_root)"

    run python3 -c "import json; assert json.load(open('$root/.codex-plugin/plugin.json'))['version'] == '4.11.0'"
    [ "$status" -eq 0 ]
    [ -f "$root/skills/interview-framework-codex/SKILL.md" ]
    [ -f "$root/skills/interview-framework-codex/references/algorithm.md" ]
    grep -q 'surface: internal' "$root/skills/interview-framework-codex/SKILL.md"
    grep -q 'allow_implicit_invocation: false' "$root/skills/interview-framework-codex/agents/openai.yaml"
}

@test "codex phase flow: each affected phase normalizes mode and gates delegation" {
    local root skill text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *"phase_gate.py mode"* ]]
        [[ "$text" == *'exact `--quick`'* ]]
        [[ "$text" == *'exact `--interactive`'* ]]
        [[ "$text" == *'`-q`'* ]]
        [[ "$text" == *"interview-framework-codex/SKILL.md"* ]]
        [[ "$text" == *"approve and delegate"* ]]
        [[ "$text" == *"check-delegation"* ]]
        [[ "$text" == *"phaseSkillLoad"* || "$text" == *"verbatim manifest"* || "$text" == *"verbatim skill manifest"* ]]
        [[ "$text" == *"unique teammate dispatch identity"* ]]
        [[ "$text" == *"check-agent-write"* ]]
    done < <(phase_skills)
}

@test "codex phase flow: primary routing leaves implement and refactor ungated" {
    local primary
    primary="$(<"$(plugin_root)/skills/ralph-specum/SKILL.md")"

    [[ "$primary" == *'For only `start`, `triage`, `research`, `requirements`, `design`, and `tasks`'* ]]
    [[ "$primary" == *'Keep the existing delegation flows for `implement` and `refactor` unchanged'* ]]
    [[ "$primary" != *'For every phase (research, requirements, design, tasks, implement, triage, refactor)'* ]]
}

@test "codex phase flow: interview contract uses critical frontier rounds and durable partial answers" {
    local root skill algorithm
    root="$(plugin_root)"
    skill="$(<"$root/skills/interview-framework-codex/SKILL.md")"
    algorithm="$(<"$root/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$skill" == *"Ask only critical user decisions"* ]]
    [[ "$skill" == *"whole currently unblocked critical frontier"* ]]
    [[ "$skill" == *"three questions per call"* ]]
    [[ "$skill" == *"Persist each partial answer"* ]]
    [[ "$skill" == *"setup and administration"* ]]
    [[ "$skill" == *'`apply the changes`, `continue`, `proceed`, and `go ahead`'* ]]
    [[ "$skill" == *'bare `skip`'* ]]
    [[ "$skill" == *"approve and delegate"* ]]

    [[ "$algorithm" == *"open-frontier STATE --round N --decision-id"* ]]
    [[ "$algorithm" == *"classify-reply --text TEXT"* ]]
    [[ "$algorithm" == *"record-answer STATE --decision-id"* ]]
    [[ "$algorithm" == *"await-confirmation STATE"* ]]
    [[ "$algorithm" == *"confirm STATE --decision-id ID --source approve-and-delegate"* ]]
    [[ "$algorithm" == *"skip STATE"* ]]
    [[ "$algorithm" == *"revise STATE --decision-id ID"* ]]
    [[ "$algorithm" == *'- `Cancel`'* ]]
    [[ "$algorithm" == *"leave the interview nonterminal and stop without delegation"* ]]
    [[ "$algorithm" == *'Re-call `open-frontier` with the same round and remaining pending IDs'* ]]
}

@test "codex phase flow: skill discovery and preload match the locked sources" {
    local root algorithm
    root="$(plugin_root)"
    algorithm="$(<"$root/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$algorithm" == *"Run pass 1 after start setup"* ]]
    [[ "$algorithm" == *"Run pass 2 after the final research artifact"* ]]
    [[ "$algorithm" == *'only the final `research.md` `## Executive Summary` section'* ]]
    [[ "$algorithm" == *'plugin `skills/*/SKILL.md`'* ]]
    [[ "$algorithm" == *'project `.agents/skills/*/SKILL.md`'* ]]
    [[ "$algorithm" == *'project `.claude/skills/*/SKILL.md`'* ]]
    [[ "$algorithm" == *"current Codex harness available-skills catalog"* ]]
    [[ "$algorithm" == *"Always select an explicitly named skill"* ]]
    [[ "$algorithm" == *"harness catalog"* ]]
    [[ "$algorithm" == *"shadowed"* ]]
    [[ "$algorithm" == *'`core: true`'* ]]
    [[ "$algorithm" == *'`core: false`'* ]]
    [[ "$algorithm" == *'`partial_warned`'* ]]
    [[ "$algorithm" == *'`core_failed`'* ]]
    [[ "$algorithm" == *'"failures": []'* ]]
    [[ "$algorithm" == *'A failed receipt has `sha256: null`'* ]]
    [[ "$algorithm" == *'`requiredResourceSources`'* ]]
    [[ "$algorithm" == *"Receipt sources must match the inventory exactly"* ]]
    [[ "$algorithm" == *"Before each new or resumed grill"* ]]
    [[ "$(<"$root/skills/interview-framework-codex/SKILL.md")" == *"Start no task action"* ]]
}

@test "codex downstream phases select pass2 only when research exists" {
    local root skill text
    root="$(plugin_root)"

    for skill in ralph-specum-requirements ralph-specum-design ralph-specum-tasks; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *'When `research.md` exists, require skill discovery pass 2'* ]]
        [[ "$text" == *'When it is absent, require pass 1 against the goal alone'* ]]
    done
}

@test "codex phase flow: context identity is immutable and resume preserves answers" {
    local algorithm
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$algorithm" == *'frame("ralph-phase-context-v1")'* ]]
    [[ "$algorithm" == *'`frame(BYTES)` is the ASCII decimal byte length'* ]]
    [[ "$algorithm" == *'`research.md`, `requirements.md`, `design.md`'* ]]
    [[ "$algorithm" == *"Exclude mutable interview answers"* ]]
    [[ "$algorithm" == *'stored round in `begin-interview`'* ]]
    [[ "$algorithm" == *"preserves asked, pending, and answered IDs"* ]]
    [[ "$algorithm" == *"current plus one"* ]]
    [[ "$algorithm" == *"changed contract bytes make the manifest stale"* ]]
}

@test "codex phase flow: discovery history is append-only and never executes skills" {
    local algorithm state
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    state="$(<"$(plugin_root)/references/state-contract.md")"

    [[ "$algorithm" == *'Append one `discoveredSkills` entry'* ]]
    [[ "$algorithm" == *'`pass`, `revision`, `name`, `activeSource`, `reason`, and `shadowedSources`'* ]]
    [[ "$algorithm" == *"cumulative and append-only"* ]]
    [[ "$algorithm" == *"executes no skill action"* ]]
    [[ "$algorithm" == *'legacy `invoked` as history only'* ]]
    [[ "$state" == *'Legacy `invoked` fields never prove current load'* ]]
}

@test "codex phase flow: quick skips questions but keeps discovery and load gates" {
    local root skill text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *"both interactive and quick mode"* ]]
        [[ "$text" == *"current loaded-manifest identity"* ]]
        [[ "$text" == *"bypassed_quick"* ]]
    done < <(phase_skills)

    text="$(<"$root/skills/interview-framework-codex/SKILL.md")"
    [[ "$text" == *"Quick mode bypasses interview questions only"* ]]
}

@test "codex phase flow: precedence-resolved conflicts are recorded without questions" {
    local algorithm workflow
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    workflow="$(<"$(plugin_root)/references/workflow.md")"

    [[ "$algorithm" == *"Apply clear conflicts through the current harness instruction precedence"* ]]
    [[ "$algorithm" == *"Ask no question for a precedence-resolved conflict"* ]]
    [[ "$workflow" == *"Ask only unresolved material contract conflicts"* ]]
}

@test "codex phase flow: artifact prompts and agent templates refuse ungated writes" {
    local root skill prompt template
    root="$(plugin_root)"

    while IFS= read -r skill; do
        prompt="$(<"$root/skills/$skill/agents/openai.yaml")"
        [[ "$prompt" == *"manifest"* ]]
        [[ "$prompt" == *"check-delegation"* ]]
        [[ "$prompt" == *"check-agent-write"* ]]
        [[ "$prompt" == *"discovery revision"* ]]
        [[ "$prompt" == *"approve-and-delegate"* ]]
        [[ "$prompt" == *"Refuse dispatch or artifact writes"* ]]
    done < <(phase_skills)

    for template in triage-analyst research-analyst product-manager architect-reviewer task-planner; do
        prompt="$(<"$root/agent-configs/$template.toml.template")"
        [[ "$prompt" == *"Before reading or writing"* ]]
        [[ "$prompt" == *"record-agent-load"* ]]
        [[ "$prompt" == *"unique dispatch identity"* ]]
        [[ "$prompt" == *"check-agent-write"* ]]
        [[ "$prompt" == *"discovery revision"* ]]
        [[ "$prompt" == *"Refuse artifact work"* ]]
        [[ "$prompt" == *"Failed domain receipts have null hashes"* ]]
    done
}

@test "codex phase flow: documented gate CLI matches the final helper contract" {
    local algorithm state
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    state="$(<"$(plugin_root)/references/state-contract.md")"

    [[ "$algorithm" == *'`classify-reply` prints exactly `bare_skip`, `control_only`, or `substantive`'* ]]
    [[ "$algorithm" == *'`revise` requires `awaiting_confirmation`'* ]]
    [[ "$algorithm" == *'check-agent-write STATE --phase PHASE --interview-id ID --context-digest SHA256 --discovery-revision REV --agent UNIQUE_DISPATCH_ID'* ]]
    [[ "$state" == *'confirm STATE --decision-id ID --source approve-and-delegate'* ]]
    [[ "$state" == *'revise STATE --decision-id ID [--decision-id ID ...]'* ]]
    [[ "$state" == *'Failed receipts require `sha256: null`'* ]]
}

@test "codex phase flow: triage gates on epic state" {
    local text
    text="$(<"$(plugin_root)/skills/ralph-specum-triage/SKILL.md")"

    [[ "$text" == *'`.epic-state.json` as `STATE`'* ]]
    [[ "$text" == *'phase `triage`'* ]]
    [[ "$text" == *'do not require `.ralph-state.json`'* ]]
    [[ "$text" == *'normalize mode before any possible question'* ]]
    [[ "$text" == *'With exact `--quick`, resume the matching active epic without prompting'* ]]
    [[ "$text" == *'use local Spec files as the deterministic default and ask nothing'* ]]
    [[ "$text" == *'Create no `research.md`, `epic.md`, or generated `plan.md` before approval'* ]]
    [[ "$text" == *"Read-only exploration children"* ]]
    [[ "$text" == *"separate unique gated writer dispatches"* ]]
    [[ "$text" == *"coordinator does not assemble"* ]]
    [[ "$text" == *"administrative destination question"* ]]
}

@test "codex phase flow: bootstrap and settings cannot enable quick by default" {
    local root bootstrap local_settings settings_template
    root="$(plugin_root)"
    bootstrap="$(<"$root/assets/bootstrap/AGENTS.md")"
    local_settings="$(<"$root/assets/bootstrap/ralph-specum.local.md")"
    settings_template="$(<"$root/templates/settings-template.md")"

    [[ "$bootstrap" == *'Only exact `--quick` enables quick mode'* ]]
    [[ "$bootstrap" == *'Natural-language requests and `-q` do not enable quick mode'* ]]
    [[ "$local_settings" == *'Only exact `--quick` enables persistent quick mode'* ]]
    [[ "$settings_template" != *"quick_mode_default:"* ]]
    [[ "$settings_template" == *'Only exact `--quick` enables it'* ]]
    [[ "$(<"$root/skills/ralph-specum-help/SKILL.md")" == *'only exact `--quick` bypasses interview questions'* ]]
    [[ "$(<"$root/skills/ralph-specum-help/SKILL.md")" == *'exact `--interactive` clears it'* ]]
}

@test "codex phase flow: apply changes uses pending feedback or asks once" {
    local root skill text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *'`apply the changes` immediately delegates already-recorded feedback'* ]]
        [[ "$text" == *"new unique dispatch"* || "$text" == *"fresh unique gated revision writer"* ]]
        [[ "$text" == *"Ask one focused change question only when no feedback is pending"* ]]
    done < <(phase_skills)
}

@test "codex phase flow: edited contract files stay ASCII" {
    run python3 - "$(plugin_root)" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
paths = [
    root / "skills/interview-framework-codex/SKILL.md",
    root / "skills/interview-framework-codex/references/algorithm.md",
    root / "references/workflow.md",
    root / "references/state-contract.md",
    root / "assets/bootstrap/AGENTS.md",
    root / "assets/bootstrap/ralph-specum.local.md",
    root / "templates/settings-template.md",
]
paths.extend((root / "skills" / name / "SKILL.md") for name in (
    "ralph-specum", "ralph-specum-start", "ralph-specum-triage",
    "ralph-specum-research", "ralph-specum-requirements",
    "ralph-specum-design", "ralph-specum-tasks",
    "ralph-specum-help",
))
for path in paths:
    path.read_text(encoding="ascii")
PY
    [ "$status" -eq 0 ]
}
