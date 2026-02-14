<div align="center">

<img src="smart-ralph.png" alt="Smart Ralph" width="500"/>

# Smart Ralph

### *"Me fail specs? That's unpossible!"*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Spec-driven development for Claude Code. Task-by-task execution with fresh context per task.**

Execution loop powered by [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum). Requires Ralph Wiggum plugin.

[Quick Start](#-quick-start) | [Commands](#-commands) | [How It Works](#-how-it-works) | [Troubleshooting](#-troubleshooting)

</div>

---

## What is this?

Smart Ralph is a Claude Code plugin that turns your vague feature ideas into structured specs, then executes them task-by-task. Like having a tiny product team in your terminal.

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

### Requirements

- [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) plugin (provides `/ralph-loop` execution loop)

```bash
# 1. Install Ralph Wiggum (required dependency)
/plugin install ralph-wiggum@claude-plugins-official

# 2. Install Smart Ralph
/plugin marketplace add tzachbon/smart-ralph
/plugin install ralph-specum@smart-ralph

# 3. Restart Claude Code
```

<details>
<summary>Troubleshooting & alternative methods</summary>

**Install from GitHub directly:**
```bash
/plugin install https://github.com/tzachbon/smart-ralph
```

**Local development:**
```bash
git clone https://github.com/tzachbon/smart-ralph.git
claude --plugin-dir ./smart-ralph/plugins/ralph-specum
```

</details>

---

## Quick Start

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
| `/ralph-specum:cancel` | Cancel loop, cleanup state |
| `/ralph-specum:help` | Show help |

---

## How It Works

```text
        "I want a feature!"
               |
               v
    +---------------------+
    |      Research       |  <- Analyzes codebase, searches web
    +---------------------+
               |
               v
    +---------------------+
    |    Requirements     |  <- User stories, acceptance criteria
    +---------------------+
               |
               v
    +---------------------+
    |       Design        |  <- Architecture, patterns, decisions
    +---------------------+
               |
               v
    +---------------------+
    |       Tasks         |  <- POC-first task breakdown
    +---------------------+
               |
               v
    +---------------------+
    |     Execution       |  <- Task-by-task with fresh context
    +---------------------+
               |
               v
          "I did it!"
```

### The Agents

Each phase uses a specialized sub-agent:

| Phase | Agent | Superpower |
|-------|-------|------------|
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

```text
     /ralph-specum:index
             |
             v
  +---------------------+
  |  Pre-Scan Interview |  <- External URLs? Focus areas? Sparse areas?
  +---------------------+
             |
             v
  +---------------------+
  |  Component Scanner  |  <- Detects controllers, services, models...
  +---------------------+
             |
             v
  +---------------------+
  | External Resources  |  <- Fetches URLs, queries MCP, introspects skills
  +---------------------+
             |
             v
  +---------------------+
  |  Post-Scan Review   |  <- Validates findings with user
  +---------------------+
             |
             v
      specs/.index/
       ├── index.md          # Summary dashboard
       ├── components/       # Code component specs
       └── external/         # External resource specs
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
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── ralph-specum/           # Spec workflow (requires Ralph Wiggum)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/             # Sub-agent definitions
│   │   ├── commands/           # Slash commands
│   │   ├── hooks/              # Stop watcher (controls execution loop)
│   │   ├── templates/          # Spec templates
│   │   └── schemas/            # Validation schemas
│   └── ralph-speckit/          # Spec-kit methodology
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/             # spec-executor, qa-engineer
│       ├── commands/           # /speckit:* commands
│       └── templates/          # Constitution, spec, plan templates
└── README.md
```

### Your Specs

Specs live in `./specs/` in your project:

```text
./specs/
├── .current-spec           # Active spec name
└── my-feature/
    ├── .ralph-state.json   # Loop state (deleted on completion)
    ├── .progress.md        # Progress tracking
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

**"Ralph Wiggum not found" error?**
Smart Ralph v4.0.0+ requires the Ralph Wiggum plugin. Install it:
```bash
/plugin install ralph-wiggum@claude-plugins-official
```
Then restart Claude Code and retry `/ralph-specum:implement`.

**Task keeps failing?**
After max iterations, the loop stops. Check `.progress.md` for errors. Fix manually, then `/ralph-specum:implement` to resume.

**Want to start over?**
`/ralph-specum:cancel` cleans up state files and stops any active Ralph loop. Then start fresh.

**Resume existing spec?**
Just `/ralph-specum:start` - it auto-detects and continues where you left off.

**More issues?** See the full [Troubleshooting Guide](TROUBLESHOOTING.md).

---

## Breaking Changes

### v4.0.0

**Ralph Wiggum dependency required**

Starting with v4.0.0, Smart Ralph delegates execution loop control to the [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) plugin. You must install Ralph Wiggum before using `/ralph-specum:implement`.

**Migration from v3.x:**
1. Install Ralph Wiggum: `/plugin install ralph-wiggum@claude-plugins-official`
2. Update Smart Ralph to v4.0.0+
3. Restart Claude Code
4. Existing specs continue working. No spec file changes needed.

**What changed:**
- Execution loop now powered by Ralph Wiggum (`/ralph-loop`)
- Stop-hook is passive (logging only, no loop control output)
- `/implement` invokes `/ralph-loop` with the coordinator prompt
- `/cancel` calls `/cancel-ralph` before cleaning up state files

**Why:**
- Better loop reliability via dedicated loop plugin
- Cleaner separation of concerns (loop control vs. task orchestration)
- Shared loop infrastructure across plugins

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
