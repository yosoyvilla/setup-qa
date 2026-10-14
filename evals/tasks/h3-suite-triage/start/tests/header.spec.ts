import { test, expect } from '@playwright/test';

test('header greets the user by first name', async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await expect(page.getByTestId('user-name')).toHaveText('Welcome, Alice');
});
