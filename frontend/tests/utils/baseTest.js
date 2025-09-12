// tests/utils/baseTest.js
const { test, expect } = require('@playwright/test');

// Helper function to login
async function login(page, username = 'testuser', password = 'testpassword') {
  await page.goto('/login'); // Use relative path, Playwright will resolve with baseURL
  await page.fill('input[name="username"]', username);
  await page.fill('input[name="password"]', password);
  await Promise.all([
    page.waitForNavigation(),
    page.click('button[type="submit"]'),
  ]);
  await expect(page).toHaveURL('/'); // Also use relative path
}

// Helper function to create account
async function createAccount(page, accountData) {
  await page.goto('/accounts');
  //await page.click('button:has-text("Create New Account")');

  
  await page.fill('input[name="name"]', accountData.name);
  await page.selectOption('select[name="type"]', accountData.type);
  if (accountData.description) {
    await page.fill('input[name="description"]', accountData.description);
  }
  await page.fill('input[name="opening_balance"]', accountData.opening_balance);

  await Promise.all([
    //page.waitForSelector('.Toastify__toast--success', { timeout: 5000 }),
    page.click('button:has-text("Create Account")'),
  ]);
  //await expect(page.locator('.Toastify__toast--success')).toBeVisible();
}

module.exports = { login, createAccount };