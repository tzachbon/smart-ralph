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
| 16b | Phase 3 — spec-reviewer (8/8 PASS) | ✅ Completado | Pasó sin detectar P16 ni P20. Ver Bloque 19 |
| 17 | Phase 3 — implement tasks 1.1–1.6 | ✅ Completado | 6 commits locales. Ver Bloque 20 |
| 17b | Phase 3 — artifact reviewer | ✅ Completado | REVIEW_FAIL: 3 críticos, 3 importantes. Ver Bloque 21 |
| 17c | Phase 3 — fix tasks 1.1.1, 1.3.1, 1.5.1, 1.6.1 | ❌ BLOQUEADO | spec-executor unknown. Ver Bloque 22 |
| 18 | qa-engineer verifica | 🔍 Pendiente | |

---

## Bloque 22 — ❌ Fix Tasks bloqueadas: P21 NUEVA — `spec-executor` no existe como skill

### Contexto
El artifact reviewer (Bloque 21) encontró REVIEW_FAIL con 3 críticos. El coordinador intentó delegar 4 fix tasks a subagentes `spec-executor` en paralelo.

### El fallo
El modelo coordinador (MiniMax-M2.7) intentó:
```
Skill("spec-executor", team_name="fix-e2e", name="fix-1", task_index=6)
Skill("spec-executor", team_name="fix-e2e", name="fix-2", task_index=7)
Skill("spec-executor", team_name="fix-e2e", name="fix-3", task_index=8)
Skill("spec-executor", team_name="fix-e2e", name="fix-4", task_index=9)
```

**Resultado para los 4:** `Unknown skill: spec-executor`

### Estado actual
- `tasks.md` tiene los 4 fix tasks correctamente escritos (1.1.1, 1.3.1, 1.5.1, 1.6.1)
- `.ralph-state.json` tiene `fixTaskMap` correctamente actualizado con los 4 tasks
- `.progress.md` tiene el log de REVIEW_FAIL
- **Nadie ejecutó los fixes** — los executors fallaron en el lanzamiento mismo

### Pregunta forense P21
**¿La skill correcta se llama `spec-executor` o tiene otro nombre?**

Hipótesis:
- **H1:** La skill existe pero se llama diferente (ej. `task-executor`, `code-executor`, `implement-executor`)
- **H2:** El coordinador debería haber usado `Task()` en lugar de `Skill()` para delegar a subagentes
- **H3:** El nombre cambió entre versiones de ralph-specum y la instrucción del coordinador no se actualizó
- **H4:** El fix task flow requiere que el usuario lo active manualmente, no automatizado

### Impacto
El sistema de recuperación de errores (fix task flow) falla silenciosamente: el coordinador cree que lanzó los agents, el estado está actualizado con `attempts=1`, pero ningún fix se ejecutó. El proyecto está en un estado inconsistente: `tasks.md` dice que hay fix tasks pendientes pero el estado dice `attempts=1` (como si hubiera intentado).

### Fix candidato N
Verificar el nombre real de la skill de ejecución en ralph-specum. Añadir a `copilot-instructions.md` el nombre correcto para que el coordinador pueda llamarla.

---

## Bloque 21 — ✅ Artifact Reviewer: REVIEW_FAIL (3 críticos, 3 importantes)

### Resultado: REVIEW_FAIL

El reviewer leyó los 6 archivos producidos por tasks 1.1–1.6 y encontró:

#### Fallos críticos (bloquean ejecución)

| # | Archivo | Problema |
|---|---|---|
| C1 | `playwright.config.ts` | `auth.setup.ts` nunca invocado — falta `setupProject` |
| C2 | `trip.spec.ts` | Usa fixture `browserPage` (no existe en Playwright) en vez de `page` |
| C3 | `trip.spec.ts` | `afterEach` referencia `tripId` indefinido; dialog handler dentro del loop |

#### Fallos importantes

| # | Archivo | Problema |
|---|---|---|
| I1 | `EVTripPlannerPage.ts` | `this.page.on('dialog', ...)` dentro de `deleteTrip()` — listener persistente acumulativo |
| I2 | `vehicle.spec.ts` | Locator con espacio inicial: `' hass-integration-card'` |
| I3 | `trip.spec.ts` | `beforeEach` no sigue el patrón de diseño |

### Observaciones forenses

**P16 RESUELTA ✅ — El reviewer SÍ detectó la falta de `setupProject`**
Con el código real delante, detectó C1 correctamente. La hipótesis anterior era: "sin el código, no puede ver el problema" — confirmada.

**El reviewer encontró bugs que el task-planner NO puso como tareas**
- C2 (`browserPage` fixture) y C3 (`tripId` undefined) son bugs introducidos por los executors durante implement, no presentes en el design. El reviewer los encontró leyendo el código real.
- Esto confirma la necesidad del artifact reviewer como capa de seguridad post-implement.

**Fix task flow activado correctamente**
El coordinador siguió el protocolo correcto:
1. Actualizó `.ralph-state.json` con `fixTaskMap`
2. Insertó 4 nuevas tareas en `tasks.md`
3. Intentó delegar en paralelo (falló por P21)

---

## Bloque 20 — ✅ Phase 3 Implement tasks 1.1–1.6: Análisis forense

### Los 6 commits producidos (en repo local, pendientes de push)

