---
spec: opencode-codex-support
phase: tasks
total_tasks: 20
created: 2026-02-15
generated: auto
---

# Tasks: opencode-codex-support

## Phase 1: Make It Work (POC)

Focus: Get SKILL.md portability working end-to-end. Validate that a user can discover and follow the Ralph workflow via SKILL.md files in any tool.

- [x] 1.1 Audit templates and schemas for Claude Code-specific references
  - **Do**:
    1. Read all files in `plugins/ralph-specum/templates/` and `plugins/ralph-specum/schemas/spec.schema.json`
    2. Search for Claude Code-specific references: "Task tool", "AskUserQuestion", "TeamCreate", "SendMessage", "Stop hook", "allowed-tools", "subagent_type", "claude", "plugin.json"
    3. Document any findings in `.progress.md`
    4. If templates/schemas are already tool-agnostic, note "no changes needed"
    5. If changes needed, replace tool-specific references with generic alternatives (e.g., "delegate to subagent" instead of "use Task tool")
  - **Files**: `plugins/ralph-specum/templates/*.md`, `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: All templates and schemas contain zero Claude Code-specific tool references
  - **Verify**: `grep -rn "Task tool\|AskUserQuestion\|TeamCreate\|SendMessage\|Stop hook\|subagent_type\|allowed-tools" plugins/ralph-specum/templates/ plugins/ralph-specum/schemas/ | grep -v "^Binary" | wc -l` returns 0
  - **Commit**: `feat(portability): audit and clean templates for cross-tool compatibility`
  - _Requirements: FR-4, AC-2.1_
  - _Design: Component B_

- [x] 1.2 Create start SKILL.md
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/workflow/start/`
    2. Create `SKILL.md` with progressive disclosure:
       - Level 1: Overview of what start does (detect new vs resume, create spec directory, initialize state)
       - Level 2: Step-by-step instructions (parse name/goal, create directory, write .ralph-state.json, write .progress.md, set .current-spec)
       - Level 3: Advanced options (--quick mode, --fresh, --specs-dir, --commit-spec)
    3. Use tool-agnostic language throughout (no "Task tool", no "AskUserQuestion")
    4. Include state file format documentation inline
    5. Reference spec workflow phases: research -> requirements -> design -> tasks -> implement
  - **Files**: `plugins/ralph-specum/skills/workflow/start/SKILL.md`
  - **Done when**: SKILL.md exists with all 3 disclosure levels, zero Claude Code-specific references
  - **Verify**: `test -f plugins/ralph-specum/skills/workflow/start/SKILL.md && ! grep -q "Task tool\|AskUserQuestion\|TeamCreate\|allowed-tools" plugins/ralph-specum/skills/workflow/start/SKILL.md && echo "PASS"`
  - **Commit**: `feat(skills): add universal start SKILL.md for cross-tool workflow`
  - _Requirements: FR-1, FR-2, AC-1.1, AC-1.2, AC-1.3_
  - _Design: Component A_

