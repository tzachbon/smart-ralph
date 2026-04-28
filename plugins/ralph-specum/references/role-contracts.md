---
name: role-contracts
description: Agent access matrix, state field ownership, and non-execution agent boundaries for Smart Ralph
> Used by:
> - implement.md
> - spec-executor agent
> - external-reviewer agent
> - qa-engineer agent
> - spec-reviewer agent
> - architect-reviewer agent
> - product-manager agent
> - research-analyst agent
> - task-planner agent
> - refactor-specialist agent
> - triage-analyst agent

## Purpose

This document is the authoritative contract for which agent reads and writes which files,
and what each agent is explicitly forbidden from modifying. It complements the channel-map.md
(which documents the *when* of communication) by defining the *what* of file access.

## Access Matrix

| Agent | Reads | Writes | Denylist |
|-------|-------|--------|----------|
| spec-executor | All spec files, `.ralph-state.json`, channels | `.progress-task-*.md`, `chat.md`, `chat.executor.lastReadLine` | `.ralph-state.json` (except `chat.executor.lastReadLine`), `.epic-state.json`, spec meta files |
| external-reviewer | `task_review.md`, `tasks.md`, `.ralph-state.json`, spec files | `task_review.md`, `tasks.md`, `chat.md`, `chat.reviewer.lastReadLine`, `external_unmarks` | `.ralph-state.json` (except `chat.reviewer.lastReadLine`, `external_unmarks`) |
| qa-engineer | `.ralph-state.json` (taskIndex), spec files | _(read-only for state files; reads spec files for verification)_ | `.ralph-state.json` (except reading taskIndex) |
| spec-reviewer | Spec content via delegation | _(read-only)_ | All files |
| architect-reviewer | Spec files, `.ralph-state.json` | `.ralph-state.json` (`awaitingApproval`) | `.ralph-state.json` (except `awaitingApproval`), `tasks.md`, task files |
| product-manager | Spec files, `.ralph-state.json` | `.ralph-state.json` (`awaitingApproval`) | `.ralph-state.json` (except `awaitingApproval`), `tasks.md` |
| research-analyst | Codebase, spec files, `.ralph-state.json` | `.ralph-state.json` (`awaitingApproval`) | `.ralph-state.json` (except `awaitingApproval`) |
| task-planner | Spec files, `.ralph-state.json` | `.ralph-state.json` (`awaitingApproval`) | `.ralph-state.json` (except `awaitingApproval`), `tasks.md` |
| refactor-specialist | Spec files, `.ralph-state.json` | _(read-only for state files; creates and updates spec markdown files)_ | `.ralph-state.json`, lock files |
| triage-analyst | `.progress.md`, spec files | _(read-only)_ | `.ralph-state.json` |
| coordinator (human) | All | All | None |
| stop-watcher.sh | `.ralph-state.json`, `.ralph-field-baseline.json` | _(read-only — does NOT modify files)_ | N/A |

## State Field Ownership

The `.ralph-state.json` file contains many fields. The coordinator (human) writes **all** fields unless explicitly delegated. Agent-write exceptions:

| Field | Owner(s) | Type |
|-------|----------|------|
| `chat.executor.lastReadLine` | spec-executor | chat cursor |
| `chat.reviewer.lastReadLine` | external-reviewer | chat cursor |
| `external_unmarks` | external-reviewer | external review signal |
| `awaitingApproval` | coordinator, architect-reviewer, product-manager, research-analyst, task-planner | approval gate |
| `phase` | coordinator | string: research/requirements/design/tasks/implement/cancel |
| `taskIndex` | coordinator | integer: current task index |
| `totalTasks` | coordinator | integer: total task count |
| `taskIteration` | coordinator | integer: per-task retry count |
| `globalIteration` | coordinator | integer: overall iteration count |
| `parallelGroup` | coordinator | integer: group for parallel execution |
| `relatedSpecs` | coordinator | array: related epic specs |
| `taskResults` | coordinator | array: per-task pass/fail summary |
| `recoveryMode` | coordinator | boolean: recovery from crash |
| `source` | coordinator | string: epic or spec origin |
| `name` | coordinator | string: spec/epic name |
| `basePath` | coordinator | string: working directory |
| `epicName` | coordinator | string: parent epic name |
| `fixTaskMap` | coordinator | object: fix task mapping |
| `modificationMap` | coordinator | object: modification mapping |
| `maxFixTasksPerOriginal` | coordinator | integer: fix task limit |
| `maxFixTaskDepth` | coordinator | integer: fix depth limit |
| `maxModificationsPerTask` | coordinator | integer: modification limit |
| `maxModificationDepth` | coordinator | integer: modification depth limit |
| `nativeTaskMap` | coordinator | object: native task mapping |
| `nativeSyncEnabled` | coordinator | boolean: sync toggle |
| `nativeSyncFailureCount` | coordinator | integer: failure counter |
| `granularity` | coordinator | string: coarse/fine |
| `maxGlobalIterations` | coordinator | integer: max iterations |
| `maxTaskIterations` | coordinator | integer: per-task max iterations |
| `failedStory` | coordinator | string: failed story identifier |
| `repairIteration` | coordinator | integer: repair attempt count |
| `originTaskIndex` | coordinator | integer: original task index |
| `commitSpec` | coordinator | boolean: commit specification |
| `specName` | coordinator | string: spec name |
| `chat` | coordinator | object: chat state |

