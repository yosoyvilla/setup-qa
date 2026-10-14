#!/usr/bin/env bash
# setup-qa installer for macOS. Safe to run again: it only changes what differs, and backs up anything it replaces.
#
# usage: ./install.sh [--skip-deps] [--no-check]
#   --skip-deps  do not install Homebrew packages, Node, Chrome or opencode (config files only)
#   --no-check   do not run scripts/check-harness.sh at the end
#
# Honours XDG_CONFIG_HOME. Never touches opencode's auth data and never writes your NaN key anywhere.
set -u

OPENCODE_VERSION="1.18.34"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CONFIG_DIR/backups/setup-qa-$STAMP"
ORIG_DIR="$CONFIG_DIR/backups/original"   # first copy of every file that existed before setup-qa; never overwritten
MANIFEST="$CONFIG_DIR/.setup-qa-manifest"
SKIP_DEPS=0; RUN_CHECK=1
FAILED=0

for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    --no-check) RUN_CHECK=0 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; FAILED=1; }
LOG="$(mktemp -t setup-qa-install.XXXXXX)"
run_logged() { # run a command, keep its output in $LOG, show the tail when it fails
  "$@" >> "$LOG" 2>&1 && return 0
  echo "  command failed: $*"; tail -n 8 "$LOG" | sed 's/^/    | /'; echo "  (full log: $LOG)"; return 1
}

[ "$(uname -s)" = Darwin ] || { echo "setup-qa supports macOS only." >&2; exit 1; }

say "setup-qa install"
say "  config directory: $CONFIG_DIR"

# ---------------------------------------------------------------- dependencies
node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local major; major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)"
  [ -n "$major" ] && [ "$major" -ge 20 ]
}

if [ "$SKIP_DEPS" -eq 0 ]; then
  say "1/3 dependencies"
  if ! command -v brew >/dev/null 2>&1; then
    bad "Homebrew is not installed. Install it from https://brew.sh, open a new terminal, then run this script again."
    exit 1
  fi
  if node_ok; then ok "node $(node -v)"; else
    say "  installing node with Homebrew ..."; run_logged brew install node
    node_ok && ok "node $(node -v)" || bad "node 20 or newer is required (brew install node failed)"
  fi
  if [ -d "/Applications/Google Chrome.app" ]; then ok "Google Chrome"; else
    say "  installing Google Chrome with Homebrew (the browser tools use it) ..."; run_logged brew install --cask google-chrome
    [ -d "/Applications/Google Chrome.app" ] && ok "Google Chrome" || bad "Google Chrome could not be installed; install it manually"
  fi
  if [ "$(opencode --version 2>/dev/null)" = "$OPENCODE_VERSION" ]; then ok "opencode $OPENCODE_VERSION"; else
    say "  installing opencode $OPENCODE_VERSION ..."; run_logged npm install -g "opencode-ai@$OPENCODE_VERSION"
    [ "$(opencode --version 2>/dev/null)" = "$OPENCODE_VERSION" ] && ok "opencode $OPENCODE_VERSION" \
      || bad "opencode $OPENCODE_VERSION is not on PATH (try: npm install -g opencode-ai@$OPENCODE_VERSION, then open a new terminal)"
  fi
else
  say "1/3 dependencies: skipped (--skip-deps)"
fi

# ---------------------------------------------------------------- place files
say "2/3 configuration"
mkdir -p "$CONFIG_DIR"
: > "$MANIFEST.new"
BACKED_UP=0

place() { # place <source file> <destination file> [mode]
  local src="$1" dst="$2" mode="${3:-644}" rel="${2#"$CONFIG_DIR"/}" ours=0
  [ -f "$MANIFEST" ] && /usr/bin/grep -qxF "$dst" "$MANIFEST" && ours=1
  if [ -e "$dst" ] && [ "$ours" -eq 0 ] && [ ! -e "$ORIG_DIR/$rel" ]; then
    mkdir -p "$ORIG_DIR/$(dirname "$rel")" && cp -p "$dst" "$ORIG_DIR/$rel"
  fi
  if [ -e "$dst" ] && cmp -s "$src" "$dst"; then
    echo "$dst" >> "$MANIFEST.new"; return 0
  fi
  if [ -e "$dst" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$CONFIG_DIR"/}")"
    cp -p "$dst" "$BACKUP_DIR/${dst#"$CONFIG_DIR"/}" && BACKED_UP=1
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst" && chmod "$mode" "$dst" && echo "$dst" >> "$MANIFEST.new" || bad "could not write $dst"
}

place "$HERE/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"
place "$HERE/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
place "$HERE/scripts/qa-lint.sh" "$CONFIG_DIR/bin/qa-lint" 755
for f in "$HERE"/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$f")")"; place "$f" "$CONFIG_DIR/skills/$name/SKILL.md"
done
for f in "$HERE"/commands/*.md; do place "$f" "$CONFIG_DIR/commands/$(basename "$f")"; done
for f in "$HERE"/agents/*.md;   do place "$f" "$CONFIG_DIR/agents/$(basename "$f")"; done
# files installed by an older version of setup-qa that this version no longer ships
if [ -f "$MANIFEST" ]; then
  while IFS= read -r old; do
    /usr/bin/grep -qxF "$old" "$MANIFEST.new" || { [ -f "$old" ] && rm -f "$old"; }
  done < "$MANIFEST"
fi
mv "$MANIFEST.new" "$MANIFEST"
ok "skills, commands, agents, rules and config are in place"
[ "$BACKED_UP" -eq 1 ] && warn "replaced files were backed up to $BACKUP_DIR"

# ---------------------------------------------------------------- NaN key and check
say "3/3 NaN key and health check"
if [ -n "${NAN_API_KEY:-}" ]; then
  ok "NAN_API_KEY is set in this shell"
else
  warn "NAN_API_KEY is not set yet. Add this line to ~/.zshrc, then open a new terminal:"
  say  "          export NAN_API_KEY=\"<your key>\""
fi

if [ "$RUN_CHECK" -eq 1 ]; then
  if [ -n "${NAN_API_KEY:-}" ]; then bash "$HERE/scripts/check-harness.sh" || FAILED=1
  else bash "$HERE/scripts/check-harness.sh" --offline || FAILED=1; fi
fi

if [ "$FAILED" -eq 0 ]; then
  say ""; say "Done. Open a terminal in a test project and run: opencode"
else
  say ""; say "Finished with problems (see FAIL lines above)."; exit 1
fi
