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

## PLAN DE PRUEBA ACTIVO — Pipeline paso a paso desde `/start`

> **Contexto:** El proyecto ha sido limpiado — no hay specs e2e ni ficheros de test previos.  
> El agente parte de cero. Seguimos la pipeline en orden natural: `/start` → product-manager → spec-executor → qa-engineer.  
> En cada paso: ejecutamos, observamos, anotamos aquí, comparamos con lo esperado.

### Foco de la prueba

No estamos testeando si el agente "pasa los tests". Estamos testeando si el agente:
1. **Lee el sistema bajo test antes de actuar** (¿lee `panel.py`? ¿`__init__.py`?)
2. **Experimenta antes de asumir** (¿navega manualmente antes de escribir tests de navegación?)
3. **Conoce el ciclo de vida de Playwright** (¿monta `baseURL` de forma segura con puertos dinámicos?)
4. **Emite las señales correctas** (`VERIFICATION_PASS/FAIL/DEGRADED`) para que el hook actúe bien

### Tabla de seguimiento de pasos

| Paso | Comando/Acción | Estado | Observaciones |
|---|---|---|---|
| 1 | `/start` — prompt inicial | 🔍 Pendiente | |
| 2 | product-manager genera spec | 🔍 Pendiente | |
| 3 | spec-executor Phase 1 (research) | 🔍 Pendiente | ¿Lee `panel.py`? |
| 4 | spec-executor Phase 2 (scaffold) | 🔍 Pendiente | ¿`baseURL` seguro? |
| 5 | spec-executor Phase 3 (implement) | 🔍 Pendiente | ¿Usa `navigateViaSidebar`? |
| 6 | qa-engineer verifica | 🔍 Pendiente | ¿Emite señal correcta? |
| 7 | stop-watcher reacciona | 🔍 Pendiente | ¿Trata DEGRADED bien? |

### Prompt inicial para `/start` (Paso 1)

```
Quiero añadir tests e2e al componente ev_trip_planner.
El componente es un custom panel de Home Assistant.
Los tests deben cubrir el flujo principal: abrir el panel, planificar un viaje, ver el resultado.
```

> **Por qué este prompt:** Es intencionalmente escueto — no le damos información sobre cómo funciona HA, ni sobre `navigateViaSidebar`, ni sobre el ciclo de vida de Playwright. Es una prueba de caja negra: el agente debe descubrir esas cosas por sí solo durante Phase 1 (research). Si las descubre, el sistema funciona. Si no, sabemos exactamente qué añadir y dónde.

---

## Plan de investigación original: estado actual

| # | Pregunta | Estado | Bloque |
|---|---|---|---|
| P1 | ¿Cómo funciona realmente el auth de HA con Playwright? ¿storageState es suficiente? | ✅ Resuelto | Bloque 2 + 7 |
| P2 | ¿Por qué los paneles custom de HA devuelven 404 sin auth en lugar de redirigir? | ✅ Resuelto | Bloque 7 |
| P3 | ¿Por qué `goto` directo a panel falla aunque estemos autenticados? | ✅ Resuelto | Bloque 7 |
| P4 | ¿El bug de `storageState` no guardado era el único bug o había más? | ✅ Resuelto: había más | Bloque 0 |
| P5 | ¿El agente tenía la información disponible o realmente no podía saberlo? | 🔍 A observar en prueba activa | Bloque 8 |
| P6 | ¿Qué cambio minimal en el sistema habría evitado todos estos fallos? | 💬 En debate | Bloque 9 |
| P7 | ¿El agente sin empujón del usuario habría llegado a la hipótesis del 404/sidebar? | 🔍 A observar en prueba activa | Bloque 8 |
| P8 | ¿Por qué el agente sigue fallando incluso después de conocer la causa raíz del 404? | ✅ Resuelto | Bloque 10 |

---

## Bloque 0 — Timeline de la sesión original (referencia)

> Cronología de lo que el agente hizo en la sesión anterior. Sirve de referencia para comparar con la prueba activa.

**Ronda 1:** El agente encuentra que `auth.setup.ts` no guarda `storageState`. Fix aplicado. 11 tests siguen fallando.  
**Ronda 2:** El agente teoriza sobre workers en paralelo, conflictos de puertos — **hipótesis incorrectas**, tiempo perdido.  
**Ronda 3:** El usuario da el empújón: *"quizás cuando haces goto sin estar autenticado, HA te da 404 en lugar de redirigir"*.  
**Ronda 4:** El agente experimenta. Confirma la hipótesis. Lanza agentes paralelos de research. Llega a la causa raíz.  
**Ronda 5:** El agente cambia a `navigateViaSidebar()` en todos los tests. Sigue fallando. 31/32 tests fallan ahora en el mismo punto: `sidebar.waitFor()` timeout.  
**Ronda 6:** El agente diagnostica erróneamente que hay **dos instancias HA**. Hipótesis incorrecta — tiempo perdido.

---

## Bloque 10 — ✅ CONFIRMADO: Segundo bug — `baseURL` evaluado antes de `globalSetup`

