import { test, expect } from '@playwright/test';

test('search narrows the list', async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});
