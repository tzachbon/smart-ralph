# E2E HA Findings — Pizarra de Investigación Forense

> Rama de trabajo: `research/e2e-ha-findings`  
> **Objetivo de esta investigación:** Reducir el gap entre agentes escribiendo tests malos y tests correctos para HA custom components. Encontrar qué le falta al agente (información, metodología, o ambas) y cómo arreglarlo de forma minimal y reutilizable.  
> **No estamos arreglando el fork.** Estamos analizando por qué el agente falló y qué cambiar en el sistema para que no vuelva a fallar.

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

Hay dos posibles respuestas:

**A) Le falta información** — no sabe cómo funciona HA por dentro (los dos sistemas de routing, que los paneles custom son rutas estáticas, que el storageState no basta sin WebSocket auth). Nadie se lo dijo y no lo puede inferir del código solo.

**B) Le falta metodología** — no tiene un protocolo de diagnóstico que le diga "antes de escribir un test de navegación, experimenta manualmente lo que pasa al navegar sin auth". Sabe las herramientas pero no el orden en que usarlas.

💬 **Nuestra hipótesis de trabajo:** Es principalmente **B**, con un componente de A. La información sobre HA está disponible en el código fuente del proyecto y en la documentación pública, pero el agente no tiene instrucción de buscarla en ese orden antes de actuar. Le faltaba el paso de "experimento manual antes de escribir tests".

**Por qué esto importa para el sistema:** Si es B, el fix no es documentar más sobre HA — es añadir un paso de research experimental a `phase-rules.md` que aplique a TODOS los proyectos.

---

## Plan de investigación: orden y estado

| # | Pregunta | Estado | Bloque |
|---|---|---|---|
| P1 | ¿Cómo funciona realmente el auth de HA con Playwright? ¿storageState es suficiente? | ✅ Resuelto | Bloque 2 + 7 |
| P2 | ¿Por qué los paneles custom de HA devuelven 404 sin auth en lugar de redirigir? | ✅ Resuelto | Bloque 7 |
| P3 | ¿Por qué `goto` directo a panel falla aunque estemos autenticados? | ✅ Resuelto | Bloque 7 |
| P4 | ¿El bug de `storageState` no guardado era el único bug o había más? | ✅ Resuelto: había más | Bloque 0 |
| P5 | ¿El agente tenía la información disponible o realmente no podía saberlo? | 🔍 Pendiente | Bloque 8 |
| P6 | ¿Qué cambio minimal en el sistema habría evitado todos estos fallos? | 💬 En debate | Bloque 9 |
| P7 | ¿El agente sin empujón del usuario habría llegado a la hipótesis del 404/sidebar? | 🔍 Pendiente | Bloque 8 |
| P8 | ¿Por qué el agente sigue fallando incluso después de conocer la causa raíz del 404? | ✅ Resuelto | Bloque 10 |

---

## Bloque 0 — Timeline de la sesión en vivo

> Cronología de lo que el agente hizo y descubrió para poder identificar cuándo falló y por qué.

**Ronda 1:** El agente encuentra que `auth.setup.ts` no guarda `storageState`. Fix aplicado. 11 tests siguen fallando.  
**Ronda 2:** El agente teoriza sobre workers en paralelo, conflictos de puertos — **hipótesis incorrectas**, tiempo perdido.  
**Ronda 3:** El usuario da el empújón: *"quizás cuando haces goto sin estar autenticado, HA te da 404 en lugar de redirigir"*.  
**Ronda 4:** El agente experimenta. Confirma la hipótesis. Lanza agentes paralelos de research. Llega a la causa raíz.  
**Ronda 5:** El agente cambia a `navigateViaSidebar()` en todos los tests. Sigue fallando. 31/32 tests fallan ahora en el mismo punto: `sidebar.waitFor()` timeout.  
**Ronda 6 (nueva):** El agente diagnostica erróneamente que hay **dos instancias HA** creadas (una por proyecto de Playwright). Hipótesis incorrecta — dedica tiempo a analizar diferencias de puerto entre runs distintos.

**Observación crítica nueva (2026-04-03):** El agente llegó a la causa raíz del 404 pero **tiene un segundo bug de arquitectura** que le impide avanzar. Ver Bloque 10.

---

## Bloque 10 — ✅ CONFIRMADO: Segundo bug — `baseURL` evaluado antes de `globalSetup`

