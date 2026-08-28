---
name: ralph-specum-cancel
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-cancel`, or explicitly asks Ralph Specum in Codex to stop execution or remove a spec.
metadata:
  surface: helper
  action: cancel
---

# Ralph Specum Cancel

Use this to stop execution safely and optionally remove a spec. Safe cancel preserves the spec and every prototype source path.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Resolve the target by explicit path, exact name, or `.current-spec`
- Treat a missing `activePrototypes` field as an empty map
- Publish reviewed immutable cancellation evidence before removing active state
- Confirm the exact local target before any deletion
- Never delete a remote branch or perform another remote action
- Do not guess on ambiguous names

## Action

1. Resolve the target spec. If none exists, report that there is nothing to cancel.
2. Read `.ralph-state.json` when present and summarize the current phase and progress.
3. If `activePrototypes` is non-empty, use the resolved `basePath` and run `"$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" reconcile` before cancellation. Process active IDs by `created`, then ID, at the next safe tool boundary.
4. For each active prototype:
   - Inspect its `owner`, `leaseToken`, and `harnessRun.id`. When `owner` and `leaseToken` are both null or absent, verify that `harnessRun.id` is also null or absent and no builder is associated, then skip interrupt and release and continue cancellation. If those fields disagree, treat the entry as inconsistent builder ownership: retain the lease and active entry and stop for that ID. Otherwise, interrupt only its recorded child builder through the bounded harness contract. Release through `locked_state.py release-lease --id <id> --lease-token <leaseToken>` only after the harness verifies that the recorded builder and descendants stopped. If interruption is unavailable or unverified, or reports any failed termination attempt, retain the lease and active entry and stop cancellation for that ID.
   - Preserve its question, blocker, return phase and task, timestamps, local branch, isolation pointers, partial implementation, run evidence, stale metadata, and downstream artifacts.
   - Render an exclusive terminal candidate with `verdict: cancelled`, `gateApproved: false`, and `sourceDisposition: retained`. Never overwrite existing candidate or final bytes; allocate a new publication ID with `supersedes: ["<original-id>"]` on collision.
   - Before review, store the exact returned `candidateHash`. Update the existing original entry through compare-and-set `transition`, or reserve a separate superseding ID through create-only `locked_state.py upsert-prototype` with the copied recovery fields and exact `candidateHash`. Retain the original active entry unchanged while the superseding record is reviewed. A reservation collision preserves both entries and candidates and allocates another ID.
   - Send the exact candidate bytes and source pointers to the reviewer. Continue only after `REVIEW_PASS`, then call `review-candidate` and `publish` with the publication ID and exact candidate hash.
   - Re-read and parse the immutable final and verify its hash. Publication removes its own active publication entry. When a superseding ID was used, remove the original active entry only after final verification succeeds; any earlier failure retains it. Reconcile, then restore the recorded main phase and task index through `locked_state.py` without changing unrelated state.
5. Safe cancel is the default. After every active prototype has a verified immutable `cancelled` record, delete only `.ralph-state.json` through `locked_state.py delete-state`. Keep the spec directory, `.current-spec`, terminal records, prototype source, partial work, scratch paths, worktrees, and local branches.
6. If full removal was explicitly requested, show the resolved spec directory and every prototype isolation path and branch. Require confirmation naming the exact spec directory before removing it. Prototype paths and local branches require separate exact confirmations and are never included in recursive spec cleanup. Never delete a remote branch.
7. If no state exists, report that no active loop exists and remove nothing unless the exact full-removal confirmation is complete.
8. Keep active epic files unless the user separately requests their removal. Report exactly what was removed and what was preserved.
