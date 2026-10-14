#!/usr/bin/env bash
# Run many cells, a few at a time (NaN allows 5 concurrent per model and 60 requests/min per key).
# usage: evals/matrix.sh [-j N] < cells.txt      each line: <arm> <model> <task> <rep>
# Prints one result line per finished cell. Summarise with: python3 evals/analyze.py
set -u
E="$(cd "$(dirname "$0")" && pwd)"; J=3
[ "${1:-}" = "-j" ] && { J="$2"; shift 2; }
sed 's/[[:space:]]*$//' | xargs -P "$J" -L 1 sh -c "\"$E/run.sh\" \"\$0\" \"\$1\" \"\$2\" \"\$3\" 2>&1 | tail -1 | sed \"s|^|\$2 r\$3 |\""
