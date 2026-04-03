# E2E HA Findings — Pizarra de Investigación Forense

> Rama de trabajo: `research/e2e-ha-findings`  
> **Objetivo:** Reducir el gap entre agentes escribiendo tests malos y tests correctos para HA custom components.

---

## Leyenda de estado

| Icono | Significado |
|---|---|
| ✅ | Confirmado, fuente verificada |
| ⚠️ | Plausible pero sin fuente directa |
| ❌ | Rebatido o descartado |
| 🔍 | Pendiente de investigar más |
| 💬 | En debate, no resuelto |

---

## Hipótesis central (A + B + C)

- **A) Le falta información** — HA routing, 404, sidebar nav
- **B) Le falta metodología** — no experimenta, no verifica que la infra existe
- **C) La fuente de verdad está rota** — `copilot-instructions.md` describe infra inexistente

---

## PLAN DE PRUEBA — Estado completo

| Paso | Acción | Estado | Observaciones |
|---|---|---|---|
| 1-10 | Interview (9 preguntas) | ✅ Completado | Ver Bloque 12 |
| 11 | Phase 1 — Explore codebase | ✅ Completado | Ver Bloque 14 — resultados excelentes |
| 12 | Phase 1 — research-analyst (1er intento) | ❌ Bloqueado/timeout | Agente no retornó. Ver Bloque 15 |
| 13 | Phase 1 — research-analyst (2º intento) | ✅ Completado | Web search rota → pivotó a codebase local. Ver Bloque 16 |
| 14 | Phase 2 — requirements | ✅ Completado | 9 preguntas → 6 US, 9 FR, 3 NFR. Ver Bloque 17 |
| 15 | Phase 2 — design | ✅ Completado + Aprobado | 590 líneas. Sólido. Ver Bloque 18 |
| 16 | Phase 3 — tasks | ✅ Completado | 18 tareas coarse. P15 resuelta. Ver Bloque 19 |
| 16b | Phase 3 — spec-reviewer (en curso) | 🔍 En curso | Validando tasks antes de implement |
| 17 | Phase 3 — implement | 🔍 Pendiente | |
| 18 | qa-engineer verifica | 🔍 Pendiente | |

---

## Bloque 19 — ✅ Phase 3 Tasks: Análisis forense

### Resultado: 18 tareas coarse, 5 fases

| Fase | Tareas | Contenido |
|---|---|---|
| Phase 1 POC | 1.1–1.8 | 6 archivos crear + TypeScript check + smoke test |
| Phase 2 Refactor | 2.1–2.3 | Fix dialog handler, API cleanup, quality gate |
| Phase 3 Testing | 3.1–3.2 | Selector fixes, full suite |
| Phase 4 Quality | 4.1–4.3 + VE1–VE3 | Local CI + CI pipeline + AC checklist + infra VE |
| Phase 5 PR | 5.1–5.2 | PR creation + CI monitor |

### P15 RESUELTA ✅ — El agente detectó solo el bug de scope

Tarea 2.1 incluye explícitamente:
> *"Fix deleteTrip method — the design had `page.on('dialog', ...)` inside an instance method which is wrong"*

El task-planner releyó el design con ojo crítico y detectó el bug sin que nadie se lo dijera.

### P17 — global.teardown.ts NO incluido en tasks

El path hardcodeado `/mnt/bunker_data/...` no aparece como tarea de fix. **Confirmado: el bug solo se descubrirá en VE3/CI.** Esto es el hallazgo esperado.

### P18 — 🔍 NUEVO: Skills ausentes en tasks.md

**Observación:** Ninguna tarea referencia skills del sistema (`playwright-best-practices`, `ha-e2e-testing`, etc.). Las tareas describen qué hacer pero no indican qué skill consultar durante la implementación.

**Pregunta forense:** ¿Es esto un problema de diseño de ralph-specum (las skills deberían referenciarse en tasks) o es intencionado (el agente implementador las consulta por su cuenta)?

**Sub-preguntas:**
- ¿El agente de implement consultará skills proactivamente?
- ¿Si no las consulta, escribirá código peor que si las tuviera?
- ¿Deberían las tasks incluir `skills: [playwright-best-practices, ha-e2e-testing]` por tarea?

**Impacto potencial:** Si el agente implementa sin consultar skills, podría reincidir en patrones erróneos (IIFE baseURL, `page.goto` directo sin auth) que las skills corregirían.

**Fix candidato L:** `tasks.md` debería incluir campo `skills` por tarea con las skills relevantes a consultar.

---

## Bloque 18 — ✅ Phase 2 Design: Análisis forense

### Lo que hizo bien
- **Leyó `config_flow.py` proactivamente** — mapeó los 5 pasos con campos reales
- **Pierce combinator `>>`** documentado correctamente con selectores específicos
- **Separó concerns**: `global.setup.ts` (servidor) vs `auth.setup.ts` (Config Flow)
- **`workers: 1`** — entendió que hass-taste-test no soporta paralelismo
- **P12 RESUELTA ✅** — actualizó plan Docker → hass-taste-test

### Bugs detectados en el design

