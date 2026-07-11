# Ralph Specum Path Resolution for Codex

## Project settings

Read `.codex/ralph-specum.local.md` when it exists. Supported frontmatter keys are `specs_dirs` and `auto_commit_spec`.

The default specs root is `./specs`. The first configured root is the default root. Keep `.current-spec` in that root.

## Resolution rules

- Resolve the repository root before reading settings or writing any file.
- Reject configured roots and explicit spec paths that escape the repository root.
- A bare `.current-spec` value means `<default-root>/<name>`.
- A repo-relative path identifies a non-default-root spec.
- When the same exact name exists in multiple roots, show the matches and require a path.
- Ignore hidden directories when listing specs.

## Installed helper

From any Ralph phase skill, the resolver is at `../../scripts/resolve_spec_paths.py` relative to that skill directory. Resolve that path before invoking it. Do not assume the plugin source repository exists.

Typical invocations from a consumer repository are:

```bash
python3 <resolved-plugin-script> --cwd "$PWD"
python3 <resolved-plugin-script> --cwd "$PWD" --current
python3 <resolved-plugin-script> --cwd "$PWD" --name api-auth
python3 <resolved-plugin-script> --cwd "$PWD" --list
```

`--name` returns 0 for one match, 1 for no match, and 2 for ambiguous matches.
