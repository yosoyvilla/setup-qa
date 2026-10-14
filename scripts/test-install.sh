#!/usr/bin/env bash
# Offline self-test of install.sh and uninstall.sh in throwaway HOME directories (one contains a space).
# It never installs dependencies and never calls the network.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(mktemp -d)"; trap 'rm -rf "$ROOT"' EXIT
fail=0
t() { if "$@"; then echo "ok   $DESC"; else echo "FAIL $DESC"; fail=1; fi; }
inst()   { env -u XDG_CONFIG_HOME HOME="$1" bash "$HERE/install.sh" --skip-deps --no-check >/dev/null 2>&1; }
uninst() { env -u XDG_CONFIG_HOME HOME="$1" bash "$HERE/uninstall.sh" >/dev/null 2>&1; }
same()   { cmp -s "$1" "$2"; }

# 1. fresh install in a HOME with a space, idempotent re-run, clean uninstall
H1="$ROOT/home one"; mkdir -p "$H1"; C1="$H1/.config/opencode"
inst "$H1"
DESC="fresh install places config, rules, lint, 11 skills, 6 commands, agent"
t test -f "$C1/opencode.jsonc" -a -f "$C1/AGENTS.md" -a -x "$C1/bin/qa-lint" -a "$(ls "$C1/skills" | wc -l | tr -d ' ')" = 11 -a "$(ls "$C1/commands" | wc -l | tr -d ' ')" = 6 -a -f "$C1/agents/reviewer.md"
inst "$H1"
DESC="second install makes no backup"
t test ! -d "$C1/backups"
uninst "$H1"
DESC="uninstall removes everything it installed"
t test ! -e "$C1/opencode.jsonc" -a ! -e "$C1/skills" -a ! -e "$C1/.setup-qa-manifest"

# 2. user's own files survive an upgrade re-run followed by uninstall
H2="$ROOT/home2"; C2="$H2/.config/opencode"; mkdir -p "$C2"
echo '{"model":"user/own"}' > "$C2/opencode.jsonc"; echo "my own rules" > "$C2/AGENTS.md"
inst "$H2"
echo "edited after install" >> "$C2/AGENTS.md"       # a later edit forces the next install to replace the file
inst "$H2"                                             # simulated upgrade
echo "late edit" >> "$C2/skills/test-review/SKILL.md"  # edit made after the last install
uninst "$H2"
DESC="original opencode.jsonc is restored after install, upgrade and uninstall"
t grep -q '"model":"user/own"' "$C2/opencode.jsonc"
DESC="original AGENTS.md is restored (not left as setup-qa text)"
t grep -qx "my own rules" "$C2/AGENTS.md"
DESC="a post-install edit is saved before uninstall deletes it"
t grep -rq "late edit" "$C2/backups"/uninstall-*

# 3. a pre-existing file byte-identical to ours is still returned to the user
H3="$ROOT/home3"; C3="$H3/.config/opencode"; mkdir -p "$C3"; cp "$HERE/AGENTS.md" "$C3/AGENTS.md"
inst "$H3"; uninst "$H3"
DESC="identical pre-existing file is not deleted by uninstall"
t same "$HERE/AGENTS.md" "$C3/AGENTS.md"

# 4. files from an older version of setup-qa that are no longer shipped are removed
H4="$ROOT/home4"; C4="$H4/.config/opencode"; mkdir -p "$H4"
inst "$H4"; echo "old" > "$C4/commands/retired.md"; echo "$C4/commands/retired.md" >> "$C4/.setup-qa-manifest"
inst "$H4"
DESC="orphaned file from an older version is removed"
t test ! -e "$C4/commands/retired.md"

exit "$fail"
