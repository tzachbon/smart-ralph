# Smart Ralph

A Claude Code plugin marketplace for spec-driven development. Task-by-task execution with fresh context per task.

## Plugins

| Plugin | Description |
|--------|-------------|
| **ralph-specum** | Spec-driven development with research, requirements, design, tasks, and autonomous execution |

## Installation

### From Marketplace

```bash
# Add the marketplace
/plugin marketplace add tzachbon/ralph-specum

# Install the plugin
/plugin install ralph-specum@smart-ralph

# Restart Claude Code to load
```

### From GitHub

```bash
/plugin install https://github.com/tzachbon/ralph-specum
```

### Local Development

```bash
# Clone and test specific plugin
git clone https://github.com/tzachbon/ralph-specum.git
cd ralph-specum/plugins/ralph-specum
claude --plugin-dir $(pwd)

# Or from repo root
claude --plugin-dir ./plugins/ralph-specum
```

Restart Claude Code after changes.

## Quick Start

```bash
# Smart entry point (auto-detects resume or new)
/ralph-specum:start user-auth Add JWT authentication

# Or step by step
/ralph-specum:new user-auth Add JWT authentication
/ralph-specum:requirements
/ralph-specum:design
/ralph-specum:tasks
/ralph-specum:implement
```

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-specum:start [name] [goal]` | Smart entry point: resume or create new |
| `/ralph-specum:new <name> [goal]` | Create new spec and start research |
| `/ralph-specum:research` | Run/re-run research phase |
| `/ralph-specum:requirements` | Generate requirements |
| `/ralph-specum:design` | Generate design |
| `/ralph-specum:tasks` | Generate tasks |
| `/ralph-specum:implement` | Start execution loop |
| `/ralph-specum:status` | Show all specs and progress |
| `/ralph-specum:switch <name>` | Change active spec |
| `/ralph-specum:cancel` | Cancel loop, cleanup state |
| `/ralph-specum:help` | Show help |

## Workflow

```
/ralph-specum:start "my-feature"
    |
    v
[Research] -> research.md
    |
    v
[Requirements] -> requirements.md
    |
    v
[Design] -> design.md
    |
    v
[Tasks] -> tasks.md
    |
    v
[Execution] -> task-by-task with fresh context
    |
    v
Done!
```

## Sub-Agents

| Phase | Agent | Purpose |
|-------|-------|---------|
| Research | `research-analyst` | Web search, codebase analysis, feasibility |
| Requirements | `product-manager` | User stories, acceptance criteria |
| Design | `architect-reviewer` | Architecture, patterns, decisions |
| Tasks | `task-planner` | POC-first task breakdown |
| Execution | `spec-executor` | Autonomous task implementation |

## POC-First Workflow

Tasks follow a 4-phase structure:
1. **Phase 1: Make It Work** - POC validation, skip tests
2. **Phase 2: Refactoring** - Clean up code
3. **Phase 3: Testing** - Unit, integration, e2e
4. **Phase 4: Quality Gates** - Lint, types, CI

## Marketplace Structure

```
smart-ralph/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── ralph-specum/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/
│       ├── commands/
│       ├── hooks/
│       ├── templates/
│       └── schemas/
└── README.md
```

## User Files

Specs are stored in `./specs/` in your project:

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

## Troubleshooting

**Task failing repeatedly?**
After 5 attempts, hook blocks with error. Fix manually, run `/ralph-specum:implement` to resume.

**Want to restart?**
Run `/ralph-specum:cancel` to cleanup state, then start fresh.

**Resume existing spec?**
Just run `/ralph-specum:start` - it auto-detects and resumes.

## Credits

- [Ralph Wiggum](https://ghuntley.com/ralph/) agentic loop pattern
- Built for [Claude Code](https://claude.ai/code)

## License

MIT
