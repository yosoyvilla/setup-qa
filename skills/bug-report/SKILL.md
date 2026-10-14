---
name: bug-report
description: Triage a failing test or suite into application bug, test bug or environment problem using evidence, and write a reproducible bug report. Use when a CI run is red, a test fails and the cause is unclear, or the user asks for a bug report or triage.
---

# Triage and bug reports

## Procedure

1. Read the failure output and the spec (or changelog) that says what the application should do.
2. Reproduce against the running application through the API first (`curl`), then the UI. Capture exact requests and responses.
3. Classify by what the evidence shows:
   - **Application bug**: the application's behaviour differs from the spec. The API or UI returns the wrong thing for a valid request.
   - **Test bug**: the application behaves per spec but the test is wrong or stale: a locator that no longer exists after a documented redesign, a wrong expected value, a missing wait. The same feature works when exercised another way.
   - **Environment**: the test cannot reach or run against a correct application: wrong URL or port, refused connection, missing credentials or data, network or service not running.
   Read the evidence from the running system (responses, logs, the data) in parallel with reading the code; code alone cannot tell an outage from a validation rule. Classify by status first: a 4xx is deterministic (it reproduces and nothing was created), a 5xx is the transient class. Decide whether a failure is intermittent by repeating it, not by feel. The status code the system returned matters more than the wording of an error label. If the reason lives in a response body that is not logged, ask for the raw body instead of guessing.
4. Do not decide from names or guesses. A configuration flag you happen to find on the server is not a root cause; the question is whether the behaviour matches the spec.
5. Several failures can have different causes. Triage each failing test on its own, and do not list passing tests.

## Report template

```
Title: <short, names the behaviour>
Category: app-bug | test-bug | environment  (one line of evidence)
Environment: <app version or URL, browser, data>
Steps to reproduce:
1. ...
2. ...
Expected: <per spec>
Actual: <what happened, with the exact response or message>
Evidence: <request/response, error text, screenshot or trace path>
```

## Output format

When a specific format is requested (for example a JSON file with fixed keys), produce exactly that format and nothing else in that file. Do not modify the tests or the application while triaging.