## Non-Execution Agent Boundaries

The following agents operate outside the execution loop. They read spec files and write only their designated outputs or approval flags.

### architect-reviewer

- **Role**: Reviews technical design decisions; approves architectural adequacy.
- **Reads**: Spec files, `.ralph-state.json`.
- **Writes**: `.ralph-state.json` (`awaitingApproval` field only).
- **Deny**: All `.ralph-state.json` fields except `awaitingApproval`; `tasks.md`; task files.

### product-manager

- **Role**: Validates user stories, acceptance criteria, and feature completeness.
- **Reads**: Spec files, `.ralph-state.json`.
- **Writes**: `.ralph-state.json` (`awaitingApproval` field only).
- **Deny**: All `.ralph-state.json` fields except `awaitingApproval`; `tasks.md`.

### research-analyst

- **Role**: Performs codebase and web research; validates technical assumptions.
- **Reads**: Codebase, spec files, `.ralph-state.json`.
- **Writes**: `.ralph-state.json` (`awaitingApproval` field only).
- **Deny**: All `.ralph-state.json` fields except `awaitingApproval`.

### task-planner

- **Role**: Decomposes specs into task breakdowns with POC-first methodology.
- **Reads**: Spec files, `.ralph-state.json`.
- **Writes**: `.ralph-state.json` (`awaitingApproval` field only).
- **Deny**: All `.ralph-state.json` fields except `awaitingApproval`; `tasks.md`.

### refactor-specialist

- **Role**: Identifies refactoring opportunities and applies safe structural improvements.
- **Reads**: Spec files, `.ralph-state.json`.
- **Writes**: _(read-only for state files; creates and updates spec markdown files)_.
- **Deny**: `.ralph-state.json`; lock files.

### triage-analyst

- **Role**: Decomposes feature requests into epics and specs during triage.
- **Reads**: `.progress.md`, spec files.
- **Writes**: _(read-only with respect to existing files)_.
- **Deny**: `.ralph-state.json`.

## Adding a New Agent

Follow these five steps in order when onboarding a new agent:

1. **Add access matrix row**

   Add a new row to the `## Access Matrix` table (section above). Use this template:

   ```
   | <agent-name> | <reads> | <writes> | <denylist> |
   ```

   - `<agent-name>`: The agent's directory name (e.g., `my-new-agent`).
   - `<reads>`: Comma-separated list of files/directories the agent reads.
   - `<writes>`: Comma-separated list of files/directories the agent writes. Use `_(read-only)_` if applicable.
   - `<denylist>`: Explicitly forbidden files. Use `N/A` if none.

2. **Append DO NOT list section to agent file**

   Add a `## DO NOT` section at the end of the agent's markdown file in `plugins/ralph-specum/agents/`. This enforces boundaries at the prompt level:

   ````markdown
   ## DO NOT

   - Read or write `.ralph-state.json` (except `<authorized fields>`)
   - Read or write `tasks.md` (if not authorized)
   - Modify `.epic-state.json`
   - Modify spec meta files (`research.md`, `requirements.md`, etc.)
   - Run shell commands outside `<allowed commands>`
   ````

3. **Update channel-map.md if agent uses inter-agent channels**

   If the new agent reads or writes any filesystem channel (e.g., `chat.md`, `task_review.md`), add an entry to the `## Channel Registry` table in `plugins/ralph-specum/references/channel-map.md`:

   ```
   | <channel-name> | `<basePath>/<channel-name>` | <writer>(s) | <reader>(s) | <timing> | <locking> |
   ```

4. **Update baseline for new state fields**

   If the agent introduces new `.ralph-state.json` fields, add them to the `## State Field Ownership` table and update the baseline in `references/.ralph-field-baseline.json`:

   ```json
   {
     "new.state.field": "agent-name"
   }
   ```

5. **Check cross-spec conflicts**

   Before finalizing, check the `## Cross-Spec Dependencies` table (if exists in requirements.md) for file overlap with prior specs. If the new agent modifies a file listed in the table, verify that changes are additive and non-conflicting with prior spec implementations.

   The baseline maps field paths to owner agent names (flat format). Arrays (like `awaitingApproval`) list all authorized writers.

## Relationship to Channel Map

The role-contracts.md and channel-map.md are complementary:

- **role-contracts.md** defines the *what*: which files each agent may read or write. It is a permissions contract.
- **channel-map.md** defines the *when*: timing of reads/writes, locking strategies, and race condition handling for shared channels.

Use role-contracts.md to audit whether an agent has permission to access a file. Use channel-map.md to determine how to safely coordinate concurrent access to shared channels. When adding a new agent or channel, update both documents.

## Cross-Spec Dependencies

This reference document has the following cross-spec dependencies:

| Dependency | Spec(s) | Reason |
|------------|---------|--------|
| `spec-executor.md` (agent) | 3, 6, 7 | Defines the spec-executor agent's system prompt and execution rules that this access matrix constrains |
| `external-reviewer.md` (agent) | 3, 6 | Defines the external-reviewer agent's review protocol that requires its access permissions |
| `.ralph-state.json` (state schema) | All specs | The state field ownership table is derived from the state schema used across all phases |
