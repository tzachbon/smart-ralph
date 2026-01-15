---
spec: goal-interview
phase: requirements
created: 2026-01-15
---

# Requirements: Goal Interview

## Goal

Add exhaustive user interviews to Ralph Specum workflow using AskUserQuestion tool, conducted at command level before delegating to subagents. Interviews gather non-obvious requirements about technical implementation, UI/UX, constraints, and tradeoffs through iterative questioning until requirements converge. Additionally, remove deprecated "tools" field from agent files.

## User Stories

### US-1: Phase-Specific User Interviews

**As a** developer using Ralph Specum
**I want to** be asked clarifying questions at each phase before specification generation
**So that** the generated artifacts reflect my actual requirements rather than assumptions

**Acceptance Criteria:**
- [ ] AC-1.1: Research command asks questions about technical preferences, constraints, success criteria before invoking research-analyst
- [ ] AC-1.2: Requirements command asks questions about user personas, edge cases, priorities before invoking product-manager
- [ ] AC-1.3: Design command asks questions about architecture preferences, technology constraints, integration needs before invoking architect-reviewer
- [ ] AC-1.4: Tasks command asks questions about testing requirements, deployment considerations, quality thresholds before invoking task-planner
- [ ] AC-1.5: Each command includes AskUserQuestion in its allowed-tools list

### US-2: Adaptive Interview Depth

**As a** developer with varying project complexity
**I want to** interviews that start minimal and expand when complexity is detected
**So that** simple projects proceed quickly while complex ones get thorough exploration

**Acceptance Criteria:**
- [ ] AC-2.1: Initial interview batch contains 2-3 essential questions per phase
- [ ] AC-2.2: Follow-up questions triggered when user selects "Other" or provides complex answers
- [ ] AC-2.3: Interview expands automatically when ambiguity or complexity indicators detected
- [ ] AC-2.4: Maximum interview depth configurable (default: 5 rounds per phase)

### US-3: Quick Mode Interview Bypass

**As a** developer who wants rapid prototyping
**I want to** skip all interviews when using --quick flag
**So that** I can generate specs without interactive input

**Acceptance Criteria:**
- [ ] AC-3.1: --quick flag bypasses all AskUserQuestion calls
- [ ] AC-3.2: Quick mode uses default/inferred values instead of asking
- [ ] AC-3.3: No user prompts appear during quick mode execution
- [ ] AC-3.4: Behavior documented in command help text

### US-4: Interview Results Storage

**As a** spec author reviewing generated artifacts
**I want to** interview responses stored in phase artifacts
**So that** I can see what decisions informed the generated content

**Acceptance Criteria:**
- [ ] AC-4.1: Research interview responses stored in research.md under "User Context" section
- [ ] AC-4.2: Requirements interview responses stored in requirements.md under "User Decisions" section
- [ ] AC-4.3: Design interview responses stored in design.md under "Design Inputs" section
- [ ] AC-4.4: Tasks interview responses stored in tasks.md under "Execution Context" section
- [ ] AC-4.5: Interview responses passed to subagent as part of delegation context

### US-5: Interview Convergence Detection

**As a** developer answering interview questions
**I want to** the interview to stop when sufficient information gathered
**So that** I am not asked redundant questions

**Acceptance Criteria:**
- [ ] AC-5.1: Interview stops when user explicitly signals completion (e.g., "That's all")
- [ ] AC-5.2: Interview stops when predefined question categories covered
- [ ] AC-5.3: Interview stops after maximum iteration count reached
- [ ] AC-5.4: Convergence criteria documented in each command file

### US-6: Clean Agent Definitions

**As a** plugin maintainer
**I want to** deprecated "tools" field removed from agent files
**So that** agents follow current conventions (allowed-tools in commands only)