> Este es el nuevo hallazgo que explica por qué el agente sigue fallando incluso usando `navigateViaSidebar()`.

### 10.1 El bug

En `playwright.config.ts` del fork:

```typescript
// playwright.config.ts — se ejecuta al CARGAR el fichero
baseURL: (() => {
  const serverInfoPath = path.join(authDir, 'server-info.json');
  try {
    const serverInfo = JSON.parse(fs.readFileSync(serverInfoPath, 'utf-8'));
    return new URL(serverInfo.link).origin;  // ← lee el fichero AQUÍ
  } catch (error) {
    console.warn('Could not read server-info.json, using default localhost:8123');
    return 'http://localhost:8123';           // ← FALLBACK cuando no existe
  }
})()
```

Esta IIFE (función autoejecutable) se ejecuta **cuando Node.js carga `playwright.config.ts`** — antes de que `globalSetup` arranque el servidor HA efímero. En ese momento, `server-info.json` no existe todavía → `baseURL` cae a `http://localhost:8123`.

Después, `globalSetup` arranca HA en un puerto dinámico (ej: `8528`), escribe `server-info.json`, y guarda tokens válidos para `8528`. Pero ya es tarde: todos los tests tienen `baseURL = localhost:8123` en memoria.

### 10.2 Evidencia directa de los logs

```
Could not read server-info.json, using default localhost:8123   ← IIFE al cargar config
...
[GlobalTeardown] Cleaning up server at: http://127.0.0.1:8528/ ← puerto real del servidor
31 failed                                                       ← todos los tests
```

El servidor real estaba en `8528`. Los tests navegaban a `localhost:8123/dashboard` → 404 → sidebar nunca aparece → timeout.

### 10.3 Por qué la hipótesis de "dos instancias" del agente era incorrecta

❌ El `globalSetup` en `playwright.config.ts` es **global** (`globalSetup: './tests/global.setup.ts'`) — corre **una sola vez** para toda la sesión de Playwright. No hay dos instancias HA. El agente confundió puertos de **ejecuciones distintas** del comando como si fueran instancias simultáneas.

### 10.4 Consecuencia forense: este es un patrón nuevo de fallo del agente

Este bug es diferente al anterior. El anterior (404 en panel URL) era desconocimiento del comportamiento de HA. **Este es un malentendido del ciclo de vida de Playwright**: el agente no sabe que `use.baseURL` del config se evalúa antes de `globalSetup`.

**Esto es nuevo para añadir al análisis forense:** El agente conoce Playwright bien en lo superficial (sabe usar `page.goto`, `storageState`, etc.) pero no conoce el orden preciso de evaluación del ciclo de vida (config load → globalSetup → project setup → tests).

### 10.5 Implicación para el sistema (preliminary)

⚠️ **Hipótesis pendiente de debate en Bloque 9:**

Esto apunta a **Fix A** en Bloque 9 — regla metodológica — pero requiere un refinamiento:

> *"Para proyectos con servidor efímero de puerto dinámico: NO uses IIFEs en `baseURL`. Usa `process.env` seteado desde `globalSetup`, o lee el fichero de info en runtime dentro de cada método de navegación."*

¿Es esto información específica de Playwright que debería estar en `playwright-session.skill.md`? ¿O es un principio más general sobre "no leas estado dinámico en tiempo de carga de configuración"? Pendiente de debate.

---

## Bloque 7 — ✅ CONFIRMADO: Los dos sistemas de routing de HA (hallazgo clave)

> Esto es el descubrimiento más importante de la sesión. El agente lo confirmó experimentalmente.

### 7.1 Experimento del agente

| Navegación | Sin auth | Con auth |
|---|---|---|
| `/` | → redirect a `/auth/authorize` (login) | ✅ Carga |
| `/ev-trip-planner-coche2` | → **404** (sin redirect) | ✅ Panel carga |
| `/ev-trip-planner-coche2` con `storageState` | Panel carga pero **contenido no renderiza** | — |

### 7.2 Por qué ocurre esto

✅ **Confirmado por análisis del código fuente (`panel.py`):**

Home Assistant tiene **dos sistemas de frontend completamente distintos**:

| Sistema | URLs | Manejo de auth |
|---|---|---|
| React Router (SPA) | `/`, `/config`, `/lovelace`, etc. | Middleware de auth activo → redirect a login |
| Custom Panels (rutas estáticas) | `/ev-trip-planner-{vehicle_id}` | **Sin middleware** → 404 si no registrado o sin auth |

