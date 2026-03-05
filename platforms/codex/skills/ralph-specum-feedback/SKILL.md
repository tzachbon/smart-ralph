---
name: ralph-specum-feedback
description: This skill should be used when the user asks to send Ralph feedback in Codex, report a Ralph issue, draft an issue for this project, or mentions "$ralph-specum-feedback".
metadata:
  surface: helper
  action: feedback
---

# Ralph Specum Feedback

Use this to capture product feedback or bug reports for Ralph Specum.

## Action

1. Summarize the issue, request, or missing behavior.
2. Gather the minimum reproducible context, affected files, commands, and environment details.
3. If `gh` is available and the user wants submission, create a GitHub issue draft or issue.
4. If `gh` is unavailable or the user only wants a draft, produce a ready-to-paste issue body and the repository issue URL.

## Output

Keep the report concrete. Include expected behavior, actual behavior, reproduction steps, and any relevant state files or logs.
