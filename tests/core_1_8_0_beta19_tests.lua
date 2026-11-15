;(function()
	-- ======== 1.8.0-beta19 (Shweep, after reading FlareUI 6.8.2) ========
	-- A first install shows no NEW tags (nothing is new to a new player); searching "new" finds what 1.8 added, all
	-- release long; and BagSmith's fonts are made from scratch, never copied from the game's (a copy can share the
	-- game's own font, so sizing it resized the game's text everywhere: FlareUI 6.3 on Forever).

	-- a first install
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = nil; _G.BagSmithDB = nil
	local n = M.loadAddon("BagSmith")
	n.version = "1.8.0-beta19"
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local P = n.SettingsPanel
	local seen = BagSmithDB.newSeen and BagSmithDB.newSeen["1.8"]
	check(seen and seen.look and seen.icons and seen.profile, "a first install: every page counts as seen")
	P:Show()
	local any = false
	for _, b in ipairs(P.navButtons) do if b.newTag and b.newTag:IsShown() then any = true end end
	check(not any, "so no NEW in the list")
	P:ShowPage("look")
	for _, w in ipairs(P.pools.step) do if w:IsShown() and w.key == "textScale" and w.newTag and w.newTag:IsShown() then any = true end end
	check(not any, "nor beside Text Size")

	-- searching "new" (the tags themselves gone, as here, or not)
	P:SetQuery("new")
	local found = {}
	for kind, pool in pairs(P.pools) do
		for _, w in ipairs(pool) do
			if w:IsShown() then
				if w.key then found[w.key] = true end
				if kind == "head" and w.text then found[w.text.text] = true end
			end
		end
	end
	check(found.textScale and found.fontName and found.questFrame, "\"new\" finds Text Size, Font and Gold Frame for Quest Items")
	check(found["Special Bag Slot Indicators"] and found.glow_quiver, "and the Special Bag Slot Indicators card, whole")
	check(found["Shared Between Characters"], "and Shared Between Characters")
	check(not found.scale and not found.minimap, "but not settings that aren't new")
	P:SetQuery("")
	check((n.errors or 0) == 0, "no errors")

	-- an update from 1.7 is not a first install: the tags show
	package.loaded.mock = nil
	M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} }, whatsNewSeen = "1.7.5" }
	n = M.loadAddon("BagSmith")
	n.version = "1.8.0-beta19"
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	check(BagSmithDB.newSeen == nil or not next(BagSmithDB.newSeen["1.8"] or {}), "updating from 1.7.5: nothing marked seen")
	P = n.SettingsPanel
	P:Show()
	local look = false
	for _, b in ipairs(P.navButtons) do if b.page == "look" and b.newTag and b.newTag:IsShown() then look = true end end
	check(look, "so Style shows NEW")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- The fonts: a game font whose copies share it (as FlareUI found), Text Size at 150% and another face: the game's
	-- own font is never touched.
	local function fontObj(name, path, size, flags)
		local f = { name = name }
		function f:SetFont(p, s, fl)
			self.path, self.size, self.flags = p, s, fl
			if self.shared then self.shared.path, self.shared.size, self.shared.flags = p, s, fl end   -- the hazard
		end
		function f:GetFont() return self.path, self.size, self.flags end
		function f:CopyFontObject(o) self.path, self.size, self.flags = o:GetFont(); self.shared = o end
		function f:SetTextColor(r, g, b) self.color = { r, g, b } end
		function f:GetTextColor() return 1, 0.82, 0 end
		function f:SetShadowColor() end
		function f:GetShadowColor() return 0, 0, 0, 1 end
		function f:SetShadowOffset() end
		function f:GetShadowOffset() return 1, -1 end
		if path then f:SetFont(path, size, flags) end
		_G[name] = f
		return f
	end
	local oldCreate = _G.CreateFont
	_G.CreateFont = function(name) return fontObj(name) end
	local FRIZ = "Fonts\\FRIZQT__.TTF"
	local saved = {}
	for _, t in ipairs({ "GameFontHighlightSmall", "GameFontHighlight", "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontHighlightLarge", "GameFontNormalHuge" }) do
		saved[t] = _G[t]
		fontObj(t, FRIZ, 12, "")
	end
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { view = "list" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	ToggleAllBags(); M.runTimers()
	local F = n.Fonts
	local name = F:Name("GameFontHighlightSmall")
	local mine = _G[name]
	check(name == "BagSmithFont_GameFontHighlightSmall" and mine and mine.shared == nil, "BagSmith's font is its own: never a copy of the game's")
	n:Set("textScale", 1.5); M.runTimers()
	n:Set("fontName", "Inter"); M.runTimers()
	check(mine.size == 18, "Text Size 150%: BagSmith's text grows (" .. tostring(mine.size) .. ")")
	check(GameFontHighlightSmall.size == 12 and GameFontHighlightSmall.path == FRIZ, "the game's own font is untouched: " .. tostring(GameFontHighlightSmall.size) .. " " .. tostring(GameFontHighlightSmall.path))
	check(mine.color and mine.color[2] == 0.82, "its color is the game's")
	check((n.errors or 0) == 0, "no errors")
	_G.CreateFont = oldCreate
	for t, f in pairs(saved) do _G[t] = f end
end)()

;(function()
	-- (1.8.0-beta20, Shweep) /bs new reset brings Settings' NEW tags back too
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} }, whatsNewSeen = "1.8.0", newSeen = { ["1.8"] = { look = true, icons = true, profile = true } } }
	local n = M.loadAddon("BagSmith")
	n.version = "1.8.0-beta20"
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local P = n.SettingsPanel
	local function tag(page) for _, b in ipairs(P.navButtons) do if b.page == page then return b.newTag ~= nil and b.newTag:IsShown() end end end
	P:Show()
	check(not tag("look") and not tag("icons"), "(setup) all seen: no tags")
	SlashCmdList.BAGSMITH("new reset")
	check(BagSmithDB.newSeen["1.8"] == nil, "/bs new reset forgets the pages seen this release")
	check(tag("look") and tag("icons") and tag("profile"), "and with Settings open, the tags show at once")
	check(BagSmithDB.whatsNewSeen ~= "1.8.0", "What's New is reset as before")
	check((n.errors or 0) == 0, "no errors")
end)()
