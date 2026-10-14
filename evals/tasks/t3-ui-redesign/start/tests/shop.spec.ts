import { test, expect } from '@playwright/test';

async function login(page, password = 'Passw0rd!') {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('login shows the user name in the header', async ({ page }) => {
  await login(page);
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('wrong password shows an error', async ({ page }) => {
  await login(page, 'nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});

test('search narrows the list to matching products', async ({ page }) => {
  await login(page);
  await page.getByTestId('search').fill('backpack');
  await expect(page.getByTestId(/^product-/)).toHaveCount(2);
});

test('adding a product updates the cart count', async ({ page }) => {
  await login(page);
  await page.getByTestId('add-3').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
