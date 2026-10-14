#!/usr/bin/env bash
# Offline self-test for qa-lint: it must flag each bad construct and stay quiet on clean code.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
expect() { # description, expected exit, dir
  "$HERE/qa-lint.sh" "$3" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (exit $rc, wanted $2)"; fail=1; fi
}

mkdir -p "$T/clean"
cat > "$T/clean/a.spec.ts" <<'EOF'
import { test, expect } from '@playwright/test';
test('x', async ({ page }) => {
  await page.goto('/login');
  await expect(page.getByTestId('item')).toHaveCount(1);
});
EOF
expect "clean file passes" 0 "$T/clean"

bad() { # name, line
  mkdir -p "$T/$1"; printf "import { test } from '@playwright/test';\n%s\n" "$2" > "$T/$1/a.spec.ts"
  expect "$1 is flagged" 1 "$T/$1"
}
bad sleep    "test('x', async ({ page }) => { await page.waitForTimeout(500); });"
bad only     "test.only('x', async () => {});"
bad skip     "test.skip('x', async () => {});"
bad retry    "test.describe.configure({ retries: 2 });"
bad oneshot  "test('x', async ({ page }) => { expect(await page.locator('li').count()).toBe(1); });"

expect "missing directory fails (exit 2)" 2 "$T/does-not-exist"

mkdir -p "$T/warn"; printf "test('x', async () => { expect(n).toBeGreaterThan(0); });\n" > "$T/warn/a.spec.ts"
expect "warn-only file still exits 0" 0 "$T/warn"
exit "$fail"
