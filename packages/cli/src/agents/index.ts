import { prompt as researchAnalyst } from './research-analyst.js';
import { prompt as productManager } from './product-manager.js';
import { prompt as architectReviewer } from './architect-reviewer.js';
import { prompt as taskPlanner } from './task-planner.js';
import { prompt as specExecutor } from './spec-executor.js';

const prompts: Record<string, string> = {
  'research-analyst': researchAnalyst,
  'product-manager': productManager,
  'architect-reviewer': architectReviewer,
  'task-planner': taskPlanner,
  'spec-executor': specExecutor,
};

export function getPrompt(agentName: string): string {
  const prompt = prompts[agentName];
  if (!prompt) {
    throw new Error(`Unknown agent: ${agentName}. Available: ${Object.keys(prompts).join(', ')}`);
  }
  return prompt;
}
