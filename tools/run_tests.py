#!/usr/bin/env python3
"""BagSmith test runner (Lua 5.1 via lupa). Run from the repository root (the folder holding BagSmith/,
BagSmith_Gamepad/, BagSmith_ExamplePlugin/ and tests/).

    pip install lupa            # once
    python3 tools/run_tests.py                 # everything: the core suite and every set (about 4 to 5 minutes)
    python3 tools/run_tests.py --quick         # every set but the core suite (tests/run.lua)
    python3 tools/run_tests.py -j 1            # one set at a time (the default runs as many at once as you have CPUs)
    python3 tools/run_tests.py core_1_9_4_beta2_tests.lua    # one or more sets, by file name or by path

Sets are found, not listed (since 1.9.4): the core suite, tests/run.lua, and every .lua file in tests/features,
tests/releases, tests/audits and tests/plugins, and their subfolders (see tests/README.md). Any other .lua file under
tests/ must be one of the helpers named in HELPERS below, or sit in tests/tools (probes and scripts, never run as
sets); anything else stops the run before it starts, so a set can't be skipped by being put in the wrong place.

Each set runs in its own Lua runtime, as it always has. With more than one job the sets run in separate worker
processes; each set's output is captured whole, as the bytes it printed, and printed one set after another in a
fixed order, so a log reads the same whatever order they finished in. The last lines give the number of sets and
checks, then ALL OK or the failures.

Exit status is non-zero if anything failed. The core suite (tests/run.lua) began as the pinned 0.15.0 suite; its
by-design updates since are listed in docs/plugins/TEST-RESULTS.md and the handoff. These are mock results: the harness models
the client (tests/mock.lua) and is not evidence of behavior in the actual game.
"""
import sys, os, re, time, argparse
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    print("lupa (Lua 5.1) is required: pip install lupa"); sys.exit(2)

PRELUDE = '''package.path = "./tests/?.lua;" .. package.path
fails, passes = 0, 0
function check(cond, msg) if cond then passes = passes + 1 else fails = fails + 1; print("FAIL: " .. msg) end end
'''

CORE = "tests/run.lua"
# Folders whose .lua files are sets, in the order they're printed (the core suite comes last).
SET_DIRS = ["features", "releases", "audits", "plugins"]
# .lua files at the top of tests/ that aren't sets: the mock client, files the core suite and sets load, and the
# saved-variables fixtures. A new one goes here; a new set goes in one of SET_DIRS.
HELPERS = {"mock.lua", "look.lua", "lifecycle.lua", "invariants.lua", "modern_check.lua", "classic_check.lua",
           "companion_loader.lua", "prod_0112_savedvars.lua", "prod_0919_savedvars.lua", "tga.lua"}


def run_file(path, prelude=True, quiet=False):
    """Run one Lua set. (1.5.0-beta5, audit F6) The core suite ends with os.exit(code): that call now reports its
    code to Python through a private function and raises a private per-run token. A set passes only if it returned
    0 failures, or exited through that function with code 0 and, for prelude sets, no failed check. Any other error,
    whatever its message says, is a failure."""
    lua = LuaRuntime(unpack_returned_tuples=True)
    token = "BAGSMITH-RUNNER-EXIT-" + os.urandom(8).hex()
    exited = {}
    def record_exit(code):
        exited["code"] = code
    lua.globals()["__bs_record_exit"] = record_exit
    lua.execute('local tok, rec = ...; os.exit = function(c) rec(c); error(tok, 0) end; __bs_record_exit = nil', token, record_exit)
    if quiet: lua.execute('print = function() end')   # the self-test's synthetic sets print nothing
    src = open(path, encoding="utf-8").read()
    code = (PRELUDE + src + '\nprint(("%d passed, %d failed"):format(passes, fails))\nreturn fails\n') if prelude else src
    t = time.time()
    try:
        fails = lua.execute(code)
    except Exception as e:  # a Lua error, or os.exit through the private exit
        msg = str(e)
        checked_fails = lua.globals()["fails"] if prelude else None
        if token in msg and "code" in exited:
            # (1.5.0-beta9) exactly 0, true or no code is success; 1 is a failure (in Python 1 == True, so
            # "code in (0, None, True)" wrongly accepted os.exit(1))
            code = exited["code"]
            ok_exit = code is None or code is True or (not isinstance(code, bool) and isinstance(code, (int, float)) and code == 0)
            fails = 0 if ok_exit else 1
            if checked_fails: fails = 1          # a failed check is a failure however the set ended
        else:
            print("ERROR:", msg[:400]); fails = 1
    print("%s: %s (%.0fs)" % (path, "ok" if not fails else "FAILED", time.time() - t))
    return int(fails or 0)


