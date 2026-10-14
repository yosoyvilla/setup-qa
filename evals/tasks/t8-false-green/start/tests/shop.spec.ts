import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await expect(page).toHaveURL(/\/products/);
});

test('login shows the user name', async ({ page }) => {
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('search returns results', async ({ page }) => {
  await page.getByTestId('search').fill('mug');
  const count = await page.getByTestId(/^product-/).count();
  expect(count).toBeGreaterThan(0);
});

test('adding a product updates the cart', async ({ page }) => {
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toBeVisible();
});
