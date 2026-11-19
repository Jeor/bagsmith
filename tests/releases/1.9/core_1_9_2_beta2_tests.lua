-- ======== 1.9.2-beta2 (Shweep, 18 Nov) ========
-- "default should be 35% opacity": Unusable Item Opacity starts at 35% (was 50%). A save that already holds a value
-- keeps it (Shweep: "leave it"): only beta1's testers have one, and they set it by hand.

local function boot(profile, tip)
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 10001, name = "Armor 1", q = 2, count = 1, class = 4, subclass = 1, type = "Armor", sub = "Cloth", price = 10 })
	M.put(0, 2, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = profile or { view = "icons" } } }
	_G.C_TooltipInfo = tip and { GetHyperlink = tip } or nil
	_G.ITEM_MIN_LEVEL = "Requires Level %d"   -- the game's (the mock has none)
	local n = M.loadAddon("BagSmith")
	n.version = "1.9.2-beta2"
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	return n, M
end
-- the armor piece needs level 60
local function tip(link)
	local id = tonumber(tostring(link):match("item:(%d+)"))
	local lines = { { leftText = "Armor " .. tostring(id) }, { leftText = "Cloth" } }
	if id == 10001 then lines[#lines + 1] = { leftText = ITEM_MIN_LEVEL:format(60), leftColor = { r = 1, g = 0.1, b = 0.1 } } end
	return { lines = lines }
end
local function tint(n)
	local t
	n.Buttons:EachLive(function(b) if b.hasItem and b.rec and b.rec.itemID == 10001 then t = b.unusableOverlay end end)
	return t
end

;(function()
	-- a new player, or one coming from 1.9.1 (no value saved): 35%
	local n, M = boot(nil, tip)
	check(n.db.unusableOverlayOpacity == 0.35, "Unusable Item Opacity starts at 35%")
	check(BagSmithDB.profiles.Default.unusableOverlayOpacity == 0.35, "and is saved as 35%")
	n.Window:Show(); M.runTimers(); M.runTimers()
	local t = tint(n)
	check(t and t:IsShown() and t.color and math.abs(t.color[4] - 0.35) < 1e-6, "the red tint drawn at 35% (" .. tostring(t and t.color and t.color[4]) .. ")")
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("icons"); M.runTimers()
	local s
	for _, w in ipairs(P.pools.step) do if w:IsShown() and w.key == "unusableOverlayOpacity" then s = w end end
	check(s and s.value:GetText() == "35", "Settings shows 35 (%)")
	P:Hide()
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- beta1's testers: 50% already saved, kept
	local n, M = boot({ view = "icons", unusableOverlayOpacity = 0.5 }, tip)
	check(n.db.unusableOverlayOpacity == 0.5, "a save holding 50% keeps it (set by hand to change)")
	n.Window:Show(); M.runTimers(); M.runTimers()
	local t = tint(n)
	check(t and t:IsShown() and math.abs(t.color[4] - 0.5) < 1e-6, "and draws at 50%")
	n:Set("unusableOverlayOpacity", 0.35); M.runTimers()
	check(math.abs(t.color[4] - 0.35) < 1e-6 and BagSmithDB.profiles.Default.unusableOverlayOpacity == 0.35, "set to 35%: drawn and saved at 35%")
	check((n.errors or 0) == 0, "no errors")
end)()
