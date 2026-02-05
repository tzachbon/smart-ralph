---
description: Index codebase components and external resources into searchable specs
argument-hint: [--path=dir] [--type=types] [--exclude=patterns] [--dry-run] [--force] [--changed] [--quick]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion, Glob, Grep, WebFetch, ListMcpResourcesTool]
---

# Index Command

You are running the codebase indexing command. This scans the repository to generate component specs in `specs/.index/`.

## Argument Parsing

### Step 1: Parse Arguments

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

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | Are there any external documentation URLs I should index? | Optional | `externalUrls` | No external docs / Yes, I have URLs / Other |
| 2 | Are there any MCP servers or skills I should document? | Optional | `externalTools` | No MCP/skills / Yes, I have some / Other |
| 3 | Are there specific directories to focus on? | Optional | `focusAreas` | Index everything / Focus on specific areas / Other |
| 4 | Are there code areas lacking comments that need extra attention? | Optional | `sparseAreas` | No sparse areas / Yes, some areas / Other |

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

Process external resources from interview responses. Handles three resource types: URLs, MCP servers, and skills.

### Resource Type Detection

From `externalTools` interview response, detect resource types:

```text
Resource Classification:
1. URL: Starts with "http://" or "https://" -> URL processing
2. MCP Server: Matches "mcp-*" or "mcp_*" or contains "MCP" -> MCP processing
3. Skill: Starts with "/" or contains "skill" -> Skill processing
4. Unknown: Ask for clarification or skip with warning
```

### URL Processing

For each URL provided in `externalUrls`:

```text
URL Fetch Process:
1. Validate URL format (must be HTTP/HTTPS)
2. Use WebFetch with 30s timeout:
   - WebFetch: url=<url>, prompt="Extract key sections, API endpoints, configuration options, and usage examples"
3. Parse fetched content:
   - RESOURCE_NAME: Extract from page title or URL path
   - SOURCE_TYPE: "url"
   - SOURCE_ID: Full URL
   - FETCH_TIMESTAMP: Current ISO timestamp
   - CONTENT_SUMMARY: First 500 chars or description meta tag
   - SECTIONS: Array of {title, content} from headings
   - KEYWORDS: Extract from content (APIs, endpoints, config terms)
   - RELATED_COMPONENTS: Match against scanned component names
4. Generate external spec using template
5. Write to specs/.index/external/url-<sanitized-name>.md

Timeout Handling:
- If WebFetch times out after 30s, log warning and skip
- Warning: "Could not fetch {{url}} within 30s - skipping"

Error Handling:
- 404/500 errors: Warning and skip
- Invalid URL: Warning and skip
- No content: Generate minimal spec with "Content unavailable" summary
```

### MCP Server Processing

For MCP servers mentioned in `externalTools`:

```text
MCP Discovery Process:
1. Use ListMcpResourcesTool to query available servers:
   - ListMcpResourcesTool: server=<server-name> (if specific server)
   - ListMcpResourcesTool: (no args to list all servers)
2. For each server found, collect:
   - Server name
   - Available tools (name, description)
   - Available resources (uri, name, description)
3. Generate spec data:
   - RESOURCE_NAME: Server name (e.g., "MCP Slack Server")
   - SOURCE_TYPE: "mcp-server"
   - SOURCE_ID: Server name/identifier
   - FETCH_TIMESTAMP: Current ISO timestamp
   - CONTENT_SUMMARY: "MCP server providing <N> tools and <M> resources"
   - SECTIONS:
     - "Available Tools" section listing each tool
     - "Available Resources" section listing each resource
   - KEYWORDS: Tool names, resource types
   - RELATED_COMPONENTS: Components that use this MCP server
4. Generate external spec using template
5. Write to specs/.index/external/mcp-<server-name>.md

MCP Tool Documentation Format:
| Tool | Description |
|------|-------------|
| tool_name_1 | Brief description from tool metadata |
| tool_name_2 | Brief description from tool metadata |

MCP Resource Documentation Format:
| Resource URI | Name | Description |
|--------------|------|-------------|
| resource://path | Resource Name | Brief description |

Error Handling:
- Server not responding: Warning and skip
- No tools/resources: Generate minimal spec noting empty server
```

