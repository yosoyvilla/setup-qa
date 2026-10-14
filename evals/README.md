# Evaluation suite

Re-measure the setup after any change to the rules, skills, agent or config. It compares two arms on the same tasks, in fresh containers:

- `bare`: only the NaN provider config (no rules, skills, commands or agent).
- `harness`: the full setup-qa install (rules, skills, commands, reviewer agent, `qa-lint`).

The browser tools are disabled in both arms so the comparison isolates rules and skills.

## Requirements

Docker, and `NAN_API_KEY` in your environment (only for real runs). The first run builds the image `setup-qa-evals` (opencode 1.18.34, Playwright 1.63.0 with Chromium).

## How a run works

- The agent runs as user `agent` in `/work` with the task files. The grader, the reference solutions and the repository are mounted under `/root`, which that user cannot enter. The demo shop (the system under test) runs as user `sut` from a private directory, so the agent can reach it only over HTTP. It cannot read its source or the environment that holds the seeded-bug flags.
- A hidden grader (`harness/grader.py`) runs the agent's tests against the healthy shop and against variants with seeded defects. A task passes only if the healthy run passes and the required defects are caught. Some tasks instead check a structured `triage.json`, or static rules such as "no fixed sleeps".
- The task is the unit of analysis. Repetitions of one task are not independent evidence.

## Run

```bash
# validate the graders without any model: every REF must pass, every NOOP must fail
for t in $(ls evals/tasks); do
  evals/run.sh REF none "$t" 0 | tail -1
  evals/run.sh NOOP none "$t" 0 | tail -1
done

# prove the agent cannot read the grader, the reference solutions, the app source or its environment
evals/run.sh ISOLATION none t1-login-tests 0 | grep -E 'READABLE|denied'   # only /out/prompt.txt may be readable

# one real cell
evals/run.sh harness qwen3.6 h3-suite-triage 1

# many cells, three at a time (NaN allows 5 concurrent per model, 60 requests per minute per key)
printf '%s\n' "bare qwen3.6 h1-state-pollution 1" "harness qwen3.6 h1-state-pollution 1" | evals/matrix.sh -j 3

# summary table and paired bootstrap per task
python3 evals/analyze.py
```

Results land in `evals/results/<task>/<arm>-<model>-r<rep>/` (git-ignored): the agent's event stream, the diff of its changes, and the grade.

## Tasks

| Task | What it checks |
| --- | --- |
| `t1-login-tests` | Write tests from acceptance criteria; must catch two seeded defects. |
| `t2-flaky-search` | Fix a flaky test under variable latency without sleeps or retries. |
| `t3-ui-redesign` | Repair locators after a redesign without weakening assertions. |
| `t4-api-tests` | API tests with the `request` fixture. |
| `t5-cypress-port`, `t6-selenium-port` | Port suites to Playwright keeping every assertion. |
| `t7-page-object-refactor` | Remove duplicated locators and login steps; behaviour unchanged. |
| `t8-false-green` | Strengthen a suite that stayed green while bugs shipped. |
| `t9-boundary-cases` | Case-insensitivity, empty result, accumulation. |
| `h1-state-pollution` | Suite fails on a reused environment; make it independent and repeatable. |
| `h2-mutation-hunt` | Vague user story; the suite must catch at least 6 of 8 seeded defects. |
| `h3-suite-triage` | Triage five failing tests across three root causes. |
| `h4-cypress-intercepts` | Port a Cypress suite with custom commands, stubs and API waits. |
| `t10-triage-app-bug`, `t11-triage-test-bug`, `t12-triage-environment` | One failure each, decided from evidence the agent can gather. |

The seeded defects live in `harness/sut-server.js` (`BUG=` flags). To add a task, create `evals/tasks/<id>/` with `prompt.txt`, `task.json`, `start/` and a reference solution in `ref/`, and confirm the self-test above: the reference must pass and the untouched start must fail.

## Limits

- Cypress and Selenium cannot run in the arm64 Linux container, so they are exercised as ports to Playwright.
- Mobile testing is not covered.
- The generic QA heuristics in the skills (boundaries, normalisation, state) overlap what `h2-mutation-hunt` rewards. Read that task's result as "the checklist helps", not as proof of general reasoning.
