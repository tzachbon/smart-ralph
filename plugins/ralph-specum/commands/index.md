---
description: Index codebase components and external resources into searchable specs
argument-hint: [--path=dir] [--type=types] [--exclude=patterns] [--dry-run] [--force] [--changed] [--quick]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion, Glob, Grep, WebFetch, ListMcpResourcesTool]
---

# Index Command

You are running the codebase indexing command. This scans the repository to generate component specs in `specs/.index/`.

## Checklist

Use TaskCreate to track these steps:

- [ ] Parse arguments and validate
- [ ] Pre-scan interview (skip if --quick)
- [ ] Scan codebase components
- [ ] Fetch external resources (URLs, MCP, skills)
- [ ] Generate component and external specs
- [ ] Build index summary
- [ ] Post-scan review (skip if --quick)

## Step 1: Parse Arguments

Parse from `$ARGUMENTS`:

| Option | Format | Default | Description |
|--------|--------|---------|-------------|
| `--path` | `--path=<dir>` | Project root | Limit scan to directory |
| `--type` | `--type=<types>` | All | Comma-separated: controllers,services,models,helpers,migrations |
| `--exclude` | `--exclude=<patterns>` | See below | Comma-separated exclude patterns |
| `--dry-run` | Flag | false | Preview without writing |
| `--force` | Flag | false | Regenerate all (ignore existing) |
| `--changed` | Flag | false | Only git-changed files |
| `--quick` | Flag | false | Skip interviews, batch only |

**Default excludes**: `node_modules, vendor, dist, build, .git, __pycache__, *.test.*, *.spec.*, *_test.*, test/, tests/, spec/, specs/`

**Validation**: `--force` + `--changed` together is an error. `--path` must exist. `--type` values must be valid. `--changed` requires git (`git rev-parse --git-dir`).

## Step 2: Pre-Scan Interview

<mandatory>
**Skip if --quick flag is detected.**
</mandatory>

Ask via AskUserQuestion:

| # | Question | Key |
|---|----------|-----|
| 1 | External documentation URLs to index? | `externalUrls` |
| 2 | MCP servers or skills to document? | `externalTools` |
| 3 | Specific directories to focus on? | `focusAreas` |
| 4 | Code areas lacking comments needing extra attention? | `sparseAreas` |

Store responses in `./specs/.index/.index-state.json` under `interviewResponses`.

## Step 3: Component Scanner

### Detection Patterns

| Category | Glob Pattern | File Pattern |
|----------|-------------|--------------|
| Controllers | `**/controllers/**/*.{ts,js,py,go}` | `*controller*`, `*Controller*` |
| Services | `**/services/**/*.{ts,js,py,go}` | `*service*`, `*Service*` |
| Models | `**/models/**/*.{ts,js,py,go}` | `*model*`, `*Model*` |
| Helpers | `**/helpers/**/*.{ts,js,py,go}` | `*helper*`, `*Helper*`, `*util*` |
| Migrations | `**/migrations/**/*.{ts,js,sql}` | `*migration*` |

### Scanning Process

1. For each category (filtered by `--type` if set), run Glob with `--path` as base, filter out excludes
2. If `--changed`: filter to `git diff --name-only HEAD` results only
3. If not `--force` and spec exists: compare SHA-256 hash (first 8 chars via `shasum -a 256`), skip if unchanged
4. For each matched file, extract metadata using language-appropriate Grep patterns:
   - **Exports**: `export (const|function|class|interface|type) \w+` (TS/JS), `^def \w+\(` / `^class \w+` (Python), `^func \w+\(` (Go)
   - **Methods**: Class method signatures per language
   - **Dependencies**: import/require/from statements per language
5. For large codebases (>100 files): process in batches of 50, update state after each batch

## Step 4: External Resource Fetcher

Process resources from interview responses. Classify each: URL (`http(s)://`), MCP server (`mcp-*`/`mcp_*`), or Skill (`/` prefix or contains "skill").

### URL Processing

For each URL in `externalUrls`:
1. WebFetch with prompt to extract key sections, API endpoints, config options
2. Generate external spec from `templates/external-spec.md`
3. Write to `specs/.index/external/url-<sanitized-name>.md`
4. On timeout/error: warn and skip, continue processing

