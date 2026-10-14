---
name: verify-fix
description: Proves a claim such as "this fixes the bug", "the test is no longer flaky" or "the migration is equivalent" with before-and-after evidence and one verdict. Use before saying work is done, fixed or passing, and whenever the user asks to verify or prove something.
---

# Verify a fix

"I believe it works" is not evidence. Verification means a repeatable check whose outcome you actually observed.

## Steps

1. State the claim so it can be disproved: the condition, what is measured, and the threshold. Example: "`login.spec.ts` passes 10 times in a row and fails against a build where a wrong password is accepted."
2. Pick the smallest check that can disprove it.
3. Baseline: run the check on the state before your change (the failing test, the broken behaviour, the unfixed suite). Save the real output.
4. Treatment: run the same command, with the same data and environment, after your change. Save the real output.
5. Compare the two outputs, not your memory of them: test names, counts, error text, HTTP responses, screenshots.
6. Give exactly one verdict:
   - VERIFIED: the baseline showed the problem and the treatment shows it gone.
   - NOT VERIFIED: the treatment still shows the problem or a new one.
   - INCONCLUSIVE: you could not run the check or the baseline never showed the problem. Say what is missing.

## Rules

- Never report success for a step you did not run. If you could not run it, say so and mark the work unverified.
- Name the failing tests (titles), not only counts.
- A green run is the terminal proof for test work. Do not substitute reasoning about why it should pass.
- For timing-related claims, repeat the run (`--repeat-each=10`) and also run the whole suite twice back to back.
- For a UI or API claim, confirm through the running application as well as the test output.