### Skill Processing

For skills mentioned in `externalTools`:

```text
Skill Introspection Process:
1. Locate plugin manifests:
   - Glob: plugins/*/.claude-plugin/plugin.json
   - Also check: .claude-plugin/plugin.json (root plugin)
2. For each manifest, read and extract:
   - Plugin name, description, version
   - Commands (from commands/*.md)
   - Agents (from agents/*.md)
   - Hooks (from hooks/*.md)
3. If specific skill requested (e.g., "/ralph-specum:start"):
   - Parse skill name: plugin="ralph-specum", command="start"
   - Find matching plugin and command file
   - Extract command description from frontmatter
4. Generate spec data:
   - RESOURCE_NAME: Skill/command name
   - SOURCE_TYPE: "skill"
   - SOURCE_ID: Full skill path (e.g., "/ralph-specum:start")
   - FETCH_TIMESTAMP: Current ISO timestamp
   - CONTENT_SUMMARY: Command description from frontmatter
   - SECTIONS:
     - "Commands" - list of available commands
     - "Agents" - list of available agents
     - "Usage" - extracted from command file
   - KEYWORDS: Command names, agent names
   - RELATED_COMPONENTS: None (external)
5. Generate external spec using template
6. Write to specs/.index/external/skill-<plugin>-<command>.md

Plugin Manifest Extraction:
```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "version": "1.0.0",
  "commands": ["command1.md", "command2.md"],
  "agents": ["agent1.md"]
}
```

Error Handling:
- Plugin not found: Warning and skip
- Manifest invalid: Warning and skip
- Command file missing: Note in spec as "undocumented"
```

### External Spec Generation

Apply external-spec template to collected data:

```text
Template Population:
1. Load templates/external-spec.md
2. Fill variables:
   - {{SOURCE_TYPE}}: "url" | "mcp-server" | "skill"
   - {{SOURCE_ID}}: URL, server name, or skill path
   - {{FETCH_TIMESTAMP}}: ISO timestamp of fetch
   - {{RESOURCE_NAME}}: Human-readable name
   - {{CONTENT_SUMMARY}}: Brief summary (max 500 chars)
   - {{SECTIONS}}: Array of {title, content} sections
   - {{KEYWORDS}}: Space-separated keywords for search
   - {{RELATED_COMPONENTS}}: Links to related component specs
3. Write to specs/.index/external/<type>-<name>.md
```

### External Spec File Naming

```text
Pattern: <type>-<sanitized-name>.md

Sanitization Rules:
1. Lowercase all characters
2. Replace non-alphanumeric with hyphens
3. Remove consecutive hyphens
4. Trim to 50 characters max

Examples:
  URL: https://api.example.com/docs -> url-api-example-com-docs.md
  MCP: mcp-slack -> mcp-slack.md
  Skill: /ralph-specum:start -> skill-ralph-specum-start.md
```

### External Resource Summary

After processing all external resources, output summary:

```text
External Resources Processed:
| Type | Name | Status |
|------|------|--------|
| URL | API Docs | Success |
| URL | Auth Guide | Failed (timeout) |
| MCP | slack | Success (5 tools, 2 resources) |
| Skill | /ralph-specum:start | Success |

Total: 3 successful, 1 failed
Output: specs/.index/external/
```

## Spec Generator

Generate spec files from scanned data.

### Directory Structure

Ensure output directories exist before writing specs:

```text
specs/.index/
├── components/       # Component spec files
│   ├── controller-users.md
│   ├── service-auth.md
│   └── ...
├── external/         # External resource specs
│   └── url-api-docs.md
├── index.md          # Summary dashboard
└── .index-state.json # Index state and hashes
```

Create directories using Bash:
```bash
mkdir -p specs/.index/components specs/.index/external
```

### Hash Calculation

Calculate content hash for change detection:

```text
Hash Algorithm:
1. Read source file content
2. Calculate SHA-256 hash of content
3. Take first 8 characters as short hash
4. Store in spec frontmatter and .index-state.json

Example hash calculation (Bash):
  shasum -a 256 <file> | cut -c1-8

Purpose:
- Skip unchanged files on re-index
- Track which files need regeneration
- Enable --force to override
```

