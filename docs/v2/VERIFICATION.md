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
