---
spec: "<spec-name>"
phase: "prototype"
id: "<prototype-id>"
status: "terminal"
verdict: "<validated|rejected|inconclusive|cancelled|failed|skipped>"
kind: "<logic|ui>"
captureMode: "<retained|ephemeral>"
triggerMode: "<suggested|explicit|quick>"
triggerPhase: "<main-phase>"
returnPhase: "<main-phase>"
returnTaskIndex: null
decisionOwner: "<user|agent>"
resolutionMode: "<resolution-mode>"
gateApproved: false
created: "<RFC3339-timestamp>"
completed: "<RFC3339-timestamp>"
sourceDisposition: "<retained|deleted|not_created>"
evidenceHash: null
cleanupReceiptHash: null
supersedes: []
conflictsWith: []
resolves: []
resolvedAt: null
---

## Question

<One falsifiable question.>

## Blocking Declaration

<Blocked artifacts or transitions, or none.>

## Isolation

<Resolved source path, branch, base commit, and approved transferred paths.>

## Run Instructions

<One runnable command or none when source was not created.>

## Cases Or Variants

<Logic cases or three UI variants.>

## Evidence And Observations

<Evidence pointers, hashes, and observations.>

## Verdict

<Terminal verdict and decision.>

## Downstream Handoff

<Selected downstream effect or exclusion.>

## Conflict Resolution

<Winner, losers, evidence, and rationale, or none.>

## Staleness

<Stale artifacts and task indexes, or none.>

## Source Disposition

<Retained pointers, verified deletion receipt, or not-created reason.>
