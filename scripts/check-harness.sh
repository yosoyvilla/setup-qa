#!/usr/bin/env bash
# Health check for a setup-qa install. Exit 0 only if every check passes.
# usage: scripts/check-harness.sh [--offline]
#   default    also calls the NaN API (needs NAN_API_KEY) and starts the Playwright MCP server
#   --offline  checks files, configuration and discovery only; no network, no model calls
set -u
OFFLINE=0; [ "${1:-}" = "--offline" ] && OFFLINE=1
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
EXPECT_VERSION="1.18.34"
FAILED=0; WARNED=0
TMP="$(mktemp -t setup-qa-check.XXXXXX)"; trap 'rm -f "$TMP"' EXIT
ok()   { printf '  ok    %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; FAILED=1; }
warn() { printf '  warn  %s\n' "$*"; WARNED=1; }

echo "setup-qa health check ($([ "$OFFLINE" -eq 1 ] && echo offline || echo online))"

# --- opencode
VER="$(opencode --version 2>/dev/null)"
[ "$VER" = "$EXPECT_VERSION" ] && ok "opencode $VER" || bad "opencode version is '${VER:-missing}', expected $EXPECT_VERSION"

# --- resolved configuration (no network)
CFG="$(opencode debug config 2>/dev/null)"
if [ -z "$CFG" ]; then bad "opencode could not resolve its configuration"; else
  printf '%s' "$CFG" | python3 -I -c '
import json, sys
c = json.load(sys.stdin); errs = []
if c.get("model") != "nan/qwen3.6": errs.append("default model is %r" % c.get("model"))
if c.get("small_model") != "nan/gemma4": errs.append("small model is %r" % c.get("small_model"))
if c.get("enabled_providers") != ["nan"]: errs.append("enabled providers are %r" % c.get("enabled_providers"))
if sorted(c.get("provider", {}).get("nan", {}).get("models", {})) != ["gemma4", "qwen3.6"]: errs.append("NaN models are not exactly qwen3.6 and gemma4")
if list(c.get("mcp", {})) != ["playwright"]: errs.append("MCP servers are %r" % list(c.get("mcp", {})))
deny = {k for k, v in c.get("permission", {}).get("bash", {}).items() if v == "deny"}
for need in ("sudo *", "git push --force*", "git reset --hard*"):
    if need not in deny: errs.append("bash deny rule missing: " + need)
print("\n".join(errs)); sys.exit(1 if errs else 0)' > "$TMP" 2>&1 \
    && ok "config: model qwen3.6, small gemma4, only NaN, only Playwright MCP, deny rules present" \
    || { while IFS= read -r l; do bad "config: $l"; done < "$TMP"; }
fi

# --- skills, agents, commands, rules, lint
SKILLS="$(opencode debug skill 2>/dev/null | python3 -I -c 'import json,sys; print(" ".join(sorted(s["name"] for s in json.load(sys.stdin))))' 2>/dev/null)"
for s in playwright-conventions test-design flaky-tests test-review verify-fix api-testing visual-checks migrate-cypress migrate-selenium page-objects bug-report; do
  case " $SKILLS " in *" $s "*) ;; *) bad "skill not found: $s" ;; esac
done
SKILLS_BAD=0; for s in playwright-conventions test-design flaky-tests test-review verify-fix api-testing visual-checks migrate-cypress migrate-selenium page-objects bug-report; do case " $SKILLS " in *" $s "*) ;; *) SKILLS_BAD=1 ;; esac; done
[ "$SKILLS_BAD" -eq 0 ] && ok "all 11 skills are discovered"
opencode agent list 2>/dev/null | /usr/bin/grep -q '^reviewer' && ok "reviewer agent present" || bad "reviewer agent missing"
for c in write-tests fix-flaky review-suite migrate triage check; do [ -f "$CONFIG_DIR/commands/$c.md" ] || bad "command missing: $c"; done
[ -f "$CONFIG_DIR/AGENTS.md" ] && ok "rules file present" || bad "AGENTS.md missing"
[ -x "$CONFIG_DIR/bin/qa-lint" ] && ok "qa-lint present" || bad "qa-lint missing or not executable"
[ -d "/Applications/Google Chrome.app" ] && ok "Google Chrome present" || bad "Google Chrome not found (the browser tools need it)"

[ "$OFFLINE" -eq 1 ] && { [ "$FAILED" -eq 0 ] && echo "offline checks passed (run without --offline once NAN_API_KEY is set)"; exit "$FAILED"; }

# --- online: NaN key and both models
if [ -z "${NAN_API_KEY:-}" ]; then
  bad "NAN_API_KEY is not set"
else
  for m in qwen3.6 gemma4; do
    OUT="$(perl -e 'alarm 120; exec @ARGV' opencode run -m "nan/$m" 'Reply with exactly the single word: pong' 2>&1)"
    case "$OUT" in *pong*|*Pong*) ok "NaN model $m answers" ;; *) bad "NaN model $m did not answer (key invalid, or network?)" ;; esac
  done
fi

# --- online: Playwright MCP actually starts
MCP="$(opencode mcp list 2>&1)"
case "$MCP" in *playwright*connected*|*playwright*Connected*|*playwright*ready*) ok "Playwright MCP connects" ;;
  *) warn "could not confirm the Playwright MCP connection; output was: $(printf '%s' "$MCP" | tr '\n' ' ' | cut -c1-160)" ;; esac

if [ "$FAILED" -eq 0 ]; then
  [ "$WARNED" -eq 0 ] && echo "all checks passed" || echo "checks passed WITH WARNINGS: read the warn lines above"
fi
exit "$FAILED"
