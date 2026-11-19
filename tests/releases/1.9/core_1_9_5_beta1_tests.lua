-- ======== 1.9.5-beta1 (Shweep, 19 Nov) ========
-- Shweep's optimization review ("i'm open to as much as this as we want to do"): in game, opening Global Inventory and
-- searching cost a 53 ms frame. (A) Global Inventory keeps its built list until something it's made of changes; (D)
-- the custom-currency list is rebuilt only when a tracked item's data arrives; (C) the textures are stored compressed
-- (Shweep's test in game: a compressed TGA draws the same), the two 256 px ones are 128 px, minimap128.tga is gone.

local TGA = dofile("tests/tga.lua")

local function boot(extraCache, prof)
	package.loaded.mock = nil
	local M = require("mock")
	M.sizes[1], M.sizes[2] = 16, 16
	for s = 1, 30 do M.put(math.floor((s - 1) / 16), ((s - 1) % 16) + 1, { id = 90000 + (s % 20), name = "Item " .. (s % 20), q = 1 + s % 3, count = 1 + s % 4, class = s % 2 == 0 and 7 or 4, subclass = 0, price = 10 + s }) end
	local cache = {}
	for c = 1, 2 do
		local items = {}
		for i = 1, 25 do items[#items + 1] = { bag = 0, slot = i, itemID = 90000 + (i % 20) + (i > 20 and 3000 + c * 10 + i or 0), count = 2, name = "Item " .. (i % 20), quality = 2, classID = 7 } end
		cache["Alt" .. c .. " - Forever"] = { name = "Alt" .. c, realm = "Forever", class = "MAGE", level = 30, items = items, bank = { { bag = -1, slot = 1, itemID = 97000 + c, count = 3, name = "Banked " .. c, quality = 1, classID = 7 } }, equipped = {} }
	end
	cache["Faraway - Elsewhere"] = { name = "Faraway", realm = "Elsewhere", class = "ROGUE", level = 20, items = { { bag = 0, slot = 1, itemID = 98001, count = 1, name = "Far Thing", quality = 1, classID = 7 } }, bank = {}, equipped = {} }
	for k, v in pairs(extraCache or {}) do cache[k] = v end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local p = { view = "list", grp = "type" }
	for k, v in pairs(prof or {}) do p[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = cache, profiles = { Default = p } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	return n, M, n.Window.main
end
local function find(list, id) for _, r in ipairs(list) do if r.itemID == id then return r end end end

;(function()
	-- A: built once, kept
	local n, M, V = boot()
	local Inv = n.Inventory
	local b0 = Inv.builds
	V:SetGlobal(true); M.runTimers(); M.runTimers()
	check(Inv.builds == b0 + 1, "opening Global Inventory builds the list once (" .. (Inv.builds - b0) .. ")")
	local b1 = Inv.builds
	for _, q in ipairs({ "i", "it", "ite", "item", "item 1" }) do V.st.filters.text = q; n:RefreshViews(); M.runTimers() end
	V.st.filters.text = ""; n:RefreshViews(); M.runTimers()
	check(Inv.builds == b1, "searching (six redraws): not rebuilt")
	local lane
	for _, h in ipairs(V.used or {}) do if h.laneId and h:IsShown() then lane = h.laneId; break end end
	V:ToggleLane(lane); M.runTimers(); V:ToggleLane(lane); M.runTimers()
	check(Inv.builds == b1, "collapsing and opening a section: not rebuilt")
	V:SetGlobal(false); M.runTimers(); V:SetGlobal(true); M.runTimers(); M.runTimers()
	check(Inv.builds == b1, "closing and reopening it: not rebuilt")
	-- each caller its own list, the same records
	local a, b = Inv:GlobalRecords(false), Inv:GlobalRecords(false)
	check(a ~= b and #a == #b and a[1] == b[1], "each caller gets its own list of the same records")
	table.sort(a, function(x, y) return x.itemID > y.itemID end); a[#a] = nil
	local c = Inv:GlobalRecords(false)
	check(#c == #b and c[1] == b[1], "sorting or trimming one doesn't touch the kept list")
	-- the same records a fresh build makes
	local fresh = Inv:BuildGlobalRecords(false)
	local same = #fresh == #c
	for i, r in ipairs(fresh) do
		local k = c[i]
		if not (k and k.itemID == r.itemID and k.count == r.count and k.who == r.who and k.where == r.where and k.cat == r.cat and #(k.globalKids or {}) == #(r.globalKids or {})) then same = false end
	end
	check(same, "the kept list matches a fresh build, record by record (" .. #fresh .. " records)")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- A: rebuilt whenever something it's made of changes, and right
	local n, M, V = boot()
	local Inv = n.Inventory
	V:SetGlobal(true); M.runTimers(); M.runTimers()
	local function rebuiltBy(label, fn, verify)
		local b = Inv.builds
		fn()
		local list = Inv:GlobalRecords(false)
		-- once, or twice when the redraw it causes comes before your data is saved (1.5 s later), which also rebuilds
		check(Inv.builds >= b + 1 and Inv.builds <= b + 2, label .. ": rebuilt (" .. (Inv.builds - b) .. ")")
		if verify then check(verify(list), label .. ": and shows it") end
	end
	rebuiltBy("an item lands in your bags", function() M.put(2, 1, { id = 96001, name = "New Loot", q = 2, count = 4, class = 7, subclass = 0, price = 5 }); M.fire("BAG_UPDATE_DELAYED"); M.runTimers(); M.runTimers() end,
		function(list) local r = find(list, 96001); return r and r.count == 4 end)
	rebuiltBy("a stack changes", function() M.put(2, 1, { id = 96001, name = "New Loot", q = 2, count = 9, class = 7, subclass = 0, price = 5 }); M.fire("BAG_UPDATE_DELAYED"); M.runTimers(); M.runTimers() end,
		function(list) local r = find(list, 96001); return r and r.count == 9 end)
	rebuiltBy("the bank opens", function() M.fire("BANKFRAME_OPENED"); M.runTimers(); M.runTimers() end)
	M.fire("BANKFRAME_CLOSED"); M.runTimers()
	rebuiltBy("what you wear changes", function() M.fire("PLAYER_EQUIPMENT_CHANGED", 1); M.runTimers() end)
	rebuiltBy("a setting changes", function() n:Set("splitCons", not n.db.splitCons); M.runTimers() end)
	rebuiltBy("your data is saved", function() n:SaveCache(); M.runTimers() end)
	rebuiltBy("a new zone", function() M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers() end)
	-- the realm choice and the Bank tab are kept apart
	local mine = Inv:GlobalRecords(false)
	local all = Inv:GlobalRecords(true)
	check(find(all, 98001) and not find(mine, 98001), "Other Rulesets: its own list (Faraway's item only there)")
	local banked = Inv:GlobalRecords(false, { bank = true })
	check(find(banked, 97001) and not find(banked, 96001), "the Bank tab: its own list (banked items only)")
	check(find(Inv:GlobalRecords(false), 96001) and not find(Inv:GlobalRecords(false), 98001), "and asking again gives each its own list back")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- D: the custom-currency list, rebuilt only for a tracked item
	local n, M = boot(nil, { customCurrencies = { 90003 } })
	local C = n.Currency
	local calls = 0
	local orig = C.Invalidate
	C.Invalidate = function(...) calls = calls + 1; return orig(...) end
	for i = 1, 50 do M.fire("GET_ITEM_INFO_RECEIVED", 50000 + i, true) end
	check(calls == 0, "50 other items' data arriving: the currency list left alone (" .. calls .. ")")
	M.fire("GET_ITEM_INFO_RECEIVED", 90003, true)
	check(calls == 1, "the tracked item's data arriving: rebuilt once")
	M.fire("GET_ITEM_INFO_RECEIVED", "90003", true)
	check(calls == 2, "(its ID as text too)")
	C.Invalidate = orig
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- C: the textures
	-- the addon's own files, from its TOC (this Lua has no directory listing), and every texture they name
	local function read(path) local f = io.open(path, "rb"); if not f then return "" end local d = f:read("*a"); f:close(); return d end
	local toc = read("BagSmith/BagSmith.toc")
	local parts = { toc, read("BagSmith/Bindings.xml") }
	for line in toc:gmatch("[^\r\n]+") do if line:match("%.lua%s*$") and not line:match("^#") then parts[#parts + 1] = read("BagSmith/" .. line:gsub("\\", "/"):gsub("%s+$", "")) end end
	local src = table.concat(parts, "\n")
	local files, seen = {}, {}
	for name in src:gmatch("([%w_%-]+)%.tga") do
		if not seen[name] then seen[name] = true; files[#files + 1] = name end
	end
	check(#parts > 40 and #files > 40, "(setup) " .. (#parts - 2) .. " Lua files read, " .. #files .. " textures named")
	local bad, compressed, total, missing = {}, 0, 0, {}
	for _, name in ipairs(files) do
		local f = "BagSmith/Media/" .. name .. ".tga"
		local t, err = TGA.load(f)
		total = total + 1
		if err == "missing" then missing[#missing + 1] = name
		elseif not t then bad[#bad + 1] = f .. " (" .. tostring(err) .. ")"
		elseif t.bpp ~= 32 or t.desc ~= 8 then bad[#bad + 1] = f .. " (format)"
		elseif t.type == 10 then compressed = compressed + 1 end
	end
	check(#missing == 0, "every texture the addon names is on disk" .. (#missing > 0 and (": missing " .. table.concat(missing, ", ")) or ""))
	check(#bad == 0, "each reads whole: 32-bit with alpha, bottom row first" .. (#bad > 0 and (": " .. table.concat(bad, ", ")) or ""))
	check(compressed == total, "all " .. total .. " stored compressed (" .. compressed .. ")")
	for _, f in ipairs({ "icon.tga", "ui-disenchant-large.tga" }) do
		local t = TGA.load("BagSmith/Media/" .. f)
		check(t and t.w == 128 and t.h == 128, f .. ": 128 x 128 (was 256)")
	end
	check(io.open("BagSmith/Media/minimap128.tga") == nil, "minimap128.tga is gone (nothing used it)")
end)()
