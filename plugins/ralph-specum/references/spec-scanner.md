# Spec Scanner

> Used by: start.md, switch.md

This reference contains the spec discovery, matching, and management logic used to scan for existing specs, match user input, and manage the `.current-spec` pointer.

## Multi-Directory Resolution

Spec scanning uses the path resolver for multi-directory support:

```bash
ralph_get_specs_dirs()    # Returns all configured spec directories
ralph_get_default_dir()   # Returns first specs_dir (default for new specs)
ralph_find_spec(name)     # Find spec by name, returns full path
ralph_list_specs()        # List all specs as "name|path" pairs
ralph_resolve_current()   # Resolve .current-spec to full path
```

Resolve index paths once:

```text
defaultDir = ralph_get_default_dir()
indexDir = "$defaultDir/.index"
```

## Scanning Steps

```text
1. List all specs across all configured directories using ralph_list_specs():
   - Returns "name|path" pairs for each spec
   - Searches all directories in ralph_get_specs_dirs()
   - Exclude the current spec being created (if known)
   - Exclude .index directory (handled separately in step 1b)
   |
1b. Scan indexed specs (if $indexDir exists):
   - List component specs: ls "$indexDir"/components/*.md 2>/dev/null
   - List external specs: ls "$indexDir"/external/*.md 2>/dev/null
   - For each indexed spec:
     - Read the file and extract "## Purpose" section (component) or "## Summary" section (external)
     - Use the purpose/summary as the match text
     - Mark as "indexed" type for display differentiation
   |
2. For each spec found (name|path pair):
   - Read $path/.progress.md (using the full path from ralph_list_specs)
   - Extract "Original Goal" section (line after "## Original Goal")
   - If .progress.md doesn't exist, skip this spec
   - Treat `$path` as the resolved `basePath`; never reconstruct `specs/<name>`
   - Read `activePrototypes` from `$path/.ralph-state.json`, treating a missing field as empty
   - Only when the active map is non-empty or `$path/prototypes/` exists, inventory `prototypes/.*.candidate.md`, immutable finals, and visible or dot-prefixed quarantines
   - At that same boundary, run `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/prototype-records.py select-downstream --base-path "$path" --state "$path/.ralph-state.json"` when state exists to derive blockers, stale artifacts, and stale task indexes without writing state
   |
3. Keyword matching:
   - Extract keywords from current goal (split by spaces, lowercase)
   - Remove common words: "the", "a", "an", "to", "for", "with", "and", "or"
   - For each existing spec, count matching keywords with its Original Goal
   - For each indexed spec, count matching keywords with its Purpose/Summary
   - Score = number of matching keywords
   |
4. Rank and filter:
   - Sort ALL specs (regular + indexed) by score (descending)
   - Take top 5 specs with score > 0 (increased from 3 to accommodate indexed specs)
   - If no matches found, skip display step
   - Classify relevance: High (score >= 5), Medium (score 3-4), Low (score 1-2)
   |
5. Display related specs (if any found):
   |
   Related specs found:

   Feature specs:
   - spec-name-1 [High]: [first 50 chars of Original Goal]... [dir-path if non-default]
   - spec-name-2 [Medium]: [first 50 chars of Original Goal]... [dir-path if non-default]

   Indexed components (from $indexDir/components):
   - auth-controller [High]: Handles authentication and session management...
   - user-service [Medium]: User CRUD operations and validation...

   Indexed external (from $indexDir/external):
   - api-docs [Low]: External API documentation for...
   |
   This context becomes evidence for the grill's design tree.
   For any matching spec with overlay state, also show active, candidate, immutable-final, and quarantine counts; active blocker targets; stale artifacts and task indexes; `returnPhase`; `returnTaskIndex`; and `sourceDisposition`. Mark a candidate without a final as recovery work and show `/ralph-specum:prototype --resume <id>`. Preserve the legacy row when no overlay exists.
   |
6. Return and persist results:
   - Keep the ranked array in command context as RELATED_SPECS.
   - If the target `.ralph-state.json` already exists, merge `relatedSpecs` into it through `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py` using the resolved base path. Preserve all existing and unknown fields.
   - If state does not exist yet, do not create it here. The New Flow writes RELATED_SPECS into the initial state after creating the spec directory.
   - Use this array shape:
     {
       "relatedSpecs": [
         {"name": "spec-name-1", "path": "full/path", "goal": "Original Goal text", "score": N, "type": "feature", "relevance": "High"},
         {"name": "spec-name-2", "path": "full/path", "goal": "Original Goal text", "score": N, "type": "feature", "relevance": "Medium"},
         {"name": "auth-controller", "path": "$indexDir/components", "goal": "Purpose text", "score": N, "type": "indexed-component", "relevance": "High"},
         {"name": "api-docs", "path": "$indexDir/external", "goal": "Summary text", "score": N, "type": "indexed-external", "relevance": "Low"}
       ]
     }
```

## Keyword Extraction

Extract meaningful keywords from the goal:

```javascript
// Pseudocode for keyword extraction
function extractKeywords(text) {
  const stopWords = ["the", "a", "an", "to", "for", "with", "and", "or", "is", "it", "this", "that", "be", "on", "in", "of"];
  return text
    .toLowerCase()
    .split(/\s+/)
    .filter(word => word.length > 2)
    .filter(word => !stopWords.includes(word));
}
```

## Match Scoring

Simple keyword overlap scoring:

