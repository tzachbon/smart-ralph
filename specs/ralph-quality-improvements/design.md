---
spec: ralph-quality-improvements
phase: design
created: 2026-04-06
updated: 2026-04-06
---

# Design: ralph-quality-improvements

## Goal

Improve Smart Ralph's spec quality by adding self-review checklists to prevent 5 categories of recurring spec errors (Track A), and introduce an External Reviewer Protocol that allows an independent async agent to review completed tasks via filesystem files (Track B).

9 Functional Requirements across 2 tracks:
- **Track A (Spec Quality)**: FR-A1, FR-A2, FR-A3, FR-A3b, FR-A4
- **Track B (External Reviewer Protocol)**: FR-B1, FR-B2, FR-B3, FR-B4

---

## Track A — Spec Quality

### FR-A1: Document Self-Review Checklist in architect-reviewer.md

**What changes**: `plugins/ralph-specum/agents/architect-reviewer.md`

**Where (anchor sections)**:
- AFTER: `## Quality Checklist`
- BEFORE: `## Final Step: Set Awaiting Approval`

**Resulting structure** (relevant portion):

```markdown
## Quality Checklist

Before completing design:
- [ ] Architecture satisfies all requirements
...
- [ ] Set awaitingApproval in state (see below)

## Document Self-Review Checklist

<mandatory>
Execute AFTER writing the full document, BEFORE setting awaitingApproval.

**Step 1 — Type consistency**
For every `Callable[..., X]` type annotation in design.md:
- Find its corresponding usage example in the same document
- If usage uses `await` → type MUST be `Callable[..., Awaitable[SomeType]]`
- If usage does NOT use `await` → type MUST NOT use Awaitable
- Fix any mismatch before delivering. Do not leave mismatched types.

**Step 2 — Duplicate section detection**
Run mentally (or via grep): check for any H3 heading (###) appearing more
than once in the document. If found: remove the duplicate, keep the
last/most complete version.

**Step 3 — Ordering and concurrency notes**
For every `await` expression in code blocks that makes a resource visible
to concurrent callers (e.g., storing a callback, setting a flag, writing
to shared state):
- Ask: "If a concurrent caller accessed this resource before this await
  completes, what breaks?"
- If something breaks: add inline comment `# CRITICAL: assign after await`
  in the code block AND add a row to the `## Concurrency & Ordering Risks`
  section

**Step 4 — Internal contradiction scan**
For every sentence containing "CANNOT", "MUST NOT", "not possible",
"cannot be stored":
- Verify it does not contradict any FR, code block, or other section in
  the same document
- If contradiction found: remove the outdated statement, add comment
  `<!-- superseded by FR-X -->`
</mandatory>

Quality Checklist addition:
- [ ] Document Self-Review Checklist passed (all 4 steps)

## Final Step: Set Awaiting Approval
...
```

---

### FR-A2: Concurrency & Ordering Risks in design.md template

**What changes**: `plugins/ralph-specum/templates/design.md`

**Where (anchor sections)**:
- AFTER: `## Edge Cases` section
- BEFORE: `## Test Strategy` section

**Resulting structure** (relevant portion):

```markdown
## Edge Cases

- **{{Edge case 1}}**: {{How handled}}
- **{{Edge case 2}}**: {{How handled}}

## Concurrency & Ordering Risks

<!-- Document any sequence-critical operations, async ordering constraints,
     or race conditions an implementer MUST know.
     If none identified: write "None identified." — do NOT leave this blank. -->

| Operation | Required Order | Risk if Inverted |
|-----------|---------------|-----------------|
| (example) capture async callback | AFTER `await async_add_entities()` | Service handler race condition during setup |

## Test Strategy
...
```

Note: The example row (capture async callback) is included as a reference pattern. Architects replace it with actual risks identified in their design. Step 3 of the Document Self-Review Checklist feeds into this section.

---

### FR-A3: On Requirements Update in product-manager.md

