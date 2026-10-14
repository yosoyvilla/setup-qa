import { Page, expect } from '@playwright/test';

export class ShopPage {
  constructor(private page: Page) {}

  async login(password = 'Passw0rd!') {
    await this.page.goto('/login');
    await this.page.getByTestId('login-email').fill('alice@example.com');
    await this.page.getByTestId('login-password').fill(password);
    await this.page.getByTestId('login-submit').click();
  }
}
