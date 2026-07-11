---
name: ralph-specum-help
description: Compatibility shim for the deprecated Ralph Specum help skill. Use only when the user explicitly invokes `$ralph-specum-help`.
---

# Ralph Specum Help Compatibility Shim

Warn that `$ralph-specum-help` is deprecated in v5 and removed in v6. Load `../ralph-specum/SKILL.md` relative to this file, then route the request to `$ralph-specum` with the intent `explain the native Codex workflow and first-class phase skills`.
