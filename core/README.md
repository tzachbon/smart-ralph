# Ralph Specum shared core

This directory contains platform-neutral specification assets and contracts.
Users install one of the self-contained plugins under `plugins/`. The core is a
build-time source of truth and is not a runtime dependency of either plugin.

Run `python3 scripts/sync-core-assets.py` after changing a shared template or
schema. Run the command with `--check` in verification and CI.

Platform orchestration remains hand-written in each plugin. Only files listed
by the sync tool are generated into both adapters. Configuration templates,
commands, skills, agents, hooks, and native reference text remain adapter-owned.
