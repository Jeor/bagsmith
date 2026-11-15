;(function()
	-- ======== 1.8.0-beta1: Text Size and Font (Shweep's plan of 10 Nov) ========
	-- The item text in the bags, bank and bag windows and the Loot and Disenchant Helpers is made from BagSmith's own
	-- copies of the game's font templates (ns.Fonts), scaled by Text Size (80% to 150%) and, with Font, set in a face
	-- another addon shares through LibSharedMedia. Window chrome, Settings and What's New stay at the game's size.
	local function fontObj(name, path, size, flags)
		local f = { name = name }
		function f:SetFont(p, s, fl) self.path, self.size, self.flags = p, s, fl end
		function f:GetFont() return self.path, self.size, self.flags end
		function f:CopyFontObject(o) self.path, self.size, self.flags = o:GetFont(); self.copied = o end
		if path then f:SetFont(path, size, flags) end
		_G[name] = f
		return f
	end
	_G.CreateFont = function(name) return fontObj(name) end
	local FRIZ = "Fonts\\FRIZQT__.TTF"
	fontObj("GameFontHighlightSmall", FRIZ, 10, ""); fontObj("GameFontHighlight", FRIZ, 12, ""); fontObj("GameFontNormal", FRIZ, 12, "")
	fontObj("GameFontNormalSmall", FRIZ, 10, ""); fontObj("GameFontNormalLarge", FRIZ, 16, ""); fontObj("GameFontHighlightLarge", FRIZ, 14, "")
	fontObj("GameFontNormalHuge", FRIZ, 20, ""); fontObj("NumberFontNormal", FRIZ, 14, "OUTLINE")

	for _, skin in ipairs({ "modern", "classic" }) do
		package.loaded.mock = nil
		local M = require("mock")
		for s = 1, 4 do M.put(0, s, { id = 9900 + s, name = "Item" .. s, q = 2, class = 15, subclass = 0, price = 1 }) end
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, view = "list", rowHeight = 20 } } }
		local n = M.loadAddon("BagSmith")
		-- a shared-media library another addon loaded, with two fonts
		local LSM = LibStub:NewLibrary("LibSharedMedia-3.0", 1) or LibStub("LibSharedMedia-3.0")
		LSM.fonts = { ["Nice Serif"] = "Interface\\AddOns\\Other\\nice.ttf", ["Plain Sans"] = "Interface\\AddOns\\Other\\plain.ttf" }
		function LSM:List(kind) local t = {}; for k in pairs(self.fonts) do t[#t + 1] = k end; table.sort(t); return t end
		function LSM:Fetch(kind, key, noDefault) return self.fonts[key] end
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		ToggleAllBags(); M.runTimers()
		local F = n.Fonts
		local S = skin .. ": "
		local small = _G.BagSmithFont_GameFontHighlightSmall
		check(F:Name("GameFontHighlightSmall") == "BagSmithFont_GameFontHighlightSmall" and small and small.copied == GameFontHighlightSmall,
			S .. "the item text's font is BagSmith's copy of the game's")
		check(F:Name("NumberFontNormal") == "NumberFontNormal" and F:Name("ChatFontNormal") == "ChatFontNormal", S .. "the icons' number fonts (and anything else) stay the game's")
		check(small.size == 10 and small.path == FRIZ, S .. "at 100%: the game's size and face")
		check(F:RowNeed() == 20, S .. "a List row needs 20 px at 100% (under every Row Height, so nothing changes)")
		-- Text Size
		local main = n.Window.main
		local function rowH() for _, b in ipairs(main.used or {}) do if b:IsShown() and b.hasItem then return b.h end end end
		local h100 = rowH()
		n:Set("textScale", 1.5); M.runTimers()
		check(small.size == 15 and _G.BagSmithFont_GameFontNormal.size == 18, S .. "150%: 10 px becomes 15, 12 becomes 18")
		check(F:RowNeed() == 25 and rowH() == 25 and h100 == 20, S .. "List rows grow to fit (20 to 25 px; " .. tostring(h100) .. " to " .. tostring(rowH()) .. ")")
		n:Set("rowHeight", 30); M.runTimers()
		check(rowH() == 30, S .. "a larger Row Height still applies")
		n:Set("rowHeight", 20)
		n:Set("textScale", 0.8); M.runTimers()
		check(small.size == 8 and rowH() == 20, S .. "80%: smaller text, rows keep their Row Height")
		n:Set("textScale", 3); check(n.db.textScale == 1.5, S .. "past 150% is held at 150%")
		n:Set("textScale", 0.2); check(n.db.textScale == 0.8, S .. "under 80% at 80%")
		n:Set("textScale", 1)
		-- Font
		n:Set("fontName", "Nice Serif"); M.runTimers()
		check(small.path == "Interface\\AddOns\\Other\\nice.ttf" and small.size == 10 and _G.BagSmithFont_GameFontNormal.path == "Interface\\AddOns\\Other\\nice.ttf",
			S .. "a shared font: every copy takes its face, at its own size")
		n:Set("fontName", "Gone Font"); M.runTimers()
		check(small.path == FRIZ, S .. "a font that isn't shared any more: the game's face")
		n:Set("fontName", ""); M.runTimers()
		check(small.path == FRIZ, S .. "Game Font: the game's face")
		-- Settings: Style > Size has Text Size and Font, the fonts listed by name
		local P = n.SettingsPanel
		P:Show(); P:ShowPage("look"); M.runTimers()
		local stepRow, cycleRow
		for _, w in ipairs(P.pools.step) do if w:IsShown() and w.key == "textScale" then stepRow = w end end
		for _, w in ipairs(P.pools.cycle) do if w:IsShown() and w.key == "fontName" then cycleRow = w end end
		check(stepRow and stepRow.value.text == "100" and stepRow.text.text == "Text Size", S .. "Style > Size: Text Size, 100%")
		check(cycleRow and cycleRow.text.text == "Font" and cycleRow.value.text == "Game Font" and #cycleRow.choices == 3, S .. "and Font: Game Font, then the two shared fonts")
		cycleRow.next:GetScript("OnClick")(cycleRow.next); M.runTimers()
		check(n.db.fontName == "Nice Serif", S .. "the next arrow picks the next font (" .. tostring(n.db.fontName) .. ")")
		for _, w in ipairs(P.pools.cycle) do if w:IsShown() and w.key == "fontName" then cycleRow = w end end
		cycleRow.prev:GetScript("OnClick")(cycleRow.prev); cycleRow.prev:GetScript("OnClick")(cycleRow.prev); M.runTimers()
		check(n.db.fontName == "Plain Sans", S .. "the previous arrow goes back, round the list (" .. tostring(n.db.fontName) .. ")")
		n:Set("fontName", "")
		P:Hide()
		-- a profile without the settings: the copies follow it
		n:Set("textScale", 1.2); M.runTimers()
		check(small.size == 12, S .. "120%: 12 px")
		n:Set("textScale", 1)
	end
	-- no shared-media library and no font objects: nothing breaks, Font offers the game's only
	_G.CreateFont = nil
	for _, t in ipairs({ "GameFontHighlightSmall", "GameFontHighlight", "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontHighlightLarge", "GameFontNormalHuge", "NumberFontNormal" }) do _G[t] = nil end
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern", textScale = 1.5 } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local ok = pcall(function() ToggleAllBags(); M.runTimers() end)
	check(ok and n.Fonts:Name("GameFontHighlightSmall") == "GameFontHighlightSmall", "without font objects: the game's templates, no error")
	local ch = n.Fonts:Choices()
	check(#ch == 1 and ch[1].label == "Game Font", "without a shared-media library: Font offers the game's only")
end)()
