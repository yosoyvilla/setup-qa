import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
});

test('search for mug returns exactly one product', async ({ page }) => {
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});

test('search for bag returns exactly two products', async ({ page }) => {
  await page.getByTestId('search').fill('bag');
  await expect(page.getByTestId(/^product-/)).toHaveCount(2);
});

test('an empty search lists all five products', async ({ page }) => {
  await expect(page.getByTestId(/^product-/)).toHaveCount(5);
});