### Hash Storage

Store hashes in `specs/.index/.index-state.json`:

```json
{
  "lastIndexed": "2026-02-05T10:30:00Z",
  "hashes": {
    "src/controllers/users.ts": "a1b2c3d4",
    "src/services/auth.ts": "e5f6g7h8"
  },
  "interviewResponses": { ... }
}
```

### Component Spec Generation

For each scanned component:

```text
Generation Process:
1. Check if --dry-run: if true, skip to dry-run preview
2. Check if spec exists at specs/.index/components/<category>-<name>.md
3. If exists and NOT --force:
   a. Calculate current source hash
   b. Compare with stored hash in .index-state.json
   c. If hash unchanged: skip (add to "unchanged" count)
   d. If hash changed: regenerate
4. If NOT exists OR --force:
   a. Calculate source hash
   b. Load templates/component-spec.md
   c. Fill template values (see Template Population)
   d. Write to specs/.index/components/<category>-<name>.md
   e. Update hash in .index-state.json
```

### Template Population

Fill component-spec.md template with extracted data:

| Template Variable | Source |
|-------------------|--------|
| `{{SOURCE_PATH}}` | Relative path to source file |
| `{{CONTENT_HASH}}` | 8-char SHA-256 hash of source |
| `{{CATEGORY}}` | Detected category (controllers, services, etc.) |
| `{{TIMESTAMP}}` | Current ISO timestamp |
| `{{COMPONENT_NAME}}` | Derived from filename (e.g., `UsersController`) |
| `{{AUTO_GENERATED_SUMMARY}}` | First comment block or "Auto-generated spec" |
| `{{EXPORTS}}` | Array from export extraction |
| `{{METHODS}}` | Array of {name, params, description} from method extraction |
| `{{DEPENDENCIES}}` | Array from dependency extraction |
| `{{KEYWORDS}}` | Category + filename words (space-separated) |
| `{{RELATED_FILES}}` | Files in same directory |

### Spec File Naming

Generate spec filename from source:

```text
Pattern: <category>-<basename>.md

Examples:
  src/controllers/users.ts -> controller-users.md
  src/services/auth-service.ts -> service-auth-service.md
  lib/models/User.py -> model-user.md
  pkg/helpers/utils.go -> helper-utils.md

Rules:
1. Use singular category prefix (controller, service, model, helper, migration)
2. Take basename without extension
3. Lowercase all characters
4. Replace spaces/special chars with hyphens
```

### Dry-Run Mode

If `parsedArgs.dryRun` is true:

```text
Dry-Run Behavior:
1. Do NOT create directories
2. Do NOT write any files
3. Do NOT update .index-state.json
4. Display preview table of what WOULD be generated:

Output Format:
---
Dry Run - Would generate:

| File | Category | Source | Status |
|------|----------|--------|--------|
| components/controller-users.md | Controllers | src/controllers/users.ts | New |
| components/service-auth.md | Services | src/services/auth.ts | Changed |
| external/url-api-docs.md | URL | https://api.example.com | New |
| index.md | Summary | - | Updated |

Summary:
- New: 2 files
- Changed: 1 file
- Unchanged: 5 files (skipped)

Total would write: 4 files
---
```

### Force Mode

If `parsedArgs.force` is true:

```text
Force Behavior:
1. Ignore all existing specs
2. Ignore hash comparisons
3. Regenerate ALL matching components
4. Overwrite all spec files
5. Rebuild .index-state.json hashes from scratch
```

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

## Index Summary Builder

Build the `specs/.index/index.md` summary file using the index-summary template.

### Template Variables

Collect data from all generated specs to fill template:

