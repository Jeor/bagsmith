# Unusable Item Overlay

Status: approved by the user; implementation on Jeor/bagsmith branch feat/unusable-item-overlay.

## Intent and base

Make items the current character cannot equip, learn, or use easy to spot. Use upstream Shweep8/bagsmith dev, verified on 2026-11-18 at ef4513473c2280cbba9f0d246db02b19b6182151 (1.9.1), and recheck the head before implementation. The separate 2.0 alpha is outside this change.

## Approaches

- Recolor the icon: simpler, but changes the original artwork colors more strongly.
- Translucent red overlay: a separate wash over the artwork preserves its identity and allows borders and labels to remain readable. The user selected this approach.

## Behavior

- Cover equipment, recipes, and consumables whose character requirements are unmet, including level, class, proficiency, and profession requirements.
- Add Unusable Item Overlay under Item Icons, enabled by default as proposed. Toggling it immediately updates visible items without a reload.
- Use an icon-sized red wash, initially approximately 25% opacity, in list and grid views and both Modern and Classic skins. Keep quality borders, counts, item levels, and corner markers legible above or outside the wash.
- Evaluate against the logged-in character, including items shown from bank or other-character inventory. This is a proposed default; never imply a reliable assessment of an offline character.
- Ordinary materials and junk do not acquire the overlay simply because they lack a use action. Cooldowns, combat restrictions, missing targets, full health, and temporary resource shortages do not count as unmet character requirements.
- Already-known recipes are outside the initial unmet-requirements rule; do not flag them solely for being known.
- Missing or inconclusive item data leaves the icon unmarked and eligible for reevaluation when data arrives.

## Implementation constraints

Use the shared item-button rendering path, with explicit clearing when a button is emptied or reused. Keep detection separate from rendering and avoid per-frame tooltip scans. Reevaluate after item data arrives and relevant character level, skill, or spell changes. Do not store a character-specific result globally by item ID.

The current classifier supplies item classes, and the scanner already records required level. Verify the WoW Forever client's usability and tooltip APIs during implementation; a generic false usability result alone is insufficient to distinguish unmet requirements from temporary restrictions. Prefer explicit requirement evidence, using localized game data rather than English-only tooltip matching. Exact detection and cache details remain implementation decisions, subject to these constraints.

## Verification

Test equipment, recipes, and consumables with unmet and satisfied requirements; unknown data; ignored temporary restrictions; setting changes; character progression; and reused/empty buttons. Run the repository checks. Review list/grid and Modern/Classic visuals, and verify actual requirement detection in game before describing the feature as game-validated.

## Scope

A small feature with one toggle and one visual treatment. No opacity slider, new filtering, automatic item actions, or changes to click behavior. Initial opacity can be tuned during visual review.