### 10.1 El bug

```typescript
// playwright.config.ts — IIFE se ejecuta al CARGAR el fichero, antes de globalSetup
baseURL: (() => {
  const serverInfoPath = path.join(authDir, 'server-info.json');
  try {
    const serverInfo = JSON.parse(fs.readFileSync(serverInfoPath, 'utf-8'));
    return new URL(serverInfo.link).origin;
  } catch (error) {
    console.warn('Could not read server-info.json, using default localhost:8123');
    return 'http://localhost:8123';  // ← SIEMPRE cae aquí en primera ejecución
  }
})()
```

Resultado: `baseURL = localhost:8123`, servidor real en puerto dinámico (ej: `8528`). 31/32 tests fallan.

### 10.2 Evidencia

```
Could not read server-info.json, using default localhost:8123   ← IIFE al cargar config
[GlobalTeardown] Cleaning up server at: http://127.0.0.1:8528/ ← puerto real
31 failed
```

### 10.3 Implicación para la prueba activa

🔍 **Pregunta clave del Paso 4:** ¿El agente, partiendo de cero, monta `baseURL` de forma segura (con `process.env`) o cae en el mismo patrón de IIFE?

---

## Bloque 7 — ✅ CONFIRMADO: Los dos sistemas de routing de HA

| Sistema | URLs | Manejo de auth |
|---|---|---|
| React Router (SPA) | `/`, `/config`, `/lovelace`, etc. | Middleware de auth → redirect a login |
| Custom Panels (rutas estáticas) | `/ev-trip-planner-{vehicle_id}` | Sin middleware → **404** si no auth |

**Regla emergida:** Para HA custom panels, NUNCA `page.goto('/panel-url')`. Siempre `navigateViaSidebar()`.

🔍 **Pregunta clave del Paso 3:** ¿El agente descubre esto leyendo `panel.py` durante Phase 1, o lo ignora y escribe tests con `goto` directo?

---

## Bloque 8 — ¿Podía el agente haber llegado solo?

### 8.3 El empújón fue una hipótesis, no un dato

Lo que le faltó al agente no era la hipótesis (podía generarla) sino el **gatillo para cambiar de táctica**: parar de depurar código y experimentar con el sistema en vivo.

**Implicación:** Añadir a `phase-rules.md`:
> *"Si llevas más de 2 rondas sin resolver, para y experimenta manualmente con el sistema."*

---

## Bloque 9 — Fixes candidatos (en debate)

| Fix | Dónde | Qué | Impacto | Costo |
|---|---|---|---|---|
| A | `phase-rules.md` Phase 1 | Experimenta antes de escribir tests para servidores efímeros | Alto | Bajo |
| B | `phase-rules.md` Phase 1 | Lee el sistema bajo test, no solo los tests existentes | Alto | Bajo |
| C | `ha-e2e-testing.skill.md` | Comportamiento auth HA: 404 vs redirect, sidebar nav obligatoria | Medio | Medio |
| D | `playwright-session.skill.md` | Ciclo de vida Playwright: config load → globalSetup → tests. No IIFEs en baseURL | Alto | Bajo |

**Observación nueva emergida del Bloque 10:**  
> *"Para proyectos con servidor efímero de puerto dinámico: NO uses IIFEs en `baseURL`. Usa `process.env` seteado desde `globalSetup`."*

---

## Bloque 1 — Ecosistema de testing HA

**Unit/Integration (Python):** `pytest` + `pytest-homeassistant-custom-component`. Sin browser.  
**E2E con browser:** `hass-taste-test` — de facto estándar. Puerto dinámico, onboarding via REST API.  
⚠️ `ha-e2e-testing.skill.md` línea 204 prohíbe usar `hass-taste-test` — contradice el codebase. 🔍 Revisar.

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Prueba nueva desde `/start` con proyecto limpio | 2026-04-03 | Los tests e2e anteriores fueron borrados. Empezamos desde cero para observar el comportamiento completo de la pipeline. |
| D2 | Prompt inicial intencionalmente escueto | 2026-04-03 | Caja negra: el agente debe descubrir los patrones de HA por sí solo. |
| D3 | Fix mínimo: Panel URL Contract a `requirements.md` del proyecto | 2026-04-03 | Dato del proyecto, no del sistema. |
| D4 | Fix mínimo: 2 líneas en `phase-rules.md → GREENFIELD Phase 3` | 2026-04-03 | Regla genérica de verificación de URLs. |
| D5 | NO crear `ha-panel-contract.skill.md` | 2026-04-03 | Demasiado acoplado. |
| D6 | Fix principal: regla "experimenta antes de depurar" en `phase-rules.md` | 2026-04-03 | La sesión anterior confirmó que lo que faltó fue el gatillo metodológico. |
| D7 | Fix D candidato: ciclo de vida Playwright en `playwright-session.skill.md` | 2026-04-03 | Agente no detectó bug IIFE teniendo el código delante. |

---

*Última actualización: 2026-04-03 02:29 CEST — Nuevo plan de prueba activo desde `/start` con proyecto limpio*
