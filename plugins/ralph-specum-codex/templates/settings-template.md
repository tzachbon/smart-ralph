---
auto_commit_spec: true
specs_dirs:
  - "./specs"
---

# Ralph Specum Configuration for Codex

Configuration is optional. The plugin works immediately after installation with
`./specs` as its default root.

## Settings

### `auto_commit_spec`

Set to `false` when the root coordinator should leave verified spec artifact
changes uncommitted.

### `specs_dirs`

List one or more workspace-contained spec roots. The first entry is the default.
Paths that escape the project root, including symlink escapes, are rejected.

## Usage

Save overrides at `.codex/ralph-specum.local.md` in the project root.

```yaml
---
auto_commit_spec: false
specs_dirs:
  - "./specs"
  - "./packages/frontend/specs"
  - "./packages/backend/specs"
---

# Ralph Specum Configuration
```

Use `$ralph-specum-start` to create or resume a spec. Use
`$ralph-specum-status` to list progress across configured roots. When a spec
name exists in more than one root, Ralph reports the matching paths and asks
you to disambiguate.
