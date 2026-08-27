---
spec: scoped-minimal-workflow
phase: design
created: 2026-08-27
generated: auto
---

# Design: scoped-minimal-workflow

## Overview

Extend seven active Ralph Specum prompt files. `.progress.md` remains the only scope carrier, and `.ralph-state.json.awaitingApproval` remains the existing mechanical stop. One Bats file pins the prompt contract; no new plugin component or runtime dependency is added.

## Architecture

### Component Diagram

```text
normal intake --------+
quick input -----------+--> Scope Envelope in .progress.md
new command -----------+              |
                                      v
                     research -> requirements -> design -> tasks
                                                              |
                                                              v
                                                spec-executor pre-check
                                                   |          |
                                              inside scope  expansion
                                                   |          |
                                                   v          v
                                                execute   escalation signal
                                                              |
                                                              v
                                               coordinator sets approval gate
```

### Components

#### Scope binding

**Purpose**: Persist one authorization boundary before research.

**Responsibilities**:
- `goal-interview.md` binds normal intake.
- `quick-mode.md` derives explicit input or pauses before work.
- `new.md` routes through normal intake instead of starting research directly.

#### Planning and execution

**Purpose**: Keep generated and executed tasks inside the boundary.

**Responsibilities**:
- `task-planner.md` checks every task and records adjacent findings as learnings.
- `spec-executor.md` checks the delegated contract before mutation.
- `coordinator-pattern.md` handles escalation, resume decisions, and automatic task modifications.

#### Minimal implementation

**Purpose**: Choose the first current mechanism that satisfies the requirement.

**Responsibilities**:
- `architect-reviewer.md` applies the order to components and dependencies.
- `task-planner.md` applies the order to `Do` and `Files`.
- `spec-executor.md` applies the order inside the delegated task boundary.

## Data Flow

1. Intake writes this canonical block to `.progress.md` before research:

```markdown
## Scope Envelope
- Target: <artifact or system>
- Action: <operation and authority level>
- Bounds: <allowed areas and exclusions>
- Deliverable: <result returned to the user>
- Complete when: <observable finish condition>
- Escalate when: <change that requires a new decision>
```

2. Each phase already reads `.progress.md`; no new handoff store is needed.
3. Task-planner keeps `Do`, `Files`, `Done when`, `Verify`, and external effects inside the envelope.
4. Spec-executor runs the same check before mutation.
5. If scope is missing or must change, spec-executor returns:

```text
SCOPE_ESCALATION_REQUIRED
Field: <field that would change>
Reason: <why the task cannot finish inside it>
Question: <one exact user decision>
```

6. Coordinator appends the blocker to `.progress.md`, sets `awaitingApproval: true`, and stops without changing task or failure counters.
7. On approval, coordinator updates the envelope first, clears the blocker and `awaitingApproval`, then replans or retries only after the task fits.
8. On rejection, coordinator keeps the original envelope. If the deliverable remains possible, it revises or removes the blocked task and clears `awaitingApproval`. If the deliverable is impossible, it records the blocker, leaves `awaitingApproval: true`, and stops without retrying.

## Minimal-Implementation Decision

The three responsible agents use this order:

1. Reuse repository code.
2. Use a language or framework feature already available to the project.
3. Change configuration or remove obsolete code.
4. Add code.

A dependency requires evidence that steps 1-3 cannot satisfy a current requirement. An abstraction requires two current uses or an explicit design requirement. The order cannot remove required validation, safety, accessibility, error handling, acceptance criteria, or verification.

## Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|---|---|---|---|
| Scope carrier | Requirements section, state-schema field, `.progress.md` block | `.progress.md` block | Every phase and executor handoff already reads it. |
| Stop mechanism | New hook rule, new phase, existing approval flag | Existing `awaitingApproval` flag | Stop watcher already honors the flag. |
| Policy surface | New skill, shared reference, active agent prompts | Active agent prompts | The behavior must run on every workflow and already has clear owners. |
| Granularity | Fine 30-50 tasks, coarse 8-15 tasks | Coarse | The user invoked minimal implementation and this is a prompt-only change. |

## File Structure

| File | Action | Purpose |
|---|---|---|
| `plugins/ralph-specum/references/goal-interview.md` | Modify | Bind six fields in normal intake. |
| `plugins/ralph-specum/references/quick-mode.md` | Modify | Bind before work or pause on ambiguity. |
| `plugins/ralph-specum/commands/new.md` | Modify | Use normal intake before research. |
| `plugins/ralph-specum/agents/architect-reviewer.md` | Modify | Apply reuse-first design. |
| `plugins/ralph-specum/agents/task-planner.md` | Modify | Bound tasks and apply reuse-first planning. |
| `plugins/ralph-specum/agents/spec-executor.md` | Modify | Check scope and apply reuse-first execution. |
| `plugins/ralph-specum/references/coordinator-pattern.md` | Modify | Handle escalation, resume, rejection, and task changes. |
| `tests/workflow-guardrails.bats` | Create | Pin the active prompt contract. |
| `plugins/ralph-specum/.claude-plugin/plugin.json` | Modify | Set version `4.11.0`. |
| `.claude-plugin/marketplace.json` | Modify | Set Ralph Specum version `4.11.0`. |

## Interfaces

The scope block and `SCOPE_ESCALATION_REQUIRED` text are prompt contracts. No application code interface changes.

## Error Handling

| Error Scenario | Handling Strategy | User Impact |
|---|---|---|
| Quick input cannot bind one field | Disable quick mode, set approval gate, ask one field-specific question before work | User answers one question. |
| Legacy spec has no envelope | Emit escalation before mutation | User supplies the missing boundary. |
| User approves expansion | Update envelope, clear gate, replan or retry | Work resumes inside the new boundary. |
| User rejects optional expansion | Remove or revise blocked task | Original deliverable continues. |
| User rejects required expansion | Record blocker and keep approval gate | Workflow stops without unauthorized work. |

## Edge Cases

- **External write hidden in verification**: Treat it as part of `Action` and `Bounds` before planning.
- **Automatic prerequisite or follow-up**: Add it only when its files, command, and external effects fit the envelope.
- **Adjacent issue**: Record it under learnings; create no task.
- **Explicit design requirement needs an abstraction**: The requirement overrides the two-use threshold.

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| None | N/A | Existing Markdown prompts, state files, Bats, and GitHub Actions are enough. |

## Security Considerations

- Scope `Action` and `Bounds` must state external-write authority when a task can send, deploy, merge, delete, pay, or mutate a remote system.
- Minimal implementation cannot bypass trust-boundary validation or security controls.

## Performance Considerations

- No runtime code path or dependency changes. Added prompt text should remain short and role-specific.

## Test Strategy

### Contract Tests

- Assert all six labels in normal and quick intake.
- Assert quick binding precedes reproduction and research.
- Assert architect, planner, and executor use the same ordered choice.
- Assert executor and coordinator carry the escalation signal and both approval outcomes.
- Assert task modifications cannot expand scope.
- Assert no source-skill path, import, or named source-skill heading appears in Ralph Specum.

### Integration Tests

- Run interview, integration, and stop-hook suites. Existing stop-hook tests prove `awaitingApproval: true` permits the loop to stop.

### Release Checks

- Run full Bats, JSON validation, diff checks, plugin smoke test, GitHub checks, and the paginated review-thread query.

## Existing Patterns to Follow

- Use literal `grep -Fq` Bats assertions from `tests/interview-framework.bats`.
- Use existing `awaitingApproval` writes and merge state instead of replacing the state object.
- Keep agent rules inside existing mandatory sections and final checklists.
