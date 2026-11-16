;(function()
	-- ======== 1.9.0-beta3 (Shweep's beta2 feedback) ========
	-- No character picker in Global Inventory (it already shows every character). The picker shows a surname as its
	-- initial only when the full name doesn't fit.
	package.loaded.mock = nil
	local M = require("mock")
	M.charName = "Aldren Thorne"
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	V.charBtn:SetWidth(170); V:FitPickerName()
	check(V.charBtn.label.text == "Aldren Thorne", "a wide picker: the full name (" .. tostring(V.charBtn.label.text) .. ")")
	V.charBtn:SetWidth(100); V:FitPickerName()
	check(V.charBtn.label.text == "Aldren T.", "a narrow one: the surname's initial (" .. tostring(V.charBtn.label.text) .. ")")
	V.charBtn:SetWidth(170); V:FitPickerName()
	check(V.charBtn.label.text == "Aldren Thorne", "wide again: the full name again")
	check(V.charBtn:IsShown(), "(setup) the picker shows in your bags")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(n.ui.global and not V.charBtn:IsShown(), "Global Inventory: no picker")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(not n.ui.global and V.charBtn:IsShown(), "back to your bags: the picker again")
	check((n.errors or 0) == 0, "no errors")
end)()
