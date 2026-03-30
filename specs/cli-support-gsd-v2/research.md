# Research: cli-support-gsd-v2

## Executive Summary

GSD v2 is a standalone TypeScript CLI (`gsd-pi`) built on the Pi SDK that provides headless/CI support, 20+ LLM providers, and a structured work hierarchy (milestone -> slice -> task). Smart Ralph's current plugin architecture has high CLI extraction feasibility: the spec management layer (file formats, state schema, templates, shell utilities) is fully portable, while the AI orchestration layer (Task tool, Team lifecycle, hooks) needs rewriting as a standard run loop with direct API calls. The industry has converged on a `init -> specify -> plan -> run` CLI pattern, and Commander.js is the recommended framework for a Node.js/TypeScript CLI binary.

## External Research

### GSD v2 Analysis

GSD exists in two major versions:
- **GSD v1** (`get-shit-done`, 45k stars): Prompt framework installed as slash commands into 8 AI tool runtimes (Claude Code, Gemini CLI, Codex, Copilot, Cursor, Windsurf, etc.)
- **GSD v2** (`gsd-pi`, 3.7k stars): Standalone TypeScript CLI application with its own agent harness

#### GSD v2 Key CLI Commands

| Command | Purpose |
|---------|---------|
| `gsd` | Launch interactive TUI |
| `gsd --web` | Browser-based web interface |
| `gsd headless --timeout N` | CI/automation mode |
| `gsd headless query` | JSON state snapshot (~50ms, no LLM) |
| `gsd headless next` | One unit at a time (cron-friendly) |
| `gsd headless dispatch plan` | Force a specific pipeline phase |
| `/login` | Select LLM provider (20+ options) |
| `/model` | Switch models |
| `/gsd doctor` | Validate worktree health |

Exit codes: `0` = complete, `1` = error/timeout, `2` = blocked.

#### GSD v2 Architecture
- Language: TypeScript 92.8%, with Rust and Shell
- 19 bundled extensions (GSD core, Browser Tools, Subagent, GitHub, MCP Client, Voice, etc.)
- Branch-per-slice with automated squash merge
- Fresh context window per task (context rot elimination)
- Work hierarchy: Milestone -> Slice (1-7 tasks) -> Task (fits one context window)

#### GSD v1 Multi-Runtime Support
Installs into 8 runtimes via flags: `--claude`, `--gemini`, `--codex`, `--copilot`, `--cursor`, `--windsurf`, `--antigravity`, `--all`

### AI CLI Landscape

#### Tool Comparison

| Tool | Type | Multi-Model | Spec Workflow | Key Pattern |
|------|------|-------------|---------------|-------------|
| Aider | CLI | Excellent (Claude, GPT, DeepSeek, Ollama) | Architect mode separates planning/execution | Session-based, no persistent spec |
| Cline | VS Code + CLI | BYOM | Plan/Act architecture | Human-in-the-loop approval |
| Continue.dev | IDE + headless CLI | Fully agnostic | No native spec workflow | Maximum customizability |
| Goose (Block) | CLI + desktop | 25+ providers | Recipes (YAML specs) | Composable, shareable workflows |
| Kiro (AWS) | Standalone IDE | AWS models | Native 3-phase: Requirements -> Design -> Tasks | Documentation-first |
| GitHub Spec Kit | CLI toolkit | Fully agnostic | 4-stage: Specify -> Plan -> Tasks -> Implement | Spec-as-interface pattern |
| BMAD-METHOD | Multi-agent framework | Model-agnostic | Named agent personas per phase | 8 agents, 30+ workflows |

#### Multi-AI Support Approaches

1. **BYOM (API key injection)**: Cline, Continue.dev, Goose accept any model via API key
2. **Spec-as-interface**: GitHub Spec Kit generates spec artifacts any AI tool can consume (most future-proof)
3. **Orchestration layer**: Route different task types to different models

**Recommendation**: Smart Ralph should adopt approach #2 (spec-as-interface) since it already stores specs as markdown files.

### CLI Frameworks

#### Comparison

| | Commander | Yargs | oclif | Clipanion | Citty |
|---|---|---|---|---|---|
| Dependencies | 0 | ~7 | ~30 | 0 | ~0 |
| TypeScript | Excellent | Manual | First-class | First-class | Native |
| Plugin system | No | Middleware | Yes | No | No |
| Startup speed | Fast (~20ms) | Moderate (~40ms) | Slow (~100ms) | Fast | Fast |
| Maturity | Very high | High | High | High | Lower |

**Recommendation: Commander.js** for zero dependencies, fast startup, excellent TypeScript support, and flexible structure. Migrate to oclif later if plugin ecosystem needed.

### Best Practices
- Subcommands: max 2 levels deep, consistent noun-verb ordering
- Config: XDG Base Directory spec (`~/.config/ralph/`)
- Output: Chalk for colors, Ora/listr2 for spinners, `--json` flag for CI
- Distribution: tsup/tsdown bundler, npm bin field, single-file bundle for npx

### Pitfalls to Avoid
- GSD v2's Pi SDK dependency creates lock-in; use Anthropic SDK directly or support multiple SDKs
- Feature sprawl (GSD v2 ships 19 extensions); start with core workflow loop
- Don't replace the existing plugin; complement it

## Codebase Analysis

### Current Architecture

