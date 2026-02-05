---
type: external-spec
generated: true
source-type: url
source-id: https://www.aihero.dev/getting-started-with-ralph
fetched: 2026-02-05T15:28:01+02:00
---

# Getting Started with Ralph

## Source
- **Type**: url
- **URL/ID**: https://www.aihero.dev/getting-started-with-ralph
- **Fetched**: 2026-02-05T15:28:01+02:00

## Summary
Ralph is a technique for running AI coding agents in automated loops. The agent repeatedly executes the same prompt, selects tasks from a PRD, commits after each feature, and returns completed code.

## Key Sections

### Setup Instructions
1. **Install Claude Code**: Via native binary with `curl -fsSL https://claude.ai/install.sh | bash` or npm
2. **Install Docker Desktop**: Download 4.50+ and run `docker sandbox run claude` for isolated environment
3. **Create Planning Documents**: Generate PRD.md using Claude's plan mode (Shift+Tab); create empty progress.txt

### Core Workflow

#### Phase 1 - Human-in-the-Loop
Create `ralph-once.sh` script with `--permission-mode acceptEdits` flag. Runs one task at a time for review.

#### Phase 2 - Autonomous
Wrap script in loop using `afk-ralph.sh` with iteration limits (e.g., `./afk-ralph.sh 20`). Use `-p` print flag and completion marker `<promise>COMPLETE</promise>`.

### Best Practices
- Reference both `@PRD.md` and `@progress.txt` in prompts
- Enforce single-task commits for granular progress tracking
- Start with human oversight before going autonomous
- Set iteration caps to control costs
- PRD can use any format (markdown, JSON, prose)

### Flexibility
Task sources can shift from local files to GitHub Issues or Linear. Loop types can address test coverage, linting, or code duplication.

## AI Context
**Keywords**: ralph setup PRD progress.txt human-in-the-loop autonomous iteration-caps single-task-commits docker-sandbox
**Related components**: plugins/ralph-specum/commands/implement.md, plugins/ralph-specum/agents/spec-executor.md