| Variable | Description | Source |
|----------|-------------|--------|
| `TIMESTAMP` | When index was generated | Current ISO timestamp (e.g., `2026-02-05T10:30:00Z`) |
| `CATEGORIES` | Array of category summaries | Aggregated from component specs |
| `TOTAL` | Total component count | Sum of all category counts |
| `CONTROLLERS` | Array of controller specs | From `specs/.index/components/controller-*.md` |
| `SERVICES` | Array of service specs | From `specs/.index/components/service-*.md` |
| `MODELS` | Array of model specs | From `specs/.index/components/model-*.md` |
| `HELPERS` | Array of helper specs | From `specs/.index/components/helper-*.md` |
| `MIGRATIONS` | Array of migration specs | From `specs/.index/components/migration-*.md` |
| `EXTERNAL` | Array of external resource specs | From `specs/.index/external/*.md` |
| `EXCLUDES` | Excluded patterns used | From `parsedArgs.exclude` (joined with `, `) |
| `PATHS` | Indexed paths | From `parsedArgs.path` or "Project root" |

### CATEGORIES Structure

Build CATEGORIES array with counts per category:

```text
CATEGORIES = [
  { name: "Controllers", count: 5, lastUpdated: "2026-02-05T10:30:00Z" },
  { name: "Services", count: 8, lastUpdated: "2026-02-05T10:30:00Z" },
  { name: "Models", count: 12, lastUpdated: "2026-02-05T10:30:00Z" },
  { name: "Helpers", count: 3, lastUpdated: "2026-02-05T10:30:00Z" },
  { name: "Migrations", count: 2, lastUpdated: "2026-02-05T10:30:00Z" }
]

Count calculation:
1. Glob: specs/.index/components/controller-*.md -> count Controllers
2. Glob: specs/.index/components/service-*.md -> count Services
3. Glob: specs/.index/components/model-*.md -> count Models
4. Glob: specs/.index/components/helper-*.md -> count Helpers
5. Glob: specs/.index/components/migration-*.md -> count Migrations
```

### Component Arrays Structure

For each category, build array of component entries:

```text
CONTROLLERS = [
  { name: "UsersController", file: "controller-users.md", purpose: "User management" },
  { name: "AuthController", file: "controller-auth.md", purpose: "Authentication" }
]

Fields extracted from component spec:
- name: From {{COMPONENT_NAME}} in spec frontmatter
- file: Filename of the generated spec
- purpose: From {{AUTO_GENERATED_SUMMARY}} or first line of Purpose section
```

### EXTERNAL Structure

Build EXTERNAL array from external resource specs:

```text
EXTERNAL = [
  { name: "API Documentation", file: "url-api-docs.md", type: "url", fetched: "2026-02-05T10:30:00Z" },
  { name: "Slack MCP", file: "mcp-slack.md", type: "mcp-server", fetched: "2026-02-05T10:30:00Z" },
  { name: "Start Command", file: "skill-ralph-specum-start.md", type: "skill", fetched: "2026-02-05T10:30:00Z" }
]

Fields extracted from external spec:
- name: From {{RESOURCE_NAME}} in spec frontmatter
- file: Filename of the generated spec
- type: From {{SOURCE_TYPE}} in spec frontmatter (url, mcp-server, skill)
- fetched: From {{FETCH_TIMESTAMP}} in spec frontmatter
```

### Index Summary Generation Process

```text
Build Index Summary:
1. Calculate TIMESTAMP as current ISO timestamp
2. Count components per category using Glob:
   - Glob "specs/.index/components/controller-*.md" -> count
   - Glob "specs/.index/components/service-*.md" -> count
   - (etc. for each category)
3. Build CATEGORIES array with name, count, lastUpdated
4. Calculate TOTAL as sum of all category counts
5. For each category, build component array:
   - Read each spec file to extract name, purpose
   - Store filename for linking
6. Glob "specs/.index/external/*.md" for external resources
7. Read each external spec to extract name, type, fetched timestamp
8. Get EXCLUDES from parsedArgs.exclude (default excludes if not specified)
9. Get PATHS from parsedArgs.path ("Project root" if not specified)
10. Load templates/index-summary.md
11. Fill template with all collected data
12. Write to specs/.index/index.md
```

### Index State Update

After writing index summary, update `specs/.index/.index-state.json`:

