# Requirements: Smart Ralph CLI

## 1. Overview

Smart Ralph CLI is a standalone Node.js/TypeScript binary that brings spec-driven development to any terminal environment. It replicates the Smart Ralph plugin's spec lifecycle (research, requirements, design, tasks, execution) as a self-contained tool with embedded AI SDK calls, requiring no Claude Code installation. It reads and writes the same spec file format as the plugin, so both tools can operate on the same specs without conversion.

---

## 2. User Stories

### CLI Setup & Config

**US-1** — As a developer, I want to install the CLI globally with a single npm command so that I can run `ralph` from any project.

- [ ] `npm install -g smart-ralph-cli` installs the binary and registers it as `ralph` in PATH.
- [ ] `ralph --version` prints the installed version.
- [ ] `ralph --help` prints command summaries with examples.
- [ ] Install requires no API key.

**US-2** — As a developer, I want to configure AI provider credentials in one place so that I do not repeat setup per project.

- [ ] `ralph init` creates `.ralph/config.json` in the current directory; `--global` writes to `~/.ralph/config.json` instead.
- [ ] Config stores provider name, model, and the name of the env var that holds the API key (not the key itself).
- [ ] `ralph doctor` checks that the configured provider env var is set and the model name is valid.
- [ ] `ralph init --help` documents the config file format.

**US-3** — As a CI/CD operator, I want to configure the CLI entirely through environment variables so that I do not commit credentials or config files.

- [ ] `RALPH_PROVIDER`, `RALPH_MODEL`, and the provider-specific API key env var fully configure the CLI without a config file.
- [ ] `ralph doctor` identifies which configuration source is active (env vars vs config file).
- [ ] All commands work in a fresh CI environment with only env vars set.

---

### Spec Creation & Management

**US-4** — As a developer, I want to create a new spec with a name and goal so that I can start a structured feature workflow.

- [ ] `ralph new <name> "<goal>"` creates `./specs/<name>/` with `research.md`, `requirements.md`, `design.md`, and `tasks.md` stubs.
- [ ] The CLI rejects names that don't match `/^[a-z0-9][a-z0-9\-_]*$/` with a clear error.
- [ ] Running `ralph new` on an existing spec name fails unless `--force` is passed.
- [ ] The new spec becomes the active spec (written to `./specs/.current-spec`).

**US-5** — As a developer, I want to switch between specs so that I can work on multiple features without retyping the spec name each command.

- [ ] `ralph switch <name>` sets the active spec by writing to `./specs/.current-spec`.
- [ ] All commands that accept `[name]` fall back to the active spec when the argument is omitted.
- [ ] `ralph status` shows which spec is currently active.

**US-6** — As a developer, I want to check spec and execution status so that I know what has been done and what remains.

- [ ] `ralph status [name]` prints the current phase, task index, and completion percentage.
- [ ] `--json` outputs a stable JSON object suitable for `jq` processing.
- [ ] If no spec is active and no name is given, the command prints an error and exits non-zero.

**US-7** — As a developer, I want to cancel an in-progress execution so that I can stop a runaway agent without killing the process manually.

- [ ] `ralph cancel [name]` deletes `.ralph-state.json` for the named spec.
- [ ] In-progress file changes from the cancelled task are left in place.
- [ ] `ralph status` reflects the cancelled state after the command runs.

---

### AI-Powered Phases

**US-8** — As a developer, I want to run `ralph research [name]` so that an AI agent analyzes the codebase and writes a research document before I begin planning.

- [ ] The agent reads existing spec stubs and relevant project files before writing.
- [ ] Output is written to `specs/<name>/research.md`.
- [ ] The command streams agent output to the terminal.
- [ ] If `research.md` already exists, the command prompts before overwriting (skippable with `--force`).

**US-9** — As a developer, I want to run `ralph requirements [name]` so that an AI agent produces structured user stories and acceptance criteria.

- [ ] The agent uses `research.md` as input if it exists.
- [ ] Output is written to `specs/<name>/requirements.md`.
- [ ] The command streams agent output to the terminal.
- [ ] If `requirements.md` already exists, the command prompts before overwriting (skippable with `--force`).

**US-10** — As a developer, I want to run `ralph design [name]` so that an AI agent produces a technical design document.

- [ ] The agent uses `research.md` and `requirements.md` as inputs if they exist.
- [ ] Output is written to `specs/<name>/design.md`.
- [ ] The command streams agent output to the terminal.
- [ ] If `design.md` already exists, the command prompts before overwriting (skippable with `--force`).

