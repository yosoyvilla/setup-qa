import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.getByTestId('login-email').fill('alice@example.com');
  await page.getByTestId('login-password').fill('Passw0rd!');
  await page.getByTestId('login-submit').click();
  await expect(page).toHaveURL(/\/products/);
});

for (const q of ['mug', 'MUG']) {
  test(`search is case-insensitive: ${q}`, async ({ page }) => {
    await page.getByTestId('search').fill(q);
    await expect(page.getByTestId(/^product-/)).toHaveCount(1);
    await expect(page.getByTestId('results')).toContainText('Camp Mug');
  });
}

test('search with no matches shows nothing', async ({ page }) => {
  await page.getByTestId('search').fill('zzz');
  await expect(page.getByTestId(/^product-/)).toHaveCount(0);
});

test('cart accumulates', async ({ page }) => {
  await page.getByTestId('add-1').click();
  await page.getByTestId('add-2').click();
  await expect(page.getByTestId('cart-count')).toHaveText('2');
});