Los paneles custom se registran via `panel_custom.async_register_panel()` como **rutas de archivos estáticos HTTP**. No pasan por el frontend de React. Por eso no hay redirect al login — directamente no existe el recurso.

### 7.3 Por qué `storageState` solo no es suficiente

✅ **Confirmado:**  
El JavaScript del panel necesita un objeto `hass` válido que viene de una **conexión WebSocket autenticada**. El `storageState` carga las cookies del browser, pero sin el flujo de login completo el panel no tiene el contexto `hass` inicializado. El HTML carga, el JS carga, pero el web component queda vacío.

### 7.4 La consecuencia para los tests

✅ **Causa raíz de los tests fallidos (primera capa):**

Los tests llaman a `navigateDirect()` → `page.goto('/ev-trip-planner-coche2')` directamente.  
Incluso con `storageState` correcto, el panel no renderiza su contenido porque no hay WebSocket auth.  
Los 4 tests que pasan tienen lógica condicional que hace early return cuando el panel no responde — enmascaraban el problema.

**Fix correcto (primera capa):** usar `navigateViaSidebar()` en lugar de `navigateDirect()`. ✅ Aplicado por el agente.

**Pero hay una segunda capa (ver Bloque 10):** incluso con `navigateViaSidebar()`, los tests siguen fallando porque `baseURL` apunta al puerto incorrecto.

### 7.5 Bug secundario confirmado: case mismatch en `DEFAULT_PANEL_URL`

```typescript
// trips.page.ts — URL incorrecta (capital C)
static readonly DEFAULT_PANEL_URL = 'http://127.0.0.1:8123/ev-trip-planner-Coche2';

// auth.setup.ts — URL correcta (lowercase)
const vehicleId = vehicleName.toLowerCase(); // "coche2"
await page.goto(`${baseUrl}/ev-trip-planner-${vehicleId}`);
// Resultado: /ev-trip-planner-coche2
```

Los tests leen de `panel-url.txt` (correcto) pero el fallback usa `DEFAULT_PANEL_URL` con `Coche2` — URL que nunca existió.

⚠️ **Nota:** Este bug puede ya estar corregido en la versión actual de `trips.page.ts` (la lectura del código muestra `coche2` en minúsculas). Pendiente de verificar si el fallback todavía es relevante.

---

## Bloque 8 — ¿Podía el agente haber llegado solo? (A investigar)

> Esta es la pregunta forense más importante. La respuesta determina qué hay que cambiar.

### 8.1 La información estaba disponible

⚠️ **Todo lo necesario para diagnosticar estaba en el código:**
- `panel.py` tiene la llamada a `hass.http.register_static_path()` — si la leen, el comportamiento de 404 es deducible
- `trips.page.ts` tiene `navigateViaSidebar()` **ya implementado** — el agente no lo estaba usando
- `auth.setup.ts` hace login completo y navega al panel via `goto`, lo que significa que el pattern correcto era usar sidebar en los tests, no `goto`
- `playwright.config.ts` tiene la IIFE visiblemente — si el agente entendiera el ciclo de vida de Playwright, el bug de `baseURL` sería deducible

### 8.2 Pero el agente no leyó el código en el orden correcto

🔍 **A confirmar:** ¿En qué momento del proceso el agente leyó `panel.py`? ¿Lo leyó durante Phase 1 (research) o solo cuando depuraba fallos?

**Hipótesis:** El agente leyó los ficheros de test que ya existían (`trips.spec.ts`, `trips.page.ts`) pero no leyó el código del componente HA (`panel.py`, `__init__.py`) antes de empezar a depurar. La diferencia entre "leer los tests" y "leer el sistema bajo test" es el gap.

### 8.3 El empújón del usuario fue una hipótesis, no un dato

**Dato clave:** El usuario no le dijo la respuesta. Le dio **una hipótesis a experimentar**: *"quizás HA da 404 sin auth en lugar de redirigir"*. El agente la experimentó y la confirmó.

Esto significa que lo que le faltó al agente no era la hipótesis (podía haberla generado) sino el **gatillo para cambiar de táctica**: parar de depurar código y empezar a experimentar con el sistema en vivo.

