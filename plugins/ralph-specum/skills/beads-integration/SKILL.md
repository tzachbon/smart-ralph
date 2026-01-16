# Beads Integration

Smart Ralph uses [Beads](https://github.com/steveyegge/beads) as the core workflow engine for dependency-aware task execution.

## What is Beads?

Beads is a lightweight, git-based issue tracker designed specifically for AI coding agents. It provides:

- **Dependency-aware task management** via `--blocks` relationships
- **Ready-work detection** with `bd list --ready` (~10ms)
- **Hash-based IDs** that prevent collisions during parallel execution
- **Git-native sync** via JSONL export
- **Audit trail** through commit message conventions

## How Smart Ralph Uses Beads

### Spec Lifecycle

```
/ralph-specum:start
        │
        ▼
┌───────────────────┐
│ research-analyst  │ ──► bd create --type epic (parent spec issue)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   task-planner    │ ──► bd create --parent $SPEC --blocks $PREV (task issues)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   coordinator     │ ──► bd list --ready (find executable tasks)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  spec-executor    │ ──► bd close $ID (mark complete)
└───────────────────┘
        │
        ▼
    bd sync (push to git)
```

### Dependency Graph

Tasks are created with explicit `--blocks` relationships:

```
┌─────────────────┐
│  1.1 Setup      │
└────────┬────────┘
         │ blocks
┌────────▼────────┐
│ 1.2 Implement   │
└────────┬────────┘
         │ blocks
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───┐
│ 1.3   │ │ 1.4   │  ← Both ready when 1.2 completes
└───┬───┘ └───┬───┘  ← Execute in parallel
    │         │
    └────┬────┘
         │ blocks
┌────────▼────────┐
│ V1 [VERIFY]     │
└─────────────────┘
```

### Key Commands

| Command | When Used | Who Uses It |
|---------|-----------|-------------|
| `bd init` | Spec creation | research-analyst |
| `bd create --type epic` | Create spec | research-analyst |
| `bd create --parent --blocks` | Create tasks | task-planner |
| `bd list --ready --json` | Find work | coordinator |
| `bd update --notes` | Record learnings | spec-executor |
| `bd close --reason` | Complete task | spec-executor |
| `bd doctor` | Check health | coordinator |
| `bd sync` | Push to git | coordinator |

## Commit Message Convention

All commits include Beads issue IDs:

```bash
feat(auth): implement OAuth2 login (bd-abc123)
refactor(auth): extract token service (bd-def456)
test(auth): add integration tests (bd-ghi789)
```

This creates a complete audit trail linking code to issues.

## Land the Plane Protocol

Every spec execution ends with:

```bash
# 1. Check for orphaned work
bd doctor

# 2. Sync to git
git pull --rebase
bd sync
git push

# 3. Verify clean state
git status  # Should show "up to date"
```

## tasks.md vs Beads

| Aspect | tasks.md | Beads |
|--------|----------|-------|
| Purpose | Detailed specification | Workflow tracking |
| Contains | Do/Files/Verify/Commit | Status/Dependencies |
| Checkboxes | Human readability | Source of truth |
| Dependencies | Implicit (ordering) | Explicit (`--blocks`) |
| Parallel detection | Manual `[P]` markers | Automatic via ready query |

**tasks.md** is the recipe (what to do).
**Beads** is the kitchen workflow (what's ready, what's done).

## Prerequisites

Beads is **required** for Smart Ralph. Install:

```bash
brew install steveyegge/tap/beads
```

## Troubleshooting

**"bd: command not found"**
Install Beads: `brew install steveyegge/tap/beads`

**"No ready tasks but issues still open"**
Possible circular dependency. Check: `bd list --open --json`

**"Beads issue not found"**
Task ID mismatch between tasks.md and Beads. Recreate issues via task-planner.

## References

- [Beads Repository](https://github.com/steveyegge/beads)
- [Beads Agent Instructions](https://github.com/steveyegge/beads/blob/main/AGENT_INSTRUCTIONS.md)
- [Beads FAQ](https://github.com/steveyegge/beads/blob/main/docs/FAQ.md)
