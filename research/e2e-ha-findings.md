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
| 14 | Phase 2 — requirements | 🔍 Pendiente | Siguiente paso |
| 15 | Phase 2 — scaffold | 🔍 Pendiente | |
| 16 | Phase 3 — implement | 🔍 Pendiente | |
| 17 | qa-engineer verifica | 🔍 Pendiente | |

---

## Bloque 16 — ✅ research-analyst (2º intento): Hallazgos

### Contexto
Web search rota (API Error 400 en los 3 intentos). El agente pivotó correctamente a leer `node_modules/hass-taste-test/` directamente — **más fiable que web search**.

### Hallazgos del research

- `hass-taste-test` autor real: **rianadon** (no twrecked — el primer intento de URL era incorrecto)
- Diseñado para **Lovelace cards** — `ev-trip-planner` es un **native panel**, las APIs de card NO aplican
- Shadow DOM: `>>` pierce combinator confirmado como patrón correcto
- `playwright.config.ts` — **NO EXISTE** en el repo (gap crítico)
- `tests/e2e/` — directorio **vacío/inexistente** (el workflow lo referencia pero no hay nada)
- `auth.setup.ts` — **NO EXISTE** — nadie automatiza el Config Flow aún

### Gap analysis confirmado

| Item | Estado |
|---|---|
| `tests/e2e/` directory | **MISSING** |
| `playwright.config.ts` | **MISSING** |
| `auth.setup.ts` | **MISSING** |
| `EVTripPlannerPage` POM | **MISSING** |
| `ConfigFlowPage` POM | **MISSING** |
| `vehicle.spec.ts` | **MISSING** |
| `trip.spec.ts` | **MISSING** |

### Preguntas abiertas (para fase requirements)
1. Nombres exactos de campos del Config Flow (`strings.json`, `config_flow.py`)
2. Texto del sidebar link tras Config Flow (¿"EV Trip Planner" o nombre del vehículo?)
3. ¿HA requiere page reload para que aparezca el panel en sidebar?
4. Entidades para entity selector en HA efímero

---

## Bloque 15 — ❌ research-analyst (1er intento): Incidente

El agente principal se quedó esperando al research-analyst que no retornó. Flujo detenido indefinidamente.

**Implicación:** El mecanismo de coordinación de subagentes no tiene timeout. ⇒ **Fix H candidato.**

---

## Bloque 14 — ✅ Phase 1 Explore: Hallazgos críticos

### Hallazgo 14.1 — ⚠️ CONTRADICCIÓN DOCKER CONFIRMADA (Fix F validado)

Existen **dos docker-compose distintos** en el repo:

| Archivo | Propósito real | Estado |
|---|---|---|
| `docker-compose.yml` (raíz) | Manual testing. Puerto **8124**. Volumenes locales hardcodeados. | Existe, pero NO es para CI |
| `test-ha/docker-compose.yml` | Lo que describe `copilot-instructions.md` para tests | **NO EXISTE** |

`copilot-instructions.md` apunta a `test-ha/docker-compose.yml` que no existe. **Fix F es urgente e independiente del experimento.**

### Hallazgo 14.2 — ✅ hass-taste-test ya lo gestiona todo (invalida el Docker approach)

`global.setup.ts` ya existe y usa `hass-taste-test` para levantar HA efímero. **Implicación crítica:** El agente propuso crear `test-ha/docker-compose.yml` en la interview, pero **el codebase ya tiene una solución mejor**.

**Pregunta forense P12 activa:** ¿El agente actualizará su plan Docker → hass-taste-test al ver `global.setup.ts`?

### Hallazgo 14.3 — ⚠️ Shadow DOM: Explore NO encontró `navigateViaSidebar`

❌ **NO hay `navigateViaSidebar` en el codebase** — no existe como función. El agente tendrá que crearla o usar `page.goto()` directo con auth correcta.

### Hallazgo 14.4 — ✅ CSS selectors del panel (disponibles)

- `.add-trip-btn`, `.trip-form-overlay`, `.trip-form-container`
- `.trips-list`, `.trip-card[data-trip-id]`, `.no-trips`
- Todos dentro del Shadow DOM de `ev-trip-planner-panel`

### Hallazgo 14.5 — Tensión Jest vs Playwright

`package.json` mezcla `jest` ^30.3.0 y `@playwright/test` ^1.58.2. Scripts de `package.json` usan jest; el workflow de GitHub Actions usa `npx playwright test`.

---

## Bloque 13 — 🦠 Archivos contaminados: global.setup.ts / global.teardown.ts

### Estado: identificados, NO borrar

Los archivos existen en el repo con bugs conocidos. Se deben **dejar para que el agente los corrija** en fase de implementación — borrarlos haría que el agente inventara algo nuevo sin aprovechar lo que ya funciona.

### P11 — global.teardown.ts: path hardcodeado (bloqueador CI)

```typescript
const rootDir = '/mnt/bunker_data/ha-ev-trip-planner/ha-ev-trip-planner';
```
Path absoluto de la máquina de Madrid hardcodeado. Rompe en GitHub Actions y cualquier otra máquina.  
**Fix:** `const rootDir = process.cwd();`

### P12 — global.teardown.ts: servidor HA nunca se cierra

`teardown` lee `server-info.json` pero **nunca llama `.close()`** en la instancia HA. El servidor efímero se queda colgado tras los tests.  
**Fix:** Guardar PID del proceso HA en `server-info.json` durante setup y matarlo por PID en teardown.

### P13 — hass-taste-test diseñado para Lovelace, no native panels

Sus APIs de card (`addCard`, etc.) no aplican a `ev-trip-planner`. Hay que navegar por sidebar/URL directamente.

### P14 — Web search del agente rota en este entorno

Los 3 intentos de `WebSearch` fallaron con `API Error 400`. El agente tiene acceso a skills y codebase local, pero **no puede hacer web research externo**. Relevante para decidir qué poner en skills vs qué confiar en web search dinámico.

---

## Bloque 12 — Interview: Análisis forense

| Capturado | NO capturado |
|---|---|
| Happy-path, POM, Docker, CI, Chromium | Shadow DOM (`pierce/` selector) |
| Docker test HA ≠ localhost:8123 | `page.goto` vs sidebar nav |
| Separate tests per action | `baseURL` dinámico / puerto efímero |
| | `hass-taste-test` reemplaza Docker |

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1-P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Confirmado: sí, en copilot-instructions y global.setup.ts |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | 🔍 A observar en Phase 3 |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota, no verificable externamente |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO — `/mnt/bunker_data/...` |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test al ver global.setup.ts? | 🔍 A observar en Phase 2 |
| P13 | ¿El mecanismo de subagentes tiene timeout? | ❌ NO — agente bloqueado indefinidamente |
| P14 | ¿Web search funciona en el entorno del agente? | ❌ NO — API Error 400 en todos los intentos |

---

## Bloque 9 — Fixes candidatos (actualizado)

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

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config` | Redirect a login |
| Custom Panels | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** NUNCA `page.goto('/panel-url')` directo sin auth. Navegar via sidebar tras login.

---

*Última actualización: 2026-04-03 03:50 CEST — research-analyst 2º intento completado (web search rota, pivotó a codebase). Hallazgos P11-P14 añadidos. Fixes I y J añadidos. Phase 2 requirements es el siguiente paso.*
