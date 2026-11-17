-- ======== 1.9.0-beta8 (Shweep, 16 Nov) ========
-- Settings: the Global Inv page names, and an icon before each sub-page's name and heading. Footer Text Size, the
-- column headings following Text Size, Modern's footer contents lower ("rides high"). Global Inventory's Total row in
-- place of the note by the title. The search icon redrawn (Shweep: "looks more like a spoon").

-- a point as the game reports it (the mock keeps it as written): point, relativeTo, relativePoint, x, y
local function pt(f, i)
	local p = { f:GetPoint(i or 1) }
	if type(p[2]) == "number" then return p[1], nil, p[1], p[2], p[3] end
	if p[2] == nil and #p == 1 then return p[1], nil, p[1], 0, 0 end
	return p[1], p[2], p[3], p[4] or 0, p[5] or 0
end
-- stand-ins for the game's fonts (the mock has none), as the 1.8.0-beta19 set makes them
local function fonts()
	local saved = { create = _G.CreateFont }
	local function fontObj(name, path, size, flags)
		local f = { name = name }
		function f:SetFont(p, s, fl) self.path, self.size, self.flags = p, s, fl end
		function f:GetFont() return self.path, self.size, self.flags end
		function f:SetTextColor() end
		function f:GetTextColor() return 1, 1, 1 end
		function f:SetShadowColor() end
		function f:GetShadowColor() return 0, 0, 0, 1 end
		function f:SetShadowOffset() end
		function f:GetShadowOffset() return 1, -1 end
		if path then f:SetFont(path, size, flags) end
		_G[name] = f
		return f
	end
	_G.CreateFont = function(name) return fontObj(name) end
	for _, t in ipairs({ "GameFontHighlightSmall", "GameFontHighlight", "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontHighlightLarge", "GameFontNormalHuge" }) do
		saved[t] = _G[t]; fontObj(t, "Fonts\\FRIZQT__.TTF", 10, "")
	end
	return function() _G.CreateFont = saved.create; for t, f in pairs(saved) do if t ~= "create" then _G[t] = f end end end
end
local function boot(skin, prof)
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local p = { skin = skin or "modern", view = "list" }
	for k, v in pairs(prof or {}) do p[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 3, name = "Linen Cloth", quality = 1, sellPrice = 10, link = "|Hitem:2589|h[Linen Cloth]|h" } } },
	}, profiles = { Default = p } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	return n, M, n.Window.main
end

