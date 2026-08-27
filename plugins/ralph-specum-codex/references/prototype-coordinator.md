# Prototype Coordinator

Use this procedure for direct, suggested, resumed, quick, and cancelled prototype requests. Store the overlay in `activePrototypes`; keep the main phase unchanged while the request is active.

## Invariants

- Resolve the target with `plugins/ralph-specum-codex/scripts/resolve_spec_paths.py` before every operation. Use its `basePath`, `specRoot`, validated prototype settings, and `configWarnings`.
- Store `triggerPhase`, `returnPhase`, and `returnTaskIndex` in the active entry. Preserve every unrelated state field.
- Keep the current checkout on its branch. Run source work only in the recorded sibling worktree or eligible scratch path.
- Route state, record, and harness mechanics through `locked_state.py`, `prototype_records.py`, and `prototype_harness.py`. Do not write state, candidates, or final records by hand.
- Stop at a safe tool boundary. Preserve a running tool call until that boundary.
- Keep source and evidence local. A local commit does not authorize a push, PR update, issue write, or remote branch publication.

## Resolve and reconcile

1. Parse one mode:
   - `direct`: preserve the current phase as `returnPhase`.
   - `suggested`: record the next phase supplied by the research or requirements walkthrough.
   - `resume`: continue the explicit ID, the sole active entry, or a selected active entry.
   - `quick`: run one agent-owned request after requirements with `returnPhase: design`.
   - `cancel`: start terminal cancellation at the next safe boundary.
2. Stop when `basePath` is null, missing, or ambiguous.
3. Read `.ralph-state.json`, then run record reconciliation before selecting or reserving an entry.
4. Snapshot settings and warnings in every new entry. Use the stored snapshot on resume.

Use these exact task 1.16-compatible helper forms:

```bash
python3 plugins/ralph-specum-codex/scripts/locked_state.py merge --state "$STATE_FILE" --set "phase=requirements"
python3 plugins/ralph-specum-codex/scripts/locked_state.py upsert-prototype --state "$STATE_FILE" --id "$ID" --entry-json "$ENTRY_JSON"
python3 plugins/ralph-specum-codex/scripts/prototype_records.py render-candidate --base-path "$BASE_PATH" --record-json "$RECORD_JSON"
python3 plugins/ralph-specum-codex/scripts/prototype_records.py publish --base-path "$BASE_PATH" --id "$ID"
python3 plugins/ralph-specum-codex/scripts/prototype_records.py reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
```

The prototype workflow does not use the first example to change its main phase. That command documents the end-to-end checkpoint interface.

## Reserve or resume

1. Calculate the normalized question hash and blocker target before reservation.
2. For the same question and blocker, offer resume, supersede, or a distinct record in normal mode. Apply approved duplicate rules in quick mode and count the result as its one request.
3. Group incompatible evidence for one blocker into a conflict set. Block dependent normal work until the conflict policy resolves it. In quick mode, select supported evidence or exclude the set, record the result, and continue.
4. Resume an explicit ID. Resume one active entry without another choice. List several entries for normal selection; let quick mode take over the oldest blocking entry.
5. Use `upsert-prototype`, `claim-builder`, `heartbeat`, `renew-lease`, `release-lease`, and compare-and-set `transition` operations. Keep the main phase untouched while the overlay runs.

## Choose capture and isolate source

Normal mode:

1. Recommend `retained` for app routes, multiple files, authentication, real data, or expensive source. Recommend `ephemeral` for one self-contained logic experiment.
2. Show both capture modes and explain the source cleanup effect before persisting the choice.
3. Create a sibling worktree from committed `HEAD` on `prototype/<spec>/<id>`. Keep the current checkout unchanged.
4. Before dirty transfer, show every staged, unstaged, and untracked path from `git status --porcelain=v1`. Transfer only paths named in the user's exact approval. Reject symlinks and paths outside the repository, then verify the isolated diff matches the approved path set.
5. If retained isolation fails, ask whether to wait, cancel, or select eligible ephemeral scratch. Limit scratch to one self-contained logic HTML file.

