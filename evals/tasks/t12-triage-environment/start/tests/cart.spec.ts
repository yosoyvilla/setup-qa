import { test, expect } from '@playwright/test';

const base = process.env.BASE_URL ?? 'http://localhost:3000';

test('adding a product updates the cart count', async ({ page }) => {
  await page.goto(`${base}/login`);
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
