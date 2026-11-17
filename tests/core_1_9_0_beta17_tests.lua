;(function()
	-- ======== 1.9.0-beta17 (Shweep, 17 Nov) ========
	-- "In Global Inventory 'By Bag' needs to be disabled / greyed out and needs tooltip": the Sections buttons and the
	-- narrow window's Sections menu. Menus gain a tip on hover, greyed entries included.
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { grp = "bag", view = "list" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	local byBag
	for _, b in ipairs(V.grpSegBtns or {}) do if b.value == "bag" then byBag = b end end
	check(byBag and byBag:IsEnabled() and byBag.active, "(setup) your bags: By Bag, chosen and usable")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(not byBag:IsEnabled() and byBag:GetAlpha() < 1 and not byBag.active, "Global Inventory: By Bag greyed out (and not the one shown)")
	for _, b in ipairs(V.grpSegBtns) do
		if b.value ~= "bag" then check(b:IsEnabled(), "All and By Section stay usable: " .. b.value) end
	end
	GameTooltip.lines = {}
	local ran = M.enter(byBag)
	local tip = table.concat(GameTooltip.lines or {}, " | ")
	check(ran and tip:find(n.View.GLOBAL_OFF, 1, true) and tip:find("groups items by section", 1, true), "its tooltip says so and why: " .. tip)
	-- the narrow window's menu
	local items
	local show = n.ShowMenu
	n.ShowMenu = function(it, anchor, keep) items = it; return show(it, anchor, keep) end
	V.btnGrpMenu:GetScript("OnClick")(V.btnGrpMenu)
	local entry
	for _, it in ipairs(items or {}) do if it.text == "By Bag" then entry = it end end
	check(entry and entry.disabled and entry.tipNote == n.View.GLOBAL_OFF and entry.tip and entry.tip:find("by section", 1, true), "the Sections menu: By Bag greyed, with the same tip")
	local row
	for _, r in ipairs(n.menuFrame and n.menuFrame.rows or {}) do if r:IsShown() and r.text.text == "By Bag" then row = r end end
	GameTooltip.lines = {}
	if row then row:GetScript("OnEnter")(row) end
	tip = table.concat(GameTooltip.lines or {}, " | ")
	check(row and tip:find(n.View.GLOBAL_OFF, 1, true), "hovering it shows the tip: " .. tip)
	local was = n.db.grp
	row:GetScript("OnClick")(row); M.runTimers()
	check(n.menuFrame:IsShown() and n.db.grp == was and n.Inventory:Settings().grp ~= "bag", "clicking it does nothing (the menu stays open)")
	n.menuFrame:Hide()
	n.ShowMenu = show
	-- leaving: usable again, your choice as it was
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(byBag:IsEnabled() and byBag:GetAlpha() == 1 and byBag.active and n.db.grp == "bag", "leaving: By Bag usable again, still your choice")
	check((n.errors or 0) == 0, "no errors")
end)()
