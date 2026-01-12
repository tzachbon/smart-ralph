/**
 * Git utilities for ralph-specum CLI
 */

import { $ } from 'bun';

/**
 * Execute a git command and return the output
 */
async function git(...args) {
  try {
    const result = await $`git ${args}`.quiet();
    return result.stdout.toString().trim();
  } catch (error) {
    throw new Error(`Git command failed: git ${args.join(' ')}\n${error.stderr || error.message}`);
  }
}

/**
 * Check if current directory is a git repository
 */
export async function isGitRepo() {
  try {
    await git('rev-parse', '--git-dir');
    return true;
  } catch {
    return false;
  }
}

/**
 * Get the current branch name
 */
export async function getCurrentBranch() {
  return await git('rev-parse', '--abbrev-ref', 'HEAD');
}

/**
 * Check if we're on a main/master branch
 */
export async function isMainBranch() {
  const branch = await getCurrentBranch();
  return ['main', 'master'].includes(branch);
}

/**
 * Get the default branch (main or master)
 */
export async function getDefaultBranch() {
  try {
    // Try to get the default branch from remote
    const remote = await git('remote', 'show', 'origin');
    const match = remote.match(/HEAD branch: (\S+)/);
    if (match) return match[1];
  } catch {
    // Fallback to checking local branches
  }

  // Check if main exists
  try {
    await git('rev-parse', '--verify', 'main');
    return 'main';
  } catch {
    return 'master';
  }
}

/**
 * Check if there are uncommitted changes
 */
export async function hasUncommittedChanges() {
  const status = await git('status', '--porcelain');
  return status.length > 0;
}

/**
 * Get list of changed files
 */
export async function getChangedFiles() {
  const status = await git('status', '--porcelain');
  if (!status) return [];

  return status.split('\n').map((line) => {
    const status = line.slice(0, 2).trim();
    const file = line.slice(3);
    return { status, file };
  });
}

/**
 * Stage files for commit
 */
export async function stageFiles(files) {
  if (Array.isArray(files)) {
    await git('add', ...files);
  } else {
    await git('add', files);
  }
}

/**
 * Create a commit with the given message
 */
export async function commit(message) {
  await git('commit', '-m', message);
}

/**
 * Create a new branch
 */
export async function createBranch(name, checkout = true) {
  if (checkout) {
    await git('checkout', '-b', name);
  } else {
    await git('branch', name);
  }
}

/**
 * Checkout a branch
 */
export async function checkout(branch) {
  await git('checkout', branch);
}

/**
 * Push current branch to remote
 */
export async function push(branch, setUpstream = false) {
  if (setUpstream) {
    await git('push', '-u', 'origin', branch);
  } else {
    await git('push');
  }
}

/**
 * Get the repository name
 */
export async function getRepoName() {
  try {
    const url = await git('remote', 'get-url', 'origin');
    // Extract repo name from URL (handles both HTTPS and SSH)
    const match = url.match(/\/([^\/]+?)(?:\.git)?$/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

/**
 * Get the repository owner
 */
export async function getRepoOwner() {
  try {
    const url = await git('remote', 'get-url', 'origin');
    // Extract owner from URL
    const httpsMatch = url.match(/github\.com\/([^\/]+)\//);
    const sshMatch = url.match(/git@github\.com:([^\/]+)\//);
    return httpsMatch?.[1] || sshMatch?.[1] || null;
  } catch {
    return null;
  }
}

/**
 * Check if gh CLI is available
 */
export async function hasGhCli() {
  try {
    await $`gh --version`.quiet();
    return true;
  } catch {
    return false;
  }
}

/**
 * Create a pull request using gh CLI
 */
export async function createPullRequest(title, body, base) {
  const result = await $`gh pr create --title ${title} --body ${body} --base ${base}`.quiet();
  return result.stdout.toString().trim();
}

/**
 * Get PR status
 */
export async function getPrStatus() {
  try {
    const result = await $`gh pr status --json state,checks`.quiet();
    return JSON.parse(result.stdout.toString());
  } catch {
    return null;
  }
}
