# Smart Ralph — Post-mortem y Análisis de Mejoras
**Proyecto**: `ha-ev-trip-planner` · refactor `rfactory-clean-architecture`
**Revisores**: Perplexity (arquitectura HA), Qwen (typing, spec hygiene), JOAO (producto)
**Fecha**: Abril 2026

***

## 1. Resumen Ejecutivo

Durante el sprint de refactorización del integración `ha-ev-trip-planner`, Smart Ralph produjo spec-documents (design.md, requirements.md, tasks.md) que contenían **cinco categorías de errores** que requirieron corrección humana antes de la implementación. Ninguno era un error de lógica de negocio — todos eran errores de **precisión técnica en la especificación**. Este informe analiza cada error, traza su causa raíz en la arquitectura de prompts y herramientas de Smart Ralph, y propone mejoras concretas y priorizadas.

***

## 2. Catálogo Completo de Errores Detectados

A continuación se listan todos los problemas que requirieron corrección humana, con su clasificación y severidad.

| # | Error | Quién detectó | Severidad | Fase en la que impacta |
|---|-------|---------------|-----------|------------------------|
| E1 | Tipo de retorno de `sensor_async_add_entities` declarado como `None` cuando debería ser `Awaitable[None]` | Qwen | Media | Implementación (mypy falla) |
| E2 | Sección "Component: Delete with Registry Cleanup" duplicada en design.md | Qwen | Baja | Claridad / riesgo de doble implementación |
| E3 | User Adjustment #2 en requirements.md contradice FR-6 (texto de versión anterior no actualizado) | Qwen | Media | Implementación (Ralph podría seguir la versión vieja) |
| E4 | Explicación técnica incorrecta del race condition del callback (`async_add_entities`) | Perplexity | Baja | Documentación/confianza |
| E5 | Falta de advertencia sobre el orden correcto de captura del callback (capturar DESPUÉS del await) | Perplexity | Media | Implementación (race condition de disponibilidad) |

### Errores previos documentados en sesiones anteriores

| # | Error | Fase |
|---|-------|------|
| E6 | Sensores sin `unique_id` → duplicados y zombis en registry | Arquitectura base |
| E7 | Sensores heredando `SensorEntity` en lugar de `CoordinatorEntity` | Arquitectura base |
| E8 | `unittest.mock.MagicMock` en código de producción | Implementación |
| E9 | `__init__.py` de >5000 líneas actuando como God Object | Arquitectura base |
| E10 | Múltiples namespaces en `hass.data` con fallbacks legacy no documentados | Arquitectura base |

> Los errores E6-E10 son del código original, no generados por Ralph. Los errores E1-E5 sí son errores de la spec producida por Ralph. Este informe se centra en E1-E5 pero los menciona para el contexto arquitectónico.

***

## 3. Análisis de Causa Raíz por Error

### 3.1 E1 — Tipo de retorno incorrecto para `sensor_async_add_entities`

**Qué pasó**: El architect-reviewer escribió `Callable[[list[SensorEntity], bool], None]` como tipo para el callback `sensor_async_add_entities`, pero el propio código de ejemplo en el mismo documento usa `await async_add_entities(...)`, lo que requiere `Awaitable[None]` como retorno.

**Por qué pasó**: El prompt del `architect-reviewer` instruye a diseñar interfaces y data flow, pero no obliga a ejecutar una **comprobación de coherencia cruzada entre el tipo documentado y el ejemplo de uso documentado**. El agente generó el tipo y el ejemplo en momentos distintos del contexto de generación, y no hubo un paso de "lee lo que acabas de escribir y verifica que el tipo coincide con el uso".

**Causa raíz**: Falta de un paso explícito de auto-revisión de coherencia interna en el `architect-reviewer`. El agente produce el documento pero no lo relee con ojos críticos buscando contradicciones internas.

***

### 3.2 E2 — Sección duplicada en design.md

