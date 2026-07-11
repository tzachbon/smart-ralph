---
name: ralph-specum-feedback
description: Compatibility shim for the deprecated Ralph Specum feedback skill. Use only when the user explicitly invokes `$ralph-specum-feedback`.
---

# Ralph Specum Feedback Compatibility Shim

Warn that `$ralph-specum-feedback` is deprecated in v5 and removed in v6. Load `../ralph-specum/SKILL.md` relative to this file, then route the request to `$ralph-specum` with the intent `draft product feedback`. Do not submit external feedback without explicit user authorization.
