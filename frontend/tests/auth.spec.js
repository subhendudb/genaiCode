// tests/auth.spec.js
const { test, expect } = require('@playwright/test');

// Add a helper to get locators with fallback
function getLocator(page, options) {
  // Try data-testid first, then fallback to text or role
  if (options.testId) return page.getByTestId(options.testId);
  if (options.role && options.name) return page.getByRole(options.role, { name: options.name });
  if (options.text) return page.locator(`text=${options.text}`);
  throw new Error('No valid locator options provided');
}

test.describe('Authentication', () => {
  test('Successful login', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="username"]', 'testuser');
    await page.fill('input[name="password"]', 'testpassword');
    await Promise.all([
      getLocator(page, { testId: 'login-submit', role: 'button', name: 'Login', text: 'Login' }).click(),
    ]);
    await expect(page).toHaveURL('/');
    await expect(getLocator(page, { testId: 'logout', role: 'button', name: 'Logout', text: 'Logout' })).toBeVisible();
  });

  test('Failed login', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="username"]', 'wronguser');
    await page.fill('input[name="password"]', 'wrongpass');
    await Promise.all([
      getLocator(page, { testId: 'login-submit', role: 'button', name: 'Login', text: 'Login' }).click(),
    ]);
    await expect(page).toHaveURL('/login');
    await expect(getLocator(page, { testId: 'login-error', text: 'Invalid' })).toBeVisible();
  });

  test('Logout', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="username"]', 'testuser');
    await page.fill('input[name="password"]', 'testpassword');
    await Promise.all([
      getLocator(page, { testId: 'login-submit', role: 'button', name: 'Login', text: 'Login' }).click(),
    ]);
    await expect(page).toHaveURL('/');
    await expect(getLocator(page, { testId: 'logout', role: 'button', name: 'Logout', text: 'Logout' })).toBeVisible();
    await getLocator(page, { testId: 'logout', role: 'button', name: 'Logout', text: 'Logout' }).click();
  });
});