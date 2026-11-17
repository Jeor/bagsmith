-- ======== 1.9.1-beta1 (Shweep, 17 Nov) ========
-- "In bank window mousing over the gold in corner should display same tool tip as main bag w/ gold across ruleset",
-- "in main bagsmith window when mousing over pinned currencies you should be able to see counts for others in tooltip,
-- like in global inv", and "yes to showing both places" (the currency drawer's rows in your own bags too).

local function boot()
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 16, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, profiles = { Default = { view = "list", customCurrencies = { 2589 } } }, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20, gold = 500000,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 2, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" } }, bank = {},
			currencies = { ["c:1901"] = { id = 1901, name = "Honor", icon = 8, count = 300 } } },
	} }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	return n, M
end
local function tipText() return table.concat(GameTooltip.lines or {}, " | ") end

;(function()
	-- the bank window's gold: the bags' tooltip
	local n, M = boot()
	M.fire("BANKFRAME_OPENED"); M.runTimers(); M.runTimers()
	local bank = n.Window.bank
	local mb = bank and bank.moneyButton
	check(mb ~= nil, "the bank window's gold can be hovered")
	GameTooltip.lines = {}
	mb:GetScript("OnEnter")(mb)
	local g = tipText()
	check(g:find("Realm-wide gold", 1, true) and g:find("Brannoc", 1, true) and g:find("500000c", 1, true), "its tooltip: this ruleset's gold, each character's: " .. g)
	check(not g:find("currency drawer", 1, true), "no \"click for the currency drawer\" line (that's the bags' gold)")
	check(n.Inventory.goldOwner == mb, "Shift follows it live, as on the bags' gold")
	local opened = false
	local toggle = n.Drawer.Toggle
	n.Drawer.Toggle = function() opened = true end
	if mb:GetScript("OnClick") then mb:GetScript("OnClick")(mb) end
	n.Drawer.Toggle = toggle
	check(not opened, "clicking it opens nothing")
	mb:GetScript("OnLeave")(mb)
	check(n.Inventory.goldOwner == nil, "and lets go when the mouse leaves")
	-- the bags' gold as before
	n.Window:Show(); M.runTimers()
	local mm = n.Window.main.moneyButton
	GameTooltip.lines = {}
	mm:GetScript("OnEnter")(mm)
	check(tipText():find("Realm-wide gold", 1, true), "the bags' gold: unchanged")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- your own bags: pinned currencies and the drawer say who has how many
	local n, M = boot()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local C = n.Currency
	-- Honor: your 1250 (the client's wallet) and Brannoc's 300 (his saved wallet)
	local per, total = C:Breakdown("c:1901")
	check(per and #per == 2 and per[1].count == 1250 and per[2].name == "Brannoc" and per[2].count == 300 and total == 1550, "Honor: you first, then Brannoc, and the total (1550)")
	local lper, ltotal = C:Breakdown("i:2589")
	check(lper and #lper == 2 and ltotal == 18 and lper[2].count == 2, "Linen Cloth: your 16 and Brannoc's 2 from his saved bags: 18")
	-- pinned in the footer
	C:ToggleFavorite("i:2589"); n:RefreshViews(true); M.runTimers()
	local chip
	for _, c in ipairs(V.favChips or {}) do if c:IsShown() and c.key == "i:2589" then chip = c end end
	check(chip ~= nil and chip.total == 16, "(setup) Linen Cloth pinned in your footer, with your own 16")
	GameTooltip.lines = {}
	chip:GetScript("OnEnter")(chip)
	local t = tipText()
	check(t:find("Total: 18", 1, true) and t:find("Brannoc", 1, true) and t:find("2", 1, true), "its tooltip: each character's count and the total: " .. t)
	-- a currency only you have (Merchant's Favor): as before, your count alone
	check(C:Breakdown("c:3402") == nil, "Merchant's Favor, only yours: no breakdown")
	C:ToggleFavorite("c:3402"); n:RefreshViews(true); M.runTimers()
	local fav
	for _, c in ipairs(V.favChips or {}) do if c:IsShown() and c.key == "c:3402" then fav = c end end
	GameTooltip.lines = {}
	if fav then fav:GetScript("OnEnter")(fav) end
	t = tipText()
	check(fav and t:find("Merchant's Favor", 1, true) and t:find("85", 1, true) and not t:find("Total", 1, true), "its tooltip: your count, as before: " .. t)
	check(C:Breakdown("c:999") == nil, "a currency nobody has: nothing")
	-- the drawer's rows
	local D = n.Drawer
	D:Show(); M.runTimers()
	local row
	for _, r in ipairs(D.frame.rows) do if r:IsShown() and r.key == "i:2589" then row = r end end
	check(row and not row.kids, "(setup) Linen Cloth in your drawer, no arrow (the arrows are Global Inventory's)")
	GameTooltip.lines = {}
	row:GetScript("OnEnter")(row)
	t = tipText()
	check(t:find("Total: 18", 1, true) and t:find("Brannoc", 1, true), "its row's tooltip: who has how many: " .. t)
	D:Hide()
	check((n.errors or 0) == 0, "no errors")
end)()