**US-11** — As a developer, I want to run `ralph tasks [name]` so that an AI agent breaks the design into an ordered task list.

- [ ] The agent uses all prior phase documents as inputs.
- [ ] Output is written to `specs/<name>/tasks.md` in the same checkbox format the plugin uses.
- [ ] `--tasks-size coarse|fine` controls task granularity (default: fine).
- [ ] If `tasks.md` already exists, the command prompts before overwriting (skippable with `--force`).

---

### Task Execution

**US-12** — As a developer, I want to run `ralph run [name]` so that the CLI executes spec tasks in order without my intervention.

- [ ] The CLI reads `tasks.md`, finds the first incomplete task, and executes it.
- [ ] Task state persists in `.ralph-state.json` after each task completes.
- [ ] If execution is interrupted, re-running `ralph run` resumes from the last incomplete task.
- [ ] On completion, the command prints a summary and exits 0.

**US-13** — As a CI/CD operator, I want to run `ralph run` non-interactively so that specs execute in automated pipelines without hanging on prompts.

- [ ] `ralph run --headless` disables all interactive prompts.
- [ ] The command exits 0 if all tasks complete, non-zero if any task fails.
- [ ] Output goes to stdout/stderr with no TTY-dependent formatting.

---

### Developer Experience & CI

**US-14** — As a developer, I want `ralph doctor` to validate my setup so that I can catch configuration problems before running a long workflow.

- [ ] `ralph doctor` checks: config file or env vars present, API key env var set, Node.js version met, `./specs/` directory exists.
- [ ] Each check prints pass/fail with a short description.
- [ ] The command exits 0 only if all checks pass.

**US-15** — As a developer, I want clear error messages so that I can fix problems without reading source code.

- [ ] Every error names the specific problem and suggests a fix or next step.
- [ ] Missing config errors point to `ralph init` or the relevant env var.
- [ ] Stack traces are hidden by default and shown with `--debug`.

**US-16** — As a developer, I want the CLI to work with specs I created in the Smart Ralph plugin so that I can switch tools without starting over.

- [ ] The CLI reads spec files produced by the plugin without modification.
- [ ] The CLI writes spec files that the plugin can read without modification.
- [ ] State files (`.ralph-state.json`, `.progress.md`) use the same schema as the plugin.

---

## 3. Functional Requirements

**FR-1: CLI binary.** The package ships a single executable named `ralph`, installable via `npm install -g smart-ralph-cli` or `npx smart-ralph-cli`.

**FR-2: Command routing.** Commander.js handles argument parsing, subcommand dispatch, and `--help` generation for all commands. The pattern is `ralph <command> [name] [options]`.

**FR-3: Name validation.** `ralph new` rejects spec names that don't match `/^[a-z0-9][a-z0-9\-_]*$/` before creating any files.

**FR-4: Provider abstraction.** All AI calls go through a provider interface with a single method: `runAgent(agentName: string, context: AgentContext): Promise<AgentResult>`. Phase 1 ships one implementation (Claude via `@anthropic-ai/sdk`). Adding a provider requires implementing the interface; no command code changes.

**FR-5: Provider resolution.** The CLI resolves the provider in this order: (1) `RALPH_PROVIDER` env var, (2) `.ralph/config.json` in the current directory, (3) `~/.ralph/config.json`. If no provider is found, any AI command fails with a clear error pointing to `ralph init`.

**FR-6: Agent system prompts.** Agent prompts are bundled inside the package. The CLI does not load agent files from the project directory at runtime.

**FR-7: Spec file layout.** The CLI reads and writes the exact directory layout the plugin uses:
```
specs/
  .current-spec
  <name>/
    research.md
    requirements.md
    design.md
    tasks.md
    .ralph-state.json
    .progress.md
```

**FR-8: State file compatibility.** `.ralph-state.json` schema stays compatible with the plugin's schema. Fields added by the CLI use a `cli_` prefix to avoid collisions.

**FR-9: Task parsing.** `ralph run` parses tasks using the same checkbox format as the plugin: `- [ ] Task title` (pending) and `- [x] Task title` (complete).

**FR-10: Execution loop.** `ralph run` executes one task at a time, updates `.ralph-state.json` after each, and retries a failed task up to 3 times before stopping. In headless mode, exit code is non-zero on failure.

**FR-11: Execution resume.** `ralph run` on a spec with existing state prompts before restarting from the beginning. In `--headless` mode it always resumes from the last completed task without prompting.

