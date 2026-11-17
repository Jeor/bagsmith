# Browser verification

Reference: `../v2/approved-mockup.png`, the user's in-game alpha screenshots, and alpha2 BagOptions/CategoryHeader modules. The existing accepted design is reused rather than generating a different concept.

Checked at 1518 × 900 (the supplied screenshot width) and 390 × 844. The original approved image is a 1774 × 887 two-panel comparison, while this deliverable is one interactive, resizable panel; the native comparison canvas is not reproduced. Local Playwright Chromium was used after the in-app browser timed out reaching the sandbox-local server.

Five model tests passed. Browser checks covered asset loading, Compact/Split, list rows, vendor/AH toggles, composed search, no results, collapsing/expanding, appearance sliders, full/empty scenarios, close/reopen, and mobile overflow. No browser exceptions were observed. Final screenshots were inspected against the approved reference with the image viewer.

## Fidelity review

| Area | Reference and implementation | Resolution |
| --- | --- | --- |
| Frame and palette | Warm charcoal panel, ivory copy, muted gold borders | Reused the addon palette and thin frame treatment; no marketing content inside the bag |
| Typography | Serif controls and condensed category titles in current alpha | Reused Marcellus and Roboto Condensed from addon assets |
| Drawer | Attached left, grouped choices, tools below, pinned settings | Checkbox rows and dropdowns follow alpha2; overflow scrolls independently |
| Category headers | Title/count, fine divider, optional values | Wraps metadata and aligns headers within each row; removed an unnecessarily tall fixed header |
| Items | Square game art with quality borders and corner quantities | Local game icons; fixture inventory intentionally differs from the user's saved inventory |
| Tabs/footer | Underlined active tab, quiet money and capacity | Preserved; no boxed footer buttons |
| Responsive | Desktop addon is the fidelity target | Intentional mobile overlay drawer and one-column layout; no page overflow |
| Copy | Core bag controls follow alpha2 | Intentional outside-frame workshop controls and simulation disclosure; sample tool dialogs explicitly labeled |

Fixed during QA: hidden ResizeObserver notifications incorrectly saved zero dimensions and shortened the reopened bag. Zero-size observations are now ignored. This is a faithful browser interpretation of the approved visual direction, not pixel-identical WoW rendering or a secure-inventory emulator. Classic skin is an approximation. Native browser select/checkbox controls are intentional for keyboard accessibility.


## Character and rarity expansion

Ten model checks pass, including distinct 60+ item inventories, exact full-bag capacities, all nine quality codes, rarity filtering, stack-quantity preservation, and share-state validation. Browser checks covered all four character selections, every rarity filter, all downloaded image assets, share-link restoration in a new tab, large-stack merging, and 1518 × 900 / 390 × 844 layouts, without page exceptions. Screenshots of the expanded character and rarity views were inspected with the image viewer. Intentional additions: inventory and rarity selectors outside the bag, more fixture characters in the existing picker, and all rarity border/text colors. Existing frame, category-header, drawer, typography, tabs, and footer styling are preserved.


## Currency and font checks

Model tests cover both drawer-opening orders, sanitizing shared pin IDs, and distinct character balances. Chromium verified currency search, pin/unpin footer controls, the gold shortcut, both dismissal directions, all nine font loads, independent header/body font changes, and restoration of open currencies plus font choices in a shared URL. Desktop and mobile screenshots were inspected. The currency panel follows the existing frame and divider styling, and mobile uses the same overlay treatment as Bag Options. Added font selectors and the live sample are intentional extensions of Appearance settings.
