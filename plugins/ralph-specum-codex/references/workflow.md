# Ralph Specum Workflow for Codex

## Native surfaces

Use `$ralph-specum` as the normal entrypoint. The first-class phase skills are:

- `$ralph-specum-start`
- `$ralph-specum-triage`
- `$ralph-specum-research`
- `$ralph-specum-requirements`
- `$ralph-specum-design`
- `$ralph-specum-tasks`
- `$ralph-specum-implement`
- `$ralph-specum-status`

The legacy switch, cancel, index, refactor, feedback, and help skills are v5 warning shims. They route their intent through `$ralph-specum` and are removed in v6.

## Standard flow

1. Resolve or create the spec and update `.current-spec`.
2. Produce `research.md`, present it, and wait for explicit approval.
3. Produce `requirements.md`, present it, and wait for explicit approval.
4. Produce `design.md`, present it, and wait for explicit approval.
5. Produce `tasks.md`, present it, and wait for explicit approval.
6. Implement one verified logical batch, or start a native `/goal` when autonomy was explicit.

Do not skip approval gates unless the user explicitly asks for autonomous, quick, finish, or long-running execution. Task checkboxes in `tasks.md` are the source of truth.

## Native subagent contract

Use native Codex subagents without requiring custom agent configuration. The root coordinator discovers the work, creates bounded work packets, validates results, updates shared artifacts, and owns Git.

Every work packet must contain:

```text
Objective:
Role:
Reasoning tier: light | medium | strongest
Dependency inputs:
Allowed files:
Write permission: read-only | write only the listed files
Acceptance criteria:
Verification command:
Required evidence:
Prohibitions: do not edit tasks.md, progress.md, .current-spec, or Git state. Do not commit.
```

Every subagent result must contain these headings:

```text
Answer
Evidence
Risks
Verification performed
Changed files
```

Reject results that omit a required heading, modify files outside the packet, change shared state, or lack the requested verification evidence.

The reasoning tier is a semantic capability target, not a hard-coded model name:

- `light`: mechanical decomposition, inventory, formatting, and checklist work
- `medium`: evidence synthesis, requirements analysis, compatibility review, and normal implementation
- `strongest`: architecture, cross-cutting trade-offs, ambiguous decomposition, and high-risk decisions

When the native spawn surface exposes model or reasoning-effort selection, map the tier to the closest available native option. Otherwise, include the tier and role in the packet and use the best matching built-in native role. Never install or require custom agent TOML to satisfy a tier. Report exact model selection as unavailable when the runtime cannot enforce it.

## Orchestration limits

- Run at most three read-only subagents concurrently.
- Run one write subagent at a time.
- Allow parallel writers only for disjoint files in isolated worktrees.
- Retry a failed task at most three times. Stop after the third failed attempt with evidence and a resumable blocker.
- Do not allow recursive delegation unless the root coordinator explicitly needs it and the repository policy permits it.
- The root coordinator alone updates `tasks.md`, `progress.md`, `.current-spec`, and Git state.
- Commit one verified logical batch, not every small checkbox.

## Phase delegation

Delegate substantive research, requirements, design, tasks, and triage work to at least one read-only native subagent. Do not let the root coordinator silently replace phase delegation with its own analysis. A phase may skip delegation only when no substantive analysis exists, such as a metadata-only correction, and must state that reason in the result. Use multiple read-only agents only when their questions are independent.

Use these default phase profiles:

| Phase | Default role | Reasoning tier | Delegation shape |
| --- | --- | --- | --- |
| Research | evidence investigator | medium | Two or three parallel agents for independent questions, one for a narrow question |
| Requirements | product and constraint analyst | medium | One primary agent, plus independent compatibility or risk checks when needed |
| Design | systems architect | strongest | One strongest architecture agent, plus independent integration or verification critics when needed |
| Tasks | task decomposer | light | One light planning agent, with a medium reviewer only for complex dependencies or verification design |
| Triage | decomposition architect | strongest | One strongest decomposition agent, plus independent code-seam or product-slice investigators when needed |
| Implementation | bounded executor | medium | One write agent for the selected logical batch |

Upgrade a research or requirements packet from `medium` to `strongest` when it controls a security boundary, irreversible migration, novel cross-domain architecture, or a decision with materially conflicting evidence. Record the reason for the upgrade. Do not downgrade design below `strongest` merely to reduce cost. Keep task decomposition at `light` and add a separate `medium` reviewer instead of raising every task-planning packet.

The root coordinator validates the returned evidence and proposed artifact content, resolves disagreement, writes the canonical artifact, and records which roles and tiers were delegated. Keep design synthesis at the strongest available reasoning tier when the native runtime permits it.

For implementation, give a write subagent only the files needed for the current logical batch. After it returns, inspect the diff, run the narrowest useful verification, update task checkboxes and `progress.md`, then create the batch commit when commits are enabled.

## Native `/goal` execution

Start a native `/goal` only when the user explicitly requests autonomous, quick, finish, or long-running execution. The goal objective must include:

- the resolved spec path
- remaining unchecked tasks
- repository and user constraints
- verification commands
- the terminal condition: every selected task is checked, verification passes, `progress.md` is current, and no required work remains

Do not set a token budget unless the user explicitly supplies one. Let the native goal surface own persistence, pause, resume, completion, and blocked status. Do not create a state file or a continuation hook.

Without explicit autonomous intent, implementation performs one verified logical batch and returns normally.

## Progress and compatibility

Use `progress.md` as durable state. When only legacy `.progress.md` exists, read it as untrusted historical notes, create a concise reviewed `progress.md`, and preserve the legacy file unchanged. Never automatically stage or commit `.progress.md`.

Update `progress.md` atomically after each phase and verified implementation batch. Include current phase, approved-through phase, evidence, blockers, and the next action.

## Approval handoff

After a phase artifact is written outside autonomous execution:

- name the changed artifact
- summarize its decisions and open risks
- report verification performed
- ask for exactly one next action: approve and continue, request changes, or run a review