**Implicación para el sistema:** Lo que hay que añadir a `phase-rules.md` no es información sobre HA. Es una regla como:
> *"Si llevas más de 2 rondas de depuración sin resolver, para y experimenta manualmente con el sistema: navega sin auth, navega con auth, observa qué pasa. Luego vuelve al código."*

### 8.4 Nuevo dato: el agente tampoco conoce el ciclo de vida de Playwright

🔍 **Observación nueva (Bloque 10):** El agente no detectó el bug de la IIFE en `playwright.config.ts` aunque la tenía delante. Esto sugiere que no tiene claro que `use.baseURL` se evalúa en tiempo de carga del config, antes de `globalSetup`.

**Pregunta adicional para P5:** ¿Es el ciclo de vida de Playwright (config load → globalSetup → project setup → tests) algo que debería estar documentado en `playwright-session.skill.md`? ¿O es conocimiento implícito que esperamos del agente?

---

## Bloque 9 — ¿Qué cambio minimal habría evitado todo esto? (En debate)

> El objetivo: cambios con el máximo impacto y el mínimo texto añadido al sistema.

### 9.1 Fix A: Una regla en `phase-rules.md` (impacto alto, costo bajo)

💬 **Propuesta:**

En la sección GREENFIELD Phase 1 (Research), añadir:
```markdown
### Para proyectos con servidor de prueba (HA, backends efímeros, etc.)
Antes de escribir cualquier test de navegación:
1. Arranca el servidor manualmente
2. Navega sin auth a las URLs objetivo — observa si redirige o da 404
3. Navega con auth a las mismas URLs — observa el comportamiento real
4. SOLO entonces escribe los tests basándote en lo que observaste
No asumas que el comportamiento de auth es estándar (redirect al login).
```

**Por qué este fix:** Habría llevado al agente directamente al experimento que confirmó la causa raíz, sin rondas de depuración incorrectas.

### 9.2 Fix B: Una regla de "leer el sistema bajo test" en Phase 1 (impacto alto, costo bajo)

💬 **Propuesta:**

En Phase 1, añadir explícitamente:
```markdown
Lee el código del SISTEMA BAJO TEST, no solo los ficheros de test existentes.
Para HA: lee panel.py, __init__.py, config_flow.py antes de escribir tests de navegación.
Busca: ¿cómo se registran las URLs? ¿qué tipo de auth usan? ¿hay rutas estáticas vs dinámicas?
```

### 9.3 Fix C: Documentar el patrón HA en `ha-e2e-testing.skill.md` (impacto medio, costo medio)

💬 **En debate.** Añadir a la skill:
```markdown
## HA Panel URL Auth Behavior
- Custom panels return 404 when unauthenticated (no redirect to login)
- StorageState alone is insufficient — panel needs WebSocket auth (hass object)
- ALWAYS use sidebar navigation for panel tests, NEVER page.goto() to panel URL
- A 404 on a panel URL = integration not installed or panel not registered (not auth problem)
```

**Debate:** ¿Esto es información sobre HA específica o es un principio general sobre sistemas con auth no-estándar? Si es lo segundo, debería ir en `playwright-session.skill.md` de forma genérica.

### 9.4 Fix D (nuevo): Documentar el ciclo de vida de Playwright en `playwright-session.skill.md`

💬 **Propuesta nueva emergida del Bloque 10:**

```markdown
## Ciclo de vida de Playwright: orden de evaluación
1. `playwright.config.ts` se carga (IIFEs y expresiones en `use.*` se evalúan AQUÍ)
2. `globalSetup` corre
3. Project `setup` corre
4. Tests del proyecto principal corren
5. `globalTeardown` corre

⚠️ NUNCA leas ficheros dinámicos (server-info.json, puertos, etc.) en IIFEs dentro del config.
Usa `process.env` seteado desde globalSetup, o lee el fichero en runtime dentro de cada método.
```

**Impacto:** Habría evitado el bug del Bloque 10 directamente. Costo bajo (4-5 líneas en skill existente).

### 9.5 Lo que NO haríamos

- ❌ Crear un skill `ha-panel-url-auth.skill.md` — demasiado acoplado
- ❌ Documentar el comportamiento de cada versión de HA — deuda de mantenimiento
- ❌ Añadir más gates/verificaciones al proceso — ya hay demasiados

---

## Bloque 1 — Ecosistema de testing HA

**Unit/Integration (Python):** ✅ Solo `pytest` + `pytest-homeassistant-custom-component`. Sin browser.