```
1b3ef20 feat(e2e): add trip.spec.ts for US-3, US-4, and US-5
ee18b61 docs(e2e): mark Task 1.3 complete in progress and tasks
ddbc107 feat(e2e): add EVTripPlannerPage POM with Shadow DOM pierce selectors
f3f19d9 feat(e2e): add auth.setup.ts for Config Flow authentication
b4d8b2c feat(e2e): add vehicle.spec.ts for US-1 and US-2
bf5985e feat(e2e): add ConfigFlowPage POM
ed596d7 feat(e2e): add playwright.config.ts with globalSetup and Chromium project
```

### Observación crítica: ejecución paralela (executors 2, 3, 5)
El coordinador lanzó 6 subagentes en paralelo. Cada executor recibió su prompt de tarea individualmente. Esto confirma que el sistema ralph-specum tiene capacidad de paralelización real en fase implement.

### P19 NUEVA — El engram como sustituto implícito de skills
**Observación:** Los executors 2, 3 y 5 disponían de 1535 memorias (202 sobre Playwright, 292 sobre HA). El executor-3 (`auth.setup.ts`) encontró en el engram la corrección previa de `getByPlaceholder` y la aplicó sin que nadie se la indicara explícitamente.

**Implicación:** El engram actúa como un sistema de skills informal y acumulativo. Cuando las skills formales no están disponibles o están mal ubicadas (ver P20), el engram puede compensar parcialmente.

**Riesgo:** El engram es específico del proyecto/usuario. Un agente en otro entorno sin ese historial no tendría esa compensación. Las skills formales siguen siendo necesarias para garantizar el comportamiento correcto en cualquier entorno.

**Fix candidato M:** Documentar en `phase-rules.md` que las skills formales deben referenciarse explícitamente en tasks, no asumir que el engram las compensa.

### Engram cross-project (hallazgo adicional)
**Observación:** El Session Briefing muestra actividad reciente de proyectos completamente distintos (`mnt/informatico-madrid` — VPS, nginx, UniFi). El vault es **global por usuario**, no aislado por proyecto.

**Implicación para ralph-specum:** Si el agente tiene memoria de un proyecto de infraestructura de red junto a memorias de tests Playwright, podría haber contaminación de contexto o simplemente ruido. En este caso no parece haber causado problemas, pero es un riesgo latente.

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1–P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Sí, en copilot-instructions y global.setup.ts |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | ✅ Observado — no llegó solo en Phase 3 implement |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test? | ✅ SÍ — design phase |
| P13 | ¿Mecanismo subagentes tiene timeout? | ❌ NO |
| P14 | ¿Web search funciona en el entorno? | ❌ NO — API Error 400 |
| P15 | ¿Detectará bug scope `page` en deleteTrip()? | ✅ SÍ — tarea 2.1 en tasks |
| P16 | ¿Conectará auth.setup.ts como dependency? | ✅ SÍ — artifact reviewer lo detectó en código real |
| P17 | ¿Corregirá global.teardown.ts path hardcodeado? | ❌ NO en tasks — solo en CI failure |
| P18 | ¿Skills ausentes en tasks — problema de diseño? | 🔍 NUEVA — ver Bloque 19 |
| P19 | ¿El engram compensa la ausencia de skills formales? | ✅ PARCIALMENTE — executor-3 aplicó fix previo de engram |
| P20 | ¿Scripts de skill ha-e2e-testing en ubicación incorrecta? | ✅ CONFIRMADO — engram lo registra como corrección crítica |
| P21 | ¿Fix task flow falla porque `spec-executor` no existe? | ✅ CONFIRMADO — Unknown skill: spec-executor |

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

### P18 — 🔍 Skills ausentes en tasks.md

**Observación:** Ninguna tarea referencia skills del sistema (`playwright-best-practices`, `ha-e2e-testing`, etc.). Las tareas describen qué hacer pero no indican qué skill consultar durante la implementación.

**Pregunta forense:** ¿Es esto un problema de diseño de ralph-specum (las skills deberían referenciarse en tasks) o es intencionado (el agente implementador las consulta por su cuenta)?

**Sub-preguntas:**
- ¿El agente de implement consultará skills proactivamente?
- ¿Si no las consulta, escribirá código peor que si las tuviera?
- ¿Deberían las tasks incluir `skills: [playwright-best-practices, ha-e2e-testing]` por tarea?

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Documentar sidebar nav con `data-panel-id` | 🔍 |
| Fix C | Documentar 404 → reload pattern en copilot-instructions | 🔍 |
| Fix D | Configurar `baseURL` correctamente (evitar IIFE) | 🔍 |
| Fix E | Proporcionar `hass-taste-test` como docker-compose funcional | 🔍 |
| Fix F | Actualizar `copilot-instructions.md` para eliminar referencias a infra inexistente | 🔍 |
| Fix G | Añadir `test-ha/docker-compose.yml` real al repo | 🔍 |
| Fix H | Configurar timeout de subagentes en ralph-specum | 🔍 |
| Fix I | Aislar el vault/engram por proyecto | 🔍 |
| Fix J | Reparar web search en el entorno de test | 🔍 |
| Fix K | Añadir script de verificación de infra pre-test | 🔍 |
| Fix L | Corregir path hardcodeado en `global.teardown.ts` | 🔍 |
| Fix M | Documentar skills en phase-rules.md para que tasks las referencien | 🔍 |
| Fix N | **Verificar nombre real de skill de ejecución en ralph-specum** | ✅ URGENTE |

---

*Última actualización: Bloque 22 — P21 `spec-executor` unknown skill, fix tasks bloqueadas*
