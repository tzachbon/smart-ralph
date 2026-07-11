---
name: ralph-specum-start
description: Create or resume a Ralph Specum spec in Codex. Use when the user invokes `$ralph-specum-start` or asks Ralph Specum to start, create, or resume a spec.
---

# Ralph Specum Start

1. Resolve the repository and spec roots with `../../scripts/resolve_spec_paths.py` relative to this skill.
2. Resolve an explicit path or exact name before `.current-spec`. Require a path when a name is ambiguous.
3. Route large dependency-heavy work to `$ralph-specum-triage`.
4. Create the spec directory when needed. Keep all paths inside the resolved repository.
5. Update the default root's local `.current-spec` selector.
6. Create `progress.md` with the frontmatter and body in `../../references/state-contract.md`.
7. If only `.progress.md` exists, perform the reviewed compatibility migration described in that reference. Preserve and never automatically commit the legacy file.
8. Detect the current phase from canonical artifacts and `tasks.md` checkboxes. Do not create runtime state.
9. In normal mode, summarize the resolved spec and stop for explicit direction.
10. For explicit autonomous, quick, finish, or long-running intent, route through `$ralph-specum` so native `/goal` owns continuation.

Never create adapter-local continuation state, install agent configuration, or rely on a hook.
