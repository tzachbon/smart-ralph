# Intent Classification

> Used by: start.md

This reference contains the goal/intent detection logic used by the start command to determine what the user wants and route to the appropriate action.

## Argument Parsing

From `$ARGUMENTS`, extract:
- **name**: Optional spec name (kebab-case)
- **goal**: Everything after the name except flags (optional)
- **--fresh**: Force new spec without prompting if one exists
- **--quick**: Skip all spec phases, auto-generate artifacts, start execution immediately
- **--commit-spec**: Commit and push spec files after generation (default: true in normal mode, false in quick mode)
- **--no-commit-spec**: Explicitly disable committing spec files
- **--specs-dir <path>**: Create spec in specified directory (must be in configured specs_dirs array)

### Commit Spec Flag Logic

```text
1. Check if --no-commit-spec in $ARGUMENTS -> commitSpec = false
2. Else if --commit-spec in $ARGUMENTS -> commitSpec = true
3. Else if --quick in $ARGUMENTS -> commitSpec = false (quick mode default)
4. Else -> commitSpec = true (normal mode default)
```

### Examples

- `/ralph-specum:start` -> Auto-detect: resume active or ask for new
- `/ralph-specum:start user-auth` -> Resume or create user-auth
- `/ralph-specum:start user-auth Add OAuth2` -> Create user-auth with goal
- `/ralph-specum:start user-auth --fresh` -> Force new, overwrite if exists
- `/ralph-specum:start "Build auth with JWT" --quick` -> Quick mode with goal string
- `/ralph-specum:start my-feature "Add logging" --quick` -> Quick mode with name+goal
- `/ralph-specum:start ./my-plan.md --quick` -> Quick mode with file input
- `/ralph-specum:start my-feature ./plan.md --quick` -> Quick mode with name+file
- `/ralph-specum:start my-feature --quick` -> Quick mode using existing plan.md

## Detection Logic (Normal Mode)

```text
1. Determine target specs directory:
   - If --specs-dir provided: Use validated path
   - Else: Use ralph_get_default_dir()
   |
2. Check if name provided in arguments
   |
   +-- Yes: Use ralph_find_spec(name) to check if spec exists
   |   |
   |   +-- Found + no --fresh: Ask "Resume '$name' or start fresh?"
   |   |   +-- Resume: Go to resume flow (use found path)
   |   |   +-- Fresh: Delete existing, go to new flow
   |   |
   |   +-- Found + --fresh: Delete existing, go to new flow
   |   |
   |   +-- Not found: Go to new flow (create in target specs dir)
   |   |
   |   +-- Ambiguous (exit 2): Show paths, ask user to specify
   |
   +-- No: Use ralph_resolve_current() to check active spec
       |
       +-- Has active spec: Go to resume flow (use resolved path)
       |
       +-- No active spec: Ask for name and goal, go to new flow
```

## Quick Mode Input Detection

Parse arguments before `--quick` flag and classify input type:

```text
Input Classification:

1. TWO ARGS before --quick:
   - First arg = spec name (must be kebab-case: ^[a-z0-9-]+$)
   - Second arg = goal string OR file path
   - Detect file path if: starts with "./" OR "/" OR ends with ".md"
   - Examples:
     - `my-feature "Add login" --quick` -> name=my-feature, goal="Add login"
     - `my-feature ./plan.md --quick` -> name=my-feature, file=./plan.md

2. ONE ARG before --quick:
   a. FILE PATH: starts with "./" OR "/" OR ends with ".md"
      - Read file content as plan
      - Infer name from plan content
      - Example: `./my-plan.md --quick` -> read file, infer name

   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Use `ralph_find_spec($name)` to resolve spec path
      - If found and `$specPath/plan.md` exists: use plan.md content, name=$name
      - If found but no plan.md: error "No plan.md found in $specPath/. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - If not found: error "Spec '$name' not found. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - Example: `my-feature --quick` -> resolve spec path, check plan.md

   c. GOAL STRING: anything else (contains spaces, uppercase, special chars)
      - Use as goal content
      - Infer name from goal
      - Example: `"Build auth with JWT" --quick` -> goal, infer name

3. ZERO ARGS with --quick:
   - Error: "Quick mode requires a goal or plan file"
```

### File Reading

When file path detected:
1. Validate file exists using Read tool
2. If not exists: error "File not found: $filePath"
3. Read file content
4. Strip frontmatter if present (content between --- markers at start)
5. If content empty after stripping: error "Plan content is empty. Provide a goal or non-empty file."
6. Use content as planContent

