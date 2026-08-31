# Ralph State Contract

## Core Files

Each spec directory uses:

- `.ralph-state.json`
- `.progress.md`
- `research.md`
- `requirements.md`
- `design.md`
- `tasks.md`

## Required State Fields

Preserve these fields across all phases:

- `source`
- `name`
- `basePath`
- `phase`
- `taskIndex`
- `totalTasks`
- `taskIteration`
- `maxTaskIterations`
- `globalIteration`
- `maxGlobalIterations`
- `commitSpec`
- `relatedSpecs`

Optional but common:

- `awaitingApproval`
- `approvalGate`
- `approvalAudit`
- `quickMode`
- `quickAuthorization`
- `phaseSkillLoad`
- `phaseInterview`
- `recoveryMode`
- `fixTaskMap`
- `activePrototypes`

## New Spec Defaults

Use these defaults when a new spec starts:

```json
{
  "source": "spec",
  "name": "<spec-name>",
  "basePath": "<resolved-spec-path>",
  "phase": "research",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "commitSpec": true,
  "relatedSpecs": [],
  "awaitingApproval": false
}
```

Read `default_max_iterations` and `auto_commit_spec` from `.claude/ralph-specum.local.md` when present.

## Overlay State

`activePrototypes` is an optional map keyed by prototype ID. It supplements the main state; `prototype` is never a main `phase` value. Each active entry records identity, lifecycle status, `triggerPhase`, `returnPhase`, optional `returnTaskIndex`, timestamps, blocking and stale dependency data, child `agentId`, resolved `specRoot` and `basePath`, isolation pointers, source disposition, configuration evidence, attempts, lease data, and decision checkpoints.

Terminal records are immutable files under `<basePath>/prototypes/<id>.md`. Candidate files remain ignored and mutable only until exact-byte review and no-overwrite publication. Remove an active entry only after re-reading and verifying its final record. Never delete state while the active map is nonempty.

## Triage State

Triage uses the active epic's `specs/_epics/<epic-name>/.epic-state.json` for `phaseSkillLoad`, `phaseInterview`, and `quickAuthorization`. Pass phase `triage` to every gate command. Do not require a spec `.ralph-state.json` for triage.

## Merge Rule

Never rebuild state from scratch once the file exists. Merge only the fields needed for the current phase.

Use `scripts/locked_state.py` for every write, lease, transition, removal, and guarded deletion. `scripts/merge_state.py` is only the compatibility wrapper for deterministic top-level merges. Resolve `basePath` before every operation and preserve unknown fields.

Normal prototype verdict and handoff checkpoints belong to the user. Quick mode owns them, asks no questions, and continues to design. Both modes persist the selected verdict, handoff, stale artifacts, and stale task indexes before publication so resume never depends on conversation memory.

## Phase gate fields

`scripts/phase_gate.py` owns these state objects:

- `quickAuthorization` records only exact `--quick` authorization.
- `phaseSkillLoad` records the exact goal snapshot, prior-artifact source/hash receipts, selected manifest, full-body and required-resource hashes, warnings, failures, conflicts, discovery identity, and artifact-agent load receipts.
- `phaseInterview` records frontier rounds, partial answers, assumptions, final confirmation, or exact quick bypass.
- `discoveredSkills` is cumulative append-only discovery history. New entries contain `pass`, `revision`, `name`, `activeSource`, `reason`, `shadowedSources`, and `outcome`, and each pass revision repeats the complete selected set. Legacy `invoked` fields never prove current load.

The identity tuple is `phase`, `interviewId`, `discoveryRevision`, and `contextDigest`. `phaseSkillLoad.context` stores the exact goal snapshot and absolute source/hash receipts for applicable prior artifacts. The helper computes the digest with the length-framed byte formula in the internal interview algorithm and rechecks current artifact bytes at every gate. When top-level `goal` exists, it is the canonical goal and must match the snapshot. Legacy spec states without `goal` use the persisted snapshot as the source of truth. Keep the tuple unchanged only while those inputs remain unchanged.

Use the helper commands instead of editing these objects by hand:

