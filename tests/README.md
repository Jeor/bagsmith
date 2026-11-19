# BagSmith's tests

They run outside the game against a mock WoW client (`mock.lua`), with Python 3 and `lupa`, from the repository root:

    pip install lupa
    python3 tools/run_tests.py                      # everything: the core suite and every set
    python3 tools/run_tests.py --quick              # every set but the core suite
    python3 tools/run_tests.py -j 1                 # one set at a time (the default runs one per CPU)
    python3 tools/run_tests.py some_set_tests.lua   # one or more sets, by file name or path

Each set runs in its own Lua runtime, so sets don't affect one another and can run at once. Mock results show the
code's behaviour, not the real game client's.

## Where things are

- `run.lua`: the core suite, the oldest and largest set.
- `features/`: sets for one feature (compact categories, icon corners, the Unusable Item Overlay, ...).
- `releases/<x.y>/`: the sets written for a release or one of its betas, such as
  `releases/1.9/core_1_9_4_beta2_tests.lua`.
- `audits/<x.y>/`: the probes the independent audits supplied or asked for, by the release they audited. Their file
  names are how the audit reports refer to them, so they keep them.
- `plugins/`: the plugin API, the example plugin and the Gamepad companion.
- `tools/`: probes and scripts that never run with the suite (see `tools/README.md`).
- At the top: `mock.lua`, the files the core suite and sets load (`look.lua`, `lifecycle.lua`, `invariants.lua`,
  `modern_check.lua`, `classic_check.lua`, `companion_loader.lua`), the look baselines and two saved-variables fixtures.

## Adding a set

Put it in the folder it belongs to; the runner finds every `.lua` file in `features/`, `releases/`, `audits/` and
`plugins/` (there's no list to add it to). A set starts from a fresh runtime with `check(condition, message)` and
`require("mock")` ready; see any recent set in `releases/` for the usual start. A new helper goes at the top and into
`HELPERS` in `tools/run_tests.py`. The runner refuses to start if it finds a `.lua` file that's neither a set nor a
known helper, so nothing is skipped by being in the wrong place.