```json
{
  "lastIndexed": "2026-02-05T10:30:00Z",
  "componentCount": 30,
  "externalCount": 3,
  "categories": {
    "controllers": 5,
    "services": 8,
    "models": 12,
    "helpers": 3,
    "migrations": 2
  },
  "excludes": ["node_modules", "dist", "..."],
  "paths": ["src/"],
  "hashes": { ... },
  "interviewResponses": { ... }
}
```

### Dry Run Handling

If `--dry-run` is set, do NOT write `specs/.index/index.md`. Instead include it in the dry-run preview table:

```text
| index.md | Summary | - | Updated |
```

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

## Edge Case Handling

Handle these edge cases per design specification.

### Empty Codebase

When no indexable components are found after scanning:

```text
Detection:
1. After component scanning completes
2. Check if total component count is 0
3. Check if all categories are empty

Handling:
1. Do NOT treat as error (scanning succeeded, just nothing found)
2. Display informative message with suggestions
3. Still create specs/.index/ directory
4. Create minimal index.md noting empty scan

Output:
No indexable components found.

This could be because:
- The codebase uses different naming conventions
- The --path or --type filters are too restrictive
- Source files are in excluded directories

Suggestions:
- Try `/ralph-specum:index --path=src/` to target source directory
- Run with `--dry-run` first to see what would be detected
- Check if files match patterns: controllers/, services/, models/, helpers/, migrations/
- Verify excludes aren't filtering desired directories

No specs were generated, but the index directory was created.
You can run `/ralph-specum:index --force` after adjusting parameters.
```

### Monorepo Support

When indexing a monorepo with multiple packages/services:

```text
Detection:
1. Check for monorepo indicators:
   - packages/ or apps/ directory exists
   - Multiple package.json files at different depths
   - Workspace configuration (lerna.json, pnpm-workspace.yaml, etc.)

Handling:
1. Respect --path filter if provided (allows targeting single package)
2. If no --path, scan entire repo (default full scan)
3. Preserve package context in component specs (path shows which package)
4. Group components by package/app in index summary if monorepo detected

Monorepo-aware output:
For monorepo codebases, component paths include package context:
  packages/auth-service/src/controllers/auth.ts -> controller-packages-auth-service-auth.md
  packages/api-gateway/src/services/routing.ts -> service-packages-api-gateway-routing.md

Tip: Use --path=packages/auth-service to index a single package.
```

### No Git Repository

When --changed flag is used but git is not available:

```text
Detection (run before scanning):
1. Execute: git rev-parse --git-dir 2>/dev/null
2. If command fails (non-zero exit), git is not available

Handling:
1. If --changed flag is set:
   - Fail immediately with helpful error
   - Suggest --force as alternative
   - Exit cleanly (do not attempt scanning)
2. For other modes (no --changed flag):
   - Proceed normally, git not required
   - Hash-based change detection still works

Output (when --changed used without git):
Error: Git required for --changed flag.

This directory is not a git repository or git is not installed.
The --changed flag uses `git diff` to detect modified files.

Alternatives:
- Use `/ralph-specum:index --force` to regenerate all specs
- Initialize git with `git init` if this should be a repository
- Use `/ralph-specum:index` without flags to use hash-based change detection
```

### Mixed Language Support

The scanner handles multiple languages in the same codebase:

```text
Supported Languages:
- TypeScript/JavaScript: .ts, .js, .tsx, .jsx
- Python: .py
- Go: .go

Detection Patterns Work Across Languages:
| Category | TS/JS | Python | Go |
|----------|-------|--------|-----|
| Controllers | `*Controller.ts` | `*controller.py` | `*controller.go` |
| Services | `*Service.ts` | `*service.py` | `*service.go` |
| Models | `*Model.ts` | `*model.py` | `*model.go` |

Metadata Extraction by Language:
- TypeScript/JavaScript: export, import, class, function patterns
- Python: def, class, from/import patterns
- Go: func, type, import patterns

Handling:
1. Run all glob patterns (they include {ts,js,py,go} suffixes)
2. Detect file language from extension
3. Apply language-specific regex patterns for metadata extraction
4. All languages output to same component spec format
```

### Very Large Codebase

For codebases with many files, batch processing with progress indicator:

