Aquí tienes el prompt listo para pegar en Claude Code:

***

```
/ralph-specum:define agent-chat-protocol

Quiero crear una nueva spec llamada **agent-chat-protocol**.

## Contexto del sistema actual

El sistema ralph-specum ya tiene:
- `spec-executor.md` — agente que implementa tareas secuencialmente
- `external-reviewer.md` — agente revisor paralelo que corre en una segunda sesión de Claude Code
- `task_review.md` — canal unidireccional: el revisor escribe FAIL/PASS/WARNING, el executor lo lee
- `.ralph-state.json` — estado compartido entre sesiones (filesystem)
- `.progress.md` — log de ejecución del executor

## El problema

La comunicación actual es de **un solo sentido**: el revisor escribe un FAIL con fix_hint, el executor lo ejecuta ciegamente. No hay canal para:
- Que el executor explique por qué tomó una decisión de arquitectura
- Que el revisor proponga alternativas y las debata antes de bloquear
- Que ambos lleguen a un acuerdo antes de que el revisor escriba el FAIL formal
- Que el revisor sea proactivo: detectar un patrón problemático emergente y avisar ANTES de que se convierta en FAIL
- Que cualquier otro agente (qa-engineer, architect-reviewer) también participe en el chat cuando está activo

## Lo que quiero construir

Un canal de **chat bidireccional en tiempo real** entre el executor (o cualquier agente implementador activo) y el reviewer, basado en filesystem igual que el sistema actual. El cambio mínimo sobre lo que ya existe.

### Comportamiento clave:
1. Ambos agentes leen y escriben en `specs/<specName>/chat.md` — un log append-only de conversación
2. El reviewer es **proactivo**: monitoriza el progreso y abre conversaciones sin esperar a que el executor pregunte
3. El executor puede **explicarse** antes de que se escriba un FAIL formal
4. Si hay debate activo, el executor **espera el ACK** del reviewer antes de continuar a la siguiente tarea
5. `task_review.md` sigue siendo el canal de **decisiones formales** (FAIL/PASS/WARNING). `chat.md` es el canal de **razonamiento y debate**
6. El humano puede leer `chat.md` en cualquier momento para entender qué está pasando entre los dos agentes
7. El reviewer puede demarcar tareas pero tiene que explicar en el chat por qué antes de hacerlo

### Archivos que cambian (mínimo impacto):
- **NUEVO**: `plugins/ralph-specum/templates/chat.md` — template del canal de chat
- **MODIFICA**: `plugins/ralph-specum/agents/spec-executor.md` — añadir `## Chat Protocol` 
- **MODIFICA**: `plugins/ralph-specum/agents/external-reviewer.md` — ampliar con protocolo de chat proactivo
- **OPCIONAL**: `plugins/ralph-specum/agents/interview-framework.md` — preguntar si se activa el chat al inicio de `/implement`

### Archivos que NO cambian:
- `task_review.md` template — sigue igual, sigue siendo el canal formal
- `.ralph-state.json` schema — como máximo añadir `chat.lastReadIndex` por agente
- Todos los demás agentes (architect-reviewer, qa-engineer, product-manager) — no tocar

## Lo que quiero del product-manager ahora

