---
spec: ralph-integration-research
phase: research
created: 2026-01-22
---

# Research: ralph-integration-research

## Executive Summary

Removing the ralph-loop dependency is feasible by inlining stop-hook logic directly into ralph-specum. The snarktank/ralph architecture provides a simpler external bash loop approach, but the ralph-wiggum approach (stop-hook with exit code 0 + `decision: block`) is more appropriate for Claude Code plugins. Inlining ~50 lines of stop-hook logic eliminates the dependency while preserving all functionality.

## External Research

### snarktank/ralph Architecture

| Aspect | Implementation |
|--------|----------------|
| Loop mechanism | External bash script (`ralph.sh`) |
| Iteration control | `for i in $(seq 1 $MAX_ITERATIONS)` in bash |
| State persistence | `prd.json` (task status), `progress.txt` (learnings) |
| Completion signal | `<promise>COMPLETE</promise>` exact string match |
| Context reset | Fresh AI instance per iteration (clean context) |

**Key Files**:
- `ralph.sh` - Bash orchestration loop (~100 lines)
- `prompt.md` / `CLAUDE.md` - Agent instructions
- `prd.json` - Task status tracking
- `progress.txt` - Append-only learnings

**Workflow per iteration**:
1. Select highest-priority incomplete story from prd.json
2. Spawn fresh AI instance (amp or claude)
3. Execute single story
4. Run quality checks (typecheck, tests)
5. Commit on success, mark story complete
6. Append learnings to progress.txt
7. Check for `<promise>COMPLETE</promise>` in output
8. Exit or continue to next iteration

**Source**: [snarktank/ralph](https://github.com/snarktank/ralph)

### ralph-wiggum (Official Anthropic Plugin) Architecture

| Aspect | Implementation |
|--------|----------------|
| Loop mechanism | Stop hook returns `{"decision": "block", "reason": "..."}` |
| Iteration control | State file `.claude/ralph-loop.local.md` with YAML frontmatter |
| State persistence | Same state file + git history |
| Completion signal | `--completion-promise` exact string match |
| Context reset | Accumulating context (same session) |

**Key Files**:
- `commands/ralph-loop.md` - Command that initializes state
- `commands/cancel-ralph.md` - Cancels active loop
- `hooks/stop-hook.sh` - Intercepts stops, re-injects prompt
- `scripts/setup-ralph-loop.sh` - Creates state file

**Stop Hook Logic** (simplified):
```bash
# Read state file
if [ "$ACTIVE" = "true" ]; then
  # Check completion promise in transcript
  if grep -q "$COMPLETION_PROMISE" transcript; then
    # Cleanup and exit 0 (allow stop)
  else
    # Return JSON to continue
    echo '{"decision": "block", "reason": "<original prompt>"}'
    exit 0
  fi
fi
```

**Source**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md)

### Best Practices for Agentic Loops

