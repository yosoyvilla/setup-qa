# Harness bake-off

Question: which agent harness gives the best results with the two NaN models that have no token quota (`qwen3.6`, `gemma4`) on QA automation work?

## Method

- 11 QA tasks against a small demo shop (login, search, cart, API): write tests from acceptance criteria, fix a flaky test, repair locators after a redesign, API tests, port Cypress and Selenium suites to Playwright, refactor to page objects, fix a false-green suite, boundary cases, and two triage tasks.
- Every task is graded by a hidden grader that runs the agent's tests against the healthy app and against variants with seeded defects. A test suite passes only if it passes on the healthy app and fails on the defective ones.
- Each run is a fresh Docker container with the same neutral rules for every arm. The unit of analysis is the task, not the repetition.
- Arms: opencode (plain), opencode with oh-my-openagent, oh-my-pi, gentle-shell. Both models on every arm.
- A decision rule was fixed before running: highest pass rate wins; if the difference is not statistically distinguishable, the simplest arm wins.

## Results

| Arm | Passes (all tasks) |
| --- | --- |
| opencode (plain) | 40/44 |
| oh-my-pi | 38/44 |
| gentle-shell | 38/44 |
| opencode with oh-my-openagent | dropped: gemma4 stalled in 2 of 3 trials |

Median time per task (seconds):

| Arm | qwen3.6 | gemma4 |
| --- | --- | --- |
| opencode (plain) | 41 | 99 |
| oh-my-pi | 51 | 95 |
| gentle-shell | 64 | 133 |

All pairwise differences between the three finished arms have 95% confidence intervals that include zero, so they are tied; the tie rule selects plain opencode. Plain opencode was the fastest with `qwen3.6` and about level with oh-my-pi with `gemma4`; only oh-my-pi had a run hit the time limit (1 of 44). `qwen3.6` was about twice as fast as `gemma4` with an equal pass rate, so it is the default.

## Caveats

- The two triage tasks in this first benchmark leaked the answer through the server's environment and were ambiguous. They are rebuilt in `evals/` (the app now runs hidden from the agent) and the first benchmark's triage failures should not be read as a measure of triage skill.
- Cypress and Selenium cannot run in the arm64 Linux container, so they are tested as "port to Playwright" tasks and graded by running the result.
- 11 tasks and 44 runs per arm cannot separate small differences.
