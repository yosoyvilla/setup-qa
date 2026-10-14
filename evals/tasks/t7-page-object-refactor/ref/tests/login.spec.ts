import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page';

test('valid login shows the user name', async ({ page }) => {
  await new ShopPage(page).login();
  await expect(page).toHaveURL(/\/products/);
  await expect(page.getByTestId('user-name')).toHaveText('Alice Reyes');
});

test('wrong password shows an error', async ({ page }) => {
  await new ShopPage(page).login('nope');
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByTestId('login-error')).toHaveText('Invalid credentials');
});
