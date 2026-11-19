;(function()
	-- ======== 1.7.4-beta2 ========
	-- (1) Forever's objective lines read "0/4 Miners' Union Card" (C_QuestLog), the classic log's "Okra: 3/3": both are
	-- matched exactly, so "Linen Cloth" isn't kept for "0/5 Bolt of Linen Cloth"; a line in neither form still falls
	-- back to the name anywhere in it. (2) An oversized accent caret points at the loot the Loot Helper is making room
	-- for (Shweep), and moves with the highlight; no caret for a quest (nothing is picked).
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local MR = n.MakeRoom
	local needs = { "0/4 Miners' Union Card", "Okra: 3/3", "0/5 Bolt of Linen Cloth", "7/7 Longshore Murloc Gill", "Bring the Old Lantern to Gryan" }
	check(MR.ObjectiveItem("0/4 Miners' Union Card") == "Miners' Union Card" and MR.ObjectiveItem("Okra: 3/3") == "Okra"
		and MR.ObjectiveItem("Bring the Old Lantern to Gryan") == nil, "both forms give the item's name; a line in neither, nothing")
	check(MR:NeededForQuest("Miners' Union Card", needs) and MR:NeededForQuest("Okra", needs) and MR:NeededForQuest("Longshore Murloc Gill", needs),
		"Forever's form and the classic form both keep their items")
	check(not MR:NeededForQuest("Linen Cloth", needs) and MR:NeededForQuest("Bolt of Linen Cloth", needs), "exact: Linen Cloth isn't kept for Bolt of Linen Cloth")
	check(not MR:NeededForQuest("Murloc Gill", needs), "nor a name inside a longer one (Murloc Gill, Longshore Murloc Gill)")
	check(MR:NeededForQuest("Old Lantern", needs), "a line in neither form: the name anywhere in it still keeps it")
	check(MR.ObjectiveItem("0/5 Linen Cloth (collect)") == "Linen Cloth" and MR:NeededForQuest("Linen Cloth", { "0/5 Linen Cloth (collect)" }),
		"a note in brackets after the name is dropped (1.7.0-beta3's \"0/5 Linen Cloth (collect)\" still keeps Linen Cloth)")

	-- the caret, in loot and quest modes, both skins
	for _, skin in ipairs({ "modern", "classic" }) do
		package.loaded.mock = nil
		M = require("mock")
		for b = 1, 5 do M.sizes[b] = 0 end
		M.sizes[0] = 2
		M.put(0, 1, { id = 9701, name = "Broken Fang", q = 0, class = 15, subclass = 0, price = 3 })
		M.put(0, 2, { id = 9702, name = "Torn Hide", q = 0, class = 15, subclass = 0, price = 2 })
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, accent = "3fa7ff" } } }
		n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		MR = n.MakeRoom
		local loot = { { id = 9710, name = "Shiny Ring" }, { id = 9711, name = "Old Necklace" } }
		_G.GetNumLootItems = function() return #loot end
		_G.GetLootSlotType = function(i) return loot[i] and 1 or 0 end
		_G.GetLootSlotLink = function(i) return loot[i] and ("item:" .. loot[i].id) end
		_G.GetLootSlotInfo = function(i) local l = loot[i]; if l then return "icon", l.name, 1, nil, 2 end end
		_G.LootSlot = function() end
		local realInfo = C_Item.GetItemInfo
		C_Item.GetItemInfo = function(arg)
			local id = tonumber(tostring(arg):match("(%d+)"))
			if id == 9710 then return "Shiny Ring", "item:9710", 2, nil, nil, nil, nil, 1, nil, nil, 500 end
			if id == 9711 then return "Old Necklace", "item:9711", 2, nil, nil, nil, nil, 1, nil, nil, 200 end
			return realInfo(arg)
		end
		M.fire("LOOT_OPENED"); M.runTimers()
		local f = MR.frame
		local S = skin .. ": "
		local function careted()
			local out = {}
			for _, r in ipairs(f.waitRows) do if r:IsShown() and r.caret and r.caret:IsShown() then out[#out + 1] = r end end
			return out
		end
		local c = careted()
		local ar, ag, ab = n.Skins:Accent()
		check(f:IsShown() and #c == 1 and c[1].isTarget and c[1].name.text == "Shiny Ring", S .. "one caret, on the row it's making room for (the most valuable)")
		local col = c[1] and c[1].caret.color
		check(col and math.abs(col[1] - ar) < 1e-6 and math.abs(col[2] - ag) < 1e-6 and math.abs(col[3] - ab) < 1e-6, S .. "in the accent color")
		check(c[1] and c[1].caret.texture and c[1].caret.texture:find("ui%-chev%-right"), S .. "BagSmith's right chevron")
		local other
		for _, r in ipairs(f.waitRows) do if r:IsShown() and not r.isTarget then other = r end end
		other:GetScript("OnClick")(other)
		c = careted()
		check(#c == 1 and c[1].name.text == "Old Necklace", S .. "clicking the other one moves the caret with the highlight")
		f:Hide(); loot = {}; M.fire("LOOT_CLOSED")
		-- a quest: no caret
		_G.GetTitleText = function() return "A Quest" end
		_G.GetNumQuestRewards = function() return 2 end
		_G.GetNumQuestChoices = function() return 0 end
		_G.GetQuestItemInfo = function(kind, i) return i == 1 and "Shiny Ring" or "Old Necklace", "icon", 1, 2 end
		_G.GetQuestItemLink = function(kind, i) return "item:" .. (i == 1 and 9710 or 9711) end
		_G.ERR_INV_FULL = _G.ERR_INV_FULL or "Inventory is full."
		M.fire("QUEST_COMPLETE"); M.fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
		check(f:IsShown() and MR.mode == "quest" and #careted() == 0, S .. "a quest's rewards: no caret")
		f:Hide()
		C_Item.GetItemInfo = realInfo
		_G.GetNumLootItems, _G.GetLootSlotType, _G.GetLootSlotLink, _G.GetLootSlotInfo, _G.LootSlot = nil, nil, nil, nil, nil
		_G.GetTitleText, _G.GetNumQuestRewards, _G.GetNumQuestChoices, _G.GetQuestItemInfo, _G.GetQuestItemLink = nil, nil, nil, nil, nil
	end
end)()
