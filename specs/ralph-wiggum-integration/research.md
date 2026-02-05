---
spec: ralph-wiggum-integration
phase: research
created: 2026-02-05
generated: auto
---

# Research: ralph-wiggum-integration

## Executive Summary

Migration from `ralph-loop` to `ralph-wiggum` requires updating completion signal format from raw text to `<promise>` tags. State file location unchanged. Minimal code changes needed - primarily format adjustments.

## Codebase Analysis

### Current Implementation (implement.md)

| Component | Current State | Required Change |
|-----------|---------------|-----------------|
| Skill invocation | `ralph-loop:ralph-loop` | `ralph-wiggum:ralph-wiggum` |
| Completion signal | Raw `ALL_TASKS_COMPLETE` | `<promise>ALL_TASKS_COMPLETE</promise>` |
| State file | `./specs/$spec/.ralph-state.json` | No change (ralph-wiggum uses `.claude/ralph-loop.local.md` internally) |
| Coordinator prompt | Outputs raw completion text | Must output promise tags |

### spec-executor.md

| Component | Current State | Required Change |
|-----------|---------------|-----------------|
| Task completion | Raw `TASK_COMPLETE` | No change (coordinator handles promise wrapping) |
| Agent behavior | Correct | No change |

### CLAUDE.md Dependencies

| Section | Current | Required |
|---------|---------|----------|
| Dependencies section | `ralph-loop@claude-plugins-official` | `ralph-wiggum@claude-plugins-official` |
| Task Completion Protocol | References `Ralph Loop` | References `ralph-wiggum` |

### Key Insight: Re-feeding Same Prompt

ralph-wiggum re-feeds the SAME prompt each iteration until promise detected. Current coordinator prompt:
- Reads state file to determine current task
- This pattern works perfectly with re-feeding (state file changes between iterations)
- No structural changes needed to coordinator logic

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Straightforward text replacements |
| Effort Estimate | S | ~30 minutes of changes |
| Risk Level | Low | No logic changes, just format updates |

## Constraints

- Must maintain backwards compatibility during transition
- Coordinator prompt must work when re-fed (already does via state file)
- Promise tags must exactly match `<promise>ALL_TASKS_COMPLETE</promise>`

## Recommendations

1. Update skill invocation path to `ralph-wiggum:ralph-wiggum`
2. Wrap completion signal in `<promise>` tags in coordinator prompt
3. Update CLAUDE.md documentation references
4. Test full execution loop to verify promise detection works
