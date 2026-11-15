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