Quick mode classifies capture without a prompt and never transfers dirty paths. Use retained source when partial work can matter. Use ephemeral scratch only for a self-contained logic file.

## Control the builder

1. Spawn one internal child agent with the prototype-builder contract and the recorded isolation path.
2. Store only its `agentId` in `harnessRun`. Use `wait_agent` for bounded waits and `interrupt_agent` at the hard deadline. Never use `create_thread`, a user-visible task, or `threadId` for an internal builder.
3. Map launch, wait, heartbeat, interrupt, and status results to the deterministic `prototype_harness.py` contract. Persist the agent ID, heartbeat, deadlines, request attempt, and builder execution attempt through the locked helper.
4. Extend the rolling deadline only for recorded activity and never beyond the hard deadline. Release the lease after completion, timeout, or interruption.
5. After the configured normal execution count, ask whether to retry, record failure, or cancel. Quick mode permits one initial execution and one mechanical retry at most.
6. If child controls are unavailable, ask normal mode to wait or cancel before launch. Publish a failed quick record and continue to design.

## Decide and hand off

Normal mode has two user-owned checkpoints without an automatic timeout:

1. Present the question, run instructions, cases or variants, evidence, and limits. Ask for `validated`, `rejected`, or `inconclusive`.
2. Ask whether to include or exclude supported evidence, resume unchanged, or revise the earliest affected artifact. Record every stale artifact and task index created by revision.

Set `gateApproved: true` only for a normal `validated` or `rejected` result that the user includes. Exclude cancelled, failed, skipped, inconclusive, malformed, and superseded records.

Quick mode owns the verdict and handoff. Select the highest-risk grounded question, or publish `skipped` with `sourceDisposition: not_created` when none exists. Quick `validated` and `rejected` records may feed design. Every quick result continues to design.

Before design, tasks, or implementation, run `select-downstream`. Block dependent work for active blockers, stale artifacts, or stale task indexes. Apply the recorded handoff before resuming `returnPhase` or `returnTaskIndex`.

## Review, cleanup, and publish

1. Render one exclusive candidate with `render-candidate`.
2. Send `artifactType: prototype`, the exact candidate bytes, source, evidence, and hashes to the reviewer. Continue only after `REVIEW_PASS` for those bytes.
3. Store the review receipt with `review-candidate`, including evidence and cleanup hashes when applicable.
4. Publish without overwrite through `publish`. Re-read and parse the final, compare its hash with the reviewed candidate, then reconcile. Remove the active entry only after final-byte verification.
5. Preserve collisions and malformed or mismatched bytes. Quarantine them or allocate a superseding ID through the record helper.

Normal deletion requires a separate confirmation naming the exact path and local branch. Cancellation and interruption preserve source. Never delete a remote branch.

Quick ephemeral deletion is the sole automatic deletion exception:

1. Review evidence while source exists and write a cleanup receipt with candidate hash, evidence hash, exact isolation path, branch, base commit, and provenance.
2. Re-read the receipt, active entry, and provenance marker. Delete only the exact recorded scratch path or sibling worktree and exact local ephemeral branch.
3. Verify source absence. Render final bytes with `sourceDisposition: deleted` and the receipt hash.
4. Send those exact bytes and the verified receipt for another review. `REVIEW_PASS` must verify receipt hash, path, provenance, unchanged evidence hash, and source absence.
5. Publish only the reviewed post-deletion bytes. On any mismatch, retain source or publish a failed record without downstream evidence.

On resume, reconcile first. When a receipt exists and source is missing, render and review the exact deleted-source bytes before publication.

## Cancel and return

At the next safe boundary, interrupt a live child through `interrupt_agent`, release its lease, and publish an immutable `cancelled` record. Preserve source, partial implementation, origin phase, return phase, return task index, and downstream artifacts. Remove the active entry only after final verification.

Apply the selected normal handoff and resume the recorded phase or task. Continue every quick terminal outcome to design. Report the final record, source disposition, downstream inclusion, and local branch. Mark every remote pointer `pending authorization` until the user authorizes that exact write.
