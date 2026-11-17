# BagSmith 2.0 workshop

Interactive, static browser counterpart to the 2.0 alpha UI. This is a visual iteration tool, not a WoW/Lua emulator. No addon or saved-variable data is uploaded. Sample prices and character data are fictional.

## Iterate

From the repository root run `python -m http.server 8000 --directory docs`, then open `http://localhost:8000/demo/`. Edit `demo/style.css` for visual tokens and layout, `demo/app.js` for controls, and `demo/data.js` for fixtures. Refresh to see changes. No build or dependency install is needed.

GitHub Pages serves `/docs` on `feat/bagsmith-2.0`; pushes update the public demo. The root redirects to `/demo/`. Local assets keep item icons and fonts independent of third-party availability at runtime.

Use the bag button (or B) to toggle the drawer. Test Standard, Compact, Split, Icons/List, grouping, sorting, merged stacks, category count/vendor/AH values, search, quality filtering, collapse, tabs, tooltip focus, and resizing. Appearance settings adjust icon size, spacing, opacity, height, and skin. The top controls switch fixture scenarios, reset state, and copy a URL containing appearance state. Character, inventory preset, and rarity filter are included in shared URLs. Search, transient selection and collapsed categories are intentionally not included.

Small screens use an overlay drawer and a single column. Desktop is the fidelity target. Gear/Bank tools switch sample views; currency/global dialogs are illustrative, and Travel Mode tucks the drawer away. These do not simulate secure WoW actions, live auctions, combat restrictions, or actual inventory operations.

## Assets

Toolbar artwork and OFL fonts are reused from this repository; font license texts accompany the copies. Item artwork uses Blizzard game icons retrieved from Wowhead's public icon CDN. Game artwork remains the property of its respective owners; this is an unofficial addon design preview. `asset-sources.json` records the source URLs. No screenshots or account SavedVariables are published.

Run model checks with `node --test docs/demo/model.test.mjs`.


## Inventory fixtures

The character picker now selects four independent inventories: Hex Loothur (warlock), Elowen (druid/herbalist), Brom Ironhand (warrior/blacksmith), and Mira Goldleaf (banker/collector). Character Bags contains 60+ curated sample items for each; Full Bags fills that character’s capacity before stack merging. Their money and capacities differ too.

The Inventory dropdown also offers Original Sample, All Rarities, Stack Stress Test, Long Categories, and Empty Bags. The independent Rarity dropdown filters Poor, Common, Uncommon, Rare, Epic, Legendary, Artifact, Heirloom, or Token. Artifact/heirloom/token entries are explicit visual test fixtures, including types that may not exist in the target game version. Stack Stress Test includes counts of 1, 20, 200, 999 and 1,000; merging exposes four-digit totals. Switch characters to return to their Character Bags preset. Character/scenario changes clear search and category selection, while preserving appearance and the selected rarity filter.

Edit `fixtures.js` to extend these collections. Item names and artwork evoke game items; quantities, quality assignments and prices are synthetic and are not authoritative game data.
