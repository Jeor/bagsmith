-- ======== 1.9.0-beta21 (Shweep, 17 Nov) ========
-- "will expressway show up if another addon loads it in?" In the list, yes; but a saved choice of a font another addon
-- shares after BagSmith has loaded (most load after it) stayed the game's face until a font setting changed. Now the
-- chosen font goes on as LibSharedMedia says it's shared, and once more at login.

local EXPRESSWAY = "Interface\\AddOns\\ElvUI\\Media\\Fonts\\Expressway.ttf"
local function boot(fontName)
	package.loaded.mock = nil
	local M = require("mock")
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
	_G.C_UIFileAsset = { IsKnownFile = function() return true end }
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { fontName = fontName } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.runTimers()
	local applied = 0
	local apply = n.Fonts.Apply
	n.Fonts.Apply = function(...) applied = applied + 1; return apply(...) end
	local function restore()
		_G.CreateFont = saved.create; _G.C_UIFileAsset = nil
		for t, f in pairs(saved) do if t ~= "create" then _G[t] = f end end
	end
	return n, M, function() return applied end, restore
end
local function item() return _G.BagSmithFont_GameFontHighlightSmall and (_G.BagSmithFont_GameFontHighlightSmall:GetFont()) end
local function header() return _G.BagSmithFaceFont_GameFontHighlightSmall and (_G.BagSmithFaceFont_GameFontHighlightSmall:GetFont()) end

;(function()
	-- Expressway saved; ElvUI (loading after BagSmith) shares it
	local n, M, applied, restore = boot("Expressway")
	n.Window:Show(); M.runTimers()
	check(item() == "Fonts\\FRIZQT__.TTF", "(as BagSmith loads, Expressway isn't shared yet: the game's face for now)")
	local LSM = LibStub("LibSharedMedia-3.0")
	LSM:Register("font", "Expressway", EXPRESSWAY)
	check(item() == EXPRESSWAY, "shared: the item text goes to Expressway at once (" .. tostring(item()) .. ")")
	check(header() == EXPRESSWAY, "and the header's buttons")
	-- another addon's font: nothing to do
	local before = applied()
	LSM:Register("font", "Some Other Font", "Interface\\AddOns\\Other\\other.ttf")
	LSM:Register("statusbar", "Expressway", "Interface\\AddOns\\Other\\bar.tga")
	check(applied() == before, "another font, or a bar texture of the same name: left alone")
	M.fire("PLAYER_LOGIN"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	check(item() == EXPRESSWAY, "after login: still Expressway")
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()

;(function()
	-- a load-on-demand addon shares it after login
	local n, M, applied, restore = boot("Expressway")
	M.fire("PLAYER_LOGIN"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers()
	check(item() == "Fonts\\FRIZQT__.TTF", "(not shared by login: the game's face)")
	LibStub("LibSharedMedia-3.0"):Register("font", "Expressway", EXPRESSWAY)
	M.runTimers()
	check(item() == EXPRESSWAY, "shared later: on as it arrives")
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()

;(function()
	-- a font put in LibSharedMedia's table without its notice (an addon's own older copy): login puts it on
	local n, M, applied, restore = boot("Expressway")
	local LSM = LibStub("LibSharedMedia-3.0")
	LSM.MediaTable.font["Expressway"] = EXPRESSWAY
	check(item() == "Fonts\\FRIZQT__.TTF", "(no notice: the game's face for now)")
	M.fire("PLAYER_LOGIN"); M.runTimers()
	check(item() == EXPRESSWAY, "at login, with every addon loaded: Expressway")
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()

;(function()
	-- no font chosen: login and newly shared fonts change nothing
	local n, M, applied, restore = boot("")
	local before = applied()
	M.fire("PLAYER_LOGIN"); M.runTimers()
	LibStub("LibSharedMedia-3.0"):Register("font", "Expressway", EXPRESSWAY)
	check(applied() == before and item() == "Fonts\\FRIZQT__.TTF", "Default Font: nothing applied again, the game's face")
	check((n.errors or 0) == 0, "no errors")
	restore()
end)()
