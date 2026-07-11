---
name: ralph-specum-cancel
description: Compatibility shim for the deprecated Ralph Specum cancel skill. Use only when the user explicitly invokes `$ralph-specum-cancel`.
---

# Ralph Specum Cancel Compatibility Shim

Warn that `$ralph-specum-cancel` is deprecated in v5 and removed in v6. Load `../ralph-specum/SKILL.md` relative to this file, then route the request to `$ralph-specum` with the intent `stop the current native goal or remove a spec`. Stopping a goal must use the native goal surface. Confirm before deleting any spec files.
