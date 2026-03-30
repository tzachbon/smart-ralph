import Anthropic from '@anthropic-ai/sdk';
import type { Provider, AgentContext, AgentResult, RunAgentOptions } from './interface.js';
import type { RalphConfig } from '../types/index.js';
import { getApiKey } from '../lib/config.js';
import { ProviderError } from '../lib/errors.js';

export class ClaudeProvider implements Provider {
  readonly name = 'claude';
  private readonly client: Anthropic;
  private readonly config: RalphConfig;

  constructor(config: RalphConfig) {
    this.config = config;
    const apiKey = getApiKey(config);
    if (!apiKey) {
      throw new ProviderError(
        `API key not found in environment variable "${config.apiKeyEnvVar}"`,
        'claude'
      );
    }
    this.client = new Anthropic({ apiKey });
  }

  async runAgent(
    _agentName: string,
    context: AgentContext,
    options: RunAgentOptions = {}
  ): Promise<AgentResult> {
    const model = options.model ?? this.config.model;
    const maxTokens = options.maxTokens ?? 8096;

    const userContent = this.buildUserContent(context);

    const stream = await this.client.messages.stream({
      model,
      max_tokens: maxTokens,
      system: context.systemPrompt,
      messages: [{ role: 'user', content: userContent }],
    });

    let content = '';
    for await (const chunk of stream) {
      if (
        chunk.type === 'content_block_delta' &&
        chunk.delta.type === 'text_delta'
      ) {
        content += chunk.delta.text;
        options.onStream?.(chunk.delta.text);
      }
    }

    const finalMessage = await stream.finalMessage();

    return {
      content,
      tokensUsed: {
        input: finalMessage.usage.input_tokens,
        output: finalMessage.usage.output_tokens,
      },
      stopReason: this.mapStopReason(finalMessage.stop_reason),
    };
  }

  private buildUserContent(context: AgentContext): string {
    const parts: string[] = [];

    parts.push(`Spec: ${context.specName}`);
    parts.push(`Spec path: ${context.specPath}`);

    if (Object.keys(context.specFiles).length > 0) {
      parts.push('\n## Spec Files');
      for (const [phase, content] of Object.entries(context.specFiles)) {
        parts.push(`\n### ${phase}\n${content}`);
      }
    }

    if (context.taskBlock) {
      parts.push(`\n## Task\n${context.taskBlock}`);
    }

    if (context.progress) {
      parts.push(`\n## Progress\n${context.progress}`);
    }

    if (context.additionalContext) {
      parts.push(`\n## Additional Context\n${context.additionalContext}`);
    }

    return parts.join('\n');
  }

  private mapStopReason(
    reason: string | null
  ): AgentResult['stopReason'] {
    switch (reason) {
      case 'end_turn':
        return 'end_turn';
      case 'max_tokens':
        return 'max_tokens';
      case 'tool_use':
        return 'tool_use';
      default:
        return 'end_turn';
    }
  }
}
