import { test, expect } from '@playwright/test';
import { mkdirSync } from 'node:fs';
mkdirSync('artifacts', { recursive: true });

test.beforeEach(async ({ page }) => { await page.goto('/'); });

test('three scenarios keep the conclusion and direct action visible; details agree', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await expect(page.getByRole('heading', { name: '今日压力负荷平稳' })).toBeVisible();
  const cta = page.getByRole('button', { name: /开始 5 分钟呼吸/ });
  await expect(cta).toBeInViewport();
  await page.screenshot({ animations: 'disabled', path: 'artifacts/01-home-light-desktop.png', fullPage: true });
  await page.getByRole('button', { name: '偏高', exact: true }).click();
  await expect(page.getByRole('heading', { name: '今日压力负荷偏高' })).toBeVisible();
  await page.getByRole('button', { name: '为什么这样判断', exact: true }).click();
  await expect(page.getByText('5 小时 36 分', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: '返回今日' }).click();
  await page.getByRole('button', { name: '数据不足', exact: true }).click();
  await expect(page.getByRole('heading', { name: '暂时还无法判断' })).toBeVisible();
  await cta.click();
  await expect(page.getByTestId('breathing-session')).toBeVisible();
  expect(errors).toEqual([]);
});

test('compound drink increments, decrement, undo, keyboard close and persistence', async ({ page }) => {
  await page.getByRole('button', { name: /今天喝了什么/ }).click();
  const sheet = page.getByRole('dialog', { name: '今日饮品记录' });
  await expect(sheet.locator('.character-artwork')).toHaveAttribute('data-character', 'dog');
  await expect(sheet.locator('img')).toHaveAttribute('src', '/characters/v4/dog-drink.png');
  await page.getByLabel('咖啡类型').selectOption('sweetCoffee');
  await page.getByRole('button', { name: '增加咖啡', exact: true }).click();
  await expect(page.getByTestId('total-fluid')).toHaveText('300 ml');
  await expect(page.getByTestId('total-caffeine')).toHaveText('140 mg');
  await expect(page.getByTestId('total-sugar')).toHaveText('1 份');
  await page.getByRole('button', { name: '增加白水', exact: true }).click();
  await expect(page.getByTestId('total-fluid')).toHaveText('550 ml');
  await expect(sheet.locator('.drink-response')).toHaveText('已增加一杯白水');
  await page.getByRole('button', { name: '减少咖啡', exact: true }).click();
  await expect(page.getByTestId('total-caffeine')).toHaveText('0 mg');
  await page.getByRole('button', { name: '撤销上一笔' }).click();
  await expect(page.getByTestId('total-caffeine')).toHaveText('140 mg');
  await expect(page.getByTestId('total-sugar')).toHaveText('1 份');
  const phoneBox = await page.locator('.phone-frame').boundingBox();
  const sheetBox = await sheet.boundingBox();
  expect(sheetBox.height / (phoneBox.height - 12)).toBeCloseTo(.5, 1);
  await page.screenshot({ animations: 'disabled', path: 'artifacts/02-composite-drink-sheet.png' });
  await page.keyboard.press('Escape');
  await expect(sheet).not.toBeVisible();
  await expect(page.getByRole('button', { name: /今天喝了什么/ })).toBeFocused();
  await page.reload();
  await expect(page.getByText('已记 2 杯 · 总液体 550 ml')).toBeVisible();
  await page.getByRole('button', { name: /看看这一周的节奏/ }).click();
  await expect(page.getByText('总液体 550 ml · 咖啡因 140 mg')).toBeVisible();
});