**Qué pasó**: La sección "Component: Delete with Registry Cleanup" aparece dos veces con contenido idéntico en `design.md`.

**Por qué pasó**: El proceso de generación del design.md probablemente incluyó un copy-paste o una re-invocación parcial que añadió el bloque dos veces. El `architect-reviewer` no dispone de ninguna instrucción del tipo "antes de finalizar, busca secciones con el mismo encabezado H3 y elimina duplicadas".

**Causa raíz**: No existe una fase de deduplicación/lint del documento producido. El agente entrega el output sin verificar duplicados.

***

### 3.3 E3 — Texto desactualizado en requirements.md (User Adjustment #2 vs FR-6)

**Qué pasó**: El encabezado de `requirements.md` tenía texto de la versión anterior del diseño (que decía que `async_add_entities` NO podía guardarse en `runtime_data`), pero el cuerpo del documento (FR-6) ya había evolucionado para decir exactamente lo contrario.

**Por qué pasó**: Este tipo de error ocurre cuando hay **múltiples iteraciones de refinamiento** sobre el mismo documento. El `product-manager` (o el propio usuario vía feedback) actualizó FR-6, pero el preámbulo del documento no fue actualizado en esa misma iteración. No hay ningún mecanismo que valide que el preámbulo/resumen es consistente con los requisitos detallados.

**Causa raíz**: Las actualizaciones parciales de documentos no tienen un paso de reconciliación. Cuando se actualiza una parte, el resto del documento puede quedar obsoleto sin que nadie lo detecte.

***

### 3.4 E4 — Explicación técnica incorrecta del race condition

**Qué pasó**: La advertencia escrita en la spec describía la razón del orden de captura del callback como "el callback aún no ha procesado las entidades", que es técnicamente incorrecto. La razón correcta es que si el callback se hace visible antes de que el setup termine, un servicio concurrente puede invocarlo mientras el setup sigue ejecutándose.

**Por qué pasó**: El `architect-reviewer` no tiene acceso directo al runtime de Home Assistant para verificar empíricamente qué pasa. Generó una explicación plausible pero incorrecta. No buscó en los docs de HA el modelo de concurrencia del event loop para verificar la afirmación.

**Causa raíz**: El research-analyst no fue invocado para verificar afirmaciones sobre el comportamiento de concurrencia de HA durante la fase de diseño. El architect-reviewer hizo una afirmación técnica sin pasarla por research.

***

### 3.5 E5 — Advertencia de orden del callback (faltaba o era imprecisa)

**Qué pasó**: La spec no documentaba de forma clara y explícita que el orden `await async_add_entities → captura del callback` es obligatorio (aunque el código de ejemplo lo mostraba en el orden correcto).

**Por qué pasó**: El task-planner y el architect-reviewer priorizan mostrar "qué hacer" pero no siempre documentan "qué NO hacer" o "por qué este orden específico es crítico". Los patrones de ordering crítico no tienen una sección estándar en los templates.

**Causa raíz**: Ausencia de una sección explícita en el design template para "Critical Ordering / Race Conditions / Concurrency Notes".

***

## 4. Análisis Sistémico: Qué Revela Esto Sobre Smart Ralph

Los cinco errores anteriores no son incidentes aislados. Revelan **tres debilidades estructurales** en el diseño actual de Smart Ralph.

### 4.1 Debilidad: Los agentes producen pero no revisan

El flujo actual de Smart Ralph es **lineal y unidireccional**:

```
research-analyst → product-manager → architect-reviewer → task-planner → spec-executor
```

Cada agente escribe su output y pasa el relevo. No existe una fase de **self-review** dentro de cada agente, ni una fase de **cross-review** entre agentes. La consecuencia es que:

- Incoherencias internas (E1, E2, E3) no se detectan porque nadie relee el documento completo.
- Afirmaciones técnicas no verificadas (E4) pasan sin challenge.
- Decisiones de implementación críticas sin documentar (E5) no se capturan porque no hay un paso que pregunte "¿hay algo en este diseño que si un implementador invierte el orden, rompe el sistema?".

