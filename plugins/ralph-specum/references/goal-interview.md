# Goal Interview

> Used by: start.md

This reference contains the pre-research brainstorming dialogue conducted in normal mode (skipped in --quick mode). It uses intent classification from `intent-classification.md` to calibrate depth.

## Prerequisites

- Intent classification must be completed first (see `intent-classification.md` for Goal Intent Classification)
- Dialogue depth determined by intent type (TRIVIAL: 1-2, REFACTOR: 3-5, GREENFIELD: 5-10, MID_SIZED: 3-7)

## Brainstorming Dialogue

Apply adaptive dialogue from `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`.

The coordinator asks context-driven questions one at a time based on the exploration territory below and what's already known from the goal text. Questions adapt to prior answers. After enough understanding, propose approaches.

<mandatory>
**Before asking any question, check: is this a codebase fact or a user decision?**
- Codebase fact -> Use Explore agent to find the answer automatically
- User decision -> Ask via AskUserQuestion

Never ask the user about things you can discover from the code.
</mandatory>

## Goal Exploration Territory

Areas to probe during the UNDERSTAND phase (hints, not a script -- generate actual questions from these based on context):

- **Problem being solved** -- what pain point or need is driving this goal?
- **Constraints and must-haves** -- performance, compatibility, timeline, integration requirements
- **Success criteria** -- how will the user know this feature works correctly?
- **Scope boundaries** -- what's explicitly in and out of scope?
- **User's existing knowledge** -- what does the user already know about the problem space vs what needs discovery?

## Goal Approach Proposals

After the dialogue, propose 2-3 high-level approaches tailored to the user's goal. Examples (illustrative only -- approaches should be specific, not generic):

- **(A)** Extend existing system/module to support the new capability
- **(B)** Build a new standalone module with clean boundaries
- **(C)** Lightweight integration using existing primitives with minimal new code

## Spec Location Interview

After the standard goal interview questions, determine where the spec should be stored:

```text
Spec Location Logic:

1. Check if --specs-dir already provided -> SKIP
2. Get configured directories: dirs = ralph_get_specs_dirs()
3. If dirs.length > 1: ASK using AskUserQuestion "Where should this spec be stored?"
4. If dirs.length == 1: OUTPUT awareness message (non-blocking):
   "Spec will be created in ./specs/
    Tip: You can organize specs in multiple directories.
    See /ralph-specum:help for multi-directory setup."
5. Store specsDir for use in spec creation
```

## Store Goal Context

After interview and approach selection, update `.progress.md`:

```markdown
## Interview Format
- Version: 1.0

## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]

## Interview Responses

### Goal Interview (from start.md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] -- [one-line rationale]
- Spec location: [responses.specsDir] (if multi-dir was asked)
[Any follow-up responses from "Other" selections]
```

## Pass Context to Research Team

Include goal interview context in each research teammate's task description:

```text
Each TaskCreate description should include:

Goal Interview Context:
[Include all topic-response pairs from the Goal Interview section of .progress.md]
Chosen Approach: [name]

Use this context to focus research on relevant areas.
```
