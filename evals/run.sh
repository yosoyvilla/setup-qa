#!/usr/bin/env bash
# Run one eval cell in a fresh container.
# usage: evals/run.sh <arm: bare|harness|REF|NOOP> <model: qwen3.6|gemma4|none> <task> <rep>
# Results land in evals/results/<task>/<arm>-<model>-r<rep>/ (git-ignored).
# Needs Docker and NAN_API_KEY (only for bare|harness). The image is built on first use.
set -u
E="$(cd "$(dirname "$0")" && pwd)"; REPO="$(dirname "$E")"
ARM="${1:?arm}"; MODEL="${2:?model}"; TASK="${3:?task}"; REP="${4:-1}"
IMAGE=setup-qa-evals
[ -d "$E/tasks/$TASK" ] || { echo "no such task: $TASK" >&2; exit 2; }
docker image inspect "$IMAGE" >/dev/null 2>&1 || docker build -t "$IMAGE" "$E" >&2 || exit 1
OUT="$E/results/$TASK/$ARM-$MODEL-r$REP"; mkdir -p "$OUT"
docker run --rm -e NAN_API_KEY -e RUN_TIMEOUT \
  -v "$E/harness:/root/bench:ro" -v "$E/tasks/$TASK:/root/task:ro" -v "$REPO:/root/repo:ro" -v "$OUT:/out" \
  --entrypoint bash "$IMAGE" /root/bench/run-task.sh "$ARM" "$MODEL"
