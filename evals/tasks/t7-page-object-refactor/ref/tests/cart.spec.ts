import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page';

test('adding one product shows 1 in the cart', async ({ page }) => {
  await new ShopPage(page).login();
  await page.getByTestId('add-1').click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});

test('adding two products shows 2 in the cart', async ({ page }) => {
  await new ShopPage(page).login();
  await page.getByTestId('add-1').click();
  await page.getByTestId('add-2').click();
  await expect(page.getByTestId('cart-count')).toHaveText('2');
});
