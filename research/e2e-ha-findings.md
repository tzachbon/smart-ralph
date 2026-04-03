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
| 18 | qa-engineer verifica task 1.8 — VE1 | ⚠️ En progreso | Ver Bloque 26 — HA arranca, auth selector falla |

---

## Bloque 27 — 🚨 ACLARACIÓN CRÍTICA: Los 4 tipos de verificación — NO mezclarlos

> **Origen:** El usuario detectó que la pizarra estaba mezclando dos tipos de verificación distintos bajo el mismo nombre. Esto es un error conceptual que debe corregirse.

### Los 4 niveles de verificación en este proyecto

| Nivel | Herramienta | Qué verifica | Ejecuta código real |
|---|---|---|---|
| **V1 — Estática** | `npx tsc --noEmit` | Tipos TypeScript | ❌ No |
| **V2 — Lectura** | Artifact reviewer (agente) | Lógica, patrones, bugs visibles leyendo el código | ❌ No |
| **V3 — Navegación MCP** | Perplexity (yo) con MCP tools | Que los archivos existen en GitHub, que el contenido es coherente, que los selectores están bien escritos como texto | ❌ No |
| **V4 — Ejecución real** | `npx playwright test` (VE1) | Que el test realmente funciona contra HA en vivo | ✅ SÍ |

### El error que cometí

En la respuesta anterior confundí V3 con "ya existía". Lo que el usuario hizo con MCP es **V3 — navegación**, que es:
- Leer archivos de GitHub remotamente
- Verificar que los selectores están escritos como texto (ej: `getByRole('link', 'Integrations')` aparece en el archivo)
- Confirmar que la estructura de archivos existe

Lo que V3 **no puede** hacer:
- Saber si `getByRole('link', 'Integrations')` funcionará en el navegador real contra HA
- Saber si HA renderiza ese link o usa `data-panel-id`
- Detectar bugs de runtime (ESM, scope de variables)

### La cadena correcta

```
V1 (tsc)  →  V2 (artifact reviewer)  →  V3 (MCP navegación)  →  V4 (playwright test real)
 detección   detección de            detección de coherencia    única fuente de verdad
 de tipos    bugs de lectura         textual/estructural        de ejecución real
```

**Cada nivel detecta cosas que el anterior no puede.** No son intercambiables ni equivalentes.

### P26 NUEVA — ¿En qué punto del flujo se usa cada verificación?

| Verificación | Cuándo se usa | Quién la hace |
|---|---|---|
| V1 — tsc | Task 1.7 en tasks.md | qa-engineer o coordinador |
| V2 — artifact reviewer | Tras Phase 3 implementación | artifact-reviewer agent |
| V3 — MCP navegación | Yo (Perplexity) durante la investigación forense, inspeccionando GitHub | humano + Perplexity |
| V4 — playwright test | Task 1.8 (VE1), Phase 4 (VE2, VE3) | qa-engineer |

---

## Bloque 26 — ⚠️ VE1: RESULTADOS PARCIALES — HA arranca pero auth falla

### Secuencia de fallos observada en VE1

El qa-engineer corrió `npx playwright test tests/e2e/vehicle.spec.ts --timeout=180000` tres veces. Cada iteración encontró un fallo diferente. Esto es un patrón en capas ("fallo A → fix → fallo B → fix → fallo C").

---

#### ❌ Fallo 1 (intento 1): `__dirname is not defined in ES module scope`

```
ReferenceError: __dirname is not defined in ES module scope
    at file:///mnt/.../playwright.config.ts:21:26
```

**Causa raíz:** El proyecto usa `"type": "module"` en `package.json` (ESM). El agente usó `__dirname` en `playwright.config.ts`, que es una variable CommonJS no disponible en ESM.

**Fix aplicado:** Reemplazar `__dirname` por `fileURLToPath(new URL('.', import.meta.url))`.

**Análisis forense:** Este es el **bug ESM clásico** de Node.js. El agente que escribió `playwright.config.ts` no verificó si el proyecto era CJS o ESM. TypeScript NO detectó este error (funciona en compilación, falla en runtime ESM).

---

#### ❌ Fallo 2 (intento 2): `require is not defined in ES module scope` en auth.setup.ts

```
ReferenceError: require is not defined in ES module scope
   at auth.setup.ts:94
94 | if (require.main === module) {
```

