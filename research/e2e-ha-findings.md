# E2E HA Findings — Pizarra de Investigación

> Rama de trabajo: `research/e2e-ha-findings`  
> Propósito: borrador vivo donde anotamos lo que investigamos, debatimos y rebatimos sobre e2e testing en proyectos HA custom component.
> **No es documentación definitiva.** Es una pizarra. Las entradas pueden estar en discusión, rebatidas o pendientes de verificar.

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

## Bloque 0 — Sesión en vivo del agente (2026-04-03) — Nuevos hallazgos

> El agente fue relanzado sobre los tests existentes (sin borrar nada) para que diagnosticara y arreglara por su cuenta. Esta sección recoge lo que encontró.

### 0.1 Bug confirmado: `auth.setup.ts` no guardaba `storageState`

✅ **Confirmado y arreglado por el agente en sesión en vivo.**

El flujo es:
```
globalSetup  →  arranca HA efímero (puerto dinámico, p.ej. 8508)  →  escribe server-info.json
auth.setup   →  lee server-info.json  →  hace login + Config Flow  →  escribe panel-url.txt
             →  ❌ NO llama page.context().storageState() → user.json NUNCA se crea
globalTeardown → borra server-info.json (pero HA sigue corriendo)
chromium tests → leen panel-url.txt (8508) + storageState user.json → ❌ user.json no existe → tests sin auth
```

**Fix aplicado:** añadir al final de `auth.setup.ts`:
```typescript
await page.context().storageState({ path: USER_JSON_PATH });
// [AuthSetup] Storage state saved to: playwright/.auth/user.json
```

**Resultado post-fix:** `user.json` se crea correctamente (831 bytes). El setup pasa en 15.9s.

### 0.2 Pero tras el fix: 11 tests siguen fallando (4 pasan, 17 skipped)

⚠️ **El storageState era solo el primer bug. Hay más.**

Resultados post-fix del storageState:
- **4 passed** — tests US-1 con lógica condicional (empty state, recurring trips, punctual trips, + 1 más)
- **11 failed** — todos los tests que intentan hacer click en "+ Agregar Viaje" (US-2) + "shows correct trip count badge" (US-1)
- **17 skipped** — US-3 a US-6 saltados por cascada de fallos previos

Error patrón en los 11 fallidos:
```
TimeoutError: locator.click: Timeout 10000ms exceeded.
waiting for getByRole('button', { name: /\+ Agregar Viaje|Add Trip/i })
```

### 0.3 El agente se confundió diagnosticando la causa raíz

💬 **Esto es importante para el análisis forense del sistema.**

El agente pasó un tiempo significativo teorizing sobre causas incorrectas antes de llegar a la correcta:

**Hipótesis falsas que exploró el agente:**
1. ❌ Ejecución en paralelo con múltiples workers → descartado (mismo resultado con `--workers=1`)
2. ❌ Conflicto de puertos entre instancias HA → descartado
3. ❌ server-info.json borrado antes de que los tests lo lean → parcialmente correcto pero no la causa raíz
4. ❌ storageState con tokens de puerto 8508 incompatibles con HA en puerto diferente → no confirmado

**La causa raíz real que el agente aún no ha articulado claramente:**  
🔍 Los 4 tests que pasan tienen lógica condicional que devuelve early si el panel devuelve 404/vacío.  
🔍 Los 11 que fallan intentan interactuar con el botón "Agregar Viaje" que NO está en la página porque la página está devolviendo la shell de HA sin el panel cargado.  
🔍 La pregunta sin responder: **¿por qué el panel no carga en los chromium tests aunque auth.setup lo registra correctamente?**

**Hipótesis principal (a confirmar):** el `storageState` guardado por `auth.setup` contiene tokens con la URL de HA (`hassUrl`) embebida. Cuando los chromium tests cargan ese `storageState`, los tokens pueden tener el `haUrl` del servidor de setup (8508), pero si el HA de setup ya fue terminado por globalTeardown entre el setup y los chromium tests, los tokens son inválidos y HA muestra la shell vacía en lugar del 404.

