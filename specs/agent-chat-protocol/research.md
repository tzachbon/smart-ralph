# Research: agent-chat-protocol

**Spec**: agent-chat-protocol
**Phase**: research
**Created**: 2026-04-07

---

## Executive Summary

FLOC (Floor Control for Agent Collaboration) es un framework de señales que填补 five communication gaps en el chat basado en filesystem entre executor y reviewer: turn-taking (→ OVER), acknowledgment (→ ACK), silencio diferenciado (→ STILL/→ ALIVE), urgencia (→ URGENT), y cierre de debate (→ CLOSE). El framework extiende el canal unidireccional existente task_review.md hacia un log de conversación bidireccional en `specs/<specName>/chat.md`.

Web search para "FLOC floor control AI agent collaboration" no devolvió resultados — FLOC como protocolo nombrado no existe en literatura publicada. El framework fue sintetizado internamente a partir de walkie-talkie protocols, FIPA ACL performatives, y patrones de team chat heartbeat.

---

## External Research

### Prior Art Surveyed

| Source | Relevant Finding | Applicability |
|--------|-----------------|---------------|
| Google A2A Protocol | Task routing and agent-to-agent message passing | Define *qué* agents send, not *when* or *how* they negotiate turns |
| IBM ACP | Agent communication primitives | Coordination-focused, not conversational floor control |
| Anthropic MCP | Tool and resource access protocol | Infrastructure protocol, not inter-agent chat semantics |
| FIPA ACL Performatives | `request`, `inform`, `confirm`, `query-*` | Richer than task routing but still about *message types* not *turn management* |
| Walkie-talkie "change" protocol | Explicit turn handoff signal | Direct model for `→ OVER` |
| Team chat heartbeat patterns | Periodic `I'm here` signals in Slack/Teams | Model for `→ ALIVE` and `→ STILL` |

**Key finding**: All three major agent protocols (A2A, ACP, MCP) address **message routing** (what goes where) but none address **conversational floor management** (when to speak, when to listen, when silence means OK vs. dead). This is the gap FLOC fills.

