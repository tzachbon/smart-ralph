# Tasks: Codex Plugin Sync

## Summary

**Total tasks**: 56
**Workflow**: POC-first (GREENFIELD)

| Phase | Tasks | Description |
|-------|-------|-------------|
| Phase 1: Make It Work | 1.1 - 1.34 | Build full plugin structure, all skills, agents, hooks, templates, references, scripts, marketplace |
| Phase 2: Refactor | 2.1 - 2.6 | Clean up skill content, consolidate references, fix any shortcuts |
| Phase 3: Testing | 3.1 - 3.10 | BATS tests for new plugin, version-sync helper, update old tests, CI updates |
| Phase 4: Quality Gates | 4.1 - 4.3 | Full test run, CI green, AC checklist |
| Phase 5: PR Lifecycle | 5.1 - 5.5 | PR creation, CI monitoring, review resolution, cleanup commit |

**POC Milestone**: By 1.34, `plugins/codex/` exists with all required files, marketplace.json created, and `bats tests/codex-plugin.bats` passes basic structure checks.

---

## Phase 1: Make It Work (POC)

Focus: Build the plugin. Skip polish. Accept hardcoded content, minimal prose. Get structure right.

- [x] 1.1 Create plugin directory skeleton and manifest
  - **Do**:
    1. Create directory tree: `plugins/codex/.codex-plugin/`, `skills/`, `agent-configs/`, `hooks/`, `templates/`, `references/`, `schemas/`, `scripts/`, `assets/bootstrap/`
    2. Write `.codex-plugin/plugin.json` with: `name: "ralph-specum"`, `version: "4.9.1"`, `description`, `author`, `license`, `keywords`, `skills: "./skills"`, `hooks: {"Stop": "./hooks/stop-watcher.sh"}`
  - **Files**: `plugins/codex/.codex-plugin/plugin.json`
  - **Done when**: `plugin.json` exists, is valid JSON, version is `4.9.1`, has `name`, `description`, `hooks` fields
  - **Verify**: `jq -e '.version == "4.9.1" and .name == "ralph-specum" and (.hooks | has("Stop"))' plugins/codex/.codex-plugin/plugin.json && echo PASS`
  - **Commit**: `feat(codex-plugin): add plugin manifest v4.9.1`
  - _Requirements: AC-1.1, AC-1.2, AC-8.4_
  - _Design: Plugin Manifest_

- [x] 1.2 Create marketplace.json with ralph-specum entry
  - **Do**:
    1. Create `.agents/plugins/` directory
    2. Write `.agents/plugins/marketplace.json` as a JSON array containing one entry: `name: "ralph-specum"`, `description`, `version: "4.9.1"`, `source: {source: "local", path: "./plugins/codex"}`, `policy: {installation: "AVAILABLE"}`
  - **Files**: `.agents/plugins/marketplace.json`
  - **Done when**: File is valid JSON array, entry present with `version: "4.9.1"` and `policy.installation: "AVAILABLE"`
  - **Verify**: `jq -e '.[0].name == "ralph-specum" and .[0].version == "4.9.1" and .[0].policy.installation == "AVAILABLE"' .agents/plugins/marketplace.json && echo PASS`
  - **Commit**: `feat(codex-plugin): create marketplace.json with ralph-specum entry`
  - _Requirements: AC-10.1, AC-10.2, AC-10.3_
  - _Design: Marketplace Entry_

- [x] 1.3 [VERIFY] Quality checkpoint: plugin.json + marketplace.json valid
  - **Do**: Verify both JSON files are valid and versions match
  - **Verify**: `jq -r .version plugins/codex/.codex-plugin/plugin.json && jq -r '.[0].version' .agents/plugins/marketplace.json && echo PASS`
  - **Done when**: Both commands exit 0, both print `4.9.1`
  - **Commit**: none

- [x] 1.4 [P] Copy Python scripts from platforms/codex with path fixes
  - **Do**:
    1. Copy `platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py` to `plugins/codex/scripts/`
    2. Copy `platforms/codex/skills/ralph-specum/scripts/merge_state.py` to `plugins/codex/scripts/`
    3. Copy `platforms/codex/skills/ralph-specum/scripts/count_tasks.py` to `plugins/codex/scripts/`
    4. Search each file for any hardcoded `platforms/codex/` path references; update to `plugins/codex/` if found
  - **Files**: `plugins/codex/scripts/resolve_spec_paths.py`, `plugins/codex/scripts/merge_state.py`, `plugins/codex/scripts/count_tasks.py`
  - **Done when**: All 3 scripts present, no `platforms/codex` substring in any of them
  - **Verify**: `ls plugins/codex/scripts/*.py | wc -l | grep -q 3 && ! grep -r 'platforms/codex' plugins/codex/scripts/ && echo PASS`
  - **Commit**: `feat(codex-plugin): copy python scripts from platforms/codex`
  - _Requirements: AC-5.4_
  - _Design: Python Scripts_

- [x] 1.5 [P] Copy JSON schema
  - **Do**: Copy `plugins/ralph-specum/schemas/spec.schema.json` to `plugins/codex/schemas/spec.schema.json`
  - **Files**: `plugins/codex/schemas/spec.schema.json`
  - **Done when**: File exists and is valid JSON
  - **Verify**: `jq . plugins/codex/schemas/spec.schema.json > /dev/null && echo PASS`
  - **Commit**: `feat(codex-plugin): copy spec schema`
  - _Requirements: AC-5.3_

- [x] 1.6 [VERIFY] Quality checkpoint: scripts + schema exist
  - **Do**: Verify all 3 scripts and schema exist
  - **Verify**: `for f in resolve_spec_paths.py merge_state.py count_tasks.py; do [ -f "plugins/codex/scripts/$f" ] || exit 1; done && [ -f plugins/codex/schemas/spec.schema.json ] && echo PASS`
  - **Done when**: All files present
  - **Commit**: none

- [x] 1.7 [P] Copy templates from Claude plugin (9 existing + epic.md)
  - **Do**:
    1. Copy all 9 templates from `plugins/ralph-specum/templates/` to `plugins/codex/templates/`: `component-spec.md`, `design.md`, `external-spec.md`, `index-summary.md`, `progress.md`, `requirements.md`, `research.md`, `settings-template.md`, `tasks.md`
    2. Copy `plugins/ralph-specum/templates/epic.md` to `plugins/codex/templates/epic.md` (this template was missing from platforms/codex)
  - **Files**: `plugins/codex/templates/` (10 files)
  - **Done when**: All 10 template files exist in plugin templates dir
  - **Verify**: `ls plugins/codex/templates/*.md | wc -l | grep -q 10 && echo PASS`
  - **Commit**: `feat(codex-plugin): copy all 10 templates including epic.md`
  - _Requirements: AC-5.1, AC-4.3, FR-5, FR-6_
  - _Design: Templates_