```javascript
// Pseudocode for scoring
function scoreMatch(currentGoalKeywords, existingGoalKeywords) {
  let score = 0;
  for (const keyword of currentGoalKeywords) {
    if (existingGoalKeywords.includes(keyword)) {
      score += 1;
    }
  }
  return score;
}
```

## Example Output

```text
Related specs found:
- user-auth: Add OAuth2 authentication with JWT tokens...
- api-refactor: Restructure API endpoints for better...
- error-handling: Implement consistent error handling...

This context becomes evidence for the grill's design tree.
```

## Usage in the Grill

After scanning, read relevant matches as facts before building the design tree. Use them to expose decisions without asking the user to repeat discoverable information:
- "The indexed `auth-controller` owns authentication. Should this feature extend that boundary or establish a separate one?"
- "The `api-refactor` spec changes these endpoints. Should this work depend on that spec or remain independently deliverable?"

Put independent decisions on the same frontier round. Keep a decision blocked when it depends on an unresolved spec or code fact.

## Spec Directory Validation

### --specs-dir Validation

When `--specs-dir` is provided:
1. Call `ralph_get_specs_dirs()` to get configured directories
2. Check if provided path matches one of the configured directories
3. If NOT in configured list: Error "Invalid --specs-dir: '$path' is not in configured specs_dirs"
4. If valid: Use this path as the spec root instead of default

```text
--specs-dir Validation Logic:

1. Extract --specs-dir value from $ARGUMENTS
2. Get configured dirs: dirs = ralph_get_specs_dirs()
3. Normalize paths (remove trailing slashes)
4. Check: specsDir in dirs?
   - YES: Use specsDir for spec creation
   - NO: Error "Invalid --specs-dir: '$specsDir' is not in configured specs_dirs. Configured: $dirs"
```

### Spec Directory Resolution

```text
Spec Directory Logic:

1. Check if --specs-dir in $ARGUMENTS
   - YES: Validate against configured specs_dirs, use if valid
   - NO: Use ralph_get_default_dir() (first configured dir, defaults to ./specs)

2. Determine spec base path:
   specsDir = validated --specs-dir OR ralph_get_default_dir()
   basePath = "$specsDir/$name"

3. For .current-spec:
   - If specsDir == "./specs" (default): Write bare name
   - If specsDir != "./specs" (non-default): Write full path "$specsDir/$name"
```

## .current-spec File Management

### Reading

Use `ralph_resolve_current()` to resolve `.current-spec` to a full path:
- Bare name (e.g., `my-feature`) resolves to `./specs/my-feature`
- Full path (e.g., `./packages/api/specs/my-feature`) used as-is

### Writing

Update `.current-spec` based on root directory:

```text
defaultDir = ralph_get_default_dir()
if specsDir == defaultDir:
    echo "$name" > "$defaultDir/.current-spec"     # Bare name for default root
else:
    echo "$basePath" > "$defaultDir/.current-spec" # Full path for non-default root
```

### switch.md Behavior

When switching active spec:
1. If input starts with `./` or `/`: treat as full path
2. Otherwise: treat as spec name to search for via `ralph_find_spec()`
3. Exit code 0 (found unique): proceed with switch
4. Exit code 1 (not found): error with list of searched directories
5. Exit code 2 (ambiguous): show disambiguation prompt with full paths

## Spec Phase/Status Detection

Determine spec phase from directory contents:

### Resume Flow

1. Read `$specPath/.ralph-state.json`
2. If no state file (completed or never started):
   - Check what files exist (research.md, requirements.md, design.md, tasks.md)
   - Determine last completed phase from file presence
   - Ask: "Continue to next phase or restart?"
3. If state file exists:
   - Read current phase and task index
   - Show brief status and continue from current phase

### Resume by Phase

| Phase | Action |
|-------|--------|
| research | Create research team, spawn parallel teammates, merge results |
| requirements | Invoke product-manager agent |
| design | Invoke architect-reviewer agent |
| tasks | Invoke task-planner agent |
| execution | Invoke spec-executor for current task |

### Status Display (on resume)

```text
Resuming: user-auth
Phase: execution
Progress: 3/8 tasks complete
Current: 2.1 Add error handling

Continuing...
```

## Quick Mode Name Conflict Resolution

```text
Validation Sequence:

1. specsDir = validated --specs-dir OR ralph_get_default_dir()
2. If $specsDir/$name/ already exists:
   - Append -2, -3, etc. until unique name found
   - Display: "Created '$name-2' at $specsDir ($name already exists)"
```

## Index Hint

Before starting a new spec, check if codebase indexing exists (skip if --quick):

```bash
# Session guard (skip if already shown in this session)
if [ -z "${RALPH_SPECUM_INDEX_HINT_SHOWN:-}" ]; then
  defaultDir="$(ralph_get_default_dir)"
  indexDir="$defaultDir/.index"
  # Check if the configured default index exists and has content
  if [ ! -d "$indexDir" ] || [ -z "$(ls -A "$indexDir" 2>/dev/null)" ]; then
    SHOW_INDEX_HINT=true
  else
    SHOW_INDEX_HINT=false
  fi
else
  SHOW_INDEX_HINT=false
fi
```

Display hint if true:
```text
Tip: Run /ralph-specum:index to scan your codebase and create indexed specs.
This helps the research phase find relevant existing code patterns and components.
```

After displaying, set `export RALPH_SPECUM_INDEX_HINT_SHOWN=1`. Only show once per session.
