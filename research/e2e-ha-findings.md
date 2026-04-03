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


 MEGA PLAN FORENSE — smart-ralph × ev-trip-planner
## Instrucciones para Copilot Autónomo

> **Branch de trabajo**: `research/e2e-ha-findings`  
> **Ejecutar en**: fork `informatico-madrid/smart-ralph`  
> **Objetivo**: Corregir todos los problemas encontrados en la investigación forense E2E, aplicando TDD de razonamiento IA (prueba que falla → arreglo → prueba que pasa → revisión sistémica).  
> **Estilo de trabajo**: AUTÓNOMO — no pedir confirmación. Si encuentras ambigüedad, documenta en `.progress.md` y elige la opción más conservadora.

---

## 🗺️ MAPA DE ARCHIVOS × PROBLEMAS

### Repositorio `smart-ralph` (el "cerebro" — prompts, skills, agentes)

```
smart-ralph/
├── .github/
│   └── copilot-instructions.md          ← P10 ❌ Describe infra inexistente (test-ha/docker-compose.yml)
│                                            P10 ❌ localhost:8123 referenciado como instancia de test
│                                            Fix F + Fix P + Fix G
│
├── plugins/ralph-specum/
│   ├── commands/
│   │   ├── start.md                     ← P21 ⚠️  Referencia "spec-executor" que no existe como agente real
│   │   │                                   Fix N + Fix O
│   │   ├── implement.md                 ← P27 ❌ No incluye contexto de decisiones de diseño al delegar
│   │   │                                   Fix R — prompts de delegación sin restricciones
│   │   ├── tasks.md                     ← P18 ❌ No referencia skills e2e en las tareas generadas
│   │   │                                   Fix M — tasks deben referenciar skills por nombre
│   │   └── [otros comandos]             ← No tienen problemas directos detectados
│   │
│   └── skills/
│       ├── e2e/
│       │   ├── playwright-env.skill.md  ← P20 ❌ Scripts de setup (global.setup.ts template)
│       │   │                               mencionan hass-taste-test pero sin corrección del
│       │   │                               auth_callback bug (P28) ni sidebar nav (Fix B)
│       │   │                               Fix S + Fix B deben reflejarse aquí
│       │   │
│       │   ├── playwright-session.skill.md ← P29 ❌ No advierte contra goto() para navegación interna HA
│       │   │                                   Fix B debe documentarse como patrón obligatorio
│       │   │
│       │   ├── mcp-playwright.skill.md  ← P24 ❌ No documenta selectores reales del sidebar HA
│       │   │                               (data-panel-id) ni el patrón waitForSelector correcto
│       │   │                               Fix B
│       │   │
│       │   ├── selector-map.skill.md    ← P24 ⚠️  Genérico — no menciona HA sidebar specifics
│       │   │                               homeassistant-selector-map.skill.md sí los tiene,
│       │   │                               pero no hay cross-reference desde playwright-session
│       │   │
│       │   ├── ui-map-init.skill.md     ← Sin problemas directos detectados
│       │   │
│       │   └── examples/
│       │       └── homeassistant-selector-map.skill.md ← ✅ Bien — tiene data-panel-id y anti-patrones
│       │                                                    PERO no está referenciado desde
│       │                                                    playwright-env ni playwright-session
│       │                                                    Fix: añadir cross-reference
│       │
│       ├── spec-workflow/
│       │   ├── SKILL.md                 ← P18 ❌ No menciona qué skills deben cargarse
│       │   │                               automáticamente en specs de tipo E2E/fullstack
│       │   │                               Fix M
│       │   └── references/
│       │       └── phase-transitions.md ← P13 ⚠️  No documenta timeout de subagentes ni fallback
│       │                                   Fix H
│       │
│       ├── reality-verification/
│       │   └── SKILL.md                 ← P26 ✅ YA CORREGIDO — 4 niveles de verificación
│       │                                   PERO: no menciona que VE1 con hass-taste-test
│       │                                   requiere Fix S (URL base limpia)
│       │                                   Fix: añadir nota sobre hassInstance.link
│       │
│       └── smart-ralph/
│           └── SKILL.md                 ← P27 ❌ No especifica qué incluir en prompt de delegación
│                                           Fix R — añadir sección "delegation contract"
│
└── research/
    └── e2e-ha-findings.md               ← Esta pizarra (fuente de verdad)
```

### Repositorio `ev-trip-planner` / fork `ha-ev-trip-planner` (el proyecto bajo test)