- [x] 1.8 [P] Copy bootstrap assets from platforms/codex
  - **Do**:
    1. Copy `platforms/codex/skills/ralph-specum/assets/bootstrap/AGENTS.md` to `plugins/codex/assets/bootstrap/AGENTS.md`
    2. Copy `platforms/codex/skills/ralph-specum/assets/bootstrap/ralph-specum.local.md` to `plugins/codex/assets/bootstrap/ralph-specum.local.md`
  - **Files**: `plugins/codex/assets/bootstrap/AGENTS.md`, `plugins/codex/assets/bootstrap/ralph-specum.local.md`
  - **Done when**: Both files exist
  - **Verify**: `[ -f plugins/codex/assets/bootstrap/AGENTS.md ] && [ -f plugins/codex/assets/bootstrap/ralph-specum.local.md ] && echo PASS`
  - **Commit**: `feat(codex-plugin): copy bootstrap assets`
  - _Design: Bootstrap assets_

- [x] 1.9 [VERIFY] Quality checkpoint: templates + assets present
  - **Do**: Count templates and verify bootstrap assets
  - **Verify**: `ls plugins/codex/templates/*.md | wc -l | grep -q 10 && ls plugins/codex/assets/bootstrap/ | wc -l | grep -q 2 && echo PASS`
  - **Done when**: 10 templates, 2 bootstrap assets
  - **Commit**: none

- [x] 1.10 Copy and adapt reference files from platforms/codex
  - **Do**:
    1. Copy `platforms/codex/skills/ralph-specum/references/workflow.md` to `plugins/codex/references/workflow.md`
    2. Copy `platforms/codex/skills/ralph-specum/references/state-contract.md` to `plugins/codex/references/state-contract.md`
    3. Copy `platforms/codex/skills/ralph-specum/references/path-resolution.md` to `plugins/codex/references/path-resolution.md`
    4. Copy `platforms/codex/skills/ralph-specum/references/parity-matrix.md` to `plugins/codex/references/parity-matrix.md`
    5. Append a "## Version Delta (v4.8.4 -> v4.9.1)" section to `parity-matrix.md` listing: added `epic.md` template, updated `tasks.md` (192->588 lines), updated `settings-template.md` (24->79 lines), added 3 net-new agent configs (spec-reviewer, qa-engineer, refactor-specialist), added `workflow.md` verification-layers + failure-recovery sections
    6. Append to `workflow.md`: a "## Hook-Driven Execution Path" section (describe stop hook loop with `{"decision":"block","reason":"..."}` output) and a "## Manual Fallback Path" section (step-by-step re-invocation instructions)
  - **Files**: `plugins/codex/references/` (4 files)
  - **Done when**: All 4 references exist; parity-matrix has "Version Delta" section; workflow.md has both execution path sections
  - **Verify**: `grep -q "Version Delta" plugins/codex/references/parity-matrix.md && grep -q "Hook-Driven" plugins/codex/references/workflow.md && grep -q "Manual Fallback" plugins/codex/references/workflow.md && echo PASS`
  - **Commit**: `feat(codex-plugin): copy + update references with v4.9.1 delta`
  - _Requirements: AC-4.1, AC-9.4, US-9_
  - _Design: References_

- [x] 1.11 [VERIFY] Quality checkpoint: all 4 references present and updated
  - **Do**: Verify reference files exist and have required sections
  - **Verify**: `for f in workflow.md state-contract.md path-resolution.md parity-matrix.md; do [ -f "plugins/codex/references/$f" ] || exit 1; done && echo PASS`
  - **Done when**: All 4 files present
  - **Commit**: none

- [x] 1.12 Write stop-watcher.sh hook (Codex output format)
  - **Do**:
    1. Create `plugins/codex/hooks/stop-watcher.sh`
    2. Read stdin JSON, extract `cwd` field with jq
    3. Locate `.ralph-state.json` via `<cwd>/specs/.current-spec` (read spec name, build path `<cwd>/specs/<name>/.ralph-state.json`)
    4. Also check `<cwd>/.claude/ralph-specum.local.md` for `specs_dirs` setting; if present, use Python script to find the spec path
    5. If no state file found: `exit 0`
    6. Read `taskIndex` and `totalTasks` from state file with jq
    7. Read `awaitingApproval` from state file; if `true`: `exit 0`
    8. If `taskIndex >= totalTasks`: print `ALL_TASKS_COMPLETE` to stdout, `exit 0`
    9. Else: output `{"decision":"block","reason":"Continue to task <taskIndex+1>/<totalTasks>"}` to stdout
    10. Make file executable: `chmod +x hooks/stop-watcher.sh`
  - **Files**: `plugins/codex/hooks/stop-watcher.sh`
  - **Done when**: File is executable; outputs `{"decision":"block",...}` JSON or exits 0; handles missing state file gracefully
  - **Verify**: `[ -x plugins/codex/hooks/stop-watcher.sh ] && echo '{"cwd":"/tmp"}' | bash plugins/codex/hooks/stop-watcher.sh; echo EXIT:$?`
  - **Commit**: `feat(codex-plugin): write stop-watcher.sh hook with Codex decision:block format`
  - _Requirements: AC-8.1, AC-8.2, AC-8.3, FR-10_
  - _Design: Stop Hook_

- [x] 1.13 [VERIFY] Quality checkpoint: hook is executable and handles no-state gracefully
  - **Do**: Run hook with no state file, verify exit 0
  - **Verify**: `echo '{"cwd":"/nonexistent/path"}' | bash plugins/codex/hooks/stop-watcher.sh && echo PASS`
  - **Done when**: Exit 0 when no state file present
  - **Commit**: none

