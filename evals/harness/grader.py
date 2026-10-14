"""usage: grader.py <task.json> <tests_dir>  -> JSON on stdout. Starts its own SUT per scenario."""
import json, os, subprocess, sys, time, urllib.request, pathlib

task = json.load(open(sys.argv[1])); tests = pathlib.Path(sys.argv[2])
res = {"static": {}, "scenarios": []}

# static checks: forbidden constructs must not appear in the test sources
work = tests.parent
roots = [tests] + [work / d for d in ("pages", "fixtures", "support", "utils", "helpers", "page-objects") if (work / d).is_dir()]
src = "\n".join(p.read_text(errors="replace") for r in roots for p in r.rglob("*") if p.suffix in (".ts", ".js"))
hits = [f for f in task.get("forbid", []) if f in src]
over = {k: src.count(k) for k, mx in task.get("max_count", {}).items() if src.count(k) > mx}
tdir = pathlib.Path(sys.argv[1]).parent
changed = [f for f in task.get("unchanged", []) if not (work / f).exists() or (work / f).read_bytes() != (tdir / "start" / f).read_bytes()]
res["static"] = {"forbidden_hits": hits, "over_max_count": over, "changed_files": changed, "ok": not (hits or over or changed)}

import re
def check_file(c):
    f = work / c["file"]
    if not f.exists(): return {"file": c["file"], "ok": False, "why": "missing"}
    try: j = json.loads(f.read_text())
    except Exception: return {"file": c["file"], "ok": False, "why": "not json"}
    bad = [k for k, v in c.get("json_equals", {}).items() if j.get(k) != v]
    bad += [k for k, rx in c.get("regex", {}).items() if not re.search(rx, str(j.get(k, "")), re.I)]
    bad += [k for k, n in c.get("min_len", {}).items() if not isinstance(j.get(k), list) or len(j[k]) < n]
    e = c.get("entries")
    if e:
        items = j.get(e["key"])
        if not isinstance(items, list): bad.append("entries")
        else:
            if "exact_len" in e and len(items) != e["exact_len"]: bad.append("entry-count")
            for sub, cause in e["expect"].items():
                if not any(isinstance(i, dict) and sub in str(i.get(e["match"], "")).lower() and i.get(e["value"]) == cause for i in items): bad.append(sub)
    return {"file": c["file"], "ok": not bad, "why": bad}
res["checks"] = [check_file(c) for c in task.get("checks", [])]

def run_scenario(i, sc):
    port = 3000  # same port the agent saw, so hard-coded base URLs behave identically
    env = {**os.environ, "PORT": str(port), **sc["env"]}
    sut = subprocess.Popen(["node", "/opt/sut/server.js"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            try: urllib.request.urlopen(f"http://localhost:{port}/health", timeout=1); break
            except Exception: time.sleep(0.1)
        runs = []
        for _ in range(sc["repeat"]):
            e = {**os.environ, "TEST_DIR": str(tests), "BASE_URL": f"http://localhost:{port}"}
            p = subprocess.run(["npx", "playwright", "test", "-c", "/opt/qa/grader.config.ts"], cwd="/opt/qa", env=e, capture_output=True, text=True, timeout=300)
            try:
                st = json.loads(p.stdout)["stats"]
                total = st["expected"] + st["unexpected"] + st["flaky"] + st["skipped"]
                runs.append({"total": total, "failed": st["unexpected"], "flaky": st["flaky"], "skipped": st["skipped"]})
            except Exception as ex:
                runs.append({"error": f"{type(ex).__name__}: {p.stderr[-300:]}"})
        return runs
    finally:
        sut.terminate(); sut.wait()

mt = task["min_tests"]
for i, sc in enumerate(task["scenarios"]):
    runs = run_scenario(i, sc)
    if sc["expect"] == "pass":
        ok = all("error" not in r and r["total"] >= mt and r["failed"] == 0 and r["flaky"] == 0 and r["skipped"] == 0 for r in runs)
    else:  # must detect the seeded bug: tests ran (not a crash) and at least one failed
        ok = all("error" not in r and r["total"] >= mt and r["failed"] >= 1 for r in runs)
    res["scenarios"].append({"name": sc["name"], "expect": sc["expect"], "ok": ok, "runs": runs})

if "min_detected" in task:  # mutation-hunt tasks: the healthy app must pass and enough seeded defects must be caught
    res["detected"] = sum(1 for s in res["scenarios"] if s["expect"] == "fail" and s["ok"])
    scen_ok = all(s["ok"] for s in res["scenarios"] if s["expect"] == "pass") and res["detected"] >= task["min_detected"]
else:
    scen_ok = all(s["ok"] for s in res["scenarios"])
res["pass"] = res["static"]["ok"] and scen_ok and all(c["ok"] for c in res["checks"])
print(json.dumps(res))