- [x] 1.3 Create research SKILL.md
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/workflow/research/`
    2. Create `SKILL.md` with progressive disclosure:
       - Level 1: Purpose of research phase (codebase analysis, external research, feasibility)
       - Level 2: Steps (read goal from .progress.md, explore codebase, search web, write research.md, update state)
       - Level 3: Parallel research notes (tool-specific), output format, research.md template
    3. Tool-agnostic delegation language: "explore codebase" not "use Explore subagent"
  - **Files**: `plugins/ralph-specum/skills/workflow/research/SKILL.md`
  - **Done when**: SKILL.md provides complete research phase guidance
  - **Verify**: `test -f plugins/ralph-specum/skills/workflow/research/SKILL.md && echo "PASS"`
  - **Commit**: `feat(skills): add universal research SKILL.md`
  - _Requirements: FR-1, FR-2, AC-1.1_
  - _Design: Component A_

- [x] 1.4 Create requirements, design, and tasks SKILL.md files
  - **Do**:
    1. Create directories: `plugins/ralph-specum/skills/workflow/requirements/`, `design/`, `tasks/`
    2. Create each SKILL.md with progressive disclosure following the same pattern as research:
       - **requirements/SKILL.md**: User stories, acceptance criteria, FR/NFR tables. Reference requirements.md template.
       - **design/SKILL.md**: Architecture, components, data flow, technical decisions. Reference design.md template.
       - **tasks/SKILL.md**: POC-first 4-phase breakdown, task format (Do/Files/Done when/Verify/Commit). Reference tasks.md template.
    3. All must be tool-agnostic
  - **Files**: `plugins/ralph-specum/skills/workflow/requirements/SKILL.md`, `plugins/ralph-specum/skills/workflow/design/SKILL.md`, `plugins/ralph-specum/skills/workflow/tasks/SKILL.md`
  - **Done when**: All three SKILL.md files exist with full progressive disclosure
  - **Verify**: `for d in requirements design tasks; do test -f "plugins/ralph-specum/skills/workflow/$d/SKILL.md" || echo "MISSING: $d"; done && echo "PASS"`
  - **Commit**: `feat(skills): add requirements, design, and tasks SKILL.md files`
  - _Requirements: FR-1, FR-2, AC-1.1_
  - _Design: Component A_

- [x] 1.5 Create implement SKILL.md (with Codex-compatible task progression)
  - **Do**:
    1. Create directory `plugins/ralph-specum/skills/workflow/implement/`
    2. Create `SKILL.md` with progressive disclosure:
       - Level 1: Purpose of execution (run tasks from tasks.md sequentially)
       - Level 2: Manual task execution loop:
         a. Read .ralph-state.json for taskIndex and totalTasks
         b. Read tasks.md, find task at taskIndex
         c. Execute Do steps, check Done when criteria
         d. Run Verify command
         e. If pass: mark task [x] in tasks.md, update .progress.md, increment taskIndex in state file
         f. If fail: document error, retry or stop
         g. Repeat until taskIndex >= totalTasks
         h. When complete: delete .ralph-state.json, report ALL_TASKS_COMPLETE
       - Level 3: Tool-specific execution modes:
         - Claude Code: Automatic via stop-hook (hands-free)
         - OpenCode: Automatic via JS/TS hooks
         - Codex CLI: Manual re-invocation per task (re-invoke this skill after each task)
    3. Include state file update instructions using jq
    4. This is the most critical SKILL.md -- it enables Codex CLI execution
  - **Files**: `plugins/ralph-specum/skills/workflow/implement/SKILL.md`
  - **Done when**: SKILL.md provides complete execution guidance that works without hooks
  - **Verify**: `test -f plugins/ralph-specum/skills/workflow/implement/SKILL.md && grep -q "taskIndex" plugins/ralph-specum/skills/workflow/implement/SKILL.md && echo "PASS"`
  - **Commit**: `feat(skills): add universal implement SKILL.md with hook-free task progression`
  - _Requirements: FR-1, FR-6, AC-1.1, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Component A, Component E_

- [x] 1.6 Create status and cancel SKILL.md files
  - **Do**:
    1. Create directories: `plugins/ralph-specum/skills/workflow/status/`, `cancel/`
    2. **status/SKILL.md**: Read all spec directories, show phase/progress/files for each. List available commands.
    3. **cancel/SKILL.md**: Delete .ralph-state.json, optionally remove spec directory, clear .current-spec.
    4. Both must be tool-agnostic and reference path resolution patterns
  - **Files**: `plugins/ralph-specum/skills/workflow/status/SKILL.md`, `plugins/ralph-specum/skills/workflow/cancel/SKILL.md`
  - **Done when**: Both SKILL.md files exist with full guidance
  - **Verify**: `test -f plugins/ralph-specum/skills/workflow/status/SKILL.md && test -f plugins/ralph-specum/skills/workflow/cancel/SKILL.md && echo "PASS"`
  - **Commit**: `feat(skills): add status and cancel SKILL.md files`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_

- [ ] 1.7 [VERIFY] POC Checkpoint -- SKILL.md completeness
  - **Do**:
    1. Verify all 8 SKILL.md files exist under `plugins/ralph-specum/skills/workflow/`
    2. Verify zero Claude Code-specific references across all SKILL.md files
    3. Verify each has name and description frontmatter
    4. Verify progressive disclosure (check for "## Overview", "## Steps", or equivalent headers)
    5. Verify templates and schemas are tool-agnostic
  - **Verify**: All commands below must pass:
    - `ls plugins/ralph-specum/skills/workflow/*/SKILL.md | wc -l` returns 8
    - `grep -rl "Task tool\|AskUserQuestion\|TeamCreate\|allowed-tools\|subagent_type" plugins/ralph-specum/skills/workflow/ | wc -l` returns 0
  - **Done when**: All 8 SKILL.md files exist, all tool-agnostic, all have progressive disclosure
  - **Commit**: `chore(qa): verify SKILL.md completeness checkpoint`

## Phase 2: Refactoring

After SKILL.md portability validated, add tool-specific adapters and AGENTS.md generation.

- [x] 2.1 Create AGENTS.md generator
  - **Do**:
    1. Add AGENTS.md generation logic to the plan-synthesizer agent or as a standalone script
    2. The generator reads design.md and extracts:
       - Architecture overview
       - Component responsibilities
       - Technical decisions
       - File structure
       - Existing patterns to follow
    3. Outputs AGENTS.md with sections: Architecture, Coding Conventions, File Structure, Key Decisions
    4. Generation is optional (controlled by `--generate-agents` flag or config)
    5. Place generated AGENTS.md at project root (not inside spec directory)
  - **Files**: `plugins/ralph-specum/scripts/generate-agents-md.sh`
  - **Done when**: Script reads design.md and outputs valid AGENTS.md
  - **Verify**: `bash plugins/ralph-specum/scripts/generate-agents-md.sh --spec-path ./specs/opencode-codex-support && test -f AGENTS.md && echo "PASS"`
  - **Commit**: `feat(agents-md): add AGENTS.md generator from design.md`
  - _Requirements: FR-7, AC-5.1, AC-5.2, AC-5.3_
  - _Design: Component C_

- [x] 2.2 Create OpenCode execution loop adapter
  - **Do**:
    1. Create `adapters/opencode/` directory structure
    2. Create `adapters/opencode/hooks/execution-loop.ts`:
       - Reads .ralph-state.json on `session.idle` or `tool.execute.after` events
       - If phase=execution and taskIndex < totalTasks: output continuation prompt
       - If taskIndex >= totalTasks: signal completion
       - Mirrors stop-watcher.sh logic in TypeScript
    3. Create `adapters/opencode/README.md` with setup instructions:
       - How to register the hook in opencode.json
       - How to configure spec directories
       - Example opencode.json snippet
  - **Files**: `adapters/opencode/hooks/execution-loop.ts`, `adapters/opencode/README.md`
  - **Done when**: TypeScript hook file exists with execution loop logic, README has setup instructions
  - **Verify**: `test -f adapters/opencode/hooks/execution-loop.ts && test -f adapters/opencode/README.md && echo "PASS"`
  - **Commit**: `feat(opencode): add execution loop adapter with JS/TS hooks`
  - _Requirements: FR-5, FR-10, AC-3.1, AC-3.2, AC-3.3, AC-3.4_
  - _Design: Component D_

- [x] 2.3 Create Codex CLI adapter
  - **Do**:
    1. Create `adapters/codex/` directory structure
    2. Create `adapters/codex/skills/ralph-implement/SKILL.md`:
       - Enhanced implement skill specifically for Codex (no hooks)
       - Reads .ralph-state.json and shows current task with full context
       - Provides explicit "after completing this task, re-invoke this skill for the next task"
       - Includes state file update instructions (jq commands for incrementing taskIndex)
    3. Create `adapters/codex/AGENTS.md.template`:
       - Template that can be populated from any spec's design.md
    4. Create `adapters/codex/README.md`:
       - How to set up Ralph skills in Codex CLI
       - How to place SKILL.md files for discovery
       - Workflow walkthrough
  - **Files**: `adapters/codex/skills/ralph-implement/SKILL.md`, `adapters/codex/AGENTS.md.template`, `adapters/codex/README.md`
  - **Done when**: Codex adapter files exist with complete guidance for hook-free execution
  - **Verify**: `test -f adapters/codex/skills/ralph-implement/SKILL.md && test -f adapters/codex/README.md && echo "PASS"`
  - **Commit**: `feat(codex): add Codex CLI adapter with SKILL.md-based execution`
  - _Requirements: FR-6, FR-10, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Component E_

- [ ] 2.4 Create configuration bridge
  - **Do**:
    1. Create `adapters/config/` directory
    2. Create `adapters/config/ralph-config.schema.json`:
       - Defines tool-agnostic Ralph settings (spec_dirs, default_branch, commit_spec, max_iterations)
    3. Create `adapters/config/generate-config.sh`:
       - Reads ralph-config.json from project root
       - Generates Claude Code config (validates existing .claude-plugin/ is compatible)
       - Generates OpenCode config (opencode.json plugin entry, .opencode/ directory)
       - Generates Codex config (copies skills, generates AGENTS.md)
    4. Create `adapters/config/README.md` with usage instructions
  - **Files**: `adapters/config/ralph-config.schema.json`, `adapters/config/generate-config.sh`, `adapters/config/README.md`
  - **Done when**: Config schema defined, generator script creates tool-specific configs
  - **Verify**: `test -f adapters/config/ralph-config.schema.json && test -f adapters/config/generate-config.sh && echo "PASS"`
  - **Commit**: `feat(config): add configuration bridge for multi-tool setup`
  - _Requirements: FR-8, AC-6.1, AC-6.2, AC-6.3, AC-6.4_
  - _Design: Component F_

- [ ] 2.5 [VERIFY] Quality checkpoint -- Adapters and generators
  - **Do**:
    1. Verify all adapter directories exist (opencode, codex, config)
    2. Verify AGENTS.md generator works on existing spec
    3. Verify OpenCode adapter has valid TypeScript
    4. Verify Codex adapter SKILL.md has task progression guidance
    5. Verify existing Claude Code plugin is unchanged (compare against HEAD~N)
  - **Verify**: All commands below must pass:
    - `test -d adapters/opencode && test -d adapters/codex && test -d adapters/config`
    - `git diff HEAD -- plugins/ralph-specum/.claude-plugin/plugin.json plugins/ralph-specum/hooks/ | wc -l` returns 0 (no changes to existing plugin core)
  - **Done when**: All adapters exist, Claude Code plugin unchanged
  - **Commit**: `chore(qa): verify adapters and zero-regression checkpoint`

## Phase 3: Testing

- [ ] 3.1 Test SKILL.md discoverability
  - **Do**:
    1. Create test script `tests/test-skill-discovery.sh`
    2. Test that all 8 SKILL.md files are discoverable:
       - Each has valid YAML frontmatter (name, description)
       - Each has content after frontmatter
       - No broken file references
    3. Test progressive disclosure structure:
       - Each has multiple heading levels (## for sections)
       - Each has Level 1 overview content
    4. Test tool-agnosticism:
       - Zero Claude Code-specific references
  - **Files**: `tests/test-skill-discovery.sh`
  - **Done when**: Test script passes all checks
  - **Verify**: `bash tests/test-skill-discovery.sh`
  - **Commit**: `test(skills): add SKILL.md discoverability tests`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3_

- [ ] 3.2 Test spec artifact portability
  - **Do**:
    1. Create test script `tests/test-artifact-portability.sh`
    2. Test that spec artifacts are tool-agnostic:
       - Templates contain no tool-specific references
       - Schema validates against sample state files
       - .ralph-state.json format is documented in SKILL.md
    3. Test that artifacts from one spec can be read by another tool's adapter:
       - Read a sample .ralph-state.json with the OpenCode adapter logic
       - Read sample tasks.md and verify task parsing
  - **Files**: `tests/test-artifact-portability.sh`
  - **Done when**: Test script validates artifact portability
  - **Verify**: `bash tests/test-artifact-portability.sh`
  - **Commit**: `test(portability): add spec artifact portability tests`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3_

- [ ] 3.3 Test zero regression for Claude Code plugin
  - **Do**:
    1. Create test script `tests/test-claude-code-regression.sh`
    2. Verify plugin.json is unchanged from main branch
    3. Verify hooks.json is unchanged
    4. Verify all existing commands still have correct frontmatter
    5. Verify all existing agents still have correct frontmatter
    6. Verify stop-watcher.sh is unchanged
    7. Compare file checksums against main branch for core plugin files
  - **Files**: `tests/test-claude-code-regression.sh`
  - **Done when**: All regression checks pass
  - **Verify**: `bash tests/test-claude-code-regression.sh`
  - **Commit**: `test(regression): add Claude Code zero-regression test`
  - _Requirements: AC-7.1, AC-7.2, AC-7.3, AC-7.4_

- [ ] 3.4 [VERIFY] Quality checkpoint -- All tests pass
  - **Do**:
    1. Run all test scripts
    2. Verify no test failures
    3. Check for any files accidentally committed to wrong directories
  - **Verify**: `bash tests/test-skill-discovery.sh && bash tests/test-artifact-portability.sh && bash tests/test-claude-code-regression.sh`
  - **Done when**: All test scripts pass with exit code 0
  - **Commit**: `chore(qa): all tests pass checkpoint`

## Phase 4: Quality Gates

- [ ] 4.1 Documentation update
  - **Do**:
    1. Update `README.md` with cross-tool support section:
       - Tool support matrix
       - Quick start for each tool (Claude Code, OpenCode, Codex CLI)
       - Link to adapter READMEs
    2. Update `CLAUDE.md` if needed (architecture section for adapters)
    3. Update `CONTRIBUTING.md` if it exists with cross-tool testing guidance
  - **Files**: `README.md`, `CLAUDE.md`
  - **Done when**: Documentation covers cross-tool setup for all three tools
  - **Verify**: `grep -q "OpenCode" README.md && grep -q "Codex" README.md && echo "PASS"`
  - **Commit**: `docs: add cross-tool support documentation`

- [ ] 4.2 Version bump
  - **Do**:
    1. Bump version in `plugins/ralph-specum/.claude-plugin/plugin.json` (minor version bump, e.g., 3.3.3 -> 3.4.0)
    2. Update version in `.claude-plugin/marketplace.json` if it exists
    3. Add changelog entry for cross-tool support
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Version bumped in both files
  - **Verify**: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Commit**: `chore(release): bump version to 3.4.0 for cross-tool support`

- [ ] 4.3 Local quality check
  - **Do**: Run all quality checks locally
  - **Verify**: All commands must pass:
    - All test scripts pass: `bash tests/test-skill-discovery.sh && bash tests/test-artifact-portability.sh && bash tests/test-claude-code-regression.sh`
    - No uncommitted files: `git status --porcelain | wc -l` returns 0
  - **Done when**: All quality checks pass with no errors
  - **Commit**: `fix(quality): address any remaining issues` (only if fixes needed)

- [ ] 4.4 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR using gh CLI:
       ```bash
       gh pr create --title "feat: add cross-tool support for OpenCode and Codex CLI" --body "## Summary
       Introduces cross-tool support for the Smart Ralph spec-driven workflow.

       ### Changes
       - 8 universal SKILL.md files for portable workflow discovery
       - OpenCode adapter with JS/TS execution loop hooks
       - Codex CLI adapter with SKILL.md-based task progression
       - AGENTS.md generator from design.md
       - Configuration bridge for multi-tool setup
       - Zero regression for existing Claude Code plugin

       ### Tool Support Matrix
       | Feature | Claude Code | OpenCode | Codex CLI |
       |---------|------------|----------|-----------|
       | Spec workflow | Full | Full | SKILL.md guided |
       | Execution loop | Auto (hooks) | Auto (hooks) | Manual (re-invoke) |
       | Parallel research | TeamCreate | Subagents | Sequential |

       ## Test Plan
       - [x] SKILL.md discoverability tests
       - [x] Spec artifact portability tests
       - [x] Claude Code zero-regression tests
       - [ ] CI checks pass"
       ```
  - **Verify**: `gh pr checks --watch` all green
  - **Done when**: PR created, all CI checks passing

## Notes

- **POC shortcuts taken**: Configuration bridge uses shell script (could be a proper CLI tool later). Codex adapter is SKILL.md-only (MCP server is future work). OpenCode adapter is a template (needs real-world testing with OpenCode).
- **Production TODOs**: MCP server for Codex execution loop, OpenCode command wrappers, integration testing with real OpenCode/Codex instances, plugin marketplace publishing.
- **Phasing**: SKILL.md portability (Phase 1) provides 80% of the value. Tool-specific adapters (Phase 2) are enhancements.