```
ha-ev-trip-planner/
├── playwright/
│   ├── global.setup.ts                  ← P28 ❌ Guarda hassInstance.link (URL con auth_callback
│   │                                       ya consumido) en vez de .origin
│   │                                       Fix S — URGENTE
│   │
│   ├── auth.setup.ts                    ← P29 ❌ goto() directo a /config/integrations
│   │   (commit 9a1dcce)                    en vez de sidebar nav — TimeoutError confirmado
│   │   línea 64-66                         waitForURL duplicado (código muerto)
│   │                                       Fix B — URGENTE
│   │
│   └── global.teardown.ts               ← P11 ❌ Path hardcodeado absoluto
│                                           Fix L
│
├── tests/
│   └── trip.spec.ts                     ← P22 ❌ Bug scope `page` en deleteTrip()
│   (commit fase implement)                 Variable `page` usada fuera del scope del test
│                                           TypeScript no lo detecta por tipos de Playwright
│                                           Fix: ya aplicado por coordinador en Bloque 23
│                                           VERIFICAR que el fix fue correcto
│
├── playwright.config.ts                 ← P8 ❌ baseURL con IIFE pattern (ESM anti-patrón)
│                                           P25 ❌ Segundo bug ESM en mismo sprint — patrón sistemático
│                                           Fix D — baseURL debe ser string directo, no IIFE
│
└── .github/
    └── copilot-instructions.md          ← P10 ❌ MISMO PROBLEMA — copia del smart-ralph
                                            o auto-generado con referencias a infra inexistente
                                            Fix F — sincronizar con correcciones de smart-ralph
```

---

## 🎯 PLAN DE EJECUCIÓN — 10 Sprints con TDD de Razonamiento

Cada sprint sigue este protocolo:
1. **STRESS TEST** — crea un test que falla por el problema (archivo `research/stress-tests/S{N}.md`)
2. **FIX** — aplica la corrección
3. **VERIFY** — ejecuta el stress test y confirma que pasa
4. **SWEEP** — busca en todo el repo otros lugares donde el mismo problema puede existir
5. **COMMIT** — `fix(sprint-N): descripción`

---

### SPRINT 1 — Fix S: `hassInstance.link` devuelve URL con auth_callback consumido
**Severidad**: 🔴 CRÍTICA — bloquea todos los tests E2E  
**Archivos a modificar**: `ha-ev-trip-planner/playwright/global.setup.ts`

#### STRESS TEST S1
```
Archivo: research/stress-tests/S1-auth-callback-url.md

Prueba que FALLA (estado actual):
- Leer global.setup.ts
- Verificar que la URL guardada en server-info.json contiene "auth_callback" o "code="
- Comando de verificación:
  grep -n "hassInstance.link" playwright/global.setup.ts
  # Debe devolver la línea con el link SIN transformar = FALLO confirmado

Evidencia del fallo:
  Log real: "Server URL: http://127.0.0.1:8542/?auth_callback=1&code=...&state=..."
  → La URL completa está siendo guardada como serverInfo.link
  → Cuando auth.setup.ts hace page.goto(serverInfo.link), el code ya fue consumido
```

#### FIX S1
```typescript
// playwright/global.setup.ts
// ❌ ANTES:
fs.writeFileSync(serverInfoPath, JSON.stringify({ link: hassInstance.link }));

// ✅ DESPUÉS:
const baseUrl = new URL(hassInstance.link).origin;
fs.writeFileSync(serverInfoPath, JSON.stringify({ 
  link: baseUrl,
  // Guardar la URL completa para debugging, pero no usarla para navegación
  _authCallbackUrl: hassInstance.link  
}));
```

#### VERIFY S1
```bash
# Leer global.setup.ts modificado
# Verificar que .origin es usado:
grep -n "\.origin" playwright/global.setup.ts  # debe existir
grep -n "_authCallbackUrl" playwright/global.setup.ts  # debe existir para debug
# Verificar que NO se usa hassInstance.link directamente:
grep -n "hassInstance\.link\b" playwright/global.setup.ts | grep -v "origin\|_auth"  # debe estar vacío
```

#### SWEEP S1
```
Buscar en todo el proyecto:
- grep -rn "hassInstance.link" .
- grep -rn "auth_callback" .
- grep -rn "serverInfo.link" . → verificar que todos los usos esperan base URL limpia
- grep -rn "page.goto(serverInfo" . → verificar que auth.setup.ts usa el link correcto
```

---

### SPRINT 2 — Fix B: `goto()` directo a `/config/integrations` — navegar por sidebar
**Severidad**: 🔴 CRÍTICA — TimeoutError confirmado con log real  
**Archivos a modificar**: `ha-ev-trip-planner/playwright/auth.setup.ts` (líneas 64-66)

