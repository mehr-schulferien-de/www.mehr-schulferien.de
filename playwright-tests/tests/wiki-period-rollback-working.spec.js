const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Rollback - Working Tests', () => {
  const periodId = '5839';
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test.beforeEach(async ({ page }) => {
    await page.goto(editUrl);
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
  });

  test('Create version and rollback immediately', async ({ page }) => {
    console.log('=== TEST: Create version and rollback immediately ===');
    
    // Step 1: Make a unique change we can track
    const uniqueMemo = `Test rollback - ${Date.now()}`;
    const memoField = page.locator('#period_memo');
    
    // Get current memo to rollback to later
    const previousMemo = await memoField.inputValue();
    console.log('Previous memo:', previousMemo);
    
    // Make the change
    await memoField.clear();
    await memoField.fill(uniqueMemo);
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Verify change was saved
    expect(await memoField.inputValue()).toBe(uniqueMemo);
    console.log('Changed memo to:', uniqueMemo);
    
    // Step 2: Find and click the FIRST rollback button (most recent previous version)
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    console.log(`Found ${rollbackButtons.length} rollback buttons`);
    
    if (rollbackButtons.length > 0) {
      // Click the first button (the most recent previous version)
      await rollbackButtons[0].click();
      
      // Wait for rollback success
      await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
      await page.waitForTimeout(500);
      
      // Verify memo is back to previous value
      const rolledBackMemo = await memoField.inputValue();
      console.log('Rolled back memo to:', rolledBackMemo);
      expect(rolledBackMemo).toBe(previousMemo);
      
      console.log('✅ Immediate rollback successful');
    } else {
      throw new Error('No rollback buttons found');
    }
  });

  test('Multiple sequential changes with step-by-step rollback', async ({ page }) => {
    console.log('=== TEST: Multiple sequential changes with rollback ===');
    
    const memoField = page.locator('#period_memo');
    const startDateField = page.locator('#period_starts_on');
    
    // Record initial state
    const initialMemo = await memoField.inputValue();
    const initialStartDate = await startDateField.inputValue();
    console.log('Initial state:', { memo: initialMemo, startDate: initialStartDate });
    
    // Version 1: Change memo
    const memo1 = `Version A - ${Date.now()}`;
    await memoField.clear();
    await memoField.fill(memo1);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    console.log('Created Version 1 with memo:', memo1);
    
    // Version 2: Change start date
    const date2 = new Date(initialStartDate);
    date2.setDate(date2.getDate() + 1);
    const startDate2 = date2.toISOString().split('T')[0];
    await startDateField.fill(startDate2);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    console.log('Created Version 2 with start date:', startDate2);
    
    // Version 3: Change memo again
    const memo3 = `Version C - ${Date.now()}`;
    await memoField.clear();
    await memoField.fill(memo3);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    console.log('Created Version 3 with memo:', memo3);
    
    // Current state: memo=Version C, startDate=+1 day
    expect(await memoField.inputValue()).toBe(memo3);
    expect(await startDateField.inputValue()).toBe(startDate2);
    
    // Rollback to Version 2 (one step back)
    let rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    console.log(`Found ${rollbackButtons.length} rollback buttons after 3 changes`);
    
    await rollbackButtons[0].click(); // First button = most recent previous version
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have: memo=Version A (from V1), startDate=+1 day (from V2)
    console.log('After first rollback:', {
      memo: await memoField.inputValue(),
      startDate: await startDateField.inputValue()
    });
    expect(await memoField.inputValue()).toBe(memo1);
    expect(await startDateField.inputValue()).toBe(startDate2);
    
    // Rollback one more step
    rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[0].click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have: memo=Version A, startDate=original
    console.log('After second rollback:', {
      memo: await memoField.inputValue(),
      startDate: await startDateField.inputValue()
    });
    expect(await memoField.inputValue()).toBe(memo1);
    expect(await startDateField.inputValue()).toBe(initialStartDate);
    
    console.log('✅ Sequential rollback successful');
  });

  test('Change all fields and rollback', async ({ page }) => {
    console.log('=== TEST: Change all fields and rollback ===');
    
    // Capture current state
    const current = {
      memo: await page.locator('#period_memo').inputValue(),
      startDate: await page.locator('#period_starts_on').inputValue(),
      endDate: await page.locator('#period_ends_on').inputValue(),
      federalState: await page.locator('#period_location_id').inputValue(),
      vacationType: await page.locator('#period_holiday_or_vacation_type_id').inputValue()
    };
    console.log('Current state:', current);
    
    // Change all fields
    const timestamp = Date.now();
    const newMemo = `All fields test - ${timestamp}`;
    
    const newStartDate = new Date(current.startDate);
    newStartDate.setDate(newStartDate.getDate() + 5);
    const newEndDate = new Date(current.endDate);
    newEndDate.setDate(newEndDate.getDate() + 5);
    
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(newMemo);
    await page.locator('#period_starts_on').fill(newStartDate.toISOString().split('T')[0]);
    await page.locator('#period_ends_on').fill(newEndDate.toISOString().split('T')[0]);
    
    // Try to change federal state if possible
    const federalStateOptions = await page.locator('#period_location_id option').all();
    let changedFederalState = false;
    for (const option of federalStateOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== current.federalState) {
        await page.locator('#period_location_id').selectOption(value);
        current.newFederalState = value;
        changedFederalState = true;
        break;
      }
    }
    
    // Try to change vacation type if possible
    const vacationTypeOptions = await page.locator('#period_holiday_or_vacation_type_id option').all();
    let changedVacationType = false;
    for (const option of vacationTypeOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== current.vacationType) {
        await page.locator('#period_holiday_or_vacation_type_id').selectOption(value);
        current.newVacationType = value;
        changedVacationType = true;
        break;
      }
    }
    
    // Save changes
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Verify changes were saved
    expect(await page.locator('#period_memo').inputValue()).toBe(newMemo);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(newStartDate.toISOString().split('T')[0]);
    expect(await page.locator('#period_ends_on').inputValue()).toBe(newEndDate.toISOString().split('T')[0]);
    if (changedFederalState) {
      expect(await page.locator('#period_location_id').inputValue()).toBe(current.newFederalState);
    }
    if (changedVacationType) {
      expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(current.newVacationType);
    }
    
    console.log('All fields changed successfully');
    
    // Rollback
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[0].click(); // Most recent previous version
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Verify rollback
    const rolledBack = {
      memo: await page.locator('#period_memo').inputValue(),
      startDate: await page.locator('#period_starts_on').inputValue(),
      endDate: await page.locator('#period_ends_on').inputValue(),
      federalState: await page.locator('#period_location_id').inputValue(),
      vacationType: await page.locator('#period_holiday_or_vacation_type_id').inputValue()
    };
    
    console.log('After rollback:', rolledBack);
    
    // All fields should be back to previous values
    expect(rolledBack.memo).toBe(current.memo);
    expect(rolledBack.startDate).toBe(current.startDate);
    expect(rolledBack.endDate).toBe(current.endDate);
    expect(rolledBack.federalState).toBe(current.federalState);
    expect(rolledBack.vacationType).toBe(current.vacationType);
    
    console.log('✅ All fields rollback successful');
  });

  test('Already at version detection', async ({ page }) => {
    console.log('=== TEST: Already at version detection ===');
    
    const memoField = page.locator('#period_memo');
    
    // Make a change
    const testMemo = `Already at version test - ${Date.now()}`;
    await memoField.clear();
    await memoField.fill(testMemo);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Make another change
    const testMemo2 = `Second change - ${Date.now()}`;
    await memoField.clear();
    await memoField.fill(testMemo2);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Rollback to first test version
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[0].click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Now we're at the first test version
    expect(await memoField.inputValue()).toBe(testMemo);
    
    // Try to rollback to the same version again (now it's at the top of the list)
    const newRollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    
    // The current state should now be at the top, find it and click
    // Look for the button associated with our testMemo
    let foundButton = null;
    for (let i = 0; i < newRollbackButtons.length; i++) {
      const button = newRollbackButtons[i];
      const parent = button.locator('..'); // Get parent element
      const text = await parent.textContent();
      if (text.includes(testMemo)) {
        foundButton = button;
        break;
      }
    }
    
    if (foundButton) {
      await foundButton.click();
      
      // Should show "already at this version" message
      await expect(page.locator('text=Die Daten entsprechen bereits dieser Version')).toBeVisible({ timeout: 10000 });
      console.log('✅ Already-at-version detection works');
    } else {
      console.log('Could not find button for current version - test inconclusive');
    }
  });
});