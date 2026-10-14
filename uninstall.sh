#!/usr/bin/env bash
# Removes the files setup-qa installed (listed in the manifest) and puts back the files that existed
# before the first install (kept in backups/original). Whatever is deleted is first copied to
# backups/uninstall-<time>, so edits you made after installing are not lost.
# Leaves opencode, Node and Chrome installed.
set -u
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
MANIFEST="$CONFIG_DIR/.setup-qa-manifest"
SAVE="$CONFIG_DIR/backups/uninstall-$(date +%Y%m%d-%H%M%S)"
[ -f "$MANIFEST" ] || { echo "nothing to do: no setup-qa manifest in $CONFIG_DIR"; exit 0; }

while IFS= read -r f; do
  case "$f" in
    "$CONFIG_DIR"/*)
      if [ -f "$f" ]; then
        rel="${f#"$CONFIG_DIR"/}"; mkdir -p "$SAVE/$(dirname "$rel")" && cp -p "$f" "$SAVE/$rel" && rm -f "$f"
      fi ;;
  esac
done < "$MANIFEST"
rm -f "$MANIFEST"
find "$CONFIG_DIR/skills" "$CONFIG_DIR/commands" "$CONFIG_DIR/agents" "$CONFIG_DIR/bin" -type d -empty -delete 2>/dev/null

if [ -d "$CONFIG_DIR/backups/original" ]; then
  cp -R "$CONFIG_DIR/backups/original"/. "$CONFIG_DIR"/ && echo "restored the files that existed before setup-qa"
fi
echo "setup-qa removed from $CONFIG_DIR (removed files are saved in $SAVE)"