**⚠️ ATENCIÓN: esto es crítico para la arquitectura.**  
Aunque el agente arregló el storageState, puede que el diseño fundamental tenga un problema: `auth.setup.ts` es el 'setup' project de Playwright, que corre en su propio proceso. Si globalSetup arranca HA una sola vez y globalTeardown lo destruye al final, ¿cuándo exactamente se destruye? ¿Antes o después de que los chromium tests terminen?

### 0.4 Nuevo hallazgo: `globalTeardown` borra server-info.json pero ¿destruye HA?

🔍 **Pendiente de confirmar leyendo el código exacto.**

De la salida del agente:
> "The globalTeardown says it 'destroys the ephemeral HA server' but looking at the actual code, it only deletes server-info.json and logs. It doesn't actually stop HA!"

Si esto es correcto, HA sigue corriendo durante toda la sesión de tests. El problema puede ser otro.

El agente también nota:
> "Could not read server-info.json, using default localhost:8123"

Esto aparece cuando un test individual corre DESPUÉS de que globalTeardown ha borrado server-info.json de una ejecución anterior. El test lee la URL stale del panel-url.txt (con el puerto de la ejecución anterior) pero intenta conectarse a un HA que ya no existe en ese puerto.

### 0.5 Conclusión provisional (a validar)

**El diseño actual tiene un bug arquitectural:**

```
[Run 1]
globalSetup   → HA en :8507 → server-info.json(:8507)
auth.setup    → login + panel → panel-url.txt(:8507), user.json(tokens:8507)
globalTeardown → borra server-info.json, ¿para HA?

[Run 2, mismo proceso playwright]
chromium tests → leen panel-url.txt(:8507) + user.json(tokens:8507)
               → Si HA ya no corre en :8507 → timeout/shell vacía
```

Alternativamente, si globalSetup crea un nuevo HA en :8508 al correr chromium tests:
```
globalSetup   → HA NUEVO en :8508 → server-info.json(:8508)
              → panel-url.txt sigue diciendo :8507 ← STALE
              → user.json sigue teniendo tokens de :8507 ← STALE
chromium tests → usan panel-url.txt(:8507) + user.json(:8507) contra HA en :8508 → fallo
```

---

## Bloque 1 — ¿Qué herramienta de E2E debe usar el agente para HA?

### 1.1 Ecosistema oficial de testing HA

**Unit/Integration (Python):** ✅  
La documentación oficial de HA developers solo menciona `pytest` + `pytest-homeassistant-custom-component` para tests de integración. No hay referencia oficial a ninguna herramienta de E2E de browser.
- Fuente: https://developers.home-assistant.io/docs/development_testing/
- Esto cubre: config flows, entity states, service calls — todo via Python sin browser.
- Para E2E de *panel custom (frontend)*, pytest no llega. El agente necesita browser.

**E2E con browser:** `hass-taste-test` ✅ (de facto estándar para custom components)
- Es la única librería madura específica para HA E2E con browser.
- Framework-agnóstica: soporta Playwright (único browser integration actual), Jest, Vitest.
- Mecanismo: levanta HA como subprocess Python (no Docker), puerto dinámico, onboarding via REST API.
- Repo: https://github.com/rianadon/hass-taste-test
- ⚠️ CAVEAT: El repo tiene actividad baja (último commit relevante 2021-2023). Hay que verificar compatibilidad con versiones recientes de HA.
- 🔍 PENDIENTE: ¿Funciona con HA 2024.x/2025.x? ¿Hay alternativas más activas?
- ✅ NUEVO: El agente actual SÍ usa hass-taste-test correctamente en global.setup.ts — el problema no está en cómo se levanta HA, sino en cómo se coordina auth y tests.