test('breathing phase timing freezes on pause and exit confirmation; early exit records duration', async ({ page }) => {
  await page.clock.install();
  await page.getByRole('button', { name: /开始 5 分钟呼吸/ }).click();
  await page.clock.runFor(4200);
  await expect(page.getByTestId('phase-label')).toHaveText('再补一小口');
  await page.getByRole('button', { name: '暂停练习', exact: true }).click();
  const paused = await page.getByTestId('remaining-time').textContent();
  await page.clock.runFor(6000);
  await expect(page.getByTestId('remaining-time')).toHaveText(paused);
  await page.getByRole('button', { name: '继续练习', exact: true }).click();
  await page.clock.runFor(1400);
  await expect(page.getByTestId('phase-label')).toHaveText('缓缓呼气');
  await page.screenshot({ animations: 'disabled', path: 'artifacts/03-breathing.png' });
  await page.getByRole('button', { name: '结束练习', exact: true }).click();
  const atExit = await page.getByTestId('remaining-time').textContent();
  await page.clock.runFor(12000);
  await expect(page.getByTestId('remaining-time')).toHaveText(atExit);
  await page.getByRole('button', { name: '结束并记录', exact: true }).click();
  await expect(page.getByRole('heading', { name: '这次，就到这里。' })).toBeVisible();
  await expect(page.locator('.completion-view .companions')).toHaveAttribute('data-pose', 'rest');
  await page.getByRole('button', { name: '返回今日首页' }).click();
  await page.getByRole('button', { name: /看看这一周的节奏/ }).click();
  await expect(page.getByText(/已记录 1 次/)).toBeVisible();
});

test('five-minute session completes once with an honest local completion record', async ({ page }) => {
  await page.clock.install();
  await page.getByRole('button', { name: /开始 5 分钟呼吸/ }).click();
  // Skip idle frames, like a delayed render, while retaining the full 300-second duration.
  await page.clock.fastForward(301000);
  await page.clock.runFor(100);
  await expect(page.getByRole('heading', { name: '这 5 分钟，属于你。' })).toBeVisible();
  await expect(page.locator('.completion-view .companions')).toHaveAttribute('data-pose', 'touch');
  await page.screenshot({ animations: 'disabled', path: 'artifacts/10-completion-companions.png' });
  await expect(page.getByText('已记录在本机', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: '返回今日首页' }).click();
  await expect(page.getByRole('heading', { name: '今日压力负荷平稳' })).toBeVisible();
  await page.getByRole('button', { name: /看看这一周的节奏/ }).click();
  await expect(page.getByText('已记录 1 次 · 5:00')).toBeVisible();
});

