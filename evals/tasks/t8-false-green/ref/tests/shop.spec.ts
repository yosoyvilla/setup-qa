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

test('search returns only matching results', async ({ page }) => {
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
  await expect(page.getByTestId('results')).toContainText('Camp Mug');
});

test('adding a product updates the cart', async ({ page }) => {
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
