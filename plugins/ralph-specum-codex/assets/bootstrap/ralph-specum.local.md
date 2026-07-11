---
enabled: true
auto_commit_spec: true
specs_dirs:
  - "./specs"
---

# Ralph Specum Configuration

Install this file as `.codex/ralph-specum.local.md` to configure Ralph Specum for this Codex project.

## Notes

- Add more entries to `specs_dirs` for monorepos
- Set `auto_commit_spec` to `false` if spec artifact commits should stay manual.
- Autonomous execution must come from explicit user wording and uses native `/goal`.
