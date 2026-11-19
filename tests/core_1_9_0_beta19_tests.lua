-- ======== 1.9.0-beta19 (Shweep, 17 Nov) ========
-- Fonts (Shweep: "we lost fonts", his /run: 15 of 20 left out, all nine of BagSmith's among them). As FlareUI 6.10.1
-- found on Forever: a font file loads only when a drawn text asks for it (until then SetFont answers false and the text
-- keeps its face), and a hidden or blank text's request never loads it; BagSmith tested each file on a hidden, blank
-- text, so only fonts already drawn somewhere passed. Now the client says whether it has the file
-- (C_UIFileAsset.IsKnownFile); font objects take the file at once (Shweep's /run: SetFont answers nil, GetFont reads it
-- back); the Font menu's names ask again until the game has the file. The chosen Font also on the toolbar's buttons and
-- labels, the sheet tabs and the character picker, at the game's size (Shweep: "header buttons (both styles) and the alt
-- dropdown"). Global Inventory's item currencies counted in each character's saved bags and bank (Shweep: "Currency is
-- not showing everyone's currency... linen cloth").

local OWN = "Interface\\AddOns\\BagSmith\\Media\\Fonts\\"
local function key(p) return (tostring(p or "")):lower():gsub("/", "\\") end

-- The client as FlareUI describes it: files drawn already load at once; any other file is refused (false, the face
-- unchanged) until a shown text with words asks for it, which loads it for the next ask; a file that isn't there never.
local function client(M)
	local LOADED = { ["fonts\\frizqt__.ttf"] = true }
	local function missing(p) return key(p):find("gone", 1, true) ~= nil end
	-- drawn: shown, with words, and every frame above it shown
	local function drawn(s)
		if not (s:IsShown() and (s.text or "") ~= "") then return false end
		local f, depth = s.parentFrame, 0
		while f and depth < 30 do
			if f.IsShown and not f:IsShown() then return false end
			f = f.GetParent and f:GetParent() or nil
			depth = depth + 1
		end
		return true
	end
	local mk = M.fs
	M.fs = function()
		local s = mk()
		function s:SetFont(p, size, flags)
			if missing(p) then return false end
			if not LOADED[key(p)] then
				if drawn(self) then LOADED[key(p)] = true end   -- (asked by a drawn text)
				return false
			end
			self.font, self.size, self.flags = p, size, flags
			return true
		end
		function s:GetFont() return self.font, self.size, self.flags end
		return s
	end
	-- font objects: they take a file as it is (Shweep's /run), and the game's templates start in Friz at 10
	local saved = { create = _G.CreateFont }
	local function fontObj(name, path, size, flags)
		local f = { name = name }
		function f:SetFont(p, s, fl) if missing(p) then return false end self.path, self.size, self.flags = p, s, fl end
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
	return LOADED, function()
		_G.CreateFont = saved.create; M.fs = mk; _G.C_UIFileAsset = nil
		for t, f in pairs(saved) do if t ~= "create" then _G[t] = f end end
	end
end

local function boot(skin, cache, prof)
	package.loaded.mock = nil
	local M = require("mock")
	_G.C_UIFileAsset = nil
	local LOADED, restore = client(M)
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 16, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local p = { skin = skin or "modern", view = "list" }
	for k, v in pairs(prof or {}) do p[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = cache or {}, profiles = { Default = p } }
	local n = M.loadAddon("BagSmith")
	local LSM = LibStub("LibSharedMedia-3.0")
	LSM:Register("font", "Gone Font", "Interface\\AddOns\\Other\\gone.ttf")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_LOGIN"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	return n, M, n.Window.main, LOADED, restore
end

local function names(F)
	local t = {}
	for _, c in ipairs(F:Choices()) do t[c.label] = true end
	return t
end
local NINE = { "Noto Sans", "Roboto Condensed", "Inter", "Asap Condensed", "Barlow Condensed", "Cabin Condensed", "Fira Condensed", "Marcellus", "Roboto Condensed Bold" }

;(function()
	local n, M, V, LOADED, restore = boot("modern", { ["Cinder - Forever"] = { name = "Cinder", realm = "Forever", class = "MAGE", level = 20, items = {}, bank = {} } })
	local F = n.Fonts
	-- the old check, on this client: only fonts already drawn (Shweep's list)
	local before = names(F)
	check(before["Default Font"] and not before["Inter"] and not before["Marcellus"], "(the model) without the client's answer, fonts not drawn yet are left out, as Shweep saw")
	-- the client's answer
	local asked = {}
	_G.C_UIFileAsset = { IsKnownFile = function(p) asked[#asked + 1] = p; return not key(p):find("gone", 1, true) end }
	local now = names(F)
	local missing = {}
	for _, w in ipairs(NINE) do if not now[w] then missing[#missing + 1] = w end end
	check(#missing == 0, "all nine of BagSmith's fonts offered, none drawn yet (missing: " .. table.concat(missing, ", ") .. ")")
	check(#asked > 0, "the client was asked whether it has each file")
	check(not now["Gone Font"], "a file the client doesn't have isn't offered")
	check(not LOADED[key(OWN .. "Inter-Regular.ttf")], "(nothing drew Inter: the list didn't need it drawn)")

	-- choosing one: the item text's font objects take it at once
	n:Set("fontName", "Inter"); M.runTimers()
	check(F:Path() == OWN .. "Inter-Regular.ttf", "Inter chosen: it's the one used (" .. tostring(F:Path()) .. ")")
	local item = _G.BagSmithFont_GameFontHighlightSmall
	check(item and item:GetFont() == OWN .. "Inter-Regular.ttf", "the item text's font is Inter, though the game hadn't drawn it")

	-- the header in the chosen Font, at the game's size (Item Text Size stays off it)
	n:Set("textScale", 1.3); M.runTimers()
	local FACE = "BagSmithFaceFont_GameFontHighlightSmall"
	local face = _G[FACE]
	check(face and face:GetFont() == OWN .. "Inter-Regular.ttf" and select(2, face:GetFont()) == 10, "the header's font: Inter at the game's size (10), with Item Text Size at 130%")
	check(select(2, item:GetFont()) == 13, "(the item text follows Item Text Size: 13)")
	local label
	for _, it in ipairs(V.toolItems) do if it.isLabel then label = label or it.frame end end
	local function uses(fs) return fs and fs.fontObject == FACE end
	check(uses(V.btnSort.label) and uses(V.btnMerge.label) and uses(V.btnFilter.label) and uses(V.btnGrpMenu.label), "Sort, Merge Stacks, Filter and the Sections menu button")
	check(uses(V.grpSegBtns[1].label) and uses(V.grpSegBtns[3].label) and uses(label), "the Sections choices, and the \"Sections\" label")
	check(V.charBtn and uses(V.charBtn.label) and uses(V.charLevel), "the character picker: name and level")
	local tab
	for _, b in ipairs(V.tabButtons or {}) do if b:IsShown() then tab = tab or b end end
	check(tab and uses(tab.label), "the sheet tabs")
	n.Popups:ToggleCharacters(V)
	local row = n.Popups.chars.rows[1]
	check(row and uses(row.name) and uses(row.lvl), "the character list: names and levels")
	n.Popups.chars:Hide()
	-- the "Sections" label measured again in the new face
	local was = label.GetStringWidth
	label.GetStringWidth = function() return 77 end
	n:Set("fontName", "Marcellus"); M.runTimers()
	local w
	for _, it in ipairs(V.toolItems) do if it.frame == label then w = it.width end end
	check(w == 77 and face:GetFont() == OWN .. "Marcellus-Regular.ttf", "a new font: the header's labels measured again (" .. tostring(w) .. ")")
	label.GetStringWidth = was
	n:Set("fontName", ""); M.runTimers()
	check(face:GetFont() == "Fonts\\FRIZQT__.TTF" and select(2, face:GetFont()) == 10, "Default Font: the game's face again, at its size")
	n:Set("textScale", 1); M.runTimers()

	-- the Font menu: each name in its own face, asking again until the game has the file
	n.SettingsPanel:Show(); n.SettingsPanel:ShowPage("look")
	local drop
	for _, d in ipairs(n.SettingsPanel.pools.dropdown) do if d:IsShown() and d.key == "fontName" then drop = d end end
	drop.btn:GetScript("OnClick")(drop.btn)
	local menu = n.menuFrame
	local cabin
	for _, r in ipairs(menu.rows) do if r:IsShown() and r.text.text == "Cabin Condensed" then cabin = r end end
	check(cabin and cabin.text:GetFont() ~= OWN .. "CabinCondensed-Regular.ttf" and n.MENU_FACES_PENDING[cabin.text], "a name the game hasn't drawn: refused at first, and waiting")
	M.runTimers()   -- half a second: the shown name asks, and the game loads the file
	M.runTimers()   -- a second: it asks again, and takes it
	check(cabin.text:GetFont() == OWN .. "CabinCondensed-Regular.ttf" and not n.MENU_FACES_PENDING[cabin.text], "a second on: in its own face")
	menu:Hide()
	n.SettingsPanel.frame:Hide()
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()

-- Classic: the header the same
;(function()
	local n, M, V, LOADED, restore = boot("classic")
	_G.C_UIFileAsset = { IsKnownFile = function(p) return not key(p):find("gone", 1, true) end }
	n:Set("fontName", "Inter"); M.runTimers(); M.runTimers()
	local FACE = "BagSmithFaceFont_GameFontHighlightSmall"
	local function uses(fs) return fs and fs.fontObject == FACE end
	local tab
	for _, b in ipairs(V.tabButtons or {}) do if b:IsShown() then tab = tab or b end end
	check(uses(V.btnSort.label) and uses(V.grpSegBtns[2].label) and uses(V.charBtn.label) and tab and uses(tab.label), "Classic: Sort, Sections, the picker and the tabs in the chosen Font")
	check(_G[FACE]:GetFont() == OWN .. "Inter-Regular.ttf", "Classic: Inter")
	check((n.errors or 0) == 0, "Classic: no errors")
	restore()
end)()

-- Global Inventory's currencies: items counted in each character's saved bags and bank
;(function()
	local linen = { bag = 0, slot = 1, itemID = 2589, count = 2, name = "Linen Cloth", quality = 1, sellPrice = 10, link = "|Hitem:2589|h[Linen Cloth]|h" }
	local mark = { bag = 0, slot = 2, itemID = 20558, count = 3, name = "Warsong Gulch Mark", quality = 2, link = "|Hitem:20558|h[Warsong Gulch Mark]|h" }
	local cache = {
		-- Linen Cloth in the bags, not in the currencies saved at the last logout; a mark only this one has; a wallet
		-- currency; and a stale saved token (saved as 5, none in the bags now)
		["Cinder - Forever"] = { name = "Cinder", realm = "Forever", class = "MAGE", level = 20, items = { linen, mark }, bank = {},
			currencies = { ["i:20558"] = { id = 20558, name = "Warsong Gulch Mark", icon = 1, count = 3, source = "Bags" },
				["c:42"] = { id = 42, name = "Honor Points", icon = 1, count = 80 },
				["i:4306"] = { id = 4306, name = "Silk Cloth", icon = 1, count = 5, source = "Bags" } } },
	}
	local n, M, V, _, restore = boot("modern", cache, { customCurrencies = { 2589 } })
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local by = {}
	for _, e in ipairs(n.Currency:Global(false)) do by[e.key] = e end
	local L = by["i:2589"]
	local function per(e)
		local t = {}
		for _, p in ipairs(e and e.per or {}) do t[#t + 1] = tostring(p.name) .. "=" .. tostring(p.count) end
		return table.concat(t, ", ")
	end
	check(L and L.count == 18 and #L.per == 2 and L.per[1].count == 16 and L.per[2].name == "Cinder" and L.per[2].count == 2,
		"Linen Cloth: 18, you 16 and Cinder 2, from Cinder's saved bags (" .. per(L) .. ")")
	check(by["i:20558"] and by["i:20558"].count == 3 and #by["i:20558"].per == 1, "a mark only Cinder has: 3, Cinder's")
	check(by["c:42"] and by["c:42"].count == 80, "a wallet currency: from the saved wallet, as before")
	check(not by["i:4306"], "a token saved as 5 but no longer in the bags: not counted")
	-- the drawer: Linen Cloth opens; the footer's tooltip lists both
	n.Currency:ToggleFavorite("i:2589")
	local D = n.Drawer
	D:Show(); M.runTimers()
	local row
	for _, r in ipairs(D.frame.rows) do if r:IsShown() and r.key == "i:2589" then row = r end end
	check(row and row.kids, "the drawer: Linen Cloth has its arrow")
	n:RefreshViews(true); M.runTimers()
	local chip
	for _, c in ipairs(V.favChips or {}) do if c:IsShown() and c.key == "i:2589" then chip = c end end
	GameTooltip.lines = {}
	if chip then chip:GetScript("OnEnter")(chip) end
	local tip = table.concat(GameTooltip.lines or {}, " | ")
	check(chip and tip:find("Total: 18", 1, true) and tip:find("Cinder", 1, true), "the footer's Linen Cloth: both characters and the total: " .. tip)
	D:Hide()
	-- your own bags: your count only
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local mine
	for _, e in ipairs(n.Currency:List()) do if e.key == "i:2589" then mine = e end end
	check(mine and mine.count == 16, "your bags' list: your 16")
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()
