# BagSmith 2.0 test build

Based on upstream dev `6004e6e` (1.9.2). Current package: **2.0.0-alpha8**.

## Current appearance

- BagSmith Options opens beside the bag without resizing it.
- Display combines List, Standard, Compact and Split. Icon choices switch directly out of List; Compact/Split restore category grouping when needed.
- Group by offers All, Category and Bag. Global Inventory retains upstream restrictions.
- Sorting, Category details and Tools start expanded and can be collapsed for the session.
- Original shaded category bands, gold titles and accent rails stay single-line. Values that do not fit remain in the header tooltip.
- Search contains the filter button. Tabs use an underline and footer counters use quiet styling.
- Options and currencies dismiss each other. All Settings remains fixed at the drawer bottom.

The web demo retains experimental sidebar concepts and synthetic inventories for comparison. Those are not included in the addon.

## Build the testing ZIP

From this checkout, with the test runner's `lupa` dependency available:

```powershell
python tools/package_test_addon.py --output-dir ../../releases
```

The command packages only the addon, preserving assets and libraries. It renames the addon namespace, saved variables and slash commands for isolated testing, parses all Lua files, runs the focused 2.0 checks against the renamed package, and verifies every ZIP entry against its checksum. Existing release files are never overwritten. The script does not install into WoW.

Extract `BagSmithTest` into WoW's `Interface/AddOns` folder. Enable **BagSmith 2.0 Test** and disable regular BagSmith while testing. Restart WoW for a new addon folder, or `/reload` for an update. Test settings use `BagSmithTestDB` and `BagSmithTestCharDB`. Commands are `/bstest` and `/bagsmithtest`.

## Verification and review

`python tools/run_tests.py` runs the full historical fixture suite and the focused shipping 2.0 tests. `python tools/run_tests.py tests/core_2_0_0_tests.lua` runs the focused checks alone. Results and limitations are recorded in [VERIFICATION.md](VERIFICATION.md).

Historical toolbar-geometry tests use the legacy presentation; their hidden-toolbar sizing assertions do not describe the new sidebar. Use `--shipping-ui` only for applicable behavior suites.

Check both skins, all displays/grouping choices, large fonts, narrow windows, category values, bank, Global Inventory, Travel Mode and combat in game. Mock tests do not prove actual client rendering.

To restore upstream presentation in the test addon: `/bstest v2 off`, then `/reload`. Use `/bstest v2`, then `/reload` to enable 2.0 again. Earlier design history is preserved in the changelog and Git history.
