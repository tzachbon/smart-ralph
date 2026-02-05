---
description: Index codebase components and external resources into searchable specs
argument-hint: [--path=dir] [--type=types] [--exclude=patterns] [--dry-run] [--force] [--changed] [--quick]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion, Glob, Grep, WebFetch, ListMcpResourcesTool]
---

# Index Command

You are running the codebase indexing command. This scans the repository to generate component specs in `specs/.index/`.

## Argument Parsing

Parse the following arguments from `$ARGUMENTS`:

### Available Options

| Option | Format | Default | Description |
|--------|--------|---------|-------------|
| `--path` | `--path=<dir>` | Project root | Limit scan to specific directory |
| `--type` | `--type=<types>` | All types | Comma-separated: controllers,services,models,helpers,migrations |
| `--exclude` | `--exclude=<patterns>` | Default excludes | Comma-separated patterns to exclude |
| `--dry-run` | Flag | false | Preview without writing files |
| `--force` | Flag | false | Regenerate all specs (ignore existing) |
| `--changed` | Flag | false | Regenerate only git-changed files |
| `--quick` | Flag | false | Skip interview, batch scan only |

### Default Excludes

When no `--exclude` is provided, use these defaults:
```text
node_modules, vendor, dist, build, .git, __pycache__,
*.test.*, *.spec.*, *_test.*, test/, tests/, spec/, specs/
```

### Detection Logic

Parse `$ARGUMENTS` to detect which options are present:

```text
Argument Detection:
1. --path: Look for "--path=" prefix, extract value after "="
2. --type: Look for "--type=" prefix, extract and split by comma
3. --exclude: Look for "--exclude=" prefix, extract and split by comma
4. --dry-run: Check if "--dry-run" appears anywhere
5. --force: Check if "--force" appears anywhere
6. --changed: Check if "--changed" appears anywhere
7. --quick: Check if "--quick" appears anywhere
```

### Validation Rules

| Validation | Error Message |
|------------|---------------|
| `--force` and `--changed` both set | "Cannot use --force and --changed together. Choose one." |
| `--path` directory doesn't exist | "Directory not found: <path>" |
| Invalid `--type` value | "Unknown component type: <type>. Valid: controllers,services,models,helpers,migrations" |

### Parsed Arguments Structure

After parsing, store detected arguments for use in subsequent sections:

```text
parsedArgs:
  path: <string or null>
  types: [<array of types> or null for all]
  exclude: [<array of patterns> or defaults]
  dryRun: <boolean>
  force: <boolean>
  changed: <boolean>
  quick: <boolean>
```

## Quick Mode Behavior

If `--quick` is present:
- Skip pre-scan interview
- Skip post-scan review
- Perform batch scan only
- Generate output without user interaction

## Pre-Scan Interview

<mandatory>
**Skip if --quick flag is detected.**

Conduct pre-scan interview using AskUserQuestion before scanning.
</mandatory>

### Pre-Scan Interview Questions

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | Are there any external documentation URLs I should index? | `externalUrls` | No external docs / Yes, I have URLs / Other |
| 2 | Are there any MCP servers or skills I should document? | `externalTools` | No MCP/skills / Yes, I have some / Other |
| 3 | Are there specific directories to focus on? | `focusAreas` | Index everything / Focus on specific areas / Other |
| 4 | Are there code areas lacking comments that need extra attention? | `sparseAreas` | No sparse areas / Yes, some areas / Other |

### Store Interview Responses

After interview, create or update `./specs/.index/.index-state.json`:

```json
{
  "lastIndexed": null,
  "interviewResponses": {
    "externalUrls": "<response>",
    "externalTools": "<response>",
    "focusAreas": "<response>",
    "sparseAreas": "<response>"
  }
}
```

## Component Scanner

Scan codebase using detection patterns.

### Detection Patterns

| Category | Glob Pattern | File Pattern |
|----------|-------------|--------------|
| Controllers | `**/controllers/**/*.{ts,js,py,go}` | `*controller*`, `*Controller*` |
| Services | `**/services/**/*.{ts,js,py,go}` | `*service*`, `*Service*` |
| Models | `**/models/**/*.{ts,js,py,go}` | `*model*`, `*Model*` |
| Helpers | `**/helpers/**/*.{ts,js,py,go}` | `*helper*`, `*Helper*`, `*util*` |
| Migrations | `**/migrations/**/*.{ts,js,sql}` | `*migration*` |

### Scanning Process

1. For each category (or filtered by `--type`):
   - Run Glob pattern with `parsedArgs.path` as base
   - Filter out `parsedArgs.exclude` patterns
   - For each matched file:
     - Read file content
     - Extract metadata using regex patterns (see Metadata Extraction below)
     - Generate component spec using template

2. If `--changed` flag:
   - Get git-changed files: `git diff --name-only HEAD`
   - Filter scan results to only changed files

3. If not `--force` and spec exists:
   - Compare content hash
   - Skip if unchanged

### Metadata Extraction

Use Grep tool with regex patterns to extract code metadata from matched files.

#### Export Extraction

