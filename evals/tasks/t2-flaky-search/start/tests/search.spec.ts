import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await page.waitForTimeout(300);
});

test('search filters the product list', async ({ page }) => {
  await page.getByTestId('search').fill('mug');
  await page.waitForTimeout(200);
  const items = await page.getByTestId(/^product-/).count();
  expect(items).toBe(1);
  await expect(page.getByTestId('results')).toContainText('Camp Mug');
});

test('adding to cart updates the counter', async ({ page }) => {
  await page.getByTestId('add-1').click();
  await page.waitForTimeout(200);
  expect(await page.getByTestId('cart-count').textContent()).toBe('1');
});
