# Unusable Item Overlay test build

Based on upstream dev ef4513473c2280cbba9f0d246db02b19b6182151 (1.9.1), in Jeor/bagsmith branch feat/unusable-item-overlay. This is the standard BagSmith addon, not BagSmithTest or the separate 2.0 alpha.

## Behavior

Settings > Item Icons > Appearance > Unusable Item Overlay is enabled by default. It adds a 25% red wash to equipment, recipes, and consumables with a confirmed unmet character requirement. Borders, counts, item levels, and corner marks stay above it. The setting applies immediately and follows the current profile.

Checks always refer to the logged-in character, including saved inventory from other characters. Global Inventory's character portraits are never marked. Ordinary materials, cooldowns, temporary targeting/resource/combat restrictions, and already-known recipes are not marked solely for those reasons.

The detector uses required level and explicit red requirement lines, including typed skill restrictions and localized rank/class/reputation text. Unknown data stays unmarked and is retried. On clients without typed tooltip data, ambiguous rankless "Requires ..." lines stay unmarked rather than guessing what they mean.

## In-game verification

1. Back up the installed BagSmith folder before trying this package. Extract its BagSmith folder into Interface/AddOns and reload the UI.
2. Compare an equippable item with one above your level, a weapon/armor type you cannot equip, a recipe for an unavailable profession or rank, and a consumable requiring a higher level or skill.
3. Check List and Icons views with both Modern and Classic skins. Red should cover only the picture; quality borders, counts and corner marks should remain readable. Repeat with small and large icons.
4. Disable and reenable Unusable Item Overlay. Visible overlays should disappear and return without a reload. Try changing the setting during combat.
5. Move or consume a marked item, then put an ordinary material in its old slot. No red should remain on the empty or reused slot.
6. Learn the relevant skill or gain the required level. The overlay should clear. Check a cooldown, full-health consumable, and an already-known recipe: these conditions alone should not trigger red.
7. Check a bank item, a Recent copy, and saved inventory. The answer should always be for the logged-in character.

Mock tests exercise the rendering calls and client responses. They do not establish pixel appearance or actual requirement information returned by the WoW Forever client.

## API references

- [Blizzard tooltip type definitions, Classic source mirror](https://github.com/Gethe/wow-ui-source/blob/e51aa0038c8db50f01e0aa940047fe84dcbf92dd/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua): named RestrictedSkill, RestrictedLevel, and related line types.
- Localized requirement templates come from the client's own global strings, rather than English-only text matching.
