---
name: ralph-specum-start
description: This skill should be used when the user asks to start or resume Ralph Specum work in Codex, create a new Ralph spec, run quick mode, use the `new` alias, or mentions "$ralph-specum-start".
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

1. Resolve the target by explicit path, exact name, or `.current-spec`.
2. If the same name exists in multiple configured roots, stop and require a full path.
3. `new` is an alias here. Create the spec directory if needed.
4. Initialize or merge state with:
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
   - `awaitingApproval: false`
5. Update `.current-spec`.
6. Write `.progress.md` with goal, current phase, next step, blockers, and learnings.
7. In quick mode, generate missing artifacts in order and continue into implementation in the same run.

## Branch Isolation

- If the user wants isolation, offer a feature branch in place or a worktree with a feature branch.
- If a worktree is created, stop after creation and tell the user to continue from that worktree.
