---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: [Read, Write, Task, Bash, AskUserQuestion]
---

# Design Phase

You are generating technical design for a specification. Running this command implicitly approves the requirements phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN ARCHITECT.**

You MUST delegate ALL design work to the `architect-reviewer` subagent.
Do NOT create architecture diagrams, technical decisions, or design.md yourself.
</mandatory>

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use that
2. Otherwise, read `./specs/.current-spec` to get active spec
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/requirements.md` exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Existing codebase patterns (via exploration)

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Design".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal architecture context needed)
- REFACTOR: 3-5 questions (understand architecture impact)
- GREENFIELD: 5-10 questions (full architecture context)
- MID_SIZED: 3-7 questions (balanced approach)

### Design Interview (Single-Question Flow)

**Interview Framework**: Apply standard single-question loop from `skills/interview-framework/SKILL.md`

### Phase-Specific Configuration

- **Phase**: Design Interview
- **Parameter Chain Mappings**: architectureStyle, techConstraints, integrationApproach
- **Available Variables**: `{goal}`, `{intent}`, `{problem}`, `{constraints}`, `{technicalApproach}`, `{users}`, `{priority}`
- **Storage Section**: `### Design Interview (from design.md)`

### Design Interview Question Pool

| # | Question | Required | Key | Options |
|---|----------|----------|-----|---------|
| 1 | What architecture style fits this feature for {goal}? | Required | `architectureStyle` | Extend existing architecture (Recommended) / Create isolated module / Major refactor to support this / Other |
| 2 | Any technology constraints for {goal}? | Required | `techConstraints` | No constraints / Must use specific library/framework / Must avoid certain dependencies / Other |
| 3 | How should this integrate with existing systems? | Required | `integrationApproach` | Use existing APIs and interfaces / Create new integration layer / Minimal integration needed / Other |
| 4 | Any other design context? (or say 'done' to proceed) | Optional | `additionalDesignContext` | No, let's proceed / Yes, I have more details / Other |

### Store Design Interview Responses

After interview, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Design Interview (from design.md)
- Architecture style: [responses.architectureStyle]
- Technology constraints: [responses.techConstraints]
- Integration approach: [responses.integrationApproach]
- Additional design context: [responses.additionalDesignContext]
[Any follow-up responses from "Other" selections]
```

### Interview Context Format

Pass the combined context (prior + new responses) to the Task delegation prompt:

```
Interview Context:
- Architecture style: [Answer]
- Technology constraints: [Answer]
- Integration approach: [Answer]
- Follow-up details: [Any additional clarifications]
```

Store this context to include in the Task delegation prompt.

## Execute Design

<mandatory>
Use the Task tool with `subagent_type: architect-reviewer` to generate design.
</mandatory>

Invoke architect-reviewer agent with prompt:

```
You are creating technical design for spec: $spec
Spec path: ./specs/$spec/

Context:
- Requirements: [include requirements.md content]
- Research: [include research.md if exists]

[If interview was conducted, include:]
Interview Context:
$interview_context

Your task:
1. Read and understand all requirements
2. Explore the codebase for existing patterns to follow
3. Design architecture with mermaid diagrams
4. Define component responsibilities and interfaces
5. Document technical decisions with rationale
6. Plan file structure (create/modify)
7. Define error handling and edge cases
8. Create test strategy
9. Output to ./specs/$spec/design.md
10. Include interview responses in a "Design Inputs" section of design.md

Use the design.md template with frontmatter:
---
spec: $spec
phase: design
created: <timestamp>
---

Include:
- Architecture diagram (mermaid)
- Data flow diagram (mermaid sequence)
- Technical decisions table
- File structure matrix
- TypeScript interfaces
- Error handling table
- Test strategy
```

## Update State

After design complete:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "design",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark requirements as implicitly approved
   - Set current phase to design

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage design file:
   ```bash
   git add ./specs/$spec/design.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add technical design"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Output

```text
Design phase complete for '$spec'.

Output: ./specs/$spec/design.md
[If commitSpec: "Spec committed and pushed."]

Next: Review design.md, then run /ralph-specum:tasks
```
