const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Edit and Rollback - Comprehensive', () => {
  // Using the period ID from your example
  const periodId = '5839';
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test('should rollback ALL fields to their original values', async ({ page }) => {
    // Navigate to the edit page
    await page.goto(editUrl);
    
    // Wait for the page to load
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
    
    // Step 1: Capture the original values
    console.log('Step 1: Capturing original values...');
    
    // Get original values from the form fields
    const originalFederalState = await page.locator('#period_location_id').inputValue();
    const originalVacationType = await page.locator('#period_holiday_or_vacation_type_id').inputValue();
    const originalStartDate = await page.locator('#period_starts_on').inputValue();
    const originalEndDate = await page.locator('#period_ends_on').inputValue();
    const originalMemo = await page.locator('#period_memo').inputValue();
    
    console.log('Original values:', {
      federalState: originalFederalState,
      vacationType: originalVacationType,
      startDate: originalStartDate,
      endDate: originalEndDate,
      memo: originalMemo
    });
    
    // Step 2: Change ALL values to something different
    console.log('Step 2: Changing all values...');
    
    // Change federal state (select a different option)
    const federalStateSelect = page.locator('#period_location_id');
    const allFederalStateOptions = await federalStateSelect.locator('option').all();
    let newFederalStateValue;
    for (const option of allFederalStateOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== originalFederalState) {
        newFederalStateValue = value;
        break;
      }
    }
    if (newFederalStateValue) {
      await federalStateSelect.selectOption(newFederalStateValue);
    }
    
    // Change vacation type (select a different option)
    const vacationTypeSelect = page.locator('#period_holiday_or_vacation_type_id');
    const allVacationTypeOptions = await vacationTypeSelect.locator('option').all();
    let newVacationTypeValue;
    for (const option of allVacationTypeOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== originalVacationType) {
        newVacationTypeValue = value;
        break;
      }
    }
    if (newVacationTypeValue) {
      await vacationTypeSelect.selectOption(newVacationTypeValue);
    }
    
    // Change dates (add 10 days to both)
    const startDate = new Date(originalStartDate);
    startDate.setDate(startDate.getDate() + 10);
    const newStartDate = startDate.toISOString().split('T')[0];
    
    const endDate = new Date(originalEndDate);
    endDate.setDate(endDate.getDate() + 10);
    const newEndDate = endDate.toISOString().split('T')[0];
    
    await page.locator('#period_starts_on').fill(newStartDate);
    await page.locator('#period_ends_on').fill(newEndDate);
    
    // Change memo
    const memoField = page.locator('#period_memo');
    await memoField.clear();
    await memoField.fill('CHANGED: This is a completely different memo text for testing rollback');
    
    // Submit the form with all changes
    console.log('Step 3: Submitting changes...');
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success message
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    
    // Wait a bit for the page to update
    await page.waitForTimeout(1000);
    
    // Verify all values have changed in the form
    console.log('Step 4: Verifying changes were saved...');
    expect(await page.locator('#period_location_id').inputValue()).toBe(newFederalStateValue);
    expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(newVacationTypeValue);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(newStartDate);
    expect(await page.locator('#period_ends_on').inputValue()).toBe(newEndDate);
    expect(await page.locator('#period_memo').inputValue()).toBe('CHANGED: This is a completely different memo text for testing rollback');
    
    // Step 5: Find and click the rollback button for the previous version
    console.log('Step 5: Performing rollback...');
    
    // The rollback buttons are ordered newest first, so we want the SECOND button
    // (first button would be for the current version we just created)
    const rollbackButtons = page.locator('button:has-text("Zu dieser Version zurückkehren")');
    const buttonCount = await rollbackButtons.count();
    console.log(`Found ${buttonCount} rollback buttons`);
    
    if (buttonCount >= 2) {
      // Click the second button (previous version)
      await rollbackButtons.nth(1).click();
    } else if (buttonCount === 1) {
      // If there's only one button, click it
      await rollbackButtons.first().click();
    } else {
      throw new Error('No rollback buttons found!');
    }
    
    // Wait for rollback success message
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    
    // Wait a bit for the form to update
    await page.waitForTimeout(1000);
    
    // Step 6: Verify ALL values are back to their original state
    console.log('Step 6: Verifying all values are rolled back to original...');
    
    const rolledBackFederalState = await page.locator('#period_location_id').inputValue();
    const rolledBackVacationType = await page.locator('#period_holiday_or_vacation_type_id').inputValue();
    const rolledBackStartDate = await page.locator('#period_starts_on').inputValue();
    const rolledBackEndDate = await page.locator('#period_ends_on').inputValue();
    const rolledBackMemo = await page.locator('#period_memo').inputValue();
    
    console.log('Rolled back values:', {
      federalState: rolledBackFederalState,
      vacationType: rolledBackVacationType,
      startDate: rolledBackStartDate,
      endDate: rolledBackEndDate,
      memo: rolledBackMemo
    });
    
    // Assert all values match the original
    expect(rolledBackFederalState).toBe(originalFederalState);
    expect(rolledBackVacationType).toBe(originalVacationType);
    expect(rolledBackStartDate).toBe(originalStartDate);
    expect(rolledBackEndDate).toBe(originalEndDate);
    expect(rolledBackMemo).toBe(originalMemo);
    
    console.log('✅ All fields successfully rolled back to original values!');
  });

  test('should create a new version entry after rollback', async ({ page }) => {
    // Navigate to the edit page
    await page.goto(editUrl);
    
    // Wait for the page to load
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
    
    // Count initial versions
    const initialVersionCount = await page.locator('.border-l-4.border-gray-300').count();
    console.log(`Initial version count: ${initialVersionCount}`);
    
    // Make a change
    const memoField = page.locator('#period_memo');
    const originalMemo = await memoField.inputValue();
    await memoField.clear();
    await memoField.fill('Test version for rollback history');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    
    // Wait for version history to update
    await page.waitForTimeout(1000);
    
    // Count versions after change
    const afterChangeCount = await page.locator('.border-l-4.border-gray-300').count();
    console.log(`Version count after change: ${afterChangeCount}`);
    expect(afterChangeCount).toBeGreaterThan(initialVersionCount);
    
    // Perform rollback
    const rollbackButtons = page.locator('button:has-text("Zu dieser Version zurückkehren")');
    if (await rollbackButtons.count() >= 2) {
      await rollbackButtons.nth(1).click();
    } else {
      await rollbackButtons.first().click();
    }
    
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(1000);
    
    // Count versions after rollback
    const afterRollbackCount = await page.locator('.border-l-4.border-gray-300').count();
    console.log(`Version count after rollback: ${afterRollbackCount}`);
    
    // Rollback should create a new version
    expect(afterRollbackCount).toBeGreaterThan(afterChangeCount);
    
    // Verify the memo is back to original
    expect(await memoField.inputValue()).toBe(originalMemo);
  });

  test('should handle multiple rollbacks correctly', async ({ page }) => {
    // Navigate to the edit page
    await page.goto(editUrl);
    
    // Wait for the page to load
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
    
    // Capture original memo
    const memoField = page.locator('#period_memo');
    const originalMemo = await memoField.inputValue();
    
    // Make first change
    await memoField.clear();
    await memoField.fill('Version A');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Make second change
    await memoField.clear();
    await memoField.fill('Version B');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Make third change
    await memoField.clear();
    await memoField.fill('Version C');
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Now we have: original -> A -> B -> C
    // Current state is C
    expect(await memoField.inputValue()).toBe('Version C');
    
    // Rollback to Version B (should be 2nd rollback button)
    let rollbackButtons = page.locator('button:has-text("Zu dieser Version zurückkehren")');
    await rollbackButtons.nth(1).click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    expect(await memoField.inputValue()).toBe('Version B');
    
    // Rollback to Version A (should now be 3rd or 4th button depending on history)
    rollbackButtons = page.locator('button:has-text("Zu dieser Version zurückkehren")');
    const buttonCount = await rollbackButtons.count();
    // Find the button for Version A by checking surrounding text
    for (let i = 0; i < buttonCount; i++) {
      const parent = rollbackButtons.nth(i).locator('..');
      const text = await parent.textContent();
      if (text.includes('Version A')) {
        await rollbackButtons.nth(i).click();
        break;
      }
    }
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    expect(await memoField.inputValue()).toBe('Version A');
  });
});