import { test, expect } from '@playwright/test';

test('adding a product updates the cart count', async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
