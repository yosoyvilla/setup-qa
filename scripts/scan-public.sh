#!/usr/bin/env bash
# Pre-push scan for a public repository: secrets, personal paths, e-mail addresses and private names.
# usage: scripts/scan-public.sh
# Private names are not stored in this repo. Provide them in a file of patterns (first column,
# one per line, '#' comments allowed) via SCAN_DENYLIST, default ~/.config/setup-sync/sanitize-map.txt,
# and/or a comma-separated list in SCAN_EXTRA. Exit 0 only when nothing is found.
set -u
cd "$(dirname "$0")/.." || exit 2
GREP=/usr/bin/grep
found=0

FILES="$(git ls-files -co --exclude-standard 2>/dev/null)"
[ -n "$FILES" ] || { echo "scan-public: no files to scan (is this a git repository?)" >&2; exit 2; }

report() { # label, matches
  [ -z "$2" ] && return 0
  echo "FOUND $1:"; echo "$2" | sed 's/^/    /' | head -20
  found=1
}

# every scan runs over the file list, skipping binary files
scan() { printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 "$GREP" -InE -e "$1" 2>/dev/null; }
scan_ci() { printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 "$GREP" -InEi -e "$1" 2>/dev/null; }

report "secret-shaped strings" "$(scan 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-ant-[A-Za-z0-9_-]{10,}|sk-[A-Za-z0-9]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.')"
report "an assigned NaN key" "$(scan 'NAN_API_KEY[[:space:]]*=[[:space:]]*["'"'"']?[A-Za-z0-9_-]{16,}')"
if [ -n "${NAN_API_KEY:-}" ]; then
  report "the live NaN key value" "$(printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 "$GREP" -InF -e "$NAN_API_KEY" 2>/dev/null | sed 's/:.*/: (key value present)/')"
fi
report "personal home paths (the eval container user /home/agent is allowed)" "$(scan '/Users/[A-Za-z0-9._-]+|/home/[a-z][A-Za-z0-9._-]+' | "$GREP" -v '/home/agent')"
report "e-mail addresses (only @example.com is allowed)" "$(scan '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | "$GREP" -v '@example\.com')"

DENY="${SCAN_DENYLIST:-$HOME/.config/setup-sync/sanitize-map.txt}"
patterns=""
[ -f "$DENY" ] && patterns="$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$DENY" | cut -f1 | paste -sd'|' -)"
[ -n "${SCAN_EXTRA:-}" ] && patterns="${patterns:+$patterns|}$(printf '%s' "$SCAN_EXTRA" | tr ',' '|')"
if [ -n "$patterns" ]; then
  printf '' | "$GREP" -E -e "$patterns" >/dev/null 2>&1; [ $? -eq 2 ] && { echo "scan-public: the private-name pattern list is not a valid regular expression" >&2; exit 2; }
  report "private names in content" "$(scan_ci "$patterns" | sed 's/:.*/: (private name present)/')"
  report "private names in file names" "$(printf '%s\n' "$FILES" | "$GREP" -iE -e "$patterns")"
else
  echo "scan-public: WARNING no private-name list (set SCAN_DENYLIST or SCAN_EXTRA); only generic checks ran" >&2
fi

if [ "$found" -eq 0 ]; then echo "scan-public: clean ($(printf '%s\n' "$FILES" | wc -l | tr -d ' ') files)"; fi
exit "$found"
