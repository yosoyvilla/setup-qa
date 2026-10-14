---
name: test-design
description: Deriving test cases from requirements or a user story using standard techniques - equivalence classes, boundary values, decision tables, state transitions and negative testing. Use when asked to design tests or a test plan, when requirements are vague, or before writing a suite for a feature.
---

# Test design

Turn a requirement into cases on purpose, instead of testing whatever comes to mind first.

## Steps

1. Restate the requirement as observable behaviours. List your assumptions; if something is ambiguous, say so and choose the safest reading.
2. Explore the real application to learn inputs, limits and messages.
3. For each behaviour apply the techniques below and write the cases as a short list.
4. Automate the highest-value cases first; keep each test to one behaviour.

## Techniques

- Equivalence classes: group inputs the application should treat alike (valid, invalid, empty) and test one from each group.
- Boundary values: the edges of every range or limit: nothing, one, many, and one past any limit you can find or suspect.
- Input normalisation: letter case, leading and trailing whitespace, special characters.
- Decision tables: when several conditions combine (user known or unknown, password right or wrong), cover every combination that matters.
- State transitions: what happens after a sequence (act twice, undo, reload, log out and back in), and whether state leaks between sessions.
- Negative testing: invalid, missing and malformed input must be rejected with the right message and no side effect.
- Idempotence and repetition: the same action twice.

## Cases people forget

Empty result sets, unknown identities, wrong but plausible input, exact error text, the count after several actions, and state after reloading the page.

## Output

A table: behaviour, case, input, expected result, priority. Then implement the cases and show which ones you automated. Apply `test-review` to your own tests before finishing.