```text
Large Codebase Detection:
1. After initial glob, count total matching files
2. If file count > 100, enable progress indicator
3. If file count > 1000, enable batch processing

Progress Indicator:
Display progress during scanning:
  Scanning components... [=====>        ] 45/100 files (45%)
  Processing: src/services/auth-service.ts

Update frequency: Every 10 files or every 5 seconds (whichever comes first)

Batch Processing:
1. Process files in batches of 50
2. Write specs incrementally (allows Ctrl+C resume)
3. Update .index-state.json after each batch
4. If interrupted, partial index is valid

Memory Management:
1. Do not hold all file contents in memory
2. Read, process, write, then release each file
3. Aggregate counts only (not full content)

Respect Excludes:
1. Apply exclude patterns BEFORE counting files
2. Default excludes remove node_modules, build/, dist/, etc.
3. This significantly reduces file count for typical codebases

Output for large scans:
Scanning large codebase (1,247 files detected)...
This may take a few minutes.

[Progress indicator during scan]

Scan complete in 2m 34s.
```

### Existing Index

When specs/.index/ already exists:

```text
Detection:
1. Check if specs/.index/ directory exists
2. Check if specs/.index/.index-state.json exists
3. Read existing hashes from state file

Handling by Mode:

Default (no flags):
1. Compare source file hash with stored hash
2. If hash matches: skip file (unchanged)
3. If hash differs: regenerate spec
4. Track "unchanged" count for summary

--force flag:
1. Ignore all existing specs and hashes
2. Regenerate everything from scratch
3. Overwrite all spec files
4. Rebuild .index-state.json completely

--changed flag:
1. Get list of git-changed files
2. Only regenerate specs for those files
3. Others remain unchanged (even if hash differs)

Output (default mode with existing index):
Existing index found at specs/.index/
Using incremental update (hash-based change detection).

To force full regeneration, use: /ralph-specum:index --force
To update only git-changed files, use: /ralph-specum:index --changed

Summary will show:
| Status | Count |
|--------|-------|
| Updated | 5 |
| Unchanged | 45 |
| New | 2 |
```

### Interrupted Indexing

Handle interrupted scans gracefully:

```text
Partial Index is Valid:
- If indexing is interrupted (Ctrl+C, crash, etc.), existing specs are valid
- Each spec is written atomically (write-then-rename pattern)
- .index-state.json is updated after each batch
- No cleanup needed after interruption

Resume Strategy:
1. Run /ralph-specum:index again (normal mode)
2. Hash comparison will skip already-indexed files
3. Only new/changed files get processed
4. Or use --force to start completely fresh

Detection of Incomplete Index:
1. Check .index-state.json for lastIndexed timestamp
2. Compare with component file mtimes
3. If specs exist without state entry, add to state on next run

Output (when resuming):
Resuming incomplete index...
Found 25 existing specs in specs/.index/
Scanning for new or changed components...

[Progress indicator]

Resume complete. Added 5 new specs.
```

## Error Handling

Handle errors gracefully with warnings and fallbacks. Never abort the entire indexing process for recoverable errors.

### Error Scenarios

| Error Scenario | Handling Strategy | User Message |
|----------------|-------------------|--------------|
| No components found | Warning + suggest broader patterns | "No components found. Try `--path=src/` or check patterns." |
| External URL unreachable | Skip with warning, continue | "Warning: Could not fetch {{url}} - skipping" |
| MCP server unavailable | Skip with warning, continue | "Warning: MCP server '{{name}}' not responding - skipping" |
| Git not available (--changed) | Error, suggest alternative | "Git required for --changed. Use --force instead." |
| Permission denied | Skip file with warning | "Warning: Cannot read {{path}} - skipping" |
| Already indexed (no --force) | Skip silently, note in summary | Shows count of "skipped (already indexed)" |

### Error Handling Behavior

#### No Components Found

When the scanner finds zero components:

```text
Behavior:
1. Do NOT treat as fatal error
2. Display warning message with suggestions
3. Check if --path is too restrictive
4. Suggest broader patterns or different directory

Output:
⚠️ No components found.

Suggestions:
- Try broader path: /ralph-specum:index --path=src/
- Check detection patterns match your file structure
- Run with --dry-run to see what would be scanned

No specs were generated.
```

