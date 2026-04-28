# Spec: bmad-bridge-plugin

Epic: specs/_epics/engine-roadmap-epic/epic.md

## Goal
Create a BMAD→smart-ralph structural mapper plugin that converts BMAD artifacts (PRD, user stories, architecture decisions, epics, test scenarios) into smart-ralph spec files.

## Acceptance Criteria
1. Plugin at `plugins/ralph-bmad-bridge/` with valid plugin.json
2. `/ralph-bmad:import` command works: `/ralph-bmad:import <bmad-path> <spec-name>`
3. Output spec files in `specs/<name>/` are valid and can be executed by `/ralph-specum:implement`
4. Mapping covers: PRD→requirements.md, user stories→verification contract, ADRs→design.md, epic→tasks.md, test scenarios→Verify commands

## Interface Contracts
### Reads
- `plugins/ralph-bmad-bridge/` — NEW (no reads of existing files)
- BMAD artifacts (via command invocation at runtime)

### Writes
- `plugins/ralph-bmad-bridge/.claude-plugin/plugin.json` — NEW
- `plugins/ralph-bmad-bridge/commands/` — NEW
- `plugins/ralph-bmad-bridge/scripts/` — NEW
- (via command at runtime) `specs/<name>/requirements.md`
- (via command at runtime) `specs/<name>/design.md`
- (via command at runtime) `specs/<name>/tasks.md`

## Dependencies
None (completely independent — no shared files with any other spec)
