;(function()
	-- ======== 1.8.0-beta17 (Shweep's /bs debug on Forever: the loot source is the disenchanted item's own GUID) ========
	-- A loot slot is the cast's only when every source is exactly the item disenchanted; with no GUID known, every source
	-- must still be an item. And the template report never lists a mask (it never draws by itself).
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith")
	local DE = n.Disenchant
	local OWN = "Item-6796-0-40000000257B6C17"   -- (Shweep's log)
	DE.castOpen = { entry = { rec = { guid = OWN } } }
	_G.GetLootSourceInfo = function() return OWN, 3 end
	check(DE.SlotIsCast(1) == true, "the source is the disenchanted item: the cast's")
	_G.GetLootSourceInfo = function() return "Item-6796-0-4000000099999999", 3 end
	check(DE.SlotIsCast(1) == false, "another item: not the cast's (an item's loot can't teach)")
	_G.GetLootSourceInfo = function() return OWN, 2, "Item-6796-0-4000000099999999", 1 end
	check(DE.SlotIsCast(1) == false, "the item and another item: not the cast's")
	_G.GetLootSourceInfo = function() return OWN, 2, OWN, 1 end
	check(DE.SlotIsCast(1) == true, "the item listed twice: still the cast's")
	DE.castOpen = { entry = { rec = {} } }
	_G.GetLootSourceInfo = function() return "Item-1", 1 end
	check(DE.SlotIsCast(1) == true, "no GUID known for the item: any item source, as before")
	_G.GetLootSourceInfo = function() return "Creature-0-1-2-3-4-5", 1 end
	check(DE.SlotIsCast(1) == false, "and never a creature")
	DE.castOpen = nil; _G.GetLootSourceInfo = nil

	-- the template report skips masks
	local b = CreateFrame("Button")
	local mask = { IsShown = function() return true end, GetAlpha = function() return 1 end, GetObjectType = function() return "MaskTexture" end, GetTexture = function() return 2922105 end }
	local stray = { IsShown = function() return true end, GetAlpha = function() return 1 end, GetObjectType = function() return "Texture" end, GetTexture = function() return "Interface\\Stray" end }
	b.GetRegions = function() return mask, stray end
	b.Mask, b.Stray = mask, stray
	local out = n.Buttons:TemplateLeftovers(b)
	local text = table.concat(out, " | ")
	check(#out == 1 and text:find("Stray") and not text:find("Mask"), "a mask isn't reported; real leftover art still is: " .. text)
end)()