- [x] 1.14 Write ralph-specum primary skill (bootstrap/help)
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum/SKILL.md`
    2. Content: adapt `platforms/codex/skills/ralph-specum/SKILL.md` — keep all routing table rows (`| Start |`, `| Triage |`, etc.), approval handoff text, "Use only when the user explicitly invokes `$ralph-specum`" instruction, "## Response Handoff" section
    3. Replace any `platforms/codex/` path references with `plugins/codex/`
    4. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum/SKILL.md`
  - **Done when**: File exists; contains all required routing tokens; no `platforms/codex` refs; under 2000 words
  - **Verify**: `[ -f plugins/codex/skills/ralph-specum/SKILL.md ] && grep -q "| Triage |" plugins/codex/skills/ralph-specum/SKILL.md && grep -q "Response Handoff" plugins/codex/skills/ralph-specum/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum primary skill`
  - _Requirements: AC-3.1, AC-3.2_
  - _Design: Skill inventory_

- [x] 1.15 [P] Write ralph-specum-start skill (merges start+new)
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-start/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-start/SKILL.md` — preserve: quick mode, granularity, `.current-epic` check, `awaitingApproval` handling
    3. Merge new-spec creation behavior (from `plugins/ralph-specum/commands/new.md`) into the start skill — no separate `new` skill needed
    4. Replace Task tool / coordinator refs with `spawn_agent("ralph-specum:research-analyst", prompt="...")` pattern
    5. Include approval handoff: "wait for explicit direction", "research" tokens
    6. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-start/SKILL.md`
  - **Done when**: File exists; contains `quick mode`, `granularity`, `awaitingApproval`, `spawn_agent`; no `Task tool` refs
  - **Verify**: `grep -q "quick mode" plugins/codex/skills/ralph-specum-start/SKILL.md && grep -q "spawn_agent" plugins/codex/skills/ralph-specum-start/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-start skill (merges start+new)`
  - _Requirements: AC-3.1, AC-3.3, AC-7.1, FR-3_

- [x] 1.16 [P] Write ralph-specum-research skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-research/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-research/SKILL.md` — preserve: brainstorming, research.md, verification tooling tokens
    3. Replace Task tool with `spawn_agent("ralph-specum:research-analyst", prompt="...")`
    4. Include approval handoff: "approve current artifact", "continue to requirements"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-research/SKILL.md`
  - **Done when**: File exists; `spawn_agent` present; approval handoff tokens present
  - **Verify**: `grep -q "spawn_agent" plugins/codex/skills/ralph-specum-research/SKILL.md && grep -q "approve current artifact" plugins/codex/skills/ralph-specum-research/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-research skill`
  - _Requirements: AC-3.1, AC-7.1_

- [x] 1.17 [VERIFY] Quality checkpoint: first 3 skills created
  - **Do**: Verify skills exist and have spawn_agent
  - **Verify**: `for s in ralph-specum ralph-specum-start ralph-specum-research; do [ -f "plugins/codex/skills/$s/SKILL.md" ] || exit 1; done && echo PASS`
  - **Done when**: All 3 SKILL.md files present
  - **Commit**: none

- [x] 1.18 [P] Write ralph-specum-requirements skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-requirements/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-requirements/SKILL.md` — preserve: brainstorming, requirements.md, awaitingApproval tokens
    3. Replace Task tool with `spawn_agent("ralph-specum:product-manager", prompt="...")`
    4. Include approval handoff: "approve current artifact", "continue to design"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-requirements/SKILL.md`
  - **Done when**: File exists; `spawn_agent("ralph-specum:product-manager"` present; approval tokens present
  - **Verify**: `grep -q 'ralph-specum:product-manager' plugins/codex/skills/ralph-specum-requirements/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-requirements skill`
  - _Requirements: AC-3.1, AC-7.2_

- [x] 1.19 [P] Write ralph-specum-design skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-design/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-design/SKILL.md` — preserve: brainstorming, design.md, awaitingApproval tokens
    3. Replace Task tool with `spawn_agent("ralph-specum:architect-reviewer", prompt="...")`
    4. Include approval handoff: "approve current artifact", "continue to tasks"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-design/SKILL.md`
  - **Done when**: File exists; `spawn_agent("ralph-specum:architect-reviewer"` present; approval tokens present
  - **Verify**: `grep -q 'ralph-specum:architect-reviewer' plugins/codex/skills/ralph-specum-design/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-design skill`
  - _Requirements: AC-3.1, AC-7.3_

- [x] 1.20 [P] Write ralph-specum-tasks skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-tasks/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-tasks/SKILL.md` — preserve: granularity, `[P]`, `[VERIFY]`, VE tasks, `taskIndex: first incomplete or totalTasks` tokens
    3. Replace Task tool with `spawn_agent("ralph-specum:task-planner", prompt="...")`
    4. Include approval handoff: "approve current artifact", "continue to implementation"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-tasks/SKILL.md`
  - **Done when**: File exists; `spawn_agent("ralph-specum:task-planner"` present; granularity token present
  - **Verify**: `grep -q 'ralph-specum:task-planner' plugins/codex/skills/ralph-specum-tasks/SKILL.md && grep -q 'granularity' plugins/codex/skills/ralph-specum-tasks/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-tasks skill`
  - _Requirements: AC-3.1, AC-7.4_

- [x] 1.21 [VERIFY] Quality checkpoint: requirements/design/tasks skills created
  - **Do**: Verify 3 new skills exist with correct agent references
  - **Verify**: `for s in ralph-specum-requirements ralph-specum-design ralph-specum-tasks; do [ -f "plugins/codex/skills/$s/SKILL.md" ] || exit 1; done && echo PASS`
  - **Done when**: All 3 present
  - **Commit**: none

- [x] 1.22 Write ralph-specum-implement skill (hook loop + manual fallback)
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-implement/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-implement/SKILL.md`
    3. Add "## Automatic Loop (requires `[features] codex_hooks = true`)" section: describe stop hook driving loop via `spawn_agent("ralph-specum:spec-executor", ...)`, state reads, continuation
    4. Add "## Manual Loop (hooks disabled or Windows)" section: step-by-step re-invocation using `.ralph-state.json` fields, exact steps for user to check `taskIndex`/`totalTasks`/`phase` and re-invoke
    5. Preserve: `[P]`, `[VERIFY]`, VE tasks, tasks.md, approval, quick mode, explicit user direction, file sets do not overlap, Marker syntax tokens
    6. Reference `[features] codex_hooks = true` requirement
    7. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-implement/SKILL.md`
  - **Done when**: File has both "Automatic Loop" and "Manual Loop" sections; `codex_hooks` mentioned; `spawn_agent("ralph-specum:spec-executor"` present
  - **Verify**: `grep -q "Automatic Loop" plugins/codex/skills/ralph-specum-implement/SKILL.md && grep -q "Manual Loop" plugins/codex/skills/ralph-specum-implement/SKILL.md && grep -q "codex_hooks" plugins/codex/skills/ralph-specum-implement/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-implement skill with hook loop + manual fallback`
  - _Requirements: AC-4.4, AC-7.5, AC-8.5, AC-9.1, AC-9.2, FR-11_
  - _Design: Skill inventory (implement special structure)_

