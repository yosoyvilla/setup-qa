import { test, expect } from '@playwright/test';

async function login(page, email = 'alice@example.com', password = 'Passw0rd!') {
  await page.goto('/login');
  await page.getByTestId('login-email').fill(email);
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('valid login', async ({ page }) => {
  await login(page);
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});
test('wrong password rejected with message', async ({ page }) => {
  await login(page, 'alice@example.com', 'nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});
test('unknown email rejected', async ({ page }) => {
  await login(page, 'bob@example.com', 'Passw0rd!');
  await expect(page).toHaveURL(/\/login/);
});
test('search filters', async ({ page }) => {
  await login(page);
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});
test('search is case-insensitive', async ({ page }) => {
  await login(page);
  await page.getByTestId('search').fill('MUG');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});
test('search ignores surrounding whitespace', async ({ page }) => {
  await login(page);
  await page.getByTestId('search').fill('  mug  ');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});
test('cart count follows each add up to four', async ({ page }) => {
  await login(page);
  for (const [i, id] of [1, 2, 3, 4].entries()) {
    await page.getByTestId(`add-${id}`).click();
    await expect(page.getByTestId('cart-count')).toHaveText(String(i + 1));
  }
});
