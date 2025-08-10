const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Rollback - Complete Test Suite', () => {
  const periodId = '5839';
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test.beforeEach(async ({ page }) => {
    await page.goto(editUrl);
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
  });

  test('Single field change and rollback', async ({ page }) => {
    console.log('=== TEST: Single field change and rollback ===');
    
    // Step 1: Capture original values
    const originalMemo = await page.locator('#period_memo').inputValue();
    const originalStartDate = await page.locator('#period_starts_on').inputValue();
    const originalEndDate = await page.locator('#period_ends_on').inputValue();
    const originalFederalState = await page.locator('#period_location_id').inputValue();
    const originalVacationType = await page.locator('#period_holiday_or_vacation_type_id').inputValue();
    
    console.log('Original values:', {
      memo: originalMemo,
      startDate: originalStartDate,
      endDate: originalEndDate,
      federalState: originalFederalState,
      vacationType: originalVacationType
    });
    
    // Step 2: Change only the memo field
    const newMemo = `Test memo - ${Date.now()}`;
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(newMemo);
    await page.locator('button:has-text("Änderungen speichern")').click();
    
    // Wait for success message
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Verify the change was saved
    expect(await page.locator('#period_memo').inputValue()).toBe(newMemo);
    
    // Step 3: Find the rollback button for the original version
    // The newest version should be at the top, so we want the LAST rollback button
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    console.log(`Found ${rollbackButtons.length} rollback buttons`);
    
    // Click the last button (oldest version)
    if (rollbackButtons.length > 0) {
      await rollbackButtons[rollbackButtons.length - 1].click();
      
      // Wait for rollback success
      await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
      await page.waitForTimeout(500);
      
      // Step 4: Verify ALL fields are back to original values
      expect(await page.locator('#period_memo').inputValue()).toBe(originalMemo);
      expect(await page.locator('#period_starts_on').inputValue()).toBe(originalStartDate);
      expect(await page.locator('#period_ends_on').inputValue()).toBe(originalEndDate);
      expect(await page.locator('#period_location_id').inputValue()).toBe(originalFederalState);
      expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(originalVacationType);
      
      console.log('✅ Single field rollback successful - ALL fields restored');
    } else {
      throw new Error('No rollback buttons found');
    }
  });

  test('Multiple field changes and rollback', async ({ page }) => {
    console.log('=== TEST: Multiple field changes and rollback ===');
    
    // Step 1: Capture original values
    const originalMemo = await page.locator('#period_memo').inputValue();
    const originalStartDate = await page.locator('#period_starts_on').inputValue();
    const originalEndDate = await page.locator('#period_ends_on').inputValue();
    const originalFederalState = await page.locator('#period_location_id').inputValue();
    const originalVacationType = await page.locator('#period_holiday_or_vacation_type_id').inputValue();
    
    // Step 2: Change multiple fields at once
    const newMemo = `Multi-change test - ${Date.now()}`;
    const startDate = new Date(originalStartDate);
    startDate.setDate(startDate.getDate() + 7);
    const newStartDate = startDate.toISOString().split('T')[0];
    
    const endDate = new Date(originalEndDate);
    endDate.setDate(endDate.getDate() + 7);
    const newEndDate = endDate.toISOString().split('T')[0];
    
    // Change memo, start date, and end date
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(newMemo);
    await page.locator('#period_starts_on').fill(newStartDate);
    await page.locator('#period_ends_on').fill(newEndDate);
    
    // Also change federal state if there are multiple options
    const federalStateOptions = await page.locator('#period_location_id option').all();
    if (federalStateOptions.length > 1) {
      // Find a different federal state
      for (const option of federalStateOptions) {
        const value = await option.getAttribute('value');
        if (value && value !== originalFederalState) {
          await page.locator('#period_location_id').selectOption(value);
          break;
        }
      }
    }
    
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Step 3: Rollback to original
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    if (rollbackButtons.length > 0) {
      await rollbackButtons[rollbackButtons.length - 1].click();
      await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
      await page.waitForTimeout(500);
      
      // Step 4: Verify ALL fields are restored
      expect(await page.locator('#period_memo').inputValue()).toBe(originalMemo);
      expect(await page.locator('#period_starts_on').inputValue()).toBe(originalStartDate);
      expect(await page.locator('#period_ends_on').inputValue()).toBe(originalEndDate);
      expect(await page.locator('#period_location_id').inputValue()).toBe(originalFederalState);
      expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(originalVacationType);
      
      console.log('✅ Multiple field rollback successful - ALL fields restored');
    }
  });

  test('Sequential changes and step-by-step rollback', async ({ page }) => {
    console.log('=== TEST: Sequential changes and step-by-step rollback ===');
    
    // Step 1: Capture original values
    const originalMemo = await page.locator('#period_memo').inputValue();
    const originalStartDate = await page.locator('#period_starts_on').inputValue();
    const originalEndDate = await page.locator('#period_ends_on').inputValue();
    
    // Step 2: Make first change (memo only)
    const memo1 = 'Version 1 - Memo only';
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(memo1);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Step 3: Make second change (dates)
    const startDate2 = new Date(originalStartDate);
    startDate2.setDate(startDate2.getDate() + 3);
    const newStartDate = startDate2.toISOString().split('T')[0];
    
    await page.locator('#period_starts_on').fill(newStartDate);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Step 4: Make third change (memo again)
    const memo3 = 'Version 3 - Final memo';
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(memo3);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Current state: memo=Version 3, startDate=modified, endDate=original
    expect(await page.locator('#period_memo').inputValue()).toBe(memo3);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(newStartDate);
    
    // Step 5: Rollback one step (to version 2)
    let rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[0].click(); // First button is the most recent previous version
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have: memo=Version 1, startDate=modified
    expect(await page.locator('#period_memo').inputValue()).toBe(memo1);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(newStartDate);
    
    // Step 6: Rollback another step (to version 1)
    rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[0].click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have: memo=Version 1, startDate=original
    expect(await page.locator('#period_memo').inputValue()).toBe(memo1);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(originalStartDate);
    
    // Step 7: Rollback to original
    rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[rollbackButtons.length - 1].click(); // Last button is original
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have all original values
    expect(await page.locator('#period_memo').inputValue()).toBe(originalMemo);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(originalStartDate);
    expect(await page.locator('#period_ends_on').inputValue()).toBe(originalEndDate);
    
    console.log('✅ Sequential rollback successful - step by step restoration works');
  });

  test('Multi-step rollback (skip intermediate versions)', async ({ page }) => {
    console.log('=== TEST: Multi-step rollback ===');
    
    // Step 1: Capture original values
    const originalMemo = await page.locator('#period_memo').inputValue();
    const originalStartDate = await page.locator('#period_starts_on').inputValue();
    
    // Step 2: Create multiple versions
    const versions = [
      { memo: 'Version A', startOffset: 1 },
      { memo: 'Version B', startOffset: 2 },
      { memo: 'Version C', startOffset: 3 },
      { memo: 'Version D', startOffset: 4 }
    ];
    
    for (const version of versions) {
      await page.locator('#period_memo').clear();
      await page.locator('#period_memo').fill(version.memo);
      
      const startDate = new Date(originalStartDate);
      startDate.setDate(startDate.getDate() + version.startOffset);
      await page.locator('#period_starts_on').fill(startDate.toISOString().split('T')[0]);
      
      await page.locator('button:has-text("Änderungen speichern")').click();
      await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
      await page.waitForTimeout(500);
    }
    
    // Current state: Version D with date+4
    expect(await page.locator('#period_memo').inputValue()).toBe('Version D');
    
    // Step 3: Skip directly to Version B (skip C)
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    // Buttons are in reverse order, so Version B should be at index 2 (0=C, 1=B, 2=A, 3=original)
    await rollbackButtons[2].click(); // Jump to Version B
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have Version B values
    const expectedDateB = new Date(originalStartDate);
    expectedDateB.setDate(expectedDateB.getDate() + 2);
    expect(await page.locator('#period_memo').inputValue()).toBe('Version B');
    expect(await page.locator('#period_starts_on').inputValue()).toBe(expectedDateB.toISOString().split('T')[0]);
    
    // Step 4: Jump directly to original (skip Version A)
    const newRollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await newRollbackButtons[newRollbackButtons.length - 1].click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Should have original values
    expect(await page.locator('#period_memo').inputValue()).toBe(originalMemo);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(originalStartDate);
    
    console.log('✅ Multi-step rollback successful - can skip intermediate versions');
  });

  test('Rollback with all field types', async ({ page }) => {
    console.log('=== TEST: Rollback with all field types ===');
    
    // Step 1: Capture ALL original values
    const original = {
      memo: await page.locator('#period_memo').inputValue(),
      startDate: await page.locator('#period_starts_on').inputValue(),
      endDate: await page.locator('#period_ends_on').inputValue(),
      federalState: await page.locator('#period_location_id').inputValue(),
      vacationType: await page.locator('#period_holiday_or_vacation_type_id').inputValue()
    };
    
    console.log('Original state:', original);
    
    // Step 2: Change ALL fields to different values
    const newValues = {
      memo: `Complete test - ${Date.now()}`,
      startDate: new Date(original.startDate),
      endDate: new Date(original.endDate)
    };
    
    newValues.startDate.setDate(newValues.startDate.getDate() + 10);
    newValues.endDate.setDate(newValues.endDate.getDate() + 10);
    
    // Change all text/date fields
    await page.locator('#period_memo').clear();
    await page.locator('#period_memo').fill(newValues.memo);
    await page.locator('#period_starts_on').fill(newValues.startDate.toISOString().split('T')[0]);
    await page.locator('#period_ends_on').fill(newValues.endDate.toISOString().split('T')[0]);
    
    // Change federal state to a different one
    const federalStateOptions = await page.locator('#period_location_id option').all();
    let newFederalState = original.federalState;
    for (const option of federalStateOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== original.federalState) {
        newFederalState = value;
        await page.locator('#period_location_id').selectOption(value);
        break;
      }
    }
    
    // Change vacation type to a different one
    const vacationTypeOptions = await page.locator('#period_holiday_or_vacation_type_id option').all();
    let newVacationType = original.vacationType;
    for (const option of vacationTypeOptions) {
      const value = await option.getAttribute('value');
      if (value && value !== original.vacationType) {
        newVacationType = value;
        await page.locator('#period_holiday_or_vacation_type_id').selectOption(value);
        break;
      }
    }
    
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Verify all changes were saved
    expect(await page.locator('#period_memo').inputValue()).toBe(newValues.memo);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(newValues.startDate.toISOString().split('T')[0]);
    expect(await page.locator('#period_ends_on').inputValue()).toBe(newValues.endDate.toISOString().split('T')[0]);
    expect(await page.locator('#period_location_id').inputValue()).toBe(newFederalState);
    expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(newVacationType);
    
    // Step 3: Rollback to original state
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    await rollbackButtons[rollbackButtons.length - 1].click();
    await expect(page.locator('text=Erfolgreich zur ausgewählten Version zurückgekehrt')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(500);
    
    // Step 4: Verify EVERYTHING is restored
    expect(await page.locator('#period_memo').inputValue()).toBe(original.memo);
    expect(await page.locator('#period_starts_on').inputValue()).toBe(original.startDate);
    expect(await page.locator('#period_ends_on').inputValue()).toBe(original.endDate);
    expect(await page.locator('#period_location_id').inputValue()).toBe(original.federalState);
    expect(await page.locator('#period_holiday_or_vacation_type_id').inputValue()).toBe(original.vacationType);
    
    console.log('✅ Complete field rollback successful - ALL field types restored');
  });
});