import { test, expect } from '@playwright/test';

test('brand preview replays once, switches theme, respects reduced motion and downloads assets', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/brand-studio.html#applications');
  const core = page.locator('#launch-core');
  await page.getByRole('button', { name: '播放启动效果' }).click();
  await expect(core).toHaveClass(/is-playing/);
  await expect(core).not.toHaveClass(/is-playing/, { timeout: 5000 });
  await page.getByRole('button', { name: '深色预览' }).click();
  await expect(page.locator('#launch-phone')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('#launch-mark')).toHaveAttribute('src', '/brand/fangcun-mark-white.svg');
  await page.getByLabel('减少动态效果').check();
  await page.getByRole('button', { name: '播放启动效果' }).click();
  await expect(core).not.toHaveClass(/is-playing/);
  await expect(page.getByRole('status')).toContainText('静态展示');
  await page.screenshot({ path: 'artifacts/brand-applications-desktop.png' });
  const download = page.waitForEvent('download');
  await page.getByRole('link', { name: '下载完整品牌素材包' }).click();
  expect((await download).suggestedFilename()).toBe('fangcun-brand-kit-v1.zip');
  expect(errors).toEqual([]);
});

test('brand applications fit a narrow screen and system reduced motion stays static', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/brand-studio.html#applications');
  await expect(page.getByLabel('减少动态效果')).toBeChecked();
  await page.getByRole('button', { name: '播放启动效果' }).click();
  await expect(page.locator('#launch-core')).not.toHaveClass(/is-playing/);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: 'artifacts/brand-applications-mobile.png', fullPage: true });
  await page.goto('/');
  await page.getByRole('button', { name: '设置', exact: true }).click();
  await page.getByRole('link', { name: '方寸的寓意与设计' }).click();
  await expect(page).toHaveURL(/brand-studio.html/);
});
