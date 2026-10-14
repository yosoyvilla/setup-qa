---
description: Final quality gate for tests - lint, run the suite repeatedly, report evidence
---

Run the final quality gate on: $ARGUMENTS

Load the `verify-fix` skill. Run `~/.config/opencode/bin/qa-lint tests` and fix every FAIL. Run the suite with `npx playwright test --repeat-each=3`, then once more. Report the exact commands, the results, and the titles of any failing tests. Give one verdict: VERIFIED, NOT VERIFIED or INCONCLUSIVE.
