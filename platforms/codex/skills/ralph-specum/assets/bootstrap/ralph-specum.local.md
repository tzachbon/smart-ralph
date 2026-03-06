---
enabled: true
default_max_iterations: 5
auto_commit_spec: true
quick_mode_default: false
specs_dirs:
  - "./specs"
---

# Ralph Specum Configuration

Use this file to configure Codex or Claude Ralph Specum flows for this project.

## Notes

- Add more entries to `specs_dirs` for monorepos
- Set `auto_commit_spec` to `false` if spec artifact commits should stay manual
- Set `quick_mode_default` to `true` only if this repo prefers fast one-shot spec generation
