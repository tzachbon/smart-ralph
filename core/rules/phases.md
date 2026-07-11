# Phase transition contract

The normal phase order is research, requirements, design, tasks, implementation,
then complete. A blocked phase may be entered from any phase and must record the
blocking condition and the evidence needed to resume in `progress.md`.

A phase transition requires:

1. The current artifact exists and has passed its verification checks.
2. The user has approved it when the approval contract requires approval.
3. `progress.md` records the new phase, approval boundary, timestamp, and next
   action.

Changing an upstream artifact moves the workflow back to that phase and
invalidates downstream approvals. Runtime continuation mechanisms never change
the durable phase by themselves.
