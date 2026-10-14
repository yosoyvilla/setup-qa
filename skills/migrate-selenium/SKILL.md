---
name: migrate-selenium
description: Ports Selenium WebDriver tests (Python, Java or JavaScript) to Playwright (TypeScript) keeping every test and assertion - waits, page objects, fixtures. Use when asked to migrate, convert or port Selenium tests or page objects to Playwright.
---

# Selenium to Playwright

Port every test. Keep the intent of every assertion. Run the result against the application and make sure it passes.

## Mapping

| Selenium | Playwright |
| --- | --- |
| `driver.get(url)` | `await page.goto(path)` (use `baseURL`) |
| `find_element(By.CSS_SELECTOR, "[data-testid=a]")` | `page.getByTestId('a')` |
| `find_elements(...)` and `len(...)` | `locator` with `toHaveCount(n)` |
| `.send_keys('x')` | `.fill('x')` |
| `.click()` | `.click()` |
| `.text` compared with `assert` | `await expect(loc).toHaveText('x')` |
| `driver.current_url` contains | `await expect(page).toHaveURL(/path/)` |
| `WebDriverWait(...).until(...)` | not needed: actions and `expect` wait |
| `EC.element_to_be_clickable` | `await loc.click()` (waits for actionability) |
| `driver.quit()` | handled by the `page` fixture |

## Structure

- A Selenium page object (class with locators and methods) becomes a small class taking `page`, or plain helper functions. Keep locators in one place.
- pytest or JUnit fixtures become `test.beforeEach` or Playwright fixtures.
- Remove implicit waits and explicit sleeps; do not translate them.

## Traps

- Selenium assertions compared strings after the fact; translate them to web-first `expect` so they wait.
- Await every Playwright call.
- Keep one test per Selenium test; do not merge or drop any, and keep the same expected values.