def _flush_all():
    """Python's buffer, then C's (Lua's print writes through C stdio)."""
    sys.stdout.flush(); sys.stderr.flush()
    try:
        import ctypes
        ctypes.CDLL(None).fflush(None)
    except Exception:
        pass


def run_captured(job):
    """(1.9.4) Run one set in a worker process with its output (fd 1 and 2) going to a temporary file, and return
    (path, failures, the bytes it printed). The bytes are kept as they are: some sets print text that isn't UTF-8."""
    import tempfile
    path, prelude = job
    _flush_all()
    with tempfile.TemporaryFile() as tmp:
        saved = os.dup(1), os.dup(2)
        os.dup2(tmp.fileno(), 1); os.dup2(tmp.fileno(), 2)
        try:
            try:
                fails = run_file(path, prelude=prelude)
            except BaseException as e:   # anything the runner itself raised: a failure, said in the set's output
                print("ERROR: the runner failed on this set:", repr(e)[:400]); fails = 1
        finally:
            _flush_all()
            os.dup2(saved[0], 1); os.dup2(saved[1], 2); os.close(saved[0]); os.close(saved[1])
        tmp.seek(0)
        return path, fails, tmp.read()


def _natural(s):
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", s)]


def discover():
    """Every set under tests/, in print order, and any .lua file that is neither a set nor a known helper."""
    sets, stray = [], []
    for root, dirs, files in os.walk("tests"):
        dirs.sort()
        rel = os.path.relpath(root, "tests").replace(os.sep, "/")
        top = rel.split("/")[0]
        if top == "tools":
            dirs[:] = []; continue
        for f in files:
            if not f.endswith(".lua"): continue
            p = os.path.join(root, f).replace(os.sep, "/")
            if rel == ".":
                if p != CORE and f not in HELPERS: stray.append(p)
            elif top in SET_DIRS:
                sets.append(p)
            else:
                stray.append(p)
    sets.sort(key=lambda p: (SET_DIRS.index(p.split("/")[1]), _natural(p)))
    return sets, stray


def resolve(arg):
    """A set given on the command line: a path, or (since sets moved into folders in 1.9.4) just its file name."""
    if os.path.isfile(arg): return arg.replace(os.sep, "/")
    name = os.path.basename(arg)
    hits = []
    for root, _, files in os.walk("tests"):
        if name in files: hits.append(os.path.join(root, name).replace(os.sep, "/"))
    if len(hits) == 1: return hits[0]
    raise SystemExit("no such set: %s" % arg if not hits else "%s matches more than one file: %s" % (arg, ", ".join(hits)))


_COUNT = re.compile(rb"^(\d+) passed, (\d+) failed\s*$", re.M)


def checks_in(output):
    """The checks a set reported ("N passed, M failed"; the last such line), or None."""
    m = None
    for m in _COUNT.finditer(output): pass
    return (int(m.group(1)), int(m.group(2))) if m else None


def run_sets(jobs, workers):
    """Run (path, prelude) jobs and print each set's output whole, in the order given. Returns
    (failed sets, passed checks, failed checks, per-set results)."""
    results = {}
    out = sys.stdout.buffer
    def show(path, fails, data):
        out.write(("== %s\n" % path).encode()); out.write(data)
        if data and not data.endswith(b"\n"): out.write(b"\n")
        out.flush()
        results[path] = (fails, checks_in(data))
    if workers <= 1:
        for path, prelude in jobs:
            print("==", path); sys.stdout.flush()
            p, fails, data = run_captured((path, prelude))
            out.write(data); out.flush()
            results[path] = (fails, checks_in(data))
    else:
        from concurrent.futures import ProcessPoolExecutor
        # the longest first (the core suite), so it isn't left running alone at the end
        order = sorted(range(len(jobs)), key=lambda i: jobs[i][0] != CORE)
        done = {}
        with ProcessPoolExecutor(max_workers=workers) as ex:
            futures = {i: ex.submit(run_captured, jobs[i]) for i in order}
            nxt = 0
            from concurrent.futures import as_completed
            index = {f: i for i, f in futures.items()}
            for f in as_completed(futures.values()):
                i = index[f]
                try:
                    done[i] = f.result()
                except Exception as e:   # a worker died: that set fails, and says why
                    done[i] = (jobs[i][0], 1, ("ERROR: the worker running this set stopped: %r\n%s: FAILED\n" % (e, jobs[i][0])).encode())
                while nxt in done:
                    show(*done.pop(nxt)); nxt += 1
    bad = sum(1 for f, _ in results.values() if f)
    passed = sum(c[0] for _, c in results.values() if c)
    failed = sum(c[1] for _, c in results.values() if c)
    return bad, passed, failed, results


