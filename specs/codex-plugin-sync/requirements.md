# Requirements: Codex Plugin Sync

## Goal

Replace the skills-based `platforms/codex/` approach (v4.8.4) with a real Codex plugin at `plugins/ralph-specum-codex/` using the OpenAI Codex plugin API, reaching full feature parity with the Claude ralph-specum plugin (v4.9.1).

---

## User Stories

### Theme 1: Plugin Structure and Manifest

#### US-1: Plugin Directory and Manifest
**As a** Codex user
**I want to** install ralph-specum as a proper Codex plugin
**So that** I get the full skill set without manually copying files

**Acceptance Criteria:**
- [ ] AC-1.1: `plugins/ralph-specum-codex/.codex-plugin/plugin.json` exists and passes Codex plugin schema validation
- [ ] AC-1.2: `plugin.json` declares `name: "ralph-specum-codex"`, `version: "4.9.1"`, and a non-empty `description`
- [ ] AC-1.3: All skills, agents, templates, references, schemas, and scripts live under `plugins/ralph-specum-codex/` (nothing scattered elsewhere)
- [ ] AC-1.4: Only `plugin.json` lives inside `.codex-plugin/`; no other files are placed there
- [ ] AC-1.5: Plugin directory tree matches the structure documented in `plugins/ralph-specum-codex/README.md`

#### US-2: Version Parity
**As a** maintainer
**I want to** keep the Codex plugin version in sync with the Claude plugin version
**So that** users and CI can detect drift immediately

**Acceptance Criteria:**
- [ ] AC-2.1: `plugins/ralph-specum-codex/.codex-plugin/plugin.json` version equals `plugins/ralph-specum/.claude-plugin/plugin.json` version at the time of merge
- [ ] AC-2.2: A CI check (shell script or test file) compares the two version fields and fails if they differ
- [ ] AC-2.3: `CLAUDE.md` version-bump rule applies to `plugins/ralph-specum-codex/.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`

---

### Theme 2: Skill Migration and Content Sync

#### US-3: All 15 Skills Present
**As a** Codex user
**I want to** invoke any Ralph Specum workflow from Codex
**So that** I have the same entry points as Claude Code users

**Acceptance Criteria:**
- [ ] AC-3.1: Plugin contains exactly 15 skills: `ralph-specum-start`, `ralph-specum-research`, `ralph-specum-requirements`, `ralph-specum-design`, `ralph-specum-tasks`, `ralph-specum-implement`, `ralph-specum-cancel`, `ralph-specum-status`, `ralph-specum-switch`, `ralph-specum-triage`, `ralph-specum-refactor`, `ralph-specum-index`, `ralph-specum-feedback`, `ralph-specum-help`, `ralph-specum` (main/bootstrap)
- [ ] AC-3.2: Each skill has a `SKILL.md` under `skills/<skill-name>/SKILL.md` and conforms to the Agent Skills standard (name, description, instructions sections present)
- [ ] AC-3.3: `ralph-specum-start` incorporates the behavior of both `start` and `new` from the Claude plugin (no separate `new` skill required)
- [ ] AC-3.4: Each SKILL.md stays under 2000 words (progressive disclosure: full body loads on demand, not at startup)
- [ ] AC-3.5: All 15 skills from `platforms/codex/skills/` are content-audited against their Claude plugin counterparts, with differences logged in `plugins/ralph-specum-codex/references/parity-matrix.md`

#### US-4: Content Delta Resolved (v4.8.4 -> v4.9.1)
**As a** Codex user
**I want to** access features added in Claude plugin v4.8.5 through v4.9.1
**So that** I don't miss capabilities available to Claude Code users

