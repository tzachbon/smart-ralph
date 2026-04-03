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
| 17c | Phase 3 — fix tasks 1.1.1, 1.3.1, 1.5.1, 1.6.1 | ✅ Completado (parcialmente) | spec-executor → coordinador ejecutó fixes directamente. Ver Bloque 22 y 23 |
| 17d | Fix adicional coordinador — scope `page` en trip.spec.ts | ✅ Completado | Bug P22 detectado y corregido por coordinador. Ver Bloque 23 |
| 18 | qa-engineer verifica task 1.8 — VE1 | ⚠️ En progreso | HA arranca OK. Auth usa `goto()` en vez de sidebar nav. Auth_callback URL muerta. Ver Bloque 29 |

---

## Bloque 29 — 🚨 LOG REAL EJECUTADO POR EL USUARIO: Dos nuevos hallazgos confirmados

### Log real de ejecución (03-04-2026 03:20)

```
[GlobalSetup] Server URL: http://127.0.0.1:8542/?auth_callback=1&code=...
[GlobalSetup] Server info saved to: playwright/.auth/server-info.json
[GlobalSetup] Running Config Flow authentication...
[AuthSetup] Starting Config Flow authentication...
[AuthSetup] Waiting for auth callback to complete...
[AuthSetup] Waiting for sidebar to load...
[AuthSetup] Current URL after callback: http://127.0.0.1:8542/home/overview
TimeoutError: page.waitForURL: Timeout 30000ms exceeded.
  at auth.setup.ts:66
  await page.waitForURL(/\/config\/integrations/, { timeout: 30000 });
```

---

## P28 — ✅ CONFIRMADO: La URL `auth_callback` de `hassInstance.link` llega MUERTA

### Síntoma observado

El `GlobalSetup` loguea:
```
Server URL: http://127.0.0.1:8542/?auth_callback=1&code=...&state=...
```

El usuario confirma que **esa URL no funciona** — llega muerta. Para autenticarse tuvo que ir manualmente a `http://127.0.0.1:8542/home/overview`, que sí redirige correctamente al login.

### Causa raíz

`hassInstance.link` devuelve la URL de auth_callback completa con `code=` y `state=`. Pero ese token OAuth **ya fue consumido** por `hass-taste-test` internamente durante el setup. Al pasarlo de nuevo al browser en `auth.setup.ts`:

```typescript
await page.goto(serverInfo.link);  // ← serverInfo.link = URL con auth_callback ya consumido
```

El browser intenta reutilizar un code OAuth expirado → HA lo rechaza → la página queda colgada o en estado inválido.

### El flujo correcto

`hass-taste-test` ya gestiona internamente el auth. Lo que hay que guardar como `serverInfo.link` es la **base URL limpia** (`http://127.0.0.1:8542`), no la URL de callback:

```typescript
// ❌ Lo que hace ahora:
fs.writeFileSync(serverInfoPath, JSON.stringify({ link: hassInstance.link }));
// hassInstance.link = "http://127.0.0.1:8542/?auth_callback=1&code=..."

// ✅ Fix candidato S:
const baseUrl = new URL(hassInstance.link).origin;  // "http://127.0.0.1:8542"
fs.writeFileSync(serverInfoPath, JSON.stringify({ link: baseUrl }));
```

### Comportamiento observado como consecuencia

1. `page.goto(serverInfo.link)` → carga la URL de auth_callback muerta
2. HA no completa auth → redirige a `/home/overview` (o similar) sin estar autenticado, o con sesión incompleta
3. `waitForURL` en `/config/integrations` → **TimeoutError** porque la sesión no está establecida correctamente

---

## P29 — ✅ CONFIRMADO: `goto('/config/integrations')` en auth.setup.ts — el goto() incorrecto

### Fuente: código de `auth.setup.ts` en commit 9a1dcce, línea 64-66