**Alternativas investigadas y descartadas:**
- `galata` (JupyterLab) ❌ — específico de JupyterLab, no aplica
- `pytest-homeassistant` ❌ — solo Python, sin browser
- Playwright puro sin `hass-taste-test` ⚠️ — viable pero requiere gestionar manualmente el levantado de HA, onboarding y puerto dinámico. Mayor complejidad.

### 1.2 ¿Debería el agente descubrir esto autónomamente?

💬 **En debate:**  
La hipótesis es que en la fase de research el agente debería:
1. Leer `global.setup.ts` del codebase → ver que usa `hass-taste-test` → entender el mecanismo
2. Usar MCP Playwright para navegar a la documentación de la versión concreta de HA del proyecto
3. Navegar el código fuente del componente antes de escribir cualquier test

**Problema identificado:** El skill `ha-e2e-testing` (cargado por el agente) tiene una instrucción contradictoria: prohíbe usar `hass-taste-test` (línea 204: "No importar hass-taste-test") pero el codebase ya lo usa. El agente siguió el codebase, lo cual fue correcto, pero la skill introduce ruido.

**Acción pendiente:** revisar `ha-e2e-testing.skill.md` — la prohibición puede estar desactualizada o mal redactada.

---

## Bloque 2 — El login form de HA no es un form HTML estándar

### 2.1 Realidad del onboarding/login de HA

✅ **Confirmado por investigación:**  
El flujo de login de Home Assistant NO es un formulario HTML estándar. Es un Web Component (`<ha-onboarding>` / login flow de LitElement) con múltiples pasos:
1. Step 1: Onboarding inicial (solo primera vez) — crea usuario admin
2. Step 2: Login form posterior — `<ha-auth-flow>` con campos de username/password

✅ **Confirmado también por la salida del agente:** `auth.setup.ts` hace el onboarding via browser con múltiples steps (hasta 10 pasos en el Config Flow), lo que confirma que el flujo no es un simple form.

**El problema con `playwright-session.skill.md → authMode: form`:**  
`authMode: form` asume `<input type="text">` y `<input type="password">` accesibles directamente vía snapshot de accesibilidad. El login de HA usa shadow DOM de LitElement.

### 2.2 ¿Hay algo definido/probado para el login de HA con Playwright?

✅ **hass-taste-test gestiona el onboarding via REST API**, no via browser:  
- Llama a `/api/onboarding/users` para crear el usuario inicial
- Llama a `/auth/token` para obtener tokens
- El browser solo se usa DESPUÉS del onboarding, con la sesión ya autenticada
- Esto es la práctica correcta: no simular el login en el browser, obtener el token por API y cargarlo como cookie/storage-state

⚠️ **Pero el agente NO usa este patrón.** `auth.setup.ts` hace el onboarding COMPLETO via browser (10 pasos), incluyendo el login form. Esto funciona pero es frágil — cualquier cambio en el UI de onboarding rompe el setup.

🔍 **PENDIENTE:** Verificar exactamente cómo `hass-taste-test` inyecta el token en el browser context — ¿cookie? ¿localStorage? ¿storage-state? Y comparar con lo que hace `auth.setup.ts`.

### 2.3 Implicación para `playwright-session.skill.md`

💬 **Propuesta en debate:**  
No añadir un `authMode: ha-onboarding` — eso sería demasiado acoplado a HA.  
En cambio, documentar en `playwright-session.skill.md` que para apps con Web Components / shadow DOM, `authMode: form` puede fallar y la alternativa preferida es obtener el token por API y usar `authMode: token` o `authMode: storage-state`.

Esto es genérico (aplica a cualquier app LitElement/shadow DOM) y no está acoplado a HA.

---

## Bloque 3 — `goto` vs `click` en navegación Playwright

### 3.1 ¿Cuándo usar `page.goto()` vs `locator.click()`?