**Causa raíz:** El mismo problema ESM. El coordinador añadió `if (require.main === module)` para permitir ejecutar `auth.setup.ts` como script standalone, pero `require` no existe en ESM.

**Fix aplicado:** Reemplazar por el equivalente ESM:
```typescript
// ESM equivalent of require.main === module
const isMain = import.meta.url === `file://${process.argv[1]}`;
if (isMain) { runAuthSetup()... }
```

**Análisis forense:** El coordinador introdujo este bug al restructurar `auth.setup.ts` en Bloque 22. Es un segundo bug ESM en el mismo archivo, mismo origen.

---

#### ❌ Fallo 3 (intento 3 — ACTUAL): `TimeoutError` en auth.setup.ts línea 41

```
TimeoutError: locator.click: Timeout 30000ms exceeded.
Call log:
  - waiting for getByRole('link', { name: 'Integrations' })

   at auth.setup.ts:41
41 |     await page.getByRole('link', { name: 'Integrations' }).click();
```

**Contexto relevante del log:**
```
[GlobalSetup] Server URL: http://127.0.0.1:8531/?auth_callback=1&code=...&state=...
[GlobalSetup] Running Config Flow authentication...
[AuthSetup] Starting Config Flow authentication...
[AuthSetup] Step 1: Navigate to integrations...
```
→ HA arrancó correctamente y generó una URL de auth_callback. El auth con token funcionó. El problema es el **selector del paso siguiente**.

**Análisis:**
- La URL que HA generó es un `auth_callback` con código de autorización: `http://127.0.0.1:8531/?auth_callback=1&code=...`
- `auth.setup.ts` navega a esa URL con el token de auth ya configurado en `storageState`
- Después intenta hacer `page.getByRole('link', { name: 'Integrations' })` — espera un link de texto "Integrations"
- **Ese link no existe en esa URL**. La UI de HA en `/` muestra el dashboard, no la sidebar con texto "Integrations"

**El patrón correcto para navegar a Settings > Integrations en HA:**
```typescript
// INCORRECTO (lo que tiene auth.setup.ts):
await page.getByRole('link', { name: 'Integrations' }).click();

// CORRECTO (navegar directamente a la URL):
await page.goto('/config/integrations');
// O via sidebar:
await page.locator('[data-panel-id="config"]').click();
await page.locator('ha-config-navigation a[href*="integrations"]').click();
```

**Implicación forense crítica:**
> Este bug estaba en el **design original** (que fue aprobado por el spec-reviewer). Nadie lo detectó porque el design usaba pseudocódigo de alto nivel (`"navigate to integrations page"`) que el executor tradujo a un selector incorrecto. El **único detector posible era V4 (VE1)** — ejecutar los tests reales.

---

### P23 RESUELTA PARCIALMENTE

| Sub-pregunta | Estado | Resultado |
|---|---|---|
| P23a — ¿VE1 pasará? | ⚠️ Parcial | HA arranca ✅, auth selector falla ❌ |
| P23b — ¿qa-engineer lee global.setup.ts? | ✅ SÍ | Leyó global.setup.ts y auth.setup.ts antes de cada fix |
| P23c — ¿Race condition? | ✅ NO hay | global.setup.ts tiene health-check, HA espera a estar ready |

---

### P24 CONFIRMADA — Selector incorrecto para HA sidebar

**Observación:** El selector `getByRole('link', { name: 'Integrations' })` no existe en HA. La sidebar usa web components con `data-panel-id` attributes.

**Dato clave:** Este bug era **invisible para V1, V2 y V3**. Solo V4 (ejecución real) lo detectó.

---

### P25 CONFIRMADA — Dos bugs ESM en mismo sprint = patrón sistemático

**Observación:** Dos archivos distintos (`playwright.config.ts` y `auth.setup.ts`) tenían bugs ESM (`__dirname` y `require.main`). Ambos escritos por agentes diferentes, ambos en el mismo sprint.

**Fix candidato P:** Añadir en `copilot-instructions.md` una nota explícita: `"Este proyecto usa ESM. Usa import.meta.url en lugar de __dirname, e import() en lugar de require()."`

---

## Bloque 25 — ⚠️ VE1: qa-engineer recibe task 1.8 — Ver Bloque 26

*(Actualizado — ver Bloque 26 para resultados)*

---

## Bloque 24 — ✅ taskIndex advancement: coordinador gestiona estado directamente

