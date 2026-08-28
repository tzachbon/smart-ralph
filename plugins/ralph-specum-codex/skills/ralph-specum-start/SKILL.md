---
name: ralph-specum-start
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-start`, or explicitly asks Ralph Specum in Codex to start or resume a spec.
metadata:
  surface: helper
  action: start
---

# Ralph Specum Start

Use this for the `start` and `new` entrypoints.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Read `.claude/ralph-specum.local.md` when present
- Default specs root is `./specs`
- Keep `.current-spec` in the default specs root
- Keep the standard Ralph files stable
- Merge `.ralph-state.json`. Do not replace the full object

## Action

1. Parse explicit name, goal, `--quick`, `--resume <prototype-id>`, commit flags, optional specs root, and optional `--tasks-size fine|coarse`.
2. Classify new versus resume intent, then resolve the classified target by explicit path, exact name, or `.current-spec`. A new-spec request does not inherit or recover the existing current spec.
3. If the same name exists in multiple configured roots, stop and require a full path.
4. Check active epic context from `specs/.current-epic` when no explicit spec was chosen.
5. For large or cross-cutting goals, route to triage instead of forcing a single spec.
6. `new` is an alias here. Create the spec directory if needed.
7. Initialize or merge state with:
   - `source: "spec"`
   - `name`
   - `basePath`
   - `phase: "research"`
   - `taskIndex: 0`
   - `totalTasks: 0`
   - `taskIteration: 1`
   - `maxTaskIterations: settings default or 5`
   - `globalIteration: 1`
   - `maxGlobalIterations: 100`
   - `commitSpec: settings auto_commit_spec or true`
   - `relatedSpecs: []`
   - `awaitingApproval: true` when the run will stop after setup and wait for explicit direction
   - `awaitingApproval: false` when quick mode or explicit autonomy will continue without pausing
   - preserve or set `quickMode`
   - preserve or set `granularity` when `--tasks-size` was supplied
   - preserve or set `epicName` when starting from an epic suggestion
8. Update `.current-spec`.
9. Write `.progress.md` with goal, current phase, next step, blockers, learnings, and skill discovery results when used.
10. On resume, prefer `tasks.md` and present files over stale state when they disagree.
11. In quick mode, generate missing artifacts in order, skip normal approval pauses, and continue into implementation in the same run.
12. **Without quick mode or explicit autonomy: STOP HERE after setup. Do NOT proceed to research. Wait for the user to explicitly ask to continue.** This is non-negotiable.

## Prototype Reconciliation and Resume

After resolving the classified target and before normal resume or quick routing. Skip existing-current-spec recovery for new-spec intent:

1. Use `"$RALPH_CODEX_PLUGIN_ROOT/scripts/resolve_spec_paths.py"` and only its resolved `basePath`. When both `basePath` and `<basePath>/.ralph-state.json` exist, run `"$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" reconcile --base-path "$BASE_PATH" --state "$BASE_PATH/.ralph-state.json"`, then re-read state.
2. Treat a missing `activePrototypes` field as an empty map. Sort entries by `created`, then ID.
3. Resume an explicit active ID through `$ralph-specum-prototype --resume <id>` and stop this skill. In normal mode, resume the sole active entry automatically. When several remain, list deterministic IDs with question, status, blocker, `returnPhase`, and `returnTaskIndex`, then stop for an explicit ID.
4. In quick mode, ask no question. Sort entries that block design by `created`, then ID. At the post-requirements boundary, route through `$ralph-specum-prototype --quick`; the prototype skill takes over the oldest design blocker and owns every decision. Preserve earlier quick flow and unrelated entries.
5. Treat each `resume_review` candidate as recovery work, not terminal evidence. Parse the exact candidate, verify its ID and hash, and reconstruct a minimal recovery entry from the record and source pointers. Before reviewer dispatch, reserve its ID through create-only `locked_state.py upsert-prototype` with `status: reviewing`, the exact `candidateHash`, null owner and lease fields, a null or absent `harnessRun.id`, blocker and return fields, source pointers, and recovery timestamps. This is a recovery-only entry: cancellation verifies that `owner`, `leaseToken`, and `harnessRun.id` are all null or absent and that no builder is associated, then skips interrupt and release; inconsistent builder ownership fails closed. On a concurrent reservation, re-read and continue only if its `candidateHash` matches; never overwrite it. Route the restored entry through deterministic exact-candidate review and publish recovery. If reconstruction or reservation cannot proceed, stop and report the candidate ID and candidate hash. Exclude quarantined or malformed records. If no overlay exists, continue the existing start behavior without extra output.
6. Quick mode completes its automatic local route and does not reach the interactive Response Handoff below.

## Branch Isolation

- If the user wants isolation, offer a feature branch in place or a worktree with a feature branch.
- If a worktree is created, stop after creation and ask the user to continue from that worktree.

## Response Handoff

- After creating or resuming the spec, name the resolved spec path and summarize the current state briefly.
- In normal mode only, end with exactly one explicit choice prompt:
  - `request changes`
  - `continue to research`
- Do not run research until the user explicitly asks to continue or explicitly asked for quick or autonomous flow.
