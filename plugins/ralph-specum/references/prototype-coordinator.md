# Prototype Coordinator

Use this procedure for direct, suggested, resumed, quick, and cancelled prototype requests. The prototype is an overlay in `activePrototypes`; it does not add a main phase value.

## Invariants

- Resolve the active spec before every operation. Use `ralph_resolve_context` from `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/path-resolver.sh` and use its `basePath`, `specRoot`, validated settings, and warnings.
- Keep the current main `phase` unchanged while a prototype is active. Store `triggerPhase`, `returnPhase`, and `returnTaskIndex` in the active entry.
- Never switch the current checkout. Run source work in the recorded isolation path.
- Use `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py` for state changes, `prototype-records.py` for record operations, and `prototype-harness.py` for builder control. Do not write state, candidates, or final records by hand.
- Stop at a safe tool boundary. Do not interrupt a running tool call. Preserve unrelated work and state fields.
- Keep source and evidence local. A local source commit does not authorize a push, PR change, issue write, or remote branch publication.

## Resolve the request

1. Parse one mode:
   - `direct`: the default explicit command. Preserve the current phase as `returnPhase`.
   - `suggested`: a research or requirements walkthrough supplied `--suggested --return-phase <phase>`. Record that next phase without entering it yet.
   - `resume`: `--resume <id>`, one active entry, or an explicit active ID continues the recorded status.
   - `quick`: `--quick` runs one agent-owned request after requirements and sets `returnPhase: design`.
   - `cancel`: `--cancel <id>` starts terminal cancellation at the next safe boundary.
2. Fail if `basePath` is null or the resolved directory does not exist.
3. Read `.ralph-state.json`, then run record reconciliation before selecting or reserving an entry.
4. Snapshot the resolved settings and `configWarnings` in a new active entry. Resume uses the stored snapshot.

Use these task 1.16-compatible forms for the common reservation and publication path:

```bash
python3 "$STATE_HELPER" merge --state "$STATE_FILE" --set "phase=requirements"
python3 "$STATE_HELPER" upsert-prototype --state "$STATE_FILE" --id "$ID" --entry-json "$ENTRY_JSON"
python3 "$RECORD_HELPER" render-candidate --base-path "$BASE_PATH" --record-json "$RECORD_JSON"
python3 "$RECORD_HELPER" publish --base-path "$BASE_PATH" --id "$ID"
python3 "$RECORD_HELPER" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
```

The prototype command does not use the first `merge` example to change the main phase. It shows the exact helper interface exercised by the end-to-end checkpoint. `upsert-prototype` is create-only and exclusive: use it once to reserve a new ID, and treat an existing ID as a collision. After reservation, mutate the entry only with `transition` using its expected `stateRevision` and expected status.

## Reserve or resume

1. Build a normalized question hash and blocker target before reserving an ID.
2. For the same question hash and blocker target, offer resume, supersede, or a distinct record in normal mode. Quick mode applies the approved duplicate rules and counts the result as its one request.
3. For incompatible evidence against one blocker target, create a conflict set. Normal mode blocks dependent work until the user or bounded conflict policy resolves it. Quick mode chooses supported evidence or excludes the set, records the resolution, and continues.
4. An explicit ID resumes that entry. One active entry resumes without another choice. List several active entries for normal selection; quick takes over the oldest blocking entry.
5. Reserve a new ID through create-only `upsert-prototype`. Update an existing entry only through compare-and-set `transition`; never call `upsert-prototype` as an update operation or replace the full state object.
6. Claim builder ownership with the expected ID, revision, and status. Persist the returned `leaseToken`, and pass that exact token to every `heartbeat`, `renew-lease`, and `release-lease` call. On a token or revision mismatch, reload state and join, resume, or report the current owner without launching another builder.

## Resolve record conflicts

Start conflict-decision runtime only when two or more live or terminal records affect the same downstream target and contain incompatible evidence or handoff rules. Ordinary normal verdict and handoff waits have no deadline.

1. In normal mode, calculate the interval as half the resolved initial builder timeout, including approved transfer-path additions, then clamp it between `prototype_conflict_timeout_min_minutes` and `prototype_conflict_timeout_max_minutes`. Quick timeout is 0 minutes.
2. Initialize `decisionDeadline`, `resolvedAt: null`, `conflictResolutionAttempt: 0`, and `maxConflictResolutionRetries` from `prototype_conflict_resolution_retries` with one locked compare-and-set `transition`.
3. A user message, verdict or handoff choice, reviewer start, or reviewer result may reset `decisionDeadline` once. Persist the reset marker and new deadline with the expected `stateRevision`; later activity does not reset it.
4. Evaluate expiry at the first later safe boundary: prototype, start, status, phase generation, implementation dispatch or loop, or stop-hook continuation. No background scheduler is assumed.
5. At expiry, increment `conflictResolutionAttempt` with a locked compare-and-set `transition`, rerun downstream selection, and apply reviewer-passed runnable evidence, target relevance, recorded observations, source disposition, and run instructions. A verdict label alone never selects the winner.
6. Retry a transient selection, candidate-parse, or reviewer-evidence failure only while `conflictResolutionAttempt <= maxConflictResolutionRetries`. The configured default of 0 permits the first automatic attempt and no retry.
7. Record `resolvedAt` through locked compare-and-set before rendering the immutable resolution record. Normal mode keeps dependent work blocked after failed resolution. Quick mode writes an exclusion record, excludes all unsupported conflicting evidence, and continues.
8. If a normal user reply arrives after expiry, publish the automatic resolution first. Then let the user create a new immutable record that supersedes that resolution.

## Choose capture and isolation

Normal mode keeps the user in control:

