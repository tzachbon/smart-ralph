/**
 * Parse command line arguments for ralph-specum CLI
 *
 * Usage patterns:
 *   ralph-specum "goal description"
 *   ralph-specum run "goal description" --mode auto
 *   ralph-specum approve
 *   ralph-specum implement [phase]
 *   ralph-specum cancel
 *   ralph-specum status
 *   ralph-specum help
 */

const COMMANDS = ['run', 'approve', 'implement', 'cancel', 'status', 'help'];

const FLAG_ALIASES = {
  m: 'mode',
  d: 'dir',
  i: 'max-iterations',
  h: 'help',
  v: 'version',
  q: 'quiet',
};

export function parseArgs(args) {
  const result = {
    command: null,
    goal: null,
    phase: null,
    flags: {
      mode: 'interactive',
      dir: './spec',
      'max-iterations': 10,
      debug: false,
      quiet: false,
    },
    raw: args,
  };

  let i = 0;
  while (i < args.length) {
    const arg = args[i];

    // Handle flags
    if (arg.startsWith('--')) {
      const [key, value] = arg.slice(2).split('=');
      if (value !== undefined) {
        result.flags[key] = parseValue(value);
      } else if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
        result.flags[key] = parseValue(args[++i]);
      } else {
        result.flags[key] = true;
      }
      i++;
      continue;
    }

    // Handle short flags
    if (arg.startsWith('-') && arg.length === 2) {
      const shortFlag = arg[1];
      const fullFlag = FLAG_ALIASES[shortFlag] || shortFlag;
      if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
        result.flags[fullFlag] = parseValue(args[++i]);
      } else {
        result.flags[fullFlag] = true;
      }
      i++;
      continue;
    }

    // Handle commands and positional arguments
    if (!result.command && COMMANDS.includes(arg)) {
      result.command = arg;
    } else if (!result.goal && (result.command === 'run' || !result.command)) {
      // Goal description (for run command)
      result.goal = arg;
    } else if (result.command === 'implement' && !result.phase) {
      // Phase for implement command
      result.phase = arg;
    }

    i++;
  }

  // Normalize flags
  result.flags.maxIterations = result.flags['max-iterations'];
  delete result.flags['max-iterations'];

  return result;
}

function parseValue(value) {
  // Parse numbers
  if (/^\d+$/.test(value)) {
    return parseInt(value, 10);
  }
  // Parse booleans
  if (value === 'true') return true;
  if (value === 'false') return false;
  return value;
}

export function validateGoal(goal) {
  if (!goal || typeof goal !== 'string') {
    throw new Error('Goal description is required');
  }
  if (goal.length < 10) {
    throw new Error('Goal description must be at least 10 characters');
  }
  if (goal.length > 500) {
    throw new Error('Goal description must be less than 500 characters');
  }
  return goal.trim();
}

export function deriveFeatureName(goal) {
  return goal
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .slice(0, 50);
}
