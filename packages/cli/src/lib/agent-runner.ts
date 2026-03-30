import path from 'path';
import { promises as fs } from 'fs';
import { getPrompt } from '../agents/index.js';
import { createProvider } from '../providers/factory.js';
import type { AgentContext, AgentResult, RunAgentOptions, RalphConfig } from '../types/index.js';

const PHASE_FILES = ['research', 'requirements', 'design', 'tasks'];

async function readFileOptional(filePath: string): Promise<string | null> {
  try {
    return await fs.readFile(filePath, 'utf8');
  } catch {
    return null;
  }
}

async function buildContext(agentName: string, specPath: string): Promise<AgentContext> {
  const specName = path.basename(specPath);
  const systemPrompt = getPrompt(agentName);

  const specFiles: Record<string, string> = {};
  for (const phase of PHASE_FILES) {
    const content = await readFileOptional(path.join(specPath, `${phase}.md`));
    if (content !== null) {
      specFiles[phase] = content;
    }
  }

  const progress = await readFileOptional(path.join(specPath, '.progress.md')) ?? undefined;

  return {
    systemPrompt,
    specName,
    specPath,
    specFiles,
    progress,
  };
}

export async function runAgent(
  agentName: string,
  specPath: string,
  config: RalphConfig,
  options?: RunAgentOptions
): Promise<AgentResult> {
  const context = await buildContext(agentName, specPath);

  const onStream = options?.onStream ?? ((chunk: string) => {
    process.stdout.write(chunk);
  });

  const provider = createProvider(config);

  return provider.runAgent(agentName, context, {
    ...options,
    onStream,
  });
}