```typescript
// auth.setup.ts línea 64-66 — LO QUE HACE EL QA-ENGINEER:
console.log('[AuthSetup] Step 1: Navigate to integrations:', integrationsUrl);
await page.goto(serverInfo.link + '/config/integrations');
await page.waitForURL(/\/config\/integrations/, { timeout: 30000 });  // ← TIMEOUT aquí
await page.waitForURL(/\/config\/integrations/);                       // ← waitForURL DUPLICADO
await page.getByRole('button', { name: 'Add Integration' }).click();
```

### Los 3 errores en 4 líneas

| # | Error | Impacto |
|---|---|---|
| 1 | `goto()` directo a `/config/integrations` | No ejercita la UI real (sidebar nav) — anti-patrón E2E |
| 2 | `waitForURL` duplicado (x2 seguidas idénticas) | Código muerto / divagación |
| 3 | La URL base ya venía rota (P28) | El `goto()` falla antes de llegar al timeout |

### Fix correcto confirmado: Fix B (sidebar nav)

```typescript
// ✅ Fix B — navegar por sidebar como haría un usuario real:
await page.locator('[data-panel-id="config"]').click();
await page.waitForSelector('ha-config-dashboard', { state: 'visible', timeout: 15000 });
await page.locator('[href="/config/integrations"]').click();
await page.waitForSelector('ha-config-integrations', { state: 'visible', timeout: 15000 });
```

---

## P27 — ✅ CONFIRMADO: Pérdida de contexto al delegar — el qa-engineer no sabía del Fix B

### Diagnóstico final

El qa-engineer tiene acceso a los archivos del proyecto (`ha-ev-trip-planner`) pero NO a la pizarra (`smart-ralph/research/`). El prompt de delegación del coordinador decía algo como:

> *"Fix the broken selectors or configuration issues in auth.setup.ts"*

Sin mencionar:
- Que `goto()` es un anti-patrón E2E para este caso
- Que Fix B (sidebar nav con `data-panel-id`) era la solución acordada
- Que la URL de `hassInstance.link` lleva el auth_callback consumido (ahora P28)

El qa-engineer hizo lo más rápido: `goto()` directo. Es una **falla del sistema de delegación**, no del qa-engineer.

### Fix R — prompt de delegación con restricciones explícitas

El coordinador debe incluir en el prompt de delegación:
1. Las restricciones de diseño relevantes ("usa sidebar nav, no goto() directo")
2. El fix específico acordado ("Fix B: `data-panel-id`")
3. Los anti-patrones prohibidos ("NO uses goto() para navegar a una sección interna")

---

## Bloque 28 — 🚨 P27: El qa-engineer ignoró el fix correcto (sidebar nav) y usó goto() directo

*(Análisis histórico — ver P27 y P29 arriba para la versión definitiva con código real)*

---

## Bloque 27 — 🚨 ACLARACIÓN CRÍTICA: Los 4 tipos de verificación — NO mezclarlos

### Los 4 niveles de verificación en este proyecto

