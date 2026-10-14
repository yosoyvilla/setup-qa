---
name: playwright-conventions
description: Conventions for writing reliable Playwright (TypeScript) tests - locator priority, web-first assertions, test structure and the commands to run them. Use when writing or editing Playwright tests (*.spec.ts) or choosing locators.
---

# Playwright conventions

## Inspect first

Never guess locators. Work in this order: open or fetch the page, look at the rendered state (screenshot, accessibility snapshot or the DOM), choose locators from what is really there, then write the actions. Check API shapes with `curl` before asserting on them. Wait for the page to be actually ready by asserting on an element, not by sleeping or relying on network idle.

If the application is not running, start it with the config's `webServer` option (`command`, `url`, `reuseExistingServer`) instead of a separate script.

## Locator priority

Use the first that works:

1. `getByRole('button', { name: 'Sign in' })`
2. `getByLabel('Email address')`
3. `getByText('...')` for static text
4. `getByTestId('login-submit')` when the app provides test ids
5. CSS or XPath only as a last resort

Locators must match exactly one element. Prefer a precise locator over `.first()`.

## Assertions

Use web-first assertions. They retry until the condition holds, so no sleeps are needed.

```ts
await expect(page).toHaveURL(/\/products/);
await expect(page.getByRole('alert')).toHaveText('Invalid credentials');
await expect(page.getByTestId(/^product-/)).toHaveCount(1);
```

Do not read a value once and assert on it (`const n = await loc.count(); expect(n)...`, `expect(await loc.textContent())...`). Those do not wait.

## Structure

- One behaviour per test, with a title that states the behaviour.
- Shared setup goes in `test.beforeEach` or a helper function, never copy-pasted per test.
- Each test is independent: it creates or resets the state it needs and passes when run alone, in any order, and twice in a row.
- Never edit `playwright.config.ts` unless asked. Use `baseURL` and relative paths (`page.goto('/login')`).

## Running

```bash
npx playwright test                         # whole suite
npx playwright test tests/login.spec.ts     # one file
npx playwright test -g "wrong password"     # by title
npx playwright test --repeat-each=5         # stability check
npx playwright test --trace on              # then: npx playwright show-trace <trace.zip>
```

## Lint

Run `~/.config/opencode/bin/qa-lint tests` before finishing; it fails on fixed sleeps, `.only`, skipped tests, retries and one-shot reads. For a project you own, also consider `eslint-plugin-playwright` (preset `flat/recommended`; see its README for the config). Its rules include `no-wait-for-timeout`, `no-skipped-test`, `no-focused-test`, `expect-expect`, `missing-playwright-await` and `prefer-web-first-assertions`.

## Anti-patterns

| Do not | Do instead |
| --- | --- |
| `await page.waitForTimeout(500)` | wait on the condition with `expect(...)` |
| `expect(count).toBeGreaterThan(0)` | assert the exact count or exact items |
| assert only that something is visible | assert its text or value |
| `test.skip` or deleting a failing test | find the cause and fix it |
| `.first()` to silence a strict-mode error | make the locator specific |
