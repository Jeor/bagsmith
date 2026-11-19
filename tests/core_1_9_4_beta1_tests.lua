-- ======== 1.9.4-beta1 (Shweep, 19 Nov) ========
-- "Icon View Compact Mode is not showing AH and V in the section headers - prob would use the coin version tho due to
-- space issues": in Compact View every section header shows the small coin (1.7.0-beta10's, the other views' last
-- format), hover or click for that section's V and AH. Its room is part of the section's minimum width, so a long name
-- is never cut short for it. Recent, an empty custom section and a gear set's note keep what they had.

local function boot(skin, extra)
	package.loaded.mock = nil
	local M = require("mock")
	M.sizes[0] = 40
	for s = 1, 20 do
		local class = s == 1 and 15 or (s <= 12 and 0 or 7)
		M.put(0, s, { id = 81000 + s, name = "Sample " .. s, q = 1, class = class, subclass = 0, price = 12 })
	end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local prof = { skin = skin, view = "icons", grp = "type", sizeMode = "fixed", fixW = 720, recentSection = false, mergeStacks = false, compactCategories = true }
	for k, v in pairs(extra or {}) do prof[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = prof } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	n.Window.main.frame.IsMouseOver = function() return false end
	return n, M, n.Window.main
end
local function headers(V)
	local out = {}
	for _, h in ipairs(V.used) do if h.laneId and h.text and h:IsShown() then out[#out + 1] = h end end
	return out
end
local function coinShown(h) return h.valCoin and h.valCoin:IsShown() or false end

for _, skin in ipairs({ "modern", "classic" }) do
	local S = skin .. ": "
	local n, M, V = boot(skin)
	check(V.compactCategories == true, S .. "(setup) Compact View")
	local hs = headers(V)
	check(#hs >= 3, S .. "(setup) " .. #hs .. " sections")
	local bad, overlap, cut = {}, {}, {}
	for _, h in ipairs(hs) do
		if not coinShown(h) or h.sub:IsShown() or h.vAmt:IsShown() then bad[#bad + 1] = tostring(h.laneId) end
		local p = h.valCoin and h.valCoin.points and h.valCoin.points[1]
		if not (p and p[1] == "RIGHT" and (p[2] == -4 or p[4] == -4)) then bad[#bad + 1] = tostring(h.laneId) .. "@" end
		-- the name and count end before the coin begins
		local used = 20 + h.text:GetStringWidth() + 6 + h.count:GetStringWidth() + 4
		if used + 14 + 4 > h:GetWidth() then overlap[#overlap + 1] = ("%s %d/%d"):format(tostring(h.laneId), used + 18, h:GetWidth()) end
		if h.compactTitle then cut[#cut + 1] = tostring(h.laneId) end
	end
	check(#bad == 0, S .. "every section header shows the coin at its right edge, nothing else" .. (#bad > 0 and (": " .. table.concat(bad, ", ")) or ""))
	check(#overlap == 0, S .. "the name and count never reach the coin" .. (#overlap > 0 and (": " .. table.concat(overlap, ", ")) or ""))
	check(#cut == 0, S .. "no name cut short for it" .. (#cut > 0 and (": " .. table.concat(cut, ", ")) or ""))
	-- hover and click: the section's name and V
	local h = hs[1]
	GameTooltip:Hide(); GameTooltip.lines = {}
	h.valCoin.scripts.OnEnter(h.valCoin)
	local text = table.concat(GameTooltip.lines or {}, " | ")
	-- (the mock keeps no tooltip title: SetText does nothing; the section's name is the coin's title, as in 1.7.0)
	check(GameTooltip.shown and GameTooltip.owner == h.valCoin and text:find("V: ", 1, true), S .. "hover the coin: its tooltip, with the section's V (" .. text .. ")")
	GameTooltip:Hide(); GameTooltip.lines = {}
	h.valCoin.scripts.OnClick(h.valCoin, "LeftButton")
	check(GameTooltip.shown and table.concat(GameTooltip.lines or {}, " "):find("V: ", 1, true), S .. "click: the same")
	check(h.valCoin.v == h.compactValues.v, S .. "the coin's V is the section's (" .. tostring(h.valCoin.v) .. ")")
	-- the section's name still shows its values on hover
	GameTooltip:Hide(); GameTooltip.lines = {}
	h.scripts.OnEnter(h)
	check(GameTooltip.shown and table.concat(GameTooltip.lines or {}, " "):find("V:", 1, true), S .. "hovering the name still shows them")
	-- collapsed: still there
	V:ToggleLane(h.laneId); M.runTimers()
	local folded
	for _, x in ipairs(headers(V)) do if x.laneId == h.laneId then folded = x end end
	check(folded and coinShown(folded), S .. "a collapsed section keeps its coin")
	V:ToggleLane(h.laneId); M.runTimers()
	-- back to Full Width: the one-line values again, no coin left over on the pooled headers
	n:Set("compactCategories", false); M.runTimers()
	local left = 0
	for _, x in ipairs(headers(V)) do if coinShown(x) then left = left + 1 end end
	local first = headers(V)[1]
	check(left == 0 and first.sub:IsShown() and first.sub:GetText():find("V: ", 1, true), S .. "Full Width: \"V: ...\" on one line, no coin left over")
	check((n.errors or 0) == 0, S .. "no errors")
end

;(function()
	-- Recent keeps its words and button, no coin
	local n, M, V = boot("modern")
	n.RecentRecords = function() return { n.items[1] } end
	n:Set("recentSection", true); n:Set("splitViewRecentWide", false); M.runTimers()
	local recent
	for _, h in ipairs(headers(V)) do if h.laneId == "~recent" then recent = h end end
	check(recent ~= nil, "(setup) a Recent section, sharing a row")
	check(recent and not coinShown(recent), "Recent: no coin")
	check(recent and recent.clearRecent and recent.clearRecent:IsShown(), "Recent keeps Clear Recent")
	local others = 0
	for _, h in ipairs(headers(V)) do if h.laneId ~= "~recent" and coinShown(h) then others = others + 1 end end
	check(others >= 3, "the other sections keep theirs (" .. others .. ")")
	check((n.errors or 0) == 0, "no errors")
end)()
