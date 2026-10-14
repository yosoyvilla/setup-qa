---
name: page-objects
description: Refactoring Playwright specs to page objects or fixtures so each locator is defined once and tests read as intent. Use when several tests repeat the same login or navigation steps, locators are duplicated across files, or the user asks for a page object.
---

# Page objects

## When

Several tests share the same flow (login, navigation, adding to a cart) or the same locators. For a single short test, a helper function is enough.

## Rules

- Each locator and each shared flow is defined in exactly one place.
- Methods describe intent (`login()`, `search('mug')`), not clicks.
- Keep assertions in the tests, not hidden inside the page object, so a test says what it verifies.
- The class takes `page` in its constructor; no global state.
- Behaviour must not change: same tests, same assertions, same expected values. Run the suite before and after.

## Example

```ts
// pages/shop-page.ts
import { Page } from '@playwright/test';

export class ShopPage {
  constructor(private page: Page) {}

  async login(password = 'Passw0rd!') {
    await this.page.goto('/login');
    await this.page.getByTestId('login-email').fill('alice@example.com');
    await this.page.getByTestId('login-password').fill(password);
    await this.page.getByTestId('login-submit').click();
  }
}
```

```ts
// tests/login.spec.ts
import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page';

test('valid login shows the user name', async ({ page }) => {
  await new ShopPage(page).login();
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});
```

Use `test.extend` to provide the page object as a fixture when many specs need it.

## Finish

Search all specs for the raw locators you moved; none should remain duplicated.
