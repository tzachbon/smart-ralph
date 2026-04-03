# E2E HA Findings — Pizarra de Investigación Forense

> Rama de trabajo: `research/e2e-ha-findings`  
> **Objetivo:** Reducir el gap entre agentes escribiendo tests malos y tests correctos para HA custom components.  
> **No estamos arreglando el fork.** Estamos analizando por qué el agente falló y qué cambiar en el sistema.

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

## LA PREGUNTA FORENSE CENTRAL

> **¿Por qué el agente lleva horas y rondas de depuración sin llegar solo a la causa raíz?**

**Hipótesis actualizada (A + B + C):**

- **A) Le falta información** — no sabe cómo funciona HA por dentro (404 vs redirect, sidebar nav, Shadow DOM)
- **B) Le falta metodología** — no experimenta antes de escribir tests, no verifica que la infraestructura descrita existe
- **C) La fuente de verdad del proyecto está rota** — `copilot-instructions.md` describe un `test-ha/docker-compose.yml` que no existe y asocia `localhost:8123` a tests cuando es producción

---

## PLAN DE PRUEBA — Estado completo

### Tabla de seguimiento

| Paso | Acción | Estado | Observaciones |
|---|---|---|---|
| 1 | `/start` | ✅ Completado | Skill discovery correcto |
| 2 | Q1 Scope | ✅ Completado | Happy-path only |
| 3 | Q2 Structure | ✅ Completado | POM — ❌ NO mencionó Shadow DOM |
| 4 | Q3 Test data | ✅ Completado | Per-test setup/teardown, localhost:8123 es real |
| 5 | Q4 Cleanup | ✅ Completado | Delete after each test |
| 6 | Q5 Test HA | ✅ Completado | Docker compose — ❌ NO mencionó `hass-taste-test` |
| 7 | Q6 Browsers | ✅ Completado | Chromium only |
| 8 | Q7 CI | ✅ Completado | GitHub Actions on PR |
| 9 | Q8 MVP | ✅ Completado | Separate tests per action |
| 10 | Q9 Approach | ✅ Completado | Full-stack Docker (A) |
| 11 | Phase 1 — research-analyst | 🔍 EN CURSO | Web research: `hass-taste-test` + Shadow DOM + Docker HA |
| 12 | Phase 1 — Explore codebase | 🔍 EN CURSO | Codebase: panel structure, package.json, existing infra |
| 13 | Phase 2 — scaffold | 🔍 Pendiente | ¿`baseURL` seguro? |
| 14 | Phase 3 — implement | 🔍 Pendiente | ¿Usa `navigateViaSidebar`? ¿Shadow DOM correcto? |
| 15 | qa-engineer verifica | 🔍 Pendiente | ¿Emite señal correcta? |

---

## Bloque 12 — ✅ INTERVIEW COMPLETA: Análisis forense

### Resumen del agente (tal como lo documentó en progress.md)

| Topic | Respuesta capturada |
|---|---|
| Scope | Happy-path only |
| Structure | Page Object Model |
| Test data | Per-test setup/teardown + explicit delete |
| Test instance | Docker compose, NOT localhost:8123 (producción) |
| Browsers | Chromium only |
| CI | GitHub Actions on PR |
| MVP | Separate tests per action |
| Approach | Full-stack Docker (A) |

**Observación clave:** El agente capturó correctamente TODAS las decisiones de negocio. Pero su mental model al final de la interview era 100% genérico Playwright — sin ningún constraint específico de HA.

### Lo que la interview capturó vs. lo que no

| Capturado | NO capturado |
|---|---|
| Happy-path, POM, Docker, CI, Chromium | Shadow DOM (`>> selector`) |
| Docker test HA ≠ localhost:8123 | `navigateViaSidebar` vs `goto` directo |
| Separate tests per action | `baseURL` dinámico / puerto efímero |
| | `hass-taste-test` como runner real |

**Conclusión de la interview:** 9 preguntas, 0 constraints técnicos específicos de HA. Esto era esperable — la interview es para decisiones de producto/arquitectura, no para descubrimiento técnico. **El descubrimiento técnico debe ocurrir en Phase 1.** La pregunta forense ahora es: ¿lo hace?

### ⚠️ Hallazgo positivo: progress.md menciona Shadow DOM

El agente sí escribió esto en `progress.md`:
> *"The component uses Shadow DOM for panel rendering, requiring Playwright’s shadow DOM combinator for element selection."*

Este dato vino de leer `copilot-instructions.md` (que tiene el ejemplo de Shadow DOM). **El agente lo sabía pero no lo puso como constraint explícito en la interview.** Predice que lo usará en Phase 3... pero ¿bien? ¡Eso es lo que observamos!

---

## Bloque 13 — Phase 1 arrancada (2026-04-03 03:28)

