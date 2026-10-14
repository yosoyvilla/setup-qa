#!/usr/bin/env python3
"""Summarise eval results: pass rate per arm/model/task and a paired task-level bootstrap.

usage: python3 evals/analyze.py [results_dir] [--arms bare,harness] [--tasks t1-,h1-]
The task is the unit of analysis (repetitions of one task are not independent samples).
"""
import glob, json, os, random, statistics as st, sys

args = sys.argv[1:]
opt = {a.split("=", 1)[0]: a.split("=", 1)[1] for a in args if a.startswith("--") and "=" in a}
pos = [a for a in args if not a.startswith("--")]
root = pos[0] if pos else os.path.join(os.path.dirname(os.path.abspath(__file__)), "results")
arms_f = opt.get("--arms", "").split(",") if opt.get("--arms") else None
task_f = opt.get("--tasks", "").split(",") if opt.get("--tasks") else None

runs = []
for g in glob.glob(os.path.join(root, "*", "*", "grade.json")):
    d = os.path.dirname(g); task = os.path.basename(os.path.dirname(d)); name, rep = os.path.basename(d).rsplit("-r", 1)
    arm, model = name.split("-", 1)
    if arm in ("REF", "NOOP") or (arms_f and arm not in arms_f) or (task_f and not any(task.startswith(t) for t in task_f)):
        continue
    try:
        ok = json.load(open(g))["pass"]; wall = int(open(os.path.join(d, "wall_seconds")).read())
        rc = int(open(os.path.join(d, "exit_code")).read())
    except Exception:
        continue  # still running or crashed before grading
    runs.append(dict(arm=arm, model=model, task=task, rep=rep, ok=ok, wall=wall, rc=rc))

if not runs:
    sys.exit("no graded runs found in " + root)
arms = sorted({r["arm"] for r in runs}); tasks = sorted({r["task"] for r in runs})
rate = lambda rs: sum(r["ok"] for r in rs) / len(rs) if rs else float("nan")

print(f"{len(runs)} graded runs\n")
print("task".ljust(28) + "".join(a.rjust(10) for a in arms))
for t in tasks:
    print(t.ljust(28) + "".join(f"{rate([r for r in runs if r['task']==t and r['arm']==a]):10.2f}" for a in arms))
print()
for a in arms:
    for m in sorted({r["model"] for r in runs}):
        rs = [r for r in runs if r["arm"] == a and r["model"] == m]
        if rs:
            w = sorted(r["wall"] for r in rs)
            print(f"{a:10} {m:8} pass {sum(r['ok'] for r in rs)}/{len(rs)}  median {w[len(w)//2]}s  timeouts {sum(r['rc']==124 for r in rs)}")

if len(arms) >= 2:
    random.seed(1)
    per = {a: [rate([r for r in runs if r["task"] == t and r["arm"] == a]) for t in tasks] for a in arms}
    print("\npaired task-level difference (95% bootstrap CI); a CI containing 0 means no measured difference")
    for i, x in enumerate(arms):
        for y in arms[i + 1:]:
            pairs = [(p, q) for p, q in zip(per[x], per[y]) if p == p and q == q]
            diffs = [p - q for p, q in pairs]
            bs = sorted(st.mean(random.choices(diffs, k=len(diffs))) for _ in range(5000))
            print(f"  {x} - {y}: {st.mean(diffs):+.3f}  [{bs[125]:+.3f}, {bs[4875]:+.3f}]  over {len(diffs)} tasks")