**Acceptance Criteria:**
- [ ] AC-4.1: A diff between `platforms/codex/` skills and their Claude equivalents is documented in `plugins/ralph-specum-codex/references/parity-matrix.md` under a "Version Delta" section
- [ ] AC-4.2: Every behavioral change identified in the delta is reflected in the corresponding Codex skill body
- [ ] AC-4.3: The `tasks.md` template in the plugin matches the Claude plugin's template in structure (both must include verification layers, failure recovery guidance, and POC-first workflow sections)
- [ ] AC-4.4: `ralph-specum-implement` SKILL.md documents the manual fallback workflow for running the execution loop without Stop hooks

#### US-5: Templates and References Copied
**As a** spec-executor running inside Codex
**I want** all 10 spec templates and reference files available
**So that** generated specs match the Claude plugin format exactly

**Acceptance Criteria:**
- [ ] AC-5.1: Plugin includes all 10 templates: `component-spec.md`, `design.md`, `external-spec.md`, `index-summary.md`, `progress.md`, `requirements.md`, `research.md`, `settings-template.md`, `tasks.md`, plus `epic.md` (missing from platforms/codex, present in Claude plugin)
- [ ] AC-5.2: Plugin includes all reference files: `parity-matrix.md`, `path-resolution.md`, `state-contract.md`, `workflow.md`
- [ ] AC-5.3: Plugin includes the JSON schema from the Claude plugin (`schemas/` directory)
- [ ] AC-5.4: Scripts (`count_tasks.py`, `merge_state.py`, `resolve_spec_paths.py`) are copied and verified to still work with the new plugin root paths

---

### Theme 3: Custom Agent TOML Definitions

#### US-6: All 9 Agents Defined as TOML
**As a** Codex skill
**I want to** delegate work to specialized sub-agents
**So that** each phase has the same domain focus as the Claude plugin agents

**Acceptance Criteria:**
- [ ] AC-6.1: Plugin contains TOML agent definitions for all 9 agents under `.codex/agents/` or `agents/` (per Codex TOML agent convention): `ralph-specum:research-analyst`, `ralph-specum:product-manager`, `ralph-specum:architect-reviewer`, `ralph-specum:task-planner`, `ralph-specum:spec-executor`, `ralph-specum:spec-reviewer`, `ralph-specum:qa-engineer`, `ralph-specum:refactor-specialist`, `ralph-specum:triage-analyst`
- [ ] AC-6.2: Each TOML file declares at minimum: `name`, `description`, and `system_prompt` (or equivalent field per Codex TOML spec)
- [ ] AC-6.3: System prompts for `ralph-specum:spec-reviewer`, `ralph-specum:qa-engineer`, and `ralph-specum:refactor-specialist` are authored from scratch (no existing Claude markdown agent to copy from); they must cover the same responsibilities documented in the Claude plugin's task-planner agent
- [ ] AC-6.4: `ralph-specum:spec-executor` TOML includes the Task Completion Protocol (`TASK_COMPLETE` / `ALL_TASKS_COMPLETE` output signals) in its system prompt
- [ ] AC-6.5: Agent nesting depth does not exceed 1 (Codex limit); skills that previously used nested delegation restructure to sequential calls

#### US-7: Agent Invocation from Skills
**As a** skill
**I want to** spawn the correct agent for each phase
**So that** phase responsibilities stay separated, matching the Claude plugin behavior

**Acceptance Criteria:**
- [ ] AC-7.1: `ralph-specum-research` skill spawns `ralph-specum:research-analyst`
- [ ] AC-7.2: `ralph-specum-requirements` skill spawns `ralph-specum:product-manager`
- [ ] AC-7.3: `ralph-specum-design` skill spawns `ralph-specum:architect-reviewer`
- [ ] AC-7.4: `ralph-specum-tasks` skill spawns `ralph-specum:task-planner`
- [ ] AC-7.5: `ralph-specum-implement` skill spawns `ralph-specum:spec-executor` per task iteration
- [ ] AC-7.6: `ralph-specum-triage` skill spawns `ralph-specum:triage-analyst`

---

### Theme 4: Hook Configuration (Stop Hook and Fallback)