#### STRESS TEST S2
```
Archivo: research/stress-tests/S2-goto-antipattern.md

Prueba que FALLA (estado actual):
- Leer auth.setup.ts
- Verificar que existe goto() directo a una URL interna de HA (no la base URL):
  grep -n "goto.*config" playwright/auth.setup.ts  # = FALLO si encuentra resultado
- Verificar que existe waitForURL duplicado:
  grep -n "waitForURL" playwright/auth.setup.ts | wc -l  # ≥ 2 = FALLO
  
Anti-patrón detectado: usar goto() para navegar a secciones internas de HA
en lugar de simular la navegación real del usuario por el sidebar.
Impacto: test no es E2E real, además falla porque la URL base venía rota (P28).
```

#### FIX S2
```typescript
// playwright/auth.setup.ts — reemplazar las líneas 64-66 y el bloque de navegación

// ❌ ANTES (anti-patrón):
await page.goto(serverInfo.link + '/config/integrations');
await page.waitForURL(/\/config\/integrations/, { timeout: 30000 });
await page.waitForURL(/\/config\/integrations/);  // duplicado — código muerto

// ✅ DESPUÉS (sidebar nav real — Fix B):
// 1. Ir a la URL base limpia (ya corregida por Sprint 1)
await page.goto(serverInfo.link);
await page.waitForSelector('home-assistant', { state: 'visible', timeout: 30000 });

// 2. Navegar por el sidebar como un usuario real
await page.locator('[data-panel-id="config"]').click();
await page.waitForSelector('ha-config-dashboard', { state: 'visible', timeout: 15000 });

// 3. Navegar a integraciones desde el dashboard de configuración
await page.locator('[href="/config/integrations"]').click();
await page.waitForSelector('ha-config-integrations', { state: 'visible', timeout: 15000 });
```

#### VERIFY S2
```bash
grep -n "goto.*config" playwright/auth.setup.ts      # No debe haber goto a rutas internas
grep -n "waitForURL" playwright/auth.setup.ts | wc -l # Debe ser 0 o 1 (no duplicado)
grep -n "data-panel-id" playwright/auth.setup.ts     # Debe existir
grep -n "ha-config-dashboard" playwright/auth.setup.ts  # Debe existir
```

#### SWEEP S2
```
Buscar en todo el proyecto otros goto() a rutas internas de HA:
- grep -rn "goto.*\/config\/" .
- grep -rn "goto.*\/lovelace\/" .
- grep -rn "goto.*\/hacs\/" .
→ Cada uno debe ser reemplazado por navegación por sidebar o ser justificado explícitamente
```

---

### SPRINT 3 — Fix L: Path hardcodeado en `global.teardown.ts`
**Severidad**: 🟠 ALTA — falla en CI y en otras máquinas  
**Archivos a modificar**: `ha-ev-trip-planner/playwright/global.teardown.ts`

#### STRESS TEST S3
```
Archivo: research/stress-tests/S3-hardcoded-path.md

Prueba que FALLA:
- Leer global.teardown.ts
- Verificar si existe algún path absoluto hardcodeado:
  grep -n "\/Users\/" playwright/global.teardown.ts   # FALLO si encuentra resultado
  grep -n "\/home\/" playwright/global.teardown.ts    # FALLO si encuentra resultado  
  grep -n "C:\\\\" playwright/global.teardown.ts      # FALLO si encuentra resultado
- Verificar que NO usa __dirname o process.cwd() para construir paths:
  grep -n "__dirname\|process\.cwd\|fileURLToPath" playwright/global.teardown.ts
  # Si está vacío Y hay paths → FALLO
```

#### FIX S3
```typescript
// playwright/global.teardown.ts — reemplazar path hardcodeado

// ✅ PATRÓN CORRECTO (ESM-compatible):
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Usar __dirname para construir paths relativos al archivo
const serverInfoPath = path.join(__dirname, '../playwright/.auth/server-info.json');
```

#### VERIFY S3
```bash
grep -n "\/Users\|\/home\/\|C:\\\\" playwright/global.teardown.ts  # Vacío = PASS
grep -n "fileURLToPath\|import\.meta\.url" playwright/global.teardown.ts  # Existe = PASS
```

#### SWEEP S3
```
Buscar ESM anti-patrones en TODO el proyecto:
- grep -rn "__dirname" . --include="*.ts" | grep -v "fileURLToPath"
  → Cada __dirname sin fileURLToPath es un bug ESM latente (P25)
- grep -rn "require(" . --include="*.ts"
  → CommonJS require() en un proyecto ESM = bug
- grep -rn "\/Users\/\|\/home\/[a-z]" . --include="*.ts"
  → Paths hardcodeados
```

---

