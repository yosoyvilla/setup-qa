---
name: migrate-cypress
description: Ports Cypress tests to Playwright (TypeScript) keeping every test and assertion - command mapping, intercepts, custom commands, fixtures. Use when asked to migrate, convert or port Cypress specs (cypress/e2e/*.cy.js) to Playwright.
---

# Cypress to Playwright

Port every test. Keep the intent of every assertion. Run the result against the application and make sure it passes.

## Mapping

| Cypress | Playwright |
| --- | --- |
| `cy.visit('/x')` | `await page.goto('/x')` |
| `cy.get('[data-testid=a]')` | `page.getByTestId('a')` |
| `cy.get('[data-testid^=p-]')` | `page.getByTestId(/^p-/)` |
| `.type('text')` | `.fill('text')` |
| `.click()` | `.click()` |
| `.should('have.text', 'x')` | `await expect(loc).toHaveText('x')` |
| `.should('contain', 'x')` | `await expect(loc).toContainText('x')` |
| `.should('have.length', n)` | `await expect(loc).toHaveCount(n)` |
| `.should('be.visible')` | `await expect(loc).toBeVisible()` |
| `cy.url().should('include', '/x')` | `await expect(page).toHaveURL(/\/x/)` |
| `describe` / `it` / `beforeEach` | `test.describe` / `test` / `test.beforeEach` |

## Network

- Stubbing: `cy.intercept('GET', '/api/p*', { fixture: 'a.json' })` becomes `await page.route('**/api/p*', (route) => route.fulfill({ json: [...] }))`. Register the route before the navigation or action that triggers it. Load fixture JSON with `import data from './a.json'` or `fs`.
- Waiting: `cy.intercept(...).as('x')` followed by `cy.wait('@x')` becomes a promise created BEFORE the action:

```ts
const cart = page.waitForResponse('**/api/cart');
await page.getByTestId('add-1').click();
expect((await cart).status()).toBe(200);
```

## Custom commands and sessions

`Cypress.Commands.add('login', ...)` becomes a helper function (or a fixture) that takes `page`. `cy.session` maps to `storageState`.

## Traps

- Every Playwright action and assertion must be awaited; Cypress commands were queued automatically.
- Do not add sleeps. Cypress retried assertions; Playwright's `expect` does too.
- Keep one Playwright test per Cypress `it`; do not merge or drop any.
