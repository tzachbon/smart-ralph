import { Command } from 'commander';
import { createRequire } from 'module';
import { setDebugMode, setJsonMode, error } from './lib/output.js';
import type { RalphError } from './lib/errors.js';

const require = createRequire(import.meta.url);
const pkg = require('../package.json') as { version: string };

const program = new Command();

program
  .name('ralph')
  .description('Smart Ralph CLI for spec-driven development')
  .version(pkg.version)
  .option('--debug', 'enable debug output', false)
  .option('--no-color', 'disable color output')
  .option('--json', 'output JSON where supported', false)
  .hook('preAction', (thisCommand) => {
    const opts = thisCommand.opts() as { debug: boolean; json: boolean };
    setDebugMode(opts.debug);
    setJsonMode(opts.json);
  });

// Subcommands — imported lazily to keep startup fast
program
  .command('init', 'Initialize ralph in the current project (or globally with --global)', {
    executableFile: 'commands/init',
  });

program
  .command('new', 'Create a new spec', {
    executableFile: 'commands/new',
  });

program
  .command('switch', 'Switch the active spec', {
    executableFile: 'commands/switch',
  });

program
  .command('status', 'Show status of the active or named spec', {
    executableFile: 'commands/status',
  });

program
  .command('cancel', 'Cancel active execution for a spec', {
    executableFile: 'commands/cancel',
  });

program
  .command('doctor', 'Check environment and configuration', {
    executableFile: 'commands/doctor',
  });

program
  .command('research', 'Run research-analyst agent on the active spec', {
    executableFile: 'commands/research',
  });

program
  .command('requirements', 'Run product-manager agent on the active spec', {
    executableFile: 'commands/requirements',
  });

program
  .command('design', 'Run architect-reviewer agent on the active spec', {
    executableFile: 'commands/design',
  });

program
  .command('tasks', 'Run task-planner agent on the active spec', {
    executableFile: 'commands/tasks',
  });

program
  .command('run', 'Execute tasks for the active or named spec', {
    executableFile: 'commands/run',
  });

// Top-level error handler
process.on('unhandledRejection', (reason) => {
  const err = reason as RalphError;
  if (err && typeof err === 'object' && 'suggestion' in err) {
    error(`${err.message}`);
    error(`Suggestion: ${err.suggestion}`);
    process.exit(err.exitCode ?? 1);
  } else {
    error(String(reason));
    process.exit(1);
  }
});

program.parseAsync(process.argv).catch((err: unknown) => {
  const ralphErr = err as RalphError;
  if (ralphErr && typeof ralphErr === 'object' && 'suggestion' in ralphErr) {
    error(ralphErr.message);
    error(`Suggestion: ${ralphErr.suggestion}`);
    process.exit(ralphErr.exitCode ?? 1);
  } else {
    error(String(err));
    process.exit(1);
  }
});
