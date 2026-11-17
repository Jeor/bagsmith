;(function()
	-- ======== 1.9.0-beta14 (Shweep, 17 Nov) ========
	-- The setting in Shweep's words ("Global Inventory: Custom Window Size"), and "preset width and height as sub-settings
	-- if checked but let players change it".
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { sizeMode = "fixed", fixW = 620, fixH = 560, view = "list" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("window")
	local function rows()
		local c, w, h
		for _, x in ipairs(P.pools.check) do if x:IsShown() and x.key == "globalResize" then c = x end end
		for _, x in ipairs(P.pools.step) do if x:IsShown() and x.key == "__globalW" then w = x end; if x:IsShown() and x.key == "__globalH" then h = x end end
		return c, w, h
	end
	local c, w, h = rows()
	check(c and c.text.text == "Global Inventory: Custom Window Size", "the name: " .. tostring(c and c.text.text))
	check(c and c.help.text == "Opens Global Inventory in a custom window size, then puts your bags back to their previous size when you leave Global Inventory.", "the help, word for word")
	check(w and h and w.text.text == "Width" and h.text.text == "Height", "Width and Height under it")
	check(w.value.text == "750" and h.value.text == "620", "preset: 750 and 620")
	check(w.points[1][4] > c.points[1][4], "indented under it")
	check(w.plus:IsEnabled() and w.value:IsEnabled(), "usable while it's ticked")
	-- changed in Settings: Global Inventory's size, at once when it shows
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	c, w, h = rows()
	w.plus:GetScript("OnClick")(w.plus); M.runTimers()
	local G = n.Inventory:Settings()
	check(G.w == 770 and V.frame:GetWidth() == 770, "Width +20: 770, and the open Global Inventory follows")
	c, w, h = rows()
	h.value:SetText("2000"); h.value:GetScript("OnEnterPressed")(h.value); M.runTimers()
	check(G.h == 1200 and V.frame:GetHeight() == 1200, "a height past the limit: 1200")
	h.value:SetText("640"); h.value:GetScript("OnEnterPressed")(h.value); M.runTimers()
	check(G.h == 640 and n.db.fixW == 620 and n.db.fixH == 560, "640; your bags' size untouched")
	-- a drag in Global Inventory shows in them
	V.frame:SetSize(860, 700)
	V.grip:GetScript("OnMouseUp")(V.grip); M.runTimers()
	c, w, h = rows()
	check(G.w == 860 and w.value.text == "860" and h.value.text == "700", "dragging the corner there: Width and Height show it")
	-- unticked: greyed, fixed
	c.box:SetChecked(false); c.box:GetScript("OnClick")(c.box); M.runTimers()
	c, w, h = rows()
	check(n.db.globalResize == false and not w.plus:IsEnabled() and not w.minus:IsEnabled() and not w.value:IsEnabled() and w.plus:GetAlpha() < 1,
		"unticked: Width and Height greyed out")
	check(w.value.text == "860", "still showing the size it would use")
	check(V.frame:GetWidth() == 620, "and Global Inventory uses your bags' size")
	c.box:SetChecked(true); c.box:GetScript("OnClick")(c.box); M.runTimers()
	check(V.frame:GetWidth() == 860, "ticked again: its own size")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(V.frame:GetWidth() == 620 and V.frame:GetHeight() == 560, "leaving: your size back")
	check((n.errors or 0) == 0, "no errors")
	-- kept for the account
	local saved = BagSmithDB
	package.loaded.mock = nil
	M = require("mock")
	_G.BagSmithDB = saved; _G.BagSmithCharDB = { version = 1, firstSeen = {} }
	n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	G = n.Inventory:Settings()
	check(G.w == 860 and G.h == 700, "after a reload: 860 by 700")
	check((n.errors or 0) == 0, "no errors after the reload")
end)()