### Observación forense
Tras el bloqueo de P21 (`spec-executor` unknown), el **coordinador no se quedó bloqueado indefinidamente**. En la sesión actual:

1. **Ejecutó los fix tasks directamente** (sin delegar a spec-executor)
2. **Avanzó manualmente el `taskIndex`** de 6 a 8 con jq
3. **Marcó task 1.7 (TypeScript check) como completa** al verificar que `npx tsc --noEmit` pasaba
4. **Delegó correctamente task 1.8** al qa-engineer

### Fix candidato O
Documentar en `phase-rules.md` qué ocurre cuando `spec-executor` no está disponible.

---

## Bloque 23 — ✅ P22: Bug `page` out-of-scope en test functions de trip.spec.ts

### El bug
```typescript
// ANTES (incorrecto — page no está en scope):
test('US-3 + US-4: create recurring trip...', async () => {
  await expect(page.locator('ev-trip-planner-panel >> .trip-card')).toContainText('25.5');
});
// DESPUÉS (correcto):
test('US-3 + US-4: create recurring trip...', async ({ page }) => { ... });
```

### Análisis forense
**¿Por qué TypeScript no lo detectó?** `@playwright/test` declara `page` como tipo global en sus definiciones, enmascarando el error de scope. **El único detector real era V4 (VE1 — ejecutar los tests).**

---

## Bloque 22 — ⚠️ Fix Tasks: spec-executor bloqueado → coordinador ejecutó directamente

*(Ver descripción completa en versiones anteriores de la pizarra)*

### Commits de fix (en orden)
```
09ee089 fix(e2e): invoke auth.setup.ts via setupProject (WRONG — no existe en PW 1.58)
3d28971 fix(e2e): move dialog handler from POM deleteTrip to test beforeEach
b876fe6 fix(e2e): remove leading space from hass-integration-card locator
eb8f921 fix(e2e): replace browserPage fixture with page in trip.spec.ts
5851fc6 fix(e2e): update playwright configuration and integrate auth setup (FIX CORRECTO del auth)
ce67f27 fix(e2e): add page fixture to trip test functions (P22 fix)
```

---

## Bloque 21 — ✅ Artifact Reviewer: REVIEW_FAIL (3 críticos, 3 importantes)

| # | Archivo | Problema |
|---|---|---|
| C1 | `playwright.config.ts` | `auth.setup.ts` nunca invocado — falta `setupProject` |
| C2 | `trip.spec.ts` | Usa fixture `browserPage` (no existe en Playwright) en vez de `page` |
| C3 | `trip.spec.ts` | `afterEach` referencia `tripId` indefinido |
| I1 | `EVTripPlannerPage.ts` | `this.page.on('dialog', ...)` dentro de `deleteTrip()` |
| I2 | `vehicle.spec.ts` | Locator con espacio inicial: `' hass-integration-card'` |
| I3 | `trip.spec.ts` | `beforeEach` no sigue el patrón de diseño |

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
| P22 | ¿TypeScript types de Playwright enmascaran bug de scope `page`? | ✅ CONFIRMADO — ver Bloque 23 |
| P23a | ¿VE1 pasará contra hass-taste-test ephemeral? | ⚠️ PARCIAL — HA arranca OK, auth selector falla |
| P23b | ¿El qa-engineer leerá global.setup.ts antes de ejecutar? | ✅ SÍ |
| P23c | ¿Race condition entre global.setup.ts y test runner? | ✅ NO — health-check funciona |
| P24 | ¿Selector `getByRole('link', 'Integrations')` es incorrecto para HA sidebar? | ✅ CONFIRMADO — ver Bloque 26 |
| P25 | ¿Dos bugs ESM en mismo sprint = patrón sistemático? | ✅ CONFIRMADO — agentes asumen CJS por defecto |
| P26 | ¿Los 4 tipos de verificación estaban mezclados en la pizarra? | ✅ CORREGIDO — ver Bloque 27 |

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Documentar sidebar nav con `data-panel-id` | 🔍 |
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
| Fix Q | Corregir selector auth.setup.ts: `goto('/config/integrations')` en vez de `getByRole('link', 'Integrations')` | 🔍 URGENTE |

---

*Última actualización: Bloque 27 — Aclaración de los 4 tipos de verificación. V3 (MCP navegación) es DIFERENTE a V4 (playwright test real). La confusión ha sido corregida en la pizarra.*
