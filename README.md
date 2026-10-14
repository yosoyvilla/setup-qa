# setup-qa

A ready-to-use AI coding assistant for QA automation engineers on macOS. It installs [opencode](https://opencode.ai) with a tuned QA configuration and uses only two [NaN](https://nan.builders) models that have no token quota listed in NaN's documentation (`qwen3.6` and `gemma4`); they are limited by request rate, not by tokens.

It is built for writing, fixing, reviewing and migrating automated tests: Playwright (TypeScript) first, plus Cypress, Selenium and API tests. It comes with a real browser the assistant can drive, QA skills, slash commands, a reviewer agent, and a lint gate that blocks common test-quality mistakes.

You can talk to it in English or Spanish. Everything it writes to disk (code, test names, reports) is English unless you explicitly ask for Spanish.

## What you need

- A Mac with [Homebrew](https://brew.sh) installed.
- A NaN API key (ask the person who set this up for you).
- Internet access.

## Install

```bash
git clone https://github.com/yosoyvilla/setup-qa.git
cd setup-qa
./install.sh
```

The installer:

1. installs Node (if missing), Google Chrome (if missing) and a pinned version of opencode,
2. copies the configuration, rules, skills, commands and agent into `~/.config/opencode/` (anything it replaces is backed up first),
3. runs a health check and tells you what, if anything, is left to do.

It is safe to run again at any time.

## Set your NaN key

Add this line to `~/.zshrc`, replacing the placeholder with your key, then open a new terminal:

```bash
export NAN_API_KEY="<your key>"
```

Check everything works (this makes two tiny model calls and starts the browser tools):

```bash
./scripts/check-harness.sh
```

You should see `all checks passed`. The key is never written to any file by this project (see [SECRETS.md](SECRETS.md)).

## Start working

Open a terminal in your test project and run:

```bash
cd path/to/your-test-project
opencode
```

Then ask for what you need, in English or Spanish. Examples:

- `Write Playwright tests for the login page of http://localhost:3000. Cover wrong password and empty fields.`
- `Arregla el test flaky de tests/search.spec.ts.` (the fix is written in English)
- `Port cypress/e2e/shop.cy.js to Playwright.`
- `Review tests/ and tell me which tests would miss a regression.`
- `CI is red on tests/cart.spec.ts, see ci-failure.log. Is it an app bug, a test bug or the environment?`

### Slash commands

Type `/` in opencode to see them.

| Command | What it does |
| --- | --- |
| `/write-tests <feature>` | Writes tests after inspecting the real app, runs them three times, and names the defect each test would catch. |
| `/fix-flaky <test or suite>` | Reproduces the flakiness, fixes the root cause (no sleeps or retries), proves it with repeated runs. |
| `/review-suite <path>` | Finds false-green tests and missing cases. Does not edit unless you ask. |
| `/migrate <path>` | Ports Cypress or Selenium tests to Playwright, keeping every assertion. |
| `/triage <failures>` | Classifies failures as application bug, test bug or environment, with evidence. |
| `/check` | Final gate: lint, repeated runs, one verdict (VERIFIED, NOT VERIFIED or INCONCLUSIVE). |

### What is inside

| Part | Location after install | Purpose |
| --- | --- | --- |
| Configuration | `~/.config/opencode/opencode.jsonc` | NaN provider with only `qwen3.6` (default) and `gemma4`; the Playwright browser tools; best-effort guard rails against destructive commands and secret-file edits (they match common command patterns; they are not a sandbox). |
| Rules | `~/.config/opencode/AGENTS.md` | How the assistant works: look before writing, reproduce before fixing, run what it wrote, strong assertions, no sleeps, evidence-based triage, language rule. |
| Skills | `~/.config/opencode/skills/` | `playwright-conventions`, `test-design`, `flaky-tests`, `test-review`, `verify-fix`, `api-testing`, `visual-checks`, `migrate-cypress`, `migrate-selenium`, `page-objects`, `bug-report`. The assistant loads the right one by itself. |
| Agent | `~/.config/opencode/agents/reviewer.md` | A read-only adversarial reviewer for test code. |
| Lint gate | `~/.config/opencode/bin/qa-lint` | Fails on fixed sleeps, `.only`, skipped tests, retries and one-shot reads. Run it yourself: `~/.config/opencode/bin/qa-lint tests`. |

## Models and limits

- `qwen3.6` is the default: in our evaluation it was about twice as fast as `gemma4` with the same pass rate. `gemma4` is the background model; switch models inside opencode with `/models`.
- Both are rate limited, not token limited, per NaN's documentation: 5 concurrent requests per model, 7 simultaneous requests per API key on the base plan (10 on premium), and 60 requests per minute per key across all models. Do not run several assistants at once; if you see a rate-limit message, wait a minute.
- Context window: 262K tokens each. Start a new session (`/new`) when you change topic.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| The assistant stops without any answer | Rare (seen once in about 10 test runs on `gemma4`). Type `continue`. |
| `NAN_API_KEY` not found | Add the `export` line to `~/.zshrc` and open a new terminal. |
| A Chrome window opens while the assistant works | Expected: that is the browser tool. To hide it, add `"--headless"` to the `playwright` command list in `~/.config/opencode/opencode.jsonc`. |
| A `.playwright-mcp/` folder appears in your project | Add it to that project's `.gitignore`. |
| `opencode: command not found` after install | Open a new terminal, or run `npm install -g opencode-ai@1.18.34`. |
| The health check says a skill or file is missing | Run `./install.sh` again. |
| opencode offers to upgrade | Ignore it. The version is pinned on purpose; updates come through this repository. |

## Update or uninstall

```bash
git pull && ./install.sh     # update
./uninstall.sh                # remove; restores any files it replaced
```

## How we know it works

This setup was measured, not guessed. See [docs/evaluation.md](docs/evaluation.md) for the method and results, and [docs/bakeoff.md](docs/bakeoff.md) for why plain opencode was chosen over other harnesses. The evaluation suite ships in [evals/](evals/README.md) so the setup can be re-measured after any change.

## For maintainers

```bash
bash scripts/test-install.sh      # self-test of install and uninstall in throwaway homes
bash scripts/test-qa-lint.sh      # self-test of the lint gate
bash scripts/test-scan-public.sh  # self-test of the pre-push scanner
bash scripts/scan-public.sh       # must pass before every push (see SECRETS.md)
```

## License

MIT. See [LICENSE](LICENSE).
