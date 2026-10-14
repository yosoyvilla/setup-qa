#!/usr/bin/env bash
# Runs ONE task inside the eval container, as root.
# usage: run-task.sh <arm: bare|harness|REF|NOOP> <model>
# mounts (under /root, which the agent user cannot enter): /root/bench (this folder), /root/task (task folder), /root/repo (setup-qa checkout), plus /out (results)
#
# Isolation: the system under test runs as user `sut` from a private directory, so the agent (user
# `agent`) can read neither its source nor its environment (which holds the seeded-bug flags).
set -u
ARM="$1"; MODEL="$2"
AGENT_UID=1100
SUT_UID=1001

mkdir -p /work /home/agent/.config/opencode
cp -R /root/task/start/. /work/
cp /root/bench/AGENTS.md /root/bench/playwright.config.ts /work/
ln -s /opt/qa/node_modules /work/node_modules
cp /root/bench/grader.config.ts /opt/qa/grader.config.ts
cp /root/task/prompt.txt /out/prompt.txt
cp -R /work /tmp/start-snapshot

# --- system under test, hidden from the agent
mkdir -p /opt/sut
cp /root/bench/sut-server.js /opt/sut/server.js
python3 -I - <<'PY'
import json
t = json.load(open("/root/task/task.json"))["sut"]
env = {"PORT": "3000", "UI": t["UI"], "LATENCY": t["LATENCY"], "BUG": t.get("BUG", "")}
open("/opt/sut/env", "w").write("".join(f"export {k}='{v}'\n" for k, v in env.items()))
PY
printf '#!/bin/sh\n. /opt/sut/env\nexec node /opt/sut/server.js\n' > /opt/sut/start.sh
chmod 700 /opt/sut/start.sh; chown -R sut:sut /opt/sut; chmod 700 /opt/sut
setpriv --reuid=$SUT_UID --regid=$SUT_UID --clear-groups env -i PATH="$PATH" /opt/sut/start.sh > /out/sut.log 2>&1 &
SUT_PID=$!
for _ in $(seq 1 50); do curl -sf localhost:3000/health >/dev/null && break; sleep 0.1; done

# --- arm configuration: `bare` = provider config only; `harness` = the full setup-qa install
CFG=/home/agent/.config/opencode
case "$ARM" in
  bare|harness) cp /root/repo/config/opencode.jsonc "$CFG/opencode.jsonc" ;;
esac
if [ "$ARM" = harness ]; then
  cp /root/repo/AGENTS.md "$CFG/AGENTS.md"
  cp -R /root/repo/skills "$CFG/skills"; cp -R /root/repo/commands "$CFG/commands"; cp -R /root/repo/agents "$CFG/agents"
  mkdir -p "$CFG/bin"; cp /root/repo/scripts/qa-lint.sh "$CFG/bin/qa-lint"; chmod +x "$CFG/bin/qa-lint"
fi
chown -R $AGENT_UID:$AGENT_UID /home/agent /work

PROMPT="$(cat /root/task/prompt.txt)"
start=$(date +%s)
case "$ARM" in
  REF)  cp -R /root/task/ref/. /work/; rc=0 ;;
  NOOP) rc=0 ;;
  ISOLATION)
        for target in /root /root/bench /root/task /root/task/ref /root/repo /opt/sut/server.js /opt/sut/env /out/prompt.txt; do
          if setpriv --reuid=$AGENT_UID --regid=$AGENT_UID --clear-groups cat "$target" >/dev/null 2>&1 || setpriv --reuid=$AGENT_UID --regid=$AGENT_UID --clear-groups ls "$target" >/dev/null 2>&1; then echo "READABLE   $target"; else echo "denied     $target"; fi
        done
        SPID=$(pgrep -f '^node /opt/sut/server.js' | head -1)
        if setpriv --reuid=$AGENT_UID --regid=$AGENT_UID --clear-groups cat /proc/$SPID/environ >/dev/null 2>&1; then echo "READABLE   sut environment"; else echo "denied     sut environment"; fi
        rc=0 ;;
  bare|harness)
        timeout -k 30 "${RUN_TIMEOUT:-600}" setpriv --reuid=$AGENT_UID --regid=$AGENT_UID --clear-groups \
          env HOME=/home/agent OPENCODE_CONFIG_CONTENT='{"mcp":{"playwright":{"enabled":false}}}' \
          opencode run -m "nan/$MODEL" --dir /work --format json "$PROMPT" > /out/events.jsonl 2> /out/stderr.log
        rc=$? ;;
  *)    echo "bad arm $ARM" >&2; rc=99 ;;
esac
echo "$rc" > /out/exit_code; echo $(( $(date +%s) - start )) > /out/wall_seconds

# nothing the agent started may survive into grading (it could hold the port the grader uses)
pkill -KILL -u $AGENT_UID 2>/dev/null; sleep 1
kill "$SUT_PID" 2>/dev/null; wait "$SUT_PID" 2>/dev/null
diff -ruN /tmp/start-snapshot /work -x node_modules -x test-results > /out/changes.diff 2>&1 || true
python3 -I /root/bench/grader.py /root/task/task.json /work/tests > /out/grade.json 2> /out/grade.err
echo "arm=$ARM model=$MODEL rc=$rc wall=$(cat /out/wall_seconds)s pass=$(python3 -I -c 'import json;print(json.load(open("/out/grade.json"))["pass"])' 2>/dev/null || echo ERR)"
