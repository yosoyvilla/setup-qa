import { test, expect } from '@playwright/test';

async function login(page, password: string) {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('valid login lands on products and shows the user name', async ({ page }) => {
  await login(page, 'Passw0rd!');
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('wrong password stays on login and shows an error', async ({ page }) => {
  await login(page, 'wrong');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});