1. Recommend `retained` for app-integrated, multi-file, authenticated, real-data, or expensive source. Recommend `ephemeral` for a self-contained logic experiment.
2. Show both choices and explain that ephemeral source can be deleted only after a separate exact-path approval.
3. Create a sibling worktree from committed `HEAD` on `prototype/<spec>/<id>` by default. Do not check out that branch in the current conversation checkout.
4. Before transferring dirty work, show every staged, unstaged, and untracked path from `git status --porcelain=v1`. Transfer only paths the user names in an exact approval. Reject symlinks and paths outside the repository. Verify the isolated diff contains the approved path set only.
5. If retained isolation fails, ask whether to wait, cancel, or explicitly select eligible ephemeral scratch. Scratch supports one self-contained logic HTML file only.

Quick mode classifies capture without a prompt. It uses retained source for app routes, multiple files, authentication, real data, or valuable partial work. It may use ephemeral scratch only for a self-contained logic file. Quick never transfers dirty paths.

## Build under bounded control

1. Delegate source work to `prototype-builder` in the recorded isolation path.
2. Launch, wait, heartbeat, interrupt, and inspect status through the harness helper. Store its run ID, name, heartbeat, deadline, request attempt, and builder execution attempt in the active entry. Pass the claimed `leaseToken` to each state heartbeat, lease renewal, and release.
3. Extend the rolling deadline only for recorded activity and never beyond the hard deadline. At the hard deadline, interrupt the builder and release its lease.
4. Normal mode follows the configured builder execution count, then asks whether to retry, record failure, or cancel. Quick allows one initial execution and one mechanical retry at most.
5. If control is unavailable, normal mode asks the user to wait or cancel before launch. Quick publishes a failed record and continues to design.

Example bounded calls:

```bash
python3 "$HARNESS_HELPER" wait --registry "$HARNESS_REGISTRY" --id "$ID" --until-seconds "$REMAINING_SECONDS"
python3 "$HARNESS_HELPER" heartbeat --registry "$HARNESS_REGISTRY" --id "$ID"
python3 "$HARNESS_HELPER" interrupt --registry "$HARNESS_REGISTRY" --id "$ID"
python3 "$HARNESS_HELPER" status --registry "$HARNESS_REGISTRY" --id "$ID"
```

## Decide and hand off

Normal mode has two user-owned checkpoints with no automatic timeout:

1. Show the question, run instructions, cases or variants, evidence, and builder limits. Ask for `validated`, `rejected`, or `inconclusive`.
2. Ask whether downstream work should include or exclude supported evidence, resume unchanged, or revise the earliest affected artifact. Record stale artifacts and task indexes for revision.

Only an explicitly included normal `validated` or `rejected` result gets `gateApproved: true`. Cancellation, failure, skipped, inconclusive, excluded, malformed, and superseded records stay out of downstream input.

Quick owns the verdict and handoff. It selects the highest-risk grounded falsifiable question, or publishes `skipped` with `sourceDisposition: not_created` when none exists. Quick `validated` and `rejected` results may feed design; other verdicts do not. Every quick outcome continues to design, including duplicate, conflict, timeout, lock failure, builder failure, and skip.

## Review, cleanup, and publish

1. Render an exclusive candidate with `render-candidate`.
2. Give `spec-reviewer` `artifactType: prototype`, the exact candidate bytes, source, run evidence, and hashes. Continue only after `REVIEW_PASS` for those bytes.
3. Record the passed candidate with `review-candidate --base-path "$BASE_PATH" --id "$ID" --candidate-hash "$CANDIDATE_HASH"`. Supply the evidence hash and cleanup receipt when applicable.
4. Publish with no overwrite through `publish`. Re-read and parse the final, compare its hash with the reviewed candidate, then reconcile. Remove the active entry only after final verification.
5. On collision, malformed final, or mismatched candidate, preserve the bytes, quarantine or allocate the next ID through the record helper, and resume from recorded state.

Normal deletion requires a separate confirmation that names the exact scratch or worktree path and local branch. Cancellation and interruption preserve source. Never delete a remote branch.

Quick ephemeral deletion is the sole automatic deletion exception:

1. Review the evidence while source exists and write a durable cleanup receipt with the candidate hash, evidence hash, exact isolation path, branch, base commit, and provenance.
2. Re-read the receipt, active entry, and provenance marker. Delete only the exact recorded scratch path or sibling worktree and its exact local ephemeral branch.
3. Verify source absence. Render new final candidate bytes with `sourceDisposition: deleted` and the receipt hash.
4. Give the reviewer those exact bytes and the verified receipt. `REVIEW_PASS` must verify the receipt hash, path, provenance, unchanged evidence hash, and source absence.
5. Publish only the reviewed post-deletion bytes. If any check fails, retain the source or publish a failed result without downstream evidence.

On resume, reconcile first. If a cleanup receipt exists and source is missing, render and review the exact deleted-source bytes before publication. A receipt never substitutes for review.

## Cancel and return

At the next safe boundary, interrupt a live builder through the harness, release its lease, and publish an immutable `cancelled` record. Preserve source, partial implementation, origin phase, return phase, return task index, and downstream artifacts. Remove the active entry only after final verification. Restore the recorded phase and task index without changing unrelated state.

After any normal terminal outcome, apply the selected handoff and return to the recorded phase or task. After any quick terminal outcome, continue to design. Report the terminal record path, source disposition, downstream inclusion, and local branch. Never push an isolated prototype source branch. Before any other push, inspect the exact outbound commits for `**/prototypes/*.md`. If records are present, normal mode may ask at that boundary for separate explicit authorization naming every exact record; `commitSpec` and generic push or PR approval do not count. Quick mode never asks and never pushes. Label every remote pointer `pending authorization` until the user separately approves the exact remote action.
