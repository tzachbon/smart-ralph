# Grilling Examples

## Whole critical frontier

Suppose requirements has three independent critical decisions: primary user, compatibility promise, and data retention. Ask all three in one `AskUserQuestion` call. Put `[Recommended]` on the grounded first option for each and name its tradeoff. Do not ask repository framework, output path, or ticket number when those facts are discoverable.

If five independent critical decisions are open, ask four in the first call and one in the second. The tool maximum is the only batching reason.

Resolve repository facts and domain language before asking. For example, inspect the active authentication boundary and its `CONTEXT.md` definition instead of asking which module owns it. Ask only when the remaining boundary choice materially changes the artifact.

## Partial answer

The user answers the primary-user and retention questions but omits compatibility.

1. Record both answered decision IDs immediately.
2. Leave compatibility open.
3. Recompute dependencies.
4. Ask compatibility plus any decisions it unblocked.

Do not discard the two saved answers or restart the round.

If the user selects `Other`, create a specific dependent decision from the supplied alternative. Do not ask a generic "what did you have in mind?" question.

## Control-only reply

Active frontier: architecture boundary and rollout safety.

User: `proceed`

Result: persist no answer, keep both decisions open, and ask the same frontier again. `continue`, `go ahead`, and `apply the changes` behave the same way.

## Bare skip

Active frontier: test depth and rollback policy.

User: `skip`

Result: record the phase interview as skipped with the recommended test depth and rollback policy listed as defaults and assumptions. Present those choices in the final decision brief and require explicit approval before delegation.

User: `Skip browser tests; keep the rollback task.`

Result: treat the reply as substantive. Persist both decisions. It is not a bare skip.

## Final approval

Present:

```text
Decision brief
- Scope: existing API only
- Compatibility: preserve the current client contract
- Approach: extend the current module
- Tradeoff: smallest change, but keeps the current coupling
- Assumptions: current deployment pipeline remains available
```

Ask `Approve and delegate`, `Revise decisions`, or `Cancel`. Only the explicit approval selection completes the gate. After approval, call the helper check and launch the artifact agent in the same response.

## Artifact revision

After the agent writes `design.md`, the user says `apply the changes` and supplies reviewer findings.

Result: delegate the revision with those findings, show the updated walkthrough, and ask for artifact approval again. Keep the phase in artifact approval until the user explicitly approves.
