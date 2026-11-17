# BagSmith 2.0 alpha

This Jeor branch starts from Shweep8's dev commit `17618d012a05cc6ed109d4d45806f8ac123080e9` (1.9.0-beta18).

The new appearance is enabled by default. Click the bag icon beside the title to open Bag Options. Grouping, view, layout, sort, stack merging, category details and the existing tools live there. Scroll the drawer when the window is short. It opens left when space allows, or right near the screen's left edge, without resizing the inventory.

Category titles use fine dividers. Enabled vendor and auction values stay visible, wrapping within a taller header before items are placed. Empty values are omitted. Existing compact/split ordering, item interactions, tooltips, section actions and sheet behavior remain in place. Both skin palettes use the new window controls; Classic still uses its item artwork.

Search includes its filter button. Sheet tabs use a selected underline and footer capacity controls have no boxes. The status note remains available in the bag button's tooltip.

To restore the upstream appearance, use `/bs v2 off`, then `/reload`. To enable the new appearance again, use `/bs v2`, then `/reload`. Appearance changes take effect at reload to avoid replacing live protected item frames.

## Verification

`python tools/run_tests.py` runs the existing regression suites with their historical presentation fixture plus `tests/core_2_0_0_tests.lua` with shipping defaults. Historical tests pin toolbar and Classic-template geometry; their fixture explicitly chooses the legacy appearance. The production default remains enabled and the 2.0 test loads it without an override.

Use `python tools/run_tests.py --shipping-ui <test-files.lua>` to run existing behavior tests against the shipping appearance. Global Inventory, currency details, sorting, custom sections, junk sales and prompts were also exercised this way.

## In-game review

This is an alpha, not an in-game-validated release. Test both skin palettes, compact/split/standard and List/Icons, long custom section names, large text, vendor/AH/count visibility, bank and Global Inventory, Travel Mode, short windows, screen edges, section drag/drop and combat. Compare against `approved-mockup.png`. The live installed addon is not changed by building this branch.

## Alpha2 refinement

The drawer now uses grouping/sort dropdowns and checkbox rows for stack merging and category details. All Settings remains fixed below the scrollable content; a slim scrollbar and edge shading indicate overflow. The frame follows the bag skin and background opacity. View/Layout choices share their sizing, tool rows are tighter, and the search filter is smaller.

Compact categories reserve the tallest heading in each row before finalizing item offsets. This aligns first item rows without dropping vendor/AH metadata, and expands pinned backgrounds accordingly. Dividers are capped at 180 UI pixels. Clear Recent sits on the right; its divider reserves that action's space.

The separate BagSmithTest installation is updated without touching saved settings or regular BagSmith. Alpha1 was backed up before replacement. In-game screenshots remain the visual acceptance check.

## Alpha3 drawer repair

The live client's backdrop sizing can synchronously invoke the old toolbar's `OnSizeChanged` callback while the merge checkbox is being created. Alpha2 entered the drawer layout before `optionsLabels` existed, raised an error, and left `optionsLayingOut` set. Later layout attempts returned early, leaving an empty drawer and detached tools.

Alpha3 publishes `optionsReady` only once drawer construction finishes. Layout ignores earlier resize callbacks without setting its reentrancy guard. A regression fixture recreates the nested callback for main and bank windows and checks that visible tools are attached to the drawer. The normal mock did not simulate that callback timing.
