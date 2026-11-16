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

;(function()
	-- The accordion (Shweep): an item more than one character has opens into a row per character, right under it, each
	-- with the class icon then the name first, indented. No item menu in Global Inventory.
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	M.put(0, 2, { id = 4306, name = "Silk Cloth", q = 1, count = 2, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 150 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, profiles = { Default = { itemMenuButton = true } }, cache = {
		["Brannoc - Forever"] = { name = "Brannoc", realm = "Forever", class = "PRIEST", level = 20,
			items = { { bag = 0, slot = 1, itemID = 2589, count = 3, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" } },
			bank = { { bag = 6, slot = 1, itemID = 2589, count = 2, name = "Linen Cloth", quality = 1, link = "|Hitem:2589|h[Linen Cloth]|h" } } },
	} }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local function rows()
		local list = {}
		for _, pool in pairs(n.Buttons.cached or {}) do
			for _, b in pairs(pool) do
				if b:IsShown() and b.rec then local p = { b:GetPoint(1) }; list[#list + 1] = { b = b, y = tonumber(p[5]) or 0 } end
			end
		end
		table.sort(list, function(a, c) return a.y > c.y end)
		local out = {}
		for _, e in ipairs(list) do out[#out + 1] = e.b end
		return out
	end
	local function find(test) for _, b in ipairs(rows()) do if test(b.rec) then return b end end end
	local linen = find(function(r) return r.itemID == 2589 and not r.globalChild end)
	check(linen and linen.rec.globalKids and #linen.rec.globalKids == 2, "Linen Cloth (two characters) can open")
	check(linen.colWho.text:find("ui-chev-right", 1, true) and linen.colWho.text:find("2 characters", 1, true), "a closed chevron beside 2 characters")
	check(not (linen.kebab and linen.kebab:IsShown()), "no item menu in Global Inventory")
	local silk = find(function(r) return r.itemID == 4306 end)
	check(silk and not silk.rec.globalKids, "an item only you have doesn't open")
	linen:GetScript("OnClick")(linen, "LeftButton"); M.runTimers(); M.runTimers()
	local list = rows()
	local at
	for i, b in ipairs(list) do if b.rec.itemID == 2589 and not b.rec.globalChild then at = i end end
	local k1, k2 = list[at + 1], list[at + 2]
	check(k1 and k1.rec.globalChild and k2 and k2.rec.globalChild, "opened: a row per character, right under it")
	local mine, his = k1, k2
	if k1.rec.who == "Brannoc" then mine, his = k2, k1 end
	check(his.colName.text == "Brannoc" and his.rec.count == 5 and his.colWhere.text == "Bags, Bank" and mine.rec.count == 5, "each: the name first, their own count and places")
	check(his.icon.texture and his.icon.texture:find("UI%-CHARACTERCREATE%-CLASSES") and his.icon.texCoord and his.icon.texCoord[1] == 0.5, "the class icon in the icon's place (a priest's)")
	check(his.iconLayoutX == his.iconBaseX + 14, "indented, nested under the item")
	check(list[at].colWho.text:find("ui-chev-down", 1, true), "the chevron points down while open")
	-- closed again: rows reused for items get their own icon back
	list[at]:GetScript("OnClick")(list[at], "LeftButton"); M.runTimers(); M.runTimers()
	local still = find(function(r) return r.globalChild end)
	check(still == nil, "closed: the character rows go")
	for _, b in ipairs(rows()) do
		check(not b.globalChildIcon and b.iconLayoutX == b.iconBaseX, "a reused row shows its item normally (" .. tostring(b.rec.name) .. ")")
	end
	-- leaving closes the accordion
	linen = find(function(r) return r.itemID == 2589 end)
	linen:GetScript("OnClick")(linen, "LeftButton"); M.runTimers()
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers()
	check(n.ui.globalOpen == nil, "leaving Global Inventory closes every item")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- Settings: text and buttons clear of the line above (Shweep: "words tend to push up to the hr above them")
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { deEnabled = true } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("dehelper")
	local t
	for _, w in ipairs(P.pools.text) do if w:IsShown() then t = w; break end end
	local p = { t.text:GetPoint(1) }
	check(p[1] == "TOPLEFT" and p[3] == -6, "a line of text starts 6 px below the line above it, as a setting's label does")
	check(t:GetHeight() >= 12 + 14, "and keeps 6 px below it")
	local b
	for _, w in ipairs(P.pools.btn) do if w:IsShown() then b = w; break end end
	local bp = { b:GetPoint(1) }
	check(b and (-bp[5]) % 1 == 0, "(setup) a button")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- (Shweep: "bagbar makes no sense to be clickable in global") In Global Inventory the bag bar's button and strip step
	-- aside, and the bag-window and reagent buttons are greyed out, as when browsing another character.
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { bagBar = true } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers(); n:RefreshViews(true); M.runTimers()
	local V = n.Window.main
	check(V.btnBagBar:IsShown() and V.btnBags:IsEnabled(), "(setup) your bags: the bag bar button shows, bag windows can open")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(not V.btnBagBar:IsShown(), "Global Inventory: no bag bar button")
	check(not V.btnBags:IsEnabled() and V.btnBags.tip:find("your own bags", 1, true), "the bag-window button greyed out, saying why")
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	check(V.btnBagBar:IsShown() and V.btnBags:IsEnabled(), "back to your bags: both again")
	check((n.errors or 0) == 0, "no errors")
end)()
