// Provider

export interface Provider {
  readonly name: string;

  runAgent(
    agentName: string,
    context: AgentContext,
    options?: RunAgentOptions
  ): Promise<AgentResult>;
}

export interface AgentContext {
  systemPrompt: string;
  specName: string;
  specPath: string;
  /** Existing spec files content keyed by phase name */
  specFiles: Record<string, string>;
  /** Task block text (for spec-executor) */
  taskBlock?: string;
  /** Progress file content */
  progress?: string;
  /** Additional context (codebase snippets, user goal) */
  additionalContext?: string;
}

export interface RunAgentOptions {
  /** Called with each streamed text chunk */
  onStream?: (chunk: string) => void;
  /** Model override (defaults to config) */
  model?: string;
  /** Max tokens for response */
  maxTokens?: number;
  /** Enable tool use (file read/write, bash) */
  tools?: boolean;
}

export interface AgentResult {
  content: string;
  tokensUsed: { input: number; output: number };
  stopReason: 'end_turn' | 'max_tokens' | 'tool_use';
}

// Spec State

export interface SpecState {
  source: 'spec' | 'plan' | 'direct';
  name: string;
  basePath: string;
  phase: 'research' | 'requirements' | 'design' | 'tasks' | 'execution';
  taskIndex: number;
  totalTasks: number;
  taskIteration: number;
  maxTaskIterations: number;
  globalIteration: number;
  maxGlobalIterations: number;
  recoveryMode: boolean;
  granularity?: 'fine' | 'coarse';
  /** Preserved fields from earlier phases */
  commitSpec?: boolean;
  relatedSpecs?: RelatedSpec[];
  epicName?: string;
  /** Parallel execution tracking */
  parallelGroup?: ParallelGroup;
  taskResults?: Record<string, TaskResult>;
  /** Recovery mode tracking */
  fixTaskMap?: Record<string, FixTaskEntry>;
  modificationMap?: Record<string, ModificationEntry>;
  /** CLI-specific fields use cli_ prefix */
  cli_startedAt?: string;
  cli_lastTaskAt?: string;
}

export interface RelatedSpec {
  name: string;
  relevance: 'high' | 'medium' | 'low';
  reason: string;
  mayNeedUpdate?: boolean;
}

export interface ParallelGroup {
  startIndex: number;
  endIndex: number;
  taskIndices: number[];
}

export interface TaskResult {
  status: 'pending' | 'success' | 'failed';
  error?: string;
}

export interface FixTaskEntry {
  attempts: number;
  fixTaskIds: string[];
  lastError?: string;
}

export interface ModificationEntry {
  count: number;
  modifications: Array<{
    id: string;
    type: 'SPLIT_TASK' | 'ADD_PREREQUISITE' | 'ADD_FOLLOWUP';
    reason?: string;
  }>;
}

// Config

export interface RalphConfig {
  provider: string;
  model: string;
  apiKeyEnvVar: string;
}

// Task

export interface ParsedTask {
  index: number;
  id: string;
  title: string;
  completed: boolean;
  parallel: boolean;
  body: {
    do: string;
    files: string[];
    doneWhen: string;
    verify: string;
    commit: string;
    requirementsRefs?: string[];
    designRefs?: string[];
  };
  tags: string[];
}
