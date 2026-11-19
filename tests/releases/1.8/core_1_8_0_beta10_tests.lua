;(function()
	-- ======== 1.8.0-beta10: Jeor's PR #9 (icon alignment), and corner marks inside the Classic frame ========
	-- Shweep's screenshot: with the Classic icon filling its slot, the item level "23" sat on the frame's top edge.
	-- In Classic icon cells every corner mark moves in by the frame's rim (8% of the icon: 3 px at 37 px).
	local function boot(skin)
		package.loaded.mock = nil
		local M = require("mock")
		M.put(0, 1, { id = 7001, name = "Sturdy Boots", q = 3, count = 1, class = 4, subclass = 1, price = 5, ilvl = 23, equip = "INVTYPE_FEET" })
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, view = "icons", iconItemLevel = true } } }
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		ToggleAllBags(); M.runTimers(); M.runTimers()
		return n, M
	end
	local n = boot("classic")
	local b = n.Buttons:Get(0, 1)
	local p = b.ilvlText and b.ilvlText.points[1]
	local rim = math.floor(n.Buttons:IconPx(b) * 0.08 + 0.5)
	check(b.mode == "cell" and rim >= 2, "(setup) a Classic icon cell; the rim is " .. rim .. " px")
	check(p and p[1] == "TOPRIGHT" and p[2] == b.icon and p[4] == -rim and p[5] == -rim, "Classic: the item level sits inside the frame, " .. rim .. " px in from the corner: " .. tostring(p and p[4]) .. ", " .. tostring(p and p[5]))
	n = boot("modern")
	b = n.Buttons:Get(0, 1)
	p = b.ilvlText and b.ilvlText.points[1]
	check(p and p[4] == 0 and p[5] == 0, "Modern: unchanged, flush in the corner")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- (1.8.0-beta10, Shweep's results on Forever) low blues: a third each, the shard, 3 dust, 3 essences; an early estimate
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local DE, MATS = n.Disenchant, n.Disenchant.MATS
	local list, key = DE:Expectation({ quality = 3, ilvl = 20, classID = 4 })
	local by = {}
	for _, m in ipairs(list) do by[m[1]] = m end
	check(key == "3:1" and #list == 3, "a level 20 blue: three results, the same bracket key as before (3:1)")
	check(by[MATS.smallGlimmering] and math.abs(by[MATS.smallGlimmering][2] - 1/3) < 1e-9 and by[MATS.smallGlimmering][3] == 1, "a Small Glimmering Shard, a third of the time")
	check(by[MATS.strangeDust] and by[MATS.strangeDust][3] == 3 and by[MATS.strangeDust][4] == 3, "Strange Dust x3, a third")
	check(by[MATS.greaterMagic] and by[MATS.greaterMagic][3] == 3, "Greater Magic Essence x3, a third (item level 16 to 25)")
	list = DE:Expectation({ quality = 3, ilvl = 12, classID = 2 })
	local lesser = false
	for _, m in ipairs(list) do if m[1] == MATS.lesserMagic then lesser = true end end
	check(lesser, "a level 12 blue: Lesser Magic Essence, as for greens")
	list = DE:Expectation({ quality = 3, ilvl = 30, classID = 4 })
	check(#list == 1 and list[1][1] == MATS.largeGlimmering and list[1][2] == 1 and not list.early, "above level 25: the classic shard, unchanged")
	local _, head = DE:LikelyLines({ quality = 3, ilvl = 20, classID = 4 })
	check(head and head:find("^early Forever estimate"), "the Likely results say it's an early Forever estimate: " .. tostring(head))
	local _, head2 = DE:LikelyLines({ quality = 2, ilvl = 20, classID = 4 })
	check(head2 and head2:find("^DE estimate"), "a green keeps its plain DE estimate")
	-- the loot chat now counts a blue's dust (it's in the cast's expected list)
	local c = { key = "3:1", allowed = {} }
	for _, m in ipairs(DE:Expectation({ quality = 3, ilvl = 20, classID = 4 })) do c.allowed[m[1]] = true end
	check(DE:Attributable(c, MATS.strangeDust) and DE:Attributable(c, MATS.greaterMagic), "a blue's dust and essence count from the loot chat too")
end)()

;(function()
	-- ======== 1.8.0-beta11 (Shweep): gold quest frames in both skins, a setting (on); beta profiles' indicator choices carry over ========
	for _, skin in ipairs({ "modern", "classic" }) do
		package.loaded.mock = nil
		local M = require("mock")
		M.put(0, 1, { id = 9101, name = "Gnoll Paw", q = 1, count = 3, class = 12, subclass = 0, type = "Quest", sub = "Quest", bind = 4 })
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, view = "icons", border = "off" } } }
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		ToggleAllBags(); M.runTimers(); M.runTimers()
		local b = n.Buttons:Get(0, 1)
		local function color()
			if skin == "modern" then local e = b.modernBorder and b.modernBorder[1]; return e and e:IsShown() and e.color end
			return b.qFrame:IsShown() and b.qFrame.color
		end
		check(n.db.questFrame == true, skin .. ": Gold Frame for Quest Items is on by default")
		local c = color()
		check(c and c[1] == 1 and math.abs(c[2] - 0.82) < 1e-9 and c[3] == 0, skin .. ": a quest item gets the gold frame, even with Rarity Borders Off")
		n:Set("questFrame", false); M.runTimers()
		c = color()
		check(not (c and c[1] == 1 and math.abs(c[2] - 0.82) < 1e-9), skin .. ": off: no gold frame")
		check((n.errors or 0) == 0, skin .. ": no errors")
	end
	-- a beta profile's beta9 style and beta5 items switch carry over to the empty and filled choices
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { glow_herb = true, glowStyle_herb = "frame", glowItems_herb = false, glowStyle_soul = "glow" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith")
	check(n.db.glowEmpty_herb == "frame" and n.db.glowFilled_herb == "off", "beta herb: Frame Color, items off: empty Frame Color, filled Off")
	check(n.db.glowEmpty_soul == "glow" and n.db.glowFilled_soul == "glow", "beta soul: Inner Glow on both")
	check(n.db.glowStyle_herb == nil and n.db.glowItems_herb == nil, "the old keys are gone")
end)()
