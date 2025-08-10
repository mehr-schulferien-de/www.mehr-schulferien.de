const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Rollback - Debug', () => {
  const periodId = '5839';
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test('Debug rollback functionality', async ({ page }) => {
    console.log('=== DEBUG: Rollback functionality ===');
    
    // Go to the page
    await page.goto(editUrl);
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
    
    // Make a simple change
    const memoField = page.locator('#period_memo');
    const originalMemo = await memoField.inputValue();
    console.log('Original memo:', originalMemo);
    
    const newMemo = `Debug test - ${Date.now()}`;
    await memoField.clear();
    await memoField.fill(newMemo);
    
    // Save
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(1000);
    
    console.log('Change saved successfully');
    
    // Find rollback buttons
    const rollbackButtons = await page.locator('button:has-text("Zu dieser Version zurückkehren")').all();
    console.log(`Found ${rollbackButtons.length} rollback buttons`);
    
    if (rollbackButtons.length > 0) {
      console.log('Clicking first rollback button...');
      
      // Click the first rollback button
      await rollbackButtons[0].click();
      
      // Wait a bit to see what happens
      await page.waitForTimeout(2000);
      
      // Check for ANY flash messages
      const flashMessages = await page.locator('[role="alert"], .flash, .bg-green-50, .bg-red-50, .bg-yellow-50').all();
      for (const flash of flashMessages) {
        const text = await flash.textContent();
        console.log('Flash message found:', text);
      }
      
      // Check if there's an error message
      const errorVisible = await page.locator('text=Fehler').isVisible().catch(() => false);
      if (errorVisible) {
        const errorText = await page.locator('text=Fehler').first().textContent();
        console.log('ERROR found:', errorText);
      }
      
      // Check if there's a success message
      const successVisible = await page.locator('text=Erfolgreich').isVisible().catch(() => false);
      if (successVisible) {
        const successText = await page.locator('text=Erfolgreich').first().textContent();
        console.log('SUCCESS found:', successText);
      }
      
      // Check if there's an "already at version" message
      const alreadyAtVisible = await page.locator('text=bereits').isVisible().catch(() => false);
      if (alreadyAtVisible) {
        const alreadyText = await page.locator('text=bereits').first().textContent();
        console.log('ALREADY AT VERSION found:', alreadyText);
      }
      
      // Check the current memo value
      const currentMemo = await memoField.inputValue();
      console.log('Memo after rollback attempt:', currentMemo);
      console.log('Did rollback work?', currentMemo === originalMemo ? 'YES' : 'NO');
    } else {
      console.log('No rollback buttons found!');
    }
  });
});