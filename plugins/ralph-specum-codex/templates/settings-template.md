---
enabled: true
default_max_iterations: 5
auto_commit_spec: true
quick_mode_default: false
specs_dirs: ["./specs"]
---

# Ralph Specum Configuration

This file configures Ralph Specum plugin behavior for this project.

## Settings

### enabled
Enable/disable the plugin entirely. Set to `false` to disable all hooks and commands.

### default_max_iterations
Default maximum retries per failed task before blocking (default: 5).

### auto_commit_spec
Whether to automatically commit spec files after generation (default: true).

### quick_mode_default
Whether to run in quick mode by default when no flag provided (default: false).

### specs_dirs
Array of directories where specs can be stored (default: `["./specs"]`).

This enables organizing specs across multiple directories, useful for:
- **Monorepos**: Keep specs close to their related packages
- **Large projects**: Group specs by feature area or team
- **Separation of concerns**: Distinguish infra specs from product specs

When a spec name exists in multiple directories, commands will prompt for disambiguation.

## Usage

Create this file at `.claude/ralph-specum.local.md` in your project root to customize plugin behavior.

## Example

```yaml
---
enabled: true
default_max_iterations: 3
auto_commit_spec: false
quick_mode_default: true
---

# Ralph Specum Configuration

Custom settings for this project.
```

## Monorepo Example

For monorepos, configure multiple specs directories to keep specs organized by package:

```yaml
---
enabled: true
specs_dirs:
  - "./specs"
  - "./packages/frontend/specs"
  - "./packages/backend/specs"
  - "./packages/shared/specs"
---

# Ralph Specum Configuration

Specs are organized by package in this monorepo.
```

With this setup:
- `/ralph-specum:start my-feature` creates spec in `./specs/` (first configured dir)
- `/ralph-specum:start my-feature --specs-dir ./packages/frontend/specs` creates in frontend
- `/ralph-specum:status` lists all specs from all configured directories
- `/ralph-specum:switch my-feature` prompts if name exists in multiple directories