- [x] 1.23 [P] Write ralph-specum-cancel skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-cancel/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-cancel/SKILL.md` — preserve: `.ralph-state.json`, Safe cancel, full removal tokens
    3. Remove any Task tool / coordinator references
    4. Include approval handoff: "whether anything was removed", "exactly what if so"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-cancel/SKILL.md`
  - **Done when**: File exists; `.ralph-state.json` token present; no Task tool refs
  - **Verify**: `grep -q '.ralph-state.json' plugins/codex/skills/ralph-specum-cancel/SKILL.md && ! grep -q 'Task tool' plugins/codex/skills/ralph-specum-cancel/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-cancel skill`
  - _Requirements: AC-3.1_

- [x] 1.24 [P] Write ralph-specum-status skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-status/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-status/SKILL.md` — preserve: `.current-epic`, approval state, granularity, "there is no active spec" tokens
    3. Add hook availability check: instruct skill to note if `codex_hooks` is enabled/disabled and show fallback instructions if not
    4. Remove any Task tool references
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-status/SKILL.md`
  - **Done when**: File exists; `.current-epic` and `approval state` tokens present
  - **Verify**: `grep -q '.current-epic' plugins/codex/skills/ralph-specum-status/SKILL.md && grep -q 'approval state' plugins/codex/skills/ralph-specum-status/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-status skill`
  - _Requirements: AC-3.1, AC-9.3_

- [x] 1.25 [VERIFY] Quality checkpoint: implement/cancel/status skills created
  - **Do**: Verify 3 skills exist
  - **Verify**: `for s in ralph-specum-implement ralph-specum-cancel ralph-specum-status; do [ -f "plugins/codex/skills/$s/SKILL.md" ] || exit 1; done && echo PASS`
  - **Done when**: All 3 present
  - **Commit**: none

- [x] 1.26 [P] Write ralph-specum-switch skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-switch/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-switch/SKILL.md` — preserve: `.current-spec`, approval state tokens
    3. Remove any Task tool references
    4. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-switch/SKILL.md`
  - **Done when**: File exists; `.current-spec` and `approval state` tokens present
  - **Verify**: `grep -q '.current-spec' plugins/codex/skills/ralph-specum-switch/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-switch skill`
  - _Requirements: AC-3.1_

- [x] 1.27 [P] Write ralph-specum-triage skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-triage/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-triage/SKILL.md` — preserve: `specs/_epics`, `.current-epic`, `.epic-state.json`, dependencies tokens
    3. Replace Task tool with `spawn_agent("ralph-specum:triage-analyst", prompt="...")`
    4. Include approval handoff: "approve current artifact", "continue to the next spec"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-triage/SKILL.md`
  - **Done when**: File exists; `spawn_agent("ralph-specum:triage-analyst"` present; epic tokens present
  - **Verify**: `grep -q 'ralph-specum:triage-analyst' plugins/codex/skills/ralph-specum-triage/SKILL.md && grep -q 'specs/_epics' plugins/codex/skills/ralph-specum-triage/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-triage skill`
  - _Requirements: AC-3.1, AC-7.6_

- [x] 1.28 [P] Write ralph-specum-refactor skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-refactor/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-refactor/SKILL.md` — preserve: requirements.md, design.md, tasks.md, `[VERIFY]` tokens
    3. Replace Task tool with `spawn_agent` where appropriate
    4. Include approval handoff: "approve current artifact", "continue to implementation"
    5. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-refactor/SKILL.md`
  - **Done when**: File exists; approval handoff tokens present; no Task tool refs
  - **Verify**: `grep -q 'approve current artifact' plugins/codex/skills/ralph-specum-refactor/SKILL.md && grep -q 'requirements.md' plugins/codex/skills/ralph-specum-refactor/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-refactor skill`
  - _Requirements: AC-3.1_

- [x] 1.29 [VERIFY] Quality checkpoint: switch/triage/refactor skills created
  - **Do**: Verify 3 skills exist
  - **Verify**: `for s in ralph-specum-switch ralph-specum-triage ralph-specum-refactor; do [ -f "plugins/codex/skills/$s/SKILL.md" ] || exit 1; done && echo PASS`
  - **Done when**: All 3 present
  - **Commit**: none

- [x] 1.30 [P] Write ralph-specum-index skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-index/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-index/SKILL.md` — preserve: `specs/.index`, dry run, deterministic tokens
    3. Remove any Task tool references
    4. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-index/SKILL.md`
  - **Done when**: File exists; `specs/.index` and `dry run` tokens present
  - **Verify**: `grep -q 'specs/.index' plugins/codex/skills/ralph-specum-index/SKILL.md && grep -q 'dry run' plugins/codex/skills/ralph-specum-index/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-index skill`
  - _Requirements: AC-3.1_

- [x] 1.31 [P] Write ralph-specum-feedback skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-feedback/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-feedback/SKILL.md` — preserve: GitHub issue, Codex package, Claude plugin tokens
    3. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-feedback/SKILL.md`
  - **Done when**: File exists; GitHub issue token present
  - **Verify**: `grep -q 'GitHub issue' plugins/codex/skills/ralph-specum-feedback/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-feedback skill`
  - _Requirements: AC-3.1_

- [x] 1.32 [P] Write ralph-specum-help skill
  - **Do**:
    1. Create `plugins/codex/skills/ralph-specum-help/SKILL.md`
    2. Adapt `platforms/codex/skills/ralph-specum-help/SKILL.md` — preserve: `$ralph-specum-triage`, Large effort flow, `.current-epic` tokens
    3. Use Codex invocation syntax (`$skill-name`, not `/plugin:command`)
    4. Keep under 2000 words
  - **Files**: `plugins/codex/skills/ralph-specum-help/SKILL.md`
  - **Done when**: File exists; `$ralph-specum-triage` and `Large effort flow` tokens present
  - **Verify**: `grep -q '\$ralph-specum-triage' plugins/codex/skills/ralph-specum-help/SKILL.md && grep -q 'Large effort flow' plugins/codex/skills/ralph-specum-help/SKILL.md && echo PASS`
  - **Commit**: `feat(codex-plugin): add ralph-specum-help skill`
  - _Requirements: AC-3.1_

