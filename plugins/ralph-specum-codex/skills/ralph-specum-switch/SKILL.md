---
name: ralph-specum-switch
description: Compatibility shim for the deprecated Ralph Specum switch skill. Use only when the user explicitly invokes `$ralph-specum-switch`.
---

# Ralph Specum Switch Compatibility Shim

Warn that `$ralph-specum-switch` is deprecated in v5 and removed in v6. Load `../ralph-specum/SKILL.md` relative to this file, then route the request to `$ralph-specum` with the intent `switch active spec`. Preserve ambiguity checks and update only the default root's `.current-spec`.
