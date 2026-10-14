import { test, expect } from '@playwright/test';

async function login(page, password = 'Passw0rd!') {
  await page.goto('/login');
  await page.getByLabel('Email address').fill('alice@example.com');
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign in' }).click();
}

test('login shows the user name in the header', async ({ page }) => {
  await login(page);
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByRole('banner')).toContainText('Alice Reyes');
});

test('wrong password shows an error', async ({ page }) => {
  await login(page, 'nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByRole('alert')).toHaveText('Invalid credentials');
});

test('search narrows the list to matching products', async ({ page }) => {
  await login(page);
  await page.getByLabel('Search products').fill('backpack');
  await expect(page.getByRole('list', { name: 'Product list' }).getByRole('listitem')).toHaveCount(2);
});

test('adding a product updates the cart count', async ({ page }) => {
  await login(page);
  await page.getByRole('button', { name: 'Add Steel Bottle to cart' }).click();
  await expect(page.getByRole('link', { name: 'Cart' })).toContainText('1');
});
