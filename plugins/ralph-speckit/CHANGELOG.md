# Changelog

All notable changes to Ralph Speckit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-20

### Added

- **Core Commands**
  - `/speckit:constitution` - Create/update project principles
  - `/speckit:start` - Start new feature with auto-generated ID and branch
  - `/speckit:specify` - Define feature specification with user stories
  - `/speckit:clarify` - Clarify spec requirements
  - `/speckit:checklist` - Generate quality checklist
  - `/speckit:plan` - Create technical design
  - `/speckit:analyze` - Analyze implementation approach
  - `/speckit:tasks` - Generate task list from spec and plan
  - `/speckit:taskstoissues` - Convert tasks to GitHub issues
  - `/speckit:implement` - Execute tasks autonomously via Ralph Wiggum
  - `/speckit:status` - Show current feature status
  - `/speckit:switch` - Switch active feature
  - `/speckit:cancel` - Cancel execution loop

- **Agents**
  - `spec-executor` - Executes individual tasks with commit discipline
  - `qa-engineer` - Handles verification checkpoint tasks

- **Features**
  - Constitution-first approach for project principles
  - Auto-generated feature IDs (001, 002, etc.)
  - Automatic git branch creation
  - Parallel task execution with `[P]` marker
  - Verification task delegation with `[VERIFY]` marker
  - 4-layer verification system (contradiction, uncommitted, checkmark, signal)
  - Persistent state management via `.speckit-state.json`
  - Progress tracking via `.progress.md`

- **Templates**
  - `constitution.md` - Project principles template
  - `spec-template.md` - Feature specification template
  - `plan-template.md` - Technical design template
  - `tasks-template.md` - Task list template
  - `checklist-template.md` - Quality checklist template

- **Documentation**
  - README.md with full usage guide
  - CONTRIBUTING.md with development guidelines
  - Example files for quick start

### Dependencies

- Requires Ralph Wiggum plugin for autonomous execution

[0.1.0]: https://github.com/tzachbon/smart-ralph/releases/tag/ralph-speckit-v0.1.0