El `architect-reviewer` tiene una Testing Discovery Checklist (obligatoria), lo cual demuestra que el patrón de "checklists embebidas" funciona. Pero solo existe para testing infrastructure — no existe para coherencia interna del documento.

### 4.2 Debilidad: Los templates no modelan "zonas de riesgo"

Los templates actuales (`design.md`, `requirements.md`, `tasks.md`) tienen una estructura de secciones orientada a **describir qué se va a hacer**. No tienen secciones diseñadas para capturar:

- Contradicciones con versiones anteriores
- Restricciones de ordering o concurrencia
- Tipos que deben coincidir con el uso en el código
- Invariantes que NO deben violarse

Esto significa que la información existe en la cabeza del arquitecto humano pero no tiene un hogar natural en el documento, y por tanto no se escribe.

### 4.3 Debilidad: El `research-analyst` no valida afirmaciones técnicas del `architect-reviewer`

El research-analyst investiga el problema inicial, pero no hay un mecanismo para que el architect-reviewer diga "tengo una duda técnica sobre este aspecto específico del comportamiento de HA — necesito verificación". El research-analyst y el architect-reviewer son silos.

En el caso de E4, el architect-reviewer hizo una afirmación sobre el modelo de concurrencia de Home Assistant que era incorrecta. Si hubiera habido un step de "afirmaciones que requieren verificación externa" con un bucle de vuelta al research-analyst, esto se habría detectado antes.

***

## 5. Comparativa: Cómo lo Haría un Arquitecto Senior Humano

Un arquitecto senior humano que revisa una spec antes de enviarla al equipo hace exactamente lo que Smart Ralph no hace:

| Lo que hace un humano | Lo que hace Ralph actualmente | Gap |
|----------------------|------------------------------|-----|
| Releer el documento completo de principio a fin | Escribe y entrega | No hay relectura |
| Buscar secciones con el mismo H3 | No hay deduplicación | Duplicados pasan |
| Verificar que los tipos en diagramas coinciden con los tipos en código de ejemplo | No hay cross-check | E1 |
| Marcar las líneas de ordering crítico con un comentario "DON'T REORDER" | No hay sección de ordering risks | E5 |
| Cuando hace una afirmación sobre concurrencia, citar la doc oficial o admitir incertidumbre | Genera explicación plausible | E4 |
| Cuando actualiza un requisito, buscar en todo el doc menciones del concepto anterior | No hay reconciliación | E3 |

***

## 6. Mejoras Propuestas

Las mejoras se clasifican en tres niveles: **aplicar ahora** (bajo coste, alto impacto), **analizar y decidir** (requiere experimentación), y **visión futura** (cambios estructurales más profundos).

***

### 6.1 Mejoras Inmediatas (Aplicar Ahora)

#### M1 — Añadir "Document Self-Review Checklist" al `architect-reviewer`

**Qué**: Añadir una sección `<mandatory>` al final del prompt del `architect-reviewer` con una checklist de auto-revisión que se ejecuta ANTES de entregar el design.md.

**Cómo**:

```markdown
## Document Self-Review Checklist (MANDATORY before finalizing design.md)

Run these checks after the full document is written:

**Step 1 — Type consistency**
For every `Callable[..., X]` type annotation in the document:
- Find the corresponding usage example in the same document
- Verify the return type `X` matches how it is used (`await` → Awaitable, no await → sync)
- If mismatch found: correct the type annotation before delivering

**Step 2 — Duplicate section detection**
```bash
grep -n "^### " design.md | sort | uniq -d
```
If any H3 heading appears more than once: remove the duplicate block (keep the last/most complete version).

**Step 3 — Ordering and concurrency notes**
For every `await` call that involves registering a callback or making a resource visible:
- Ask: "If a concurrent caller accessed this resource before this await completes, what would break?"
- If the answer is "something would break": add an explicit comment in the code block:
  `# CRITICAL: capture after await — see Concurrency Notes section`
