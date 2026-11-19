-- ======== 1.9.0-beta16 (Shweep, 17 Nov) ========
-- "Closing Global Inventory has the same problem now, seems to only impact classic", "and anywhere else this is
-- needed?": the list area's checks (View:EnsureListPlaced) ran only on opening. Now also after Global Inventory is
-- entered or left, a size applied with the window open, a skin switch, Travel Mode on or off, and List/Icons.
-- The mock models the client as in beta15's set: after each change the list area is left stale, and only placed once
-- a placement leaves its anchors different.
local function boot(skin, prof)
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local p = { skin = skin, view = "icons", sizeMode = "fixed", fixW = 620, fixH = 560 }
	for k, v in pairs(prof or {}) do p[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = p } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	ToggleAllBags(); M.runTimers(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local sf = V.scroll
	local model = { stale = false }
	local function sig()
		local t = {}
		for _, q in ipairs(sf.points or {}) do t[#t + 1] = table.concat({ tostring(q[1]), tostring(q[2]), tostring(q[3]), tostring(q[4]), tostring(q[5]) }, ",") end
		return table.concat(t, ";")
	end
	sf.IsRectValid = function() return not model.stale end
	local place = V.PlaceScroll
	V.PlaceScroll = function(self, ...)
		place(self, ...)
		if model.stale and sig() ~= model.sig then model.stale = false end
	end
	-- the client leaves the list stale after a change (before any timer runs): is it placed again afterwards?
	function model.after(what, change)
		change()
		model.stale, model.sig = true, sig()
		for _ = 1, 6 do M.runTimers() end
		return not model.stale
	end
	return n, M, V, model
end

for _, skin in ipairs({ "classic", "modern" }) do
	local S = skin .. ": "
	local n, M, V, model = boot(skin)
	local function globe() V.btnGlobal:GetScript("OnClick")(V.btnGlobal) end
	check(model.after("enter", globe), S .. "entering Global Inventory: the list is placed again")
	check(model.after("leave", globe), S .. "leaving it: the same (Shweep's report)")
	n:Set("globalResize", false); M.runTimers()
	check(model.after("enter, no resize", globe), S .. "entering it without its own size: the same")
	check(model.after("leave, no resize", globe), S .. "and leaving")
	n:Set("globalResize", true); M.runTimers()
	check(model.after("size", function() n:Set("fixW", 700) end), S .. "a new size from Settings, window open: the same")
	check(model.after("view", function() V:SetPref("view", "list"); n:RefreshViews(true) end), S .. "Icons to List: the same")
	check(model.after("view back", function() V:SetPref("view", "icons"); n:RefreshViews(true) end), S .. "and back")
	check(model.after("travel", function() n:Set("travelMode", true) end), S .. "Travel Mode on: the same")
	check(model.after("travel off", function() n:Set("travelMode", false) end), S .. "and off")
	check(model.after("skin", function() n:Set("skin", skin == "classic" and "modern" or "classic") end), S .. "switching look with the window open: the same")
	check((n.errors or 0) == 0, S .. "no errors")
end
