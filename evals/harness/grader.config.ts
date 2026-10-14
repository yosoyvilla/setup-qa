import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: process.env.TEST_DIR,
  workers: 1,
  retries: 0,
  timeout: 15000,
  use: { baseURL: process.env.BASE_URL, headless: true },
  reporter: 'json',
});
