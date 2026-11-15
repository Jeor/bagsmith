;(function()
	-- ======== 1.8.0-beta12 (Shweep): click the gold to open the currency drawer; the reagent count's tooltip ========
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local main = n.Window.main
	check(main.moneyButton and main.moneyButton:GetScript("OnClick"), "the gold is a button")
	local function open() return n.Drawer.frame and n.Drawer.frame:IsShown() and true or false end
	check(not open(), "(setup) the currency drawer is closed")
	main.moneyButton:GetScript("OnClick")(main.moneyButton, "LeftButton"); M.runTimers()
	check(open(), "clicking the gold opens the currency drawer")
	main.moneyButton:GetScript("OnClick")(main.moneyButton, "LeftButton"); M.runTimers()
	check(not open(), "and clicking again closes it")
	GameTooltip.lines = {}
	main.moneyButton:GetScript("OnEnter")(main.moneyButton)
	local gl = table.concat(GameTooltip.lines or {}, " | ")
	check(GameTooltip.shown and gl:find("currency drawer", 1, true), "hovering the gold says so: " .. gl)
	-- the reagent count shows the same breakdown as the bags count
	n:RefreshViews(true); M.runTimers()
	GameTooltip.lines = {}; GameTooltip.shown = false
	main.btnReagent:GetScript("OnEnter")(main.btnReagent)
	local tl = table.concat(GameTooltip.lines or {}, " | ")
	check(GameTooltip.shown and tl:find("Bags (anything fits)", 1, true) and tl:find("Reagent Bag", 1, true), "hovering the reagent count: the free-slot breakdown: " .. tl)
	check(n.Window.bank == nil or n.Window.bank.moneyButton == nil, "the bank window's gold stays plain (the drawer belongs to the bags window)")
	check((n.errors or 0) == 0, "no errors")
end)()
