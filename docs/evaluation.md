# Evaluation

Question: does the setup-qa harness (rules, skills, commands, reviewer agent, `qa-lint`) do better than the same models with only the provider config (`bare`)?

Method, tasks and how to re-run: [evals/README.md](../evals/README.md). Both arms use the same models (`qwen3.6`, `gemma4`), the same tasks, a hidden grader and a fresh container per run. The task is the unit of analysis.

## Results

Held-out tasks: the 7 tasks that no rule or skill was tuned on. Each cell is 6 runs (3 repetitions x 2 models).

| Task | bare | harness |
| --- | --- | --- |
| h1-state-pollution | 1/6 | 1/6 |
| h2-mutation-hunt | 3/6 | 3/6 |
| h3-suite-triage | 6/6 | 6/6 |
| h4-cypress-intercepts | 6/6 | 5/6 |
| t10-triage-app-bug | 6/6 | 6/6 |
| t11-triage-test-bug | 3/6 | 5/6 |
| t12-triage-environment | 5/6 | 6/6 |
| **Total** | **30/42** | **32/42** |

Regression tasks (t1 to t9, 1 repetition x 2 models): 18/18 in both arms.

Paired task-level difference on the held-out tasks, harness minus bare: +0.05, 95% bootstrap CI [-0.05, +0.17]. Over all 16 tasks: +0.02, CI [-0.02, +0.07].

Median time per task: `qwen3.6` 108 s bare, 92 s harness; `gemma4` 114 s bare, 119 s harness (held-out tasks).

## What this does and does not show

- No measured difference in pass rate. The harness is not worse, and it did not break anything on the regression tasks.
- The only visible trend is on triage (t11, t12), where the harness was ahead by 2 and 1 runs of 6. That is too small to call an effect.
- Both arms struggle on h1 (a suite that fails on a reused environment): 1 of 6 each, mostly at the 600 s limit, so the limit is part of that result.
- The regression tasks are saturated (every run passes), so they can detect breakage but not improvement.
- What the harness adds beyond pass rate is not measured here: the repeatable install, the guard rails on destructive commands and secret files, the lint gate, and the browser tools (disabled during the evaluation in both arms).

## Caveats and corrections made along the way

- A first pass found t12 failing in every run, in both arms. The cause was the task, not the models: opencode's default permissions refuse to read a file named `*.env` in non-interactive runs, and the evidence was in `ci.env`. The file was renamed and t12 was re-run; only the re-run is reported.
- Part-way through, the agents turned out to be able to read the grader, the reference solutions and the repository, which were mounted in world-readable paths. Of 120 runs, 13 had successfully read from those paths (some only listed `/repo`). Those 13 were discarded and re-run after moving the mounts under `/root`, which the agent user cannot enter. An isolation self-test (`evals/run.sh ISOLATION ...`) now checks this.
- The generic QA checklists in the skills (boundaries, normalisation, state) overlap what `h2-mutation-hunt` rewards, so that task does not measure general reasoning.
- After the measurement, four small corrections were made and not re-measured: wider destructive-command patterns in the config, a `qa-lint` error for a missing directory, and wording fixes in two skills. None changes what the agents were told to do on these tasks.
- 6 runs per cell cannot detect small effects. Treat every difference above as noise unless it grows with more repetitions.