- Add a `## Concurrency Notes` section documenting the reason

**Step 4 — Internal contradiction scan**
Search for negation pairs:
- Find every sentence containing "CANNOT", "MUST NOT", "not possible"
- Verify it does not contradict any other section using the same concept
- If contradiction found: remove the outdated statement and add `<!-- superseded by FR-X -->`
```

**Impacto esperado**: Previene E1, E2, E3, E5 en una sola adición.

***

#### M2 — Añadir sección "Concurrency & Ordering Risks" al template `design.md`

**Qué**: Añadir una sección estándar al template de design.md.

**Cómo**:

```markdown
## Concurrency & Ordering Risks

<!-- Document any sequence-critical operations, async ordering constraints, or
     race conditions that an implementer MUST know. If none: write "None identified." -->

| Operation | Critical Order | Risk if Inverted |
|-----------|---------------|-----------------|
| Example: capture callback | AFTER `await async_add_entities()` | Service handlers could invoke callback during partial setup |
```

Si el architect-reviewer siempre tiene que rellenar esta sección (aunque sea con "None identified"), fuerza la reflexión explícita sobre concurrencia en cada diseño.

**Impacto esperado**: Previene E5 y fuerza documentación de cualquier ordering crítico futuro.

***

#### M3 — Añadir "Spec Reconciliation Check" al `product-manager` (para actualizaciones)

**Qué**: Cuando el product-manager actualiza un requisito existente (no crea uno nuevo), debe ejecutar un paso de reconciliación.

**Cómo**: Añadir al prompt del `product-manager`:

```markdown
## On Requirements Update (when modifying existing requirements.md)

<mandatory>
When updating any existing Functional Requirement (FR-X):

1. Note the old value/concept being replaced
2. Search the ENTIRE requirements.md for the old concept:
   ```bash
   grep -n "<old_concept>" requirements.md
   ```
3. For every match outside the updated FR: decide if it should be updated or removed
4. Update the document header/summary if it references the old concept
5. Add a one-line changelog entry at the bottom of requirements.md:
   `<!-- Changed: FR-X updated from "<old>" to "<new>" — supersedes User Adjustment #N -->`
</mandatory>
```

**Impacto esperado**: Previene E3.

***

#### M4 — Regla en `spec-executor`: verificar coherencia de tipos antes de implementar

**Qué**: Añadir un paso inicial al spec-executor que, antes de implementar cualquier tarea que involucre tipos Python, verifica que los tipos del design coinciden con su uso.

**Cómo**: Añadir al prompt del spec-executor, sección "Implementation Tasks":

```markdown
### Type Consistency Pre-Check (for typed Python tasks)

Before implementing any task that involves `Callable`, `Awaitable`, `Coroutine` or similar types:

1. Find the type declaration in design.md or requirements.md
2. Find the usage example in the same document
3. Verify they are consistent:
   - `Callable[..., None]` → usage must NOT use `await`
   - `Callable[..., Awaitable[None]]` → usage MUST use `await`
4. If inconsistent: use the usage example as ground truth, fix the type annotation in your implementation, and add a comment in `.progress.md`:
   `Corrected type: design.md declared X but usage example shows Y — implemented as Y`
