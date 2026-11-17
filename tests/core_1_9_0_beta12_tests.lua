;(function()
	-- ======== 1.9.0-beta12 (Shweep, 17 Nov) ========
	-- Global Inventory's Who column: the accordion's arrows "may stand out more if they are the accent color", and
	-- "slightly bigger too". The text beside them keeps its own color.
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, profiles = { Default = { view = "list" } }, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 3, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" } } },
	} }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local function linenRow()
		local row
		local function look(b) if b and b.IsShown and b:IsShown() and b.rec and b.rec.itemID == 2589 and b.rec.globalKids then row = b end end
		for _, b in ipairs(n.Buttons.all or {}) do look(b) end
		for _, pool in pairs(n.Buttons.cached or {}) do for _, b in pairs(pool) do look(b) end end
		for _, pool in pairs(n.Buttons.mirrors or {}) do for _, b in pairs(pool) do look(b) end end
		return row
	end
	local function rgb(r, g, b) return ("%d:%d:%d|t"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)) end
	n:RefreshViews(true); M.runTimers()
	local row = linenRow()
	check(row ~= nil, "(setup) Linen Cloth, two characters: an accordion row")
	local text = row and row.colWho.text or ""
	check(text:find("ui%-chev%-right%.tga:12:12:", 1) and text:find(rgb(n.Skins:Accent()), 1, true), "closed: a right arrow, 12 px, in the accent: " .. text)
	check(text:find("2 characters", 1, true), "and the text after it as before")
	-- open: the down arrow, the same color
	n.ui.globalOpen = { [2589] = true }
	n:RefreshViews(true); M.runTimers()
	row = linenRow()
	text = row and row.colWho.text or ""
	check(text:find("ui%-chev%-down%.tga:12:12:", 1) and text:find(rgb(n.Skins:Accent()), 1, true), "open: a down arrow, the same")
	-- another accent: the arrows follow
	n:Set("accent", "3598db"); M.runTimers(); n:RefreshViews(true); M.runTimers()
	row = linenRow()
	text = row and row.colWho.text or ""
	check(text:find(rgb(n.Skins:Accent()), 1, true) and text:find("53:152:219|t", 1, true), "a new accent: the arrows follow it")
	check((n.errors or 0) == 0, "no errors")
end)()