### Existing Plan Check

When kebab-case name provided without goal:
1. Use `ralph_find_spec(name)` to locate existing spec
2. If found: Check if `$specPath/plan.md` exists
   - If plan.md exists: read content, use as planContent
   - If plan.md not exists: error "No plan.md found in $specPath. Provide goal: /ralph-specum:start $name 'your goal' --quick"
3. If not found: error "Spec '$name' not found. Provide goal: /ralph-specum:start $name 'your goal' --quick"

## Name Inference

If no explicit name provided, infer from goal:

1. **Extract key terms**: Identify nouns and verbs from the goal
   - Skip common words: a, an, the, to, for, with, and, or, in, on, by, from, is, be, that
   - Prioritize: action verbs (add, build, create, fix, implement, update, remove, enable)
   - Then: descriptive nouns (auth, api, user, config, endpoint, handler)
2. **Build name**: Take up to 4 key terms, join with hyphens, convert to lowercase
3. **Normalize**: Strip unicode to ASCII, remove special characters except hyphens, collapse multiple hyphens
4. **Truncate**: Max 30 characters, truncate at word boundary (hyphen) when possible

Examples:
| Goal | Inferred Name |
|------|---------------|
| "Add user authentication with JWT" | add-user-authentication-jwt |
| "Build a REST API for products" | build-rest-api-products |
| "Fix the login bug where users can't reset password" | fix-login-bug-reset |
| "Implement rate limiting" | implement-rate-limiting |

## Goal Intent Classification

Before asking interview questions, classify the user's goal to determine question depth.

### Classification Logic

Analyze the goal text for keywords to determine intent type:

```text
Intent Classification:

1. TRIVIAL: Goal contains keywords like:
   - "fix typo", "typo", "spelling"
   - "small change", "minor"
   - "quick", "simple", "tiny"
   - "rename", "update text"
   -> Min questions: 1, Max questions: 2

2. REFACTOR: Goal contains keywords like:
   - "refactor", "restructure", "reorganize"
   - "clean up", "cleanup", "simplify"
   - "extract", "consolidate", "modularize"
   - "improve code", "tech debt"
   -> Min questions: 3, Max questions: 5

3. GREENFIELD: Goal contains keywords like:
   - "new feature", "new system", "new module"
   - "add", "build", "implement", "create"
   - "integrate", "introduce"
   - "from scratch"
   -> Min questions: 5, Max questions: 10

4. MID_SIZED: Default if no clear match
   -> Min questions: 3, Max questions: 7
```

### Confidence Threshold

| Match Count | Confidence | Action |
|-------------|------------|--------|
| 3+ keywords | High | Use matched category |
| 1-2 keywords | Medium | Use matched category |
| 0 keywords | Low | Default to MID_SIZED |

### Question Count Rules

- TRIVIAL: 1-2 questions (get essentials, move fast)
- REFACTOR: 3-5 questions (understand scope and risks)
- GREENFIELD: 5-10 questions (full context needed)
- MID_SIZED: 3-7 questions (balanced approach)

### Dialogue Depth by Intent

Intent classification determines how deep the brainstorming dialogue goes:

| Intent | Min Questions | Max Questions |
|--------|---------------|---------------|
| TRIVIAL | 1 | 2 |
| REFACTOR | 3 | 5 |
| GREENFIELD | 5 | 10 |
| MID_SIZED | 3 | 7 |

### Store Intent

After classification, store the result in `.progress.md`:
```markdown
## Interview Format
- Version: 1.0

## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]
```

## Goal Type Detection (Quick Mode)

Classify goal as "fix" or "add" using regex indicators:

```text
Fix: fix|resolve|debug|broken|failing|error|bug|crash|issue|not working
Add: add|create|build|implement|new|enable|introduce (default)
```

For fix goals: run reproduction command, document BEFORE state in .progress.md.

## Routing Summary

| Detected Intent | Route |
|----------------|-------|
| Name provided + spec exists + no --fresh | Ask resume or fresh |
| Name provided + spec exists + --fresh | Delete existing, new flow |
| Name provided + spec not found | New flow |
| Name ambiguous (multiple dirs) | Show paths, ask user to specify |
| No name + active spec exists | Resume flow |
| No name + no active spec | Ask for name and goal, new flow |
| --quick with goal/file | Quick mode flow (skip interactive phases) |
| --quick with zero args | Error: "Quick mode requires a goal or plan file" |
