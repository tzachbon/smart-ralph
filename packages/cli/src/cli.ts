import { Command } from 'commander';
import { createRequire } from 'module';
import { setDebugMode, setJsonMode, error } from './lib/output.js';
import type { RalphError } from './lib/errors.js';
import { registerInit } from './commands/init.js';
import { registerNew } from './commands/new.js';
import { registerSwitch } from './commands/switch.js';
import { registerStatus } from './commands/status.js';
import { registerCancel } from './commands/cancel.js';
import { registerDoctor } from './commands/doctor.js';

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

registerInit(program);
registerNew(program);
registerSwitch(program);
registerStatus(program);
registerCancel(program);
registerDoctor(program);

// Top-level error handler for unhandled promise rejections
process.on('unhandledRejection', (reason) => {
  const err = reason as RalphError;
  if (err && typeof err === 'object' && 'suggestion' in err) {
    error(err.message);
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