test('mobile dark mode, large type, missing-day snapshot and no horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await expect(page.getByRole('button', { name: /开始 5 分钟呼吸/ })).toBeInViewport();
  await page.screenshot({ animations: 'disabled', path: 'artifacts/04-home-mobile.png' });
  await page.getByRole('button', { name: '切换深浅色模式' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  const bg = await page.locator('.phone-frame').evaluate(el => getComputedStyle(el).backgroundColor);
  expect(bg).toBe('rgb(18, 22, 26)');
  await page.getByRole('button', { name: '切换大字号' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-large', 'true');
  await page.screenshot({ animations: 'disabled', path: 'artifacts/05-dark-large-type.png' });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.getByRole('button', { name: /看看这一周的节奏/ }).click();
  await page.getByRole('button', { name: '9月13日 数据不足' }).click();
  await expect(page.getByText('9 月 13 日', { exact: true })).toBeVisible();
  await expect(page.locator('.day-snapshot').getByText('资料不足')).toHaveCount(0);
  await expect(page.locator('.day-snapshot').getByText('数据不足', { exact: true })).toBeVisible();
  await expect(page.locator('.day-snapshot').getByText('暂无完整记录')).toHaveCount(2);
  await page.screenshot({ animations: 'disabled', path: 'artifacts/06-trends-dark-large.png' });
  expect(await page.locator('.app-scroll').evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
});

test('caffeine preferences preserve existing records and reduced motion keeps pets still', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-reduced', 'true');
  await page.getByRole('button', { name: /今天喝了什么/ }).click();
  await page.getByRole('button', { name: '增加咖啡', exact: true }).click();
  await page.getByRole('button', { name: '记好了' }).click();
  await page.getByRole('navigation').getByRole('button', { name: '设置', exact: true }).click();
  await page.getByLabel('每杯咖啡因毫克数').fill('90');
  await page.getByRole('navigation').getByRole('button', { name: '今日', exact: true }).click();
  await page.getByRole('button', { name: /今天喝了什么/ }).click();
  await expect(page.getByTestId('total-caffeine')).toHaveText('140 mg');
  await page.getByRole('button', { name: '增加咖啡', exact: true }).click();
  await expect(page.getByTestId('total-caffeine')).toHaveText('230 mg');
  await page.getByRole('button', { name: '记好了' }).click();
  await page.clock.install();
  await page.getByRole('button', { name: /开始 5 分钟呼吸/ }).click();
  await page.clock.runFor(200);
  const firstOpacity = await page.locator('.breath-expansion').evaluate(el => Number(getComputedStyle(el).opacity));
  await page.clock.runFor(3000);
  const laterOpacity = await page.locator('.breath-expansion').evaluate(el => Number(getComputedStyle(el).opacity));
  expect(laterOpacity).toBeGreaterThan(firstOpacity);
  expect(await page.locator('.breathing-pet').evaluate(el => getComputedStyle(el).transform)).toBe('none');
  expect(await page.locator('.breath-expansion').evaluate(el => getComputedStyle(el).transform)).toBe('none');
  await expect(page.locator('.breathing-pet .character-artwork')).toHaveAttribute('data-still', 'true');
  await expect(page.locator('.breathing-pet .character-artwork')).toHaveAttribute('data-renderer', 'webgl');
});

test('contextual portraits retain the selected scenario and restore focus on close', async ({ page }) => {
  const trigger = page.getByRole('button', { name: /看看.*的陪伴动作/ });
  for (const [label, file, cast, asset] of [['平稳', '07-calm-portrait', 'duo', 'duo-calm'], ['偏高', '08-support-portrait', 'dog', 'dog-rest'], ['数据不足', '09-curious-portrait', 'cat', 'cat-curious']]) {
    await page.getByRole('button', { name: label, exact: true }).click();
    await expect(page.locator('.hero-card .character-artwork')).toHaveAttribute('data-character', cast);
    await expect(page.locator('.hero-card img')).toHaveAttribute('src', `/characters/v4/${asset}.png`);
    await trigger.click();
    await expect(page.locator('.companion-portrait .character-artwork')).toHaveAttribute('data-character', cast);
    await expect(page.getByRole('dialog', { name: '猫狗的此刻' })).toBeVisible();
    await expect(page.getByRole('dialog', { name: '猫狗的此刻' })).toHaveCSS('opacity', '1');
    await page.screenshot({ animations: 'disabled', path: `artifacts/${file}.png` });
    await page.keyboard.press('Escape');
    await expect(trigger).toBeFocused();
    await expect(page.getByRole('button', { name: label, exact: true })).toHaveAttribute('aria-pressed', 'true');
  }
});

test('generated breathing artwork follows the clock and freezes exactly on pause', async ({ page }) => {
  await page.clock.install();
  await page.getByRole('button', { name: /开始 5 分钟呼吸/ }).click();
  const art = page.locator('.breathing-pet .character-artwork');
  await expect(art).toHaveAttribute('data-renderer', 'webgl');
  await expect(art).toHaveAttribute('data-character', 'cat');
  await expect(art.locator('img')).toHaveAttribute('src', '/characters/v3/breathing.png');
  const canvas = art.locator('canvas');
  await page.clock.runFor(200);
  const firstStrength = Number(await canvas.getAttribute('data-breath'));
  await page.clock.runFor(3000);
  expect(Number(await canvas.getAttribute('data-breath'))).toBeGreaterThan(firstStrength);
  await page.getByRole('button', { name: '暂停练习', exact: true }).click();
  await page.clock.runFor(100);
  const pausedStrength = await canvas.getAttribute('data-breath');
  const pausedTime = await canvas.getAttribute('data-motion-time');
  const pausedDraws = await canvas.getAttribute('data-draw-count');
  await page.clock.runFor(6000);
  expect(await canvas.getAttribute('data-breath')).toBe(pausedStrength);
  expect(await canvas.getAttribute('data-motion-time')).toBe(pausedTime);
  expect(await canvas.getAttribute('data-draw-count')).toBe(pausedDraws);
  await expect(art).toHaveAttribute('data-phase', 'paused');
  await page.getByRole('button', { name: '继续练习', exact: true }).click();
  await page.clock.runFor(2000);
  await expect(page.getByTestId('phase-label')).toHaveText('缓缓呼气');
  await expect(art).toHaveAttribute('data-phase', 'exhale');
});

test('artwork studio loads solo cat, redesigned dog and duo scenes and supports replay, pause and dark mode', async ({ page }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/character-studio.html');
  await expect(page.locator('article')).toHaveCount(7);
  await expect(page.locator('[data-renderer="webgl"]')).toHaveCount(7);
  for (const img of await page.locator('.artwork-fallback').all()) {
    expect(await img.evaluate(el => el.complete && el.naturalWidth > 1000)).toBe(true);
  }
  await page.screenshot({ path: 'artifacts/11-character-studio.png', fullPage: true });
  const breathing = page.locator('article').filter({ has: page.getByRole('heading', { name: '跟着一口呼吸' }) });
  await breathing.scrollIntoViewIfNeeded();
  await page.clock.install();
  await breathing.getByRole('button', { name: '重播动作' }).click();
  await page.clock.runFor(5500);
  await expect(breathing.locator('.breathing-label')).toContainText('缓缓呼气');
  await breathing.getByRole('button', { name: '重播动作' }).click();
  await page.clock.runFor(150);
  await expect(breathing.locator('.breathing-label')).toContainText('轻轻吸气');
  await breathing.getByRole('button', { name: '暂停', exact: true }).click();
  await page.clock.runFor(100);
  const value = await breathing.locator('canvas').getAttribute('data-breath');
  await page.clock.runFor(3000);
  expect(await breathing.locator('canvas').getAttribute('data-breath')).toBe(value);
  await page.getByRole('button', { name: '深色背景', exact: true }).click();
  await expect(page.locator('.studio')).toHaveAttribute('data-theme', 'dark');
  await page.getByLabel('减少动态效果').check();
  await expect(page.locator('.character-artwork[data-still="true"]')).toHaveCount(7);
  await page.clock.runFor(150);
  const stillDraws = await page.locator('canvas').evaluateAll(nodes => nodes.map(node => node.dataset.drawCount));
  await page.clock.runFor(2000);
  expect(await page.locator('canvas').evaluateAll(nodes => nodes.map(node => node.dataset.drawCount))).toEqual(stillDraws);
  await page.screenshot({ path: 'artifacts/12-character-studio-dark.png', fullPage: true });
  expect(errors).toEqual([]);
});


test('background pets freeze behind a portrait, replay keeps focus, and rapid drink records stay accurate', async ({ page }) => {
  await page.clock.install();
  const home = page.locator('.hero-card canvas');
  await expect(page.locator('.hero-card .character-artwork')).toHaveAttribute('data-renderer', 'webgl');
  await page.clock.runFor(200);
  await page.getByRole('button', { name: '看看猫狗的陪伴动作' }).click();
  await page.clock.runFor(300);
  const count = await home.getAttribute('data-draw-count');
  await page.clock.runFor(800);
  expect(await home.getAttribute('data-draw-count')).toBe(count);
  const portrait = page.getByRole('dialog', { name: '猫狗的此刻' });
  const replay = portrait.getByRole('button', { name: '再看一次动作' });
  await replay.click();
  await page.clock.runFor(200);
  await expect(replay).toBeFocused();
  await replay.click();
  await page.clock.runFor(100);
  await expect(replay).toBeFocused();
  await portrait.getByRole('button', { name: '回到今日' }).click();
  await page.clock.runFor(200);
  expect(Number(await home.getAttribute('data-draw-count'))).toBeGreaterThan(Number(count));
  await page.getByRole('button', { name: /今天喝了什么/ }).click();
  const sheet = page.getByRole('dialog', { name: '今日饮品记录' });
  for (let i=0;i<5;i++) {
    await sheet.getByRole('button', { name: '增加白水', exact: true }).click();
    await page.clock.runFor(80);
  }
  await expect(page.getByTestId('total-fluid')).toHaveText('1250 ml');
  await expect(sheet.locator('.drink-response')).toHaveText('已增加一杯白水');
  await sheet.getByRole('button', { name: '撤销上一笔' }).click();
  await expect(page.getByTestId('total-fluid')).toHaveText('1000 ml');
  await expect(sheet.locator('.drink-response')).toHaveText('已撤销上一笔');
  await page.clock.runFor(1200);
  const settledDraws = await sheet.locator('canvas').getAttribute('data-draw-count');
  await page.clock.runFor(1200);
  expect(await sheet.locator('canvas').getAttribute('data-draw-count')).toBe(settledDraws);
});
