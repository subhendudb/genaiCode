// playwright.config.js
export default {
  testDir: './tests',
  timeout: 30000,
  expect: {
    timeout: 5000,
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // Use 1 worker on CI, default (all cores) locally
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    actionTimeout: 0,
    baseURL: 'http://localhost:8000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: {
        channel: 'chromium',
      },
    },
    // If you want to add more browsers, add them here
    // {
    //   name: 'firefox',
    //   use: { channel: 'firefox' },
    // },
    // {
    //   name: 'webkit',
    //   use: { channel: 'webkit' },
    // },
  ],
};