#### External URL Unreachable

When WebFetch fails for a URL:

```text
Behavior:
1. Log warning with URL and reason
2. Continue processing other resources
3. Do NOT create a spec for failed URL
4. Include failure count in final summary

Output:
Warning: Could not fetch https://api.example.com/docs - skipping
  Reason: Connection timeout after 30s

Continue processing remaining resources...
```

#### MCP Server Unavailable

When ListMcpResourcesTool fails for a server:

```text
Behavior:
1. Log warning with server name
2. Continue processing other resources
3. Do NOT create a spec for unavailable server
4. Include in external resources summary as "failed"

Output:
Warning: MCP server 'mcp-slack' not responding - skipping
  Ensure the MCP server is running and accessible.

Continue processing remaining resources...
```

#### Git Not Available (--changed)

When --changed is used but git is not available:

```text
Behavior:
1. Check for git availability before scanning
2. If git not found or not a repo, show error
3. Suggest --force as alternative
4. Exit without scanning (fatal for this mode)

Check:
  Run: git rev-parse --git-dir 2>/dev/null
  If fails: git not available

Output:
Error: Git required for --changed flag.
  This directory is not a git repository or git is not installed.

Alternative: Use --force to regenerate all specs instead.
```

#### Permission Denied

When Read fails due to file permissions:

```text
Behavior:
1. Log warning with file path
2. Skip the file, continue scanning
3. Include in skipped count
4. Do NOT abort scanning for permission errors

Output:
Warning: Cannot read src/legacy/protected.ts - skipping
  Permission denied. Check file permissions.

Continue scanning remaining files...
```

#### Already Indexed (No --force)

When a spec already exists and content hash matches:

```text
Behavior:
1. Compare content hash in .index-state.json
2. If hash matches: skip silently (no warning per file)
3. Track count of skipped files
4. Report in final summary

Output (in summary only):
Unchanged: 15 files (content unchanged, skipped)
```

### Graceful Fallbacks

Implement these fallbacks to ensure robustness:

```text
Fallback Strategies:

1. Hash calculation fails:
   - Fallback: Regenerate spec (treat as changed)
   - Log: "Warning: Could not calculate hash for {{file}}, regenerating"

2. Template file missing:
   - Fallback: Use inline minimal template
   - Log: "Warning: Template {{template}} not found, using default"

3. Write permission denied for output:
   - Fallback: None (fatal - cannot create specs)
   - Log: "Error: Cannot write to specs/.index/ - check permissions"

4. State file corrupted:
   - Fallback: Reset state, perform full scan
   - Log: "Warning: .index-state.json corrupted, performing fresh scan"

5. Partial scan interrupted:
   - Fallback: Existing specs are valid, can resume with --force
   - Log: "Warning: Previous index incomplete. Run with --force to complete."
```

### Error Summary

At the end of indexing, show error/warning summary:

```text
Index Complete with Warnings:

| Status | Count | Details |
|--------|-------|---------|
| Generated | 25 | New or updated specs |
| Unchanged | 10 | Skipped (already indexed) |
| Skipped | 3 | Permission errors |
| Failed | 1 | External URL timeout |

Warnings:
- Could not fetch https://api.example.com/docs (timeout)
- Cannot read src/legacy/old.ts (permission denied)
- Cannot read src/legacy/archive.ts (permission denied)
- Cannot read src/legacy/backup.ts (permission denied)

Run with --force to regenerate all specs.
```

## Testing

Test fixtures for integration testing are located at `specs/codebase-indexing/.test-fixtures/`.

### Integration Test Scenarios

#### Full Scan

Run index on the test fixtures directory to verify spec generation.

```text
Test: Full scan generates specs for all detected components

Setup:
1. Ensure test fixtures exist at specs/codebase-indexing/.test-fixtures/
2. Fixtures include sample controllers, services, models

Command:
/ralph-specum:index --path=specs/codebase-indexing/.test-fixtures/ --quick

Expected Output:
- specs/.index/components/ contains spec files for each fixture component
- specs/.index/index.md summary lists all components
- .index-state.json records component hashes

Verification:
1. Count generated specs matches fixture count
2. Each spec has correct frontmatter (type, source, hash, category)
3. Index summary shows accurate category counts
```