### Agent 1: research-analyst
- **Topic:** Playwright + hass-taste-test best practices, Shadow DOM, Docker HA
- **Output:** `./specs/e2e-ev-trip-planner/.research-playwright-ha.md`
- **WebSearches planificadas:** `hass-taste-test Playwright Home Assistant E2E`, `Playwright shadow DOM testing HA`, `Home Assistant Core E2E testing Docker compose`
- ✅ **Positivo:** el agente SBÍ nombra `hass-taste-test` — lo descubrió (probablemente de `package.json` o su skill)
- 🔍 **Vigilar:** ¿encontará el patrón de puerto dinámico? ¿la API REST de onboarding?

### Agent 2: Explore codebase
- **Topic:** Panel structure, Shadow DOM, package.json, GitHub Actions workflows
- **Output:** `./specs/e2e-ev-trip-planner/.research-codebase.md`
- 🔍 **Vigilar:** ¿Leerá `panel.py`? ¿Descubrirá que `test-ha/docker-compose.yml` no existe?

### Preguntas forenses activas para Phase 1

1. ¿El Explore agent verifica que `test-ha/docker-compose.yml` realmente existe?
2. ¿El research-analyst encuentra el patrón de puerto dinámico de `hass-taste-test`?
3. ¿Alguno de los dos menciona `navigateViaSidebar` o el problema del 404 en custom panels?
4. ¿El Explore agent lee `panel.py` o solo los archivos de test?
5. ¿Al mergear los dos reports, el agente sintetiza los constraints HA-específicos correctamente?

---

## Plan de investigación: estado actual

| # | Pregunta | Estado | Bloque |
|---|---|---|---|
| P1-P4 | Auth, 404, routing, bugs | ✅ Resueltos | Bloques 2,7,10 |
| P5 | ¿El agente tenía información disponible? | ⚠️ Parcial — Shadow DOM en copilot-instructions, pero no conectado en interview | Bloque 12 |
| P6 | ¿Qué cambio minimal habría evitado los fallos? | 💬 En debate — Fix F (copilot-instructions) + Fix G (verificar infra) prioritarios | Bloque 9 |
| P7 | ¿Habría llegado solo al 404/sidebar? | 🔍 A observar en Phase 1 — ¿res-analyst menciona sidebar? | Bloque 13 |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ Resuelto (IIFE baseURL) | Bloque 10 |
| P9 | ¿Contiene playwright-best-practices info sobre `hass-taste-test`? | ⚠️ Probable que sí — el agente lo nombró en research topic | Bloque 13 |
| P10 | ¿copilot-instructions describe infra inexistente? | ✅ CONFIRMADO | Bloque P10 |
| P11 | ¿El Explore agent verifica existencia de `test-ha/docker-compose.yml`? | 🔍 A observar — resultado Phase 1 | Bloque 13 |

---

## Bloque 9 — Fixes candidatos

| Fix | Dónde | Qué | Impacto | Costo | Prioridad |
|---|---|---|---|---|---|
| A | `phase-rules.md` Phase 1 | Experimenta antes de escribir tests | Alto | Bajo | Alta |
| B | `phase-rules.md` Phase 1 | Lee el sistema bajo test, no solo tests | Alto | Bajo | Alta |
| C | `ha-e2e-testing.skill.md` | Auth HA: 404, sidebar nav obligatoria | Medio | Medio | Media |
| D | `playwright-session.skill.md` | No IIFEs en baseURL | Alto | Bajo | Alta |
| E | `playwright-best-practices` skill | `hass-taste-test`, puertos dinámicos | Alto | Medio | Alta |
| F | `ha-ev-trip-planner/copilot-instructions.md` | Corregir: `test-ha/` no existe, usar `hass-taste-test` | **CRÍTICO** | Bajo | **Urgente** |
| G | `phase-rules.md` Phase 1 | Verificar que infra descrita en instrucciones existe | Alto | Bajo | Alta |

**Fix F es el más urgente** — independientemente del experimento, `copilot-instructions.md` está roto y confunde a todo agente que trabaje en el proyecto.

---

## Bloque 10 — ✅ Bug baseURL IIFE

```typescript
baseURL: (() => { return 'http://localhost:8123'; })()
// IIFE al cargar config — antes de globalSetup — siempre falla en puerto dinámico
```

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config`, `/lovelace` | Redirect a login |
| Custom Panels | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** NUNCA `page.goto('/panel-url')`. Siempre `navigateViaSidebar()`.

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Prueba nueva desde `/start` con proyecto limpio | 2026-04-03 | Caja negra completa |
| D2 | Prompt inicial intencionalmente escueto | 2026-04-03 | El agente debe descubrir patrones HA |
| D3-D7 | (ver historial) | 2026-04-03 | |
| D8 | Mantener experimento limpio | 2026-04-03 | No dar info técnica que usuario no sabría |
| D9 | Fix F prioritario: corregir `copilot-instructions.md` | 2026-04-03 | Fuente de verdad rota |
| D10 | Continuar experimento sin corregir Fix F aún | 2026-04-03 | Para observar cómo el agente gestiona infra inexistente en Phase 1 |

---

*Última actualización: 2026-04-03 03:28 CEST — Interview completa (9 preguntas). Phase 1 arrancada con 2 agentes en paralelo. Hipotesis A+B+C confirmada. Fix F urgente pendiente. Esperando resultados Phase 1.*