Smart Ralph is a Claude Code plugin with:
- **Commands** (`commands/*.md`): Slash commands triggered by users
- **Agents** (`agents/*.md`): Sub-agent definitions with prompts
- **Hooks** (`hooks/`): Stop-hook loop, session context loader, quick-mode guard
- **Templates** (`templates/*.md`): Spec file templates
- **Schemas** (`schemas/`): JSON Schema for state validation

### Claude Code Dependencies

| Hard Dependency | Where Used | CLI Replacement |
|----------------|-----------|-----------------|
| `Task` tool | All commands | Direct API calls |
| `TeamCreate`/`TeamDelete` | Parallel research | `Promise.all` concurrent API calls |
| `AskUserQuestion` | Goal capture, approvals | readline/inquirer CLI prompts |
| Stop hook event | Execution loop | Standard `while` loop |
| `Skill` tool | Skill discovery | N/A or custom registry |
| `SendMessage` | Agent communication | Direct function calls |
| `${CLAUDE_PLUGIN_ROOT}` | All commands | CLI install path |

### Portable Components (zero changes)

- Spec file formats (research.md, requirements.md, design.md, tasks.md)
- State schema (spec.schema.json)
- Path resolver (path-resolver.sh)
- Task format and parsing (awk-based, self-contained)
- Agent prompt content (strip frontmatter, use as system prompts)
- Templates and reference docs
- `.ralph-state.json` state management

### Extraction Boundaries

1. **Spec Management Layer** (portable): File I/O, state JSON, path resolution, task parsing, index generation
2. **AI Orchestration Layer** (needs rewrite): Phase commands -> async functions, stop-hook -> while loop, TeamCreate -> Promise.all
3. **Prompt Content** (reusable): Agent body text is 100% reusable as system prompts

### Complexity Assessment

| Component | Effort | Notes |
|-----------|--------|-------|
| Spec file I/O | Low | Copy shell scripts, wrap in CLI |
| State management | Low | jq patterns -> JSON library |
| Agent prompts | Low | Strip frontmatter, use as system prompts |
| Phase commands | Medium | Rewrite as async functions |
| Execution loop | Medium | Stop-hook -> while loop |
| Parallel execution | Medium | TeamCreate -> Promise.all |
| Research phase | High | Multiple concurrent API calls with merging |

**Overall extraction feasibility: HIGH.**

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Test | `npm test` | package.json (if configured) |
| Lint | Project-dependent | eslint config |
| Build | N/A (no build step) | CLAUDE.md states no build required |

Note: Smart Ralph is a plugin with no build step. Changes take effect on Claude Code restart.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Technical feasibility | High | Spec layer is portable, orchestration is well-documented |
| Effort estimate | Medium (M) | Core CLI in 2-3 weeks, full parity in 6-8 weeks |
| Risk | Low-Medium | Main risk is maintaining two codebases (plugin + CLI) |
| Multi-AI support | High feasibility | Spec-as-interface pattern already in place |
| CI/headless support | High feasibility | Replace stop-hook with run loop + exit codes |

## Recommendations for Requirements

1. **Start with spec management CLI**: `ralph init`, `ralph new`, `ralph status`, `ralph cancel` - no AI calls needed
2. **Add AI-powered phases incrementally**: research -> requirements -> design -> tasks -> implement
3. **Use Commander.js** with tsup/tsdown for bundling
4. **Adopt spec-as-interface pattern**: Same markdown files work with CLI and plugin
5. **Support headless mode from day one**: `--json` output, exit codes, `--timeout` flag
6. **Multi-AI installer**: `ralph init --ai claude|codex|cursor` to install specs into different AI tool directories
7. **Maintain plugin compatibility**: CLI reads/writes same file formats as the plugin

### Suggested CLI Surface

```shell
ralph init [--ai <tool>]          # Install/configure for target AI tool
ralph new <name> "<goal>"         # Create new spec
ralph research [name]             # Run research phase
ralph spec [name]                 # Generate requirements + design
ralph plan [name]                 # Generate task breakdown
ralph run [name] [--headless]     # Execute tasks
ralph status [name] [--json]      # Show state (CI-friendly)
ralph cancel [name]               # Cancel execution
ralph doctor                      # Validate project health
```

## Open Questions

1. Should the CLI embed the Anthropic SDK directly, or shell out to `claude` CLI for execution?
2. Should the CLI be published as `@smart-ralph/cli` or `ralph-cli` or just `ralph`?
3. How to handle the plugin <-> CLI sync? Should they share a package or be fully separate?
4. Should the CLI support Goose-style YAML recipes for shareable workflows?
5. Is there value in a web UI mode (like GSD v2's `--web` flag)?

## Sources

- GitHub: glittercowboy/get-shit-done (GSD v1, 45k stars)
- GitHub: gsd-build/gsd-2 (GSD v2, 3.7k stars)
- GitHub: github/spec-kit (GitHub Spec Kit)
- GitHub: block/goose (Goose, 30k+ stars)
- GitHub: paul-gauthier/aider (Aider)
- GitHub: cline/cline (Cline)
- GitHub: continuedev/continue (Continue.dev)
- GitHub: aws/kiro (Kiro)
- GitHub: bmad-sim/BMAD-METHOD (BMAD-METHOD)
- npm: commander, yargs, oclif, clipanion, citty
- plugins/ralph-specum/ (Smart Ralph codebase analysis)