**E2E con browser:** `hass-taste-test` ✅ — de facto estándar. Levanta HA como subprocess Python, puerto dinámico, onboarding via REST API. El agente lo usa correctamente en `global.setup.ts`.

**Observación nueva:** `ha-e2e-testing.skill.md` tiene en línea 204 una instrucción que prohíbe usar `hass-taste-test`, contradiciendo el codebase. 🔍 Revisar.

---

## Bloque 2 — Auth de HA con Playwright

✅ **`hass-taste-test` hace onboarding via REST API** (no via browser). El browser entra ya con sesión establecida.

⚠️ **El agente en cambio hace onboarding completo via browser** (10 pasos). Funciona pero es frágil.

✅ **Confirmado por experimento:** `storageState` solo no basta para paneles custom — se necesita WebSocket auth (objeto `hass`). Ver Bloque 7.

---

## Bloque 3 — `goto` vs `click` en navegación Playwright

✅ **Regla clara emergida de la investigación:**

> Para HA custom panels: **NUNCA `page.goto('/panel-url')`**. Siempre `navigateViaSidebar()`.  
> Para cualquier app: si un recurso tiene auth no-estándar, experimentar antes de asumir que `goto` funciona.

---

## Bloque 4 — URL del panel como contrato implícito

✅ Panel URL: `ev-trip-planner-{vehicle_name.lower().replace(' ', '_')}`  
❌ `DEFAULT_PANEL_URL` en `trips.page.ts` usaba `Coche2` (capital) — bug confirmado.  
⚠️ Posiblemente ya corregido en la versión actual del código — pendiente verificar.

---

## Bloque 5 — Deuda de texto y skills

💬 **Principio en debate:** Antes de crear un skill nuevo, preguntar: ¿dato del proyecto (→ `requirements.md`) o regla genérica (→ 2 líneas en skill existente)?  
La sesión de hoy refuerza este principio: el fix correcto probablemente sea 3-4 líneas en `phase-rules.md`, no un nuevo skill.

---

## Pendientes de investigar

- [ ] ¿En qué momento del proceso el agente leyó `panel.py`? ¿Estaba en su contexto durante Phase 1? (P5)
- [ ] ¿El agente habría generado la hipótesis del 404 sin el empújón del usuario? (P7)
- [ ] Revisar `ha-e2e-testing.skill.md` línea 204 — prohibición de `hass-taste-test`
- [ ] Confirmar si globalTeardown para el proceso HA o solo borra server-info.json
- [ ] Validar qué fix del Bloque 9 tiene mejor ratio impacto/costo (Fix A + Fix D parecen los más prometedores)
- [ ] ¿El patrón de auth no-estándar (storageState insuficiente) es algo que debería vivir en `playwright-session.skill.md` de forma genérica?
- [ ] ¿El ciclo de vida de Playwright (config load → globalSetup → tests) debería estar en `playwright-session.skill.md`? (nuevo, emergido de Bloque 10)
- [ ] Verificar si `DEFAULT_PANEL_URL` con `Coche2` sigue siendo un bug activo o ya fue corregido

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Permitir que el agente continúe (en lugar de borrar tests) | 2026-04-03 | El agente llegó a la causa raíz. Vale la pena ver si puede arreglarlo. |
| D2 | Fix mínimo: Panel URL Contract a `requirements.md` del proyecto | 2026-04-03 | Dato del proyecto, no del sistema. |
| D3 | Fix mínimo: 2 líneas en `phase-rules.md → GREENFIELD Phase 3` sobre verificar URLs antes de escribir tests | 2026-04-03 | Regla genérica. |
| D4 | NO crear `ha-panel-contract.skill.md` | 2026-04-03 | Demasiado acoplado. |
| D5 | NO borrar tests todavía | 2026-04-03 | El agente está cerca. |
| D6 | El fix principal probablemente es una regla de "experimenta antes de depurar" en `phase-rules.md` | 2026-04-03 | La sesión confirmó que lo que le faltó fue el gatillo metodológico, no la información. |
| D7 | Añadir Fix D como candidato: ciclo de vida de Playwright en `playwright-session.skill.md` | 2026-04-03 | El agente no detectó el bug de IIFE aunque tenía el código delante. Conocimiento implícito que hay que hacer explícito. |

---

*Última actualización: 2026-04-03 01:29 CEST — Bloque 10 añadido: bug baseURL IIFE + hipótesis dos instancias HA descartada*
