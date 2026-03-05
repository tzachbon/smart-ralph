---
name: ralph-specum-index
description: This skill should be used when the user asks to index a codebase for Ralph Specum in Codex, generate `specs/.index` artifacts, scan components or external resources, or mentions "$ralph-specum-index".
metadata:
  surface: helper
  action: index
---

# Ralph Specum Index

Use this to generate searchable index specs for an existing codebase.

## Contract

- Index output lives under `specs/.index/`
- Use stable Ralph templates for `index.md`, component specs, and external specs
- Keep component and external entries deterministic and easy to diff

## Action

1. Parse the user scope such as path, types, excludes, quick mode, dry run, or force.
2. Scan the requested code areas for controllers, services, models, helpers, migrations, or comparable project structures.
3. Generate or update:
   - `specs/.index/index.md`
   - `specs/.index/components/*.md`
   - `specs/.index/external/*.md`
4. Keep outputs deterministic so start, research, and triage can reuse them.
5. Include external URLs, MCP endpoints, or installed skills only when the user asked for them or they are clearly relevant.
6. In dry run mode, report what would be created without writing files.