| Language | Regex Pattern | Example Match |
|----------|--------------|---------------|
| TypeScript/JavaScript | `export\s+(const\|function\|class\|interface\|type)\s+(\w+)` | `export function login` |
| TypeScript/JavaScript | `export\s+default\s+(\w+)` | `export default UserService` |
| Python | `^def\s+(\w+)\s*\(` (at module level) | `def authenticate(` |
| Python | `^class\s+(\w+)` | `class UserModel` |
| Go | `^func\s+(\w+)\s*\(` (capitalized = exported) | `func HandleRequest(` |

#### Method Extraction

| Language | Regex Pattern | Example Match |
|----------|--------------|---------------|
| TypeScript/JavaScript | `(async\s+)?(public\|private\|protected)?\s*(static\s+)?(\w+)\s*\([^)]*\)\s*[:{]` | `async getUserById(id: string)` |
| Python | `def\s+(\w+)\s*\(self[^)]*\)` | `def get_user(self, id)` |
| Go | `func\s+\(\w+\s+\*?(\w+)\)\s+(\w+)\s*\(` | `func (s *Service) GetUser(` |

#### Dependency Extraction

| Language | Regex Pattern | Example Match |
|----------|--------------|---------------|
| TypeScript/JavaScript | `import\s+.*from\s+['"]([^'"]+)['"]` | `import { User } from './models/user'` |
| TypeScript/JavaScript | `require\s*\(['"]([^'"]+)['"]\)` | `require('express')` |
| Python | `^import\s+(\w+)` | `import os` |
| Python | `^from\s+(\S+)\s+import` | `from flask import Flask` |
| Go | `import\s+"([^"]+)"` | `import "net/http"` |

#### Extraction Process

For each matched file:

```text
1. Detect language from file extension (.ts, .js, .py, .go)
2. Apply language-specific regex patterns using Grep tool
3. Collect results:
   - exports: Array of exported names
   - methods: Array of {name, params, description}
   - dependencies: Array of import paths (deduplicated)
4. Store extracted data for template filling
```

## External Resource Fetcher

Process external resources from interview responses.

### URL Processing

For each URL provided in `externalUrls`:
1. Use WebFetch to get content
2. Extract key sections
3. Generate external spec using template
4. Store in `specs/.index/external/`

### MCP Server Processing

For MCP servers mentioned in `externalTools`:
1. Use ListMcpResourcesTool to query server
2. Document available tools and resources
3. Generate external spec using template

## Spec Generator

Generate spec files from scanned data.

### Component Specs

For each component found:
1. Load `templates/component-spec.md`
2. Fill template with extracted data
3. Calculate content hash
4. Write to `specs/.index/components/<category>-<name>.md`

### External Specs

For each external resource:
1. Load `templates/external-spec.md`
2. Fill template with fetched data
3. Write to `specs/.index/external/<type>-<name>.md`

### Index Summary

After all specs generated:
1. Load `templates/index-summary.md`
2. Aggregate counts by category
3. List all components and external resources
4. Write to `specs/.index/index.md`

## Dry Run Mode

If `--dry-run` is set:
- Do NOT write any files
- Display table of what would be generated:

```text
Dry Run - Would generate:

| File | Category | Source |
|------|----------|--------|
| components/controller-users.md | Controllers | src/controllers/users.ts |
| components/service-auth.md | Services | src/services/auth.ts |
| external/url-api-docs.md | URL | https://api.example.com/docs |
| index.md | Summary | - |

Total: 4 files
```

## Post-Scan Review

<mandatory>
**Skip if --quick flag is detected.**

Conduct post-scan review using AskUserQuestion after scanning.
</mandatory>

### Post-Scan Review Questions

| # | Question | Key | Options |
|---|----------|-----|---------|
| 1 | I found {{count}} components. Does this seem complete? | `componentCount` | Yes, looks complete / Missing some / Too many / Other |
| 2 | The external resources look correct? | `externalResources` | Yes, correct / Need changes / Other |
| 3 | Any areas I should re-scan or adjust? | `adjustments` | No, looks good / Yes, please adjust / Other |

### Handle Review Feedback

If user indicates issues:
- "Missing some": Ask which areas to add, re-scan
- "Too many": Ask what to exclude, re-filter
- "Need changes": Ask for specific changes, re-process
- "Yes, please adjust": Ask what to adjust, re-scan affected areas

## Output

After indexing completes:

```text
Index complete for '{{project_name}}'.

Output: specs/.index/

## Summary

| Category | Count |
|----------|-------|
| Controllers | {{count}} |
| Services | {{count}} |
| Models | {{count}} |
| Helpers | {{count}} |
| Migrations | {{count}} |
| External Resources | {{count}} |
| **Total** | **{{total}}** |

Index file: specs/.index/index.md

Next: Run /ralph-specum:start to create specs that reference indexed components.
```

## Error Handling

| Error Scenario | Handling |
|----------------|----------|
| No components found | Warning: "No components found. Try `--path=src/` or check patterns." |
| External URL unreachable | Warning: "Could not fetch {{url}} - skipping" |
| MCP server unavailable | Warning: "MCP server '{{name}}' not responding - skipping" |
| Git not available (--changed) | Error: "Git required for --changed. Use --force instead." |
| Permission denied | Warning: "Cannot read {{path}} - skipping" |