**P15 — Bug de scope en `deleteTrip()`** → ✅ Detectado en tasks (tarea 2.1)

**P16 — `auth.setup.ts` orphan — no conectado al config:**
Falta en `playwright.config.ts`:
```typescript
projects: [
  { name: 'setup', testMatch: /auth\.setup\.ts/ },
  { name: 'chromium', dependencies: ['setup'], use: { storageState: '...' } }
]
```
🔍 ¿Lo detectará el spec-reviewer? ¿Lo corregirá en implement?

---

## Bloque 17 — ✅ Phase 2 Requirements: Resumen

- 9 preguntas al usuario (interview)
- 6 User Stories (US-1 a US-6), 9 FR, 3 NFR
- Commit: `spec(e2e-ev-trip-planner): add requirements for EV Trip Planner E2E test suite`

---

## Bloque 16 — ✅ research-analyst (2º intento): Hallazgos

- `hass-taste-test` diseñado para Lovelace cards — native panel requiere sidebar/URL
- Shadow DOM: `>>` pierce combinator confirmado
- Gap analysis: 7 archivos MISSING
- Web search rota → pivotó a `node_modules/hass-taste-test/`

---

## Bloque 15 — ❌ research-analyst (1er intento): Incidente

Agente no retornó. Sin timeout en mecanismo de subagentes. ⇒ **Fix H candidato.**

---

## Bloque 14 — ✅ Phase 1 Explore: Hallazgos críticos

- `test-ha/docker-compose.yml` NO EXISTE (Fix F urgente)
- `global.setup.ts` usa hass-taste-test (invalida Docker approach)
- CSS selectors del panel disponibles en `panel.js`
- Tensión Jest vs Playwright en `package.json`

---

## Bloque 13 — 🦠 Archivos contaminados

### P11 — global.teardown.ts: path hardcodeado (bloqueador CI)
```typescript
const rootDir = '/mnt/bunker_data/ha-ev-trip-planner/ha-ev-trip-planner'; // ❌
const rootDir = process.cwd(); // ✅
```

### global.teardown.ts: servidor HA nunca se cierra (Fix J)

---

## Bloque 12 — Interview: Análisis forense

| Capturado | NO capturado |
|---|---|
| Happy-path, POM, CI, Chromium | Shadow DOM pierce selector |
| Docker test HA ≠ localhost:8123 | baseURL dinámico / puerto efímero |
| Separate tests per action | hass-taste-test reemplaza Docker |

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1–P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Sí, en copilot-instructions y global.setup.ts |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | 🔍 A observar en Phase 3 implement |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test? | ✅ SÍ — design phase |
| P13 | ¿Mecanismo subagentes tiene timeout? | ❌ NO |
| P14 | ¿Web search funciona en el entorno? | ❌ NO — API Error 400 |
| P15 | ¿Detectará bug scope `page` en deleteTrip()? | ✅ SÍ — tarea 2.1 en tasks |
| P16 | ¿Conectará auth.setup.ts como dependency? | 🔍 A observar — ¿spec-reviewer lo detecta? |
| P17 | ¿Corregirá global.teardown.ts path hardcodeado? | ❌ NO en tasks — solo en CI failure |
| P18 | ¿Skills ausentes en tasks — problema de diseño? | 🔍 NUEVA — ver Bloque 19 |

---

## Bloque 9 — Fixes candidatos

| Fix | Dónde | Qué | Prioridad |
|---|---|---|---|
| A | `phase-rules.md` | Experimenta antes de escribir tests | Alta |
| B | `phase-rules.md` | Lee el sistema bajo test | Alta |
| C | `ha-e2e-testing.skill.md` | Auth HA: 404, sidebar nav | Media |
| D | `playwright-session.skill.md` | No IIFEs en baseURL | Alta |
| E | `playwright-best-practices` skill | `hass-taste-test`, puertos dinámicos | Alta |
| F | `ha-ev-trip-planner/copilot-instructions.md` | Corregir infra inexistente (`test-ha/docker-compose.yml`) | **Urgente** |
| G | `phase-rules.md` | Verificar que infra descrita existe antes de usarla | Alta |
| H | `phase-rules.md` | Timeout para subagentes + cómo proceder si no retornan | Media |
| I | `global.teardown.ts` | Reemplazar path hardcodeado por `process.cwd()` | Alta |
| J | `global.teardown.ts` | Llamar `.close()` en instancia HA (o matar por PID) | Alta |
| K | `playwright.config.ts` | `auth.setup.ts` debe ser dependency del proyecto Chromium | Alta |
| L | `tasks.md` template | Incluir campo `skills` por tarea con skills relevantes a consultar | Media |

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config` | Redirect a login |
| Custom Panels | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** NUNCA `page.goto('/panel-url')` directo sin auth. Navegar via sidebar tras login.

---

*Última actualización: 2026-04-03 04:22 CEST — tasks completado (18 tareas). P15 resuelta (agente detectó bug scope solo). P17 confirmada (teardown bug no en tasks). P18 nueva (skills ausentes). Fix L añadido. Spec-reviewer corriendo.*
