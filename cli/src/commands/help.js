/**
 * Help command - Display usage information
 */

import { logger } from '../utils/logger.js';

const HELP_TEXT = `
${colorize('bold', 'ralph-specum')} - Spec-driven development CLI

${colorize('bold', 'USAGE')}
  ralph-specum "goal description" [options]
  ralph-specum <command> [options]

${colorize('bold', 'COMMANDS')}
  run          Start a new spec-driven workflow (default)
  approve      Approve current phase and continue
  implement    Execute tasks directly
  status       Show current workflow status
  cancel       Cancel and cleanup workflow
  help         Show this help message

${colorize('bold', 'OPTIONS')}
  -m, --mode <mode>          Workflow mode: interactive (default) or auto
  -d, --dir <path>           Spec directory (default: ./spec)
  -i, --max-iterations <n>   Max iterations before stopping (default: 10)
  -v, --version              Show version
  -h, --help                 Show help
  -q, --quiet                Suppress output
  --debug                    Show debug information
  --keep-specs               Keep spec files when canceling

${colorize('bold', 'EXAMPLES')}
  ${colorize('dim', '# Start a new workflow interactively')}
  ralph-specum "Add user authentication with OAuth2"

  ${colorize('dim', '# Start in auto mode')}
  ralph-specum "Create REST API for products" --mode auto

  ${colorize('dim', '# Check workflow status')}
  ralph-specum status

  ${colorize('dim', '# Approve current phase and continue')}
  ralph-specum approve

  ${colorize('dim', '# Execute only Phase 1 tasks (POC)')}
  ralph-specum implement 1

  ${colorize('dim', '# Execute all tasks')}
  ralph-specum implement all

  ${colorize('dim', '# Cancel workflow but keep spec files')}
  ralph-specum cancel --keep-specs

${colorize('bold', 'WORKFLOW PHASES')}
  1. ${colorize('cyan', 'Research')}      - Analyze feasibility, research best practices
  2. ${colorize('cyan', 'Requirements')}  - Generate user stories and requirements
  3. ${colorize('cyan', 'Design')}        - Create architecture and component design
  4. ${colorize('cyan', 'Tasks')}         - Break down into executable tasks
  5. ${colorize('cyan', 'Execution')}     - Execute tasks (POC → Refactor → Test → Quality)

${colorize('bold', 'MODES')}
  ${colorize('yellow', 'interactive')} (default)
    - Pauses after each phase for review
    - Requires manual approval to continue
    - Best for learning and complex projects

  ${colorize('yellow', 'auto')}
    - Runs all phases automatically
    - Stops on errors or max iterations
    - Best for well-defined tasks

${colorize('bold', 'TASK PHASES')}
  Phase 1: Make It Work  - POC validation, skip tests
  Phase 2: Refactoring   - Code cleanup, error handling
  Phase 3: Testing       - Unit/integration/E2E tests
  Phase 4: Quality Gates - Lint, types, CI, PR creation

${colorize('bold', 'FILES CREATED')}
  ./spec/<feature>/
    ├── .ralph-state.json    # Workflow state (auto-deleted)
    ├── .ralph-progress.md   # Progress tracking (auto-deleted)
    ├── research.md          # Research findings
    ├── requirements.md      # User stories & requirements
    ├── design.md            # Architecture & design
    └── tasks.md             # Executable task list

${colorize('bold', 'LEARN MORE')}
  Documentation: https://github.com/tzachbon/ralph-specum
`;

/**
 * Display help text
 */
export async function helpCommand(parsed) {
  console.log(HELP_TEXT);

  // Show specific command help if requested
  if (parsed.args && parsed.args.length > 0) {
    const command = parsed.args[0];
    showCommandHelp(command);
  }
}

/**
 * Show help for specific command
 */
function showCommandHelp(command) {
  const commandHelp = {
    run: `
${colorize('bold', 'ralph-specum run')}

Start a new spec-driven development workflow.

Usage:
  ralph-specum "goal description" [options]
  ralph-specum run "goal description" [options]

Options:
  --mode <mode>          interactive or auto
  --dir <path>           Output directory for specs
  --max-iterations <n>   Max agent iterations

Examples:
  ralph-specum "Add dark mode toggle to settings"
  ralph-specum run "Create user dashboard" --mode auto
`,
    approve: `
${colorize('bold', 'ralph-specum approve')}

Approve the current phase and continue to the next phase.

Usage:
  ralph-specum approve [options]

Options:
  --dir <path>    Spec directory to look in

This command is used in interactive mode to review and approve
each phase before continuing. Review the generated .md files
before approving.
`,
    implement: `
${colorize('bold', 'ralph-specum implement')}

Execute tasks directly, optionally filtering by phase.

Usage:
  ralph-specum implement [phase] [options]

Arguments:
  phase    1, 2, 3, 4, or "all" (default: all)

Options:
  --dir <path>    Spec directory

Examples:
  ralph-specum implement        # Execute all tasks
  ralph-specum implement 1      # Execute only Phase 1 (POC)
  ralph-specum implement 2      # Execute only Phase 2 (Refactor)
`,
    status: `
${colorize('bold', 'ralph-specum status')}

Show the current workflow status.

Usage:
  ralph-specum status [options]

Options:
  --dir <path>    Spec directory
  --verbose       Show full progress file content
`,
    cancel: `
${colorize('bold', 'ralph-specum cancel')}

Cancel the current workflow and cleanup state files.

Usage:
  ralph-specum cancel [options]

Options:
  --dir <path>      Spec directory
  --keep-specs      Don't delete spec files (research.md, etc)
  --all             Cancel all active workflows
`,
  };

  if (commandHelp[command]) {
    console.log(commandHelp[command]);
  }
}

/**
 * Colorize helper
 */
function colorize(style, text) {
  const styles = {
    bold: '\x1b[1m',
    dim: '\x1b[2m',
    cyan: '\x1b[36m',
    yellow: '\x1b[33m',
    reset: '\x1b[0m',
  };
  return `${styles[style] || ''}${text}${styles.reset}`;
}
