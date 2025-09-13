# Playwright E2E Tests

This directory contains all Playwright end-to-end tests for the Financial Management System.

## Directory Structure

```
testing/playwright/
├── README.md                           # This file
├── accountManagement.spec.js          # Account management tests
├── auth.spec.js                       # Authentication tests
├── reporting.spec.js                  # Reporting tests
├── transactionManagement.spec.js      # Transaction management tests
├── utils/
│   └── baseTest.js                    # Common test utilities
├── playwright-report/                 # HTML test reports
│   └── index.html
└── test-results/                      # Test execution results
    └── [test-results-directories]/
```

## Test Files

### Core Test Suites

- **`accountManagement.spec.js`** - Tests for account creation, updates, and management
- **`auth.spec.js`** - Authentication and authorization tests
- **`reporting.spec.js`** - Financial reporting functionality tests
- **`transactionManagement.spec.js`** - Transaction recording and management tests

### Utilities

- **`utils/baseTest.js`** - Common test utilities and helper functions

## Running Tests

### Prerequisites

1. Ensure the application is running (`npm start` in frontend directory)
2. Ensure backend API is running on `http://localhost:8000`
3. Install Playwright dependencies: `npm install` in frontend directory

### Running All Tests

```bash
# From the frontend directory
npm run test:e2e

# Or from the project root
cd frontend && npm run test:e2e
```

### Running Specific Test Files

```bash
# Run only authentication tests
npx playwright test auth.spec.js

# Run only account management tests
npx playwright test accountManagement.spec.js

# Run tests in headed mode (see browser)
npx playwright test --headed

# Run tests in debug mode
npx playwright test --debug
```

### Running Tests with Different Browsers

```bash
# Run on Chromium only
npx playwright test --project=chromium

# Run on all configured browsers
npx playwright test
```

## Test Configuration

The Playwright configuration is located at `frontend/playwright.config.js` and includes:

- Test directory: `../testing/playwright`
- Timeout settings: 30 seconds for tests, 5 seconds for expectations
- Base URL: `http://localhost:8000`
- Reporter: HTML report generation
- Browser projects: Chromium (with options for Firefox and WebKit)

## Test Reports

### HTML Reports

After running tests, view the HTML report:

```bash
npx playwright show-report
```

The report will be available at `testing/playwright/playwright-report/index.html`

### Test Results

Detailed test results are stored in `testing/playwright/test-results/` including:

- Screenshots of failures
- Video recordings (if enabled)
- Error context and stack traces

## Writing New Tests

### Test Structure

```javascript
const { test, expect } = require('@playwright/test');
const { login, createAccount } = require('./utils/baseTest');

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('Test description', async ({ page }) => {
    // Test implementation
    await expect(page.locator('selector')).toBeVisible();
  });
});
```

### Best Practices

1. Use descriptive test names
2. Group related tests in `test.describe` blocks
3. Use `beforeEach` for common setup
4. Use helper functions from `utils/baseTest.js`
5. Use data-testid attributes for reliable element selection
6. Clean up after tests if necessary

### Helper Functions

Available in `utils/baseTest.js`:

- `login(page, username, password)` - Login with credentials
- `createAccount(page, accountData)` - Create a new account
- `getLocator(page, options)` - Get element locators with fallbacks

## Debugging Tests

### Debug Mode

```bash
npx playwright test --debug
```

### Headed Mode

```bash
npx playwright test --headed
```

### Screenshots and Videos

- Screenshots are automatically taken on test failures
- Videos can be enabled in `playwright.config.js`
- All artifacts are stored in `test-results/`

## CI/CD Integration

Tests are integrated into the main test suite via `testing/run_all_tests.sh`:

- Tests run automatically in CI/CD pipelines
- Results are included in comprehensive test reports
- Failed tests will cause the pipeline to fail

## Troubleshooting

### Common Issues

1. **Tests timing out**: Increase timeout in config or check application responsiveness
2. **Element not found**: Use `data-testid` attributes or wait for elements to load
3. **Authentication issues**: Ensure login helper is working correctly
4. **Port conflicts**: Ensure port 8000 is available for the backend

### Debug Commands

```bash
# Show all available commands
npx playwright --help

# List all tests
npx playwright test --list

# Run tests with trace
npx playwright test --trace on

# Generate test code from browser actions
npx playwright codegen
```

## Test Data

Test data is managed within each test file or in the `utils/baseTest.js` file. For consistent test data:

- Use the same test accounts across all tests
- Clean up test data after tests complete
- Use realistic but non-sensitive data

## Maintenance

- Update tests when UI changes
- Keep test utilities up to date
- Regularly review and clean up test results
- Monitor test execution times and optimize slow tests

---
*Last Updated: $(date)*
*Test Directory Version: 1.0*
