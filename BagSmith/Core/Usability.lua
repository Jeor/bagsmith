-- Unmet character requirements, separate from cooldowns and other temporary restrictions.
local ADDON, ns = ...
local U = {}
ns.Usability = U
local cache, count, patterns = {}, 0, {}
local function plain(s)
	return type(s) == "string" and s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$") or ""
end
local function matches(text, fmt)
	if type(fmt) ~= "string" or fmt == "" then return false end
	local p = patterns[fmt]
	if not p then
		local s = plain(fmt):gsub("%%[%d]+%$[sd]", "\001"):gsub("%%[sd]", "\001")
		p = "^" .. s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"):gsub("\001", ".+") .. "$"
		patterns[fmt] = p
	end
	return text:match(p) ~= nil
end
local REQUIREMENTS = { "ITEM_MIN_LEVEL", "ITEM_LEVEL_RANGE_CURRENT", "ITEM_CLASSES_ALLOWED", "ITEM_RACES_ALLOWED",
	"RACE_CLASS_ONLY", "ITEM_MIN_SKILL", "ITEM_REQ_REPUTATION" }
local RESTRICTED = { "RestrictedRaceClass", "RestrictedFaction", "RestrictedSkill", "RestrictedPvPMedal", "RestrictedReputation", "RestrictedLevel" }
local function red(r, g, b)
	return type(r) == "number" and type(g) == "number" and type(b) == "number" and r > 0.7 and g < 0.3 and b < 0.3
end
local function redText(text, color)
	if color then
		local r, g, b = color.r, color.g, color.b
		if color.GetRGB then r, g, b = color:GetRGB() end
		if red(r, g, b) then return true end
	end
	for r, g, b in (text or ""):gmatch("|c%x%x(%x%x)(%x%x)(%x%x)") do
		if red(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255) then return true end
	end
	return false
end
local function unmet(text, color, rec)
	if type(text) ~= "string" or not redText(text, color) then return false end
	local s = plain(text)
	for _, key in ipairs(REQUIREMENTS) do if matches(s, _G[key]) then return true end end
	return (rec.classID == 2 or rec.classID == 4) and rec.itemSubType ~= nil and s == rec.itemSubType
end
local function unmetLine(line, rec)
	local types = Enum and Enum.TooltipDataLineType or {}
	for _, name in ipairs(RESTRICTED) do
		if types[name] ~= nil and line.type == types[name] then
			return redText(line.leftText, line.leftColor) or redText(line.rightText, line.rightColor)
		end
	end
	-- ITEM_REQ_SKILL is just "Requires %s": without a typed line that is ambiguous.
	return unmet(line.leftText, line.leftColor, rec) or unmet(line.rightText, line.rightColor, rec)
end
local scanTip
local function tooltip(rec)
	-- Hyperlinks describe the logged-in character even when viewing saved inventory.
	local link = rec.link or (rec.itemID and ("item:" .. rec.itemID))
	if not link then return nil end
	if C_TooltipInfo and C_TooltipInfo.GetHyperlink then return C_TooltipInfo.GetHyperlink(link) end
	if not scanTip then scanTip = CreateFrame("GameTooltip", "BagSmithUsabilityTooltip", UIParent, "GameTooltipTemplate") end
	if not (scanTip.SetHyperlink and scanTip.NumLines and scanTip.ClearLines) then return nil end
	scanTip:SetOwner(UIParent, "ANCHOR_NONE"); scanTip:ClearLines(); scanTip:SetHyperlink(link)
	local lines = {}
	for i = 1, scanTip:NumLines() do
		local line = {}
		for _, side in ipairs({ "Left", "Right" }) do
			local rgn = _G["BagSmithUsabilityTooltipText" .. side .. i]
			if rgn then
				local r, g, b = rgn:GetTextColor()
				line[side:lower() .. "Text"] = rgn:GetText()
				line[side:lower() .. "Color"] = { r = r, g = g, b = b }
			end
		end
		lines[#lines + 1] = line
	end
	scanTip:Hide()
	return { lines = lines }
end
function U:IsUnusable(rec)
	if not rec or rec.empty or rec.globalChild then return false end
	local c = rec.classID
	if c ~= 2 and c ~= 4 and c ~= 9 and c ~= 0 then
		-- Some edible reagents (raw fish on Forever) are Trade Goods. A real use
		-- spell makes them eligible; a category label alone does not tell us that.
		local ok, name, spellID = pcall(ns.ItemUseSpell, ns, rec.itemID)
		if not ok or not ((type(name) == "string" and name ~= "") or (type(spellID) == "number" and spellID > 0)) then return false end
	end
	local level = UnitLevel and UnitLevel("player")
	if type(level) == "number" and level > 0 and type(rec.minLevel) == "number" and rec.minLevel > level then return true end
	local key = rec.link or rec.itemID
	if not key then return false end
	if cache[key] ~= nil then return cache[key] end
	local ok, info = pcall(tooltip, rec)
	if scanTip then scanTip:Hide() end
	if not ok or type(info) ~= "table" or type(info.lines) ~= "table" or #info.lines == 0 then return false end
	local result, readable = false, 0
	local readOK = pcall(function()
		for _, line in ipairs(info.lines) do
			if plain(line.leftText) ~= "" or plain(line.rightText) ~= "" then readable = readable + 1 end
			if unmetLine(line, rec) then result = true; break end
		end
	end)
	if not readOK then return false end
	-- Empty/header-only tooltips are loading states, not evidence of met requirements.
	if not result and readable < 2 then return false end
	if count >= 2000 then cache, count = {}, 0 end
	cache[key], count = result, count + 1
	return result
end
function U:Decorate(b, rec)
	local show = ns.db and ns.db.unusableOverlay and self:IsUnusable(rec) or false
	if show and not b.unusableOverlay then
		-- Above the artwork, below OVERLAY borders, counts and corner marks.
		b.unusableOverlay = b:CreateTexture(nil, "ARTWORK", nil, 7)
		b.unusableOverlay:SetColorTexture(1, 0, 0, 0.25)
		b.unusableOverlay:SetAllPoints(b.icon)
	end
	if b.unusableOverlay then b.unusableOverlay:SetShown(show) end
end
function U:Invalidate() cache, count = {}, 0 end
function U:Refresh()
	local B = ns.Buttons
	if not B then return end
	local function each(b) self:Decorate(b, b.hasItem and b.rec or nil) end
	B:EachLive(each)
	for _, pool in pairs(B.cached) do for _, b in pairs(pool) do each(b) end end
end
local queued = false
local function changed()
	U:Invalidate()
	if queued then return end
	queued = true
	C_Timer.After(0, function() queued = false; U:Refresh() end)
end
ns:OnSignal("SETTINGS_CHANGED", function(key)
	if key == nil or key == "unusableOverlay" then U:Invalidate(); U:Refresh() end
end)
ns:OnSignal("ADDON_READY", function()
	for _, event in ipairs({ "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "SPELLS_CHANGED", "GET_ITEM_INFO_RECEIVED", "TOOLTIP_DATA_UPDATE", "PLAYER_ENTERING_WORLD", "UPDATE_FACTION" }) do ns:On(event, changed) end
end)