✅ **Documentación oficial Playwright (microsoft/playwright/docs/navigations.md):**

| Situación | Método recomendado | Razón |
|---|---|---|
| Navegación inicial / URL directa conocida | `page.goto(url)` | No hay elemento en el que hacer click, es la entrada al flujo |
| Navegación causada por interacción del usuario (link, botón) | `locator.click()` | Auto-waits: espera a que el elemento sea visible, estable, habilitado y reciba eventos. Luego espera a que la navegación complete. |
| Navegar a un panel HA después del Config Flow | `locator.click()` **si existe el link en el sidebar** | Simula el comportamiento real del usuario |
| Navegar a un panel HA cuando la URL ya se conoce y no hay link accesible | `page.goto(url)` | Aceptable como último recurso |

**El problema del agente:** usó `page.goto()` para navegar al panel sin verificar que el panel respondía correctamente.

### 3.2 Implicación para el skill

💬 Esta regla debería vivir en `playwright-session.skill.md → Stable State Detection` como un caso adicional: **verificar que el target de la navegación existe antes o después del goto**. No es una regla HA-específica.

---

## Bloque 4 — La URL del panel es un contrato implícito

### 4.1 Cómo se construye la URL del panel

✅ **Confirmado por lectura de `panel.py`:**
```python
frontend_url_path = f"{PANEL_URL_PREFIX}-{vehicle_id}"
vehicle_id = vehicle_name.lower().replace(" ", "_")
# vehicle_name="Coche2" → vehicle_id="coche2" → path="ev-trip-planner-coche2"
```

✅ **Confirmado también por salida del agente:**
```
[Config] Panel URL would be: http://127.0.0.1:8507/ev-trip-planner-coche2
```
El agente usó la URL correcta — el bug no era en la URL del panel sino en que el panel puede no estar accesible cuando los chromium tests corren.

### 4.2 Fix mínimo propuesto

Añadir al `requirements.md` del proyecto:
```markdown
## Panel URL Contract
- Panel URL pattern: `ev-trip-planner-{vehicle_id}`
- vehicle_id derivation: `vehicle_name.lower().replace(' ', '_')`
- Example: vehicle "Coche2" → `/ev-trip-planner-coche2`
- Source of truth: `custom_components/ev_trip_planner/panel.py → async_register_panel`
```

---

## Bloque 5 — ¿Demasiados skills? El problema de la deuda de texto

### 5.1 La trampa de resolver cada problema con un nuevo skill

💬 **Preocupación válida planteada en sesión:**  
El patrón de "cada problema → nuevo skill/gate/texto" crea:
- Prompts gigantes que el agente no lee completo
- Skills muy acopladas a casos de uso específicos (anti-reutilización)
- Deuda de mantenimiento: cuando HA cambia, los skills quedan desactualizados

**Principio propuesto (en debate):**  
> Antes de crear un skill nuevo, preguntarse: ¿esto es un dato específico del proyecto (→ va a `requirements.md`) o es una regla general reutilizable (→ puede ir en un skill existente como 1-2 líneas)?

### 5.2 El agente como investigador autónomo

💬 **Hipótesis en debate:**  
La solución más robusta no es documentar todo de antemano, sino que el agente, en la fase de research, **use MCP Playwright para navegar a la documentación real** de la versión concreta que está testeando.

✅ **Esto ya está parcialmente soportado** — el agente puede usar MCP tools durante research. El gap es que nadie le dijo explícitamente que DEBE hacerlo antes de escribir tests de navegación.

**Fix mínimo propuesto para `phase-rules.md → Phase 3`:**
```markdown
> Before writing any test that navigates to a URL, locate in source code 
> how that URL is constructed. Do not assume URLs from requirements.md.
```

---

## Bloque 6 — Bug arquitectural de la sesión en vivo: puerto stale entre runs

### 6.1 El problema real que el agente aún no ha resuelto

