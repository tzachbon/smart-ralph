---
name: spec-scanner
description: This skill should be used when the user asks about "find related specs", "scan existing specs", "spec discovery", "keyword matching for specs", "related work detection", "prior context surfacing", or needs guidance on discovering and recommending related specs before starting new work.
version: 0.1.0
---

# Spec Scanner

Scan existing specs to find related work before starting new specs. This surfaces prior context and helps avoid duplicate effort.

## When to Use

Before conducting a Goal Interview, scan for related specs to:
- Surface prior context that may inform the new work
- Avoid duplicate effort on similar goals
- Enable informed interview questions about relationships to existing work

**Skip spec scanner if --quick flag detected.**

## Scan Steps

```text
1. List all directories in ./specs/
   - Run: ls -d ./specs/*/ 2>/dev/null | xargs -I{} basename {}
   - Exclude the current spec being created (if known)
   |
2. For each spec directory found:
   - Read ./specs/$specName/.progress.md
   - Extract "Original Goal" section (line after "## Original Goal")
   - If .progress.md doesn't exist, skip this spec
   |
3. Keyword matching:
   - Extract keywords from current goal (split by spaces, lowercase)
   - Remove common words: "the", "a", "an", "to", "for", "with", "and", "or"
   - For each existing spec, count matching keywords with its Original Goal
   - Score = number of matching keywords
   |
4. Rank and filter:
   - Sort specs by score (descending)
   - Take top 3 specs with score > 0
   - If no matches found, skip display step
   |
5. Display related specs (if any found):
   |
   Related specs found:
   - spec-name-1: [first 50 chars of Original Goal]...
   - spec-name-2: [first 50 chars of Original Goal]...
   - spec-name-3: [first 50 chars of Original Goal]...
   |
   This context may inform the interview questions.
   |
6. Store in state file:
   - Update .ralph-state.json with relatedSpecs array:
     {
       ...existing state,
       "relatedSpecs": [
         {"name": "spec-name-1", "goal": "Original Goal text", "score": N},
         {"name": "spec-name-2", "goal": "Original Goal text", "score": N},
         {"name": "spec-name-3", "goal": "Original Goal text", "score": N}
       ]
     }
```

## Keyword Extraction

Extract meaningful keywords from the goal by removing stop words:

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

### Stop Words List

| Category | Words |
|----------|-------|
| Articles | the, a, an |
| Prepositions | to, for, with, on, in, of |
| Conjunctions | and, or |
| Pronouns | it, this, that |
| Verbs (common) | is, be |

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

### Scoring Rules

| Score | Interpretation | Action |
|-------|----------------|--------|
| 0 | No keyword overlap | Exclude from results |
| 1-2 | Low relevance | Include if in top 3 |
| 3-5 | Medium relevance | Prioritize in results |
| 6+ | High relevance | Definitely include, may indicate duplicate |

## Output Format

### Related Specs Display

```text
Related specs found:
- user-auth: Add OAuth2 authentication with JWT tokens...
- api-refactor: Restructure API endpoints for better...
- error-handling: Implement consistent error handling...

This context may inform the interview questions.
```

### State File Format

```json
{
  "relatedSpecs": [
    {"name": "user-auth", "goal": "Add OAuth2 authentication with JWT tokens", "score": 4},
    {"name": "api-refactor", "goal": "Restructure API endpoints for better", "score": 2},
    {"name": "error-handling", "goal": "Implement consistent error handling", "score": 1}
  ]
}
```

## Usage in Interview

After scanning, if related specs were found, reference them when asking clarifying questions:

- "I noticed you have a spec 'user-auth' for authentication. Does this new feature relate to or depend on that work?"
- "There's an existing 'api-refactor' spec. Should this work integrate with those changes?"
- "The 'error-handling' spec covers similar error patterns. Should we follow the same approach?"

## Examples

### Example 1: Finding Related Authentication Work

**Current Goal**: "Add password reset functionality"

**Existing Specs**:
- user-auth: "Add OAuth2 authentication with JWT tokens"
- api-refactor: "Restructure API endpoints"
- dashboard: "Create admin dashboard"

**Keywords extracted**: ["add", "password", "reset", "functionality"]

**Matching**:
- user-auth: 1 match ("add")
- api-refactor: 0 matches
- dashboard: 0 matches

**Output**:
```text
Related specs found:
- user-auth: Add OAuth2 authentication with JWT tokens...

This context may inform the interview questions.
```

### Example 2: No Related Specs Found

**Current Goal**: "Add unit tests for payment module"

**Existing Specs**:
- user-auth: "Add OAuth2 authentication"
- dashboard: "Create admin dashboard"

**Keywords extracted**: ["add", "unit", "tests", "payment", "module"]

**Matching**:
- user-auth: 1 match ("add") - low score
- dashboard: 0 matches

**Output** (score threshold met):
```text
Related specs found:
- user-auth: Add OAuth2 authentication...

This context may inform the interview questions.
```

### Example 3: Multiple High-Relevance Matches

**Current Goal**: "Refactor authentication to use new token system"

**Existing Specs**:
- user-auth: "Add OAuth2 authentication with JWT tokens"
- token-refresh: "Implement token refresh mechanism"
- api-auth: "Add authentication to API endpoints"

**Keywords extracted**: ["refactor", "authentication", "use", "new", "token", "system"]

**Matching**:
- user-auth: 2 matches ("authentication", "token")
- token-refresh: 1 match ("token")
- api-auth: 1 match ("authentication")

**Output**:
```text
Related specs found:
- user-auth: Add OAuth2 authentication with JWT tokens...
- token-refresh: Implement token refresh mechanism...
- api-auth: Add authentication to API endpoints...

This context may inform the interview questions.
```

## Implementation Notes

### Bash Commands for Scanning

```bash
# List spec directories
ls -d ./specs/*/ 2>/dev/null | xargs -I{} basename {} | grep -v "^\.current-spec$"

# Read original goal from progress file
sed -n '/## Original Goal/{n;p;}' "./specs/$specName/.progress.md"
```

### Edge Cases

| Scenario | Handling |
|----------|----------|
| No ./specs/ directory | Skip scanning, proceed to interview |
| Only current spec exists | Skip scanning (no other specs to compare) |
| .progress.md missing | Skip that spec |
| Empty Original Goal | Skip that spec |
| All scores are 0 | Skip display, proceed to interview |

### Performance Considerations

- Scanner should complete in < 2 seconds for typical projects
- For projects with > 20 specs, consider caching keyword extraction
- Truncate goal text to first 200 chars for display
