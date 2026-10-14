#!/usr/bin/env bash
# Offline self-test for scan-public: it must flag each planted leak and pass a clean tree.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0

fresh() { # name -> repo with the scanner and one clean file
  mkdir -p "$T/$1/scripts"; cp "$HERE/scan-public.sh" "$T/$1/scripts/"
  ( cd "$T/$1" && git init -q && echo "hello" > a.txt )
}
run() { ( cd "$T/$1" && SCAN_DENYLIST=/dev/null SCAN_EXTRA="${2:-}" bash scripts/scan-public.sh >/dev/null 2>&1 ); }
expect() { # name, wanted exit, description
  run "$1" "${4:-}"; rc=$?
  if [ "$rc" -eq "$2" ]; then echo "ok   $3"; else echo "FAIL $3 (exit $rc, wanted $2)"; fail=1; fi
}
plant() { fresh "$1"; printf '%s\n' "$2" > "$T/$1/leak.txt"; }

fresh clean;                                  expect clean 0 "clean tree passes"
plant github "token gh""p_abcdefghijklmnopqrstuvwxyz0123456789";   expect github 1 "GitHub token flagged"
plant aws    "AK""IAABCDEFGHIJKLMNOP";                               expect aws 1 "AWS key id flagged"
plant pem    "-----BEGIN RSA PRIV""ATE KEY-----";                    expect pem 1 "private key flagged"
plant nan    "export NAN_API""_KEY=abcdefghijklmnopqrstuv";          expect nan 1 "assigned NaN key flagged"
plant path   "see /Us""ers/somebody/project";                        expect path 1 "personal path flagged"
plant mail   "write to person@comp""any.org";                        expect mail 1 "e-mail flagged"
plant ok     "write to alice@example.com";                         expect ok 0 "example.com e-mail allowed"
plant name   "this belongs to AcmeSecret Corp";                    expect name 1 "private name flagged" "acmesecret"
exit "$fail"