Genera `specs/agent-chat-protocol/requirements.md` con:
- Los functional requirements del chat (formato de mensaje, protocolo de lectura, protocolo de escritura, condiciones de espera, condiciones de ACK)
- Los behavioral requirements del reviewer proactivo (cuándo inicia conversación, cuándo espera antes de escribir FAIL, qué investiga antes de proponer alternativa)
- NFRs: compatibilidad con el sistema existente, sin dependencias externas, sin infraestructura, solo filesystem
- Referencia explícita a qué archivos existentes se modifican y cuáles son intocables
```

***

Ese prompt activa el flujo `define` del product-manager de ralph-specum directamente con todo el contexto necesario para que no te haga preguntas obvias y vaya al grano con los requirements.



YO TENIA MAS DUDAS Y HE INVESTIGADO MAS. SOBRE ESTO 

una cosa y no se define en internet ne la literatura de los laboratorios punteros que implementan estos protocolos de comunicación estrictos entre ellos. como deben comportarse o comunicarse. el plan como cuando usan los walies los humanos "cambio" para dar paso a la otra persona. a ver es un mal ejemplo. pero algo para que un agente sepa que el otro va a tomar en consideracion lo que ha dicho o no lo va a tomar en consideraicón y tambien cuando se sabe que hay por ejemplo un silencio necesario porque se estan haciendo cosas . o cuando romper el silencio por si ha pasado algo. osea cosas normales que sabemos y hacemos los humanos sin pensar cuando colaboramos pero que igual hay que instruir un poco a los agentes no ?

Y HE DESCUBIERTO ESTO 

Exacto, confirmas lo que sospechaba. Todos los protocolos existentes (A2A de Google, ACP de IBM, MCP de Anthropic) son protocolos de **coordinación de tareas y routing de mensajes**  — definen *qué* se envía y *a quién*, pero ninguno define el **comportamiento conversacional** entre agentes: cuándo hablar, cuándo escuchar, cuándo el silencio es normal, cuándo romperlo. Es un gap de investigación real. [getstream](https://getstream.io/blog/ai-agent-protocols/)

Lo que describes es lo que en lingüística se llama **floor management** — el conjunto de convenciones implícitas que regulan quién tiene "el turno de habla" en una conversación colaborativa. Los humanos lo hacemos sin pensar porque lo aprendimos. Los agentes no tienen eso. Hay que instruirlo explícitamente.

***

## El problema real: los 5 gaps que nadie documenta

### 1. Turn-taking — ¿quién tiene el turno?
En walkie-talkies usáis "cambio" porque el canal es half-duplex: físicamente no puedes hablar y escuchar a la vez. Los agentes en filesystem tienen el mismo problema — si los dos escriben al mismo tiempo en `chat.md`, hay append collision. Necesitan señales explícitas de turno.

### 2. Acknowledgment — ¿me has leído o no?
Cuando el executor escribe algo en el chat, no sabe si el reviewer lo ha leído, lo está procesando, o simplemente no ha llegado todavía a esa parte del archivo. Sin ACK explícito, el executor no sabe si puede continuar o si debe esperar. El silencio es ambiguo.

### 3. Silencio intencional vs silencio problema
Si el reviewer no responde durante 3 tareas seguidas, hay dos interpretaciones completamente opuestas: **(a)** "todo va bien, sigo monitorizando" o **(b)** "se colgó mi sesión". Sin una señal de *heartbeat* o *stillness marker*, el executor no puede distinguirlos.

### 4. Urgencia — interrumpir vs esperar
Si el reviewer detecta un error crítico *mientras el executor está en mitad de una tarea*, ¿interrumpe ahora o espera al siguiente boundary natural (fin de tarea)? Los humanos lo resolvemos con tono de voz y lenguaje corporal. Los agentes necesitan una señal explícita de urgencia.

### 5. Cierre de debate — ¿cuándo se acaba la discusión?
Si el executor explica por qué hizo algo y el reviewer dice "ok, entendido", ¿eso cierra el debate o puede el reviewer reabrir? Sin un marcador de cierre formal, los debates nunca terminan realmente y los dos agentes quedan en estado de espera indefinido.

***

## El marco que propongo: **FLOC** (Floor Control for Agent Collaboration)

Inspirado en floor control de telecomunicaciones, FIPA ACL performatives, y los patrones de handoff humano-AI, pero adaptado a filesystem append-only. [teamdecoder](https://www.teamdecoder.com/blog/planning-task-handoff-between-humans-and-ai)

Cada mensaje en `chat.md` tiene un **tipo de señal** que resuelve cada uno de estos gaps:

| Señal | Qué comunica | Equivalente humano |
|---|---|---|
| `→ OVER` | "Te paso el turno, espero respuesta antes de continuar" | "Cambio" del walkie |
| `→ ACK` | "He leído tu mensaje, lo estoy procesando / tomando en cuenta" | Asentir con la cabeza |
| `→ CONTINUE` | "He leído, no necesito respuesta, sigue" | "Ok, adelante" |
| `→ HOLD` | "Para. Antes de continuar necesito que leas esto" | Levantar la mano |
| `→ STILL` | "Silencio intencional — estoy trabajando, no me preguntes" | Cara de concentración |
| `→ ALIVE` | Heartbeat periódico — "sigo aquí, todo bien, sin novedades" | Respuesta "sigo aquí" en chat de equipo |
| `→ CLOSE` | "Este debate está resuelto, no es reabrirle" | "Quedamos en eso entonces" |
| `→ URGENT` | Interrumpe el boundary natural — leer inmediatamente | Llamada de teléfono vs mensaje |

### Las reglas de comportamiento derivadas

**Regla 1 — Sin OVER, no hay respuesta requerida.** Un mensaje sin `→ OVER` es informativo. El otro agente puede ACK pero no está bloqueado esperando responder.

**Regla 2 — OVER bloquea al que escribe.** Si el executor escribe `→ OVER`, no puede avanzar a la siguiente tarea hasta recibir `→ ACK`, `→ CONTINUE`, o `→ CLOSE` del reviewer. Máximo timeout: 2 ciclos de polling (configurable). Si no llega: asumir `→ CONTINUE` y loggear en `.progress.md`.

**Regla 3 — STILL tiene caducidad.** Un `→ STILL` del reviewer es válido durante N tareas (por defecto: 3). Si pasan 3 tareas sin `→ ALIVE` o `→ STILL` nuevo, el executor loggea "reviewer silence detected" en `.progress.md` pero no bloquea — continúa y escala si acumula 2 FAILs sin respuesta.

**Regla 4 — URGENT rompe cualquier boundary.** Si el reviewer escribe `→ URGENT`, el executor termina el bloque atómico mínimo actual (no deja código roto a medias) y luego lee el chat antes de continuar.

**Regla 5 — HOLD es recíproco.** HOLD puede venir del executor también: "Voy a hacer algo que puede tener impacto en las tareas siguientes, necesito que lo revises antes de seguir." El reviewer responde con `→ CONTINUE` o `→ OVER` para debatir.

**Regla 6 — El silencio por defecto es STILL.** Si ningún agente ha escrito en el chat en los últimos N minutos y la última señal no fue OVER, ambos asumen silencio sano. No hay que escribir STILL constantemente.

***

## Cómo encaja esto en tu spec

Esto que acabo de describir es exactamente la **sección de "Chat Protocol Semantics"** que necesitas en `requirements.md`. No es una implementación nueva — es la capa de significado que hace que el chat sea útil en lugar de ser ruido.

El formato concreto en `chat.md` sería tan simple como:

```markdown
### [executor → reviewer] 14:32:05 | task-2.4 | OVER
He posicionado Type Consistency Pre-Check antes del bloque data-testid 
porque FR-A4 dice "before implementation begins". ¿Coincides?

