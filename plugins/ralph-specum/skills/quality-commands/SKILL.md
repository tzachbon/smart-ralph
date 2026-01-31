---
name: quality-commands
description: This skill should be used when the user asks about "discover quality commands", "find lint command", "check package.json scripts", "Makefile targets", "CI workflow commands", "project test commands", or needs guidance on discovering the actual quality commands available in a project.
version: 0.1.0
---

# Quality Command Discovery

Quality command discovery is essential because projects use different tools and scripts. Never assume `npm test` or `pnpm lint` exists - always discover actual commands from project sources.

## Why Discovery Matters

- Projects use different package managers (npm, pnpm, yarn, bun)
- Script names vary (lint, eslint, check-types, typecheck, tsc)
- Some projects use Makefiles instead of package.json
- CI configs reveal the authoritative commands actually run

## Sources to Check

Check these sources in order of preference:

### 1. package.json (Primary Source)

```bash
cat package.json | jq '.scripts'
```

Look for keywords: `lint`, `typecheck`, `type-check`, `check-types`, `test`, `build`, `e2e`, `integration`, `unit`, `verify`, `validate`, `check`

Common patterns:
- `lint` - ESLint/linting
- `typecheck` or `check-types` - TypeScript checking
- `test` - All tests or unit tests
- `test:unit` - Unit tests specifically
- `test:integration` - Integration tests
- `test:e2e` or `e2e` - End-to-end tests
- `build` - Build/compile

### 2. Makefile (If Exists)

```bash
grep -E '^[a-z]+:' Makefile
```

Look for keywords: `lint`, `test`, `check`, `build`, `e2e`, `integration`, `unit`, `verify` targets

### 3. CI Configs (GitHub Actions: .github/workflows/*.yml)

```bash
grep -E 'run:' .github/workflows/*.yml
```

Extract actual commands from CI steps - these are authoritative.

## Discovery Commands to Run

Run these during research phase:

```bash
# Check package.json scripts
cat package.json | jq -r '.scripts | keys[]' 2>/dev/null || echo "No package.json"

# Check Makefile targets
grep -E '^[a-z_-]+:' Makefile 2>/dev/null | head -20 || echo "No Makefile"

# Check CI workflow commands
grep -rh 'run:' .github/workflows/*.yml 2>/dev/null | head -20 || echo "No CI configs"
```

## Package Manager Detection

Detect the correct package manager:

| File Exists | Package Manager | Run Prefix |
| ------------------- | --------------- | ---------- |
| `pnpm-lock.yaml` | pnpm | `pnpm run` |
| `yarn.lock` | yarn | `yarn` |
| `bun.lockb` | bun | `bun run` |
| `package-lock.json` | npm | `npm run` |

```bash
# Detection command
if [ -f pnpm-lock.yaml ]; then echo "pnpm";
elif [ -f yarn.lock ]; then echo "yarn";
elif [ -f bun.lockb ]; then echo "bun";
else echo "npm"; fi
```

## Output Format

Document discovered commands in research.md:

```markdown
## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | `pnpm run lint` | package.json scripts.lint |
| TypeCheck | `pnpm run check-types` | package.json scripts.check-types |
| Unit Test | `pnpm test:unit` | package.json scripts.test:unit |
| Integration Test | `pnpm test:integration` | package.json scripts.test:integration |
| E2E Test | `pnpm test:e2e` | package.json scripts.test:e2e |
| Test (all) | `pnpm test` | package.json scripts.test |
| Build | `pnpm run build` | package.json scripts.build |

**Local CI**: `pnpm run lint && pnpm run check-types && pnpm test && pnpm run build`
```

## Handling Missing Commands

If a command type is not found in the project:

```markdown
| Type | Command | Source |
|------|---------|--------|
| Lint | Not found | - |
| TypeCheck | `pnpm run check-types` | package.json |
| E2E Test | Not found | - |
```

Mark as "Not found" so task-planner knows to skip that check in `[VERIFY]` tasks.

## Fallback Commands

When project lacks explicit scripts, use these fallbacks:

| Type | Fallback | Condition |
| --------- | ------------------ | ---------------------- |
| TypeCheck | `npx tsc --noEmit` | tsconfig.json exists |
| Lint | `npx eslint .` | .eslintrc* exists |
| Test | `npx jest` | jest.config.* exists |
| Test | `npx vitest run` | vitest.config.* exists |

```bash
# TypeScript check fallback
if [ -f tsconfig.json ] && ! grep -q '"typecheck\|check-types"' package.json; then
  echo "Fallback: npx tsc --noEmit"
fi
```

## Quality Command Categories

### Required (Always Check)

1. **TypeCheck** - Must pass for code to be valid
2. **Lint** - Must pass for code style compliance
3. **Build** - Must pass for deployment

### Optional (When Available)

4. **Unit Test** - Run if exists
5. **Integration Test** - Run if exists
6. **E2E Test** - Run if exists (often slow)

## Local CI Command

Construct a "Local CI" command that mirrors what CI runs:

```bash
# Template
<lint-cmd> && <typecheck-cmd> && <test-cmd> && <build-cmd>

# Example
pnpm run lint && pnpm run check-types && pnpm test && pnpm run build
```

Skip unavailable commands:

```bash
# If no lint script
pnpm run check-types && pnpm test && pnpm run build
```

## Usage in Agents

Reference this skill when discovering quality commands:

```markdown
<skill-reference>
**Apply skill**: `skills/quality-commands/SKILL.md`
Discover actual quality commands before creating [VERIFY] tasks.
</skill-reference>
```

## Quality Checklist

Before completing discovery:

- [ ] Checked package.json scripts
- [ ] Checked Makefile (if exists)
- [ ] Checked CI workflow commands
- [ ] Detected correct package manager
- [ ] Documented all found commands in table format
- [ ] Marked missing command types as "Not found"
- [ ] Constructed Local CI command
