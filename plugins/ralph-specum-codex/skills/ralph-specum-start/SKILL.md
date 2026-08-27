---
name: ralph-specum-start
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-start`, or explicitly asks Ralph Specum in Codex to start or resume a spec.
metadata:
  surface: helper
  action: start
---

# Ralph Specum Start

Use this for the `start` and `new` entrypoints.

## Contract

- Read `.claude/ralph-specum.local.md` when present
- Default specs root is `./specs`
- Keep `.current-spec` in the default specs root
- Keep the standard Ralph files stable
- Merge `.ralph-state.json`. Do not replace the full object

## Action

1. Parse explicit name, goal, exact `--quick` or exact `--interactive`, commit flags, optional specs root, and optional `--tasks-size fine|coarse`. Reject both mode flags together, `-q`, variants, and natural-language substitutes.
2. Resolve the target by explicit path, exact name, or `.current-spec`.
3. If the same name exists in multiple configured roots, stop and require a full path.
4. Check active epic context from `specs/.current-epic` when no explicit spec was chosen.
5. For large or cross-cutting goals, route to triage instead of forcing a single spec.
6. `new` is an alias here. Create the spec directory if needed.
7. Initialize or merge state with:
   - `source: "spec"`
   - `name`
   - exact `goal` text used by the context gate
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
   - `awaitingApproval: false` while the goal interview is active
   - preserve or set `quickMode`
   - preserve or set `granularity` when `--tasks-size` was supplied
   - preserve or set `epicName` when starting from an epic suggestion
8. Update `.current-spec`.
9. Write `.progress.md` with goal, current phase, next step, blockers, learnings, and skill discovery results.
10. On resume, prefer `tasks.md` and present files over stale state when they disagree.
11. Run `scripts/phase_gate.py mode STATE` with the exact supplied mode flag. No flag normalizes invalid legacy quick state to interactive.
12. Run skill discovery pass 1 against the goal. Collect plugin skills, project `.agents/skills`, project `.claude/skills`, and the current Codex harness catalog. Always select explicitly named skills and record shadowed duplicates.
13. Load `skills/interview-framework-codex/SKILL.md`, its required algorithm reference, and every selected domain contract in both interactive and quick mode. In interactive mode, follow that algorithm for the start goal territory: outcome and observable success, material scope boundaries, critical constraints, and viable high-level approach. Ask no spec-path, branch, task-size, or discoverable question.
14. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating a `research-analyst` child.
15. Pass the absolute helper path, state path, identity tuple, a unique teammate dispatch identity, and the verbatim `phaseSkillLoad` manifest. The child must record its loads and pass `check-agent-write` with that unique identity before writing `research.md`.
16. Validate `research.md`, merge `phase: "research"` and `awaitingApproval: true` in interactive mode or `false` in exact quick mode, update progress, and present artifact approval when interactive.
17. In exact quick mode, record the quick bypass, generate missing artifacts in order, skip normal approval pauses, and continue into implementation in the same run.

## Branch Isolation

- If the user wants isolation, offer a feature branch in place or a worktree with a feature branch.
- If a worktree is created, stop after creation and ask the user to continue from that worktree.

## Response Handoff

- After setup in normal mode, begin the goal grill in the same run.
- After final `approve and delegate`, dispatch research in the same turn.
- After `research.md`, name the file, summarize it, and end with exactly one artifact approval prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to requirements`
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
