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

@test "codex phase flow: manifest is 4.12.0 and core interview skill is internal" {
    local root
    root="$(plugin_root)"

    run python3 -c "import json; assert json.load(open('$root/.codex-plugin/plugin.json'))['version'] == '4.12.0'"
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
        [[ "$text" == *"phase_gate.py mode"* ]] || return 1
        [[ "$text" == *'exact `--quick`'* ]] || return 1
        [[ "$text" == *'exact `--interactive`'* ]] || return 1
        [[ "$text" == *'`-q`'* ]] || return 1
        [[ "$text" == *"interview-framework-codex/SKILL.md"* ]] || return 1
        [[ "$text" == *"approve and delegate"* ]] || return 1
        [[ "$text" == *"check-delegation"* ]] || return 1
        [[ "$text" == *"phaseSkillLoad"* || "$text" == *"verbatim manifest"* || "$text" == *"verbatim skill manifest"* ]] || return 1
        [[ "$text" == *"unique teammate dispatch identity"* ]] || return 1
        [[ "$text" == *"check-agent-write"* ]] || return 1
    done < <(phase_skills)
}

@test "codex phase flow: primary routing leaves implement and refactor ungated" {
    local primary
    primary="$(<"$(plugin_root)/skills/ralph-specum/SKILL.md")"

    [[ "$primary" == *'For only `start`, `triage`, `research`, `requirements`, `design`, and `tasks`'* ]] || return 1
    [[ "$primary" == *'Keep the existing delegation flows for `implement` and `refactor` unchanged'* ]] || return 1
    [[ "$primary" != *'For every phase (research, requirements, design, tasks, implement, triage, refactor)'* ]] || return 1
}

@test "codex phase flow: interview contract uses critical frontier rounds and durable partial answers" {
    local root skill algorithm
    root="$(plugin_root)"
    skill="$(<"$root/skills/interview-framework-codex/SKILL.md")"
    algorithm="$(<"$root/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$skill" == *"Ask only critical user decisions"* ]] || return 1
    [[ "$skill" == *"whole currently unblocked critical frontier"* ]] || return 1
    [[ "$skill" == *"three questions per call"* ]] || return 1
    [[ "$skill" == *"Persist each partial answer"* ]] || return 1
    [[ "$skill" == *"setup and administration"* ]] || return 1
    [[ "$skill" == *'`apply the changes`, `continue`, `proceed`, and `go ahead`'* ]] || return 1
    [[ "$skill" == *'bare `skip`'* ]] || return 1
    [[ "$skill" == *"approve and delegate"* ]] || return 1

    [[ "$algorithm" == *"open-frontier STATE --round N --decision-id"* ]] || return 1
    [[ "$algorithm" == *"classify-reply --text TEXT"* ]] || return 1
    [[ "$algorithm" == *"record-answer STATE --decision-id"* ]] || return 1
    [[ "$algorithm" == *"await-confirmation STATE"* ]] || return 1
    [[ "$algorithm" == *"confirm STATE --decision-id ID --source approve-and-delegate"* ]] || return 1
    [[ "$algorithm" == *"skip STATE"* ]] || return 1
    [[ "$algorithm" == *"revise STATE --decision-id ID"* ]] || return 1
    [[ "$algorithm" == *'- `Cancel`'* ]] || return 1
    [[ "$algorithm" == *"leave the interview nonterminal and stop without delegation"* ]] || return 1
    [[ "$algorithm" == *'Re-call `open-frontier` with the same round and remaining pending IDs'* ]] || return 1
}

@test "codex phase flow: skill discovery and preload match the locked sources" {
    local root algorithm
    root="$(plugin_root)"
    algorithm="$(<"$root/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$algorithm" == *"Run pass 1 after start setup"* ]] || return 1
    [[ "$algorithm" == *"Run pass 2 after the final research artifact"* ]] || return 1
    [[ "$algorithm" == *'only the final `research.md` `## Executive Summary` section'* ]] || return 1
    [[ "$algorithm" == *'plugin `skills/*/SKILL.md`'* ]] || return 1
    [[ "$algorithm" == *'project `.agents/skills/*/SKILL.md`'* ]] || return 1
    [[ "$algorithm" == *'project `.claude/skills/*/SKILL.md`'* ]] || return 1
    [[ "$algorithm" == *"current Codex harness available-skills catalog"* ]] || return 1
    [[ "$algorithm" == *"Always select an explicitly named skill"* ]] || return 1
    [[ "$algorithm" == *"harness catalog"* ]] || return 1
    [[ "$algorithm" == *"shadowed"* ]] || return 1
    [[ "$algorithm" == *'`core: true`'* ]] || return 1
    [[ "$algorithm" == *'`core: false`'* ]] || return 1
    [[ "$algorithm" == *'`partial_warned`'* ]] || return 1
    [[ "$algorithm" == *'`core_failed`'* ]] || return 1
    [[ "$algorithm" == *'"failures": []'* ]] || return 1
    [[ "$algorithm" == *'A failed receipt has `sha256: null`'* ]] || return 1
    [[ "$algorithm" == *'`requiredResourceSources`'* ]] || return 1
    [[ "$algorithm" == *"Receipt sources must match the inventory exactly"* ]] || return 1
    [[ "$algorithm" == *"Before each new or resumed grill"* ]] || return 1
    [[ "$(<"$root/skills/interview-framework-codex/SKILL.md")" == *"Start no task action"* ]] || return 1
}

