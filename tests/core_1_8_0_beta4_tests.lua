;(function()
	-- ======== 1.8.0-beta4: a material's name once the game has loaded it (Shweep's screenshot) ========
	-- The Disenchant Helper showed "item 10978" under Likely results (Small Glimmering Shard, the game hadn't loaded it
	-- yet) and never painted again. Now the item's data is asked for, and when it arrives (GET_ITEM_INFO_RECEIVED) the
	-- open Helper and its Exclusion List paint again with the name.
	package.loaded.mock = nil
	local M = require("mock")
	local DEID = 13262
	M.put(0, 1, { id = 7001, name = "Sturdy Boots", q = 2, count = 1, class = 4, subclass = 1, price = 452, ilvl = 23, equip = "INVTYPE_FEET" })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern", deEnabled = true } } }
	_G.IsSpellKnown = function(id) return id == DEID end
	_G.RegisterStateDriver = function() end
	_G.UnregisterStateDriver = function() end
	_G.ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.12, g = 1, b = 0 }, [3] = { r = 0, g = 0.44, b = 0.87 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
	-- Strange Dust is loaded; the essence and the shard aren't, until the test says so
	local loaded = { [10940] = { "Strange Dust", 1 } }
	local requested = {}
	local realInfo = C_Item.GetItemInfo
	C_Item.GetItemInfo = function(link)
		local id = tonumber(tostring(link):match("item:(%d+)")) or link
		if loaded[id] then return loaded[id][1], "item:" .. id, loaded[id][2] end
		if id == 10939 or id == 10978 or id == 20725 then return nil end
		return realInfo(link)
	end
	C_Item.RequestLoadItemDataByID = function(id) requested[id] = (requested[id] or 0) + 1 end
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local DE = n.Disenchant
	DE:Show(); M.runTimers()
	local f = DE.frame
	local function rows()
		local out = {}
		for _, r in ipairs(f.cur.likelyRows or {}) do if r:IsShown() then out[r.id] = r end end
		return out
	end
	local shard = rows()[10978]
	check(shard and shard.name.text == "item 10978", "(setup) the shard isn't loaded yet: \"item 10978\", as in the screenshot")
	check(requested[10978] == 1 and requested[10939] == 1, "its data is asked for (once each): " .. tostring(requested[10978]) .. ", " .. tostring(requested[10939]))
	DE:Refresh(); M.runTimers()
	check(requested[10978] == 1, "and not again on the next paint: " .. tostring(requested[10978]))

	-- the game loads the shard: the open Helper paints again with its name
	loaded[10978] = { "Small Glimmering Shard", 3 }
	M.fire("GET_ITEM_INFO_RECEIVED", 10978, true); M.runTimers(); M.runTimers()
	shard = rows()[10978]
	check(shard and shard.name.text == "Small Glimmering Shard", "once it's loaded the row shows its name: " .. tostring(shard and shard.name.text))
	check(shard and shard.c[3] == 0.87, "in its rarity color")
	check(rows()[10939].name.text == "item 10939", "the essence still waits for its own data")
	loaded[10939] = { "Greater Magic Essence", 2 }
	M.fire("GET_ITEM_INFO_RECEIVED", 10939, true); M.runTimers(); M.runTimers()
	check(rows()[10939].name.text == "Greater Magic Essence", "then it shows too")

	-- an item that isn't one BagSmith waited for doesn't repaint anything
	local paints = 0
	local origRefresh = DE.Refresh
	DE.Refresh = function(self, ...) paints = paints + 1; return origRefresh(self, ...) end
	M.fire("GET_ITEM_INFO_RECEIVED", 2589, true); M.runTimers(); M.runTimers()
	check(paints == 0, "another item's data arriving changes nothing: " .. paints)
	-- nor does data arriving with the Helper closed (the name is read fresh when it next opens)
	DE.NoteMissingName(20725); f:Hide()
	M.fire("GET_ITEM_INFO_RECEIVED", 20725, true); M.runTimers(); M.runTimers()
	check(paints == 0, "with the Helper closed, nothing paints: " .. paints)
	DE.Refresh = origRefresh

	-- the Exclusion List: an excluded item still loading reads "Item <id>", then its name
	f:Show()
	local function entry(id) for _, e in ipairs(DE:NeverList()) do if e.id == id then return e end end end
	DE:Never()[20725] = true
	DE:ManageNever(); M.runTimers()
	-- (asked for a second time: the first wait ended when its data came while the Helper was closed, above)
	check(entry(20725) and entry(20725).name == "Item 20725" and requested[20725] == 2 and DE.waitingNames[20725], "an excluded item not loaded yet: \"Item 20725\", its data asked for: " .. tostring(entry(20725) and entry(20725).name) .. ", " .. tostring(requested[20725]))
	local refreshed = 0
	local origNever = DE.RefreshNeverWindow
	DE.RefreshNeverWindow = function(self, ...) refreshed = refreshed + 1; return origNever(self, ...) end
	loaded[20725] = { "Nexus Crystal", 4 }
	M.fire("GET_ITEM_INFO_RECEIVED", 20725, true); M.runTimers(); M.runTimers()
	check(refreshed == 1 and entry(20725).name == "Nexus Crystal", "once loaded, the open Exclusion List paints its name")
	DE.RefreshNeverWindow = origNever
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- (1.7.5 in 1.8.0) the List view's wheel notch is two rows as tall as Text Size makes them
	package.loaded.mock = nil
	local M = require("mock")
	for s = 1, 16 do M.put(0, s, { id = 7000 + s, name = "Item" .. s, q = 1, count = 1, class = 0, subclass = 5, price = 1 }) end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local view = n.Window.main
	view:SetPref("view", "list"); n:RefreshViews(true); M.runTimers()
	check(view.wheelStep == n.db.rowHeight * 2, "at 100%: two rows of the Row Height: " .. tostring(view.wheelStep))
	n:Set("rowHeight", 20); n:Set("textScale", 1.5); M.runTimers(); n:RefreshViews(true); M.runTimers()   -- (short rows, big text)
	local need = n.Fonts:RowNeed()
	check(need > n.db.rowHeight and view.wheelStep == need * 2, "at 150% the rows grow, and the notch with them: " .. tostring(view.wheelStep) .. " (rows " .. need .. ")")
end)()
