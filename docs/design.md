# Design

## Goal

Give a QA automation engineer on macOS a ready, measured AI coding setup that she can install with one command and use without further configuration, except for the NaN API key.

## Fixed choices

- Harness: opencode, pinned to 1.18.34. No orchestration plugin. In a head-to-head evaluation it matched the heavier harnesses on pass rate (see [bakeoff.md](bakeoff.md)), so the simplest one was chosen.
- Models: NaN `qwen3.6` (default) and `gemma4` (small model). They are the two chat models with no token quota listed in NaN's documentation; they are limited by request rate (5 concurrent per model, 7 per key on the base plan, 60 requests per minute per key). `qwen3.6` is the default because it was about twice as fast with the same pass rate.
- Only one provider and only these two models are enabled.
- Browser: the Playwright MCP server (pinned) driving the Google Chrome installed on the machine. It is the only MCP server; more can be added as entries under `mcp` in the config.
- Language: the assistant answers in the language the user writes (English or Spanish), and writes everything to disk in English unless asked otherwise.
- Public repository: no secrets, no private names. The NaN key is read from the `NAN_API_KEY` environment variable only.

## What gets installed

All under `~/.config/opencode/`: the config (`opencode.jsonc`), global rules (`AGENTS.md`), eleven skills, six slash commands, one read-only reviewer agent and the `qa-lint` script.

- Rules and skills carry knowledge and method. They are advisory: a model can ignore them.
- Enforcement uses artifacts that do not depend on the model following instructions: the permission rules in the config (best-effort guard rails, not a sandbox) and `qa-lint`, which the rules require before finishing and which fails on fixed sleeps, `.only`, skipped tests, retries and one-shot reads.

## Installer behaviour

- Idempotent: running it again changes nothing that is already current.
- Backups: the first copy of any file that existed before setup-qa is kept in `backups/original` and never overwritten; each replacement also makes a timestamped backup.
- Uninstall removes only what the manifest lists, saves what it removes (including edits made after installing) in `backups/uninstall-<time>`, and restores the originals.
- It never writes the NaN key and never touches opencode's authentication data.

## Evaluation

`evals/` contains the benchmark: a demo shop run as a separate OS user so the agent cannot read its source or its seeded-defect flags, 16 tasks with hidden graders, and a runner for two arms (`bare` and `harness`). See [evaluation.md](evaluation.md) and [../evals/README.md](../evals/README.md).

## Known limits

- Mobile testing is not covered. Cypress and Selenium are exercised as ports to Playwright, not run natively.
- macOS only.
- The skills' generic QA heuristics overlap what one evaluation task rewards; results for that task should be read with that in mind.
- Prompts refer to `~/.config/opencode/bin/qa-lint`; if `XDG_CONFIG_HOME` is set the installer follows it but the prompts do not.
