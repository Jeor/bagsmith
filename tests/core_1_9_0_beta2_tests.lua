;(function()
	-- ======== 1.9.0-beta2 (Shweep, 16 Nov): Global Inventory, first steps ========
	-- The globe (left of Travel Mode) shows every item on your characters on this realm in one list: read only, Who and
	-- Where always shown, one row per item with every character's count together. The window's own choices aren't
	-- changed: leaving (the globe again, or closing) brings the bags back as they were.
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	M.put(0, 2, { id = 4306, name = "Silk Cloth", q = 1, count = 2, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 150 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, profiles = { Default = { view = "icons", mergeStacks = true } }, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20, gold = 1,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 3, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" },
				{ bag = 0, slot = 2, itemID = 2592, count = 7, name = "Wool Cloth", quality = 1, link = "|Hitem:2592|h[Wool Cloth]|h" } },
			bank = { { bag = 6, slot = 1, itemID = 2589, count = 2, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" } } },
		["Elsewhere - Other Realm"] = { name = "Elsewhere", realm = "Other Realm", class = "PRIEST", level = 30,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 99, name = "Linen Cloth", quality = 1 } } },
	} }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local G = V.btnGlobal
	check(G and G:IsShown() and G:GetPoint(1) == "RIGHT" and select(2, G:GetPoint(1)) == V.btnTravel, "the globe sits left of Travel Mode")
	check(select(2, V.titleDivider:GetPoint(1)) == G, "and the divider moved to its left")
	check(V:TitleForms()[1] == "Bags", "the title reads Bags")
	V.st.filters.text = "cloth"; V.st.sheet = "All"
	G:GetScript("OnClick")(G); M.runTimers(); M.runTimers()
	check(n.ui.global == true and V:TitleForms()[1] == "Global Inventory" and V:TitleForms()[2] == "Global Inv", "the globe: Global Inventory (Global Inv when narrow)")
	check(V.st.filters.text == "" and V:Pref("view") == "list" and V:Pref("mergeStacks") == false, "the search starts empty; always a list, unmerged")
	check(n.db.view == "icons" and n.db.mergeStacks == true, "the window's own choices aren't changed")

	local shown = V:Filtered()
	local by = {}
	for _, r in ipairs(shown) do by[r.itemID] = r end
	local linen = by[2589]
	check(linen and linen.count == 10 and linen.who == "2 characters" and linen.where == "Bags, Bank", "Linen Cloth: one row, 5 + 3 + 2, two characters, bags and bank: " .. tostring(linen and linen.count))
	check(by[2592] and by[2592].who == "Brannoc" and by[2592].whoClass == "PRIEST" and by[2592].where == "Bags", "Wool Cloth: one character's, by name")
	check(by[4306] and by[4306].count == 2, "your own items too")
	check(linen.display and linen.cached and not linen.bag, "read-only rows (no bag or slot to act on)")
	local plan = V:ColumnPlan()
	local keys = {}
	for _, c in ipairs(plan) do keys[#keys + 1] = c.key end
	local at = n.IndexOf(keys, "n")
	check(at and keys[at + 1] == "who" and keys[at + 2] == "w", "Who and Where right after the item: " .. table.concat(keys, ","))
	n:RefreshViews(true); M.runTimers()
	local row
	local function look(b) if b and b.IsShown and b:IsShown() and b.rec and b.rec.itemID == 2592 then row = b end end
	for _, b in ipairs(n.Buttons.all or {}) do look(b) end
	for _, pool in pairs(n.Buttons.mirrors or {}) do for _, b in pairs(pool) do look(b) end end
	for _, b in ipairs(n.Buttons.recent or {}) do look(b) end
	for _, pool in pairs(n.Buttons.cached or {}) do for _, b in pairs(pool) do look(b) end end
	check(row and row.colWho.text == "Brannoc" and row.colWhere.text == "Bags", "the row shows Who and Where")

	-- leaving: the globe again
	G:GetScript("OnClick")(G); M.runTimers(); M.runTimers()
	check(n.ui.global == nil and V.st.filters.text == "cloth" and V:Pref("view") == "icons" and V:TitleForms()[1] == "Bags", "the globe again: your bags as they were, the search back")
	-- leaving: closing the window
	G:GetScript("OnClick")(G); M.runTimers()
	check(n.ui.global == true, "(setup) back in Global Inventory")
	V:Hide(); M.runTimers()
	check(n.ui.global == nil and V.st.filters.text == "cloth", "closing BagSmith leaves Global Inventory")
	-- another character's view and a saved-bank tab step aside
	V:Show(); M.runTimers()
	V:SetSheet("Bank"); M.runTimers()
	G:GetScript("OnClick")(G); M.runTimers()
	check(V.st.sheet == "All", "from the saved Bank tab: All")
	G:GetScript("OnClick")(G); M.runTimers()
	check(V.st.sheet == "Bank", "and back to it on leaving")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- The other beta2 changes: Settings > General's Tooltips card, the AH price setting, the picker's surname initial
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	check(n.ShortName("Shweepy Thyme") == "Shweepy T." and n.ShortName("Bree") == "Bree", "a surname shows as its initial; a single name as it is")
	check(n.db.tipAHPrice == true, "Show AH Price in Item Tooltips: on by default")
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("general")
	local head, rows = nil, {}
	for _, h in ipairs(P.pools.head) do if h:IsShown() and h.text.text == "Tooltips" then head = h end end
	for _, w in ipairs(P.pools.check) do
		if w:IsShown() and (w.key == "tipInventory" or w.key == "tipAHPrice" or w.key == "helpTips") then rows[#rows + 1] = { key = w.key, y = select(5, w:GetPoint(1)), text = w.text.text } end
	end
	table.sort(rows, function(a, b) return a.y > b.y end)
	check(head ~= nil, "the card's heading reads Tooltips")
	check(#rows == 3 and rows[1].key == "tipInventory" and rows[2].key == "tipAHPrice" and rows[3].key == "helpTips" and rows[3].text == "Show Help Tooltips",
		"Inventory, then AH Price, then Show Help Tooltips last: " .. table.concat((function() local t = {} for _, r in ipairs(rows) do t[#t + 1] = r.key end return t end)(), ","))
	check((n.errors or 0) == 0, "no errors")
end)()
