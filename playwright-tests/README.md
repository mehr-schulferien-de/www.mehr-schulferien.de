# Playwright Tests for mehr-schulferien.de

This directory contains Playwright end-to-end tests for the mehr-schulferien.de application.

## Setup

1. Install dependencies:
   ```bash
   cd playwright-tests
   npm install
   ```

2. Install Playwright browsers:
   ```bash
   npx playwright install
   ```

## Running Tests

Make sure the Phoenix server is running on http://localhost:4000, then:

```bash
# Run all tests
npm test

# Run tests with UI mode (recommended for development)
npm run test:ui

# Run tests in debug mode
npm run test:debug

# Run a specific test file
npx playwright test wiki-period-edit-rollback.spec.js
```

## Important Notes

- The `wiki-period-edit-rollback.spec.js` test requires a valid period ID. You'll need to update the `periodId` variable in the test file with an actual period ID from your database that:
  - Is in the future (so it can be edited)
  - Belongs to a federal state
  - Has valid vacation type

## Test Coverage

### Wiki Period Edit and Rollback Tests
- Version history display with before/after values
- Successful rollback to previous versions
- Daily changes counter updates
- Date field changes and formatting