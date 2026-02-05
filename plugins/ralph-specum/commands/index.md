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