**What changes**: `plugins/ralph-specum/agents/product-manager.md`

**Where (anchor sections)**:
- AFTER: `## Append Learnings` section
- BEFORE: `## Requirements Structure`

**Resulting structure** (relevant portion):

```markdown
## Append Learnings

<mandatory>
After completing requirements, append any significant discoveries to `<basePath>/.progress.md`
...
```

**Insertion point**: After the `</mandatory>` closing tag and before `## Requirements Structure`

```markdown
## On Requirements Update

<mandatory>
When updating an EXISTING requirements.md (not creating a new one):

1. Note the concept/value being replaced or superseded
2. Search the ENTIRE requirements.md for any other occurrence of the old
   concept: mentally scan all User Adjustments, Goal section, Non-Functional
   Requirements, and the document header
3. For every occurrence outside the updated section: decide if it should
   be updated to match the new concept, or removed as outdated
4. Verify the document header and any "User Adjustment" comments match the
   current FR content — if any header text contradicts an FR, the FR wins,
   remove or update the header text
5. Append a one-line changelog at the bottom of requirements.md:
   `<!-- Changed: <brief description> — supersedes User Adjustment #N if applicable -->`
</mandatory>

Quality Checklist addition:
- [ ] If updating existing requirements: On Requirements Update steps completed
```

---

### FR-A3b: On Design Update in architect-reviewer.md

**What changes**: `plugins/ralph-specum/agents/architect-reviewer.md`

**Where (anchor sections)**:
- AFTER: `## Document Self-Review Checklist` (FR-A1 insertion)
- BEFORE: `## Karpathy Rules`

**Resulting structure**: A separate `<mandatory>` section:

```markdown
## On Design Update

<mandatory>
When updating an EXISTING design.md (not creating a new one):

1. Note the concept/value being replaced or superseded
2. Search the ENTIRE design.md for any other occurrence of the old
   concept: mentally scan the Overview, Components, Data Flow, Technical
   Decisions, and any other section using the old concept
3. For every occurrence outside the updated section: decide if it should
   be updated to match the new concept, or removed as outdated
4. Verify the document header and Overview are consistent with the current
   design content — if any header text contradicts an FR or component,
   the detailed content wins, update or remove the header text
5. Append a one-line changelog at the bottom of design.md:
   `<!-- Changed: <brief description> — supersedes section X if applicable -->`
</mandatory>

Quality Checklist addition:
- [ ] If updating existing design.md: On Design Update steps completed
```

Note: This is separate from the Document Self-Review Checklist (FR-A1). The checklist runs on every design delivery. The On Design Update section activates only when updating an existing design.

---

### FR-A4: Type Consistency Pre-Check in spec-executor.md

**What changes**: `plugins/ralph-specum/agents/spec-executor.md`

**Where (anchor sections)**:
- AFTER: the `data-testid` update block inside "## Task Types / ### Implementation Tasks"
- The subsection has NO `<mandatory>` tag

**Resulting structure** (inside Implementation Tasks section):

```markdown
### Implementation Tasks (no tag)
Direct implementation: write code, modify files, run commands.

After completing any implementation task, check if it introduced new `data-testid`
attributes into source files:
[existing data-testid block unchanged]

### Type Consistency Pre-Check (typed Python or TypeScript tasks)

Before implementing any task that involves `Callable`, `Awaitable`,
`Coroutine`, `Promise`, or similar async type annotations:

1. Find the type declaration in design.md or requirements.md
2. Find the usage example in the same document for that type
3. Verify they are consistent:
   - `Callable[..., None]` → usage must NOT use `await`
   - `Callable[..., Awaitable[T]]` → usage MUST use `await`
   - TypeScript `() => void` → usage must NOT use `await`
   - TypeScript `() => Promise<T>` → usage MUST use `await`
4. If inconsistent: use the usage example as ground truth (it represents
   intent), fix the type in your implementation to match usage, and append
   to .progress.md:
   `Type corrected: spec declared X but usage example shows Y — implemented as Y`
5. If both the type AND the usage are ambiguous (neither clearly implies
   sync or async): ESCALATE before implementing, do not guess.
```

