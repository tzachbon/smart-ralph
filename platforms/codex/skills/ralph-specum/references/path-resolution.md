# Ralph Path Resolution

## Settings Source

Read `.claude/ralph-specum.local.md` when it exists.

Relevant frontmatter keys:

- `specs_dirs`
- `default_max_iterations`
- `auto_commit_spec`
- `quick_mode_default`

## Default Behavior

- default specs root: `./specs`
- current spec marker: `<default-specs-root>/.current-spec`

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
python3 ./platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py --cwd "$PWD"
python3 ./platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py --cwd "$PWD" --current
python3 ./platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py --cwd "$PWD" --name api-auth
python3 ./platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py --cwd "$PWD" --list
```

Exit behavior:

- `--name` returns `0` for a unique match
- `--name` returns `1` when no spec matches
- `--name` returns `2` when multiple specs match

## Listing Rules

- Only existing spec directories count in `--list`
- Hidden directories are ignored
- Missing configured roots do not stop resolution
