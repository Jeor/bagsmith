-- ======== 1.9.0-beta13 (Shweep, 17 Nov) ========
-- "when you click Global can we pre-expand the window size for the player to better fit the content and then leaving
-- it bring it back to what they had? They should still be able to resize Global Inv themself after swapping to it.
-- and this can be a setting (Windows) default true"; "approx as tall as settings is, maybe a tad more"; "you can go
-- 750 for width of global".
local function boot(prof, globalInv)
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	local p = { sizeMode = "fixed", fixW = 620, fixH = 560, view = "list" }
	for k, v in pairs(prof or {}) do p[k] = v end
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = p }, globalInv = globalInv }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	return n, M, n.Window.main
end
local function size(V) return V.frame:GetWidth(), V.frame:GetHeight() end
local function globe(V, M) V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers() end

;(function()
	local n, M, V = boot()
	check(n.db.globalResize == true, "Resize for Global Inventory: on by default")
	local w, h = size(V)
	check(w == 620 and h == 560, "(setup) your bags: 620 by 560")
	globe(V, M)
	w, h = size(V)
	check(w == 750 and h == 620, "Global Inventory opens 750 by 620: " .. w .. " by " .. h)
	-- resized there: its own size, never your bags'
	V.frame:SetSize(820, 680)
	V.grip:GetScript("OnMouseUp")(V.grip); M.runTimers()
	local G = n.Inventory:Settings()
	check(G.w == 820 and G.h == 680 and n.db.fixW == 620 and n.db.fixH == 560, "resized there: saved as Global Inventory's (820 by 680); your bags' size untouched")
	globe(V, M)
	w, h = size(V)
	check(w == 620 and h == 560 and n.ui.global == nil, "leaving: your size back, 620 by 560")
	globe(V, M)
	w, h = size(V)
	check(w == 820 and h == 680, "back in: the size you gave it")
	-- closing BagSmith leaves it too
	V:Hide(); M.runTimers(); V:Show(); M.runTimers()
	w, h = size(V)
	check(w == 620 and h == 560, "closing BagSmith: your size again")
	-- off: Global Inventory uses your bags' size
	n:Set("globalResize", false); M.runTimers()
	globe(V, M)
	w, h = size(V)
	check(w == 620 and h == 560, "turned off: Global Inventory keeps your size")
	n:Set("globalResize", true); M.runTimers()
	w, h = size(V)
	check(w == 820 and h == 680, "turned on while it shows: its size at once")
	globe(V, M)
	-- Settings > Windows
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("window")
	local found
	for _, c in ipairs(P.pools.check) do if c:IsShown() and c.key == "globalResize" then found = c end end
	-- (by design since 1.9.0-beta14: Shweep's name for it)
	check(found and found.text.text == "Global Inventory: Custom Window Size" and found.box:GetChecked(), "Settings > Windows: Global Inventory: Custom Window Size, ticked")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- a window wider than 750 stays as wide; Fit to Items: its size is the largest
	local n, M, V = boot({ fixW = 900, fixH = 700 })
	globe(V, M)
	local w, h = size(V)
	-- (by design since 1.9.0-beta14: Width and Height in Settings decide, so a wider window no longer keeps its width)
	check(w == 750 and h == 620, "a window wider than 750: Global Inventory is still 750 by 620, as Settings shows")
	n, M, V = boot({ sizeMode = "auto", maxW = 620, maxH = 560 })
	globe(V, M)
	w, h = size(V)
	check(w == 750 and h <= 620, "Fit to Items: 750 wide, at most 620 tall (" .. h .. ")")
	globe(V, M)
	w = size(V)
	check(w == 620, "and back to 620")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- in combat: it waits for combat's end
	local n, M, V = boot()
	M.combat = true; M.fire("PLAYER_REGEN_DISABLED"); M.runTimers()
	globe(V, M)
	local w = size(V)
	check(n.ui.global and w == 620, "opened in combat: Global Inventory, at your size for now")
	M.combat = false; M.fire("PLAYER_REGEN_ENABLED"); M.runTimers(); M.runTimers()
	w = size(V)
	check(w == 750, "combat over: 750 wide")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- saved: a size out of range is dropped at load
	local n, M, V = boot(nil, { w = 5000, h = 100 })
	local G = n.Inventory:Settings()
	check(G.w == nil and G.h == nil, "a saved size out of range is dropped")
	globe(V, M)
	local w, h = size(V)
	check(w == 750 and h == 620, "and it opens at 750 by 620")
	check((n.errors or 0) == 0, "no errors")
end)()