#### External URL Fetch

Verify external URL processing creates valid spec files.

```text
Test: External URL fetch creates spec with extracted content

Setup:
1. Have a reachable documentation URL (e.g., public API docs)
2. Run index with interview to provide URL

Command:
/ralph-specum:index
(During interview, provide: "https://example.com/docs")

Expected Output:
- specs/.index/external/url-example-com-docs.md created
- Spec contains:
  - Frontmatter: type: external-spec, source-type: url
  - Summary section with extracted content
  - Key sections from page headings
  - Keywords for searchability

Verification:
1. External spec file exists
2. Frontmatter fields populated correctly
3. Content summary is non-empty
4. Keywords extracted from content
```

#### Dry Run

Verify dry-run mode previews without writing files.

```text
Test: Dry run shows preview without creating files

Setup:
1. Clear specs/.index/ if exists
2. Run with --dry-run flag

Command:
/ralph-specum:index --path=specs/codebase-indexing/.test-fixtures/ --quick --dry-run

Expected Output:
Dry Run - Would generate:

| File | Category | Source | Status |
|------|----------|--------|--------|
| components/controller-users.md | Controllers | .test-fixtures/controllers/users.ts | New |
| components/service-auth.md | Services | .test-fixtures/services/auth.ts | New |
| index.md | Summary | - | Updated |

Summary:
- New: N files
- Changed: 0 files
- Unchanged: 0 files

Total would write: N files

Verification:
1. No files created in specs/.index/
2. Output table lists all detected components
3. Status column shows "New" for first run
```

#### Force Regenerate

Verify force mode overwrites existing specs.

```text
Test: Force regenerate overwrites existing specs

Setup:
1. Run initial index to create specs
2. Modify a source file (add comment)
3. Run index again without --force (should skip)
4. Run index with --force

Command:
/ralph-specum:index --path=specs/codebase-indexing/.test-fixtures/ --quick --force

Expected Output:
Index complete.

| Status | Count |
|--------|-------|
| Generated | N |
| Unchanged | 0 |
| Skipped | 0 |

(All specs regenerated, none skipped)

Verification:
1. All spec files have updated timestamps
2. Hash values recalculated in .index-state.json
3. No "unchanged" count (force ignores hashes)
```

#### Changed Only

Verify changed mode only regenerates git-modified files.

```text
Test: Changed only regenerates git-modified files

Setup:
1. Run initial index to create specs
2. Modify one source file
3. Stage the change (git add)
4. Run index with --changed

Command:
/ralph-specum:index --path=specs/codebase-indexing/.test-fixtures/ --quick --changed

Expected Output:
Index complete.

| Status | Count |
|--------|-------|
| Updated | 1 |
| Unchanged | N-1 |

(Only modified file regenerated)

Verification:
1. Only changed file's spec updated
2. Other specs unchanged (same hash, same timestamp)
3. Index summary reflects current state

Error Case (No Git):
If run in non-git directory:
Error: Git required for --changed flag.
  This directory is not a git repository or git is not installed.
Alternative: Use --force to regenerate all specs instead.
```

### Test Fixtures Structure

```text
specs/codebase-indexing/.test-fixtures/
├── controllers/
│   └── users.ts          # Sample controller with exports
├── services/
│   └── auth.ts           # Sample service with methods
├── models/
│   └── user.ts           # Sample model with interface
├── helpers/
│   └── utils.ts          # Sample helper utilities
└── README.md             # Fixture documentation
```

### Running Tests

Since this is a pure markdown plugin with no build step, testing is manual verification:

```text
1. Verify command loads:
   - Start Claude Code with plugin
   - Type /ralph-specum:index --help (should show argument hints)

2. Verify full flow:
   - Run /ralph-specum:index --path=<test-dir> --quick --dry-run
   - Check output matches expected format

3. Verify integration:
   - Run /ralph-specum:start <test-spec>
   - Verify indexed specs appear in "Related Specs" section
```