---

## Track B — External Reviewer Protocol

### FR-B1: task_review.md template (NEW file)

**What creates**: `plugins/ralph-specum/templates/task_review.md`

**Exact structure**:

```markdown
# Task Review Log

<!--
  Written by: external reviewer agent (independent process)
  Read by: spec-executor at the start of each task

  Workflow:
  - FAIL (critical): reviewer unmarks task in tasks.md + increments
    external_unmarks in .ralph-state.json + writes entry here
  - WARNING (minor): reviewer writes entry here, task stays marked done
  - PASS: reviewer writes entry here for audit trail
  - PENDING: reviewer is working on it, spec-executor should not re-mark
    this task until status changes

  spec-executor: read this file before starting each task. See External Review Protocol below.
-->

## Reviews

<!-- Template for each review entry — copy and fill:

### [task-X.Y] <task title>
- **status**: PASS | FAIL | WARNING | PENDING
- **severity**: critical | minor | note
- **reviewed_at**: <ISO 8601 timestamp>
- **criterion_failed**: <exact acceptance criterion text from tasks.md, or "none">
- **evidence**: <exact error message, diff, or test output — not a summary>
- **fix_hint**: <optional: specific suggestion for the fix>
- **resolved_at**: <!-- spec-executor fills this when fix is confirmed -->

-->
```

---

### FR-B2: External Review Protocol in spec-executor.md

**What changes**: `plugins/ralph-specum/agents/spec-executor.md`

**Where (anchor sections)**:
- AFTER: `## When Invoked` section
- BEFORE: `## Task Loop` section

**Resulting structure** (between When Invoked and Task Loop):

```markdown
## When Invoked

You receive via Task delegation:
- **basePath**: Full path to spec directory
- **specName**: Spec name
- **taskIndex**: Which task to start from (0-based)

Use `basePath` for ALL file operations.

## External Review Protocol

<mandatory>
On every task start (before reading tasks.md to find the next task):

1. Check if `<basePath>/task_review.md` exists
2. If it does NOT exist: proceed normally
3. If it DOES exist:
   a. Read it fully
   b. Find any entry where task id matches the current task being started
   c. Apply the following rules based on status:
      - **FAIL**: treat as VERIFICATION_FAIL. The fix_hint is the starting
        point. Apply fix, then mark the entry's `resolved_at` with timestamp
        before marking the task complete in tasks.md
      - **PENDING**: do NOT start the task. Append to .progress.md:
        "External review PENDING for task X — waiting one cycle". Skip this
        task and move to the next unchecked one. On the next invocation,
        check again.
      - **WARNING**: read the warning, append it to .progress.md, proceed
        with the task but apply the suggested fix if one is provided
      - **PASS**: proceed normally, no action needed

4. Append to .progress.md when a FAIL or WARNING is found:
   `External review [FAIL|WARNING] for task X.Y: <criterion_failed>`
</mandatory>

## Task Loop
...
```

---

### FR-B3: external_unmarks in stuck-detection

**What changes**: `plugins/ralph-specum/agents/spec-executor.md`

**Affected sections**:

1. **Task Loop** section: The iteration increment logic
2. **Stuck State Protocol** section: The escalation trigger

**Changes**:

In the Task Loop, stuck-detection currently uses `taskIteration`. This is replaced/augmented with:

```
effectiveIterations = taskIteration + external_unmarks[taskId]
```

The `effectiveIterations` formula must appear in BOTH the Task Loop description AND the Stuck State Protocol section.

**Resulting structure** (Stuck State Protocol escalation trigger):

