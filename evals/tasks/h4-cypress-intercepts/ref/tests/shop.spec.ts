import { test, expect } from '@playwright/test';

async function login(page, password = 'Passw0rd!') {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill(password);
  await page.getByTestId('login-submit').click();
}

test('signs in with the login helper', async ({ page }) => {
  await login(page);
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('rejects a wrong password', async ({ page }) => {
  await login(page, 'nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});

test('shows no products when the catalogue API returns an empty list', async ({ page }) => {
  await page.route('**/api/products*', (route) => route.fulfill({ json: [] }));
  const products = page.waitForResponse('**/api/products*');
  await login(page);
  await products;
  await expect(page.getByTestId(/^product-/)).toHaveCount(0);
});

test('filters products using the real API', async ({ page }) => {
  await login(page);
  const search = page.waitForResponse((r) => r.url().includes('/api/products') && r.url().includes('q=mug'));
  await page.getByTestId('search').fill('mug');
  await search;
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});

test('waits for the cart API before checking the badge', async ({ page }) => {
  await login(page);
  const cart = page.waitForResponse('**/api/cart');
  await page.getByTestId('add-1').click();
  expect((await cart).status()).toBe(200);
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