**Acceptance Criteria:**
- [ ] AC-6.1: research-analyst.md has no "tools:" line in frontmatter
- [ ] AC-6.2: product-manager.md has no "tools:" line in frontmatter
- [ ] AC-6.3: architect-reviewer.md has no "tools:" line in frontmatter
- [ ] AC-6.4: task-planner.md has no "tools:" line in frontmatter
- [ ] AC-6.5: plan-synthesizer.md has no "tools:" line in frontmatter
- [ ] AC-6.6: No agent file contains "tools:" field in frontmatter

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Add AskUserQuestion to allowed-tools in research.md, requirements.md, design.md, tasks.md | High | Commands list includes AskUserQuestion |
| FR-2 | Implement interview workflow in research.md before Task delegation | High | Interview questions asked, responses captured, passed to subagent |
| FR-3 | Implement interview workflow in requirements.md before Task delegation | High | Interview questions asked, responses captured, passed to subagent |
| FR-4 | Implement interview workflow in design.md before Task delegation | High | Interview questions asked, responses captured, passed to subagent |
| FR-5 | Implement interview workflow in tasks.md before Task delegation | High | Interview questions asked, responses captured, passed to subagent |
| FR-6 | Define phase-specific question templates for research phase | High | Questions cover: technical preferences, constraints, success criteria, prior experience |
| FR-7 | Define phase-specific question templates for requirements phase | High | Questions cover: user types, edge cases, priorities, non-functional requirements |
| FR-8 | Define phase-specific question templates for design phase | High | Questions cover: architecture preferences, technology constraints, integration needs |
| FR-9 | Define phase-specific question templates for tasks phase | Medium | Questions cover: testing requirements, deployment considerations, quality gates |
| FR-10 | Implement --quick flag detection to skip interviews | High | Quick mode check at start of interview logic |
| FR-11 | Store interview responses in generated artifact files | Medium | Each phase artifact has section for interview responses |
| FR-12 | Pass interview context to subagent in Task delegation | High | Subagent prompt includes interview responses |
| FR-13 | Implement interview convergence logic | Medium | Stop conditions: user signal, categories covered, max iterations |
| FR-14 | Remove "tools:" field from research-analyst.md frontmatter | High | Line deleted, no functional change |
| FR-15 | Remove "tools:" field from product-manager.md frontmatter | High | Line deleted, no functional change |
| FR-16 | Remove "tools:" field from architect-reviewer.md frontmatter | High | Line deleted, no functional change |
| FR-17 | Remove "tools:" field from task-planner.md frontmatter | High | Line deleted, no functional change |
| FR-18 | Remove "tools:" field from plan-synthesizer.md frontmatter | High | Line deleted, no functional change |
| FR-19 | Implement adaptive depth based on answer complexity | Low | Follow-up questions triggered on "Other" selections or complex responses |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Interview response time | Time to complete interview | Under 3 minutes per phase for typical projects |
| NFR-2 | Question clarity | User comprehension | No ambiguous or jargon-heavy questions |
| NFR-3 | Timeout handling | AskUserQuestion timeout (60s) | Graceful degradation if timeout occurs |
| NFR-4 | Backward compatibility | Existing specs | Specs created before this change must still work |
| NFR-5 | Quick mode performance | Time to skip interview | No perceptible delay when --quick used |

## Glossary

- **AskUserQuestion**: Claude Code tool that presents 1-4 questions with 2-4 options each, allowing user selection or custom "Other" input
- **Command**: Coordinator-level markdown file that orchestrates phase execution (has allowed-tools)
- **Agent**: Subagent-level markdown file invoked via Task tool (no direct tool access, receives context from command)
- **Interview Convergence**: Point at which sufficient information gathered to proceed without additional questions
- **Quick Mode**: Non-interactive execution mode triggered by --quick flag, bypasses all user prompts
- **Phase Artifact**: Output file for each phase (research.md, requirements.md, design.md, tasks.md)

## Out of Scope

- Interview state persistence across sessions (resuming interrupted interviews)
- Custom question templates per project (use hardcoded templates)
- Interview analytics or metrics collection
- Multi-language interview support
- Voice or audio-based interviews
- Interview response validation (accept all user input as-is)
- Changes to implement.md or spec-executor.md (execution phase has no interview)
- Changes to start.md, new.md, status.md, cancel.md, switch.md commands

## Dependencies

- AskUserQuestion tool available in Claude Code environment
- Existing command files (research.md, requirements.md, design.md, tasks.md) must exist
- Existing agent files must exist for tools field removal
- Task tool functionality unchanged

## Success Criteria

- All 4 phase commands (research, requirements, design, tasks) conduct interviews before delegation
- Interview responses appear in generated artifact files
- Quick mode (--quick) produces output without any user prompts
- All 5 agent files have "tools:" field removed
- Existing workflow continues to function for users who answer "Other" minimally