### SPRINT 4 — Fix D: `baseURL` con IIFE anti-patrón ESM en `playwright.config.ts`
**Severidad**: 🟠 ALTA — ESM bug sistemático (P25)  
**Archivos a modificar**: `ha-ev-trip-planner/playwright.config.ts`

#### STRESS TEST S4
```
Archivo: research/stress-tests/S4-esm-iife-baseurl.md

Prueba que FALLA:
- Leer playwright.config.ts
- Verificar si existe un IIFE para definir baseURL:
  grep -n "(() =>" playwright.config.ts | grep -i "base\|url\|port"
  # Si existe → FALLO — IIFE innecesario, puede causar problemas ESM
- Verificar que baseURL no es una función sino un string:
  grep -n "baseURL" playwright.config.ts
  # Si el valor es una expresión compleja en vez de string → FALLO
```

#### FIX S4
```typescript
// playwright.config.ts

// ❌ ANTES (IIFE anti-patrón):
const baseURL = (() => {
  const port = process.env.HA_PORT || '8542';
  return `http://127.0.0.1:${port}`;
})();

// ✅ DESPUÉS (simple y directo):
const HA_PORT = process.env.HA_PORT ?? '8542';
const baseURL = `http://127.0.0.1:${HA_PORT}`;

// En la config:
use: {
  baseURL,
  // ...
}
```

#### VERIFY S4
```bash
grep -n "(() =>" playwright.config.ts  # Debe estar vacío
grep -n "baseURL" playwright.config.ts  # Debe ser string simple o template literal
npx tsc --noEmit  # No debe haber errores TypeScript
```

---

### SPRINT 5 — Fix F + Fix P + Fix G: `copilot-instructions.md` con infra inexistente
**Severidad**: 🔴 CRÍTICA — afecta a TODOS los agentes siempre (P10)  
**Archivos a modificar**: `.github/copilot-instructions.md` en AMBOS repos

#### STRESS TEST S5
```
Archivo: research/stress-tests/S5-copilot-instructions-phantom.md

Prueba que FALLA:
- Leer .github/copilot-instructions.md
- Verificar si referencia test-ha/docker-compose.yml:
  grep -n "test-ha/docker-compose" .github/copilot-instructions.md  # = FALLO si existe
- Verificar si referencia localhost:8123 como instancia de test:
  grep -n "localhost:8123" .github/copilot-instructions.md  # = FALLO si existe
- Verificar si menciona __dirname sin fileURLToPath:
  grep -n "__dirname" .github/copilot-instructions.md | grep -v "fileURLToPath"  # = FALLO

IMPACTO: Copilot-instructions llegan a TODOS los agentes en TODOS los contextos.
Un dato falso aquí contamina cada sesión de trabajo.
```

#### FIX F
```markdown
## Cambios en copilot-instructions.md

### ELIMINAR estas secciones (infra inexistente):
- Cualquier referencia a `test-ha/docker-compose.yml`
- Cualquier referencia a `localhost:8123` como instancia de test

### AÑADIR sección: Instancia de Test HA
```markdown
## Test Home Assistant Instance

Los tests E2E corren contra una instancia **efímera** gestionada por `hass-taste-test`.
NO usar localhost:8123 (instancia de producción del desarrollador).

### Setup automático (vía hass-taste-test)
La instancia de test se levanta en el `globalSetup` de Playwright:
- Puerto: asignado dinámicamente (ver `playwright/.auth/server-info.json` tras setup)
- URL base: `new URL(hassInstance.link).origin` — NUNCA la URL completa con auth_callback
- La instancia se destruye en `globalTeardown`

### Para debug manual
```bash
# El puerto se puede fijar con:
HA_PORT=8542 npx playwright test
```
```

### AÑADIR sección: ESM Rules (Fix P)
```markdown
## ESM Rules — TypeScript con type: module

Este proyecto usa ES Modules. Reglas obligatorias:

1. NUNCA usar `__dirname` o `__filename` directamente
2. SIEMPRE usar el patrón:
   ```typescript
   import { fileURLToPath } from 'url';
   import path from 'path';
   const __filename = fileURLToPath(import.meta.url);
   const __dirname = path.dirname(__filename);
   ```
3. NUNCA usar `require()` — solo `import`
4. En playwright.config.ts: baseURL debe ser un string, no una función/IIFE
```

#### VERIFY S5
```bash
grep -n "test-ha/docker-compose" .github/copilot-instructions.md  # Vacío = PASS
grep -n "localhost:8123" .github/copilot-instructions.md  # Vacío = PASS
grep -n "hass-taste-test" .github/copilot-instructions.md  # Existe = PASS
grep -n "ESM\|fileURLToPath\|import\.meta\.url" .github/copilot-instructions.md  # Existe = PASS
```