```markdown
6. **IF after 2 more attempts (5 total) the test still fails** → ESCALATE:
   ```text
   ESCALATE
     reason: external-reviewer-repeated-fail
     task: <taskId — task title>
     attempts: <effectiveIterations>
     root_cause: external reviewer has unmarked this task <N> times — human investigation required
     resolution: Human investigation required. The external reviewer has already
                 unmarked this task <N> times. This is not a normal stuck-fix loop.
                 Do NOT continue retrying.
   ```
```

And in the Stuck State Protocol intro:

```markdown
## Stuck State Protocol (MANDATORY when a task fails 3+ times)

<mandatory>
IF the same task has failed 3 or more times, each time with a DIFFERENT error:

**NOTE**: `effectiveIterations = taskIteration + external_unmarks[taskId]`
- `taskIteration`: retry attempts in current session
- `external_unmarks[taskId]`: reviewer cycles from prior sessions (NEVER reset by spec-executor)
- Both dimensions stack — external_unmarks ADDS to taskIteration, never replaces it

IF `effectiveIterations >= maxTaskIterations`: ESCALATE immediately with reason
`external-reviewer-repeated-fail`. Do NOT attempt further retries.
...
```

**Key constraint**: `external_unmarks` values are NEVER reset by spec-executor. They are cumulative across sessions. Only the external reviewer increments them.

**Escalation message must include**: `"External reviewer has unmarked this task N times. Human investigation required."`

---

### FR-B4: external_unmarks schema documentation

**What changes**: Documentation of `.ralph-state.json` schema fields

**Where**: In the **`## Task Loop`** section of `spec-executor.md`, near where `.ralph-state.json` is already documented (the section that describes reading/writing the state file). This is the natural anchor because external_unmarks is read during task loop execution. Add the field documentation as a labeled subsection or comment block within that section, not as a floating comment.

**Field documentation**:

```markdown
## external_unmarks field

Type: `object` (map of taskId string → integer count)
Default: `{}` (empty object, field is optional)
Written by: external reviewer only (increments when unmarking a task)
Read by: spec-executor (for stuck-detection, computes effectiveIterations)
Lifetime: cumulative across sessions — NEVER reset by spec-executor
Example:
```json
{
  "taskIndex": 4,
  "taskIteration": 1,
  "external_unmarks": {
    "task-2.4": 2
  }
}
```
```

---

## Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| FR-A1 checklist is `<mandatory>` | A) mandatory tag, B) regular prose | A | Testing Discovery Checklist proved embedded mandatory checks work; agents follow them |
| FR-A3b is separate from FR-A1 | A) merge into checklist, B) separate section | B | On Design Update activates only on updates, not on every delivery; keeps concerns separated |
| FR-B2 insertion after When Invoked | A) after Startup Signal, B) after When Invoked | B | Per resolved design decision: "## When Invoked section exists in the real spec-executor" |
| effectiveIterations stacks | A) replaces taskIteration, B) adds to taskIteration | B | They measure different dimensions; stacking preserves retry history while adding reviewer cycles |
| external_unmarks never reset | A) reset on task start, B) never reset | B | Cumulative reviewer cycles are the intended signal; resetting would defeat the anti-infinite-loop purpose |
| task_review.md is filesystem-only | A) add polling, B) filesystem events only | B | Ralph is event-driven, not polling; external reviewer writes file, next Ralph invocation reads it |

---

## Concurrency & Ordering Risks

| Operation | Required Order | Risk if Inverted |
|-----------|---------------|-----------------|
| Read task_review.md | BEFORE reading tasks.md and selecting next task | External review FAIL/WARNING could be missed, wrong task started |
| Increment external_unmarks | ONLY by external reviewer, never by spec-executor | spec-executor writing this field would corrupt the reviewer-cycle count |
| Mark resolved_at on FAIL entry | AFTER fix is applied, BEFORE marking task complete in tasks.md | Entry marked resolved before fix is confirmed |

---

## Edge Cases