**Source**: [getstream.io blog — AI Agent Protocols](https://getstream.io/blog/ai-agent-protocols/)

### No FLOC Literature Found

FLOC as a named protocol does not appear in published literature. The FLOC framework in this spec is synthesized from first principles, not an existing standard.

---

## Codebase Analysis

### Current Architecture

```
spec-executor (Session 1)                  external-reviewer (Session 2)
       |                                           |
       |-- writes --> .progress.md                |
       |-- writes --> tasks.md (checkboxes)        |
       |-- reads  <-- task_review.md              |-- writes --> task_review.md
       |                                           |
       |-- reads  <-- .ralph-state.json <----------|-- writes --> .ralph-state.json
       |                                           |
       (NO CHANNEL FOR BIDIRECTIONAL CHAT) <-------|--> (monologues only, no response possible)
```

### 8 FLOC Signals

| Signal | Meaning | Blocking? | Writer | Timeout |
|--------|---------|-----------|--------|---------|
| `→ OVER` | "Done speaking, awaiting response" | YES — writer blocks | executor or reviewer | 1 task then assume CONTINUE |
| `→ ACK` | "Read, processing" | No | reviewer or executor | — |
| `→ CONTINUE` | "Read, no response needed, proceed" | No | reviewer or executor | — |
| `→ HOLD` | "Pre-task gate. Read before starting next task." | YES — blocks task start only, NOT mid-task | executor or reviewer | Until ACK/CONTINUE at next task boundary |
| `→ STILL` | "Intentionally silent, working" | No | reviewer | 3-task TTL then alarm |
| `→ ALIVE` | "Still active, no issues" | No | reviewer | Every 3 tasks of silence |
| `→ CLOSE` | "Debate resolved, won't reopen" | Response to OVER | reviewer | — |
| `→ URGENT` | "Interrupt immediately" | Breaks task boundary | reviewer only | After active qa-engineer delegation |

**HOLD semantics (CORRECTED)**: spec-executor.md reads task_review.md only at task START, not continuously. If reviewer writes HOLD during executor's task execution, executor won't see it until current task completes and next task begins. HOLD is a **pre-task gate**, same semantics as PENDING in task_review.md.

### 3 Additional smart-ralph-specific Signals

| Signal | Meaning | Writer | Purpose |
|--------|---------|--------|---------|
| `→ DEADLOCK` | "Cannot resolve, human needed" | executor or reviewer | Escalation to human |
| `→ INTENT-FAIL` | "I plan to write FAIL, respond first" | reviewer | Pre-FAIL negotiation |

**CONTEXT-RESET NOT a new signal** — external-reviewer.md Section 4 (Anti-Blockage Protocol) already handles contaminated context via WARNING severity:critical in task_review.md with fix_hint "Contexto contaminado. Lee .ralph-state.json → taskIndex para saber dónde estás." CONTEXT-RESET is implemented via HOLD in chat.md to make this signal more visible pre-task, not a new mechanism.

### The 5 Gaps FLOC Resolves

| Gap | Problem | Solution |
|-----|---------|----------|
| 1. Turn-taking | Append collision if both write simultaneously | `→ OVER` as explicit turn handoff; atomic rename pattern |
| 2. Acknowledgment | Executor doesn't know if reviewer read | `→ ACK`/`→ CONTINUE` required within 1 task window |
| 3. Intentional silence vs. problem | Can't distinguish "monitoring OK" from "session died" | `→ ALIVE` heartbeat every 3 tasks of silence |
| 4. Urgency | No mechanism to interrupt mid-task | `→ URGENT` breaks task boundary after qa-engineer delegation |
| 5. Debate closure | Debates remain open indefinitely | `→ CLOSE` marks debate resolved |

### Chat Format

```markdown
### [executor → reviewer] 14:32:05 | task-2.4 | OVER
He posicionado Type Consistency Pre-Check antes del bloque data-testid
porque FR-A4 dice "before implementation begins". ¿Coincides?

### [reviewer → executor] 14:33:41 | task-2.4 | ACK → CONTINUE
Sí, correcto. FR-A4 tiene precedencia. Sigue.
```

**Parsing**: `grep "→ OVER" chat.md | grep "\[executor → reviewer\]"`

### Key Constraints

- **Filesystem-only** — no external infrastructure
- **Atomic writes mandatory** — O_APPEND or temp file + rename; concurrent appends from two agents require non-negotiable write atomicity
- **qa-engineer excluded** — sub-agent via Task tool, no session independence
- **task_review.md unchanged** — formal decisions remain authoritative
- **Human intervention always possible** — human can read/intervene anytime, voice is final
- **HOLD is pre-task gate** — executor reads chat only at task start, not mid-task execution
- Si chat.md no existe → spec-executor no debe buscar ni esperar señales OVER/HOLD de él (igual que hoy no busca task_review.md si no existe)
- Si chat.md existe pero está vacío → ningún agente está conectado todavía, silencio = UNKNOWN (tu Regla 6 corregida)
- Si chat.md tiene al menos 1 mensaje → protocolo FLOC activo
- **Activación tiene dos umbrales**: la **existencia** del archivo activa la búsqueda (el executor lo lee si existe); la **existencia + 1 mensaje** activa el protocolo FLOC completo. La condición mínima es "el archivo existe" — igual que task_review.md. El product-manager preguntará al humano si activa el revisor → si dice sí, se crea task_review.md y chat.md. Si dice no, ninguno existe y el executor no los busca. Este es el mínimo cambio real: una línea en el interview-framework que crea dos archivos en lugar de uno.
---

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Filesystem-only, no new infra, append-only semantics |
| Effort Estimate | M | New template + 2 agent modifications (spec-executor.md, external-reviewer.md) |
| Risk Level | Low | Parallel channel, does not modify task_review.md or .ralph-state.json schema |
| Backward Compatibility | High | task_review.md unchanged, chat.md is additive |

---

## Related Specs

| Spec | Relationship | mayNeedUpdate |
|------|--------------|---------------|
| `reviewer-subagent` | Directly related — defines the external-reviewer agent | YES — must implement FLOC signals, including HOLD as pre-task gate semantics |
| `parallel-task-execution` | Shares agent coordination concerns | No — different scope |
| `iterative-failure-recovery` | Stuck State Protocol related to OVER timeout | Possibly — OVER timeout may interact with effectiveIterations |
| `qa-verification` | qa-engineer not in chat (sub-agent) — confirmed out of scope | No |

---

## Open Questions

1. ~~Atomic write implementation~~ — **RESOLVED: Critical NFR, mandating O_APPEND or temp file + rename pattern.** Two agents write to same filesystem in real-time (executor advances task-by-task, reviewer polls every ~30s). Concurrent appends risk file corruption. Resolution is required in requirements phase, not deferred. Options: (a) Unix O_APPEND (atomic for writes < PIPE_BUF/~4KB), (b) `chat.tmp.{agent}.{timestamp}` → atomic rename to append position. Must decide in requirements.
2. **Chat archival**: When does `chat.md` get rotated/archived? Spec defers this ("deferred until size becomes issue").
3. **qa-engineer exclusion**: Confirmed qa-engineer communicates via VERIFICATION_PASS/FAIL/DEGRADED, not chat.
4. **chat.lastReadIndex state model**: If stored in .ralph-state.json (shared by executor and reviewer), both agents write to same JSON file. Options: (a) per-agent state files (e.g., .chat-state.executor.json, .chat-state.reviewer.json), (b) atomic JSON updates small enough to avoid collision. Must decide in requirements/design.
Pattern already established in spec-executor.md: jq … > /tmp/state.json && mv /tmp/state.json .ralph-state.json. Apply same pattern for chat.lastReadIndex writes.
---

## Recommendations for Requirements

1. **MANDATE atomic writes from day 1** — critical NFR, not optional. O_APPEND (atomic for <4KB writes) or temp file + rename pattern. Two agents write in real-time; concurrent append corruption is unacceptable. Decide mechanism in requirements.
2. **Start with INTENT-FAIL and ALIVE** — highest value, lowest risk. INTENT-FAIL eliminates false-positive FAILs; ALIVE solves silence ambiguity.
3. **Synchronize OVER with PENDING** — when executor writes OVER, also write PENDING to task_review.md. Single blocking mechanism visible in both channels.
4. **HOLD is pre-task gate, not mid-task interrupt** — document explicitly; executor reads chat at task start only, same as task_review.md.
5. **CONTEXT-RESET via HOLD, not new signal** — reuse existing external-reviewer.md Section 4 WARNING mechanism, add HOLD notification in chat for visibility.
6. **Resolve chat.lastReadIndex model** — per-agent state files or atomic JSON updates. Both agents write .ralph-state.json; collision risk must be addressed.
7. **Keep task_review.md authoritative** — chat.md is reasoning/debate, task_review.md is formal decisions.
8. **Define qa-engineer exclusion explicitly** — document that qa-engineer is not a chat participant.

---

## Sources

- `docs/agen-chat/agent-chat-research.md` — Internal research on FLOC framework and 5 gaps
- `plugins/ralph-specum/agents/spec-executor.md` — Executor agent current protocol
- `plugins/ralph-specum/agents/external-reviewer.md` — Reviewer agent current protocol
- [getstream.io — AI Agent Protocols](https://getstream.io/blog/ai-agent-protocols/) — A2A, ACP, MCP comparison
