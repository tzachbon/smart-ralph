# Verification contract

Every implementation batch must define acceptance criteria and the narrowest
useful verification command before work starts. A coordinator marks tasks
complete only after validating the returned changes and verification evidence.

Run focused checks first, then broader checks when the change risk justifies
them. Record commands, outcomes, and unverified risks in `progress.md`. Failed
verification leaves affected tasks incomplete.

Delegated work reports must contain `Answer`, `Evidence`, `Risks`,
`Verification performed`, and `Changed files`. Missing evidence is a failed
work packet, not successful completion.