### task_review.md malformed entries
- **Scenario**: Entry missing required fields (status, reviewed_at) or has invalid status value
- **Handling**: Treat as PASS (proceed normally) — malformed entry cannot be interpreted as FAIL
- **User impact**: External review feedback silently ignored for that entry

### task_review.md entry for task that does not exist
- **Scenario**: External reviewer wrote entry for "task-3.1" but tasks.md only goes to task-2.5
- **Handling**: Silently ignore — entry is stale or for a different spec version
- **User impact**: None

### external_unmarks already exists in .ralph-state.json
- **Scenario**: On first use, external_unmarks field already present from prior run
- **Handling**: Treat as cumulative — read existing values, increment from current state
- **Escalate if**: Field name collision with different type (e.g., boolean instead of object) — schema violation

### External review PENDING for a task that later gets re-invoked
- **Scenario**: Task is PENDING, spec-executor skips it. Hours later, external reviewer resolves it to PASS
- **Handling**: On next invocation, spec-executor reads task_review.md, finds PASS (not PENDING), proceeds normally
- **No special handling needed**: PENDING is a transient state

### External review FAIL with no fix_hint
- **Scenario**: External reviewer marks task FAIL but provides no fix_hint
- **Handling**: Treat as VERIFICATION_FAIL with empty fix_hint — executor attempts repair based on evidence field
- **User impact**: Executor may struggle to fix without guidance; escalation likely

---

## Test Strategy

**Project type**: `library` (Ralph plugin — markdown agent prompt files only, no UI, no runtime)

**Observable signals** (verification by grep/read of modified files):

| FR | File | What to verify | Method |
|----|------|---------------|--------|
| FR-A1 | `architect-reviewer.md` | `## Document Self-Review Checklist` exists with 4 steps in `<mandatory>` block; checklist added to Quality Checklist | `grep -n "Document Self-Review Checklist"` and read surrounding lines |
| FR-A1 | `architect-reviewer.md` | `## On Design Update` exists in `<mandatory>` block; checklist item added | `grep -n "On Design Update"` |
| FR-A2 | `templates/design.md` | `## Concurrency & Ordering Risks` section exists between Edge Cases and Test Strategy | `grep -n "Concurrency & Ordering Risks" templates/design.md` |
| FR-A3 | `product-manager.md` | `## On Requirements Update` exists in `<mandatory>` block; checklist item added | `grep -n "On Requirements Update"` |
| FR-A4 | `spec-executor.md` | `### Type Consistency Pre-Check` exists inside Implementation Tasks section | `grep -n "Type Consistency Pre-Check"` |
| FR-B1 | `templates/task_review.md` | New file exists with exact structure (title, workflow comment, Reviews section, entry template) | Read file |
| FR-B2 | `spec-executor.md` | `## External Review Protocol` exists in `<mandatory>` block, positioned after When Invoked, before Task Loop | `grep -n "External Review Protocol"` |
| FR-B3 | `spec-executor.md` | `effectiveIterations = taskIteration + external_unmarks[taskId]` formula appears in both Task Loop and Stuck State Protocol | `grep -n "effectiveIterations"` |
| FR-B3 | `spec-executor.md` | Escalation reason `external-reviewer-repeated-fail` present; escalation message includes reviewer unmark count | `grep -n "external-reviewer-repeated-fail"` |
| FR-B4 | `spec-executor.md` | `external_unmarks` field documented with type object, optional, written by reviewer, read by executor | `grep -n "external_unmarks"` |
| NFR-3 | `plugin.json` + `marketplace.json` | Both versions bumped by +1 patch (read current version dynamically, do not hardcode) | Read both files, compute patch bump, verify both show same new version |

**Hard invariants** (must not change):
- No existing content in modified files altered outside target insertion points
- spec-executor.md stuck-detection is extended only (formula added), not replaced
- external_unmarks is never written by spec-executor — only read
- Task Loop order: read task_review.md BEFORE reading tasks.md

