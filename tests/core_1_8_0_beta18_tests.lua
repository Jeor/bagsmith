;(function()
	-- ======== 1.8.0-beta18 (Shweep): What's New's directions are links; Settings marks what's new ========
	-- A "Settings > Page > Heading" in a bullet shows in soft blue and opens Settings there; the 1.8 card's titles
	-- (Fonts, Special Bag Indicators, Profile Sharing Improved) and no Quick Tip.
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local WN, P = n.WhatsNew, n.SettingsPanel
	local L = WN.Linkify

	local t = L("Try it in Settings > Style > Size.")
	check(t == "Try it in " .. WN.LINK_COLOR .. "|Hbagsmith:settings:look:Size|hSettings > Style > Size|h|r.", "a page and its heading: one soft-blue link, the full stop outside: " .. t)
	t = L("in Settings > Item Icons > Special Bag Slot Indicators.")
	check(t:find("|Hbagsmith:settings:icons:Special Bag Slot Indicators|hSettings > Item Icons > Special Bag Slot Indicators|h|r.", 1, true), "a heading of several words")
	t = L("(you can turn it off in Settings > Item Icons). In Classic")
	check(t:find("|Hbagsmith:settings:icons:|hSettings > Item Icons|h|r). In Classic", 1, true), "a page alone, in brackets")
	t = L("Turn on Ask Before Destroying in Settings > Automations & Actions > Loot Helper. Want blue")
	check(t:find("|Hbagsmith:settings:loothelper:|hSettings > Automations & Actions > Loot Helper|h|r. Want blue", 1, true), "a sub-page: opens the sub-page")
	t = L("Settings > Profile > Shared Between Characters.")
	check(t:find("|Hbagsmith:settings:profile:Shared Between Characters|h", 1, true), "Shared Between Characters")
	t = L("Links are in Settings > About & Support.")
	check(t:find("|Hbagsmith:settings:about:|hSettings > About & Support|h|r.", 1, true), "About & Support")
	check(L("Settings > Nowhere Else.") == "Settings > Nowhere Else.", "a page Settings doesn't have: left as it is")
	check(L("Settings > Sectionsless") == "Settings > Sectionsless", "a page name only as part of a longer word: no link")
	check(L("Settings > Dynamic Sections.") :find("settings:dynamic:", 1, true), "the longest page name wins (Dynamic Sections, not Sections)")

	-- every direction in every card resolves to a page
	local bad = {}
	for _, e in ipairs(WN.ENTRIES) do
		for _, line in ipairs(e.items) do
			local linked = L(line)
			local plain = linked:gsub("|H.-|h.-|h", "")
			if plain:find("Settings > ", 1, true) then bad[#bad + 1] = e.v .. ": " .. line:sub(1, 40) end
			for page in linked:gmatch("|Hbagsmith:settings:(%w+):") do
				local found = false
				for _, p in ipairs(P:PageLabels()) do if p[1] == page then found = true end end
				if not found then bad[#bad + 1] = "no page " .. page end
			end
		end
	end
	check(#bad == 0, "every card's directions are links to a real page: " .. table.concat(bad, "; "))

	-- the 1.8 card
	local card
	for _, e in ipairs(WN.ENTRIES) do if e.v == "1.8.0" then card = e end end
	local all = table.concat(card.items, "\n")
	check(all:find("|cfffac775Fonts:|r", 1, true) and all:find("|cfffac775Special Bag Indicators:|r", 1, true) and all:find("|cfffac775Profile Sharing Improved:|r", 1, true), "the renamed titles")
	check(not all:find("Quick Tip", 1, true) and not all:find("Text Your Way", 1, true) and not all:find("Profiles, Your Way", 1, true) and not all:find("Special Bags:", 1, true), "the old titles and Quick Tip are gone")
	check(#card.items == 6, "six bullets: " .. #card.items)

	-- drawn as links
	WN:Open({ card }, 1)
	local f = WN.Card()
	local linked = 0
	for _, s in ipairs(f.lines) do if s.shown ~= false and (s.text or ""):find("|Hbagsmith:settings:", 1, true) then linked = linked + 1 end end
	check(linked >= 4, "the open card draws its directions as links: " .. linked)
	check(f.content.scripts.OnHyperlinkClick and f.content.scripts.OnDragStart, "the body takes the clicks, and still drags the card")

	-- a click opens Settings on the page, at the heading
	f.content.scripts.OnHyperlinkClick(f.content, "bagsmith:settings:icons:Special Bag Slot Indicators", "Settings > Item Icons", "LeftButton")
	check(P.frame and P.frame:IsShown() and P.page == "icons", "the link opens Settings on Item Icons")
	local ok, y = P:Open("icons", "Special Bag Slot Indicators")
	check(ok and type(y) == "number" and y > 0, "Open finds the heading lower on the page: " .. tostring(y))
	local headAt
	for _, h in ipairs(P.pools.head) do if h:IsShown() and h.text.text == "Special Bag Slot Indicators" then headAt = h.points[1] and -h.points[1][5] end end
	check(headAt == y, "the heading's place is the one scrolled to: " .. tostring(headAt))
	check(P.scroll:GetVerticalScroll() >= 0, "the page scrolls there, within its room")
	ok, y = P:Open("look", "No Such Heading")
	check(ok and y == nil and P.page == "look" and P.scroll:GetVerticalScroll() == 0, "a heading the page doesn't have: the top of the page")
	check(P:Open("nowhere") == false, "a page that doesn't exist: nothing happens")
	check(WN.OnLink("item:6948") == false, "another kind of link: not ours")
	check(P.seek == nil and P.seekY == nil, "nothing left waiting")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- NEW beside a page in the list, and beside the new headings and settings on it; a page's tags go once it has
	-- been opened, from the next time Settings opens. Per account, per release.
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	n.version = "1.8.0-beta18"
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local P = n.SettingsPanel
	local function navTag(page)
		for _, b in ipairs(P.navButtons) do if b.page == page then return b.newTag and b.newTag.shown ~= false and b.newTag:IsShown() end end
	end
	local function rowTag(kind, test)
		for _, w in ipairs(P.pools[kind] or {}) do if w:IsShown() and test(w) then return w.newTag and w.newTag:IsShown() or false end end
	end
	P.page = "general"
	P:Show()
	check(navTag("look") and navTag("icons") and navTag("profile"), "Style, Item Icons and Profile: NEW in the list")
	check(not navTag("general") and not navTag("sorting"), "the others: no NEW")
	P:ShowPage("look")
	check(rowTag("step", function(w) return w.key == "textScale" end) == true, "Text Size: NEW")
	check(rowTag("dropdown", function(w) return w.key == "fontName" end) == true, "Font: NEW")
	check(rowTag("step", function(w) return w.key == "scale" end) == false, "Scale: no NEW")
	check(navTag("look"), "opened, Style keeps its NEW while Settings stays open")
	P:ShowPage("icons")
	check(rowTag("head", function(w) return w.text.text == "Special Bag Slot Indicators" end) == true, "Special Bag Slot Indicators: NEW")
	check(rowTag("check", function(w) return w.key == "questFrame" end) == true, "Gold Frame for Quest Items: NEW")
	check(rowTag("head", function(w) return w.text.text == "Marks" end) == false, "Marks: no NEW")
	check(BagSmithDB.newSeen["1.8"].look and BagSmithDB.newSeen["1.8"].icons and BagSmithDB.newSeen["1.8"].general == nil, "opened pages are remembered (only pages with something new)")
	P:Hide(); P:Show()
	check(not navTag("look") and not navTag("icons"), "reopened: the pages you opened lose their NEW")
	check(navTag("profile"), "Profile, not opened yet, keeps it")
	P:ShowPage("profile")
	check(rowTag("head", function(w) return w.text.text == "Shared Between Characters" end) == true, "Shared Between Characters: NEW this time")
	P:ShowPage("look")
	check(rowTag("step", function(w) return w.key == "textScale" end) == false, "Text Size: no NEW any more")

	-- saved per account, checked on load
	M.fire("PLAYER_LOGOUT")
	local saved = BagSmithDB
	saved.newSeen["1.8"].bad = "yes"; saved.newSeen["1.8"]["no spaces"] = true; saved.newSeen.junk = { look = true }; saved.newSeen["1.7"] = "x"
	package.loaded.mock = nil
	M = require("mock")
	_G.BagSmithDB = saved
	n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers()
	local ns18 = BagSmithDB.newSeen and BagSmithDB.newSeen["1.8"]
	check(ns18 and ns18.look == true and ns18.profile == true and ns18.bad == nil and ns18["no spaces"] == nil, "kept: the pages seen; dropped: anything else")
	check(BagSmithDB.newSeen.junk == nil and BagSmithDB.newSeen["1.7"] == nil, "only releases, each a list of pages")
	-- another release shows none of 1.8's
	n.version = "1.9.0"
	P = n.SettingsPanel
	BagSmithDB.newSeen = nil
	P:Show()
	local any = false
	for _, b in ipairs(P.navButtons) do if b.newTag and b.newTag:IsShown() then any = true end end
	check(not any, "1.9: 1.8's NEW tags don't show")
	check((n.errors or 0) == 0, "no errors")
end)()
