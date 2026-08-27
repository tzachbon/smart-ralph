---
description: Run or resume an optional prototype
argument-hint: "[spec-name] [--suggested --return-phase PHASE] [--resume ID] [--cancel ID] [--quick]"
allowed-tools: "*"
---

# Prototype

Coordinate one optional prototype overlay. Do not implement source work in this command.

1. Parse `$ARGUMENTS`. Accept direct invocation by default, `--suggested --return-phase <phase>`, `--resume <id>`, `--cancel <id>`, or `--quick`. A spec name may precede the mode.
2. Source `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/path-resolver.sh` and call `ralph_resolve_context`. If a spec name was supplied, replace the context `basePath` with the verified result from `ralph_find_spec` and set `specRoot` to its parent. Stop if `basePath` is null or missing.
3. Read `${CLAUDE_PLUGIN_ROOT}/references/prototype-coordinator.md` completely and follow it without reimplementing its mechanics.
4. Use only the resolved `basePath` and these helpers:
   - `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py`
   - `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py`
   - `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-harness.py`
5. Preserve the current main phase and current checkout while the overlay runs. Stop at safe tool boundaries. Require the exact normal-mode approvals for capture, dirty paths, verdict, handoff, deletion, and every remote action.
6. Store and resume the request in `activePrototypes` with `returnPhase` and any `returnTaskIndex`. Reconcile immutable records before dispatch or publication.
7. In quick mode, let the agent own all choices, keep the run bounded, review any post-deletion bytes, publish one terminal outcome, and continue to design without a user stop.
8. Never push source or evidence, update a remote issue, or publish a branch without separate explicit authorization.