- [x] 1.33 [VERIFY] Quality checkpoint: all 15 skills created
  - **Do**: Count all SKILL.md files
  - **Verify**: `find plugins/codex/skills -name 'SKILL.md' | wc -l | grep -q 15 && echo PASS`
  - **Done when**: Exactly 15 SKILL.md files found
  - **Commit**: none

- [x] 1.34 Write 9 agent-config TOML templates
  - **Do**:
    1. Create `plugins/codex/agent-configs/README.md` with install instructions: explain that these are bootstrap templates to paste into `.codex/config.toml`, show example merge procedure
    2. For each of 9 agents, create `agent-configs/<name>.toml.template` by adapting the corresponding `plugins/ralph-specum/agents/<name>.md`:
       - `research-analyst.toml.template` from `agents/research-analyst.md`
       - `product-manager.toml.template` from `agents/product-manager.md`
       - `architect-reviewer.toml.template` from `agents/architect-reviewer.md`
       - `task-planner.toml.template` from `agents/task-planner.md`
       - `spec-executor.toml.template` from `agents/spec-executor.md` — MUST include TASK_COMPLETE / ALL_TASKS_COMPLETE protocol in system prompt
       - `spec-reviewer.toml.template` from `agents/spec-reviewer.md`
       - `qa-engineer.toml.template` from `agents/qa-engineer.md`
       - `refactor-specialist.toml.template` from `agents/refactor-specialist.md`
       - `triage-analyst.toml.template` from `agents/triage-analyst.md`
    3. Each template format: TOML comment header noting it is a paste target for `config.toml`, then `[agents.ralph-specum-<name>]` block with `description`, `model` (omit or use `""` as placeholder), and a comment block containing the system prompt text (since `developer_instructions` field name is unconfirmed per design unresolved questions — use comment format and note in README to check Codex docs)
    4. Keep each template file under 400 lines
  - **Files**: `plugins/codex/agent-configs/README.md` + 9 `.toml.template` files
  - **Done when**: 9 template files exist + README; spec-executor template contains `TASK_COMPLETE`
  - **Verify**: `ls plugins/codex/agent-configs/*.toml.template | wc -l | grep -q 9 && grep -q 'TASK_COMPLETE' plugins/codex/agent-configs/spec-executor.toml.template && [ -f plugins/codex/agent-configs/README.md ] && echo PASS`
  - **Commit**: `feat(codex-plugin): add 9 agent-config TOML templates`
  - _Requirements: AC-6.1, AC-6.2, AC-6.4, FR-7, FR-9_
  - _Design: Agent Bootstrap Templates_

- [x] 1.35 [VERIFY] Quality checkpoint: agent configs complete
  - **Do**: Count templates and verify README
  - **Verify**: `ls plugins/codex/agent-configs/*.toml.template | wc -l | grep -q 9 && [ -f plugins/codex/agent-configs/README.md ] && echo PASS`
  - **Done when**: 9 templates + README present
  - **Commit**: none

- [x] 1.36 Write plugin README.md (installation + migration guide)
  - **Do**:
    1. Create `plugins/codex/README.md`
    2. Include sections:
       - "## Installation" — step-by-step: (1) enable plugin feature flag if needed, (2) add marketplace entry, (3) run Codex install command or copy plugin files, (4) add `[features] codex_hooks = true` to Codex config
       - "## Agent Setup" — link to `agent-configs/README.md`, explain how to paste templates into `.codex/config.toml`
       - "## Skills" — list all 15 skills with one-line description and `$skill-name` invocation
       - "## Execution Loop" — explain hook-driven vs manual fallback
       - "## Migration from platforms/codex/" — step-by-step migration guide: (1) note old skill paths, (2) install new plugin, (3) old `platforms/codex/skills/` directory will be removed, (4) update any personal scripts that referenced old paths
       - "## Plugin Structure" — directory tree
       - "## Requirements" — `[features] codex_hooks = true` note for hook-driven loop; Windows exclusion
    3. Plugin structure must match `plugins/codex/README.md` (AC-1.5)
  - **Files**: `plugins/codex/README.md`
  - **Done when**: File exists; has "## Installation", "## Migration", "## Skills" sections; lists all 15 skill names
  - **Verify**: `grep -q "## Installation" plugins/codex/README.md && grep -q "## Migration" plugins/codex/README.md && grep -q "ralph-specum-implement" plugins/codex/README.md && echo PASS`
  - **Commit**: `feat(codex-plugin): write README with installation and migration guide`
  - _Requirements: AC-1.5, AC-8.5, US-13 (migration guide)_

- [x] 1.37 [VERIFY] POC Checkpoint: full plugin structure verification
  - **Do**:
    1. Verify plugin.json is valid JSON with required fields
    2. Count SKILL.md files (must be 15)
    3. Count agent template files (must be 9)
    4. Count template files (must be 10)
    5. Count reference files (must be 4)
    6. Count Python scripts (must be 3)
    7. Verify hook is executable
    8. Verify marketplace.json has entry
    9. Verify README exists
  - **Verify**: `jq -e '.version == "4.9.1"' plugins/codex/.codex-plugin/plugin.json > /dev/null && find plugins/codex/skills -name 'SKILL.md' | wc -l | grep -q 15 && ls plugins/codex/agent-configs/*.toml.template | wc -l | grep -q 9 && ls plugins/codex/templates/*.md | wc -l | grep -q 10 && ls plugins/codex/references/*.md | wc -l | grep -q 4 && ls plugins/codex/scripts/*.py | wc -l | grep -q 3 && [ -x plugins/codex/hooks/stop-watcher.sh ] && jq -e '.[0].name == "ralph-specum"' .agents/plugins/marketplace.json > /dev/null && [ -f plugins/codex/README.md ] && echo POC_COMPLETE`
  - **Done when**: All checks pass, `POC_COMPLETE` printed
  - **Commit**: `feat(codex-plugin): complete POC - full plugin structure in place`
  - _Requirements: AC-1.1, AC-1.3, AC-3.1, AC-5.1, AC-5.2, AC-5.3, AC-6.1, AC-8.1, AC-10.1_

---

## Phase 2: Refactor

Focus: Clean up POC shortcuts, verify content quality, consolidate.

