import { test, expect } from '@playwright/test';

async function login(page, password: string) {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('valid login lands on products', async ({ page }) => {
  await login(page, 'Passw0rd!');
  await expect(page).toHaveURL(/\/products/);
});

test('wrong password shows an error', async ({ page }) => {
  await login(page, 'nope');
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});
