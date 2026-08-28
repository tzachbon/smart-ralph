# Grilling Examples

## One Frontier Round

Assume repository exploration has established that the project uses REST, has no background worker, and already exposes an authenticated admin API. Two independent user decisions are now unblocked.

```text
Q1 - Delivery boundary: Should the first version run inside the existing admin API or introduce a worker?

Recommendation: Keep it in the admin API. The repository has no worker infrastructure, and the current workload does not justify adding one.

Options:
- [Recommended] Extend the admin API
- Introduce a background worker
- Other

Q2 - First-release scope: Should the first version process one item or support batches?

Recommendation: Start with one item. This proves the workflow without committing to batch failure semantics.

Options:
- [Recommended] One item per request
- Batch processing
- Other
```

Ask both questions in the same round because neither depends on the other. A retry-policy question belongs to a later round because it depends on the delivery-boundary answer.

Submit this round through `AskUserQuestion` when available. Otherwise render the block in the response and wait for both answers.

## Fact Lookup While a Round Continues

If deployment support requires a code lookup, mark that branch `INVESTIGATING`. Continue the round with unrelated scope and user-experience decisions. Ask deployment decisions only after the lookup returns.

## Domain-Language Challenge

If `CONTEXT.md` defines **Workspace** as a tenant boundary and the user says "account" while describing tenant ownership, ask:

```text
Q3 - Canonical owner term: Do you mean the existing Workspace concept, or a separate user Account?

Recommendation: Use Workspace if the boundary matches the glossary and code. This avoids introducing two names for the same domain concept.
```

After confirmation, update `CONTEXT.md` in that round.

## Progress Storage

```markdown
## Interview Responses

### Design Grill - Round 1
- Facts resolved: Existing admin API at `src/admin`; no worker runtime configured
- Decisions: Delivery boundary -> extend admin API
- Decisions: First-release scope -> one item per request
- Domain language: Workspace -> tenant boundary that owns the operation
- Frontier after round: failure behavior, retry policy

### Design Grill - Round 2
- Decisions: Failure behavior -> return the existing problem-details response
- Decisions: Retry policy -> caller retries; service adds no retry queue
- Out of scope: batch partial-failure semantics
- Frontier after round: empty

### Design Grill - Confirmed
- Shared understanding confirmed by user
- Chosen approach: extend the existing admin API for single-item processing
```