🔍 **Hipótesis a confirmar (pendiente de leer global.setup.ts y global.teardown.ts en detalle):**

**Escenario A — globalTeardown para HA entre setup y chromium:**
```
globalSetup  → HA en :8507
auth.setup   → panel-url.txt(:8507) + user.json(tokens:8507)
globalTeardown → [¿para HA?] + borra server-info.json
chromium     → lee panel-url.txt(:8507) → HA ya no existe → timeout
```

**Escenario B — globalSetup corre dos veces (una por project):**
```
[setup project]
globalSetup  → HA en :8507 → server-info.json(:8507)
auth.setup   → panel-url.txt(:8507) + user.json(:8507)
globalTeardown → para HA:8507, borra server-info.json

[chromium project]
globalSetup  → HA NUEVO en :8508 → server-info.json(:8508)
             → panel-url.txt sigue en :8507 (stale)
             → user.json sigue en :8507 (stale)
chromium     → usa panel-url.txt(:8507) + user.json(:8507) → fallo silencioso
```

**Si se confirma el Escenario B**, el fix correcto es hacer que los chromium tests lean la URL del panel desde server-info.json (que refleja el HA vivo en ese momento) en lugar de desde panel-url.txt (que puede ser stale). O mejor: que auth.setup guarde el panel URL en el storageState mismo, o que los tests lo deriven en runtime a partir de server-info.json.

### 6.2 ¿El agente puede resolver esto solo?

💬 El agente está cerca de diagnosticarlo. En su última iteración ya identificó:
- Que server-info.json se borra entre runs
- Que los tokens tienen haUrl embebida
- Que puede haber un mismatch de puertos

Faltan los pasos:
1. Leer global.teardown.ts exacto para confirmar si para HA o solo borra el fichero
2. Verificar si globalSetup corre una o dos veces con múltiples projects
3. Proponer el fix arquitectural correcto

---

## Pendientes de investigar

- [ ] ¿`hass-taste-test` inyecta el token como cookie, localStorage o storage-state? Leer código fuente.
- [ ] ¿Hay alguna librería más activa/mantenida que `hass-taste-test` en 2025?
- [ ] ¿El onboarding REST API de HA ha cambiado en versiones 2024.x/2025.x?
- [ ] Revisar `ha-e2e-testing.skill.md` línea 204 — la prohibición de `hass-taste-test` ¿está justificada o es un error?
- [ ] ¿El skill `playwright-session.skill.md` necesita un authMode específico para shadow DOM / Web Components?
- [ ] Confirmar si globalTeardown para el proceso HA o solo borra server-info.json (leer global.teardown.ts)
- [ ] Confirmar si globalSetup corre una o dos veces cuando hay múltiples projects en playwright.config.ts
- [ ] ¿El Escenario A o Escenario B del Bloque 6 es el correcto?

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Permitir que el agente continúe intentando arreglar los tests (en lugar de borrar y empezar desde 0) | 2026-04-03 | El agente encontró y arregló el bug de storageState. Vale la pena ver hasta dónde llega antes de decidir si resetear. |
| D2 | Fix mínimo: añadir Panel URL Contract a `requirements.md` del proyecto | 2026-04-03 | Dato específico del proyecto, no del sistema. No merece un skill. |
| D3 | Fix mínimo: añadir nota de 2 líneas a `phase-rules.md → GREENFIELD Phase 3` | 2026-04-03 | Regla genérica, aplica a todos los futuros GREENFIELD. 2 líneas, no un skill. |
| D4 | NO crear skill `ha-panel-contract.skill.md` | 2026-04-03 | Demasiado acoplado al caso de uso. Ver D2. |
| D5 | NO borrar tests todavía — esperar a que el agente resuelva el bug de puerto stale | 2026-04-03 | El agente está cerca. Si falla, entonces resetear. |

---

*Última actualización: 2026-04-03 02:40 CEST — sesión en vivo del agente*
