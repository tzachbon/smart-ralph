---
name: ralph-specum-refactor
description: Compatibility shim for the deprecated Ralph Specum refactor skill. Use only when the user explicitly invokes `$ralph-specum-refactor`.
---

# Ralph Specum Refactor Compatibility Shim

Warn that `$ralph-specum-refactor` is deprecated in v5 and removed in v6. Load `../ralph-specum/SKILL.md` relative to this file, then route the request to `$ralph-specum` with the intent `reconcile spec artifacts with verified implementation learnings`.
