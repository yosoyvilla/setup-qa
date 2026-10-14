---
name: visual-checks
description: Checking how a page looks, not only whether it works - screenshots at several widths, Playwright visual comparison, accessibility snapshots and computed-style probes. Use when a UI change ships, when the user reports misaligned, overlapping, cut-off or unreadable elements, or when asked to add visual or responsive tests.
---

# Visual checks

A page can return 200, show the right data and still look broken. Functional assertions do not cover that.

## Look at it

Open the page with the playwright browser tools and take screenshots at a desktop width (about 1280 px) and a phone width (about 390 px). Review each image for: overlapping or cut-off text, buttons squeezed or overflowing, misalignment, missing spacing, unreadable contrast, horizontal scrolling, elements outside the viewport.

## Rule out a systemic cause first

If everything looks off, probe computed styles before hunting individual defects, for example whether utility classes compute at all:

```ts
const styles = await page.evaluate(() => {
  const probe = document.createElement('div');
  probe.className = 'p-4 m-4';
  document.body.appendChild(probe);
  const { padding, margin } = getComputedStyle(probe);
  probe.remove();
  return { padding, margin };
});
```

Zero values where spacing is expected point to one global rule overriding the styles, which is a root cause, not many small defects.

## Automate what is stable

```ts
test('products page layout on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/products');
  await expect(page).toHaveScreenshot('products-mobile.png', { maxDiffPixelRatio: 0.01 });
});
```

- The first run has no baseline: Playwright reports "A snapshot doesn't exist ... writing actual" and saves the image as the new baseline. Review the images, run again to confirm the test passes, then commit them. Regenerate on purpose with `npx playwright test --update-snapshots`.
- Mask or stub anything that changes between runs (dates, avatars, animations).
- Keep screenshot tests few; use them for key pages, not every page.
- Complement with an accessibility snapshot (`await expect(page.locator('main')).toMatchAriaSnapshot(...)`) for structure and names.

## Report

List defects as: page, width, what is wrong, where. A page that works but looks wrong is a defect.