- [x] 2.1 Audit skill word counts and trim any over-2000-word files
  - **Do**:
    1. For each of the 15 SKILL.md files, count words with `wc -w`
    2. For any file exceeding 2000 words, trim: remove verbose explanations, use bullet points, move extended examples to referenced files
  - **Files**: Any `plugins/codex/skills/*/SKILL.md` that exceed 2000 words
  - **Done when**: All 15 SKILL.md files are under 2000 words
  - **Verify**: `for f in $(find plugins/codex/skills -name 'SKILL.md'); do words=$(wc -w < "$f"); [ "$words" -lt 2000 ] || { echo "OVER 2000: $f ($words words)"; exit 1; }; done && echo PASS`
  - **Commit**: `refactor(codex-plugin): trim skills to under 2000 words`
  - _Requirements: AC-3.4, NFR-1_

- [x] 2.2 Audit parity matrix for completeness
  - **Do**:
    1. Read `plugins/codex/references/parity-matrix.md`
    2. Verify "Version Delta (v4.8.4 -> v4.9.1)" section documents all 5 known changes: epic.md, tasks.md expansion, settings-template.md expansion, 3 new agent configs, workflow.md additions
    3. Add any missing delta items
    4. Add a "Feature Parity Table" section if not present mapping each Claude command to its Codex skill equivalent
  - **Files**: `plugins/codex/references/parity-matrix.md`
  - **Done when**: Delta section has all 5 items; feature parity table present
  - **Verify**: `grep -q "epic.md" plugins/codex/references/parity-matrix.md && grep -q "settings-template.md" plugins/codex/references/parity-matrix.md && echo PASS`
  - **Commit**: `refactor(codex-plugin): complete parity matrix with full delta and feature table`
  - _Requirements: AC-3.5, AC-4.1_

- [x] 2.3 [VERIFY] Quality checkpoint: parity matrix complete
  - **Do**: Verify parity matrix has required sections
  - **Verify**: `grep -q "Version Delta" plugins/codex/references/parity-matrix.md && grep -q "Feature Parity" plugins/codex/references/parity-matrix.md && echo PASS`
  - **Done when**: Both sections present
  - **Commit**: none

- [x] 2.4 Remove any remaining platforms/codex path references from plugin files
  - **Do**:
    1. Search all files under `plugins/codex/` for any remaining `platforms/codex` substring
    2. Replace each with the correct `plugins/codex` equivalent
  - **Files**: Any plugin files containing stale path refs
  - **Done when**: Zero `platforms/codex` occurrences in `plugins/codex/`
  - **Verify**: `! grep -r 'platforms/codex' plugins/codex/ && echo PASS`
  - **Commit**: `refactor(codex-plugin): remove all platforms/codex path references`
  - _Requirements: AC-1.3_

- [x] 2.5 Verify Python scripts still work with new paths
  - **Do**:
    1. Run `python3 plugins/codex/scripts/count_tasks.py --help 2>&1 || true` and verify no import errors
    2. Run `python3 plugins/codex/scripts/merge_state.py --help 2>&1 || true` and verify no import errors
    3. Run `python3 plugins/codex/scripts/resolve_spec_paths.py --help 2>&1 || true` and verify no syntax errors
  - **Files**: `plugins/codex/scripts/*.py`
  - **Done when**: All 3 scripts parse without Python syntax errors
  - **Verify**: `python3 -m py_compile plugins/codex/scripts/count_tasks.py && python3 -m py_compile plugins/codex/scripts/merge_state.py && python3 -m py_compile plugins/codex/scripts/resolve_spec_paths.py && echo PASS`
  - **Commit**: `refactor(codex-plugin): verify python scripts compile cleanly`
  - _Requirements: AC-5.4_

- [x] 2.6 [VERIFY] Quality checkpoint: no stale refs, scripts valid
  - **Do**: Final cleanup check
  - **Verify**: `! grep -r 'platforms/codex' plugins/codex/ && python3 -m py_compile plugins/codex/scripts/resolve_spec_paths.py && echo PASS`
  - **Done when**: No stale refs, scripts compile
  - **Commit**: none

---

## Phase 3: Testing

Focus: BATS tests for new plugin, version-sync helper, update old tests, CI config.

- [x] 3.1 Create tests/helpers/version-sync.sh
  - **Do**:
    1. Create `tests/helpers/version-sync.sh`
    2. Script compares 3 version fields: Claude plugin (`plugins/ralph-specum/.claude-plugin/plugin.json`), Codex plugin (`plugins/codex/.codex-plugin/plugin.json`), marketplace (`.agents/plugins/marketplace.json` entry for `ralph-specum`)
    3. If any mismatch: print `VERSION MISMATCH: claude=X codex=Y marketplace=Z` and `exit 1`
    4. If all match: print `VERSION SYNC OK: X` and `exit 0`
    5. Make executable: `chmod +x tests/helpers/version-sync.sh`
  - **Files**: `tests/helpers/version-sync.sh`
  - **Done when**: Script exists, is executable, exits 0 when versions match
  - **Verify**: `bash tests/helpers/version-sync.sh && echo PASS`
  - **Commit**: `test(codex-plugin): add version-sync.sh helper`
  - _Requirements: AC-2.2, AC-12.1, AC-12.2_

- [x] 3.2 [VERIFY] Quality checkpoint: version-sync passes for current versions
  - **Do**: Run version-sync helper
  - **Verify**: `bash tests/helpers/version-sync.sh && echo PASS`
  - **Done when**: Exits 0 (all 3 version fields match `4.9.1`)
  - **Commit**: none

