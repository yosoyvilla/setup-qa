import { test, expect } from '@playwright/test';

async function login(page, password = 'Passw0rd!') {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('logs in and shows the user name', async ({ page }) => {
  await login(page);
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('rejects a wrong password', async ({ page }) => {
  await login(page, 'nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});

test('filters products by search', async ({ page }) => {
  await login(page);
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
  await expect(page.getByTestId('results')).toContainText('Camp Mug');
});

test('adds a product to the cart', async ({ page }) => {
  await login(page);
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
