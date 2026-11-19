;(function()
	-- ======== 1.9.0-beta18 (Shweep, 17 Nov) ========
	-- The currency drawer in Global Inventory: "Can't read the entire description text here and no way to expand it",
	-- "when pinned the tool tip doesn't give any info on per player counts", "be nice to see some accordions in the
	-- side panel for each currency like the sheet to show per player of each".
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, profiles = { Default = { view = "list" } }, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20,
			currencies = { ["c:42"] = { id = 42, name = "Honor Points", icon = 1, count = 300 }, ["c:7"] = { id = 7, name = "Badge", icon = 1, count = 4 } } },
		["Corwin - Forever"] = { name = "Corwin", realm = "Forever", class = "WARRIOR", level = 30,
			currencies = { ["c:42"] = { id = 42, name = "Honor Points", icon = 1, count = 50 } } },
	} }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local D = n.Drawer
	D:Show(); M.runTimers()
	local f = D.frame
	-- the note, whole
	check(f.hint.text == "All your characters' currencies. Pin one to show it in Global Inventory's footer.", "no pins: the note, in full: " .. tostring(f.hint.text))
	n.Currency:ToggleFavorite("c:42"); D:Refresh(); M.runTimers()
	check(f.hint.text == "Pinned currencies show in Global Inventory's footer, totalled for all your characters.", "with a pin: the note, in full")
	local p = { f.scroll:GetPoint(1) }
	local y = type(p[2]) == "table" and p[5] or p[3]
	local down = f.listDown or 0
	check(down > 0 and y == -50 - down, "the note wraps, and the list starts below it (" .. tostring(y) .. ")")
	-- rows: Honor Points (two characters) opens; Badge (one) doesn't
	local function rows()
		local t = {}
		for _, r in ipairs(f.rows) do if r:IsShown() then t[#t + 1] = r end end
		return t
	end
	local honor, badge
	for _, r in ipairs(rows()) do
		if r.key == "c:42" then honor = r elseif r.key == "c:7" then badge = r end
	end
	check(honor and honor.kids and tostring(honor.name.text):find("ui%-chev%-right%.tga:12:12:") and tostring(honor.name.text):find("Honor Points", 1, true),
		"Honor Points (two characters): an arrow, in the accent")
	check(badge and not badge.kids and not tostring(badge.name.text):find("ui%-chev", 1), "Badge (one character): no arrow")
	local before = #rows()
	honor:GetScript("OnMouseUp")(honor, "LeftButton"); M.runTimers()
	local kids = {}
	for _, r in ipairs(rows()) do if r.kid then kids[r.name.text] = r end end
	check(#rows() == before + 2 and kids.Brannoc and kids.Corwin, "clicked: a row per character under it")
	check(kids.Brannoc.count.text == 300 or kids.Brannoc.count.text == "300", "each with their count (Brannoc 300)")
	check(not kids.Brannoc.star:IsShown() and not kids.Brannoc.up:IsShown() and select(4, kids.Brannoc:GetPoint(1)) == 14, "indented, no pin or arrows")
	for _, r in ipairs(rows()) do if r.key == "c:42" then honor = r end end
	check(tostring(honor.name.text):find("ui%-chev%-down%.tga"), "the arrow points down while open")
	honor:GetScript("OnMouseUp")(honor, "LeftButton"); M.runTimers()
	check(#rows() == before, "clicked again: closed")
	honor:GetScript("OnMouseUp")(honor, "LeftButton"); M.runTimers()
	D:Hide(); D:Show(); M.runTimers()
	check(#rows() == before, "opening the drawer again: all closed")
	badge:GetScript("OnMouseUp")(badge, "LeftButton"); M.runTimers()
	check(#rows() == before, "Badge: clicking opens nothing")
	-- the footer's pinned currency: who has how many
	n:RefreshViews(true); M.runTimers()
	local chip
	for _, c in ipairs(V.favChips or {}) do if c:IsShown() and c.key == "c:42" then chip = c end end
	check(chip ~= nil, "(setup) Honor Points pinned in Global Inventory's footer")
	GameTooltip.lines = {}
	chip:GetScript("OnEnter")(chip)
	local tip = table.concat(GameTooltip.lines or {}, " | ")
	check(tip:find("Total: 350", 1, true) and tip:find("Brannoc", 1, true) and tip:find("300", 1, true) and tip:find("Corwin", 1, true), "its tooltip: each character's count and the total: " .. tip)
	check((n.errors or 0) == 0, "no errors")
end)()