- [x] 3.3 Create tests/codex-plugin.bats (plugin structure tests)
  - **Do**:
    1. Create `tests/codex-plugin.bats`
    2. Add `repo_root()` helper (same pattern as `codex-platform.bats`)
    3. Write the following BATS tests:
       - `@test "codex plugin: plugin.json exists and is valid JSON"` — `jq . "$root/plugins/codex/.codex-plugin/plugin.json" > /dev/null`
       - `@test "codex plugin: plugin.json has required fields name version description"` — jq assertions
       - `@test "codex plugin: plugin.json version matches 4.9.1"` — exact version check
       - `@test "codex plugin: plugin.json version matches claude plugin version"` — compare both plugin.json files
       - `@test "codex plugin: all 15 SKILL.md files exist"` — loop over known skill list
       - `@test "codex plugin: each SKILL.md has description and instructions sections"` — grep for `## Description` and `## Instructions` in each
       - `@test "codex plugin: no SKILL.md exceeds 2000 words"` — `wc -w` check
       - `@test "codex plugin: all 9 agent-config templates exist"` — loop over known template names
       - `@test "codex plugin: spec-executor template contains TASK_COMPLETE"` — grep check
       - `@test "codex plugin: all 10 templates exist"` — loop over known template filenames
       - `@test "codex plugin: epic.md template exists"` — specific check for the previously missing template
       - `@test "codex plugin: all 4 references exist"` — loop
       - `@test "codex plugin: spec.schema.json exists"` — file check
       - `@test "codex plugin: all 3 python scripts exist"` — loop
       - `@test "codex plugin: stop-watcher.sh is executable"` — `-x` check
       - `@test "codex plugin: marketplace.json contains ralph-specum entry"` — jq check
       - `@test "codex plugin: marketplace version matches plugin.json version"` — compare versions
       - `@test "codex plugin: version sync passes"` — run `tests/helpers/version-sync.sh`
       - `@test "codex plugin: no platforms/codex references in plugin files"` — `! grep -r platforms/codex plugins/codex/`
  - **Files**: `tests/codex-plugin.bats`
  - **Done when**: File exists; all tests pass with `bats tests/codex-plugin.bats`
  - **Verify**: `bats tests/codex-plugin.bats`
  - **Commit**: `test(codex-plugin): add codex-plugin.bats structure tests`
  - _Requirements: AC-11.1, AC-11.2, AC-11.3, AC-11.4, AC-11.5_

- [x] 3.4 [VERIFY] Quality checkpoint: new BATS tests pass
  - **Do**: Run new test file
  - **Verify**: `bats tests/codex-plugin.bats && echo PASS`
  - **Done when**: All tests green, zero failures
  - **Commit**: none

- [x] 3.5 Update tests/codex-platform.bats paths for new plugin location
  - **Do**:
    1. Read `tests/codex-platform.bats` in full
    2. Replace all `platforms/codex/skills/` path references with `plugins/codex/skills/` (the test file currently checks `platforms/codex/skills/<skill>/SKILL.md` and `agents/openai.yaml`)
    3. Note: the new plugin does NOT use `agents/openai.yaml` files — after migration the test structure will change. For now, update only path strings; flag any tests that reference `agents/openai.yaml` with a TODO comment since those tests will fail after platforms/codex is deleted (they will be rewritten in task 3.6)
  - **Files**: `tests/codex-platform.bats`
  - **Done when**: No remaining `platforms/codex/skills/` strings in file; updated paths point to `plugins/codex/`
  - **Verify**: `! grep -q 'platforms/codex/skills/' tests/codex-platform.bats && echo PASS`
  - **Commit**: `test(codex-plugin): update codex-platform.bats paths to new plugin location`
  - _Requirements: AC-13.1_

- [x] 3.6 Rewrite codex-platform.bats tests for new plugin structure
  - **Do**:
    1. The old tests check for `agents/openai.yaml` which the new plugin does not use (skills use SKILL.md only, no yaml metadata file)
    2. Rewrite tests that reference `openai.yaml` to instead verify the new plugin structure: check for `SKILL.md` existence and basic content tokens
    3. Update `all_codex_skills()` helper to match the 15-skill list (verify it is already correct)
    4. Remove or skip `codex platform: skill frontmatter passes quick validation when available` if it relies on `agents/openai.yaml` format
    5. Rewrite `codex platform: docs describe the packaged distribution` test to check `plugins/codex/README.md` instead of `platforms/codex/README.md` — verify the new README has installation and migration sections
  - **Files**: `tests/codex-platform.bats`
  - **Done when**: All tests in file pass with `bats tests/codex-platform.bats`; no references to `agents/openai.yaml` for the new plugin
  - **Verify**: `bats tests/codex-platform.bats && echo PASS`
  - **Commit**: `test(codex-plugin): rewrite codex-platform.bats for new plugin structure`
  - _Requirements: AC-13.2, AC-13.3_

- [x] 3.7 [VERIFY] Quality checkpoint: both test files pass
  - **Do**: Run both BATS test files
  - **Verify**: `bats tests/codex-plugin.bats tests/codex-platform.bats && echo PASS`
  - **Done when**: All tests pass
  - **Commit**: none

- [x] 3.8 Update tests/codex-platform-scripts.bats paths
  - **Do**:
    1. Replace all `platforms/codex/skills/ralph-specum/scripts/` references with `plugins/codex/scripts/`
    2. Update `merge_state_script()` and `resolve_spec_paths_script()` helper functions to point to new paths
  - **Files**: `tests/codex-platform-scripts.bats`
  - **Done when**: No `platforms/codex` refs in file; `bats tests/codex-platform-scripts.bats` passes
  - **Verify**: `! grep -q 'platforms/codex' tests/codex-platform-scripts.bats && bats tests/codex-platform-scripts.bats && echo PASS`
  - **Commit**: `test(codex-plugin): update codex-platform-scripts.bats to new plugin paths`
  - _Requirements: AC-13.1, AC-13.3_

- [x] 3.9 Update .github/workflows/bats-tests.yml trigger paths
  - **Do**:
    1. Add `plugins/codex/**` to both `push.paths` and `pull_request.paths` in `.github/workflows/bats-tests.yml`
    2. Also add `.agents/plugins/**` to trigger paths (marketplace.json changes should trigger CI)
  - **Files**: `.github/workflows/bats-tests.yml`
  - **Done when**: File contains `plugins/codex/**` in trigger paths
  - **Verify**: `grep -q 'ralph-specum' .github/workflows/bats-tests.yml && echo PASS`
  - **Commit**: `ci: add codex plugin to bats-tests.yml trigger paths`
  - _Requirements: AC-11.5_

- [x] 3.10 Create .github/workflows/codex-version-check.yml
  - **Do**:
    1. Create `.github/workflows/codex-version-check.yml`
    2. Trigger on `push` and `pull_request` with paths: `plugins/ralph-specum*/**`, `.agents/plugins/marketplace.json`
    3. Job: checkout, install jq, run `bash tests/helpers/version-sync.sh`
    4. Job name: "Codex plugin version sync check"
  - **Files**: `.github/workflows/codex-version-check.yml`
  - **Done when**: File exists and is valid YAML; runs `version-sync.sh`
  - **Verify**: `grep -q 'version-sync.sh' .github/workflows/codex-version-check.yml && echo PASS`
  - **Commit**: `ci: add codex-version-check.yml for version parity enforcement`
  - _Requirements: AC-2.2, AC-12.3_

