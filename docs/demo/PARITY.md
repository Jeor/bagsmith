# Visible control parity

Scope agreed: visible controls and layouts using sample inventory. Game-only item movement, selling, equip actions, combat protection and service connections are outside this pass.

| Control | Browser behavior |
| --- | --- |
| Bag button / Currencies / gold / pinned currencies | Open the corresponding drawer; options and currencies dismiss one another. Close actions leave both closed. |
| Fonts & Appearance / All Settings | Same appearance dialog, nine bundled fonts, independent headings, live preview, skin, size, spacing, opacity and height. Fonts apply to drawer text, tooltip text, quantities and currency amounts. |
| Character / inventory / rarity selectors | Four actual fixture inventories; full, empty, long-name, all-rarity and large-stack scenarios; composed rarity filtering. |
| Layout / View | Standard, Compact, Split and Icons/List; metadata wrapping and row alignment; responsive single-column mobile. |
| Grouping | All Items, By Section, By Bag; By Bag disabled for Global Inventory. |
| Sorting | Quality, Name, Item Level, Newest, Oldest, Off. Fixture item levels and ages are synthetic. |
| Merge Stacks / Clean Up | Merge totals without losing quantity; cleanup selects quality sorting. |
| Category details / collapse | Independent count, vendor and auction fields; individual and all-section collapse. |
| Filter / search | Filter panel with rarity/category controls and clear action; search composes with filters and tabs. |
| Gear Sets | Gear Sets tab with dungeon/raid/all set selection on the selected character's fixture gear. No pretend equip operation. |
| Bank | Bank view and title using that character's sample bank subset. |
| Global Inventory | Aggregates all four inventories, gold and wallet currencies; item tooltips show owner quantities. Back to Character restores the single-owner view. |
| Travel Mode | Compact window, hidden tabs and Recent section, visible exit control; returns to prior dimensions. |
| Currency drawer | Per-character/global sample amounts, search, pin/unpin, pin order, track/remove inventory items, footer shortcuts. |
| Reset / Copy View Link | Reset clears transient filters and scroll; links initialize once so later edits survive refresh. Appearance, fixture, drawer and pin state are shared. |
| Refresh Demo | Cache-busting page refresh preserving preferences; release badge and update notice identify the loaded build. |

Intentional visual differences: native web select/checkbox behavior, mobile overlay drawers, synthetic inventory and values, and approximate Classic skin. The browser remains a presentation/interaction test environment, not the addon executing in WoW.

## Regression checks

`node --test docs/demo/model.test.mjs` covers data and state transitions. `browser.test.cjs` covers visible controls, both drawer orders, old shared-link initialization followed by font/drawer changes and refresh, font loading, tracking/reordering currencies, filters, six sort modes, global/gear/bank/travel views and mobile overflow. Set DEMO_URL to run it against a served local build or the public Pages URL.

The reported font change was reproduced as Inter before refresh reverting to Marcellus after refresh when an older shared hash remained in the URL. It stays Inter after the fix. Currency opened correctly on the inspected live page; the original reported click failure was not reproduced. Versioned modules and the update notice prevent mixed-release assets and make stale-page diagnosis explicit.
