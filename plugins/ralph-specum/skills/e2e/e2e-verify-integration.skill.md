# Skill: e2e-verify-integration

> Cómo integrar tests E2E Playwright dentro del loop de ralph-specum.
> Describe el contrato entre las tareas `tasks.md`, el agente `qa-engineer`
> y el hook `stop-watcher.sh`. No es un sustituto de `homeassistant-selector-map.skill.md`
> — ambos se usan juntos en tareas E2E.

---

## Cómo funciona el loop de verificación en ralph-specum

El motor no es un script externo. Es el **Stop Hook de Claude Code**:

```
Claude termina una tarea
       ↓
stop-watcher.sh se ejecuta (Stop hook en hooks.json)
       ↓
Lee .ralph-state.json → ¿hay tareas pendientes?
       ↓
  SÍ → bloquea el stop, inyecta prompt de continuación
  NO → deja parar
       ↓ (caso NO)
Busca ALL_TASKS_COMPLETE en el transcript → limpia estado y termina
```

**Fuente**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` y
`plugins/ralph-specum/hooks/hooks.json` en este repositorio.

---

## Las tres señales reales

### 1. `TASK_COMPLETE`

Emitida por `spec-executor` al final de cada tarea exitosa.

```
TASK_COMPLETE
status: pass
commit: a1b2c3d
verify: all tests passed (5/5)
```

`stop-watcher` no busca esta señal en el transcript — lee `.ralph-state.json`
para saber si quedan tareas. `TASK_COMPLETE` es para el coordinador interno.

### 2. `VERIFICATION_PASS` / `VERIFICATION_FAIL`

Emitidas **exclusivamente** por el agente `qa-engineer` cuando `spec-executor`
le delega una tarea con tag `[VERIFY]`.

```
# Éxito
VERIFICATION_PASS

# Fallo
VERIFICATION_FAIL
```

Comportamiento según resultado:

| Señal | `spec-executor` hace | `stop-watcher` hace |
|---|---|---|
| `VERIFICATION_PASS` | Marca `[x]` en tasks.md, emite `TASK_COMPLETE` | Lee estado, continúa si hay más tareas |
| `VERIFICATION_FAIL` | NO marca `[x]`, NO emite `TASK_COMPLETE`, loguea en `.progress.md` | Bloquea stop, reintenta la tarea en siguiente iteración |

**Fuente**: `plugins/ralph-specum/agents/qa-engineer.md` (sección `<verify_tasks>`) y
`plugins/ralph-specum/agents/spec-executor.md`.

### 3. `ALL_TASKS_COMPLETE`

Emitida por el coordinador cuando todas las tareas están terminadas.
`stop-watcher` la busca en el transcript con:

```bash
grep -qE '(^|\W)ALL_TASKS_COMPLETE(\W|$)'
```

Cuando la detecta: limpia estado, actualiza epic si aplica, permite el stop.

**Fuente**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (~línea 60).

---

## Formato correcto de tarea E2E en `tasks.md`

Cada tarea es **un solo checkbox**. Las secciones `Do`, `Files`, `Done when`,
`Verify` y `Commit` son metadata de la tarea, no checkboxes adicionales.
Las historias de usuario (`US-*`, `AC-*`) están en `requirements.md`,
nunca en `tasks.md`.

### Tarea de implementación E2E

```markdown
- [ ] 2.1 E2E test: [descripción del flujo]
  - **Do**: Crear test Playwright en `tests/e2e/[nombre].spec.ts`
    siguiendo `skills/e2e/homeassistant-selector-map.skill.md`
  - **Files**: `tests/e2e/[nombre].spec.ts`
  - **Done when**: Test pasa con `npx playwright test [nombre].spec.ts`
  - **Verify**: `npx playwright test [nombre].spec.ts --reporter=line`
  - **Commit**: `test(e2e): add [nombre] flow test`
  - _Requirements: US-X, AC-X.Y_
```

### Tarea de verificación E2E (Quality Gate)

```markdown
- [ ] VE1 [VERIFY] E2E startup: launch dev server and verify health
  - **Do**: Iniciar servidor: `pnpm dev &` (guardar PID en /tmp/ve-pids.txt),
    esperar health endpoint en puerto `{{port}}`
  - **Verify**: `curl -sf http://localhost:{{port}}/health -o /dev/null && echo PASS`
  - **Done when**: Servidor corriendo y health endpoint devuelve 200
  - **Commit**: None

- [ ] VE2 [VERIFY] E2E check: run critical flow verification
  - **Do**: Ejecutar suite E2E contra servidor en marcha
  - **Verify**: `npx playwright test --reporter=line`
  - **Done when**: Todos los tests pasan
  - **Commit**: None

- [ ] VE3 [VERIFY] E2E cleanup: stop server and release resources
  - **Do**: Matar proceso por PID y liberar puerto
  - **Verify**: `! lsof -ti :{{port}} && echo PASS`
  - **Done when**: Puerto libre, archivo PID eliminado
  - **Commit**: None
```

**Importante**: Las tareas `[VERIFY]` nunca las ejecuta `spec-executor` directamente.
Las delega siempre a `qa-engineer` vía Tool delegation.

---

## Flujo completo de una tarea [VERIFY] E2E

```
stop-watcher detecta tareas pendientes
       ↓
spec-executor lee la tarea VE2
       ↓
Detecta tag [VERIFY] → delega a qa-engineer via Task tool
       ↓
qa-engineer ejecuta: npx playwright test --reporter=line
       ↓
  Todos pasan (exit 0)  →  emite VERIFICATION_PASS
  Alguno falla (exit ≠ 0) →  emite VERIFICATION_FAIL
       ↓
spec-executor recibe resultado:
  PASS → marca [x] en tasks.md, commit, emite TASK_COMPLETE
  FAIL → loguea en .progress.md, NO emite TASK_COMPLETE
       ↓
stop-watcher.sh:
  Quedan tareas → bloquea stop, siguiente iteración
  No quedan → busca ALL_TASKS_COMPLETE en transcript → termina
```

---

## Qué NO hace este sistema

- No usa `ralph-loop.sh` — ese archivo es legacy de otro repo
- No usa señales `state_match`, `verification_ok`, `TASK_COMPLETE` en transcript
  (esas señales eran del loop externo de bash, no aplican aquí)
- No lee las historias de usuario de `tasks.md` — las lee de `requirements.md`
- No soporta `waitForTimeout` en tests (ver `homeassistant-selector-map.skill.md`)

---

## Checklist de integración

- [ ] Cada test E2E tiene su propia tarea de implementación (un solo `- [ ]`)
- [ ] Las tareas de verificación usan el patrón VE1/VE2/VE3
- [ ] Las tareas `[VERIFY]` tienen comando concreto en `Verify:`
  con exit code 0/1 como señal de pass/fail
- [ ] Las referencias a historias de usuario (`US-X`, `AC-X.Y`) están en
  la línea `_Requirements:_`, no como checkboxes
- [ ] Los selectores del test siguen `skills/e2e/homeassistant-selector-map.skill.md`
- [ ] Ninguna señal legacy (`state_match`, `TASK_COMPLETE` en transcript) en prompts
