import { promises as fs } from 'fs';
import path from 'path';
import type { SpecState } from '../types/index.js';

const SPEC_NAME_RE = /^[a-z0-9][a-z0-9\-_]*$/;

const PHASES = ['research', 'requirements', 'design', 'tasks'] as const;

const STUB_CONTENT: Record<string, string> = {
  'research.md': '# Research\n\n<!-- Add research notes here -->\n',
  'requirements.md': '# Requirements\n\n<!-- Add requirements here -->\n',
  'design.md': '# Design\n\n<!-- Add design notes here -->\n',
  'tasks.md': '# Tasks\n\n<!-- Add tasks here -->\n',
  '.progress.md': '# Progress\n\n<!-- Progress notes -->\n',
};

const DEFAULT_STATE: SpecState = {
  source: 'spec',
  name: '',
  basePath: '',
  phase: 'research',
  taskIndex: 0,
  totalTasks: 0,
  taskIteration: 0,
  maxTaskIterations: 5,
  globalIteration: 0,
  maxGlobalIterations: 50,
  recoveryMode: false,
};

// --- Validation ---

export function validateSpecName(name: string): boolean {
  return SPEC_NAME_RE.test(name);
}

// --- Active spec ---

export async function getActiveSpec(specsDir: string): Promise<string | null> {
  const currentSpecFile = path.join(specsDir, '.current-spec');
  try {
    const content = await fs.readFile(currentSpecFile, 'utf8');
    const name = content.trim();
    return name.length > 0 ? name : null;
  } catch {
    return null;
  }
}

export async function setActiveSpec(specsDir: string, name: string): Promise<void> {
  const currentSpecFile = path.join(specsDir, '.current-spec');
  await fs.mkdir(specsDir, { recursive: true });
  await fs.writeFile(currentSpecFile, name, 'utf8');
}

// --- Create spec ---

export async function createSpec(
  specsDir: string,
  name: string,
  goal: string
): Promise<string> {
  if (!validateSpecName(name)) {
    throw new Error(
      `Invalid spec name "${name}". Must match /^[a-z0-9][a-z0-9\\-_]*$/`
    );
  }

  const specPath = path.join(specsDir, name);
  await fs.mkdir(specPath, { recursive: true });

  // Write stub files
  for (const [filename, content] of Object.entries(STUB_CONTENT)) {
    const filePath = path.join(specPath, filename);
    // Don't overwrite existing files
    try {
      await fs.access(filePath);
    } catch {
      await fs.writeFile(filePath, content, 'utf8');
    }
  }

  // Write initial state
  const initialState: SpecState = {
    ...DEFAULT_STATE,
    name,
    basePath: specPath,
    phase: 'research',
  };
  await writeState(specPath, initialState);

  // Append goal to research.md
  const researchPath = path.join(specPath, 'research.md');
  const existing = await fs.readFile(researchPath, 'utf8');
  if (!existing.includes('## Goal')) {
    await fs.writeFile(
      researchPath,
      existing.trimEnd() + `\n\n## Goal\n\n${goal}\n`,
      'utf8'
    );
  }

  return specPath;
}

// --- Phase file I/O ---

export async function readSpecFile(specPath: string, phase: string): Promise<string> {
  const filePath = path.join(specPath, `${phase}.md`);
  return fs.readFile(filePath, 'utf8');
}

export async function writeSpecFile(
  specPath: string,
  phase: string,
  content: string
): Promise<void> {
  const filePath = path.join(specPath, `${phase}.md`);
  await fs.mkdir(specPath, { recursive: true });
  await fs.writeFile(filePath, content, 'utf8');
}

// --- State management ---

export async function readState(specPath: string): Promise<SpecState> {
  const statePath = path.join(specPath, '.ralph-state.json');
  try {
    const raw = await fs.readFile(statePath, 'utf8');
    const parsed = JSON.parse(raw) as Partial<SpecState>;
    return { ...DEFAULT_STATE, ...parsed };
  } catch {
    return { ...DEFAULT_STATE, name: path.basename(specPath), basePath: specPath };
  }
}

export async function writeState(specPath: string, state: SpecState): Promise<void> {
  const statePath = path.join(specPath, '.ralph-state.json');
  const tmpPath = statePath + '.tmp';
  await fs.mkdir(specPath, { recursive: true });
  await fs.writeFile(tmpPath, JSON.stringify(state, null, 2), 'utf8');
  await fs.rename(tmpPath, statePath);
}

export async function deleteState(specPath: string): Promise<void> {
  const statePath = path.join(specPath, '.ralph-state.json');
  try {
    await fs.unlink(statePath);
  } catch {
    // Already gone — not an error
  }
}