def runner_self_test(workers):
    """(1.5.0-beta5, audit F6) The runner must fail a set that fails a check and then raises an error mentioning
    EXIT:0, and one that fails a check and then calls os.exit(0); and pass a clean os.exit(0). (1.9.4) And the same
    through the worker processes: a failing set fails there too, a passing one passes, and their checks are counted."""
    import tempfile
    cases = [
        ('check(false, "deliberately failing assertion")\nerror("EXIT:0 synthetic unrelated Lua error")\n', True),
        ('check(false, "deliberately failing assertion")\nos.exit(0)\n', True),
        ('error("something else went wrong")\n', True),
        ('check(true, "fine")\nos.exit(1)\n', True),
        ('check(true, "fine")\nos.exit(0)\n', False),
        ('check(true, "fine")\n', False),
    ]
    ok = True
    names = []
    for src, should_fail in cases:
        with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
            f.write(src); name = f.name
        names.append((name, should_fail))
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            failed = run_file(name, quiet=True) != 0
        if failed != should_fail: ok = False; print("runner self-test: wrong result for", repr(src[:60]))
    # through the workers (output captured, not shown)
    if workers > 1:
        from concurrent.futures import ProcessPoolExecutor
        with ProcessPoolExecutor(max_workers=2) as ex:
            got = list(ex.map(run_captured, [(n, True) for n, _ in names]))
        for (n, should_fail), (_, fails, data) in zip(names, got):
            if (fails != 0) != should_fail: ok = False; print("runner self-test (workers): wrong result for", n)
        last = got[-1][2]
        if checks_in(last) != (1, 0) or b"ok" not in last: ok = False; print("runner self-test (workers): output not captured")
    for n, _ in names: os.unlink(n)
    print("runner self-test:", "ok" if ok else "FAILED")
    return 0 if ok else 1


def main(argv):
    if not os.path.isdir("tests") or not os.path.isdir("BagSmith"):
        print("run from the repository root (needs tests/ and BagSmith/)"); return 2
    ap = argparse.ArgumentParser(description="BagSmith test runner")
    ap.add_argument("sets", nargs="*", help="sets to run (a path, or a file name); none runs everything")
    ap.add_argument("--quick", action="store_true", help="every set but the core suite")
    ap.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 1, help="sets at once (default: CPUs)")
    ap.add_argument("--results", help="also write one line per set (path, ok or FAILED, passed, failed) to this file")
    a = ap.parse_args(argv)
    workers = max(1, a.jobs)
    if a.sets:
        jobs = [(p, p != CORE) for p in (resolve(s) for s in a.sets)]
    else:
        sets, stray = discover()
        if stray:
            print("These .lua files are neither sets nor known helpers, so they would never run:")
            for p in stray: print("  ", p)
            print("Move a set into tests/features, tests/releases, tests/audits or tests/plugins; add a helper to HELPERS in")
            print("tools/run_tests.py; or put a probe in tests/tools.")
            return 2
        print("== runner self-test"); sys.stdout.flush()
        if runner_self_test(workers): print("FAILURES: the runner's self-test"); return 1
        jobs = [(p, True) for p in sets] + ([] if a.quick else [(CORE, False)])
    t = time.time()
    bad, passed, failed, results = run_sets(jobs, workers)
    if a.results:
        with open(a.results, "w", encoding="utf-8") as f:
            for path, _ in jobs:
                fails, c = results[path]
                f.write("%s\t%s\t%s\t%s\n" % (path, "FAILED" if fails else "ok", c[0] if c else "-", c[1] if c else "-"))
    print("%d set(s), %s checks passed, %d failed, in %.0fs (%d at once)" % (len(jobs), format(passed, ","), failed, time.time() - t, workers))
    print("ALL OK" if not bad else "FAILURES: %d set(s)" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
