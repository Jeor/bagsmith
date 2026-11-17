-- ======== 1.9.0-beta15 (Shweep, 17 Nov) ========
-- Blank bags after a reload in Classic (beta14, Shweep's /bs debug logs): the list area opened "0x0 stale" in both
-- styles; Modern recovered on a resize, Classic never did, as the safety net placed it again in the very same spot,
-- which the client ignores. Now what the list hangs from is anchored again too, and the list goes 1 px off and back.
-- The mock models the client here: a stale list area is placed only once its anchors end up different.
for _, skin in ipairs({ "classic", "modern" }) do
	local S = skin .. ": "
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, view = "icons" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	ToggleAllBags(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local sf = V.scroll
	local function sig()
		local t = {}
		for _, p in ipairs(sf.points or {}) do t[#t + 1] = table.concat({ tostring(p[1]), tostring(p[2]), tostring(p[3]), tostring(p[4]), tostring(p[5]) }, ",") end
		return table.concat(t, ";")
	end
	-- the client: stale until a placement leaves the anchors different from what they were when it went stale
	local stale, staleSig = true, sig()
	sf.IsRectValid = function() return not stale end
	local place = V.PlaceScroll
	V.PlaceScroll = function(self, ...)
		place(self, ...)
		if stale and sig() ~= staleSig then stale = false end
	end
	-- the old safety net: the same spot again
	V:PlaceScroll()
	check(stale, S .. "(the model) placing it again in the same spot leaves it stale, as the client did")
	-- the debug line names what the list hangs from
	local lines = {}
	n.db.debug = true
	local oldDebug = n.Debug
	n.Debug = function(_, fmt, ...) lines[#lines + 1] = fmt:format(...) end
	V:EnsureListPlaced(1)
	check(not stale, S .. "the safety net now places it: a real change")
	local said = table.concat(lines, " | ")
	check(said:find("header ", 1, true) and said:find("footer ", 1, true) and said:find("tabs ", 1, true), S .. "the log line says how the header, footer and tabs stand: " .. said)
	check(V.placeNudge == 1, S .. "1 px off for now")
	M.runTimers(); M.runTimers()
	check(V.placeNudge == nil and sig() == staleSig, S .. "and back where it belongs on the next frame")
	-- a placed list area costs a look, nothing more
	local before = sig()
	lines = {}
	V:EnsureListPlaced(2)
	said = table.concat(lines, " | ")
	check(not said:find("unplaced", 1, true) and said:find("placed", 1, true) and sig() == before, S .. "once placed, the checks leave it alone (and say so once): " .. said)
	n.Debug = oldDebug; n.db.debug = false
	check((n.errors or 0) == 0, S .. "no errors")
end
