# Tasks: epic-triage

## Phase 1: Make It Work

- [x] 1.1 Add epic state schema definition
  - **Do**: 1. Add `epicState` definition to `plugins/ralph-specum/schemas/spec.schema.json` after the `state` definition (line 185) and before `task` definition (line 187). 2. Add `epicName` property inside `state.properties` object. 3. Verify valid JSON with `jq empty`.
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema file contains `epicState` definition and `epicName` property, and passes `jq empty` validation
  - **Verify**: `jq '.definitions.epicState.required' plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties.epicName' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `feat(ralph-specum): add epicState schema and epicName field`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 1_

- [x] 1.2 Create epic.md template
  - **Do**: 1. Create `plugins/ralph-specum/templates/epic.md` with frontmatter (epic, created placeholders) and sections: Vision, Success Criteria, Specs (with per-spec Goal/AC/MVP Scope/Dependencies/Interface Contracts/Architecture/Size), Dependency Graph, Notes. 2. Use `{{PLACEHOLDER}}` syntax matching existing templates.
  - **Files**: `plugins/ralph-specum/templates/epic.md`
  - **Done when**: Template file exists with all required sections and placeholder syntax
  - **Verify**: `test -f plugins/ralph-specum/templates/epic.md && grep -c '{{' plugins/ralph-specum/templates/epic.md`
  - **Commit**: `feat(ralph-specum): add epic.md template for triage output`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 2_

- [x] 1.3 Create triage-analyst agent
  - **Do**: 1. Create `plugins/ralph-specum/agents/triage-analyst.md` with YAML frontmatter (name, description, model: inherit, color: orange). 2. Define role as senior engineering manager/product strategist. 3. Include rules for vertical-slice decomposition, interface contracts, and spec independence. 4. Define process: Understand, Map User Journeys, Propose Decomposition, Refine with User. 5. Output epic.md. 6. Include mandatory learnings append and communication style sections.
  - **Files**: `plugins/ralph-specum/agents/triage-analyst.md`
  - **Done when**: Agent file exists with valid frontmatter, role definition, process steps, and mandatory sections
  - **Verify**: `head -6 plugins/ralph-specum/agents/triage-analyst.md | grep -c 'name:\|description:\|model:\|color:'`
  - **Commit**: `feat(ralph-specum): add triage-analyst agent for epic decomposition`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 3_

- [x] 1.4 Create triage-flow reference
  - **Do**: 1. Create `plugins/ralph-specum/references/triage-flow.md` with "Used by: triage.md" header. 2. Define 4-step flow: Exploration Research (triage-focused parallel-research), Brainstorming & Decomposition (triage-analyst delegation), Validation Research (single research-analyst validation), Finalize (adjustment rounds, output selection, state init). 3. Include research prompt customizations, output handlers (spec files, GitHub issues, both), and epic status display format.
  - **Files**: `plugins/ralph-specum/references/triage-flow.md`
  - **Done when**: Reference file exists with all 4 steps, research prompts, output handlers, and status display format
  - **Verify**: `test -f plugins/ralph-specum/references/triage-flow.md && grep -c '## Step' plugins/ralph-specum/references/triage-flow.md`
  - **Commit**: `feat(ralph-specum): add triage-flow reference for explore-brainstorm-validate-finalize`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 4_

- [x] 1.5 Create triage.md command
  - **Do**: 1. Create `plugins/ralph-specum/commands/triage.md` with frontmatter (description, argument-hint: [epic-name] [goal], allowed-tools: "*"). 2. Checklist: check active epic, handle branch, parse input, run triage flow, display result. 3. Step 1: detect `.current-epic`, show status if exists, offer continue/new/view. 4. Step 2: branch management via reference. 5. Step 3: parse epic-name and goal from args, create `specs/_epics/$EPIC_NAME/` dir, init `.progress.md`. 6. Step 4: delegate to triage-flow reference. 7. Step 5: mandatory walkthrough with epic summary. 8. Include coordinator delegation requirement and stop-after-subagent mandatory blocks.
  - **Files**: `plugins/ralph-specum/commands/triage.md`
  - **Done when**: Command file exists with valid frontmatter, 5-step checklist, delegation requirements, and mandatory walkthrough
  - **Verify**: `head -5 plugins/ralph-specum/commands/triage.md | grep -c 'description:\|argument-hint:\|allowed-tools:'`
  - **Commit**: `feat(ralph-specum): add /triage command for epic decomposition`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 5_

- [x] 1.6 Add epic detection to start.md
  - **Do**: 1. Insert "Step 3.5: Epic Detection" section in `plugins/ralph-specum/commands/start.md` between Step 3 (Scan Existing Specs) and Step 4 (Route to Action). 2. Check for `.current-epic` file, read `.epic-state.json`, find unblocked specs, display brief status, ask user. 3. Add complexity detection: if no active epic and goal appears complex, suggest `/triage`. 4. Add `epicName` to state initialization note in New Flow section. 5. Update gitignore step to include `specs/.current-epic`.
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: start.md contains Step 3.5 with epic detection, epicName state note, and updated gitignore step
  - **Verify**: `grep -c 'Epic Detection\|epicName\|current-epic' plugins/ralph-specum/commands/start.md`
  - **Commit**: `feat(ralph-specum): add epic detection to /start routing`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 6_

- [x] 1.7 Add epic state update to stop-watcher.sh
  - **Do**: 1. In `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`, add epic state update logic inside both ALL_TASKS_COMPLETE detection blocks (before each `exit 0`). 2. Read `epicName` from state file, check for `.current-epic`, update `.epic-state.json` with jq to mark spec as completed. 3. Verify bash syntax.
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Stop-watcher updates epic state on spec completion and passes `bash -n` validation
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -c 'epicName\|epic-state' plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Commit**: `feat(ralph-specum): update epic state on spec completion in stop-watcher`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 7_

## Phase 2: Quality & Documentation

- [x] 2.1 [VERIFY] Verify all new files and modifications
  - **Do**: 1. Check all 4 new files exist (template, agent, reference, command). 2. Validate schema JSON. 3. Validate stop-watcher bash syntax. 4. Verify start.md contains epic detection.
  - **Files**: `plugins/ralph-specum/templates/epic.md`, `plugins/ralph-specum/agents/triage-analyst.md`, `plugins/ralph-specum/references/triage-flow.md`, `plugins/ralph-specum/commands/triage.md`
  - **Done when**: All files exist, schema valid JSON, stop-watcher valid bash, start.md has epic detection
  - **Verify**: `ls plugins/ralph-specum/templates/epic.md plugins/ralph-specum/agents/triage-analyst.md plugins/ralph-specum/references/triage-flow.md plugins/ralph-specum/commands/triage.md && jq empty plugins/ralph-specum/schemas/spec.schema.json && bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`

- [x] 2.2 Update CLAUDE.md documentation
  - **Do**: 1. Add Epics section to Architecture in CLAUDE.md after "State Files" section: file structure, entry points, flow summary. 2. Add `triage-analyst` row to Agents table. 3. Add `.current-epic` and `.epic-state.json` to State Files section. 4. Keep changes surgical - only add epic-related content.
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md contains Epics section, triage-analyst in agents table, and epic state files documented
  - **Verify**: `grep -c 'epic\|triage' CLAUDE.md`
  - **Commit**: `docs: add epic triage documentation to CLAUDE.md`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 10_

- [x] 2.3 Update plugin description and keywords
  - **Do**: 1. Update description in `plugins/ralph-specum/.claude-plugin/plugin.json` to mention epic triage. 2. Add "epic" and "triage" to keywords array. 3. Update description and tags in `.claude-plugin/marketplace.json` similarly.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files mention epic/triage in description and keywords/tags
  - **Verify**: `grep 'epic' plugins/ralph-specum/.claude-plugin/plugin.json && grep 'triage' .claude-plugin/marketplace.json`
  - **Commit**: `docs(ralph-specum): update plugin description and keywords for epic triage`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 11_

- [x] 2.4 Version bump
  - **Do**: 1. Bump version from 4.4.0 to 4.5.0 in `plugins/ralph-specum/.claude-plugin/plugin.json`. 2. Bump version from 4.4.0 to 4.5.0 in `.claude-plugin/marketplace.json` for the ralph-specum entry. 3. Verify both match.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 4.5.0 for ralph-specum
  - **Verify**: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json | grep -c '4.5.0'`
  - **Commit**: `chore(ralph-specum): bump version to 4.5.0 for epic triage feature`
  - _Design: docs/plans/2026-03-03-epic-triage-design.md, Task 9_
