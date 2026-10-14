import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests',
  workers: 1,
  retries: 0,
  timeout: 15000,
  use: { baseURL: 'http://localhost:3000', headless: true },
  reporter: 'list',
});
