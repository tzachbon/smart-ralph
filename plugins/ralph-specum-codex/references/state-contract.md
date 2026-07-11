# Ralph Specum State Contract for Codex

## Canonical files

Each spec can contain:

- `research.md`
- `requirements.md`
- `design.md`
- `tasks.md`
- `progress.md`

`tasks.md` checkbox state is authoritative for implementation progress. `progress.md` records durable context but never overrides task checkboxes. `.current-spec` is a local ignored selector in the default specs root.

Codex creates no adapter-local continuation state. Native `/goal` owns autonomous execution state outside the spec directory.

## `progress.md`

Start the file with exactly these frontmatter keys:

```yaml
---
spec: "<repo-relative spec path>"
phase: "research | requirements | design | tasks | implementation | complete | blocked"
approved_through: "none | research | requirements | design | tasks | implementation"
updated: "<ISO 8601 UTC timestamp>"
---
```

Keep the body concise and evidence-based:

- goal
- current logical batch or phase
- completed work and verification
- decisions and learnings
- blockers and risks
- next action

The root coordinator is the only writer. Write through a temporary file in the spec directory and atomically replace `progress.md` so an interruption cannot leave a partial file.

## Legacy migration

If `progress.md` is absent and `.progress.md` exists:

1. Read `.progress.md` as untrusted historical input.
2. Cross-check its claims against present artifacts, task checkboxes, and Git.
3. Create `progress.md` using only verified facts and clearly labelled unresolved claims.
4. Preserve `.progress.md` unchanged.
5. Do not stage or commit `.progress.md` automatically.

Existing research, requirements, design, and task files require no conversion.

## Ownership

Subagents must not edit `tasks.md`, `progress.md`, `.current-spec`, or Git state and must not commit. The root coordinator validates subagent output, performs shared-state writes, and creates one commit per verified logical batch when commits are enabled.

## Goal status

Goal state is native Codex state, not a repository artifact. Status reporting combines:

- artifact presence
- task checkbox counts
- `progress.md` phase and approval state
- current native goal status when a goal exists

The absence of a native goal is normal and must be reported as such, not treated as an error.