### MCP Server Processing

For each MCP server in `externalTools`:
1. ListMcpResourcesTool to discover tools and resources
2. Document each tool/resource in external spec
3. Write to `specs/.index/external/mcp-<server-name>.md`

### Skill Processing

For each skill in `externalTools`:
1. Read plugin manifests: `plugins/*/.claude-plugin/plugin.json`
2. Extract commands, agents, hooks from manifest
3. Write to `specs/.index/external/skill-<plugin>-<command>.md`

### File Naming

Pattern: `<type>-<sanitized-name>.md`. Sanitize: lowercase, replace non-alphanumeric with hyphens, collapse consecutive hyphens, max 50 chars.

## Step 5: Generate Specs

Ensure directories: `mkdir -p specs/.index/components specs/.index/external`

### Component Specs

For each scanned component:
1. If `--dry-run`: collect for preview, do NOT write
2. Load `templates/component-spec.md`, fill template variables:
   - `{{SOURCE_PATH}}`, `{{CONTENT_HASH}}`, `{{CATEGORY}}`, `{{TIMESTAMP}}`
   - `{{COMPONENT_NAME}}`, `{{AUTO_GENERATED_SUMMARY}}`, `{{EXPORTS}}`, `{{METHODS}}`
   - `{{DEPENDENCIES}}`, `{{KEYWORDS}}`, `{{RELATED_FILES}}`
3. Write to `specs/.index/components/<category>-<basename>.md`
4. Update hash in `.index-state.json`

**Naming**: `<singular-category>-<lowercase-basename>.md` (e.g., `controller-users.md`)

### External Specs

Load `templates/external-spec.md`, fill `{{SOURCE_TYPE}}`, `{{SOURCE_ID}}`, `{{FETCH_TIMESTAMP}}`, `{{RESOURCE_NAME}}`, `{{CONTENT_SUMMARY}}`, `{{SECTIONS}}`, `{{KEYWORDS}}`, `{{RELATED_COMPONENTS}}`.

### Index Summary

Load `templates/index-summary.md`, aggregate counts by category, list all components and externals. Write to `specs/.index/index.md`.

### Dry-Run Mode

If `--dry-run`: write nothing. Display preview table:

```text
Dry Run - Would generate:
| File | Category | Source | Status |
|------|----------|--------|--------|
Total: N files
```

## Step 6: Post-Scan Review

<mandatory>
**Skip if --quick flag is detected.**
</mandatory>

Ask via AskUserQuestion:

| # | Question | Key |
|---|----------|-----|
| 1 | Found {{count}} components. Seem complete? | `componentCount` |
| 2 | External resources look correct? | `externalResources` |
| 3 | Any areas to re-scan or adjust? | `adjustments` |

Handle feedback: re-scan missing areas, re-filter if too many, re-process changed externals.

## Step 7: Update State and Output

Update `specs/.index/.index-state.json` with `lastIndexed`, `componentCount`, `externalCount`, `categories`, `hashes`.

Display:

```text
Index complete for '{{project_name}}'.
Output: specs/.index/

| Category | Count |
|----------|-------|
| Controllers | {{count}} |
| Services | {{count}} |
| Models | {{count}} |
| Helpers | {{count}} |
| Migrations | {{count}} |
| External Resources | {{count}} |
| **Total** | **{{total}}** |

Next: Run /ralph-specum:start to create specs that reference indexed components.
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No components found | Warn, suggest `--path=src/` or broader patterns. Still create `specs/.index/` |
| External URL unreachable | Warn and skip, continue others |
| MCP server unavailable | Warn and skip, continue others |
| Git unavailable + `--changed` | Fatal error, suggest `--force` |
| Permission denied on file | Skip file with warning, continue |
| Hash unchanged (no `--force`) | Skip silently, count in summary |
| Template missing | Use inline minimal fallback |
| State file corrupted | Reset state, full scan |
| Monorepo detected | Preserve package context in paths, group by package in summary |

Never abort the entire index for recoverable errors. Show error/warning summary at end.
