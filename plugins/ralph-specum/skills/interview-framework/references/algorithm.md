# Critical-Frontier Interview Algorithm

Use this state machine for every normal-mode phase interview.

## 1. Establish the interview

```text
context = goal + applicable prior artifact bytes or research relevance context
phase = start | triage | research | requirements | design | tasks
interviewId = stable ID for this phase attempt
discoveryRevision = current skill discovery revision
contextDigest = SHA-256 for the ordered current phase context

complete discovery and preload
record-skill-load(state, manifest)
begin-interview(state, phase, interviewId, round, discoveryRevision, contextDigest)
```

Compute the digest from the length-framed phase, exact goal snapshot, and current artifact-source bytes defined in `normal-mode-gates.md`. The helper re-reads those sources and recomputes the digest at every gate. Exclude answers, state, receipts, discovery history, and skill bytes. Reuse the existing interview ID, immutable digest, discovery revision, and round when resuming. `begin-interview` preserves the active record. Advance one layer with `open-frontier --round N+1`; do not overwrite partial answers.

## 2. Build the design tree

For each candidate topic from the phase territory:

1. Assign a stable decision ID.
2. Mark dependencies on other decisions.
3. Inspect the codebase and prior artifacts for discoverable facts.
4. Drop the topic when it fails the critical decision test.
5. Resolve it from evidence when the answer is factual.
6. Keep it open only when user judgment can materially change the artifact.

Represent each open node as:

```text
{
  id,
  dependencies,
  evidence,
  options[2..4],
  recommendation,
  rationale,
  tradeoffs,
  consequences
}
```

Apply clear instruction precedence automatically. If loaded skill contracts still conflict materially after system, developer, user, project, plugin, and skill precedence is applied, create an unblocked conflict decision in the first layer. Describe both unresolved contracts and the consequence of choosing each.

## 3. Traverse by frontier

```text
while critical open nodes remain:
  frontier = every open node whose dependencies are resolved
  inspect any newly discoverable facts
  remove nodes resolved by evidence or inference
  frontier = recompute frontier

  if frontier is empty:
    report the blocking dependency or conflict
    stop without delegating

  call open-frontier with the current round for every frontier decision ID
  ask every node in frontier using AskUserQuestion
  chunk only at the tool's four-question maximum

  call classify-reply on the whole response

  if bare skip after an active question:
    call skip with decision ID skip-confirmation, reason, defaults, and assumptions
    leave state awaiting_confirmation
    break

  if control-only:
    keep every frontier node open
    ask the same frontier again
    continue

  for each substantively answered node:
    record-answer immediately
    mark that node resolved

  keep omitted or ambiguous nodes open
  infer dependent answers only when the inference is deterministic
```

Ask all independent decisions together. Never reduce the batch below four merely to simulate a one-question-at-a-time conversation.

## 4. Handle partial and free-text answers

- Map each clear answer to its stable decision ID.
- Persist the mapped answers before asking again.
- Keep unanswered questions active.
- Turn ambiguous free text into a focused follow-up only when the ambiguity changes a material outcome.
- Inspect any factual claim that can be verified locally before asking the user to confirm it.
- Bound follow-ups by decision resolution, not an arbitrary question count.

## 5. Prepare the decision brief

When no critical node remains open, synthesize one recommended approach. Include viable rejected alternatives only when their tradeoffs help the approval decision.

```text
brief = {
  resolved decisions,
  recommended approach,
  material tradeoffs,
  defaults,
  assumptions,
  unresolved non-material items,
  skill conflicts and resolutions
}
```

Call `await-confirmation` with a stable confirmation decision ID and the recommended approach. Then ask the explicit final approval question.

## 6. Process final approval

```text
if explicit "Approve and delegate" selection:
  confirm(state, confirmationDecisionId or skip-confirmation, source)
  check-delegation(state, phase, interviewId, discoveryRevision, contextDigest)
  delegate immediately

if "Revise decisions":
  call revise once with every affected decision ID
  reopen affected nodes
  invalidate dependent answers when necessary
  return to frontier traversal

if "Cancel":
  leave the interview nonterminal
  stop without delegation

if control-only text:
  keep awaiting_confirmation
  repeat the approval question
```

Approval of an earlier phase does not approve the current phase. Artifact approval after writing does not substitute for this pre-delegation approval.

## 7. Quick mode

Only exact `--quick` authorization may bypass the interview. Record mode first, begin the phase interview so the helper writes `bypassed_quick`, then run the delegation check. Natural-language requests, `-q`, stale booleans, and legacy malformed quick state do not bypass the gate.
