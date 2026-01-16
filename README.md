<div align="center">

<img src="smart-ralph.png" alt="Smart Ralph" width="500"/>

# Smart Ralph

### *"Me fail specs? That's unpossible!"*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Spec-driven development for Claude Code. Task-by-task execution with fresh context per task.**

Ralph Wiggum + Spec-Driven Development = <3

[Quick Start](#-quick-start) | [Commands](#-commands) | [How It Works](#-how-it-works) | [Troubleshooting](#-troubleshooting)

</div>

---

## What is this?

Smart Ralph is a Claude Code plugin that turns your vague feature ideas into structured specs, then executes them task-by-task. Like having a tiny product team in your terminal.

```
You: "Add user authentication"
Ralph: *creates research.md, requirements.md, design.md, tasks.md*
Ralph: *executes each task with fresh context*
Ralph: "I'm helping!"
```

## Why "Ralph"?

Named after the [Ralph agentic loop pattern](https://ghuntley.com/ralph/) and everyone's favorite Springfield student. Ralph doesn't overthink. Ralph just does the next task. Be like Ralph.

---

## Requirements

**v2.0.0+** requires the Ralph Wiggum plugin for task execution:

```bash
/plugin install ralph-wiggum@claude-plugins-official
```

Ralph Wiggum provides the execution loop. Smart Ralph provides the spec-driven workflow on top.

---

## Installation

### From Marketplace

```bash
# Install Ralph Wiggum dependency first
/plugin install ralph-wiggum@claude-plugins-official

# Add the marketplace
/plugin marketplace add tzachbon/smart-ralph

# Install the plugin
/plugin install ralph-specum@smart-ralph

# Restart Claude Code
```

### From GitHub

```bash
# Install Ralph Wiggum dependency first
/plugin install ralph-wiggum@claude-plugins-official

/plugin install https://github.com/tzachbon/smart-ralph
```

### Local Development

```bash
# Install Ralph Wiggum dependency first
/plugin install ralph-wiggum@claude-plugins-official

git clone https://github.com/tzachbon/smart-ralph.git
cd smart-ralph/plugins/ralph-specum
claude --plugin-dir $(pwd)
```

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
| `/ralph-specum:status` | Show all specs and progress |
| `/ralph-specum:switch <name>` | Change active spec |
| `/ralph-specum:cancel` | Cancel loop, cleanup state |
| `/ralph-specum:help` | Show help |

---

## How It Works

```
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

## Project Structure

```
smart-ralph/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── ralph-specum/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/           # Sub-agent definitions
│       ├── commands/         # Slash commands
│       ├── hooks/            # Stop watcher (logging only)
│       ├── templates/        # Spec templates
│       └── schemas/          # Validation schemas
└── README.md
```

### Your Specs

Specs live in `./specs/` in your project:

```
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

## Troubleshooting

**"Ralph Wiggum plugin not found"?**
Install the dependency: `/plugin install ralph-wiggum@claude-plugins-official`

**Task keeps failing?**
After max iterations, the loop stops. Check `.progress.md` for errors. Fix manually, then `/ralph-specum:implement` to resume.

**Want to start over?**
`/ralph-specum:cancel` cleans up state (both Ralph Wiggum and Smart Ralph state files). Then start fresh.

**Resume existing spec?**
Just `/ralph-specum:start` - it auto-detects and continues where you left off.

**"Loop state conflict"?**
Another Ralph loop may be running. Use `/cancel-ralph` to reset Ralph Wiggum state, then retry.

---

## Breaking Changes

### v2.0.0

**Ralph Wiggum dependency required**

Starting with v2.0.0, Smart Ralph delegates task execution to the official Ralph Wiggum plugin.

**Migration from v1.x:** See [MIGRATION.md](MIGRATION.md) for detailed guide.

Quick version:
1. Install Ralph Wiggum: `/plugin install ralph-wiggum@claude-plugins-official`
2. Restart Claude Code
3. Existing specs continue working. No spec file changes needed.

**What changed:**
- Custom stop-handler removed. Ralph Wiggum provides the execution loop.
- `/implement` now invokes `/ralph-loop` internally
- `/cancel` now calls `/cancel-ralph` for cleanup
- Same task format, same verification, same workflow. Just different internals.

**Why:**
- Less code to maintain (deleted ~300 lines of bash)
- Official plugin gets updates and fixes
- Better reliability for the execution loop

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