#### US-8: Stop Hook for Execution Loop
**As a** Codex user running `$ralph-specum-implement`
**I want** the execution loop to continue automatically after each task
**So that** I don't have to manually re-invoke the skill for every task

**Acceptance Criteria:**
- [ ] AC-8.1: Plugin defines a Stop hook script at `hooks/stop-watcher.sh` (or equivalent) that reads `.ralph-state.json` and outputs a continuation prompt when tasks remain
- [ ] AC-8.2: Stop hook uses `decision: "block"` + `reason` to pause and surface the continuation prompt (per Codex experimental hook API)
- [ ] AC-8.3: Stop hook outputs `ALL_TASKS_COMPLETE` and exits cleanly when `taskIndex >= totalTasks`
- [ ] AC-8.4: Stop hook is declared in `plugin.json` under the hooks section (exact field name per Codex plugin spec)
- [ ] AC-8.5: A `[features] codex_hooks = true` requirement is documented in the plugin's README and in `ralph-specum-implement` SKILL.md

#### US-9: Manual Fallback Workflow
**As a** Codex user whose environment has Stop hooks disabled (Windows, or feature flag off)
**I want** clear instructions to run the loop manually
**So that** I can still complete multi-task specs without the hook

**Acceptance Criteria:**
- [ ] AC-9.1: `ralph-specum-implement` SKILL.md contains a "Manual Loop" section that shows exact re-invocation steps
- [ ] AC-9.2: Manual fallback instructions reference `.ralph-state.json` fields (`taskIndex`, `totalTasks`, `phase`) so users can monitor progress
- [ ] AC-9.3: `ralph-specum-status` skill outputs hook availability (reads whether Stop hook is active) and shows fallback instructions if unavailable
- [ ] AC-9.4: `plugins/ralph-specum-codex/references/workflow.md` documents both the hook-driven and manual execution paths

---

### Theme 5: Marketplace Distribution

#### US-10: Marketplace Entry
**As a** repo maintainer
**I want** the Codex plugin listed in the marketplace
**So that** teams can install it via standard Codex install flows

**Acceptance Criteria:**
- [ ] AC-10.1: `.agents/plugins/marketplace.json` contains an entry for `ralph-specum-codex` with `name`, `description`, `version`, and `path` fields
- [ ] AC-10.2: Install policy is set to `AVAILABLE` (not `INSTALLED_BY_DEFAULT`, not `NOT_AVAILABLE`)
- [ ] AC-10.3: Marketplace `version` field matches `plugin.json` version
- [ ] AC-10.4: A CI check verifies that marketplace version equals plugin.json version (can be same script as AC-2.2)

---

### Theme 6: Testing and CI

#### US-11: Plugin Structure Tests
**As a** CI pipeline
**I want** automated checks that the plugin is structurally valid
**So that** malformed plugins don't reach users

**Acceptance Criteria:**
- [ ] AC-11.1: A test file (shell or existing test framework) verifies all 15 SKILL.md files exist at expected paths
- [ ] AC-11.2: A test verifies all 9 TOML agent files exist at expected paths
- [ ] AC-11.3: A test verifies all 10 templates exist at expected paths
- [ ] AC-11.4: A test verifies `plugin.json` is valid JSON and contains required fields (`name`, `version`, `description`)
- [ ] AC-11.5: All structure tests run in CI (added to existing test suite invocation)

#### US-12: Version Sync Tests
**As a** CI pipeline
**I want** version drift between Claude and Codex plugins to fail the build
**So that** version gaps like v4.8.4 vs v4.9.1 are caught before merge

**Acceptance Criteria:**
- [ ] AC-12.1: CI script compares `plugins/ralph-specum/.claude-plugin/plugin.json` version with `plugins/ralph-specum-codex/.codex-plugin/plugin.json` version and exits non-zero if they differ
- [ ] AC-12.2: CI script compares `plugins/ralph-specum-codex/.codex-plugin/plugin.json` version with `.agents/plugins/marketplace.json` entry version and exits non-zero if they differ
- [ ] AC-12.3: Both checks run on every PR touching `plugins/ralph-specum*/` or `marketplace.json`