**FR-12: Config file.** `ralph init` writes `.ralph/config.json` (project) or `~/.ralph/config.json` (global with `--global`). Config stores provider name, model, and the name of the env var that holds the API key. The actual key is never written to disk.

**FR-13: Output formatting.** A consistent prefix character indicates message type (info, success, warning, error). Color output is on when stdout is a TTY and off otherwise. `--no-color` disables color unconditionally. `--json` on status commands suppresses all non-JSON output.

**FR-14: Error handling.** All unhandled rejections and thrown errors are caught at the top level, written to stderr in a consistent format, and exit non-zero. Stack traces appear only with `--debug`.

---

## 4. Non-Functional Requirements

**NFR-1: Startup time.** `ralph --help` completes in under 100ms on a modern laptop. AI provider initialization happens only when a command calls the AI.

**NFR-2: Node.js version.** The CLI requires Node.js 18 or higher and uses the built-in `fetch` API without polyfilling it.

**NFR-3: Cross-platform.** The CLI runs on macOS and Linux. Windows is best-effort in Phase 1. File paths use `path.join` throughout.

**NFR-4: Zero required config.** A developer can run `ralph init` then `ralph new <name> "<goal>"` with only `ANTHROPIC_API_KEY` set in the environment. No other config is required to use Phase 1 commands.

**NFR-5: Test coverage.** Unit tests cover all command handlers, the provider interface, and file I/O utilities. Integration tests cover `init`, `new`, `status`, and `cancel` against a temp directory. Target: 80% line coverage.

**NFR-6: Bundle size.** The compiled tsup output stays under 10MB including dependencies.

**NFR-7: Security.** API keys are never written to any file. Config files store only the env var name. The CLI reads the actual key from the environment at runtime.

---

## 5. Phasing

### Phase 1 (MVP)

- `ralph init`, `ralph new`, `ralph switch`
- `ralph research`, `ralph requirements`, `ralph design`, `ralph tasks`
- `ralph run` with `--headless`
- `ralph status` with `--json`
- `ralph cancel`
- `ralph doctor`
- Claude provider implementation behind the provider abstraction interface
- Config management (env var + project/global config file)
- Spec file compatibility with Smart Ralph plugin v3.0.0+
- Published to npm as `smart-ralph-cli`

### Phase 2

- Second AI provider (OpenAI or Gemini) to validate the abstraction
- Epic support: `ralph triage` and multi-spec orchestration
- TUI mode for interactive task review before execution

### Future

- Native CI integrations (GitHub Actions action, CircleCI orb)
- Multi-runtime installer (Homebrew, standalone binary via Bun compile)
- Team-shared spec repositories

---

## 6. Glossary

| Term | Definition |
|------|------------|
| Spec | A named set of markdown files (research, requirements, design, tasks) under `./specs/<name>/` |
| Active spec | The spec name stored in `./specs/.current-spec`; used as default when no name argument is given |
| Agent | An AI-powered process that reads context and writes to a spec file |
| Provider | An AI API integration (Anthropic, OpenAI, etc.) accessed through the provider interface |
| Task | A single implementation step in `tasks.md`, represented as a markdown checkbox |
| Headless mode | CLI execution with no interactive prompts, intended for CI/CD pipelines |
| State file | `.ralph-state.json` inside a spec directory; tracks execution progress during `ralph run` |

---

## 7. Out of Scope

- Replacing the Claude Code plugin. Both tools coexist and share the same spec format.
- Web UI or browser-based interface.
- IDE extensions or editor plugins.
- Custom TUI (deferred to Phase 2+).
- Any AI provider other than Claude in Phase 1.
- Version control operations (commits, PRs) performed by the CLI.
- Real-time collaboration on specs.

---

## 8. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `commander` | ^12 | Argument parsing and subcommand routing |
| `@anthropic-ai/sdk` | ^0.39 | Claude API client |
| `tsup` | ^8 | Build and bundle (dev) |
| `typescript` | ^5 | Type checking (dev) |
| `vitest` | ^2 | Unit and integration testing (dev) |
| `zod` | ^3 | Config and state file schema validation |
| `chalk` | ^5 | Terminal color output |
| `ora` | ^8 | Spinner for long-running AI calls |

External constraints:
- Anthropic API key required for Phase 1 (Claude is the only provider).
- Spec file format must stay backward-compatible with Smart Ralph plugin v3.0.0+.
- npm publish rights required for the `smart-ralph-cli` package name.