| Pattern | Description | Source |
|---------|-------------|--------|
| ReAct | Reason + Act interleaving, explicit reasoning trail | [ByteByteGo](https://blog.bytebytego.com/p/top-ai-agentic-workflow-patterns) |
| Reflection | Self-critique and revision before finalizing | [ByteByteGo](https://blog.bytebytego.com/p/top-ai-agentic-workflow-patterns) |
| State Machine | Explicit states, transitions, retries, timeouts | [Vellum AI](https://www.vellum.ai/blog/agentic-workflows-emerging-architectures-and-design-patterns) |
| Fresh Context | New context per task prevents drift | [snarktank/ralph](https://github.com/snarktank/ralph) |
| Check `stop_hook_active` | Prevent infinite loops | [Claude Code Hooks](https://code.claude.com/docs/en/hooks) |

**Key insight**: Fresh context per task (via Task tool) is more reliable than accumulating context. ralph-specum already does this correctly.

### Pitfalls to Avoid

- **Exit code 2 plugin bug**: Plugin-installed hooks with exit code 2 may halt instead of continue
- **Completion-promise exact match**: Unreliable for variations; use `max-iterations` as primary safety
- **Accumulating context**: Token consumption grows rapidly, degrades quality
- **Infinite loops**: Must check `stop_hook_active` flag

**Source**: [GitHub Issue #10412](https://github.com/anthropics/claude-code/issues/10412), [Claude Code Hooks](https://code.claude.com/docs/en/hooks)

## Codebase Analysis

### Current Architecture

| Component | File | Lines | Purpose |
|-----------|------|-------|---------|
| implement.md | commands/implement.md | ~465 | Coordinator prompt, calls ralph-loop |
| cancel.md | commands/cancel.md | ~72 | Calls cancel-ralph + cleans state |
| stop-watcher.sh | hooks/scripts/stop-watcher.sh | ~67 | Cleanup only (logging, state removal) |
| spec-executor.md | agents/spec-executor.md | ~391 | Task execution agent |

**Current dependency chain**:

```text
/implement -> writes coordinator prompt -> invokes ralph-loop:ralph-loop skill
ralph-loop:ralph-loop -> creates .claude/ralph-loop.local.md -> stop-hook blocks exits
/cancel -> invokes ralph-loop:cancel-ralph -> cleans up both state files
```

### What ralph-loop Actually Provides

1. **State file creation**: `.claude/ralph-loop.local.md` with iteration tracking
2. **Stop hook**: Returns `{"decision": "block", "reason": "<prompt>"}` to continue
3. **Completion detection**: Checks transcript for completion promise
4. **Cancel command**: Cleans up state file

**Total functionality**: ~150 lines of bash/markdown

### Existing Patterns

- Coordinator delegates via Task tool (fresh context per task)
- State tracked in `.ralph-state.json` (taskIndex, totalTasks, phase)
- `.progress.md` for learnings persistence
- Verification layers in coordinator prompt

## Feasibility Assessment

| Option | Complexity | User Setup | Maintenance | Recommendation |
|--------|------------|------------|-------------|----------------|
| Keep ralph-loop dependency | Low | Must install plugin | Depends on Anthropic | Not recommended |
| Inline ralph-loop logic | Medium | Zero dependencies | Own maintenance | **Recommended** |
| Use snarktank/ralph approach | High | External bash script | Own maintenance | Not for plugins |
| Create custom external loop | High | Script installation | Own maintenance | Not for plugins |

### Recommended: Inline ralph-loop Logic

**What to inline** (~50 lines):

1. **Stop hook** that:
   - Reads `./specs/$spec/.ralph-state.json`
   - Checks if execution phase is active
   - Parses transcript for `ALL_TASKS_COMPLETE`
   - Returns `{"decision": "block", "reason": "Continue execution..."}` if incomplete
   - Exits 0 (allow stop) if complete

2. **State file updates** (already exists in coordinator prompt)

3. **No changes needed** to:
   - Coordinator prompt logic
   - spec-executor agent
   - Task tool delegation
   - Parallel [P] execution
   - [VERIFY] delegation

### Implementation Approach

```text
Before (with ralph-loop):
  /implement -> invokes ralph-loop:ralph-loop
  ralph-loop:ralph-loop -> stop-hook blocks exits

After (inlined):
  /implement -> writes coordinator prompt to context
  stop-hook.sh (own) -> blocks exits until ALL_TASKS_COMPLETE
```

**Changes required**:

| File | Change |
|------|--------|
| `hooks/scripts/stop-watcher.sh` | Add loop logic (~50 lines) |
| `hooks/hooks.json` | Already configured for Stop hook |
| `commands/implement.md` | Remove ralph-loop invocation, add prompt directly |
| `commands/cancel.md` | Remove ralph-loop:cancel-ralph, keep state cleanup |

### Stop Hook Implementation (Proposed)

```bash
#!/bin/bash
# Read hook input
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Check for active execution
STATE_FILE="$CWD/specs/$(cat "$CWD/specs/.current-spec")/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(jq -r '.phase // empty' "$STATE_FILE")
if [ "$PHASE" != "execution" ]; then
  exit 0
fi

# Check for completion signal in transcript
if grep -q "ALL_TASKS_COMPLETE" "$TRANSCRIPT_PATH" 2>/dev/null; then
  # Cleanup and allow stop
  rm -f "$STATE_FILE"
  exit 0
fi

# Block exit and continue
cat << 'EOF'
{"decision": "block", "reason": "Continue executing tasks. Read ./specs/$SPEC/.ralph-state.json and follow coordinator instructions."}
EOF
exit 0
```

## Related Specs

| Name | Relevance | Relationship | mayNeedUpdate |
|------|-----------|--------------|---------------|
| implement-ralph-wiggum | High | Integrated ralph-loop, now reversing | true |
| parallel-task-execution | Low | Uses Task tool, independent of loop | false |
| qa-verification | Low | Uses Task tool, independent of loop | false |

**implement-ralph-wiggum**: This spec added ralph-loop dependency. New spec would undo that integration by inlining the logic instead.

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | Not found | N/A (markdown-only plugin) |
| TypeCheck | Not found | N/A (markdown-only plugin) |
| Test | Not found | N/A (markdown-only plugin) |
| Build | Not found | N/A (markdown-only plugin) |
| Version Check | CI workflow | .github/workflows/plugin-version-check.yml |

**Local CI**: Manual verification - plugin is markdown-only with no build step.

## Recommendations for Requirements

1. **Inline stop-hook logic**: Add ~50 lines to `stop-watcher.sh` to handle loop continuation
2. **Remove ralph-loop invocation**: Modify `implement.md` to output prompt directly instead of invoking skill
3. **Remove cancel-ralph call**: Modify `cancel.md` to only handle local state cleanup
4. **Update plugin dependency docs**: Remove ralph-wiggum requirement from README
5. **Preserve Task tool pattern**: Keep spec-executor delegation via Task tool (proven pattern)
6. **Keep verification layers**: Move any remaining verification from ralph-loop into coordinator prompt

## Open Questions

1. Should the coordinator prompt be in `implement.md` or a separate template file?
   - *Recommendation*: Keep inline in `implement.md` for simplicity

2. How to handle the `--max-iterations` safety limit?
   - *Recommendation*: Track iteration count in `.ralph-state.json`, add `maxGlobalIterations` field

3. Should we support the `--completion-promise` parameter?
   - *Recommendation*: No, hardcode `ALL_TASKS_COMPLETE` since it's already the spec-executor protocol

## Deep Dive: Autonomy Patterns

### 1. Autonomous Task Selection in snarktank/ralph

**Task Selection Logic**:
- Sequential: picks "highest priority story where `passes: false`"
- No dynamic priority scoring - array position in `prd.json` implies priority
- Simple boolean filter (`passes: true/false`) for completion status

**prd.json Structure**:

| Field | Type | Purpose |
|-------|------|---------|
| `id` | string | Unique identifier |
| `title` | string | Task description |
| `passes` | boolean | Completion status |

**Priority Re-evaluation**: None. Ralph does NOT re-evaluate priorities between iterations. After completion, it marks `passes: true` and proceeds to next incomplete task in array order.

**Key Insight**: Ralph's simplicity is intentional - no complex dependency graphs or priority algorithms. The PRD author defines order, Ralph executes sequentially.

### 2. Fresh Context Strategy

**How snarktank/ralph maintains coherence**:

| Mechanism | Purpose |
|-----------|---------|
| `prd.json` | Task status - what's done, what's next |
| `progress.txt` | Append-only learnings - patterns, gotchas, decisions |
| Git history | Completed work evidence |
| `AGENTS.md` files | Directory-specific patterns/conventions |
| Thread URLs | References to previous detailed work |

**What goes into progress.txt**:
- Discovered codebase patterns ("this codebase uses X for Y")
- Gotchas and pitfalls encountered
- Thread URLs for deep-dives
- Status updates (not detailed - just markers)

**Format**: Append-only. "APPEND to progress.txt (never replace, always append)" - creates immutable audit trail.

**Avoiding repeated work**:
1. Explicit `passes` field marks completion
2. Thread URLs enable revisiting past reasoning without re-doing
3. Pattern extraction consolidates learnings at top of progress.txt
4. "ONE story per iteration" prevents confusion

### 3. Quality Gates After Every Task

**snarktank/ralph approach**:
- Runs quality checks (typecheck, tests) after each task
- Commits ONLY if checks pass
- "CI must stay green" - prevents error compounding
- No explicit retry logic in bash script - external tool handles

**Failure handling**: Minimal in ralph.sh itself - uses `|| true` to suppress errors. The intelligence is in the agent, not the loop.

**Contrast with ralph-specum**:

| Aspect | snarktank/ralph | ralph-specum |
|--------|-----------------|--------------|
| Quality gates | After task, before commit | Verification layers in coordinator |
| Retry logic | None in bash | `maxTaskIterations` with retry |
| Failure detection | Implicit (no commit) | Explicit signals + contradiction detection |
| Gate types | typecheck, tests | 4-layer verification (contradiction, uncommitted, checkmark, signal) |

**Industry best practice** (from [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)):
- "test a minimal prompt with the best model...then add clear instructions based on failure modes"
- Verify tools have minimal overlapping functionality
- Test that humans can definitively specify which tool applies

### 4. Coordinator Context Accumulation Problem

**The problem**: As coordinator executes multiple tasks, context grows. Token consumption increases, quality degrades, costs rise.

**Solutions from industry**:

| Pattern | Source | Implementation |
|---------|--------|----------------|
| Sub-agent delegation | [Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Specialized agents with clean context, return condensed summaries (1-2k tokens) |
| Todo.md pattern | [Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) | Constantly rewrite objectives at context end to maintain focus |
| External state | [Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Treat agents as stateless functions, manage state externally |
| Context-aware state machine | [Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) | Mask token logits to constrain actions without modifying tool definitions |
| Tool result clearing | [Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Remove executed tool outputs while preserving decisions |
| Fresh context per task | [Spotify](https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2) | Each task starts clean, user condenses context upfront |

**Key quote** (Anthropic): "find the smallest set of high-signal tokens that maximize the likelihood of some desired outcome"

**Spotify's approach**: Deliberately static prompts, fresh context per task, NO dynamic context retrieval. "We don't currently have code search or documentation tools exposed to our agent."

### 5. Autonomy Best Practices from Industry

**Core Design Patterns** ([Skywork AI](https://skywork.ai/blog/agentic-ai-examples-workflow-patterns-2025/)):

| Pattern | Description |
|---------|-------------|
| ReAct | Reason + Act interleaving with tool calls |
| Reflection | Self-critique loop before finalizing |
| Plan-Do-Check-Act | Plan workflow, execute, review, adjust |
| Task Routing | Route to best model/tool based on intent |
| Multi-Agent Orchestration | Swarms of specialized agents |

**Task Selection Patterns** ([Agentic Patterns](https://agentic-patterns.com/)):

| Pattern | Description |
|---------|-------------|
| Action-Selector | Selective execution of capabilities |
| Tool Use Steering | Guide tool selection through prompting |
| Context-Minimization | Favor lean inputs |
| Dynamic Context Injection | Supply only necessary info on-demand |

**State Management** ([Google ADK](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)):
- `session.state` as shared whiteboard
- Descriptive keys (`security_report`, `style_report`)
- Agent descriptions = "API documentation for the LLM"

**Error Handling**:
- "Three strikes" - counter then reset/escalate ([Medium](https://medium.com/@hungry.soul/context-management-a-practical-guide-for-agentic-ai-74562a33b2a5))
- Append error to thread, let model retry
- Generate "lesson learned" notes after failures

### 6. Gaps Between Ralph's Autonomy and ralph-specum

| Capability | snarktank/ralph | ralph-specum Current | Gap |
|------------|-----------------|---------------------|-----|
| Context freshness | True fresh (new instance per iteration) | Task tool provides fresh context | **Parity** |
| Coordinator context | External bash = no accumulation | Coordinator accumulates in-session | **Gap** |
| Task selection | Sequential by array position | Sequential by taskIndex | **Parity** |
| Priority re-eval | None | None | **Parity** |
| Learnings persistence | progress.txt append-only | .progress.md Learnings section | **Parity** |
| Quality gates | typecheck, tests | 4-layer verification | **ralph-specum stronger** |
| State tracking | prd.json (passes field) | tasks.md [x] checkmarks | **Parity** |
| Error handling | Minimal (`\|\|` true) | maxTaskIterations + contradiction detection | **ralph-specum stronger** |
| Todo/focus pattern | Not used | Not used | **Gap** (could adopt) |

### 7. Recommendations for Adopting Ralph's Patterns

1. **Adopt todo.md pattern**: Coordinator should write/update a focus file that gets recited at each iteration start
   - Prevents drift in long sessions
   - Already compatible with Task tool pattern

2. **Context compaction**: After each Task tool return, coordinator should summarize rather than preserve full output
   - Implement "tool result clearing" pattern
   - Keep decisions, discard raw tool output

3. **External state emphasis**: `.ralph-state.json` already does this - emphasize in coordinator prompt
   - Treat coordinator as stateless function
   - All state in files, not in context

4. **Learnings at context end**: Always include `.progress.md` Learnings section LAST in Task tool prompts
   - Recency bias helps model remember patterns
   - Mirrors Manus's objective recitation

5. **Keep existing strengths**: ralph-specum's verification layers are stronger than original Ralph
   - Don't simplify to Ralph's `|| true` approach
   - 4-layer verification catches more failures

## Sources

- [snarktank/ralph Repository](https://github.com/snarktank/ralph)
- [anthropics/claude-code ralph-wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [ByteByteGo Agentic Workflow Patterns](https://blog.bytebytego.com/p/top-ai-agentic-workflow-patterns)
- [Vellum AI Agentic Workflows Guide](https://www.vellum.ai/blog/agentic-workflows-emerging-architectures-and-design-patterns)
- [GitHub Issue #10412 - Stop Hook Bug](https://github.com/anthropics/claude-code/issues/10412)
- [Awesome Claude: Ralph Wiggum](https://awesomeclaude.ai/ralph-wiggum)
- [Paddo.dev Ralph Wiggum Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Manus Context Engineering Blog](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- [Spotify Background Coding Agents Part 2](https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2)
- [Skywork AI Agentic Patterns 2025](https://skywork.ai/blog/agentic-ai-examples-workflow-patterns-2025/)
- [Agentic Patterns Catalogue](https://agentic-patterns.com/)
- [Google ADK Multi-Agent Patterns](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Medium Context Management Guide](https://medium.com/@hungry.soul/context-management-a-practical-guide-for-agentic-ai-74562a33b2a5)
- Local: `plugins/ralph-specum/commands/implement.md`
- Local: `plugins/ralph-specum/agents/spec-executor.md`
- Local: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
- Local: `specs/implement-ralph-wiggum/research.md`
