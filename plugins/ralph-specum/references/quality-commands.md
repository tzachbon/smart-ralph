# Quality Commands

> Used by: spec-executor agent

## Purpose

Before running quality checks, the executor must discover what commands are actually available in the project. Do NOT assume any specific command exists.

## Discovery Order

Check these sources in order. Use the first matching commands found.

### 1. research.md Quality Commands Section

The primary source. The research phase discovers and records project commands:

```markdown
## Quality Commands
| Type | Command | Source |
```

Read `<basePath>/research.md` and parse the Quality Commands table. This is the most reliable source since it was validated during research.

### 2. package.json Script Discovery

If research.md has no Quality Commands section, inspect `package.json`:

```bash
# Check for common script names
cat package.json | jq '.scripts'
```

Standard scripts to look for:

| Script Key | Quality Type | Example Invocation |
|-----------|-------------|-------------------|
| `test` | Tests | `npm test` / `pnpm test` |
| `test:unit` | Unit tests | `pnpm test:unit` |
| `test:e2e` | E2E tests | `pnpm test:e2e` |
| `test:integration` | Integration tests | `pnpm test:integration` |
| `lint` | Linting | `pnpm lint` |
| `lint:fix` | Auto-fix lint | `pnpm lint:fix` |
| `check-types` | Type checking | `pnpm check-types` |
| `typecheck` | Type checking | `pnpm typecheck` |
| `type-check` | Type checking | `pnpm type-check` |
| `build` | Build | `pnpm build` |
| `ci` | Full CI suite | `pnpm ci` |

Also check for monorepo patterns where scripts live in workspace root vs package-level `package.json` files.

### 3. Makefile Target Discovery

If no package.json or scripts are missing:

```bash
# List available make targets
grep -E '^[a-zA-Z_-]+:' Makefile
```

Common targets: `test`, `lint`, `build`, `check`, `ci`, `fmt`, `format`.

### 4. Other Config File Patterns

| Config File | Language/Ecosystem | Commands to Try |
|------------|-------------------|-----------------|
| `pyproject.toml` | Python | `pytest`, `ruff check .`, `mypy .`, `python -m build` |
| `Cargo.toml` | Rust | `cargo test`, `cargo clippy`, `cargo build` |
| `go.mod` | Go | `go test ./...`, `golangci-lint run`, `go build ./...` |
| `Gemfile` | Ruby | `bundle exec rspec`, `bundle exec rubocop`, `bundle exec rake build` |
| `build.gradle` / `pom.xml` | Java/Kotlin | `./gradlew test`, `./gradlew check`, `mvn test`, `mvn verify` |
| `mix.exs` | Elixir | `mix test`, `mix credo`, `mix compile` |
| `deno.json` | Deno | `deno test`, `deno lint`, `deno check` |

### 5. Fallback Strategies

When no config file is found:
- Check for CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`) and extract the commands used there
- Look for a `scripts/` directory with test/lint/build scripts
- Check for `.tool-versions` or `asdf` to identify the language, then use standard commands for that ecosystem
- If truly nothing found, note in .progress.md Learnings that no quality commands were discovered

## Phase-Specific Command Usage

| Phase | Which Commands to Run |
|-------|----------------------|
| Phase 1 (POC) | Lint + type check only. Skip tests -- POC validates the idea, not test coverage |
| Phase 2 (Refactoring) | Lint + type check + existing tests (ensure refactoring doesn't break anything) |
| Phase 3 (Testing) | Lint + type check + all tests including newly written ones |
| Phase 4 (Quality Gates) | Full suite: lint + type check + all tests + E2E + build |
| Phase 5 (PR Lifecycle) | Full suite + `gh pr checks` for CI pipeline status |

## Verify Command Format

Checkpoint tasks chain commands with `&&` so any failure stops execution:

```
<lint cmd> && <typecheck cmd>                          # Phase 1
<lint cmd> && <typecheck cmd> && <test cmd>            # Phase 2-3
<lint cmd> && <typecheck cmd> && <test cmd> && <e2e> && <build>  # Phase 4
```

All commands must exit 0 for the checkpoint to pass.

## Automated Verification Alternatives

When a task's Verify field seems to require manual testing, use these automated alternatives:

| Seems Manual | Automated Alternative |
|-------------|----------------------|
| Visual/UI checks | DOM element assertions, screenshot comparison CLI |
| User flow testing | Browser automation (Puppeteer/Playwright), MCP browser tools |
| Dashboard verification | API queries to the dashboard backend, WebFetch |
| Extension testing | `web-ext lint`, manifest validation, build output checks |
| API verification | `curl http://localhost:PORT/endpoint \| jq .field` |
| Auth flow testing | Test tokens, mock auth, CLI-based OAuth flows |