#### SWEEP S5
```
¿Hay otros archivos de documentación con infra obsoleta?
- grep -rn "test-ha\|localhost:8123" . --include="*.md"
- grep -rn "test-ha\|localhost:8123" . --include="*.yml"
→ Cada ocurrencia debe ser actualizada o eliminada
```

---

### SPRINT 6 — Fix R: Prompts de delegación sin contexto de decisiones
**Severidad**: 🟠 ALTA — el qa-engineer perdió el Fix B porque no estaba en el prompt (P27)  
**Archivos a modificar**: `plugins/ralph-specum/commands/implement.md`, `skills/smart-ralph/SKILL.md`

#### STRESS TEST S6
```
Archivo: research/stress-tests/S6-delegation-context-loss.md

Prueba que FALLA (simulación de razonamiento):
Prompt actual de delegación (aproximado):
  "Fix the broken selectors or configuration issues in auth.setup.ts"
  
Pregunta: ¿Un agente que recibe este prompt y tiene acceso al código puede 
saber que goto() es un anti-patrón en este proyecto?

Respuesta: NO — el archivo no lo documenta, la restricción no está en el prompt.
Resultado: el agente usa goto() porque es lo más rápido → TimeoutError.

Verificar que implement.md/start.md NO tiene sección de "delegation contract":
  grep -n "delegation\|anti-pattern\|restriction\|prohibido" plugins/ralph-specum/commands/implement.md
  # Si vacío → FALLO
```

#### FIX R
```markdown
## Añadir a plugins/ralph-specum/commands/implement.md

### Delegation Contract — Lo que DEBE incluir cada prompt de delegación

Cuando delegues una tarea a un subagente, el prompt DEBE incluir:

1. **Restricciones de diseño relevantes** — decisiones ya tomadas que el subagente debe respetar
   Ejemplo: "Usa sidebar nav (data-panel-id), NO goto() directo a rutas internas de HA"

2. **Anti-patrones prohibidos** — explícitamente, con el porqué
   Ejemplo: "NO uses goto('/config/integrations') — HA no soporta deep linking sin auth"

3. **El fix específico acordado** — si existe una solución diseñada, nombrala
   Ejemplo: "Implementa Fix B: navegar por data-panel-id como documentado en homeassistant-selector-map.skill.md"

4. **Archivos de referencia relevantes** — rutas exactas a skills/docs que aplican
   Ejemplo: "Ver plugins/ralph-specum/skills/e2e/examples/homeassistant-selector-map.skill.md"

5. **Criterio de éxito verificable** — cómo saber que el fix es correcto
   Ejemplo: "El test debe pasar sin TimeoutError y sin goto() a rutas internas"

### Plantilla de delegación

```
## Tarea: [nombre]

### Contexto de la decisión
[Explicar por qué se hace esto de esta manera, no otra]

### Restricciones (NO hacer)
- ❌ [anti-patrón 1] — porque [razón]
- ❌ [anti-patrón 2] — porque [razón]

### Fix acordado (SÍ hacer)
- ✅ [descripción del fix] — ver [archivo de referencia]

### Criterio de éxito
- [ ] [verificación 1]
- [ ] [verificación 2]
```
```

#### SWEEP S6
```
Revisar TODOS los comandos en plugins/ralph-specum/commands/:
- ¿Cuáles generan prompts de delegación a subagentes?
  grep -rn "delegate\|subagent\|assign\|handoff" plugins/ralph-specum/commands/
- Cada uno debe tener el delegation contract o una referencia a él
```

---

### SPRINT 7 — Fix M: Skills E2E no referenciadas en tasks generadas
**Severidad**: 🟡 MEDIA — el agente no cargaba las skills correctas en fases E2E (P18)  
**Archivos a modificar**: `plugins/ralph-specum/commands/tasks.md`, `skills/spec-workflow/SKILL.md`

#### STRESS TEST S7
```
Archivo: research/stress-tests/S7-missing-skill-references.md

Prueba que FALLA:
- Leer un tasks.md generado por el agente (si existe en research/ o specs/)
- Verificar si las tareas de tipo E2E referencian skills por nombre:
  grep -n "playwright-env\|mcp-playwright\|selector-map\|homeassistant" specs/*/tasks.md 2>/dev/null
  # Si vacío → FALLO

- Leer plugins/ralph-specum/commands/tasks.md
- Verificar si hay lógica para incluir skills en tareas E2E:
  grep -n "e2e\|playwright\|skill" plugins/ralph-specum/commands/tasks.md
  # Si vacío → FALLO
```

