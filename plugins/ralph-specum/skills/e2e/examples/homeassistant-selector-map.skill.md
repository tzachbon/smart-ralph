# Skill: homeassistant-selector-map

> **Ejemplo de dominio específico** — basado en `selector-map.skill.md`.
> Estrategia de selectores estables para tests Playwright contra la UI de
> Home Assistant (Lovelace, paneles custom, integraciones).
>
> Para apps que no son HA, usa `../selector-map.skill.md` como base
> y crea tu propio `{tu-dominio}-selector-map.skill.md`.

---

## Regla principal

Un selector inestable rompe el test aunque el código esté bien.
Elige siempre el selector más semántico y resistente a cambios de UI.

---

## Jerarquía de selectores (orden de preferencia)

```text
1. getByRole()          — accesibilidad semántica, más estable
2. getByLabel()         — asociado al label del formulario
3. getByTestId()        — data-testid explícito, sin semántica UI
4. getByText()          — solo para texto visible único y estable
5. locator('css')       — último recurso, solo si no hay alternativa
```

### Cuándo usar cada uno

| Selector | Cuándo | Ejemplo HA |
|---|---|---|
| `getByRole` | Botones, links, inputs, headings | `getByRole('button', { name: 'Calcular ruta EV' })` |
| `getByLabel` | Inputs con `<label>` asociado | `getByLabel('Origen')` |
| `getByTestId` | Componentes web / shadow DOM / cards custom | `getByTestId('ev-route-card-MAD-BCN')` |
| `getByText` | Mensajes de estado, badges únicos | `getByText('Ruta guardada')` |
| `locator('css')` | Nunca en tests nuevos — solo legado | — |

---

## Shadow DOM en Home Assistant

La mayor parte de la UI de HA está dentro de shadow roots.
Playwright los atraviesa automáticamente con `getByRole` y `getByTestId`,
pero si necesitas acceder manualmente:

```typescript
// Atravesar shadow root explícitamente
const haCard = page.locator('ha-card').first()
const shadowContent = haCard.locator(':scope >> text=Ruta activa')

// Mejor: usa getByTestId si el componente lo expone
const card = page.getByTestId('ev-route-card')
```

Regla: si `getByRole` / `getByTestId` no llegan, investiga si el componente
expone atributos ARIA antes de atravesar el shadow DOM manualmente.

---

## Convención `data-testid` para componentes HA custom

Formato: `{dominio}-{entidad}-{variante}-{acción}`

```html
<!-- Card de ruta -->
<ha-card data-testid="ev-route-card">

<!-- Card con variante específica -->
<ha-card data-testid="ev-route-card-mad-bcn">

<!-- Acción sobre la card -->
<mwc-button data-testid="ev-route-card-delete">

<!-- Listado de rutas -->
<div data-testid="ev-route-list">
<ha-card data-testid="ev-route-list-item">

<!-- Input del panel -->
<ha-textfield data-testid="ev-origin-input">
```

Reglas:
- Prefijo de dominio siempre (`ev-`, `sensor-`, `climate-`)
- Minúsculas con guiones
- Sin entity_id ni IDs de HA (son inestables entre instancias)
- Nombrar por función, no por posición

---

## Anti-patrones — nunca usar en HA

```typescript
// ❌ Shadow DOM hardcodeado por profundidad
page.locator('home-assistant >>> ha-panel-lovelace >>> hui-card-container')

// ❌ entity_id en selector
page.locator('[data-entity-id="sensor.ev_battery_level"]')

// ❌ Clase CSS de Polymer/Lit (cambia con versiones de HA)
page.locator('.card-content.ha-scrollbar')

// ❌ XPath
page.locator('//ha-card[@class="ev-route"]')

// ❌ Posición en lista
page.locator('hui-entities-card:nth-child(3)')
```

---

## Patrones correctos

```typescript
// Botón de acción en card
await page.getByRole('button', { name: 'Calcular ruta EV' }).click()

// Input de origen
await page.getByLabel('Origen').fill('Madrid')

// Card por testid (componente complejo con shadow DOM)
const card = page.getByTestId('ev-route-card-mad-bcn')
await expect(card).toBeVisible()

// Verificar estado de la ruta
await expect(page.getByText('Ruta guardada')).toBeVisible()

// Scope: buscar dentro de un diálogo de HA
const dialog = page.getByRole('dialog')
await dialog.getByRole('button', { name: 'Confirmar' }).click()

// Esperar respuesta de la API de HA
await page.waitForResponse(resp =>
  resp.url().includes('/api/conversation/process') && resp.status() === 200
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
await expect(locator).toHaveValue('Madrid')
await expect(page).toHaveURL(/\/lovelace\/ev-routes/)
await expect(page.getByTestId('ev-route-list-item')).toHaveCount(3)
```

---

## Esperas — nunca `waitForTimeout`

```typescript
// ✅ Esperar a que la card sea visible tras navegación
await page.getByTestId('ev-route-card').waitFor({ state: 'visible' })

// ✅ Esperar respuesta de WebSocket de HA
await page.waitForResponse(resp =>
  resp.url().includes('/api/websocket') && resp.status() === 101
)

// ✅ Esperar cambio de URL en Lovelace
await page.waitForURL(/\/lovelace\//)

// ❌ Nunca
await page.waitForTimeout(2000)
```

---

## Checklist antes de entregar un test E2E

- [ ] Todos los selectores usan `getByRole`, `getByLabel` o `getByTestId`
- [ ] Ningún `locator('.clase')`, XPath ni shadow DOM hardcodeado
- [ ] Ningún `waitForTimeout`
- [ ] Ningún entity_id ni ID dinámico de HA en selectores
- [ ] Los `data-testid` siguen el formato `{dominio}-{entidad}-{variante}-{acción}`
- [ ] No hay testids duplicados en la misma vista

---

## HA Native Navigation

Add this section to document the native System navigation paths in Home Assistant that are not part of custom Lovelace panels. These routes and labels are part of the native HA UI and are consistently English-labelled across locales. Tests that need to reach native HA pages should navigate using UI controls (sidebar and links), not `page.goto()` to an internal route.

Recommended navigation steps (Playwright examples):

1. Sidebar → Settings (system configuration)

```typescript
// Open Settings via sidebar
await page.getByRole('link', { name: 'Settings' }).click();
await page.waitForSelector('[data-panel-id="config"]', { state: 'visible', timeout: 15000 });
```

2. Settings → Developer tools

```typescript
// In Settings, click Developer tools link (native UI element)
await page.getByRole('link', { name: 'Developer tools' }).click();
// Developer tools is a native HA label — always English: 'Developer tools'
await page.getByRole('heading', { name: 'Developer tools' }).waitFor({ state: 'visible' });
```

3. Developer tools → States / Devices tabs

```typescript
// Switch to the States tab
await page.getByRole('tab', { name: 'States' }).click();
await page.getByRole('tab', { name: 'States' }).waitFor({ state: 'visible' });

// Or switch to Devices
await page.getByRole('tab', { name: 'Devices' }).click();
await page.getByRole('tab', { name: 'Devices' }).waitFor({ state: 'visible' });
```

Notes:
- Do NOT use `page.goto()` to navigate to internal HA routes (e.g., `/config/developer-tools/state`) — these are client-side routes and bypass app initialization and auth state.
- Use `getByRole('link', { name: 'Developer tools' })` and `getByRole('tab', { name: 'States' })` because these native labels are stable and English across locales.
- After navigating, always run a `browser_snapshot` + stable state detection (see `playwright-session.skill.md`) before asserting selectors.

These steps are examples; prefer `ui-map.local.md` entries if they exist for a specific instance under test.