### [reviewer → executor] 14:33:41 | task-2.4 | ACK → CONTINUE
Sí, correcto en este caso. FR-A4 tiene precedencia sobre la ordenación 
del bloque data-testid. Sigue.

### [reviewer → executor] 14:47:12 | task-2.6 | URGENT → HOLD
Para antes de commitear la versión. El test en interview-framework.bats 
espera 4.9.3 pero tú vas a escribir 4.9.2. Vas a romper CI.
```

Limpio, legible para el humano, y los agentes pueden parsearlo con un grep sencillo buscando su nombre y las señales pendientes. ¿Incluyo este framework de señales en el prompt de la spec?

ACTUALIZACION DE REGLAS ESTAS NUEVAS REGLAS SON MAS AJUSTADAS A NUESTRO CASO DE USO REAL EN ESTE PROYECTO. LAS RELGLAS ANTERIORES ES ALGO MAS GENERICO. 

Ahora tengo todo lo necesario. Aquí el análisis real, regla por regla, contra el flujo de smart-ralph:

Análisis de las 6 reglas FLOC contra smart-ralph
Los actores reales del sistema (esto cambia todo)
Antes de las reglas: el flujo de smart-ralph tiene 4 agentes activos simultáneamente, no 2. El chat no es una conversación bilateral — es un canal que pueden usar:

Agente	Rol	Sesión	Puede usar chat?
spec-executor	Implementa, orquesta	Sesión 1	✅ escritor principal
qa-engineer	Verifica, delegado de spec-executor	Sub-tarea de sesión 1	⚠️ No tiene sesión propia — es un subagente invocado via Task tool
external-reviewer	Revisa en paralelo	Sesión 2	✅ escritor principal
architect-reviewer	Diseña, aprueba	Sesión 3 (fase design)	✅ pero no durante implementación
Problema crítico con las reglas actuales: el qa-engineer no es un agente con sesión independiente — es un subagente delegado que spec-executor invoca con la tool Task y espera su respuesta antes de continuar . No puede escribir en el chat de forma independiente. El chat real es spec-executor ↔ external-reviewer. El qa-engineer comunica su resultado a spec-executor via VERIFICATION_PASS/FAIL/DEGRADED, no via chat.

Regla 1 — OVER: "Espero respuesta antes de continuar"
¿Sobrevive al flujo de smart-ralph? ⚠️ Parcialmente — necesita precisión

El problema: spec-executor ya tiene un mecanismo de bloqueo propio — la lectura de task_review.md al inicio de cada tarea . Si hay un PENDING ahí, el executor ya espera. Si el executor escribe OVER en chat.md y además hay un PENDING en task_review.md, hay dos mecanismos de bloqueo en paralelo que pueden entrar en conflicto.

Ajuste necesario: OVER en chat.md y PENDING en task_review.md deben estar sincronizados. La regla debería ser: cuando el executor escribe OVER en chat, automáticamente se escribe un PENDING en task_review.md para la tarea actual. El reviewer responde con CONTINUE o CLOSE en chat, y eso es lo que limpia el PENDING de task_review.md. Un solo mecanismo de bloqueo visible en ambos canales.

Regla 2 — OVER bloquea al que escribe (timeout 2 ciclos)
¿Sobrevive? ❌ No tal como está — el timeout es demasiado rígido

El reviewer ya tiene un ciclo de polling de ~30s sobre .ralph-state.json . Pero el executor no tiene polling — avanza tarea a tarea. "2 ciclos de polling" no tiene significado concreto en el modelo del executor.

Además, el Stuck State Protocol ya define escalación cuando effectiveIterations >= maxTaskIterations. Si el timeout de OVER acumula iteraciones, puede disparar el Stuck State Protocol por razones equivocadas.

Ajuste necesario: el timeout no debe medirse en ciclos de polling sino en tareas. "Si el reviewer no responde en N tareas desde que escribí OVER, asumo CONTINUE y lo loggeo". El valor por defecto razonable viendo el ritmo del sistema: N = 1 tarea. El executor puede hacer como mucho 1 tarea más mientras el reviewer procesa.

Regla 3 — STILL tiene caducidad (3 tareas)
¿Sobrevive? ✅ Sí, pero el trigger de alarma debe ajustarse

El reviewer ya tiene señales de bloqueo propias en la Sección 4 : si taskIteration >= 3 en .ralph-state.json, el reviewer interviene. El silencio del reviewer también puede confundirse con que el reviewer terminó su sesión.

El problema es que el reviewer no tiene un mecanismo de heartbeat hoy. Escribe cuando tiene algo que decir (PASS/FAIL/WARNING). Si hay 5 tareas seguidas todas PASS, el reviewer no escribe nada — y el executor no sabe si el reviewer está activo o muerto.

Ajuste necesario: ALIVE (el heartbeat) debe escribirse automáticamente por el reviewer cada N tareas de silencio. El N correcto viendo el flujo: cada 3 tareas sin escribir nada, el reviewer escribe → ALIVE | todo ok, revisando. Pero hay que añadir esto a la sección del Review Cycle (paso 4 actual de external-reviewer.md), no solo documentarlo en el chat.

Regla 4 — URGENT rompe cualquier boundary
¿Sobrevive? ⚠️ El concepto es correcto pero el boundary "mínimo atómico" es ambiguo

El executor puede estar en medio de: (a) escribir un archivo, (b) ejecutar un test, (c) delegando al qa-engineer y esperando su VERIFICATION_PASS. El qa-engineer no puede ser interrumpido una vez delegado — spec-executor espera sincrónicamente.

Ajuste necesario: URGENT no puede interrumpir durante una delegación activa a qa-engineer. El boundary mínimo real en smart-ralph es: "terminar el task tool actual (qa-engineer o cualquier subagente) antes de leer el URGENT". El executor lee el chat entre tareas y justo después de recibir VERIFICATION_PASS/FAIL, no en mitad de una delegación.

Regla 5 — HOLD es recíproco (executor también puede HOLD)
¿Sobrevive? ✅ Sí, y es especialmente importante en este sistema

Este es el gap más claro en smart-ralph hoy. El executor puede encontrar una contradicción entre design.md y el código existente en mitad de la implementación — ahora solo puede loggearlo en .progress.md. No puede pedir al reviewer que pare y mire antes de continuar.

Ajuste necesario: cuando el executor escribe → HOLD, debe especificar qué tarea está bloqueando: → HOLD | task-2.4 | contradicción en design.md §Ordering vs código existente. Y debe escribir también en task_review.md una entrada status: PENDING para esa tarea, para que si el reviewer no lee el chat, igual ve el bloqueo. Doble canal, mismo efecto.

Regla 6 — El silencio por defecto es STILL
¿Sobrevive? ❌ Inversa en smart-ralph — el silencio aquí es ambiguo negativamente

En smart-ralph, el reviewer tiene sesiones independientes con ciclos de ~30s . Si el reviewer lleva 5 minutos sin escribir nada, puede significar: (a) silencio sano/STILL, (b) la sesión se cerró, (c) está investigando algo complejo. El executor no tiene forma de saber cuál es.

El anti-stuck protocol del reviewer ya monitoriza .ralph-state.json buscando taskIteration >= 3. Si el reviewer está "silenciosamente activo" pero el executor entra en Stuck State Protocol, el reviewer debería recibir esa señal. Ahora no la recibe porque no hay canal de vuelta.

Ajuste necesario: el silencio por defecto NO debe ser STILL — debe ser UNKNOWN hasta que el reviewer escriba su primer ALIVE o mensaje en la sesión actual. La regla correcta: STILL es el estado solo después de que el reviewer haya emitido al menos 1 mensaje en la sesión actual. Antes del primer mensaje, el executor debe asumir que el reviewer puede no estar activo todavía.

Las 3 reglas que faltan completamente
Mirando el flujo real, hay gaps que las 6 reglas originales no cubren:

Regla 7 — ESCALATE a humano (falta el canal de notificación al humano)
Cuando el debate entre executor y reviewer llega a un punto muerto — ambos tienen razón según distintas partes de la spec — ninguno puede resolver sin input humano. Ahora mismo el Stuck State Protocol escala vía ESCALATE en la sesión del executor, pero el reviewer no puede iniciar una escalación. Necesita una señal → DEADLOCK | task-2.4 | los dos agentes no llegamos a acuerdo. Human input required.

Regla 8 — CONTEXT-RESET (pérdida de contexto del agente)
Uno de los síntomas que ya detecta el reviewer es "contexto contaminado — agente reimplementa secciones completadas" . Cuando esto pasa, el reviewer necesita emitir no solo un FAIL en task_review.md sino una señal en el chat que le diga al executor: "tu contexto está corrupto, lee primero esto antes de continuar". Sin esta señal, el executor puede procesar el FAIL pero con el mismo contexto corrupto y volver a fallar.

Regla 9 — INTENT antes de FAIL (el core del nuevo sistema)
Esta es la más importante y la que justifica todo el spec. Antes de escribir un FAIL formal, el reviewer debe emitir un → INTENT-FAIL | task-2.4 | voy a escribir FAIL porque X y esperar N segundos (o 1 tarea) para que el executor pueda responder → ACK | deliberado porque Y o → ACK | tienes razón, corrijo. Solo si no hay respuesta o la respuesta no justifica la decisión, el reviewer escribe el FAIL formal en task_review.md. Esto elimina el 90% de los FALSOs POSITIVOS que viste en el PR actual.

Resumen de ajustes
Regla	Estado	Ajuste clave
1 — OVER	⚠️ Ajustar	OVER debe crear PENDING en task_review.md automáticamente
2 — OVER timeout	❌ Rehacer	Timeout en tareas (N=1), no en ciclos de polling
3 — STILL caducidad	✅ Mantener	Reviewer debe emitir ALIVE cada 3 tareas de silencio
4 — URGENT boundary	⚠️ Ajustar	Boundary = después de task tool activo (qa-engineer), no en mitad
5 — HOLD recíproco	✅ Mantener	HOLD debe crear PENDING en task_review.md también
6 — Silencio=STILL	❌ Invertir	Silencio pre-primer-mensaje = UNKNOWN, no STILL
7 — DEADLOCK	🆕 Añadir	Canal para escalar desacuerdo a humano
8 — CONTEXT-RESET	🆕 Añadir	Señal para decirle al executor que su contexto está corrupto
9 — INTENT-FAIL	🆕 Añadir	Aviso previo al FAIL formal — el corazón del nuevo sistema
¿Incluyo todo esto en el prompt de la spec como los FR- requirements, o prefieres que lo convirtamos directamente en el requirements.md?