#### FIX M
```markdown
## Añadir a plugins/ralph-specum/commands/tasks.md — sección E2E Tasks

### E2E Task Template (para proyectos fullstack/frontend)

Cuando generes tareas de tipo E2E, SIEMPRE incluir en el contexto de la tarea:

```markdown
- [ ] VE1 — Start test infrastructure
  - **Skills requeridas**: 
    - `plugins/ralph-specum/skills/e2e/playwright-env.skill.md`
    - `plugins/ralph-specum/skills/e2e/playwright-session.skill.md`
    - `plugins/ralph-specum/skills/e2e/examples/homeassistant-selector-map.skill.md` (si es HA)
  - **Anti-patrones prohibidos**:
    - NO usar goto() para navegar a secciones internas de HA
    - NO usar waitForTimeout() — usar waitForSelector o waitForURL
    - NO hardcodear entity_id de HA en selectores
  - **Herramientas**: hass-taste-test (instancia efímera, no localhost:8123)
```

## Añadir a skills/spec-workflow/SKILL.md

### Skills automáticas por tipo de spec

| Tipo de spec | Skills que se deben cargar automáticamente |
|---|---|
| fullstack E2E | playwright-env + playwright-session + mcp-playwright + homeassistant-selector-map (si HA) |
| api-only | reality-verification únicamente |
| cli/library | reality-verification únicamente |
```

#### SWEEP S7
```
Verificar spec-workflow references:
- grep -rn "playwright-env\|mcp-playwright" plugins/ralph-specum/skills/spec-workflow/
- Si no están referenciadas → añadir cross-reference
```

---

### SPRINT 8 — Fix N + Fix O: `spec-executor` referenciado pero no existe
**Severidad**: 🟠 ALTA — flujo de fix tasks roto (P21)  
**Archivos a modificar**: `plugins/ralph-specum/commands/start.md`, `skills/smart-ralph/SKILL.md`

#### STRESS TEST S8
```
Archivo: research/stress-tests/S8-spec-executor-phantom.md

Prueba que FALLA:
- Buscar referencias a "spec-executor" en todos los archivos:
  grep -rn "spec-executor" plugins/ralph-specum/
  # Si existen referencias → verificar que el agente/comando referenciado existe
  
- Verificar si existe un comando o skill llamado spec-executor:
  ls plugins/ralph-specum/commands/ | grep executor   # ¿existe?
  ls plugins/ralph-specum/skills/ | grep executor     # ¿existe?
  
- Si las referencias existen pero el archivo no → FALLO confirmado (P21)
```

#### FIX N + O
```markdown
## Opción A: Crear spec-executor como alias del coordinador

Crear plugins/ralph-specum/commands/spec-executor.md que redirija al comando correcto:

```markdown
# spec-executor

> Este comando es un alias. El flujo de ejecución de specs 
> está gestionado por el coordinador (start.md).
> 
> Si ves una referencia a "spec-executor" en un prompt de delegación,
> trátala como una instrucción para ejecutar la siguiente tarea pendiente
> en el tasks.md del spec actual.

## Comportamiento
1. Leer el tasks.md del spec activo
2. Encontrar la primera tarea no completada [ ]
3. Ejecutarla siguiendo las instrucciones de la tarea
4. Marcar como [x] cuando termine
5. Documentar resultado en .progress.md
```

## Opción B: Eliminar todas las referencias a spec-executor y sustituir por coordinador

grep -rn "spec-executor" plugins/ → reemplazar cada ocurrencia por descripción explícita de qué hacer
```

#### SWEEP S8
```
Buscar otros agentes/comandos referenciados que pueden no existir:
- grep -rn "agent\|agente\|@[a-z-]*" plugins/ralph-specum/commands/ | grep -v "^Binary"
- Para cada referencia verificar que el archivo existe
```

---

### SPRINT 9 — Cross-reference: `homeassistant-selector-map.skill.md` no enlazado
**Severidad**: 🟡 MEDIA — el skill existe pero los agentes no lo encuentran (P20)  
**Archivos a modificar**: `playwright-env.skill.md`, `playwright-session.skill.md`

#### STRESS TEST S9
```
Archivo: research/stress-tests/S9-skill-cross-reference.md

Prueba que FALLA:
- Leer playwright-env.skill.md
- Verificar si referencia homeassistant-selector-map:
  grep -n "homeassistant-selector-map\|examples/" plugins/ralph-specum/skills/e2e/playwright-env.skill.md
  # Si vacío → FALLO

- Leer playwright-session.skill.md
- Misma verificación:
  grep -n "homeassistant-selector-map\|examples/" plugins/ralph-specum/skills/e2e/playwright-session.skill.md
  # Si vacío → FALLO
  
IMPACTO: El agente tiene el conocimiento correcto sobre HA (data-panel-id, anti-patrones),
pero no lo carga porque nadie le dice que el archivo examples/ existe.
```

