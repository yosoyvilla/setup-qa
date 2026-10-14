---
description: Diagnose and fix a flaky or order-dependent test
---

Fix the flaky test or suite: $ARGUMENTS

Load the `flaky-tests` skill first. Reproduce the failure before changing anything. Fix the root cause (no sleeps, no retries, no skips). Prove the fix with at least 10 consecutive passing runs and two back-to-back runs against the same running application.