#### US-13: Existing Codex Tests Updated
**As a** test suite
**I want** all old `platforms/codex/` path references replaced with `plugins/ralph-specum-codex/`
**So that** tests pass after the migration and no dead paths remain

**Acceptance Criteria:**
- [ ] AC-13.1: All test files referencing `platforms/codex/` are updated to `plugins/ralph-specum-codex/`
- [ ] AC-13.2: No test file references `platforms/codex/` after migration (verified by grep in CI)
- [ ] AC-13.3: Full test suite passes after update

---

### Theme 7: Cleanup and Migration

#### US-14: Remove platforms/codex/
**As a** maintainer
**I want** `platforms/codex/` deleted after the plugin is verified
**So that** there is one canonical Codex implementation with no confusion about which files are current

**Acceptance Criteria:**
- [ ] AC-14.1: `platforms/codex/` directory is fully removed from the repository
- [ ] AC-14.2: No import, reference, or path in any remaining file points to `platforms/codex/`
- [ ] AC-14.3: Removal happens in a dedicated commit after all tests pass (not bundled with plugin creation)
- [ ] AC-14.4: `CLAUDE.md` or `README.md` at repo root updated to remove any mention of `platforms/codex/`

---

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Plugin manifest at `.codex-plugin/plugin.json` declares name, version (4.9.1), description | High | AC-1.1, AC-1.2 |
| FR-2 | 15 skills present with SKILL.md under 2000 words each | High | AC-3.1, AC-3.2, AC-3.4 |
| FR-3 | `ralph-specum-start` merges start+new behavior | High | AC-3.3 |
| FR-4 | Content delta v4.8.4->4.9.1 documented and applied to all affected skills | High | AC-4.1, AC-4.2 |
| FR-5 | `tasks.md` template includes verification layers, failure recovery, POC-first sections | High | AC-4.3 |
| FR-6 | `epic.md` template added (missing from platforms/codex) | High | AC-5.1 |
| FR-7 | 9 TOML agent files with name, description, system_prompt | High | AC-6.1, AC-6.2 |
| FR-8 | 3 new agents authored (spec-reviewer, qa-engineer, refactor-specialist) | High | AC-6.3 |
| FR-9 | spec-executor TOML includes TASK_COMPLETE/ALL_TASKS_COMPLETE protocol | High | AC-6.4 |
| FR-10 | Stop hook reads state and emits continuation prompt or ALL_TASKS_COMPLETE | High | AC-8.1, AC-8.2, AC-8.3 |
| FR-11 | Manual loop fallback documented in implement SKILL.md | Medium | AC-9.1, AC-9.2 |
| FR-12 | Marketplace entry in `.agents/plugins/marketplace.json` | High | AC-10.1, AC-10.2 |
| FR-13 | CI version-sync checks for both plugin pairs | High | AC-12.1, AC-12.2 |
| FR-14 | `platforms/codex/` removed after verification | High | AC-14.1, AC-14.2 |
| FR-15 | All old test references updated to new plugin path | High | AC-13.1, AC-13.2 |

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | SKILL.md size | Word count per file | Under 2000 words (progressive disclosure) |
| NFR-2 | Agent nesting | Max spawn depth | 1 (Codex platform limit) |
| NFR-3 | Concurrent agent threads | Max parallel spawns | 6 (Codex platform limit) |
| NFR-4 | Stop hook reliability | Platform support | Documented as experimental; Windows exclusion noted |
| NFR-5 | Template fidelity | Field coverage vs Claude plugin | 100% of Claude template sections present in Codex templates |
| NFR-6 | CI runtime | Version-sync check duration | Under 5 seconds |
| NFR-7 | Plugin install size | Total file count | No binaries; text files only |

---

## Glossary

