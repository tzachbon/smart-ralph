# Migration to Ralph Specum v5

Version 5 keeps existing specs readable while separating Ralph into native Claude and Codex products backed by canonical shared artifacts.

## Claude Code

Claude command names and the `ralph-specum@smart-ralph` installation identity remain unchanged. Update the marketplace and plugin, restart Claude Code, then resume the existing spec normally.

Claude retains local hook continuation. Runtime state remains disposable and is reconstructed from the spec artifacts when needed.

## Codex

Codex 0.144.0 or newer is required.

```bash
codex plugin remove ralph-specum@smart-ralph
codex plugin marketplace upgrade smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

The plugin no longer registers a Stop hook and no longer requires custom agent TOML blocks. Explicit autonomous, quick, finish, or long-running requests use native `/goal`. Other implementation requests complete one verified logical batch.

The phase skills remain first-class. Auxiliary skills route to `$ralph-specum` with a version 6 deprecation warning.

## Progress migration

New and updated specs use tracked `progress.md` with `spec`, `phase`, `approved_through`, and `updated` frontmatter.

When only legacy `.progress.md` exists, Ralph may read it as migration input. It must create a concise reviewed `progress.md` containing stable goal, phase, completion, learning, blocker, and next-step information. It must not automatically commit or copy raw legacy logs.

`tasks.md` checkboxes remain the authoritative task completion state. `.current-spec` remains local. Codex runtime continuation no longer depends on `.ralph-state.json`.

## Version 6 removals

Version 6 removes Codex auxiliary skill shims, legacy `.progress.md` reading, old agent-config templates, and obsolete loop documentation.

## Rollback

Rollback uses a tagged marketplace checkout. Existing Markdown specs remain compatible with version 4, but version 4 ignores `progress.md`. Preserve it when rolling back.
