;(function()
	-- ======== 1.7.4-beta1: picking a quest reward in the Loot Helper only moves the highlight (Shweep, 14 Nov) ========
	-- Turning in Westfall Stew with room for one of its three rewards: clicking the top waiting row made it the target,
	-- the target took the free slot first, so it counted as fitting and left the list; the reward that had held the
	-- slot came back and the highlight fell to the most valuable. Clicking the top row again swapped them back. A quest
	-- hands over every reward at once, so which rewards are waiting must not depend on the pick.
	for _, skin in ipairs({ "modern", "classic" }) do
		package.loaded.mock = nil
		local M = require("mock")
		for b = 1, 5 do M.sizes[b] = 0 end
		M.sizes[0] = 4
		M.put(0, 1, { id = 9701, name = "Broken Fang", q = 0, class = 15, subclass = 0, price = 3 })
		M.put(0, 2, { id = 9702, name = "Torn Hide", q = 0, class = 15, subclass = 0, price = 2 })
		M.put(0, 3, { id = 9703, name = "Linen Belt", q = 1, class = 4, subclass = 1, price = 22, equip = "INVTYPE_WAIST" })
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin } } }
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		-- the rewards: a recipe (50c), oven mitts (47c), a knife (183c)
		local R = { { 9801, "Recipe: Westfall Stew", 50, 1 }, { 9802, "Salma's Oven Mitts", 47, 2 }, { 9803, "Sharp Kitchen Knife", 183, 2 } }
		local byId = {}
		for _, r in ipairs(R) do byId[r[1]] = r end
		local realInfo = C_Item.GetItemInfo
		C_Item.GetItemInfo = function(id)
			id = tonumber(tostring(id):match("(%d+)")) or id
			local r = byId[id]
			if r then return r[2], "item:" .. r[1], r[4], nil, nil, nil, nil, 1, nil, nil, r[3] end
			return realInfo(id)
		end
		_G.GetNumQuestRewards = function() return 3 end
		_G.GetNumQuestChoices = function() return 0 end
		_G.GetQuestItemInfo = function(kind, i) local r = R[i]; return r[2], "icon", 1, r[4] end
		_G.GetQuestItemLink = function(kind, i) return "item:" .. R[i][1] end
		_G.GetQuestReward = function() end
		_G.ERR_INV_FULL = _G.ERR_INV_FULL or "Inventory is full."
		M.fire("QUEST_COMPLETE")
		M.fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
		local f = n.MakeRoom.frame
		local S = skin .. ": "
		local function shown()
			local names, target = {}, nil
			for _, r in ipairs(f.waitRows) do
				if r:IsShown() then names[#names + 1] = r.name.text; if r.isTarget then target = r.name.text end end
			end
			return names, target
		end
		local before, t0 = shown()
		check(f:IsShown() and n.MakeRoom.mode == "quest" and #before == 2, S .. "(control) two of the three rewards are waiting: " .. table.concat(before, ", "))
		check(t0 ~= nil, S .. "one of them is highlighted: " .. tostring(t0))
		-- click the row that isn't highlighted
		local other
		for _, r in ipairs(f.waitRows) do if r:IsShown() and not r.isTarget then other = r end end
		local picked = other.name.text
		other:GetScript("OnClick")(other)
		local after, t1 = shown()
		check(table.concat(after, "|") == table.concat(before, "|"), S .. "clicking a reward leaves the list as it was (" .. table.concat(after, ", ") .. ")")
		check(t1 == picked, S .. "and highlights the reward you clicked: " .. tostring(t1))
		check(f.heads and (function() for _, h in ipairs(f.heads) do if h:IsShown() and h.text and h.text:find(picked, 1, true) then return true end end end)(),
			S .. "the suggestions are for it (\"To make room for " .. picked .. "\")")
		-- and back again
		for _, r in ipairs(f.waitRows) do if r:IsShown() and not r.isTarget then other = r end end
		local picked2 = other.name.text
		other:GetScript("OnClick")(other)
		local after2, t2 = shown()
		check(table.concat(after2, "|") == table.concat(before, "|") and t2 == picked2, S .. "clicking the other one moves the highlight back, the list unchanged")
		f:Hide()
		C_Item.GetItemInfo = realInfo
		_G.GetQuestReward, _G.GetNumQuestRewards, _G.GetNumQuestChoices, _G.GetQuestItemInfo, _G.GetQuestItemLink = nil, nil, nil, nil, nil
	end
end)()