```text
phase_gate.py mode STATE [--quick|--interactive]
phase_gate.py record-skill-load STATE --input FILE
phase_gate.py begin-interview STATE --phase PHASE --interview-id ID --round N --discovery-revision REV --context-digest SHA256
phase_gate.py open-frontier STATE --round N --decision-id ID [--decision-id ID ...]
phase_gate.py classify-reply --text TEXT
phase_gate.py resolve-approval STATE --text TEXT
phase_gate.py record-answer STATE --decision-id ID --answer TEXT [--assumption TEXT]
phase_gate.py await-confirmation STATE --decision-id ID --approach TEXT
phase_gate.py confirm STATE --decision-id ID --source approve-and-delegate
phase_gate.py skip STATE --reason TEXT --assumption TEXT [--assumption TEXT ...] [--decision-id ID]
phase_gate.py revise STATE --decision-id ID [--decision-id ID ...]
phase_gate.py check-delegation STATE --phase PHASE --interview-id ID --discovery-revision REV --context-digest SHA256
phase_gate.py record-agent-load STATE --input RECEIPT
phase_gate.py check-agent-write STATE --phase PHASE --interview-id ID --context-digest SHA256 --discovery-revision REV --agent UNIQUE_DISPATCH_ID
```

`phaseSkillLoad.status` is `complete`, `partial_warned`, or `core_failed`. `phaseInterview.status` is `collecting`, `awaiting_confirmation`, `complete`, `skipped`, or `bypassed_quick`.

Manifest `failures` exactly lists every failed body and resource error. `warnings` lists only domain failures that allow continuation. Complete state has neither; `partial_warned` has equal domain-only arrays; `core_failed` has all errors in `failures` and domain-only errors in `warnings`.

Loaded body and resource receipts require their current SHA-256 digest, `loadStatus: "loaded"`, and no errors. Failed receipts require `sha256: null`, `loadStatus: "failed"`, and nonempty errors. Every selected skill also records `requiredResourceSources`; its receipt sources must match that complete inspected inventory exactly. A fresh `phaseSkillLoad` must have an empty `artifactAgentLoads`; only `record-agent-load` may append child receipts.

The one core selection must resolve to this plugin's packaged `skills/interview-framework-codex/SKILL.md` and must include its packaged `references/algorithm.md` and `references/domain-modeling.md`. Changing mode clears an incompatible `phaseInterview` in the same atomic state write. `skip` requires at least one nonblank assumption and preserves recorded answers.

## Approval Contract

`awaitingApproval: true` is not enough on its own.

This mirrors `Approval Prompt Shape` in `references/workflow.md` and should stay in sync with that section. Current enforcement is via Codex platform review plus the repo-local metadata and content checks.

`approvalGate` and append-only `approvalAudit` are helper-owned enforcement state. Never authorize an action from prompt wording, chat history, or audit history. A usable `approvalGate` exists only while `awaitingApproval: true` and exactly one current artifact or revision action has nonblank `id`, `phase`, `kind`, and `action`; a `revision` also has recorded nonblank `feedback`. A missing, stale, malformed, or multi-option view has no usable descriptor: ask one focused clarification and do not mutate state. Clear or replace the descriptor only after its existing action succeeds. After an accepted resolver result only, the helper appends `originalReply`, `normalizedAction`, and `gateId` to `approvalAudit`.

When a phase sets `awaitingApproval: true`, the visible assistant response must also:

- name the file or files that changed
- give a short summary
- end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to <named next step>`

Treat `continue to <named next step>` as approval of the current artifact and permission to move forward.

Pre-delegation approval is separate. At an active decision frontier, retain `classify-reply`; control-only text cannot answer a decision. Handle canonical final and artifact choices first. Only otherwise run `phase_gate.py resolve-approval STATE --text TEXT` for one live action. For an accepted pre-delegation result, persist the existing `confirm --source approve-and-delegate`, require `check-delegation`, then use the existing delegate path. For an accepted artifact or revision result, use its existing continuation or revision route and fresh writer checks. Resolver acceptance never bypasses those checks. On clarification, leave state unchanged and ask one focused question. Use `revise` from `awaiting_confirmation` to reopen named decisions, then obtain the same final confirmation ID again. During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and keeps `awaitingApproval: true`. Ask for focused feedback only when none is pending.

## Progress File

`.progress.md` is persistent. Keep:

- original goal
- current phase
- current task summary
- completed task notes
- learnings
- blockers
- next step

## Commit Rules

- Spec artifacts may be auto-committed locally when `commitSpec` is true. The setting authorizes no remote action.
- Implementation tasks should use the task's `Commit` line by default.
- If the user disables commits, keep the disk state and progress updates but skip git commits.
- Before any push, apply the Prototype Evidence Push Gate in `workflow.md`. Prototype source commits and records stay local unless the user separately authorizes the exact records and remote action at that boundary. Quick mode never asks and never pushes.
