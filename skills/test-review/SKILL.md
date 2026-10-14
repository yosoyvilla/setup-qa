---
name: test-review
description: Reviews and strengthens test suites so they would actually catch regressions - finds false-green tests, vacuous assertions and missing negative or boundary cases using mutation thinking. Use when asked to review a suite, when tests pass but bugs shipped, or before declaring new tests done.
---

# Test review

A passing test only matters if it would fail when the feature breaks.

## Mutation thinking

For every test, write down two realistic defects in the feature and check whether this test would fail for each. If not, the test is weak.

Think in categories rather than guessing one bug: input validation (invalid input accepted or wrong error), authorisation and identity checks, filtering and search behaviour, input normalisation, counters and totals, limits and boundaries, state handling between steps, and error and empty states.

## Weakness checklist

- Vacuous assertions: `toBeGreaterThan(0)`, `>= 0`, `toBeVisible()` alone, `expect(true)`, a swallowed error (`.catch(() => {})`), asserting a value the test just set.
- No assertion at all after the action.
- Happy path only. Look for the missing cases: wrong or empty input, unknown user, no results, upper and lower case, surrounding whitespace, boundaries (0, 1, many, above a suspected limit), repeated actions.
- Locators that could match the wrong element.
- Exact values missing: assert the text or number, not just presence.

## Output format for a review

| Test | Defect it would miss | Fix |
| --- | --- | --- |

Then list the missing cases as new tests. Apply fixes only when asked.

## Proving a strengthened test

Run it against the healthy application (must pass). If you can run a variant of the application with the defect, run against that too (must fail). If you cannot change the application, reason through each defect explicitly and state which assertion would catch it.
