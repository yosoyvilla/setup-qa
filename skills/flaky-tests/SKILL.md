---
name: flaky-tests
description: How to reproduce, diagnose and fix flaky or order-dependent end-to-end tests - race conditions, fixed sleeps, shared state, stale reads. Use when a test passes sometimes and fails sometimes, passes locally but fails in CI, or fails only when run after another test or on a reused environment.
---

# Flaky tests

## 1. Reproduce first

```bash
npx playwright test --repeat-each=10 --workers=1       # timing flakiness
npx playwright test && npx playwright test             # state left over from the previous run
npx playwright test tests/a.spec.ts tests/b.spec.ts    # order dependence: run together, then alone
```

Read the actual error and the line it points at. Do not change anything until you can make it fail.

## 2. Root-cause checklist

- Fixed sleeps (`waitForTimeout`): the wait is a guess about speed. Search the WHOLE file, including `beforeEach` hooks and helpers.
- Reading a value once and asserting on it: `await loc.count()`, `await loc.textContent()`, `isVisible()` do not wait. Use `await expect(loc).toHaveCount(n)` and similar.
- Acting before the page is ready, or asserting before the response arrives.
- Shared state: server-side data (cart, session, records) that survives between tests or between runs. A test that passes alone and fails after another is order-dependent.
- Race between responses: an older request answering after a newer one.
- Time, timezone, locale, random data.
- Unawaited promises.

## 3. Fix the cause

- Replace sleeps and one-shot reads with web-first assertions that wait on the exact condition.
- When you need a specific response, create the wait BEFORE the action that triggers it:

```ts
const response = page.waitForResponse((r) => r.url().includes('/api/cart'));
await page.getByTestId('add-1').click();
await response;
```

- Isolate state: every test begins by establishing the state it needs (sign in again, call a reset endpoint, create unique data). Never rely on what a previous test left behind.

## 4. Not acceptable as a fix

Fixed sleeps, retries (`retries` in the config or `test.describe.configure({ retries })`), `test.skip`/`fixme`, loosening the assertion, mocking the network to hide a race. These hide the problem.

## 5. Prove it

Run the suite at least 10 times in a row (`--repeat-each=10`), and twice back to back against the same running application, with no failures.
