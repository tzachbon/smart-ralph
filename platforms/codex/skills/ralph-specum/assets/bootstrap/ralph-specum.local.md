---
enabled: true
default_max_iterations: 5
auto_commit_spec: true
specs_dirs:
  - "./specs"
---

# Ralph Specum Configuration

Use this file to configure Codex or Claude Ralph Specum flows for this project.

## Notes

- Add more entries to `specs_dirs` for monorepos
- Set `auto_commit_spec` to `false` if spec artifact commits should stay manual
- `quick_mode_default` is removed and ignored in this version
- Quick or autonomous flow must come from explicit user wording
