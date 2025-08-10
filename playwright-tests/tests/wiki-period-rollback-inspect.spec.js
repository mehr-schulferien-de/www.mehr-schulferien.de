const { test, expect } = require('@playwright/test');

test.describe('Wiki Period Rollback - Inspect Versions', () => {
  const periodId = '5839';
  const editUrl = `/wiki/periods/${periodId}/edit`;

  test('Inspect version structure', async ({ page }) => {
    console.log('=== INSPECT: Version structure ===');
    
    // Go to the page
    await page.goto(`http://localhost:4000${editUrl}`);
    await expect(page.locator('h1')).toContainText('Ferientermin bearbeiten');
    
    // Get initial memo
    const memoField = page.locator('#period_memo');
    const initialMemo = await memoField.inputValue();
    console.log('Initial memo:', initialMemo);
    
    // Look at the version history structure
    const versionBlocks = await page.locator('.border-l-4.border-gray-300').all();
    console.log(`\nFound ${versionBlocks.length} version blocks initially\n`);
    
    for (let i = 0; i < Math.min(3, versionBlocks.length); i++) {
      const block = versionBlocks[i];
      const text = await block.textContent();
      console.log(`Version block ${i}:`);
      console.log(text.substring(0, 200) + '...');
      
      // Check if this block has a rollback button
      const button = block.locator('button:has-text("Zu dieser Version zurückkehren")');
      const hasButton = await button.count() > 0;
      if (hasButton) {
        const buttonId = await button.getAttribute('phx-value-version-id');
        console.log(`  Has rollback button with version ID: ${buttonId}`);
      } else {
        console.log(`  No rollback button`);
      }
      console.log('---');
    }
    
    // Make a change
    const testMemo = `Inspect test - ${Date.now()}`;
    console.log(`\nChanging memo to: ${testMemo}`);
    await memoField.clear();
    await memoField.fill(testMemo);
    await page.locator('button:has-text("Änderungen speichern")').click();
    await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(1000);
    
    // Look at versions again
    const newVersionBlocks = await page.locator('.border-l-4.border-gray-300').all();
    console.log(`\nAfter change, found ${newVersionBlocks.length} version blocks\n`);
    
    for (let i = 0; i < Math.min(3, newVersionBlocks.length); i++) {
      const block = newVersionBlocks[i];
      const text = await block.textContent();
      console.log(`Version block ${i} after change:`);
      
      // Extract key information
      if (text.includes('Notiz:')) {
        const notizMatch = text.match(/Notiz:([^→]+)(→([^→]+))?/);
        if (notizMatch) {
          console.log(`  Notiz change: "${notizMatch[1]?.trim()}" → "${notizMatch[3]?.trim() || notizMatch[1]?.trim()}"`);
        }
      }
      
      // Check button
      const button = block.locator('button:has-text("Zu dieser Version zurückkehren")');
      const hasButton = await button.count() > 0;
      if (hasButton) {
        const buttonId = await button.getAttribute('phx-value-version-id');
        console.log(`  Has rollback button with version ID: ${buttonId}`);
        
        // What happens if we click this button?
        console.log(`  Clicking button ${i}...`);
        await button.click();
        await page.waitForTimeout(2000);
        
        // Check for messages
        const messages = await page.locator('.bg-green-50, .bg-red-50, .bg-yellow-50').all();
        for (const msg of messages) {
          const msgText = await msg.textContent();
          console.log(`  Message after click: ${msgText.trim()}`);
        }
        
        // Check memo value
        const memoAfterClick = await memoField.inputValue();
        console.log(`  Memo after clicking button ${i}: ${memoAfterClick}`);
        
        // If it changed, make another change to test the next button
        if (memoAfterClick !== testMemo) {
          console.log('  Rollback seems to have worked, making another change to continue testing...');
          const nextMemo = `Continue test - ${Date.now()}`;
          await memoField.clear();
          await memoField.fill(nextMemo);
          await page.locator('button:has-text("Änderungen speichern")').click();
          await expect(page.locator('text=erfolgreich aktualisiert')).toBeVisible({ timeout: 10000 });
          await page.waitForTimeout(1000);
        }
      }
      console.log('---');
    }
  });
});