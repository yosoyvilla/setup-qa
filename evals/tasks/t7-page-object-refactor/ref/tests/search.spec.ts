import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page';

test('search narrows the list', async ({ page }) => {
  await new ShopPage(page).login();
  await page.getByTestId('search').fill('mug');
  await expect(page.getByTestId(/^product-/)).toHaveCount(1);
});
