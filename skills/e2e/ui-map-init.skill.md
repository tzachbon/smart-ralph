# Skill: ui-map-init

> Protocolo para que el agente explore una aplicación web, extraiga sus
> selectores reales y genere `ui-map.local.md` en la raíz del proyecto.
>
> Este skill es **agóstico de dominio**. Funciona con cualquier app web:
> Home Assistant, SaaS, dashboards, e-commerce, etc.
>
> `ui-map.local.md` está en `.gitignore` — es específico de cada instalación
> y nunca se commitea al repositorio.

> **NOTA — Versión supersedida**: Si estás usando `ralph-specum`, utiliza
> `plugins/ralph-specum/skills/e2e/ui-map-init.skill.md` en su lugar.
> Esa versión incluye exploración MCP-first con fallback estático (Phase 5).
> Este archivo se mantiene como referencia para proyectos que no usan
> ralph-specum o que no tienen `@playwright/mcp` disponible.

---

## Cuándo ejecutar este skill

- Primera vez que se crean tests E2E en un proyecto
- Cuando la UI cambia significativamente (refactor visual, nueva versión)
- Cuando los tests empiezan a fallar por selectores obsoletos
- Al incorporar un nuevo desarrollador o agente al proyecto

---

## Output esperado

El agente genera el archivo `ui-map.local.md` en la raíz del proyecto
(o en la ruta que indique el archivo de settings del plugin).

Este archivo contiene el mapa de selectores reales de la app,
organizado por vista/página/componente, listo para ser referenciado
por los tests E2E.

---

## Protocolo de exploración

### Paso 1: Contexto previo

Antes de abrir el navegador, leer:
- `specs/[spec-activo]/requirements.md` — qué vistas toca este spec
- `specs/[spec-activo]/design.md` — componentes y flujos diseñados
- `ui-map.local.md` si ya existe — actualizar solo las vistas afectadas,
  no regenerar todo

### Paso 2: Navegación exploratoria

Para cada vista relevante:

1. Navegar a la URL de la vista
2. Esperar a que cargue completamente (`networkidle` o elemento clave visible)
3. Extraer elementos interactivos:
   - Botones y acciones (`getByRole('button')`)
   - Inputs y formularios (`getByRole('textbox')`, `getByLabel`)
   - Links de navegación (`getByRole('link')`)
   - Componentes con `data-testid`
   - Headings y landmarks de navegación
4. Para cada elemento: anotar selector más estable + descripción funcional

### Paso 3: Verificar estabilidad

Antes de incluir un selector en el mapa:
- ¿Sobrevive a un reload?
- ¿Sobrevive a un cambio de datos?
- ¿Es único en la vista?

Si alguna respuesta es no, buscar alternativa más estable.

### Paso 4: Escribir `ui-map.local.md`

Formato del archivo:

```markdown
# UI Map — [Nombre del proyecto]

> Generado: [fecha]
> Versión app: [versión o commit si está disponible]
> Útil para spec: [spec-nombre]
> Regenerar si: cambios visuales en [lista de vistas]

---

## [Nombre de la vista] — [URL o ruta]

### Acciones principales

| Elemento | Selector | Notas |
|---|---|---|
| Botón guardar | `getByRole('button', { name: 'Guardar' })` | Deshabilitado si form inválido |
| Input nombre | `getByLabel('Nombre')` | Obligatorio |
| Card de item | `getByTestId('item-card')` | Repetido por ítem |

### Estados observados

| Estado | Cómo detectarlo |
|---|---|
| Cargando | `getByRole('progressbar')` visible |
| Error | `getByRole('alert')` con texto de error |
| Vacío | `getByText('No hay elementos')` visible |

### Flujos probables

- Flujo A: [descripción breve del flujo principal]
- Flujo B: [descripción breve del flujo alternativo]

---

## [Siguiente vista]

...
```

---

## Reglas del mapa

- Solo selectores verificados en la app real, nunca inventados
- Si un elemento no tiene selector estable, documentarlo como
  `PENDING: necesita data-testid en [componente]`
- Incluir solo vistas que toca el spec activo (el mapa crece incrementalmente)
- Un mapa de 3 vistas bien documentadas vale más que 20 vistas incompletas

---

## Tarea tipo para `tasks.md`

Cuando el task-planner genera las tareas de un spec con E2E, incluir:

```markdown
- [ ] 0.1 Generate UI map for affected views
  - **Do**: Execute `ui-map-init.skill.md` protocol. Navigate views listed
    in requirements.md, extract stable selectors, write `ui-map.local.md`.
    If file exists, update only affected views.
  - **Skills**: `skills/e2e/ui-map-init.skill.md`
  - **Files**: `ui-map.local.md`
  - **Done when**: `ui-map.local.md` exists and covers all views in this spec
  - **Verify**: `test -f ui-map.local.md && grep -c '##' ui-map.local.md | xargs -I{} test {} -ge 1 && echo PASS`
  - **Commit**: None (ui-map.local.md is gitignored)
```

Esta tarea va siempre **antes** de cualquier tarea `[RED]` de tests E2E.

**Si usas ralph-specum**: usa `plugins/ralph-specum/skills/e2e/ui-map-init.skill.md`
que referencia `mcp-playwright.skill.md` para exploración real con browser.

---

## Checklist de calidad del mapa

- [ ] Cubre todas las vistas del spec activo
- [ ] Cada selector verificado contra la app en ejecución
- [ ] Elementos sin selector estable marcados como `PENDING`
- [ ] Estados (loading, error, vacío) documentados por vista
- [ ] Fecha de generación y versión de app anotadas
- [ ] Sin entity_ids, IDs dinámicos ni clases CSS frágiles
