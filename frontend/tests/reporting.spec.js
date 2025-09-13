// tests/reporting.spec.js
const { test, expect } = require('@playwright/test');
const { login, createAccount } = require('./utils/baseTest');

test.describe('Reporting', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);

    // Setup test data
    const assetAccount = {
      name: 'Test Asset',
      type: 'ASSET',
      opening_balance: '2000.00',
    };
    const liabilityAccount = {
      name: 'Test Liability',
      type: 'LIABILITY',
      opening_balance: '500.00',
    };
    const incomeAccount = {
      name: 'Test Income',
      type: 'INCOME',
      opening_balance: '0.00',
    };
    const expenseAccount = {
      name: 'Test Expense',
      type: 'EXPENSE',
      opening_balance: '0.00',
    };
    await createAccount(page, assetAccount);
    await createAccount(page, liabilityAccount);
    await createAccount(page, incomeAccount);
    await createAccount(page, expenseAccount);

    // Create some transactions
    await page.goto('http://localhost:8000/transactions');
    await page.click('button:has-text("Record New Transaction")');
    await page.selectOption('select[name="account_id"]', {
      label: 'Test Income (INCOME)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Test Asset (ASSET)',
    });
    await page.fill('input[name="amount"]', '1000.00');
    await page.fill('input[name="description"]', 'Income transaction');
    await page.click('button:has-text("Record Transaction")');

    await page.click('button:has-text("Record New Transaction")');
    await page.selectOption('select[name="account_id"]', {
      label: 'Test Asset (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Test Expense (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '500.00');
    await page.fill('input[name="description"]', 'Expense transaction');
    await page.click('button:has-text("Record Transaction")');
  });

  test('US-006: Generate account status report', async ({ page }) => {
    await page.goto('http://localhost:8000/reports');
    await page.click('button:has-text("Balance Report")');

    // Verify report content
    await expect(page.locator('text=Balance Sheet Report')).toBeVisible();
    await expect(page.locator('text=Test Asset')).toBeVisible();
    await expect(page.locator('text=$2,500.00')).toBeVisible(); // 2000 + 1000 - 500
    await expect(page.locator('text=Test Liability')).toBeVisible();
    await expect(page.locator('text=$500.00')).toBeVisible();
    await expect(page.locator('text=Net Worth')).toBeVisible();
    await expect(page.locator('text=$2,000.00')).toBeVisible(); // 2500 - 500
  });

  test('US-007: Monthly profit/loss report', async ({ page }) => {
    await page.goto('http://localhost:8000/reports');
    await page.click('button:has-text("Profit & Loss")');

    // Verify report content
    await expect(page.locator('text=Profit & Loss Statement')).toBeVisible();
    await expect(page.locator('text=Total Income')).toBeVisible();
    await expect(page.locator('text=$1,000.00')).toBeVisible();
    await expect(page.locator('text=Total Expenses')).toBeVisible();
    await expect(page.locator('text=($500.00)')).toBeVisible();
    await expect(page.locator('text=Net Profit/Loss')).toBeVisible();
    await expect(page.locator('text=$500.00')).toBeVisible();
  });
});
