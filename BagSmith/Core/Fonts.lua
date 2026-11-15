--[[
	BagSmith - Core/Fonts.lua (1.8.0)
	Text Size and Font for BagSmith's item windows: the bags, bank and bag windows and the Loot and Disenchant Helpers.
	Settings and What's New stay at the game's size (Shweep, 10 Nov).

	Each of the game's font templates those windows use gets a BagSmith copy (BagSmithFont_<template>, made from the
	game's on first use), and their text is created from the copy (ns.Fonts:Name). Text Size (ns.db.textScale, 80% to
	150%) scales the copies; Font (ns.db.fontName) swaps the typeface for one shared through LibSharedMedia. (1.8.0-beta2,
	Shweep) BagSmith bundles LibSharedMedia and shares three fonts of its own through it (Media/Fonts: Noto Sans, Roboto
	Condensed, Inter; SIL OFL), so they're in other addons' font lists too, and every font another addon shares is in
	BagSmith's. A font the client can't load (LibSharedMedia also lists the game's own, not all on every client) isn't
	offered, and a font that's no longer there falls back to the game's. Changing a font object updates every text made from it, so a change is live; windows lay out again to
	measure the new widths. The number fonts on item icons stay as they are: they're sized to the icon.
--]]

local ADDON, ns = ...
local Fonts = {}
ns.Fonts = Fonts

Fonts.MIN, Fonts.MAX = 0.8, 1.5
Fonts.TEMPLATES = {
	GameFontHighlightSmall = true, GameFontHighlight = true, GameFontHighlightLarge = true,
	GameFontNormal = true, GameFontNormalSmall = true, GameFontNormalLarge = true, GameFontNormalHuge = true,
}
local base = {}   -- template -> { path, size, flags } as the game made it

-- (1.8.0-beta2) BagSmith's own fonts, shared through LibSharedMedia (western clients: they're cut to Latin characters)
local MEDIA = "Interface\\AddOns\\BagSmith\\Media\\Fonts\\"
Fonts.OWN = {
	{ "Noto Sans", MEDIA .. "NotoSans-Regular.ttf" },
	{ "Roboto Condensed", MEDIA .. "RobotoCondensed-Regular.ttf" },
	{ "Inter", MEDIA .. "Inter-Regular.ttf" },
}

local function lsm()
	if type(LibStub) ~= "table" and type(LibStub) ~= "function" then return nil end
	local ok, lib = pcall(LibStub, "LibSharedMedia-3.0", true)
	return ok and lib or nil
end
do
	local lib = lsm()
	if lib and lib.Register then
		local western = lib.LOCALE_BIT_western or 128
		for _, f in ipairs(Fonts.OWN) do pcall(lib.Register, lib, "font", f[1], f[2], western) end
	end
end

