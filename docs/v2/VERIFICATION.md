# 2.0.0-alpha1 verification

Base: upstream dev 17618d012a05cc6ed109d4d45806f8ac123080e9.
Implementation: 8088b1d, feat/bagsmith-2.0 in Jeor/bagsmith.

- Full command: `python tools/run_tests.py` — exit 0, ALL OK; 219 test sets, 101,690 assertions passed, zero failed.
- Includes 58 new appearance checks using shipping defaults. The historical suites explicitly use the legacy appearance fixture.
- Additional shipping-appearance run: 110 assertions passed across Global Inventory, currency details, sorting/pins, custom sections, junk sales and prompts, using `--shipping-ui`.
- Untouched upstream baseline: 101,607 assertions passed, zero failed.
- Read-only code review: three findings addressed (Travel Mode control, hidden-count geometry, footer styling).
- Package: 138 files verified byte-for-byte against the checkout; ZIP integrity checked.
- Package SHA256: `6d03f1283d6cd8e3e7eb91da800840b2e724d6a7c6717d479b2f2eba84b9e774`.
- `git diff --check` passed.

In-game visual validation has not been performed. No live addon installation was changed.

## 2.0.0-alpha2 verification

Implementation: 54946d1, feat/bagsmith-2.0 in Jeor/bagsmith.

- Full regression: `python -u tools/run_tests.py` exited 0 with ALL OK; all 219 test sets passed.
- Shipping-default 2.0 checks: 89 passed, zero failed (also included in the full run).
- Additional shipping-appearance behavior checks: Global Inventory (10), currencies (15), sorting/pins (26), custom pins (14), all passed.
- Legacy compact category checks: 416 passed.
- Separate BagSmithTest package: Lua syntax and namespace isolation verified; all 89 focused checks passed against renamed code.
- Live installation: all 138 files verified against the alpha2 package. Regular BagSmith and both addons' saved settings were unchanged. Alpha1 was backed up before replacement.
- Read-only review finding addressed: reserve divider space for the relocated Clear Recent action, including narrow windows.
- `git diff --check` passed.

Alpha2 is installed for in-game review. Automated checks do not verify the rendered WoW UI; compact/split layouts and short-window drawer scrolling still need visual acceptance in game.

## 2.0.0-alpha3 verification

- Confirmed root cause from the saved WoW BugGrabber stack: backdrop geometry triggered toolbar OnSizeChanged during BagOptions.Build, before optionsLabels existed; the failed layout left its guard set.
- A nested-callback regression reproduced the blank drawer and detached controls before the readiness fix, then passed afterward.
- Full regression run: 219 test sets, exit 0, ALL OK. Two stale version-pattern assertions were corrected before the successful run.
- The later mutually exclusive currency/options behavior passed the final focused suite: 101 checks. Shipping-appearance currency detail checks: 15 passed. Earlier shipping Global Inventory/sort checks also passed.
- The final renamed BagSmithTest package passed Lua syntax, namespace isolation and all 101 focused checks. All 138 installed files matched the package, with a backup made first. Regular BagSmith and saved settings were unchanged.
- Final installed release remains 2.0.0-alpha3. Reload is required to pick up the drawer repair and currency dismissal behavior. In-game visual acceptance remains with the user.

The GitHub Pages demo now includes independent character inventories, all rarity fixtures, mutually exclusive currency/options drawers, per-character sample currency balances, pinning, and all nine bundled font files with interface/header selectors. Twelve model tests and desktop/mobile browser checks passed; the public Pages deployment was verified in the in-app browser. Browser fixtures are visual simulations and do not replace in-game checks.

## Alpha4: upstream dev and Minimal sidebar (2026-11-18)

- Upstream dev `6004e6e` (1.9.2) merged; alpha4 retains the 2.0 presentation default.
- Full Lua regression runner: 233 sets, 102,085 assertions, zero failures, ALL OK.
- Eight newer upstream suites also passed with `--shipping-ui`.
- Separate renamed package: 110 focused checks passed; all Lua sources parsed.
- Installed 140 hash-verified files in BagSmithTest; prior test build backed up, regular BagSmith and saved variables untouched.
- Minimal disclosures and layout menu preserve existing actions; category bands/rails restored with wrapping metadata retained.
- This is mock/runtime verification. Actual WoW rendering and interaction acceptance still require in-game review after reload.
