/**
 * Logger utility for ralph-specum CLI
 * Provides colored console output with different log levels
 */

const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',

  // Foreground colors
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  gray: '\x1b[90m',

  // Background colors
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
};

const SYMBOLS = {
  success: '\u2714',
  error: '\u2716',
  warning: '\u26A0',
  info: '\u2139',
  arrow: '\u279C',
  dot: '\u2022',
  star: '\u2605',
};

let quietMode = false;

function colorize(color, text) {
  return `${COLORS[color]}${text}${COLORS.reset}`;
}

function formatPrefix(prefix, color) {
  return colorize(color, `[${prefix}]`);
}

export const logger = {
  setQuiet(value) {
    quietMode = value;
  },

  log(...args) {
    if (!quietMode) {
      console.log(...args);
    }
  },

  info(message) {
    if (!quietMode) {
      console.log(`${colorize('blue', SYMBOLS.info)} ${message}`);
    }
  },

  success(message) {
    if (!quietMode) {
      console.log(`${colorize('green', SYMBOLS.success)} ${message}`);
    }
  },

  warn(message) {
    console.log(`${colorize('yellow', SYMBOLS.warning)} ${colorize('yellow', message)}`);
  },

  error(message) {
    console.error(`${colorize('red', SYMBOLS.error)} ${colorize('red', message)}`);
  },

  debug(message) {
    if (!quietMode) {
      console.log(`${colorize('gray', '[DEBUG]')} ${colorize('gray', message)}`);
    }
  },

  // Phase-specific logging
  phase(name, status = 'starting') {
    const statusColors = {
      starting: 'cyan',
      running: 'yellow',
      completed: 'green',
      failed: 'red',
      skipped: 'gray',
    };
    const color = statusColors[status] || 'white';
    console.log(
      `\n${colorize('bold', colorize(color, `${SYMBOLS.arrow} Phase: ${name}`))} ${colorize('dim', `(${status})`)}`
    );
  },

  // Task-specific logging
  task(index, total, name, status = 'pending') {
    const statusColors = {
      pending: 'gray',
      running: 'yellow',
      completed: 'green',
      failed: 'red',
    };
    const color = statusColors[status] || 'white';
    const progress = `[${index}/${total}]`;
    console.log(`  ${colorize('dim', progress)} ${colorize(color, name)}`);
  },

  // Progress bar
  progress(current, total, label = '') {
    const width = 30;
    const percent = Math.round((current / total) * 100);
    const filled = Math.round((current / total) * width);
    const empty = width - filled;
    const bar = colorize('green', '\u2588'.repeat(filled)) + colorize('gray', '\u2591'.repeat(empty));
    process.stdout.write(`\r  ${bar} ${percent}% ${label}`);
    if (current === total) {
      console.log(); // New line when complete
    }
  },

  // Box for important messages
  box(title, content) {
    const lines = content.split('\n');
    const maxLen = Math.max(title.length, ...lines.map((l) => l.length));
    const border = '\u2500'.repeat(maxLen + 4);

    console.log(colorize('cyan', `\u250C${border}\u2510`));
    console.log(colorize('cyan', `\u2502 ${colorize('bold', title.padEnd(maxLen + 2))} \u2502`));
    console.log(colorize('cyan', `\u251C${border}\u2524`));
    lines.forEach((line) => {
      console.log(colorize('cyan', '\u2502') + ` ${line.padEnd(maxLen + 2)} ` + colorize('cyan', '\u2502'));
    });
    console.log(colorize('cyan', `\u2514${border}\u2518`));
  },

  // Divider line
  divider(char = '\u2500', length = 50) {
    console.log(colorize('dim', char.repeat(length)));
  },

  // Blank line
  newline() {
    console.log();
  },

  // Header with branding
  header() {
    console.log(
      colorize(
        'magenta',
        `
${colorize('bold', 'ralph-specum')} ${colorize('dim', 'v1.2.0')}
${colorize('dim', 'Spec-driven development with the Ralph Wiggum loop')}
`
      )
    );
  },
};

export { COLORS, SYMBOLS };
