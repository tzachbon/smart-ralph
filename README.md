<div align="center">

<img src="smart-ralph.png" alt="Smart Ralph" width="500"/>

# Smart Ralph

### *"Me fail specs? That's unpossible!"*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Native spec-driven development for Claude Code and Codex.**

Self-contained plugins with platform-native orchestration and no added runtime dependencies.

[Quick Start](#-quick-start) | [Commands](#-commands) | [How It Works](#-how-it-works) | [Troubleshooting](#-troubleshooting)

</div>

---

## What is this?

Smart Ralph provides native Claude Code and Codex plugins that turn vague feature ideas into reviewed specs, then implement verified logical batches. Like having a tiny product team in your terminal.

```text
You: "Add user authentication"
Ralph: *creates research.md, requirements.md, design.md, tasks.md*
Ralph: *executes each task with fresh context*
Ralph: "I'm helping!"
```

## Why "Ralph"?

Named after the [Ralph agentic loop pattern](https://ghuntley.com/ralph/) and everyone's favorite Springfield student. Ralph doesn't overthink. Ralph just does the next task. Be like Ralph.

---

## Installation

### Claude Code

> **Prerequisite:** Claude Code 2.1.32 or newer. Check with `claude --version`.

```bash
claude --version
claude plugin marketplace add tzachbon/smart-ralph
claude plugin install ralph-specum@smart-ralph
```

Restart Claude Code after installation. See the [Claude plugin guide](plugins/ralph-specum/README.md) for update and rollback instructions.

### Codex

> **Prerequisite:** Codex CLI 0.144.0 or newer.

```bash
codex --version
codex plugin marketplace add tzachbon/smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

Ralph uses Codex phase skills, native subagents, and native `/goal` execution. It does not require hooks or custom agent configuration. See the [Codex plugin guide](plugins/ralph-specum-codex/README.md) for update, rollback, and v4 migration instructions.

<details>
<summary>Troubleshooting & alternative methods</summary>

**Claude local development:**
```bash
git clone https://github.com/tzachbon/smart-ralph.git
claude --plugin-dir ./smart-ralph/plugins/ralph-specum
```

**Codex local development:**
```bash
git clone https://github.com/tzachbon/smart-ralph.git
codex plugin marketplace add ./smart-ralph
codex plugin add ralph-specum-codex@smart-ralph
```

</details>

---

## Quick Start

### Codex

Use `$ralph-specum` as the default Codex surface. Helper skills mirror the explicit phase entrypoints:

```text
$ralph-specum
$ralph-specum-start
$ralph-specum-triage
$ralph-specum-research
$ralph-specum-requirements
$ralph-specum-design
$ralph-specum-tasks
$ralph-specum-implement
$ralph-specum-status
```

Version 5 keeps `$ralph-specum-switch`, `$ralph-specum-cancel`, `$ralph-specum-index`, `$ralph-specum-refactor`, `$ralph-specum-feedback`, and `$ralph-specum-help` as compatibility shims. They route to `$ralph-specum` and are removed in version 6.

Use `$ralph-specum-triage` first when the goal is large, cross-cutting, or likely to become multiple specs. Use `$ralph-specum-start` for a single spec or to resume an existing one.

Codex Ralph is approval-gated by default. After each spec artifact, Ralph stops and asks you to approve the current artifact, request changes, or continue to the next step. Quick or autonomous flow happens only when you explicitly ask for it. Autonomous implementation uses native `/goal`; normal implementation completes one verified logical batch and returns.
Normal mode uses bundled grill-with-docs behavior before phase generation. Research, requirements, and design can also offer an optional prototype gate after the artifact walkthrough. Ralph ships these behaviors for Claude Code and documents inline fallbacks for Codex users without `$grill-with-docs` or `$prototype`.

### Claude Code

```bash
# The smart way (auto-detects resume or new)
/ralph-specum:start user-auth Add JWT authentication

# Quick mode (skip spec phases, auto-generate everything)
/ralph-specum:start "Add user auth" --quick

# The step-by-step way
/ralph-specum:new user-auth Add JWT authentication
/ralph-specum:requirements
/ralph-specum:design
/ralph-specum:tasks
/ralph-specum:implement
```

---

## Commands

For Codex, the equivalent surface is `$ralph-specum` plus 14 helper skills installed via the `ralph-specum` plugin.

| Command | What it does |
|---------|--------------|
| `/ralph-specum:start [name] [goal]` | Smart entry: resume existing or create new |
| `/ralph-specum:start [goal] --quick` | Quick mode: auto-generate all specs and execute |
| `/ralph-specum:new <name> [goal]` | Create new spec, start research |
| `/ralph-specum:research` | Run/re-run research phase |
| `/ralph-specum:requirements` | Generate requirements from research |
| `/ralph-specum:design` | Generate technical design |
| `/ralph-specum:tasks` | Break design into executable tasks |
| `/ralph-specum:implement` | Execute tasks one-by-one |
| `/ralph-specum:index` | Scan codebase and generate component specs |
| `/ralph-specum:status` | Show all specs and progress |
| `/ralph-specum:switch <name>` | Change active spec |
| `/ralph-specum:triage [name] [goal]` | Decompose large features into multiple specs (epics) |
| `/ralph-specum:cancel` | Cancel loop, cleanup state |
| `/ralph-specum:help` | Show help |

---

## How It Works

```mermaid
flowchart TD
    A["I want a feature!"] --> B{"/start detects scope"}
    B -->|Single spec| C[Research]
    B -->|"Too big for one spec"| T["/triage"]

    C -->|Analyzes codebase, searches web| D[Requirements]
    D -->|User stories, acceptance criteria| E[Design]
    E -->|Architecture, patterns, decisions| F[Tasks]
    F -->|POC-first task breakdown| G[Execution]
    G -->|Task-by-task with fresh context| H["I did it!"]

    T -->|Explore| T1[Exploration Research]
    T1 -->|Brainstorm| T2[Triage Analyst]
    T2 -->|Validate| T3[Validation Research]
    T3 -->|Finalize| T4["Epic Plan"]
    T4 -->|"Spec 1, Spec 2, ..."| C
```

### The Agents

Each phase uses a specialized sub-agent:

| Phase | Agent | Superpower |
|-------|-------|------------|
| Triage | `triage-analyst` | Feature decomposition, dependency graphs, interface contracts |
| Research | `research-analyst` | Web search, codebase analysis, feasibility checks |
| Requirements | `product-manager` | User stories, acceptance criteria, business value |
| Design | `architect-reviewer` | Architecture patterns, technical trade-offs |
| Tasks | `task-planner` | POC-first breakdown, task sequencing |
| Execution | `spec-executor` | Autonomous implementation, quality gates |

### Task Execution Workflow

Tasks follow a 4-phase structure:

1. **Make It Work** - POC validation, skip tests initially
2. **Refactoring** - Clean up the code
3. **Testing** - Unit, integration, e2e tests
4. **Quality Gates** - Lint, types, CI checks

Current Ralph planning also supports:
- `--tasks-size fine|coarse` to control task granularity
- approval checkpoints between spec phases outside quick mode
- `[P]` markers for low-conflict parallel tasks
- `[VERIFY]` and VE tasks for explicit verification work
- epic planning through `/ralph-specum:triage` or `$ralph-specum-triage`

---

## Codebase Indexing

Starting with v2.12.0, Smart Ralph can scan existing codebases and auto-generate component specs, making legacy code discoverable during new feature research.

### Why Index?

When starting a new feature on an existing codebase, the **research phase benefits from knowing what's already built**. Without indexing, the research agent has limited visibility into your codebase structure.

The `/ralph-specum:index` command:

- Scans your codebase for controllers, services, models, helpers, and migrations
- Generates searchable specs for each component
- Indexes external resources (URLs, MCP servers, installed skills)
- Makes existing code discoverable in `/ralph-specum:start`

### Quick Start

```bash
# Full interactive indexing (recommended for first-time)
/ralph-specum:index

# Quick mode - skip interviews, batch scan only
/ralph-specum:index --quick

# Dry run - preview what would be indexed
/ralph-specum:index --dry-run

# Index specific directory
/ralph-specum:index --path=src/api/

# Force regenerate all specs
/ralph-specum:index --force
```

### How It Works

```mermaid
flowchart TD
    A["/ralph-specum:index"] --> B[Pre-Scan Interview]
    B -->|External URLs? Focus areas?| C[Component Scanner]
    C -->|Controllers, services, models...| D[External Resources]
    D -->|URLs, MCP, skills| E[Post-Scan Review]
    E -->|Validates findings with user| F["specs/.index/"]
    F --- G["index.md - Summary dashboard"]
    F --- H["components/ - Code component specs"]
    F --- I["external/ - External resource specs"]
```

### Options

| Option | Description |
|--------|-------------|
| `--path=<dir>` | Limit indexing to specific directory |
| `--type=<types>` | Filter by type: controllers, services, models, helpers, migrations |
| `--exclude=<patterns>` | Patterns to exclude (e.g., test, mock) |
| `--dry-run` | Preview without writing files |
| `--force` | Regenerate all specs (overwrites existing) |
| `--changed` | Regenerate only git-changed files |
| `--quick` | Skip interviews, batch scan only |

### Recommended: Index Before Research

**For best results, run `/ralph-specum:index` before starting new features on an existing codebase.**

The research phase searches indexed specs to discover relevant existing components. Without an index, you may miss important context about what's already built.

```bash
# First time on a codebase? Index it first
/ralph-specum:index

# Then start your feature
/ralph-specum:start my-feature Add user authentication
```

When you run `/ralph-specum:start`:

1. If no index exists, you'll see a hint suggesting to run `/ralph-specum:index`
2. The spec scanner searches both regular specs AND indexed specs
3. Indexed components appear in "Related Specs" during research

### What Gets Indexed

**Components** (detected by path/name patterns):
- Controllers: `**/controllers/**/*.{ts,js,py,go}`
- Services: `**/services/**/*.{ts,js,py,go}`
- Models: `**/models/**/*.{ts,js,py,go}`
- Helpers: `**/helpers/**/*.{ts,js,py,go}`
- Migrations: `**/migrations/**/*.{ts,js,sql}`

**External Resources** (discovered via interview):
- URLs (fetched via WebFetch)
- MCP servers (queried for tools/resources)
- Installed skills (commands/agents documented)

**Default Excludes**:
`node_modules`, `vendor`, `dist`, `build`, `.git`, `__pycache__`, test files

---

## Project Structure

```text
smart-ralph/
├── core/                       # Canonical shared artifacts, schemas, rules, fixtures
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── ralph-specum/           # Claude Code plugin (self-contained)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/             # Sub-agent definitions
│   │   ├── commands/           # Slash commands
│   │   ├── hooks/              # Claude-native continuation and context hooks
│   │   ├── templates/          # Generated canonical templates
│   │   └── schemas/            # Validation schemas
│   ├── ralph-specum-codex/     # Native Codex plugin
│   │   ├── .codex-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/             # 15 skills ($ralph-specum-*)
│   │   ├── templates/          # Generated canonical templates
│   │   └── references/         # Codex-native workflow and state rules
│   └── ralph-speckit/          # Spec-kit methodology
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/             # spec-executor, qa-engineer
│       ├── commands/           # /speckit:* commands
│       └── templates/          # Constitution, spec, plan templates
├── scripts/                    # Core sync and package validation
└── README.md
```

### Your Specs

Specs live in `./specs/` in your project:

```text
./specs/
├── .current-spec           # Active spec name
└── my-feature/
    ├── .ralph-state.json   # Optional Claude runtime state, never canonical
    ├── progress.md         # Tracked durable phase and approval state
    ├── research.md
    ├── requirements.md
    ├── design.md
    └── tasks.md
```

---

## Ralph Speckit (Spec-Kit Methodology)

**ralph-speckit** is an alternative plugin implementing [GitHub's spec-kit methodology](https://github.com/github/spec-kit) with constitution-first governance.

### Key Differences from ralph-specum

| Feature | ralph-specum | ralph-speckit |
|---------|--------------|---------------|
| Directory | `./specs/` | `.specify/specs/` |
| Naming | `my-feature/` | `001-feature-name/` |
| Constitution | None | `.specify/memory/constitution.md` |
| Spec structure | research, requirements, design, tasks | spec (WHAT/WHY), plan (HOW), tasks |
| Traceability | Basic | Full FR/AC annotations |

### Installation

```bash
/plugin install ralph-speckit@smart-ralph
```

### Quick Start

```bash
# Initialize constitution (first time only)
/speckit:constitution

# Create and develop a feature
/speckit:start user-auth "Add JWT authentication"
/speckit:specify
/speckit:plan
/speckit:tasks
/speckit:implement
```

### Commands

| Command | What it does |
|---------|--------------|
| `/speckit:constitution` | Create/update project constitution |
| `/speckit:start <name> [goal]` | Create new feature with auto ID |
| `/speckit:specify` | Define feature spec (WHAT/WHY) |
| `/speckit:plan [tech]` | Create technical plan with research |
| `/speckit:tasks` | Generate task breakdown by user story |
| `/speckit:implement` | Execute tasks task-by-task |
| `/speckit:status` | Show current feature status |
| `/speckit:switch <name>` | Switch active feature |
| `/speckit:cancel` | Cancel execution loop |
| `/speckit:clarify` | Optional: clarify ambiguous requirements |
| `/speckit:analyze` | Optional: check spec consistency |

### Feature Directory Structure

```text
.specify/
├── memory/
│   └── constitution.md       # Project-level principles
├── .current-feature          # Active feature pointer
└── specs/
    ├── 001-user-auth/
    │   ├── .speckit-state.json
    │   ├── .progress.md
    │   ├── spec.md           # Requirements (WHAT/WHY)
    │   ├── research.md
    │   ├── plan.md           # Technical design (HOW)
    │   └── tasks.md
    └── 002-payment-flow/
        └── ...
```

### When to Use Which

- **ralph-specum**: Quick iterations, personal projects, simple features
- **ralph-speckit**: Enterprise projects, team collaboration, audit trails needed

---

## Troubleshooting

**Task keeps failing?**
After three failed attempts, inspect `progress.md` and the verification evidence. Fix the blocker, then run `/ralph-specum:implement` in Claude or `$ralph-specum-implement` in Codex.

**Want to start over?**
`/ralph-specum:cancel` cleans up state files. Then start fresh.

**Resume existing spec?**
Just `/ralph-specum:start` - it auto-detects and continues where you left off.

**More issues?** See the full [Troubleshooting Guide](TROUBLESHOOTING.md).

---

## Breaking Changes

### v5.0.0

**Native Claude and Codex adapters with a shared specification core**

- Claude keeps its slash commands, agents, teams, and hook-driven execution.
- Codex uses phase skills, native subagents, and `/goal` instead of a Stop hook.
- Canonical artifacts remain Markdown. `tasks.md` checkboxes are task truth.
- New specs use tracked `progress.md`. Legacy `.progress.md` is read only for migration and is never committed automatically.
- Codex auxiliary skills remain as deprecation shims for version 5 and are removed in version 6.
- Codex now requires version 0.144.0 or newer and installs as `ralph-specum-codex`.

See [Migration to v5](docs/migration-v5.md) for the compatibility and rollback procedure.

### v3.0.0

**Self-contained execution loop (no more ralph-loop dependency)**

Starting with v3.0.0, Smart Ralph is fully self-contained. The execution loop is handled by the built-in stop-hook.

**Migration from v2.x:**
1. Update Smart Ralph to v3.0.0+
2. Restart Claude Code
3. Existing specs continue working. No spec file changes needed.
4. You can optionally uninstall ralph-loop if you don't use it elsewhere

**What changed:**
- Ralph Loop dependency removed
- Stop-hook now controls the execution loop directly
- `/implement` runs the loop internally (no external invocation)
- `/cancel` only cleans up Smart Ralph state files

**Why:**
- Simpler installation (one plugin instead of two)
- No version compatibility issues between plugins
- Self-contained workflow

### v2.0.0

**Ralph Loop dependency required** *(superseded by v3.0.0)*

v2.0.0 delegated task execution to the Ralph Loop plugin. This is no longer required as of v3.0.0.

---

## Contributing

PRs welcome! This project is friendly to first-time contributors.

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes
4. Push to the branch
5. Open a PR

---

## Credits

- [Ralph agentic loop pattern](https://ghuntley.com/ralph/) by Geoffrey Huntley
- Built for [Claude Code](https://claude.ai/code)
- Inspired by every developer who wished their AI could just figure out the whole feature

---

<div align="center">

**Made with confusion and determination**

*"The doctor said I wouldn't have so many nosebleeds if I kept my finger outta there."*

MIT License

</div>