#### FIX S9
```markdown
## Añadir al final de playwright-env.skill.md

### Home Assistant — Recursos específicos

Para proyectos con Home Assistant, cargar también:
- `skills/e2e/examples/homeassistant-selector-map.skill.md`
  → Contiene: jerarquía de selectores HA, data-panel-id del sidebar,
    convención data-testid para componentes custom, anti-patrones Shadow DOM,
    patterns para waitFor en Lovelace

## Añadir al final de playwright-session.skill.md

### HA Sidebar Navigation (OBLIGATORIO para auth flows)

Para navegar a secciones del panel de configuración de HA,
NUNCA usar goto() directo — siempre sidebar nav:

```typescript
// ✅ CORRECTO — navegar como usuario real
await page.locator('[data-panel-id="config"]').click();
await page.waitForSelector('ha-config-dashboard', { state: 'visible', timeout: 15000 });

// ❌ PROHIBIDO — goto() a ruta interna HA
await page.goto('/config/integrations');  // No funciona sin auth establecido
```

Ver guía completa: `skills/e2e/examples/homeassistant-selector-map.skill.md`
```

#### SWEEP S9
```
Verificar otros skills e2e que pudieran necesitar cross-reference:
- grep -rn "homeassistant\|home-assistant\|ha-" plugins/ralph-specum/skills/e2e/
- Verificar que mcp-playwright.skill.md también tiene la referencia
```

---

### SPRINT 10 — Fix H + Fix K: Timeout de subagentes y verificación pre-test
**Severidad**: 🟡 MEDIA — P13 (timeout) + Fix K (pre-flight check)  
**Archivos a modificar**: `skills/spec-workflow/references/phase-transitions.md`, nuevo script

#### STRESS TEST S10
```
Archivo: research/stress-tests/S10-timeout-preflight.md

Prueba que FALLA (P13):
- Leer phase-transitions.md
- Verificar si documenta timeout de subagentes:
  grep -n "timeout\|fallback\|retry\|hung\|stuck" plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md
  # Si vacío → FALLO — no hay documentado qué hacer cuando un agente no responde

Prueba que FALLA (Fix K — verificación pre-test):
- Verificar si existe algún script de pre-flight check:
  ls ha-ev-trip-planner/scripts/ 2>/dev/null | grep "check\|verify\|preflight"
  # Si no existe → FALLO — el agente no puede verificar que la infra existe antes de correr tests
```

#### FIX H
```markdown
## Añadir a phase-transitions.md

### Subagent Timeout Protocol

Si un subagente no responde en 5 minutos:
1. El coordinador debe asumir timeout y continuar sin el resultado
2. Documentar en .progress.md: `[TIMEOUT] Subagente {nombre} no respondió en 5min`
3. Marcar la tarea como `[ ] [TIMEOUT]` en tasks.md
4. NO bloquear el sprint completo por un subagente colgado
5. En el siguiente ciclo, reintentar la tarea con prompt más acotado
```

#### FIX K (nuevo archivo)
```bash
## Crear: ha-ev-trip-planner/scripts/preflight-check.sh

#!/bin/bash
# preflight-check.sh — verifica que la infra de test está disponible antes de correr E2E

echo "🔍 Preflight check para tests E2E..."

# 1. Verificar que hass-taste-test está instalado
if ! npx hass-taste-test --version &>/dev/null; then
  echo "❌ hass-taste-test no está instalado"
  echo "   Ejecutar: npm install hass-taste-test"
  exit 1
fi
echo "✅ hass-taste-test disponible"

# 2. Verificar que playwright está instalado
if ! npx playwright --version &>/dev/null; then
  echo "❌ playwright no está instalado"
  echo "   Ejecutar: npm install && npx playwright install"
  exit 1
fi
echo "✅ playwright disponible"

# 3. Verificar que NO hay server-info.json obsoleto de una sesión anterior
SERVER_INFO="playwright/.auth/server-info.json"
if [ -f "$SERVER_INFO" ]; then
  echo "⚠️  Existe $SERVER_INFO de sesión anterior — limpiando..."
  rm -f "$SERVER_INFO"
fi
echo "✅ Estado limpio"

# 4. Verificar que copilot-instructions.md NO referencia localhost:8123 como test
if grep -q "localhost:8123" .github/copilot-instructions.md 2>/dev/null; then
  echo "❌ copilot-instructions.md referencia localhost:8123 como instancia de test"
  echo "   Ver Fix F en research/e2e-ha-findings.md"
  exit 1
fi
echo "✅ copilot-instructions.md limpio"

echo ""
echo "✅ Preflight check completado. Listo para ejecutar tests E2E."
```