```

**Impacto esperado**: Convierte E1 en un catch en el punto de implementación si pasa la revisión del architect.

***

### 6.2 Mejoras a Analizar y Decidir

#### M5 — Introducir un agente `spec-reviewer` post-architect (ya existe en el repo, pero ¿se usa?)

**Observación**: El repositorio de Smart Ralph ya tiene un archivo `agents/spec-reviewer.md` en la lista de agentes. Sin embargo, el flujo actual (`research → requirements → design → tasks → implement`) no parece invocar al `spec-reviewer` de forma automática después del `architect-reviewer`.

**Propuesta**: Hacer que el comando `/ralph-specum:design` invoque al `spec-reviewer` automáticamente al final, pasándole el design.md recién generado con el mandato de buscar:
- Tipos inconsistentes
- Secciones duplicadas
- Afirmaciones técnicas no citadas
- Contradicciones con la versión anterior

**Coste**: Añade un paso al flujo (tokens + tiempo). Puede ser opt-in con un flag `--review`.

**Decisión a tomar**: ¿Se activa siempre, solo en specs complejas, o solo cuando el usuario lo pide?

***

#### M6 — Loop de verificación `research-analyst ↔ architect-reviewer` para afirmaciones técnicas

**Observación**: El architect-reviewer actualmente hace afirmaciones técnicas sobre frameworks externos (Home Assistant, en este caso) sin un mecanismo de verificación. El research-analyst y el architect-reviewer no se hablan entre sí.

**Propuesta**: Añadir al `architect-reviewer`:

```markdown
## Technical Claims Requiring Verification