@test "codex downstream phases select pass2 only when research exists" {
    local root skill text
    root="$(plugin_root)"

    for skill in ralph-specum-requirements ralph-specum-design ralph-specum-tasks; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *'When `research.md` exists, require skill discovery pass 2'* ]] || return 1
        [[ "$text" == *'When it is absent, require pass 1 against the goal alone'* ]] || return 1
    done
}

@test "codex phase flow: context identity is immutable and resume preserves answers" {
    local algorithm
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"

    [[ "$algorithm" == *'frame("ralph-phase-context-v1")'* ]] || return 1
    [[ "$algorithm" == *'`frame(BYTES)` is the ASCII decimal byte length'* ]] || return 1
    [[ "$algorithm" == *'requirements includes `research.md` when present'* ]] || return 1
    [[ "$algorithm" == *'design requires `requirements.md` and includes `research.md` when present'* ]] || return 1
    [[ "$algorithm" == *'tasks requires `requirements.md` plus `design.md` and includes `research.md` when present'* ]] || return 1
    [[ "$algorithm" == *"Exclude interview answers, load receipts, discovery history, progress bookkeeping, and skill bytes"* ]] || return 1
    [[ "$algorithm" == *'stored round in `begin-interview`'* ]] || return 1
    [[ "$algorithm" == *"preserves asked, pending, and answered IDs"* ]] || return 1
    [[ "$algorithm" == *"current plus one"* ]] || return 1
    [[ "$algorithm" == *"changed contract bytes make the manifest stale"* ]] || return 1
}

@test "codex phase flow: discovery history is append-only and never executes skills" {
    local algorithm state
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    state="$(<"$(plugin_root)/references/state-contract.md")"

    [[ "$algorithm" == *'Append one `discoveredSkills` entry'* ]] || return 1
    [[ "$algorithm" == *'`pass`, `revision`, `name`, `activeSource`, `reason`, `shadowedSources`, and `outcome`'* ]] || return 1
    [[ "$algorithm" == *"cumulative and append-only"* ]] || return 1
    [[ "$algorithm" == *"executes no skill action"* ]] || return 1
    [[ "$algorithm" == *'legacy `invoked` as history only'* ]] || return 1
    [[ "$state" == *'Legacy `invoked` fields never prove current load'* ]] || return 1
}

@test "codex phase flow: quick skips questions but keeps discovery and load gates" {
    local root skill text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *"both interactive and quick mode"* ]] || return 1
        [[ "$text" == *"current loaded-manifest identity"* ]] || return 1
        [[ "$text" == *"bypassed_quick"* ]] || return 1
    done < <(phase_skills)

    text="$(<"$root/skills/interview-framework-codex/SKILL.md")"
    [[ "$text" == *"Quick mode bypasses interview questions only"* ]] || return 1
}

@test "codex phase flow: precedence-resolved conflicts are recorded without questions" {
    local algorithm workflow
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    workflow="$(<"$(plugin_root)/references/workflow.md")"

    [[ "$algorithm" == *"Apply clear conflicts through the current harness instruction precedence"* ]] || return 1
    [[ "$algorithm" == *"Ask no question for a precedence-resolved conflict"* ]] || return 1
    [[ "$workflow" == *"Ask only unresolved material contract conflicts"* ]] || return 1
}