**Escalate if**:
- Any insertion point is ambiguous due to changed file structure
- external_unmarks field already exists in .ralph-state.json with different type

---

## Implementation Steps

1. **FR-A1**: Insert `## Document Self-Review Checklist` in `architect-reviewer.md` after Quality Checklist, before Final Step. Add checklist item to Quality Checklist.

2. **FR-A3b**: Insert `## On Design Update` in `architect-reviewer.md` after Document Self-Review Checklist, before Karpathy Rules. Add checklist item to Quality Checklist.

[VERIFY] Track A checkpoint 1 — architect-reviewer.md
- **Verify**: `grep -n "Document Self-Review Checklist" plugins/ralph-specum/agents/architect-reviewer.md` returns section with 4 steps in `<mandatory>`; `grep -n "On Design Update" plugins/ralph-specum/agents/architect-reviewer.md` returns section in `<mandatory>`; both checklist items present in Quality Checklist
- **Done when**: grep succeeds for all checks; surrounding content unchanged

3. **FR-A2**: Insert `## Concurrency & Ordering Risks` section in `templates/design.md` between Edge Cases and Test Strategy.

[VERIFY] Track A checkpoint 2 — design.md template
- **Verify**: `grep -n "Concurrency & Ordering Risks" plugins/ralph-specum/templates/design.md` finds section between Edge Cases and Test Strategy; table structure present with headers
- **Done when**: grep succeeds; section not empty

4. **FR-A3**: Insert `## On Requirements Update` in `product-manager.md` after Append Learnings. Add checklist item to Quality Checklist.

5. **FR-A4**: Insert `### Type Consistency Pre-Check` subsection in `spec-executor.md` inside Implementation Tasks, after data-testid block.

[VERIFY] Track A checkpoint 3 — product-manager.md + spec-executor.md
- **Verify**: `grep -n "On Requirements Update" plugins/ralph-specum/agents/product-manager.md`; `grep -n "Type Consistency Pre-Check" plugins/ralph-specum/agents/spec-executor.md`
- **Done when**: both grep succeed

6. **FR-B1**: Create `templates/task_review.md` with exact specified structure.

[VERIFY] Track B checkpoint 1 — task_review.md template
- **Verify**: `grep -n "Task Review Log" plugins/ralph-specum/templates/task_review.md`; `grep -n "## Reviews" plugins/ralph-specum/templates/task_review.md`; file exists with entry template fields (status, severity, reviewed_at, criterion_failed, evidence, fix_hint, resolved_at)
- **Done when**: file exists, title and Reviews section present, entry template complete

7. **FR-B2**: Insert `## External Review Protocol` in `spec-executor.md` after When Invoked, before Task Loop.

8. **FR-B3**: Update spec-executor.md Task Loop and Stuck State Protocol to use `effectiveIterations = taskIteration + external_unmarks[taskId]`; update escalation reason to `external-reviewer-repeated-fail`.

9. **FR-B4**: Document `external_unmarks` field schema in spec-executor.md, in the Task Loop section near the state file documentation (not in Startup Signal).

[VERIFY] Track B checkpoint 2 — spec-executor.md external protocol
- **Verify**: `grep -n "External Review Protocol" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "effectiveIterations" plugins/ralph-specum/agents/spec-executor.md` (appears in Task Loop AND Stuck State Protocol); `grep -n "external-reviewer-repeated-fail" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "external_unmarks" plugins/ralph-specum/agents/spec-executor.md` (field schema documented)
- **Done when**: all 4 grep succeed; effectiveIterations appears in at least 2 distinct sections

10. **NFR-3**: Bump version in `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — READ the current version from plugin.json at execution time and bump patch once from that value. Do NOT hardcode a target version. Apply to BOTH files (once, at end of all changes, not per-file).

[VERIFY] Final — version bump
- **Verify**: Both files report the same bumped version; difference between old and new is exactly +1 patch
- **Done when**: `grep` of both version fields shows identical patch-level bump