---

## Phase 4: Quality Gates

- [x] V4 [VERIFY] Full test suite passes
  - **Do**:
    1. Run all BATS test files: `bats tests/*.bats`
    2. Fix any remaining failures
  - **Verify**: `bats tests/*.bats && echo ALL_PASS`
  - **Done when**: Zero test failures across all BATS files
  - **Commit**: `fix(codex-plugin): address remaining test failures` (if fixes needed)
  - _Requirements: AC-11.5, AC-13.3_

- [x] V5 [VERIFY] AC checklist verification
  - **Do**: For each acceptance criterion, verify programmatically:
    - AC-1.1: `jq . plugins/codex/.codex-plugin/plugin.json > /dev/null`
    - AC-1.2: `jq -e '.name == "ralph-specum" and .version == "4.9.1"' plugins/codex/.codex-plugin/plugin.json`
    - AC-2.1: `bash tests/helpers/version-sync.sh`
    - AC-3.1: `find plugins/codex/skills -name 'SKILL.md' | wc -l` (must be 15)
    - AC-3.4: word count check on all SKILL.md
    - AC-5.1: `ls plugins/codex/templates/*.md | wc -l` (must be 10)
    - AC-6.1: `ls plugins/codex/agent-configs/*.toml.template | wc -l` (must be 9)
    - AC-6.4: `grep -q 'TASK_COMPLETE' plugins/codex/agent-configs/spec-executor.toml.template`
    - AC-8.1: `[ -f plugins/codex/hooks/stop-watcher.sh ]`
    - AC-10.1: `jq -e '.[0].name == "ralph-specum"' .agents/plugins/marketplace.json`
  - **Verify**: All commands above exit 0
  - **Done when**: All AC checks pass
  - **Commit**: none

- [x] 4.1 Create PR and push feature branch
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push branch: `git push -u origin <branch-name>`
    3. Create PR: title "feat(codex-plugin): create ralph-specum plugin with full v4.9.1 parity", body summarizing: new plugin at `plugins/codex/`, 15 skills, 9 agent templates, stop hook, marketplace entry, BATS tests, CI version-check
  - **Verify**: `gh pr view --json state | jq -r .state | grep -q open && echo PASS`
  - **Done when**: PR open, CI started
  - **Commit**: none (PR creation)

---

## Phase 5: PR Lifecycle and Cleanup

- [x] 5.1 [VERIFY] CI pipeline passes
  - **Do**:
    1. Monitor CI: `gh pr checks --watch`
    2. If any check fails: read failure output, fix locally, push
  - **Verify**: `gh pr checks | grep -v pass | grep -qv fail && echo CI_GREEN || gh pr checks`
  - **Done when**: All CI checks green

- [x] 5.2 [VERIFY] Version sync CI check passes
  - **Do**: Verify the new codex-version-check workflow passes in CI
  - **Verify**: `gh pr checks | grep -q 'version' && echo PASS`
  - **Done when**: Version sync job green

- [x] 5.3 Cleanup commit: delete platforms/codex/ (separate commit)
  - **Do**:
    1. Verify all tests pass first: `bats tests/*.bats`
    2. Remove `platforms/codex/` directory: `git rm -r platforms/codex/`
    3. Update `README.md` at repo root: remove any mention of `platforms/codex/` — replace with reference to `plugins/codex/`
    4. Update `TROUBLESHOOTING.md` if present: same path replacement
    5. Check `CLAUDE.md` at repo root for any `platforms/codex/` mentions; update if found
    6. Commit with message: `chore(cleanup): remove platforms/codex/ after plugin migration`
    7. Verify no remaining references: `! grep -r 'platforms/codex' . --exclude-dir=.git --exclude-dir=specs`
  - **Files**: `platforms/codex/` (deleted), `README.md`, `TROUBLESHOOTING.md`, `CLAUDE.md`
  - **Done when**: `platforms/codex/` gone; no remaining refs in codebase
  - **Verify**: `[ ! -d platforms/codex ] && ! grep -r 'platforms/codex' . --exclude-dir=.git --exclude-dir=specs && echo PASS`
  - **Commit**: `chore(cleanup): remove platforms/codex/ after plugin migration`
  - _Requirements: AC-14.1, AC-14.2, AC-14.3, AC-14.4_

- [x] 5.4 [VERIFY] Post-cleanup test suite passes
  - **Do**: Run full test suite after platforms/codex deletion to confirm no dead references
  - **Verify**: `bats tests/*.bats && echo PASS`
  - **Done when**: All tests pass with no `platforms/codex` references active

- [x] 5.5 [VERIFY] Final AC checklist post-cleanup
  - **Do**:
    1. Confirm `platforms/codex/` is absent: `[ ! -d platforms/codex ]`
    2. Confirm no test references old path: `! grep -r 'platforms/codex' tests/`
    3. Run version sync: `bash tests/helpers/version-sync.sh`
    4. Run plugin structure tests: `bats tests/codex-plugin.bats`
  - **Verify**: All 4 commands exit 0
  - **Done when**: Full cleanup confirmed, AC-14.1 through AC-14.4 satisfied
  - **Commit**: none

---

## Notes

**POC shortcuts taken**:
- Agent TOML template field name for system prompt left as comment block (not `developer_instructions`) pending Codex TOML spec confirmation — noted in `agent-configs/README.md`
- Stop hook path resolution uses simple `specs/.current-spec` lookup before calling Python scripts (avoids Python dependency in hook)
- SKILL.md content adapted from `platforms/codex/` directly; full behavioral diff documented in parity-matrix.md rather than deep audit per skill

**Production TODOs** (would be addressed in a follow-up spec):
- Confirm exact TOML `developer_instructions` field name from Codex docs and update all 9 templates
- Add `$plugin-creator` scaffolding automation notes to README if Codex publishes a stable API for it
- E2E verification: manual install test in a real Codex environment

**Key constraints**:
- Cleanup (platforms/codex/ deletion) MUST be a separate commit from plugin creation (per AC-14.3 and requirements interview)
- marketplace.json did not exist — task 1.2 creates it as a new file (not an append)
- `agents/openai.yaml` files used by `platforms/codex/` are NOT part of the new plugin structure; codex-platform.bats tests referencing them must be rewritten