@test "codex phase flow: artifact prompts and agent templates refuse ungated writes" {
    local root skill prompt template
    root="$(plugin_root)"

    while IFS= read -r skill; do
        prompt="$(<"$root/skills/$skill/agents/openai.yaml")"
        [[ "$prompt" == *"manifest"* ]] || return 1
        [[ "$prompt" == *"check-delegation"* ]] || return 1
        [[ "$prompt" == *"check-agent-write"* ]] || return 1
        [[ "$prompt" == *"discovery revision"* ]] || return 1
        [[ "$prompt" == *"approve-and-delegate"* ]] || return 1
        [[ "$prompt" == *"Refuse dispatch or artifact writes"* ]] || return 1
    done < <(phase_skills)

    for template in triage-analyst research-analyst product-manager architect-reviewer task-planner; do
        prompt="$(<"$root/agent-configs/$template.toml.template")"
        [[ "$prompt" == *"Before reading or writing"* ]] || return 1
        [[ "$prompt" == *"record-agent-load"* ]] || return 1
        [[ "$prompt" == *"unique dispatch identity"* ]] || return 1
        [[ "$prompt" == *"check-agent-write"* ]] || return 1
        [[ "$prompt" == *"discovery revision"* ]] || return 1
        [[ "$prompt" == *"Refuse artifact work"* ]] || return 1
        [[ "$prompt" == *"Failed domain receipts have null hashes"* ]] || return 1
    done
}

@test "codex phase flow: documented gate CLI matches the final helper contract" {
    local algorithm state
    algorithm="$(<"$(plugin_root)/skills/interview-framework-codex/references/algorithm.md")"
    state="$(<"$(plugin_root)/references/state-contract.md")"

    [[ "$algorithm" == *'`classify-reply` prints exactly `bare_skip`, `control_only`, or `substantive`'* ]] || return 1
    [[ "$algorithm" == *'`revise` requires `awaiting_confirmation`'* ]] || return 1
    [[ "$algorithm" == *'check-agent-write STATE --phase PHASE --interview-id ID --context-digest SHA256 --discovery-revision REV --agent UNIQUE_DISPATCH_ID'* ]] || return 1
    [[ "$state" == *'confirm STATE --decision-id ID --source approve-and-delegate'* ]] || return 1
    [[ "$state" == *'revise STATE --decision-id ID [--decision-id ID ...]'* ]] || return 1
    [[ "$state" == *'Failed receipts require `sha256: null`'* ]] || return 1
}

@test "codex phase flow: triage gates on epic state" {
    local text
    text="$(<"$(plugin_root)/skills/ralph-specum-triage/SKILL.md")"

    [[ "$text" == *'`.epic-state.json` as `STATE`'* ]] || return 1
    [[ "$text" == *'phase `triage`'* ]] || return 1
    [[ "$text" == *'do not require `.ralph-state.json`'* ]] || return 1
    [[ "$text" == *'normalize mode before any possible question'* ]] || return 1
    [[ "$text" == *'With exact `--quick`, resume the matching active epic without prompting'* ]] || return 1
    [[ "$text" == *'use local Spec files as the deterministic default and ask nothing'* ]] || return 1
    [[ "$text" == *'Create no `research.md`, `epic.md`, or generated `plan.md` before approval'* ]] || return 1
    [[ "$text" == *"Read-only exploration children"* ]] || return 1
    [[ "$text" == *"separate unique gated writer dispatches"* ]] || return 1
    [[ "$text" == *"coordinator does not assemble"* ]] || return 1
    [[ "$text" == *"administrative destination question"* ]] || return 1
}

@test "codex phase flow: bootstrap and settings cannot enable quick by default" {
    local root bootstrap local_settings settings_template
    root="$(plugin_root)"
    bootstrap="$(<"$root/assets/bootstrap/AGENTS.md")"
    local_settings="$(<"$root/assets/bootstrap/ralph-specum.local.md")"
    settings_template="$(<"$root/templates/settings-template.md")"

    [[ "$bootstrap" == *'Only exact `--quick` enables quick mode'* ]] || return 1
    [[ "$bootstrap" == *'Natural-language requests and `-q` do not enable quick mode'* ]] || return 1
    [[ "$local_settings" == *'Only exact `--quick` enables persistent quick mode'* ]] || return 1
    [[ "$settings_template" != *"quick_mode_default:"* ]] || return 1
    [[ "$settings_template" == *'Only exact `--quick` enables it'* ]] || return 1
    [[ "$(<"$root/skills/ralph-specum-help/SKILL.md")" == *'only exact `--quick` bypasses interview questions'* ]] || return 1
    [[ "$(<"$root/skills/ralph-specum-help/SKILL.md")" == *'exact `--interactive` clears it'* ]] || return 1
}

@test "codex phase flow: apply changes uses pending feedback or asks once" {
    local root skill text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        text="$(<"$root/skills/$skill/SKILL.md")"
        [[ "$text" == *'`apply the changes` immediately delegates already-recorded feedback'* ]] || return 1
        [[ "$text" == *"new unique dispatch"* || "$text" == *"fresh unique gated revision writer"* ]] || return 1
        [[ "$text" == *"Ask one focused change question only when no feedback is pending"* ]] || return 1
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
