# BagSmith 2.0 visual design and implementation plan

Approved direction: the final compact/split title-and-divider mockup in this chat.
Base: Shweep8/bagsmith dev 17618d012a05cc6ed109d4d45806f8ac123080e9 (1.9.0-beta18).
Destination: Jeor/bagsmith, feat/bagsmith-2.0. Version: 2.0.0-alpha1.

Use the existing Lua frame and action implementations. A separate options drawer owns their placement and uses the existing callbacks, disabled states and tooltips. Rewriting inventory behavior or replacing the addon with a new UI framework would introduce unnecessary risk.

- [x] Add a bag-button drawer to the left of main/bank windows, with scrollable controls for short windows. Keep inventory width and item positions stable on opening. Retain every original tool and conditional availability. Close with the parent. Keep Travel Mode functional.
- [x] Move grouping, view, sorting and actions into the drawer; expose existing compact/split/standard layout settings. Preserve character picker, close button, search and filtering in the bag.
- [x] Use ivory category titles and hairline dividers. Keep enabled vendor/AH details visible, expanding header height before item placement when necessary. Preserve Recent, equipment sets, pinned/custom sections, their actions and drag/drop. Keep counts, optional details and pooled-header reuse correct.
- [x] Use text tabs with selected underline and quiet footer counters. Preserve overflow menus, sheet ordering and disabled states. Maintain both skin modes.
- [x] Verify drawer actions, metadata/layout changes, narrow widths, skin switches, combat and Global Inventory with regression tests; run the repository suite. Package an alpha for in-game review. Do not install over the live addon without a separate request.

Implementation files: Frames/BagOptions.lua (drawer and chrome), Frames/CategoryHeader.lua (measured header presentation), Frames/View.lua (explicit integration), Frames/ViewList.lua (header geometry), Core/Settings.lua (detail preferences), BagSmith.toc and tests/core_2_0_0_tests.lua.

Review risks: protected item frames in combat; large fonts and long section names; values disappearing after layout switches; orphaned drawer or inaccessible controls at screen edges; profile and bank settings accidentally shared. Visual fidelity requires in-game review; the Lua mock cannot verify rendering.

Ledger: managed worktree tool stalled; isolated local clone used instead, with origin reset to Jeor and upstream pointing to Shweep8. Existing dirty checkout preserved. Existing layout order is retained to minimize behavioral change; independent split-column packing is deferred from this visual alpha.

User decision: new appearance enabled by default. Rollback remains available through /bs v2 off and reload. Review caught and fixed the Travel Mode twin, disabled-count geometry and missing footer paint call. In-game rendering remains to be reviewed.