- **Agent Skills standard**: Cross-platform format (agentskills.io) for SKILL.md files, compatible with Codex, Claude Code, Gemini CLI, Cursor
- **TOML agent**: Codex-native agent definition file using TOML syntax, placed under `.codex/agents/`
- **Stop hook**: Experimental Codex hook (`[features] codex_hooks = true`) that fires after each agent turn; uses `decision: "block"` + `reason` to pause and continue the execution loop
- **`$skill-name` invocation**: Codex equivalent of Claude Code's `/plugin:command`; dollar-sign prefix triggers a named skill
- **Marketplace**: `.agents/plugins/marketplace.json` at repo root; install policy `AVAILABLE` means user can install but it is not auto-installed
- **Progressive disclosure**: Skills load name+description at startup (level 1); full SKILL.md body loads on first invocation (level 2); referenced files load on demand (level 3)
- **Parity matrix**: Reference document tracking feature mapping between Claude and Codex plugin implementations
- **platforms/codex/**: Legacy directory (v4.8.4 skills-based approach); will be removed after the plugin is verified
- **POC-first workflow**: Task execution strategy: Phase 1 (make it work), Phase 2 (refactor), Phase 3 (test), Phase 4 (quality gates)
- **TASK_COMPLETE / ALL_TASKS_COMPLETE**: Output signals from spec-executor and coordinator that drive the execution loop

---

## Out of Scope

- Gemini CLI or Cursor plugin variants (separate effort)
- MCP server integration (no MCP servers needed for this plugin per research)
- Automated E2E testing (no test runner available; verification is manual install + invocation)
- Changes to the Claude ralph-specum plugin files (read-only reference)
- Worktree management UI inside Codex (stays conversational per parity matrix)
- `$plugin-creator` scaffolding automation (informational; actual files written manually)

---

## Dependencies

- Codex Stop hook feature flag (`[features] codex_hooks = true`) must be enabled in the target environment for the automatic execution loop; without it, only the manual fallback works
- Codex TOML agent spec must support `name`, `description`, `system_prompt` fields (or equivalent); implementation must confirm field names against live Codex docs before authoring all 9 files
- `.agents/plugins/marketplace.json` must already exist (it does per research); no new file creation needed, only an append
- Claude plugin v4.9.1 files are the authoritative source for content sync; any future Claude plugin changes after this spec is locked require a new sync spec

---

## Unresolved Questions

- **TOML agent field names**: Research identified `.codex/agents/` as the location and TOML as the format, but did not confirm exact field names (`system_prompt` vs `instructions` vs another key). Implementation must fetch live Codex TOML agent docs before authoring agent files.
- **Stop hook declaration syntax**: Exact `plugin.json` field for declaring the Stop hook path is not confirmed. Must verify against Codex plugin API docs before implementing AC-8.4.
- **Max concurrent agent threads**: Research cites 6 concurrent threads as the Codex limit. Confirm this applies to plugin-spawned agents (not just user-initiated sessions) before designing parallel task batching.
- **Marketplace install policy**: `AVAILABLE` is assumed correct (opt-in, not auto-install). Confirm the policy does not require an additional approval step in the marketplace before the plugin appears to users.
- **`spec-reviewer`, `qa-engineer`, `refactor-specialist` scope**: These three agents are net-new with no existing markdown source. Their system prompts must be derived from task-planner agent references and Claude plugin phase descriptions. A separate review of the Claude plugin task-planner and the tasks.md template is needed before authoring.

---

## Next Steps

1. Resolve unresolved questions (TOML field names, Stop hook declaration syntax) by fetching Codex plugin API docs
2. Author `plugins/ralph-specum-codex/` directory structure (plugin.json, skills, agents, templates, hooks)
3. Run content diff between each `platforms/codex/` skill and its Claude counterpart; document delta in parity-matrix.md
4. Author the 3 net-new agent TOML files (spec-reviewer, qa-engineer, refactor-specialist)
5. Write CI version-sync check script
6. Verify plugin installs and skills invoke correctly in a Codex environment
7. Remove `platforms/codex/` and update all test references