<mandatory>
When you write a statement about external framework behavior (e.g., "HA's async_add_entities
does X when called at moment Y"), mark it with `[VERIFY]` in the design.md:

```
> [VERIFY] `async_add_entities` is an async method — source: TBD
```

After completing design.md, for each `[VERIFY]` marker:
1. Spawn research-analyst to verify the claim
2. Replace `[VERIFY]` with a citation: `[source: HA developer docs, EntityPlatform.async_add_entities]`
3. If research-analyst cannot confirm → replace with `[UNVERIFIED — human review required]`
</mandatory>
```

**Coste**: Puede alargar significativamente la fase de diseño para specs con muchas afirmaciones técnicas. Requiere medir el impacto en tokens.

**Decisión a tomar**: Aplicar solo a afirmaciones sobre concurrencia/async, o a todas las afirmaciones técnicas.

***

#### M7 — Añadir "Diff Review" al flujo de actualización de specs existentes

**Observación**: El error E3 surgió porque la spec fue actualizada en múltiples iteraciones (el usuario pidió cambios, el agente los aplicó) y el preámbulo quedó obsoleto. El flujo actual no tiene un concepto de "versión de la spec" ni de "diff entre la versión anterior y la actual".

**Propuesta**: Cuando `/ralph-specum:requirements` (u otro comando de spec) se ejecuta sobre una spec existente, el agent debería:
1. Leer la versión actual del documento
2. Aplicar los cambios
3. Generar un "micro-changelog" de las secciones modificadas
4. Añadirlo al final del documento como comentario HTML

**Coste**: Requiere cambios en el prompt del `product-manager` y posiblemente en el comando `/requirements`.

***

#### M8 — Checklist de QA para specs (análoga a la de tests)

**Observación**: El `architect-reviewer` ya tiene una "Testing Discovery Checklist" (obligatoria, bien diseñada). El mismo patrón debería existir para la calidad del propio documento de spec.

**Propuesta**: Crear una "Spec Quality Checklist" análoga:

```markdown
## Spec Quality Checklist (MANDATORY before finalizing)

**Step 1 — Completeness**
- [ ] Every FR has an acceptance criterion
- [ ] Every component in the architecture diagram has a corresponding code block
- [ ] Every Callable type has a usage example that matches the type

**Step 2 — Consistency**
- [ ] No section headers appear more than once (dedup check)
- [ ] No statement contradicts another statement in the same document
- [ ] All User Adjustments in the header match the current FR content

**Step 3 — Implementability**
- [ ] Every task in tasks.md maps to at least one FR
- [ ] Every async operation has its error handling path documented
- [ ] Every operation that must happen in a specific order has that order documented

**Step 4 — Verifiability**
- [ ] Every architectural claim about external frameworks is either cited or marked [UNVERIFIED]
- [ ] Every [VERIFY] task has a clear pass/fail criterion
```

***

### 6.3 Visión Futura

#### M9 — Meta-agente "Spec Linter" como hook automático

**Concepto**: Un hook `PostToolUse` que se dispara cuando el `architect-reviewer` o el `product-manager` escribe un archivo `.md` de spec, y ejecuta un linter de specs ligero:

```python
# pseudo-código del spec linter
def lint_spec(path):
    content = read(path)
    errors = []

    # Check 1: duplicate H3
    h3s = re.findall(r'^### .+', content, re.MULTILINE)
    if len(h3s) != len(set(h3s)):
        errors.append(f"DUPLICATE_H3: {[h for h in h3s if h3s.count(h) > 1]}")

    # Check 2: Callable types vs await usage
    callable_types = re.findall(r'Callable\[.*?\]', content)
    for t in callable_types:
        if '], None]' in t:  # sync return type
            # search for 'await <callback_name>' nearby
            ...

    # Check 3: CANNOT/MUST NOT contradictions
    ...

    return errors
```

Esto convertiría la revisión de specs en algo automatizable y reproducible, con salida machine-readable que el spec-reviewer podría consumir.

**Coste**: Requiere desarrollo de herramienta + integración como hook Claude Code. Es un proyecto propio.

***

#### M10 — "Spec Versioning" con semver automático

**Concepto**: Cada vez que un agente modifica un archivo de spec, aplica un bump de versión al frontmatter del documento:

```markdown
---
spec_version: 1.3.0
last_modified_by: architect-reviewer
last_modified: 2026-04-06
changelog:
  - "1.3.0: Updated FR-6 callback pattern, removed contradictory User Adjustment #2"
  - "1.2.0: Added Concurrency Notes section"
  - "1.1.0: Initial requirements from product-manager"
---
```

Esto haría que la contradicción del tipo E3 fuera inmediatamente visible: el changelog diría "User Adjustment #2 eliminado en 1.3.0" y el texto desactualizado habría sido eliminado en ese mismo bump.

***

## 7. Plan de Acción Priorizado

| Prioridad | Mejora | Dónde aplicar | Coste estimado | Impacto |
|-----------|--------|---------------|----------------|---------|
| 🔴 P1 | M1 — Self-review checklist en architect-reviewer | `agents/architect-reviewer.md` | 30 min | Previene E1, E2, E3, E5 |
| 🔴 P1 | M2 — Sección Concurrency Risks en design.md template | `templates/design.md` | 15 min | Previene E5 |
| 🔴 P1 | M3 — Reconciliation check en product-manager (updates) | `agents/product-manager.md` | 20 min | Previene E3 |
| 🟡 P2 | M4 — Type consistency pre-check en spec-executor | `agents/spec-executor.md` | 20 min | Catch tardío de E1 |
| 🟡 P2 | M5 — Activar spec-reviewer en flujo post-design | `commands/design.md` | 1-2h | Catch general |
| 🟡 P2 | M8 — Spec Quality Checklist estándar | `agents/architect-reviewer.md` | 45 min | Previene todo |
| 🟢 P3 | M6 — Loop research ↔ architect para afirmaciones técnicas | `agents/architect-reviewer.md` | 2-3h | Previene E4 |
| 🟢 P3 | M7 — Diff Review en actualizaciones de spec | `product-manager.md` + commands | 3-4h | Previene E3 |
| ⚪ Futuro | M9 — Meta-agente Spec Linter como hook | Nuevo componente | 1-2 días | Automatización total |
| ⚪ Futuro | M10 — Spec Versioning con semver | Templates + todos los agents | 2-3 días | Trazabilidad total |

***

## 8. Lecciones Aprendidas

### Lección 1: Los errores de spec son más caros que los errores de código

Un error de código se detecta en el test. Un error de spec se detecta en la revisión humana, y puede haber sido implementado ya cuando se detecta. La inversión en calidad de la spec tiene un ROI mayor que la inversión en calidad del código generado.

### Lección 2: "El orden del código de ejemplo es correcto" no es suficiente documentación

E5 ilustra que el orden correcto estaba en el código de ejemplo, pero sin documentar el POR QUÉ. Un implementador que no entiende la razón puede reordenar el código "para claridad" y romper el sistema. Las reglas de ordering crítico deben estar documentadas con su razón, no solo mostradas.

### Lección 3: Las actualizaciones iterativas son el principal vector de inconsistencia

Los errores E3 y la contradicción del User Adjustment #2 no surgieron en la generación inicial de la spec, sino en actualizaciones posteriores. El flujo de Smart Ralph es robusto para la generación inicial pero frágil para las iteraciones de refinamiento. Las mejoras M3 y M7 apuntan directamente a este vector.

### Lección 4: Un agente que no se autocuestiona produce documentos que suenan correctos pero tienen sutilezas incorrectas

E4 (la explicación técnica del race condition) es el ejemplo más claro: la explicación era coherente internamente y sonaba plausible, pero era incorrecta. Un modelo de lenguaje es especialmente susceptible a este error porque su entrenamiento premia la fluidez y la coherencia interna, no la exactitud técnica verificada. La solución no es confiar más en el modelo — es forzar al modelo a citar o marcar como `[UNVERIFIED]` cualquier afirmación sobre comportamiento de sistemas externos.

### Lección 5: Los checklists embebidos en prompts funcionan

La Testing Discovery Checklist del `architect-reviewer` es un ejemplo de que cuando el prompt dice "run this checklist — mandatory", el agente lo hace. El patrón es válido y probado. La respuesta a "Ralph no verificó X" casi siempre es "añade X a un checklist obligatorio en el prompt del agente relevante".

***

## 9. Texto de Mejora para Ralph (Listo para Copiar)

### Para `agents/architect-reviewer.md` — Añadir al final:

```markdown
## Document Self-Review Checklist (MANDATORY before finalizing design.md)

<mandatory>
Execute AFTER writing the full document, BEFORE declaring design complete.

**Step 1 — Type consistency**
For every `Callable[..., X]` annotation:
- Find its usage example in the document
- If usage uses `await` → type MUST be `Callable[..., Awaitable[None]]`
- If usage does NOT use `await` → type MUST be `Callable[..., None]`
- Fix any mismatch before delivering

**Step 2 — Duplicate section detection**
Check for duplicate H3 headings. Remove duplicates, keep the last/most complete version.

**Step 3 — Ordering and concurrency notes**
For every `await` that makes a resource visible to concurrent callers:
- Document the required order in the `## Concurrency & Ordering Risks` section
- Add an inline comment `# CRITICAL: capture after await` in the code block

**Step 4 — Internal contradiction scan**
For every sentence containing "CANNOT", "MUST NOT", "not possible":
- Verify it does not contradict any FR or code block in the same document
- If contradiction: remove the outdated statement and add: `<!-- superseded by FR-X -->`
</mandatory>
```

### Para `templates/design.md` — Añadir sección:

```markdown
## Concurrency & Ordering Risks

<!-- Document sequence-critical operations. If none: write "None identified." -->

| Operation | Required Order | Risk if Inverted |
|-----------|---------------|-----------------|
| (example) capture callback | AFTER `await async_add_entities()` | Service handler race condition |
```

### Para `agents/product-manager.md` — Añadir sección:

```markdown
## On Requirements Update

<mandatory>
When updating an existing requirements.md (not creating new):

1. Note the concept being replaced
2. Run: `grep -n "<old_concept>" requirements.md`
3. Update every match that refers to the old concept
4. Verify the document header/User Adjustments section matches the current FRs
5. Append to document footer: `<!-- Changed: <description> — supersedes User Adjustment #N if applicable -->`
</mandatory>
```

***

*Fin del informe*