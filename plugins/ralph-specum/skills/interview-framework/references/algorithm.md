# Grilling Algorithm

Use this algorithm for every normal-mode Ralph interview.

```text
GRILL:
  1. GATHER CONTEXT
     - Read the original goal, .progress.md, .ralph-state.json, and prior artifacts.
     - Read <default-specs-dir>/.index/index.md when present.
     - Open related indexed entries and existing specs that may affect the goal.
     - Read CONTEXT-MAP.md and its applicable CONTEXT.md, or root CONTEXT.md.
     - Read the calling command's exploration territory.

  2. BUILD DESIGN TREE
     nodes = decisions implied by:
       - the goal and phase territory
       - prior artifacts and interview rounds
       - spec-index relationships
       - domain-language conflicts
       - concrete scenarios and edge cases
       - contradictions between user claims and code

     for each node:
       classify unknowns as FACT or USER_DECISION
       record prerequisite decision and fact dependencies
       set status = OPEN, INVESTIGATING, RESOLVED, or OUT_OF_SCOPE

  3. RESOLVE FACTS
     fact_frontier = discoverable facts whose prerequisites are resolved
     dispatch independent fact_frontier lookups in parallel
     mark each lookup INVESTIGATING
     on result:
       record evidence
       mark fact RESOLVED
       update dependent nodes

  4. ASK USER FRONTIER
     user_frontier = every OPEN user decision whose prerequisites are RESOLVED

     if user_frontier is not empty:
       build one numbered round from the whole frontier
       for each question:
         ground it in facts and prior answers
         derive a recommended answer and rationale
         present 2-4 meaningful options with recommendation first and Other last
       if AskUserQuestion is available:
         submit the round through AskUserQuestion
       else:
         render the same numbered round in the response
       wait for every answer in the round

       for each answer:
         mark the node RESOLVED
         infer dependent answers only when the inference is justified
         add newly exposed branches
         challenge glossary conflicts or fuzzy terms
         test domain boundaries with concrete scenarios where needed
         update CONTEXT.md immediately when a domain term resolves

       append the round to .progress.md
       return to RESOLVE FACTS

  5. HANDLE APPARENT STOP SIGNALS
     if the user asks to stop while unresolved branches remain:
       show the remaining branches
       ask whether each branch is out of scope or still needs resolution
       mark OUT_OF_SCOPE only after explicit confirmation
       return to RESOLVE FACTS

  6. COMPLETE
     if any fact is INVESTIGATING:
       wait for it and return to RESOLVE FACTS
     if any decision is OPEN:
       return to ASK USER FRONTIER
     if every branch is RESOLVED or OUT_OF_SCOPE:
       summarize decisions, scope, approach, and domain-language updates
       ask the user to confirm shared understanding
       if corrected:
         reopen affected nodes and return to RESOLVE FACTS
       if confirmed:
         store final summary in .progress.md
         delegate to the phase agent
```

## Invariants

- Ask no repository fact as a user question.
- Ask no dependent decision before its prerequisites resolve.
- Ask every currently unblocked user decision in the same round.
- Add no fixed question cap or early-exit heuristic.
- Advance no phase with an open frontier.
- Create no interview mode or counter in `.ralph-state.json`.
