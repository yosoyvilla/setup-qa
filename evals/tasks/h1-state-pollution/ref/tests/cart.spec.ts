import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  // logging in resets the server-side cart
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await expect(page).toHaveURL(/\/products/);
});

test('adding a product shows 1 in the cart', async ({ page }) => {
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});

test('adding a different product also starts from an empty cart', async ({ page }) => {
  await page.getByTestId('add-2').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});

test('adding two products shows 2 in the cart', async ({ page }) => {
  await page.getByTestId('add-3').click();
  await page.getByTestId('add-4').click();
  await expect(page.getByTestId('cart-count')).toHaveText('2');
});
