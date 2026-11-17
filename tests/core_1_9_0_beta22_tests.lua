-- ======== 1.9.0-beta22 (Shweep, 17 Nov) ========
-- Settings' side list: "can we pull in the carrots closer to the words so the new fits better beside them", and
-- "automations & actions does not have room for a new tag": "rename to Automations".

local function boot(skin)
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin or "modern" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	return n, M
end

for _, skin in ipairs({ "modern", "classic" }) do
	local S = skin .. ": "
	local n, M = boot(skin)
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("general"); M.runTimers()
	local by = {}
	for _, b in ipairs(P.navButtons) do by[b.page] = b end
	-- the name
	check(by.automation.text.text == "Automations", S .. "the page reads Automations")
	-- the arrows: just after the page's name
	for _, page in ipairs({ "sections", "columns", "sheets", "automation" }) do
		local b = by[page]
		local p = b.arrow and b.arrow.points and b.arrow.points[1]
		check(p and p[1] == "LEFT" and p[2] == b.text and p[3] == "RIGHT" and p[4] == P.NAV_ARROW_GAP and P.NAV_ARROW_GAP == 4,
			S .. page .. ": its arrow 4 px after its name")
	end
	-- every NEW tag at one right edge, arrow or not; Automations' name and arrow clear of it
	local newPage = P.NewPage
	P.NewPage = function() return true end
	P:SyncNav()
	local xs = {}
	for _, page in ipairs({ "general", "look", "sections", "columns", "sheets", "automation", "advanced" }) do
		local t = by[page].newTag
		xs[#xs + 1] = t and t:IsShown() and select(4, t:GetPoint(1)) or "none"
	end
	local same = true
	for i = 2, #xs do if xs[i] ~= xs[1] then same = false end end
	check(type(xs[1]) == "number" and same, S .. "NEW at the same spot on every page's row, with an arrow or without (" .. table.concat(xs, ", ") .. ")")
	local b = by.automation
	local textEnd = 8 + 14 + 4 + b.text:GetStringWidth() + P.NAV_ARROW_GAP + 10
	local tagX = select(4, b.newTag:GetPoint(1))
	if b.newTag.scaled then tagX = tagX * 0.75 end
	check(textEnd + 6 <= tagX, S .. "Automations: its name and arrow end before its NEW tag (" .. textEnd .. " < " .. tostring(tagX) .. ")")
	P.NewPage = newPage
	P:SyncNav()
	check((n.errors or 0) == 0, S .. "no errors")
end

;(function()
	local n, M = boot()
	-- links in What's New: the new name opens the page and its sub-pages
	local L = n.WhatsNew.Linkify
	n.SettingsPanel:Show()
	local t = L("Turn on Ask Before Destroying in Settings > Automations > Loot Helper. Want blue")
	check(t:find("|Hbagsmith:settings:loothelper:|hSettings > Automations > Loot Helper|h", 1, true), "\"Settings > Automations > Loot Helper\": opens the Loot Helper page")
	t = L("You can also sell junk automatically at vendors: Settings > Automations.")
	check(t:find("|Hbagsmith:settings:automation:|hSettings > Automations|h", 1, true), "\"Settings > Automations\": opens the page")
	-- no "Automations & Actions" left anywhere players see it
	local left = {}
	for _, e in ipairs(n.WhatsNew.ENTRIES) do for _, it in ipairs(e.items) do if it:find("Automations & Actions", 1, true) then left[#left + 1] = e.v end end end
	check(#left == 0, "What's New: every card says Automations (" .. table.concat(left, ", ") .. ")")
	local said
	local print0 = n.Print
	n.Print = function(_, msg) said = msg end
	n.db.deEnabled = false
	n.Disenchant:Show()
	n.Print = print0
	check(said == "Turn on the Disenchant Helper in Settings > Automations > Disenchant Helper first.", "the Disenchant Helper's reminder points to its page: " .. tostring(said))
	local confirm
	for _, k in ipairs(n.KeyBinds.LIST) do if k[1] == "BAGSMITH_CONFIRMKEY" then confirm = k[3] end end
	check(confirm and confirm:find("(Automations > Prompts)", 1, true), "the Confirm Prompts keybinding names Automations > Prompts")
	check((n.errors or 0) == 0, "no errors")
end)()
