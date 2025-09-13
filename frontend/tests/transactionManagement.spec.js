// tests/transactionManagement.spec.js
const { test, expect } = require('@playwright/test');
const { login, createAccount } = require('./utils/baseTest');

test.describe('Transaction Management', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);

    // Create accounts for transaction testing
    const bankAccount = {
      name: 'Bank Account',
      type: 'ASSET',
      opening_balance: '1000.00',
    };
    const expenseAccount = {
      name: 'Office Expenses',
      type: 'EXPENSE',
      opening_balance: '0.00',
    };
    await createAccount(page, bankAccount);
    await createAccount(page, expenseAccount);
  });

  test('US-004: Record transactions', async ({ page }) => {
    await page.goto('http://localhost:8000/transactions');
    await page.click('button:has-text("Record Transaction")');

    // Fill transaction form
    await page.selectOption('select[name="account_id"]', {
      label: 'Bank Account (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Office Expenses (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '150.00');
    await page.fill('input[name="description"]', 'Office supplies');
    await page.click('button:has-text("Record Transaction")');

    // Verify success
    await expect(page.locator('.Toastify__toast--success')).toBeVisible();
    await expect(page.locator('text=Office supplies')).toBeVisible();
    await expect(page.locator('text=$150.00')).toBeVisible();

    // Verify account balances updated
    await page.goto('http://localhost:8000/accounts');
    await expect(
      page
        .locator('text=Bank Account')
        .locator('..')
        .locator('.account-balance'),
    ).toHaveText('$850.00');
  });

  test('US-005: Prevent negative balances', async ({ page }) => {
    await page.goto('http://localhost:8000/transactions');
    await page.click('button:has-text("Record Transaction")');

    // Attempt invalid transaction
    await page.selectOption('select[name="account_id"]', {
      label: 'Bank Account (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Office Expenses (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '1500.00');
    await page.click('button:has-text("Record Transaction")');

    // Verify error
    await expect(page.locator('.Toastify__toast--error')).toBeVisible();
    await expect(page.locator('.Toastify__toast--error')).toContainText(
      'Insufficient funds',
    );

    // Verify balance unchanged
    await page.goto('http://localhost:8000/accounts');
    await expect(
      page
        .locator('text=Bank Account')
        .locator('..')
        .locator('.account-balance'),
    ).toHaveText('$1,000.00');
  });

  test('US-004: Edge cases - duplicate and future transactions', async ({
    page,
  }) => {
    // First create a valid transaction
    await page.goto('http://localhost:8000/transactions');
    await page.click('button:has-text("Record New Transaction")');
    await page.selectOption('select[name="account_id"]', {
      label: 'Bank Account (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Office Expenses (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '100.00');
    await page.fill('input[name="description"]', 'Duplicate test');
    await page.click('button:has-text("Record Transaction")');
    await expect(page.locator('.Toastify__toast--success')).toBeVisible();

    // Attempt duplicate
    await page.click('button:has-text("Record New Transaction")');
    await page.selectOption('select[name="account_id"]', {
      label: 'Bank Account (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Office Expenses (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '100.00');
    await page.fill('input[name="description"]', 'Duplicate test');
    await page.click('button:has-text("Record Transaction")');
    await expect(page.locator('.Toastify__toast--warning')).toContainText(
      'possible duplicate',
    );

    // Future-dated transaction
    await page.click('button:has-text("Record New Transaction")');
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 7);
    const futureDateStr = futureDate.toISOString().split('T')[0];
    await page.selectOption('select[name="account_id"]', {
      label: 'Bank Account (ASSET)',
    });
    await page.selectOption('select[name="contra_account_id"]', {
      label: 'Office Expenses (EXPENSE)',
    });
    await page.fill('input[name="amount"]', '50.00');
    await page.fill('input[name="transaction_date"]', futureDateStr);
    await page.click('button:has-text("Record Transaction")');
    await expect(page.locator('.Toastify__toast--success')).toBeVisible();
    await expect(page.locator('text=Pending')).toBeVisible();
  });
});