-- (1.8.0-beta2) Whether the client can load a font file: a scratch text is set to it and asked what it got (a file that
-- isn't there leaves the text as it was). Remembered per file. A client that can't be asked takes the file as usable.
local usable, probe = {}, nil
local function norm(p) return (tostring(p or "")):lower():gsub("/", "\\") end
function Fonts:Usable(path)
	if type(path) ~= "string" or path == "" then return false end
	if usable[path] ~= nil then return usable[path] end
	if not probe and UIParent and UIParent.CreateFontString then probe = UIParent:CreateFontString(nil, "OVERLAY"); if probe.Hide then probe:Hide() end end
	if not (probe and probe.SetFont and probe.GetFont) then return true end
	local fallback = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	if norm(path) == norm(fallback) then usable[path] = true; return true end
	pcall(probe.SetFont, probe, fallback, 12, "")
	local ok, res = pcall(probe.SetFont, probe, path, 12, "")
	local got = probe:GetFont()
	usable[path] = ok and res ~= false and norm(got) == norm(path)
	return usable[path]
end

function Fonts:Scale()
	local v = tonumber(ns.db and ns.db.textScale) or 1
	if v < self.MIN then v = self.MIN elseif v > self.MAX then v = self.MAX end
	return v
end

-- The chosen typeface's file, or nil for the game's own (none chosen, or it isn't there any more).
function Fonts:Path()
	local name = ns.db and ns.db.fontName
	if type(name) ~= "string" or name == "" then return nil end
	local lib = lsm()
	if not (lib and lib.Fetch) then return nil end
	local ok, path = pcall(lib.Fetch, lib, "font", name, true)
	path = ok and type(path) == "string" and path ~= "" and path or nil
	return path and self:Usable(path) and path or nil
end

-- The choices for the Font setting: the game's font first, then every font another addon shares, by name.
function Fonts:Choices()
	local out = { { key = "", label = "Game Font" } }
	local lib = lsm()
	if lib and lib.List then
		local ok, list = pcall(lib.List, lib, "font")
		if ok and type(list) == "table" then
			for _, name in ipairs(list) do
				if type(name) == "string" and name ~= "" and self:PathOf(name) then out[#out + 1] = { key = name, label = name } end
			end
		end
	end
	return out
end
-- A font's file by its choice key (for showing each name in its own face); nil for the game's.
function Fonts:PathOf(key)
	if type(key) ~= "string" or key == "" then return nil end
	local lib = lsm()
	if not (lib and lib.Fetch) then return nil end
	local ok, path = pcall(lib.Fetch, lib, "font", key, true)
	path = ok and type(path) == "string" and path ~= "" and path or nil
	return path and self:Usable(path) and path or nil
end

local function apply(template)
	local b = base[template]
	local f = _G["BagSmithFont_" .. template]
	if not (b and f and f.SetFont) then return end
	local size = math.max(6, math.floor(b[2] * Fonts:Scale() + 0.5))
	local ok = pcall(f.SetFont, f, Fonts:Path() or b[1], size, b[3] or "")
	if not ok then pcall(f.SetFont, f, b[1], size, b[3] or "") end   -- (a file the game can't read: the game's face)
end

-- The BagSmith copy of one of the game's templates, made on first use; the template itself when a copy can't be made.
function Fonts:Name(template)
	if not self.TEMPLATES[template] then return template end
	local name = "BagSmithFont_" .. template
	if base[template] then return name end
	local game = _G[template]
	if not (game and game.GetFont and type(CreateFont) == "function") then return template end
	local path, size, flags = game:GetFont()
	if not (path and size) then return template end
	local f = _G[name] or CreateFont(name)
	if f.CopyFontObject then pcall(f.CopyFontObject, f, game)
	else
		if game.GetTextColor and f.SetTextColor then f:SetTextColor(game:GetTextColor()) end
		if game.GetShadowColor and f.SetShadowColor then f:SetShadowColor(game:GetShadowColor()) end
		if game.GetShadowOffset and f.SetShadowOffset then f:SetShadowOffset(game:GetShadowOffset()) end
	end
	base[template] = { path, size, flags }
	apply(template)
	return name
end

-- A size in pixels at the current Text Size (for text set to a fixed size, like the Disenchant Helper's small lines).
function Fonts:Px(px) return math.max(6, math.floor((px or 10) * self:Scale() + 0.5)) end
-- A height that holds text: grows with Text Size above 100%, never shrinks below its own size.
function Fonts:Grow(px) return math.floor((px or 0) * math.max(1, self:Scale()) + 0.5) end
-- The file and flags of a BagSmith copy (for text set to its own size in the same face).
function Fonts:Face(template)
	local name = self:Name(template)
	local f = _G[name]
	if f and f.GetFont then local path, _, flags = f:GetFont(); return path, flags end
	return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", ""
end
-- The height a List row needs for its text: the row font's size and 10 px of air (20 at 100%, under every Row Height).
function Fonts:RowNeed()
	local b = base.GameFontHighlightSmall
	return math.floor((b and b[2] or 10) * self:Scale() + 0.5) + 10
end

function Fonts:Apply()
	for template in pairs(base) do apply(template) end
	ns:Fire("FONTS_CHANGED")
end

ns:OnSignal("SETTINGS_CHANGED", function(key)
	if key == nil or key == "textScale" or key == "fontName" then Fonts:Apply() end
end)
-- the saved settings are read (or another profile is in force): copies made before then take the settings now
ns:OnSignal("PROFILE_ACTIVATED", function() Fonts:Apply() end)
-- a change: the bags, bank and bag windows lay out again (widths measured anew), the helpers repaint
ns:OnSignal("FONTS_CHANGED", function()
	if not ns.ready then return end
	if ns.RefreshViews then ns:RefreshViews(true) end
	local DE = ns.Disenchant
	if DE and DE.frame and DE.frame:IsShown() then DE:Layout(); if DE.Paint then DE:Paint() end end
	local MR = ns.MakeRoom
	if MR and MR.frame and MR.frame:IsShown() and MR.Refresh then MR:Refresh() end
end)
