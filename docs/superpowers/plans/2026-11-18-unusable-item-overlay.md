# Unusable Item Overlay Implementation Plan

> Execute in this session using superpowers:executing-plans.

**Goal:** Show a switchable translucent red wash for unmet character requirements.
**Architecture:** A small Usability module reads requirement evidence and decorates shared item buttons. Buttons own fill/blank integration; settings own the profile toggle.
**Tech Stack:** Lua, WoW Forever APIs, existing Lua 5.1 mock suite through Python/lupa.
**Spec:** ../specs/2026-11-18-unusable-item-overlay-design.md

## Constraints and review focus

Use upstream dev ef451347 (1.9.1). Default on, 25% red opacity, current character only. Unknown data stays unmarked. Keep overlays below labels and borders; class portrait rows never receive item overlays. No per-frame scanning. No generic false IsUsableItem predicate. Verify missing APIs, localized requirements, delayed item info, pooled-button reuse, and progression events.

## Task 1: Detect and display unmet requirements

- [x] Add tests/core_unusable_overlay_tests.lua covering minimum level on equipment/recipes/consumables; red localized class/skill/proficiency lines; ordinary materials; cooldown and already-known text; missing and throwing APIs; disabled setting; reuse and blanking; both skins and row/cell modes; cached items; class portraits; character progression.
- [x] Run `python tools/run_tests.py tests/core_unusable_overlay_tests.lua` and observe expected missing-feature failures.
- [x] Create Core/Usability.lua with `IsUnusable(rec)`, `Decorate(button, rec)`, and `Invalidate()` methods. Use required level plus explicit red requirement lines from C_TooltipInfo, with hidden GameTooltip fallback where necessary. Cache only conclusive results for the session, invalidate on item/progression events, and never cache unknowns.
- [x] Load the module before Core/Buttons.lua. Integrate decoration at the end of Fill and clearing in Blank. Add default `unusableOverlay = true` and the Item Icons checkbox.
- [x] Run focused tests until green; add the suite to tools/run_tests.py.

## Task 2: Verify and package

- [x] Run the full suite and compare any failures with the unchanged baseline.
- [x] Review all changes, including overlay geometry and event refresh. Record remaining game-only checks.
- [x] Package the addon as a local test ZIP, with a concise test guide and change summary. Do not install or publish without an instruction to do so.

## Execution ledger

- Approved design; executing natively under the user's proceed instruction.
- Native worktree completed at C:/Users/geoff/.codex/worktrees/unusable-item-overlay/bagsmith. Branch feat/unusable-item-overlay belongs to the Jeor repository; origin remains https://github.com/Jeor/bagsmith.git. Draft tests and docs were transferred from the temporary snapshot before addon implementation.
- Unchanged dev baseline full suite passed.
- Initial regression run: 4 expected failures (missing setting/module). Final focused suite: 106 checks passed, including secure buttons, legacy fallback, both skins and both views.
- Review found a partial-tooltip cache bug. Added a failing regression, then fixed it by refusing to cache header-only/unreadable negatives and listening for tooltip data updates.
- Verified original Blizzard global strings: ITEM_MIN_SKILL is the ranked requirement; ITEM_REQ_SKILL is generic. Rankless skill restrictions require typed tooltip evidence, rather than treating every red "Requires ..." line as a permanent character restriction.
- No product changes in the old checkout or 2.0 alpha. Package only; game installation and in-game verification are separate.
- The first full feature run exposed core_modern_crop_tests.lua loading Buttons.lua alone. Added the same optional-decorator guard used by other button features; that regression and all 106 feature checks pass. The final full run includes this fix before reaching that test.

- Final full run: 230 test sets passed, including 106 feature assertions; runner reported ALL OK. ZIP byte comparison verified all 138 addon files match the current source. In-game validation remains outstanding.
