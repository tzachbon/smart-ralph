# Ralph Specum Project Guidance

Use Ralph Specum as the spec workflow for this repo.

## Preferred Entry Surface

- `$ralph-specum` for the general flow
- `$ralph-specum-start` to create, resume, or run in quick mode. Only exact `--quick` enables quick mode; exact `--interactive` clears it
- `$ralph-specum-research`
- `$ralph-specum-requirements`
- `$ralph-specum-prototype` to run, resume, quick-run, or cancel an optional prototype
- `$ralph-specum-design`
- `$ralph-specum-tasks`
- `$ralph-specum-implement`
- `$ralph-specum-status`

## Project Contract

- Specs live in `./specs` unless `.claude/ralph-specum.local.md` defines `specs_dirs`
- `.current-spec` lives in the default specs root
- `.ralph-state.json` is transient execution state
- Prototype work stays in the `activePrototypes` overlay; the main `phase` never becomes `prototype`
- `.progress.md` persists learnings and blockers

## Flow

1. Start or resume a spec, then grill critical goal decisions
2. Approve the phase plan and delegate research
3. Approve the artifact, request changes, or continue to requirements
4. Grill, approve, and delegate requirements
5. Approve the artifact, request changes, or continue to design
6. Grill, approve, and delegate design
7. Approve the artifact, request changes, or continue to tasks
8. Grill, approve, and delegate tasks
9. Approve the artifact, request changes, or continue to implementation
10. Implement

Exact `--quick` may generate missing artifacts and continue straight into implementation in one run. Natural-language requests and `-q` do not enable quick mode.

## Prototype Overlay

The `references/` and `scripts/` paths below are relative to the installed Ralph Specum Codex plugin. Read `references/workflow.md` for entry and handoff, `references/path-resolution.md` for custom roots, and `references/state-contract.md` before any state mutation or recovery.

1. Offer `decline and continue` or `continue to prototype` after research and requirements. Route direct requests to `$ralph-specum-prototype`; normal mode proceeds after the user chooses.
2. Resolve `basePath` with `scripts/resolve_spec_paths.py`. Use `scripts/locked_state.py` or the `merge_state.py` compatibility wrapper for state, `scripts/prototype_records.py` for records, and `scripts/prototype_harness.py` for builder control. Derive every state and record path from the returned `basePath`.
3. Delegate source work to a child agent and store its `agentId` before waiting. Internal builders do not use `create_thread` or a `threadId`.
4. Keep source in a sibling worktree or eligible scratch path. Keep the current checkout on its existing branch. Quick mode copies no dirty work; normal mode transfers only approved paths. Verify that source exists only at the recorded isolation path.
5. Review exact candidate bytes, publish the immutable local record under `<basePath>/prototypes/`, then remove the active entry under lock. Finish after the final hash matches and the return phase or task is restored. Preserve retained source. Require separate authority for remote actions.

Quick mode runs one request after requirements, asks no user questions, takes over the oldest design blocker or selects the highest-risk grounded question, and continues to design. `$ralph-specum-start --resume <id>`, `$ralph-specum-prototype --resume <id>`, and `$ralph-specum-status` expose recovery. Normal deletion requires exact approval. Quick deletion covers only reviewed ephemeral isolation.

Before every push, apply the installed plugin's Prototype Evidence Push Gate: inspect the exact outbound commits for `**/prototypes/*.md`. If records appear, normal mode requires separate explicit authorization naming every exact record path. `commitSpec` and generic branch or PR approval do not count. Quick mode asks no question and skips every push. Never push an isolated `prototype/<spec>/<id>` source branch. Preserve existing non-prototype push behavior.
