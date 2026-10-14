#!/usr/bin/env bash
# qa-lint: deterministic checks for test-quality rules that prose alone cannot enforce.
# usage: qa-lint [dir ...]        (default: tests)
# FAIL findings exit 1; WARN findings are printed but exit 0.
set -u
GREP=/usr/bin/grep
dirs=("$@")
[ "${#dirs[@]}" -eq 0 ] && dirs=(tests)
status=0
for d in "${dirs[@]}"; do
  [ -d "$d" ] || { echo "qa-lint: no such directory: $d (pass your test folder, for example: qa-lint e2e)" >&2; exit 2; }
done

scan() { # level name pattern message
  local hits
  hits=$("$GREP" -rnE --include='*.ts' --include='*.tsx' --include='*.js' --include='*.mjs' --include='*.py' -e "$3" "${dirs[@]}" 2>/dev/null)
  [ -z "$hits" ] && return 0
  echo "$1 $2: $4"
  echo "$hits" | sed 's/^/    /'
  [ "$1" = FAIL ] && status=1
  return 0
}

scan FAIL no-fixed-sleep    'waitForTimeout\(|time\.sleep\(|cy\.wait\([[:space:]]*[0-9]' 'fixed sleeps hide timing bugs; wait on the condition with expect(...)'
scan FAIL no-focused-test   '\.only\(' 'a focused test silently disables the rest of the suite'
scan FAIL no-skipped-test   'test\.(skip|fixme)\(|describe\.skip\(|\bxit\(|\bxdescribe\(' 'skipped tests hide failures; fix or delete with a reason'
scan FAIL no-retry-as-fix   'retries[[:space:]]*:' 'retries hide flaky tests; fix the cause'
scan FAIL no-one-shot-read  'expect\([[:space:]]*await [^;]*\.(count|textContent|innerText|innerHTML|inputValue|isVisible|isHidden|isChecked)\(' 'one-shot reads do not wait; use a web-first assertion such as toHaveCount or toHaveText'
scan WARN vacuous-assertion 'toBeGreaterThan\(0\)|toBeGreaterThanOrEqual\(0\)|expect\(true\)|\.catch\(\(\) => \{\}\)' 'weak or swallowed assertion; assert exact values'
scan WARN hardcoded-url     'https?://localhost:[0-9]+' 'use baseURL from the config instead of a hard-coded host'

[ "$status" -eq 0 ] && echo "qa-lint: no FAIL findings in: ${dirs[*]}"
exit "$status"
