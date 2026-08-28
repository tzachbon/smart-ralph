# Ralph Path Resolution

## Settings Source

Read `.claude/ralph-specum.local.md` when it exists.

Relevant frontmatter keys:

- `specs_dirs`
- `default_max_iterations`
- `auto_commit_spec`
- `prototype_lock_timeout_seconds` and `prototype_quick_lock_timeout_seconds`
- prototype logic/UI, activity-extension, hard-deadline, conflict, transfer-path, and builder-execution limits

## Default Behavior

- default specs root: `./specs`
- current spec marker: `<default-specs-root>/.current-spec`
- ignore unknown or deprecated settings keys, including `quick_mode_default`

## `.current-spec` Rules

- bare name means `<default-root>/<name>`
- path starting with `./` or `/` means full path

## Ambiguity Rules

When a spec name exists in multiple roots:

- do not guess
- show the matching full paths
- require the user to pick the full path

## Script Usage

Use `scripts/resolve_spec_paths.py`.

Examples for this source repo, run them from the repo root:

```bash
python3 ./plugins/ralph-specum-codex/scripts/resolve_spec_paths.py --cwd "$PWD"
python3 ./plugins/ralph-specum-codex/scripts/resolve_spec_paths.py --cwd "$PWD" --current
python3 ./plugins/ralph-specum-codex/scripts/resolve_spec_paths.py --cwd "$PWD" --name api-auth
python3 ./plugins/ralph-specum-codex/scripts/resolve_spec_paths.py --cwd "$PWD" --list
```

Exit behavior:

- `--name` returns `0` for a unique match
- `--name` returns `1` when no spec matches
- `--name` returns `2` when multiple specs match

The default JSON output also includes `specRoot`, `basePath`, validated `prototype_settings`, and ordered `configWarnings`. Prototype coordinators, record helpers, state helpers, hooks, status, and indexing use that resolved `basePath`; they never reconstruct `specs/<name>`. A resumed entry uses its stored configuration snapshot.

## Listing Rules

- Only existing spec directories count in `--list`
- Hidden directories are ignored
- Missing configured roots do not stop resolution
- Prototype paths may be in any configured root and remain local to that resolved spec
