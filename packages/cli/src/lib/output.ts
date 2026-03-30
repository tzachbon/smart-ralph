import chalk from 'chalk';

let jsonMode = false;
let debugMode = false;

export function setJsonMode(v: boolean): void {
  jsonMode = v;
}

export function setDebugMode(v: boolean): void {
  debugMode = v;
}

export function isJsonMode(): boolean {
  return jsonMode;
}

export function isDebugMode(): boolean {
  return debugMode;
}

const useColor = !process.env['NO_COLOR'] && process.stdout.isTTY;

export function info(msg: string): void {
  if (jsonMode) return;
  const prefix = useColor ? chalk.cyan('>') : '>';
  console.log(`${prefix} ${msg}`);
}

export function success(msg: string): void {
  if (jsonMode) return;
  const prefix = useColor ? chalk.green('+') : '+';
  console.log(`${prefix} ${msg}`);
}

export function warn(msg: string): void {
  if (jsonMode) return;
  const prefix = useColor ? chalk.yellow('!') : '!';
  console.error(`${prefix} ${msg}`);
}

export function error(msg: string): void {
  const prefix = useColor ? chalk.red('-') : '-';
  console.error(`${prefix} ${msg}`);
}

export function debug(msg: string): void {
  if (!debugMode) return;
  const prefix = useColor ? chalk.dim('debug') : 'debug';
  console.error(`${prefix} ${msg}`);
}
