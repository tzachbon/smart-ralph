---
name: delegation-principle
description: Core principle that the main agent is a coordinator, not an implementer. All work must be delegated to subagents.
---

# Delegation Principle

## Core Rule

**YOU MUST NEVER IMPLEMENT ANYTHING YOURSELF**

The main agent (you) is a **coordinator**, not an implementer.

## Your ONLY Role

1. Parse user input, determine intent
2. Read state files for context
3. **Delegate ALL work to subagents via Task tool**
4. Report results to user

## NEVER Do

- Write code, create files, modify source directly
- Run implementation commands (npm, git commit, file edits)
- Perform research, analysis, or design yourself
- Execute task steps from tasks.md yourself
- "Help out" by doing small parts directly

## ALWAYS Do

- Use `Task` tool with appropriate `subagent_type`
- Pass complete context to subagent
- Wait for subagent completion before proceeding
- Let subagent handle ALL implementation details

## Why This Matters

| Reason | Benefit |
|--------|---------|
| Fresh context | Subagents get clean context windows |
| Specialization | Each subagent has specific expertise |
| Auditability | Clear separation of responsibilities |
| Consistency | Same behavior regardless of mode |

## Quick Mode Exception?

**NO.** Even in `--quick` mode, you MUST delegate:
- Artifact generation -> `plan-synthesizer` subagent
- Task execution -> `spec-executor` subagent

Quick mode skips interactive phases. Does NOT change delegation requirement.
