#!/usr/bin/env bun

import { parseArgs } from './utils/args.js';
import { logger } from './utils/logger.js';
import { runCommand } from './commands/run.js';
import { approveCommand } from './commands/approve.js';
import { implementCommand } from './commands/implement.js';
import { cancelCommand } from './commands/cancel.js';
import { helpCommand } from './commands/help.js';
import { statusCommand } from './commands/status.js';

const VERSION = '1.2.0';

const COMMANDS = {
  run: runCommand,
  approve: approveCommand,
  implement: implementCommand,
  cancel: cancelCommand,
  status: statusCommand,
  help: helpCommand,
};

export async function main(args) {
  const parsed = parseArgs(args);

  // Handle version flag
  if (parsed.flags.version || parsed.flags.v) {
    console.log(`ralph-specum v${VERSION}`);
    process.exit(0);
  }

  // Handle help flag or help command
  if (parsed.flags.help || parsed.flags.h || parsed.command === 'help') {
    await helpCommand(parsed);
    process.exit(0);
  }

  // Default to 'run' if no command but has a goal
  const command = parsed.command || (parsed.goal ? 'run' : 'help');
  const handler = COMMANDS[command];

  if (!handler) {
    logger.error(`Unknown command: ${command}`);
    logger.info('Run "ralph-specum help" for usage information');
    process.exit(1);
  }

  try {
    await handler(parsed);
  } catch (error) {
    logger.error(`Command failed: ${error.message}`);
    if (parsed.flags.debug) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run if executed directly
if (import.meta.main) {
  main(process.argv.slice(2));
}
