---
name: intent-classification
description: This skill should be used when the user asks about "classify user goal", "detect intent type", "keyword matching", "question count determination", "TRIVIAL vs GREENFIELD", "goal type detection", or needs guidance on categorizing user goals to determine interview depth and question count for spec-driven development.
version: 0.1.0
---

# Intent Classification

Classify user goals to determine appropriate interview depth. Different goal types require different levels of discovery.

## Classification Logic

Analyze the goal text for keywords to determine intent type:

```text
Intent Classification:

1. TRIVIAL: Goal contains keywords like:
   - "fix typo", "typo", "spelling"
   - "small change", "minor"
   - "quick", "simple", "tiny"
   - "rename", "update text"
   -> Min questions: 1, Max questions: 2

2. REFACTOR: Goal contains keywords like:
   - "refactor", "restructure", "reorganize"
   - "clean up", "cleanup", "simplify"
   - "extract", "consolidate", "modularize"
   - "improve code", "tech debt"
   -> Min questions: 3, Max questions: 5

3. GREENFIELD: Goal contains keywords like:
   - "new feature", "new system", "new module"
   - "add", "build", "implement", "create"
   - "integrate", "introduce"
   - "from scratch"
   -> Min questions: 5, Max questions: 10

4. MID_SIZED: Default if no clear match
   -> Min questions: 3, Max questions: 7
```

## Keyword Tables

### TRIVIAL Keywords

| Keyword | Confidence Boost |
| ------- | ---------------- |
| fix typo | high |
| typo | high |
| spelling | high |
| small change | high |
| minor | medium |
| quick | medium |
| simple | medium |
| tiny | high |
| rename | medium |
| update text | medium |

### REFACTOR Keywords

| Keyword | Confidence Boost |
| ------- | ---------------- |
| refactor | high |
| restructure | high |
| reorganize | high |
| clean up | high |
| cleanup | high |
| simplify | medium |
| extract | medium |
| consolidate | medium |
| modularize | high |
| improve code | medium |
| tech debt | high |

### GREENFIELD Keywords

| Keyword | Confidence Boost |
| ------- | ---------------- |
| new feature | high |
| new system | high |
| new module | high |
| add | low |
| build | medium |
| implement | medium |
| create | medium |
| integrate | medium |
| introduce | medium |
| from scratch | high |

## Confidence Threshold

| Match Count | Confidence | Action |
| ----------- | ---------- | ------ |
| 3+ keywords | High | Use matched category |
| 1-2 keywords | Medium | Use matched category |
| 0 keywords | Low | Default to MID_SIZED |

## Question Count by Intent

Intent classification determines the question count range, not which questions to ask. All goals use the same interview question pool, but the number of questions varies by intent:

| Intent | Min Questions | Max Questions |
| ------ | ------------- | ------------- |
| TRIVIAL | 1 | 2 |
| REFACTOR | 3 | 5 |
| GREENFIELD | 5 | 10 |
| MID_SIZED | 3 | 7 |

## Classification Algorithm

```text
function classifyIntent(goalText):
  goalLower = goalText.toLowerCase()

  trivialScore = countMatches(goalLower, TRIVIAL_KEYWORDS)
  refactorScore = countMatches(goalLower, REFACTOR_KEYWORDS)
  greenfieldScore = countMatches(goalLower, GREENFIELD_KEYWORDS)

  maxScore = max(trivialScore, refactorScore, greenfieldScore)

  if maxScore == 0:
    return { type: "MID_SIZED", confidence: "low", minQ: 3, maxQ: 7 }

  if trivialScore == maxScore:
    return { type: "TRIVIAL", confidence: getConfidence(trivialScore), minQ: 1, maxQ: 2 }

  if refactorScore == maxScore:
    return { type: "REFACTOR", confidence: getConfidence(refactorScore), minQ: 3, maxQ: 5 }

  if greenfieldScore == maxScore:
    return { type: "GREENFIELD", confidence: getConfidence(greenfieldScore), minQ: 5, maxQ: 10 }

function getConfidence(score):
  if score >= 3: return "high"
  if score >= 1: return "medium"
  return "low"
```

## Store Intent in Progress File

After classification, store the result in `.progress.md`:

```markdown
## Interview Format
- Version: 1.0

## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]
```

## Question Selection Logic

```text
1. Get intent from Intent Classification step
2. Intent determines question COUNT, not which pool to use
3. All goals use the same interview question pool
4. Ask Required questions first, then Optional questions
5. Stop when:
   - User signals completion (after minRequired reached)
   - All questions asked (maxAllowed reached)
   - User selects "No, let's proceed" on optional question
```

## Examples

### Example 1: Trivial Intent

**Goal**: "Fix typo in README"

**Classification**:
- Keywords matched: "fix typo"
- Type: TRIVIAL
- Confidence: high (1 keyword, but high-confidence keyword)
- Min questions: 1
- Max questions: 2

### Example 2: Greenfield Intent

**Goal**: "Build a new authentication system with OAuth2"

**Classification**:
- Keywords matched: "build", "new system"
- Type: GREENFIELD
- Confidence: medium (2 keywords)
- Min questions: 5
- Max questions: 10

### Example 3: Refactor Intent

**Goal**: "Refactor the user service to extract common utilities"

**Classification**:
- Keywords matched: "refactor", "extract"
- Type: REFACTOR
- Confidence: medium (2 keywords)
- Min questions: 3
- Max questions: 5

### Example 4: Default MID_SIZED

**Goal**: "Update the dashboard to show metrics"

**Classification**:
- Keywords matched: none significant
- Type: MID_SIZED
- Confidence: low
- Min questions: 3
- Max questions: 7
