const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Edit and Rollback', () => {
  // You'll need to replace this with an actual period ID from your database
  const periodId = '5839'; // Example ID - replace with a real one
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test.beforeEach(async ({ page }) => {
    // Navigate to the edit page
    await page.goto(editUrl);
    
    // Wait for the page to load
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
  });

  test('should display version history with before/after values', async ({ page }) => {
    // Check initial state
    await expect(page.locator('h3:has-text("Versionshistorie")')).toBeVisible();
    
    // Make a change to the memo field
    const memoField = page.locator('#period_memo');
    await memoField.clear();
    await memoField.fill('First test memo');
    
    // Submit the form
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success message
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Check that version history now shows the change
    await expect(page.locator('.text-gray-800.dark\\:text-gray-200')).toContainText('Notiz:');
    
    // Make another change
    await memoField.clear();
    await memoField.fill('Second test memo');
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success message again
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Verify we can see the old value with strikethrough
    const versionHistory = page.locator('.space-y-3').first();
    await expect(versionHistory.locator('.line-through')).toBeVisible();
    await expect(versionHistory).toContainText('First test memo');
    await expect(versionHistory).toContainText('Second test memo');
    await expect(versionHistory).toContainText('→');
  });

  test('should successfully rollback to a previous version', async ({ page }) => {
    // First, make two changes to have something to rollback
    const memoField = page.locator('#period_memo');
    
    // First change
    await memoField.clear();
    await memoField.fill('Version 1 memo');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Second change
    await memoField.clear();
    await memoField.fill('Version 2 memo');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Now rollback to the first version
    // Click the rollback button for the first version (they are in reverse order)
    const rollbackButtons = page.locator('button:has-text("Zu dieser Version zurückkehren")');
    await rollbackButtons.nth(1).click(); // Second button is the older version
    
    // Wait for rollback success message
    await expect(page.locator('[role="alert"], .flash')).toContainText('Erfolgreich zur ausgewählten Version zurückgekehrt');
    
    // Verify the memo field now contains the rolled back value
    await expect(memoField).toHaveValue('Version 1 memo');
    
    // Verify version history shows the rollback as a new entry
    const versionHistory = page.locator('.space-y-3').first();
    await expect(versionHistory.locator('.text-green-600').first()).toContainText('Version 1 memo');
  });

  test('should update daily changes counter', async ({ page }) => {
    // Check initial daily changes display - more specific selector
    const counterElement = page.locator('text=Änderungen heute:').first();
    await expect(counterElement).toBeVisible();
    
    // Get initial count
    const initialCountText = await counterElement.textContent();
    const initialCount = parseInt(initialCountText.match(/(\d+) \//)[1]);
    
    // Make a change
    const memoField = page.locator('#period_memo');
    await memoField.clear();
    await memoField.fill('Test change for counter');
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Check that counter increased
    const newCountText = await counterElement.textContent();
    const newCount = parseInt(newCountText.match(/(\d+) \//)[1]);
    
    expect(newCount).toBe(initialCount + 1);
  });

  test('should handle date changes correctly', async ({ page }) => {
    // Change the start date
    const startDateField = page.locator('#period_starts_on');
    const currentStartDate = await startDateField.inputValue();
    
    // Set a new date (30 days from today)
    const newDate = new Date();
    newDate.setDate(newDate.getDate() + 30);
    const formattedDate = newDate.toISOString().split('T')[0];
    
    await startDateField.fill(formattedDate);
    
    // Submit the form
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success
    await expect(page.locator('[role="alert"], .flash')).toContainText('erfolgreich aktualisiert');
    
    // Verify version history shows the date change
    const versionHistory = page.locator('.space-y-3').first();
    await expect(versionHistory).toContainText('Beginn:');
    
    // Should show old date with strikethrough and new date
    await expect(versionHistory.locator('.line-through')).toBeVisible();
    await expect(versionHistory).toContainText('→');
  });
});