;(function()
	-- Settings: names and icons
	local n, M = boot()
	local P = n.SettingsPanel
	P:Show()
	local by = {}
	for _, b in ipairs(P.navButtons) do by[b.page] = b end
	check(by.globalsections.text.text == "Global Inv Sections" and by.globalcols.text.text == "Global Inv Columns" and by.globalsheets.text.text == "Global Inv Sheets",
		"the Global Inv page names")
	local want = { dynamic = "ui%-dynamic", custom = "ui%-sliders", globalsections = "ui%-globe", bagcols = "mark%.tga", bankcols = "ui%-bank",
		globalcols = "ui%-globe", bagsheets = "mark%.tga", banksheets = "ui%-bank", globalsheets = "ui%-globe", loothelper = "ui%-pouch", dehelper = "ui%-disenchant%.tga" }
	for page, pat in pairs(want) do
		local b = by[page]
		check(b and b.icon and tostring(b.icon.texture):find(pat), page .. ": its icon before its name in the list")
		P:ShowPage(page)
		local head
		for _, h in ipairs(P.pools.head) do if h:IsShown() then head = head or h end end
		local first
		for _, h in ipairs(P.pools.head) do if h:IsShown() and (not first or select(5, h:GetPoint(1)) > select(5, first:GetPoint(1))) then first = h end end
		check(first and first.icon and first.icon:IsShown() and tostring(first.icon.texture):find(pat), page .. ": and before its heading")
	end
	check(not (by.general.icon and by.general.icon.texture) and not (by.sections.icon and by.sections.icon.texture), "the main pages have none")
	-- an icon's file path isn't searchable text
	P:SetQuery("pouch")
	local found = false
	for _, h in ipairs(P.pools.head) do if h:IsShown() and tostring(h.text.text):find("Loot Helper", 1, true) then found = true end end
	check(not found, "searching \"pouch\" doesn't find Loot Helper by its icon's name")
	P:SetQuery("")
	for _, f in ipairs({ "ui-dynamic.tga", "ui-sliders.tga", "ui-search.tga" }) do
		local h = io.open("BagSmith/Media/" .. f, "rb")
		check(h ~= nil, f .. " is in the addon")
		if h then
			local head = h:read(18); h:close()
			check(head and head:byte(3) == 2 and head:byte(13) == 64 and head:byte(15) == 64 and head:byte(17) == 32, f .. ": 64x64, 32-bit, like the other icons")
		end
	end
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- Modern's footer: its contents 6 px lower, the line and tabs where they were; Classic as built
	local n, M, V = boot("modern")
	local f = V.footer
	local p = { pt(f) }
	check(p[1] == "BOTTOMLEFT" and p[5] == 6, "Modern: the footer sits 6 px lower (" .. tostring(p[5]) .. ")")
	local lp = { pt(f.line) }
	check(lp[1] == "TOPLEFT" and lp[5] == 6 and f:GetHeight() == 26, "its line raised 6 px: where it was")
	local tp = { pt(V.tabs) }
	check(tp[5] == 12 + 26 + 2, "the tabs where they were")
	n, M, V = boot("classic")
	p = { pt(V.footer) }
	check(p[5] == 12 and V.footerKey == "26:0", "Classic: as built (" .. tostring(p[5]) .. ", " .. tostring(V.footerKey) .. ")")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- Footer Text Size: the footer's text and height; Text Size: the column headings
	local restore = fonts()
	local n, M, V = boot("modern")
	check(n.db.footerTextScale == 1, "Footer Text Size: 100% at first")
	local FF = "BagSmithFooterFont_GameFontHighlightSmall"
	check(V.moneyText.fontObject == FF and V.btnBags.label.fontObject == FF and V.statusText.fontObject == FF, "the gold, the counts and the status in the footer's own font")
	local hdr = V.headerLabels.n.text.fontObject
	check(hdr == "BagSmithFont_GameFontHighlightSmall", "the column headings in the item text's font: " .. tostring(hdr))
	local minBefore = V.minWidth
	n:Set("footerTextScale", 1.5); M.runTimers(); n:RefreshViews(true); M.runTimers()
	check(_G[FF].size == 15 and _G.BagSmithFont_GameFontHighlightSmall.size == 10, "150%: the footer's text 15, the items' still 10")
	check(V.footer:GetHeight() == 39 and V.btnBags:GetHeight() == 30, "the footer grows to hold it (39), its buttons too (30)")
	local tp = { pt(V.tabs) }
	check(tp[5] == 12 + 39 + 2, "the tabs move up with it")
	check(V:FooterNeed() > 0 and V.minWidth >= minBefore and V.minWidth >= V:FooterNeed(), "the window's narrowest width keeps the footer's text apart: " .. tostring(V.minWidth))
	n:Set("footerTextScale", 1); M.runTimers(); n:RefreshViews(true); M.runTimers()
	check(V.footer:GetHeight() == 26 and V.btnBags:GetHeight() == 20, "back to 100%")
	n:Set("textScale", 1.5); M.runTimers(); n:RefreshViews(true); M.runTimers()
	check(V.header:GetHeight() == 30 and V.headerLabels.n:GetHeight() == 30, "Text Size 150%: the headings' strip grows (30)")
	check(_G[FF].size == 10, "and the footer's text stays")
	n:Set("textScale", 1); M.runTimers(); n:RefreshViews(true); M.runTimers()
	check(V.header:GetHeight() == 20, "back to 20")
	-- Settings > Style > Size
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("look")
	local rows = {}
	for _, w in ipairs(P.pools.step) do if w:IsShown() then rows[#rows + 1] = w.key end end
	local a, b = n.IndexOf(rows, "textScale"), n.IndexOf(rows, "footerTextScale")
	check(a and b == a + 1, "Footer Text Size right under Text Size: " .. table.concat(rows, ","))
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()

;(function()
	-- Global Inventory's Total row
	local n, M, V = boot("modern")
	check(not (V.totalRow and V.totalRow:IsShown()), "(setup) your bags: no Total row")
	local sp = { V.scroll:GetPoint(2) }
	local before = sp[5]
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local T = V.totalRow
	check(T and T:IsShown(), "Global Inventory: a Total row")
	check(T.label.text == "Total" and T.count.text == "(1 item shown)", "Total, and how many items: " .. tostring(T.count.text))
	check(T.cells.v.text and T.cells.v.text ~= "-", "the Vendor sum: " .. tostring(T.cells.v.text))
	local plan = V:ColumnPlan()
	local vcol
	for _, c in ipairs(plan) do if c.key == "v" then vcol = c end end
	local cp = { T.cells.v:GetPoint(1) }
	check(vcol and cp[4] == vcol.x and T.cells.v.width == vcol.width, "under the Vendor column")
	local tp = { T:GetPoint(1) }
	check(tp[2] == V.tabs and tp[3] == "TOPLEFT", "pinned above the tabs")
	sp = { V.scroll:GetPoint(2) }
	check(sp[5] == before + T:GetHeight() + 2, "the list ends above it")
	-- what it means
	GameTooltip.lines = {}
	T:GetScript("OnEnter")(T)
	local tip = table.concat(GameTooltip.lines or {}, " | ")
	check(tip:find("search, tab and filters", 1, true) and tip:find("Vendor:", 1, true), "hover: what it totals and means: " .. tip)
	-- a search changes it
	V.st.filters.text = "zzz"; n:RefreshViews(true); M.runTimers()
	check(T.count.text == "(0 items shown)" and T.cells.v.text == "-", "it follows the search")
	V.st.filters.text = ""; n:RefreshViews(true); M.runTimers()
	-- leaving
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	sp = { V.scroll:GetPoint(2) }
	check(not T:IsShown() and sp[5] == before, "leaving: no Total row, the list down to the tabs again")
	check((n.errors or 0) == 0, "no errors")
end)()
