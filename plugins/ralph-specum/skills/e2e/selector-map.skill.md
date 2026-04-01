# Skill: selector-map

> Estrategia de selectores estables para tests Playwright.
> Úsalo como referencia en cualquier proyecto para escribir tests
> resistentes a cambios de UI.
>
> Para proyectos con componentes específicos (shadow DOM, web components,
> frameworks custom) crea un archivo `{tu-dominio}-selector-map.skill.md`
> copiando este como base y adaptando los ejemplos.

---

## Regla principal

Un selector inestable rompe el test aunque el código esté bien.
Elige siempre el selector más semántico y resistente a cambios de UI.

---

## Jerarquía de selectores (orden de preferencia)

```
1. getByRole()          — accesibilidad semántica, más estable
2. getByLabel()         — asociado al label del formulario
3. getByTestId()        — data-testid explícito, sin semántica UI
4. getByText()          — solo para texto visible único y estable
5. locator('css')       — último recurso, solo si no hay alternativa
```

### Cuándo usar cada uno

| Selector | Cuándo | Ejemplo |
|---|---|---|
| `getByRole` | Botones, links, inputs, headings | `getByRole('button', { name: 'Guardar' })` |
| `getByLabel` | Inputs con `<label>` asociado | `getByLabel('Email')` |
| `getByTestId` | Componentes sin semántica ARIA / shadow DOM | `getByTestId('user-card-42')` |
| `getByText` | Mensajes de estado, badges únicos y estables | `getByText('Guardado correctamente')` |
| `locator('css')` | Nunca en tests nuevos — solo legado | — |

---

## Convención `data-testid`

Formato recomendado: `{dominio}-{entidad}-{variante}-{acción}`

```html
<!-- Elemento principal -->
<div data-testid="{dominio}-{entidad}">

<!-- Con variante -->
<div data-testid="{dominio}-{entidad}-{variante}">

<!-- Acción sobre el elemento -->
<button data-testid="{dominio}-{entidad}-delete">

<!-- Listado y sus ítems -->
<ul data-testid="{dominio}-{entidad}-list">
<li data-testid="{dominio}-{entidad}-list-item">
```

Reglas:
- Prefijo de dominio siempre (`user-`, `order-`, `product-`)
- Minúsculas con guiones
- Sin IDs de base de datos ni valores dinámicos (son inestables entre entornos)
- Nombrar por función, no por posición

---

## Anti-patrones — nunca usar

```typescript
// ❌ Shadow DOM hardcodeado por profundidad
page.locator('app-root >>> app-header >>> nav')

// ❌ ID de base de datos en selector
page.locator('[data-id="3fa85f64"]')

// ❌ Clase CSS interna del framework (cambia con versiones)
page.locator('.MuiButton-containedPrimary')

// ❌ XPath
page.locator('//button[@class="submit"]')

// ❌ Posición en lista
page.locator('li:nth-child(3)')

// ❌ Espera arbitraria
await page.waitForTimeout(2000)
```

---

## Patrones correctos

```typescript
// Botón de acción
await page.getByRole('button', { name: 'Guardar' }).click()

// Input de formulario
await page.getByLabel('Email').fill('test@example.com')

// Componente por testid
const card = page.getByTestId('user-card')
await expect(card).toBeVisible()

// Verificar mensaje de estado
await expect(page.getByText('Guardado correctamente')).toBeVisible()

// Scope: buscar dentro de un modal
const dialog = page.getByRole('dialog')
await dialog.getByRole('button', { name: 'Confirmar' }).click()

// Esperar respuesta de API
await page.waitForResponse(resp =>
  resp.url().includes('/api/items') && resp.status() === 200
)
```

---

## Assertions recomendadas

```typescript
await expect(locator).toBeVisible()
await expect(locator).toBeHidden()
await expect(locator).toHaveText('Texto esperado')
await expect(locator).toContainText('parcial')
await expect(locator).toHaveAttribute('aria-disabled', 'true')
await expect(locator).toHaveValue('valor')
await expect(page).toHaveURL(/\/ruta-esperada/)
await expect(page.getByTestId('list-item')).toHaveCount(3)
```

---

## Esperas — nunca `waitForTimeout`

```typescript
// ✅ Esperar a que el elemento sea visible tras navegación
await page.getByTestId('result-card').waitFor({ state: 'visible' })

// ✅ Esperar respuesta de API
await page.waitForResponse(resp =>
  resp.url().includes('/api/data') && resp.status() === 200
)

// ✅ Esperar cambio de URL
await page.waitForURL(/\/dashboard/)

// ❌ Nunca
await page.waitForTimeout(2000)
```

---

## Para proyectos con shadow DOM o web components

Si tu app usa shadow DOM extensivamente (custom elements, Lit, Stencil, etc.):
1. Copia este archivo como `{tu-dominio}-selector-map.skill.md`
2. Añade la sección de shadow DOM específica de tu framework
3. Ejecuta `ui-map-init.skill.md` para generar el mapa de selectores reales
   de tu app en `ui-map.local.md` (gitignoreado)

Ejemplo de referencia: `examples/homeassistant-selector-map.skill.md`

---

## Checklist antes de entregar un test E2E

- [ ] Todos los selectores usan `getByRole`, `getByLabel` o `getByTestId`
- [ ] Ningún `locator('.clase')`, XPath ni shadow DOM hardcodeado
- [ ] Ningún `waitForTimeout`
- [ ] Ningún ID de base de datos ni valor dinámico en selectores
- [ ] Los `data-testid` siguen el formato `{dominio}-{entidad}-{variante}-{acción}`
- [ ] No hay testids duplicados en la misma vista