#### SWEEP S10
```
Verificar que preflight-check.sh está referenciado:
- En package.json como script: "test:preflight": "bash scripts/preflight-check.sh"
- En playwright.config.ts como globalSetup alternativo o en README
- En copilot-instructions.md como paso previo a ejecutar tests
```

---

## 📋 CHECKLIST FINAL DE REVISIÓN SISTÉMICA

Después de completar los 10 sprints, Copilot debe ejecutar esta revisión global:

### Revisión A — Coherencia de archivos de documentación
```bash
# ¿Algún .md todavía menciona infra inexistente?
grep -rn "test-ha/docker-compose\|localhost:8123" . --include="*.md"

# ¿Algún .md todavía menciona spec-executor sin que exista?
grep -rn "spec-executor" . --include="*.md"
ls plugins/ralph-specum/commands/ | grep executor  # debe existir si está referenciado

# ¿Todos los skills e2e tienen cross-reference a homeassistant-selector-map?
grep -rn "homeassistant-selector-map" plugins/ralph-specum/skills/e2e/
```

### Revisión B — Coherencia de código TypeScript
```bash
# ¿Quedan __dirname sin patrón ESM?
grep -rn "__dirname\|__filename" . --include="*.ts" | grep -v "fileURLToPath\|node_modules\|dist"

# ¿Quedan goto() a rutas internas de HA?
grep -rn "goto.*\/config\|goto.*\/lovelace\|goto.*\/hacs" . --include="*.ts"

# ¿Quedan waitForTimeout()?
grep -rn "waitForTimeout" . --include="*.ts"

# ¿TypeScript compila sin errores?
cd ha-ev-trip-planner && npx tsc --noEmit
```

### Revisión C — Coherencia del flujo de agentes
```bash
# ¿Todos los comandos con delegación tienen delegation contract?
grep -rln "delegate\|subagent\|assign" plugins/ralph-specum/commands/
# Para cada archivo encontrado: verificar sección delegation contract

# ¿Tasks.md template incluye skills para E2E?
grep -n "playwright-env\|homeassistant-selector" plugins/ralph-specum/commands/tasks.md
```

### Revisión D — Stress tests pasan
```bash
# Para cada stress test en research/stress-tests/:
for f in research/stress-tests/S*.md; do
  echo "=== Revisando $f ==="
  # Los comandos grep/bash dentro de cada S*.md deben dar resultado vacío (PASS)
done
```

---

## 🚦 ORDEN DE EJECUCIÓN RECOMENDADO

```
Sprint 1 (Fix S) → Sprint 2 (Fix B) → Sprint 5 (Fix F+P+G) → Sprint 3 (Fix L) 
→ Sprint 4 (Fix D) → Sprint 9 (cross-ref) → Sprint 6 (Fix R) → Sprint 7 (Fix M) 
→ Sprint 8 (Fix N+O) → Sprint 10 (Fix H+K) → Revisión Sistémica A+B+C+D
```

**Sprints 1+2 son BLOQUEANTES** — sin ellos los tests E2E no pueden ejecutar.  
**Sprint 5 es CRÍTICO** — contamina todos los agentes hasta que se corrija.  
**Sprints 6-10** pueden ejecutarse en paralelo si hay capacidad.

---

## 📌 COMMIT CONVENTION

```
fix(sprint-1): Fix S — global.setup.ts save base URL, not auth_callback URL
fix(sprint-2): Fix B — auth.setup.ts use sidebar nav, not goto() to internal HA routes  
fix(sprint-3): Fix L — global.teardown.ts use fileURLToPath for ESM-compatible paths
fix(sprint-4): Fix D — playwright.config.ts simplify baseURL, remove IIFE anti-pattern
fix(sprint-5): Fix F+P+G — copilot-instructions.md remove phantom infra, add ESM rules
fix(sprint-6): Fix R — implement.md add delegation contract template
fix(sprint-7): Fix M — tasks.md add E2E skill references, spec-workflow auto-load rules
fix(sprint-8): Fix N+O — resolve spec-executor phantom reference
fix(sprint-9): cross-ref homeassistant-selector-map from playwright-env and playwright-session
fix(sprint-10): Fix H+K — subagent timeout protocol, preflight check script
chore(research): systematic review A+B+C+D — no remaining issues
```

---

*Generado por análisis forense completo — 03/04/2026 05:33 CEST*  
*Fuente: 29 hallazgos (P1-P29), 19 fix candidatos (Fix A-S), 10 sprints TDD-IA*