| Nivel | Herramienta | Qué verifica | Ejecuta código real |
|---|---|---|---|
| **V1 — Estática** | `npx tsc --noEmit` | Tipos TypeScript | ❌ No |
| **V2 — Lectura** | Artifact reviewer (agente) | Lógica, patrones, bugs visibles leyendo el código | ❌ No |
| **V3 — Navegación MCP** | Perplexity (yo) con MCP tools | Que los archivos existen en GitHub, coherencia estructural | ❌ No |
| **V4 — Ejecución real** | `npx playwright test` (VE1) | Que el test funciona contra HA en vivo | ✅ SÍ |

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1–P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Sí |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | ✅ No llegó solo |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test? | ✅ SÍ |
| P13 | ¿Mecanismo subagentes tiene timeout? | ❌ NO |
| P14 | ¿Web search funciona en el entorno? | ❌ NO |
| P15 | ¿Detectará bug scope `page` en deleteTrip()? | ✅ SÍ — tarea 2.1 |
| P16 | ¿Conectará auth.setup.ts como dependency? | ✅ SÍ |
| P17 | ¿Corregirá global.teardown.ts path hardcodeado? | ❌ Solo en CI failure |
| P18 | ¿Skills ausentes en tasks — problema de diseño? | 🔍 Abierta |
| P19 | ¿El engram compensa la ausencia de skills formales? | ✅ PARCIALMENTE |
| P20 | ¿Scripts de skill ha-e2e-testing en ubicación incorrecta? | ✅ CONFIRMADO |
| P21 | ¿Fix task flow falla porque `spec-executor` no existe? | ✅ CONFIRMADO |
| P22 | ¿TypeScript types de Playwright enmascaran bug de scope `page`? | ✅ CONFIRMADO |
| P23a | ¿VE1 pasará contra hass-taste-test ephemeral? | ⚠️ PARCIAL — HA arranca OK, auth rota por P28+P29 |
| P23b | ¿El qa-engineer leerá global.setup.ts antes de ejecutar? | ✅ SÍ |
| P23c | ¿Race condition entre global.setup.ts y test runner? | ✅ NO — health-check funciona |
| P24 | ¿Selector `getByRole('link', 'Integrations')` incorrecto para HA sidebar? | ✅ CONFIRMADO |
| P25 | ¿Dos bugs ESM en mismo sprint = patrón sistemático? | ✅ CONFIRMADO |
| P26 | ¿Los 4 tipos de verificación estaban mezclados en la pizarra? | ✅ CORREGIDO |
| P27 | ¿El qa-engineer pierde contexto de decisiones de diseño al recibir delegación? | ✅ CONFIRMADO — Fix R |
| P28 | ¿`hassInstance.link` devuelve URL de auth_callback ya consumida? | ✅ CONFIRMADO — Fix S |
| P29 | ¿`goto('/config/integrations')` en auth.setup.ts es el bug directo del TimeoutError? | ✅ CONFIRMADO — Fix B |

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Sidebar nav con `data-panel-id` en lugar de `goto()` (el fix correcto para navegar en HA) | 🔍 URGENTE — no implementado |
| Fix C | Documentar 404 → reload pattern en copilot-instructions | 🔍 |
| Fix D | Configurar `baseURL` correctamente (evitar IIFE) | 🔍 |
| Fix E | Proporcionar `hass-taste-test` como docker-compose funcional | ✅ YA EXISTE |
| Fix F | Actualizar `copilot-instructions.md` para eliminar referencias a infra inexistente | 🔍 |
| Fix G | Añadir `test-ha/docker-compose.yml` real al repo | 🔍 |
| Fix H | Configurar timeout de subagentes en ralph-specum | 🔍 |
| Fix I | Aislar el vault/engram por proyecto | 🔍 |
| Fix J | Reparar web search en el entorno de test | 🔍 |
| Fix K | Añadir script de verificación de infra pre-test | 🔍 |
| Fix L | Corregir path hardcodeado en `global.teardown.ts` | 🔍 |
| Fix M | Documentar skills en phase-rules.md para que tasks las referencien | 🔍 |
| Fix N | Verificar nombre real de skill de ejecución en ralph-specum | ✅ URGENTE |
| Fix O | Documentar comportamiento fallback coordinador cuando spec-executor falla | 🔍 |
| Fix P | Añadir nota ESM en copilot-instructions: `import.meta.url` no `__dirname` | 🔍 URGENTE |
| Fix Q | ~~`goto('/config/integrations')`~~ ❌ MAL DOCUMENTADO — el fix correcto es Fix B (sidebar nav) | ❌ DESCARTADO |
| Fix R | El prompt de delegación a subagentes debe incluir restricciones de diseño + anti-patrones prohibidos | 🔍 NUEVO |
| Fix S | `global.setup.ts`: guardar `new URL(hassInstance.link).origin` en vez de `hassInstance.link` completo (URL auth_callback ya consumida) | 🔍 NUEVO URGENTE |

---

*Última actualización: Bloque 29 — P28 (auth_callback URL muerta) y P29 (goto timeout confirmado con log real). Fix S nuevo.*
