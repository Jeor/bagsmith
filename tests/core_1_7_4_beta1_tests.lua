;(function()
	-- ======== 1.7.4-beta1: the Loot Helper for quests says it plainly (Shweep, 14 Nov) ========
	-- Turning in Westfall Stew with room for one of its three rewards: clicking the top waiting row made it the target,
	-- the target took the free slot first, so it counted as fitting and left the list; the reward that had held the
	-- slot came back and the highlight fell to the most valuable; clicking again swapped them back. A quest hands over
	-- every reward at once, so now: every reward is listed, there's no highlight and nothing to click, and the lines say
	-- how many free slots are still needed. Offers are judged against the most valuable reward.
	-- Accepting a quest that hands you items: the game doesn't say how many; at least 1, and more once a refusal with
	-- free slots shows it.
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
		local R = { { 9801, "Recipe: Westfall Stew", 50, 1 }, { 9802, "Salma's Oven Mitts", 47, 2 }, { 9803, "Sharp Kitchen Knife", 183, 2 } }
		local byId = {}
		for _, r in ipairs(R) do byId[r[1]] = r end
		local realInfo = C_Item.GetItemInfo
		C_Item.GetItemInfo = function(arg)
			local r = byId[tonumber(tostring(arg):match("(%d+)"))]
			if r then return r[2], "item:" .. r[1], r[4], nil, nil, nil, nil, 1, nil, nil, r[3] end
			return realInfo(arg)
		end
		_G.GetTitleText = function() return "Westfall Stew" end
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
		local function rows()
			local names, hl, clickable = {}, false, false
			for _, r in ipairs(f.waitRows) do
				if r:IsShown() then
					names[#names + 1] = r.name.text
					if r.isTarget or (r.bar and r.bar:IsShown()) or (r.hl and r.hl:IsShown()) then hl = true end
					if r.onTarget then clickable = true end
				end
			end
			return names, hl, clickable
		end
		local function heading(text) for _, h in ipairs(f.heads) do if h:IsShown() and h.text == text then return true end end end
		local names, hl, clickable = rows()
		check(f:IsShown() and n.MakeRoom.mode == "quest" and table.concat(names, "|") == "Recipe: Westfall Stew|Salma's Oven Mitts|Sharp Kitchen Knife",
			S .. "every reward is listed, in the quest's order: " .. table.concat(names, ", "))
		check(heading("Rewards"), S .. "under the heading Rewards")
		check(not hl and not clickable, S .. "no highlight and nothing to click: a quest gives everything at once")
		check(f.sub.text == "Your bags are full. Westfall Stew gives you all 3 rewards at once, so you need 2 more free slots. Make room, then click Complete Quest.",
			S .. "the line says why and how many: " .. f.sub.text)
		check(heading("To make room for Westfall Stew's rewards"), S .. "the suggestions are for the quest's rewards")
		check(f.foot:IsShown() and f.foot.text == "Then you need 1 more free slot.", S .. "the footer counts down: " .. tostring(f.foot.text))
		-- clicking a row changes nothing
		local first
		for _, r in ipairs(f.waitRows) do if r:IsShown() then first = r; break end end
		first:GetScript("OnClick")(first)
		local names2 = rows()
		check(table.concat(names2, "|") == table.concat(names, "|"), S .. "clicking a reward changes nothing (the old swap)")
		-- one slot freed (not the Broken Fang: it's what's offered; items put in during the test are new, so protected)
		M.bags[0][2] = nil; n:Scan(); M.runTimers()
		check(f.sub.text:find("so you need 1 more free slot%.") and f.foot.text == "Then there's room for all 3 rewards.",
			S .. "one slot freed: 1 more needed; the footer says the next one makes room for all 3 (" .. tostring(f.foot.text) .. ")")
		check(table.concat(rows(), "|") == table.concat(names, "|"), S .. "still every reward listed")
		M.bags[0][3] = nil; n:Scan(); M.runTimers()
		check(f.sub.text == "There's room now: click Complete Quest.", S .. "room for all: " .. f.sub.text)
		f:Hide(); M.fire("QUEST_FINISHED")

		-- accepting a quest that hands you items: at least 1; a refusal with 1 free slot means at least 2
		_G.GetTitleText = function() return "Report to Goldshire" end
		M.gameTime = (M.gameTime or 0) + 30
		M.fire("QUEST_DETAIL")
		M.put(0, 2, { id = 9702, name = "Torn Hide", q = 0, class = 15, subclass = 0, price = 2 })
		M.put(0, 3, { id = 9703, name = "Linen Belt", q = 1, class = 4, subclass = 1, price = 22, equip = "INVTYPE_WAIST" })
		M.put(0, 4, { id = 9704, name = "Pebble", q = 0, class = 15, subclass = 0, price = 1 }); n:Scan()   -- full: 4 of 4
		M.fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
		local an = rows()
		check(f:IsShown() and #an == 1 and an[1] == "An item from this quest" and heading("Given when you accept"), S .. "accepting: one row, under Given when you accept")
		check(f.sub.text == "Your bags are full. Accepting Report to Goldshire gives you at least 1 item, so you need at least 1 free slot. The game doesn't say how many items. Make room, then click Accept.",
			S .. "accepting: at least 1 (" .. f.sub.text .. ")")
		check(heading("To make room for it") and f.foot.text == "Then there's room for it.", S .. "for it: " .. tostring(f.foot.text))
		-- make room for one, then the game refuses again: it gives more than 1
		M.bags[0][2] = nil; n:Scan(); M.runTimers()
		check(f.sub.text:find("^There's room now: click Accept%. If the game still says your bags are full, the quest gives more than 1 item"), S .. "room for one, with the caveat: " .. f.sub.text)
		M.fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
		an = rows()
		check(an[1] == "At least 2 items from this quest" and f.sub.text:find("gives you at least 2 items, so you need at least 2 free slots"),
			S .. "refused with 1 free slot: at least 2 (" .. f.sub.text .. ")")
		check(heading("To make room for them") and f.foot.text == "Then there's room for them.", S .. "for them")
		-- the same quest opened again keeps it
		M.fire("QUEST_FINISHED"); M.fire("QUEST_DETAIL")
		check(n.MakeRoom.quest.minNeed == 2, S .. "opening the same quest again keeps at least 2")
		_G.GetTitleText = function() return "Another Quest" end
		M.fire("QUEST_DETAIL")
		check(n.MakeRoom.quest.minNeed == nil, S .. "another quest starts from 1")
		f:Hide()
		C_Item.GetItemInfo = realInfo
		_G.GetTitleText = nil
		_G.GetQuestReward, _G.GetNumQuestRewards, _G.GetNumQuestChoices, _G.GetQuestItemInfo, _G.GetQuestItemLink = nil, nil, nil, nil, nil
	end

	-- ======== 1.7.4-beta1: the quest log read through C_QuestLog (Forever: no GetNumQuestLogEntries) ========
	-- Shweep's /bs questlog on Forever: "? lines", "Items kept for quests: 0", while C_QuestLog listed 20 quests. The log
	-- was taken as read and empty, so Westfall Stew's Okra was offered at its turn-in. Now it's listed through C_QuestLog.
	for _, skin in ipairs({ "modern", "classic" }) do
		package.loaded.mock = nil
		local M = require("mock")
		for b = 1, 5 do M.sizes[b] = 0 end
		M.sizes[0] = 3
		M.put(0, 1, { id = 4536, name = "Okra", q = 1, count = 7, stack = 20, class = 7, subclass = 0, price = 6 })
		M.put(0, 2, { id = 9701, name = "Broken Fang", q = 0, class = 15, subclass = 0, price = 3 })
		M.put(0, 3, { id = 9702, name = "Torn Hide", q = 0, class = 15, subclass = 0, price = 2 })
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin } } }
		local fail = {}
		local log = { { title = "Westfall", header = true }, { title = "Westfall Stew", questID = 38, objs = { { "Okra: 3/3", "item" }, { "Murloc Eye: 3/3", "item" } } } }
		_G.GetNumQuestLogEntries, _G.GetQuestLogTitle = nil, nil
		_G.C_QuestLog = {
			GetNumQuestLogEntries = function() return #log, 1 end,
			GetInfo = function(i) if fail.info then error("info") end local q = log[i]; if not q then return nil end return { title = q.title, isHeader = q.header or false, isCollapsed = false, questID = q.questID } end,
			GetQuestObjectives = function(id) for _, q in ipairs(log) do if q.questID == id then local out = {}; for _, o in ipairs(q.objs) do out[#out + 1] = { text = o[1], type = o[2] } end return out end end return {} end,
		}
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		local MR = n.MakeRoom
		local S = skin .. " (C_QuestLog): "
		local needs, complete, _, lines = MR:QuestObjectives()
		check(complete and lines == 2 and #needs == 2, S .. "the log is listed through C_QuestLog: 2 lines, 2 items kept (" .. tostring(lines) .. ", " .. #needs .. ")")
		check(MR:NeededForQuest("Okra", needs) and not MR:NeededForQuest("Broken Fang", needs), S .. "Okra is needed for Westfall Stew; the Fang isn't")
		-- turning it in with full bags: Okra isn't offered
		local R = { { 9803, "Sharp Kitchen Knife", 183, 2 } }
		local realInfo = C_Item.GetItemInfo
		C_Item.GetItemInfo = function(arg)
			if tonumber(tostring(arg):match("(%d+)")) == 9803 then return "Sharp Kitchen Knife", "item:9803", 2, nil, nil, nil, nil, 1, nil, nil, 183 end
			return realInfo(arg)
		end
		_G.GetTitleText = function() return "Westfall Stew" end
		_G.GetNumQuestRewards = function() return 1 end
		_G.GetNumQuestChoices = function() return 0 end
		_G.GetQuestItemInfo = function(kind, i) return "Sharp Kitchen Knife", "icon", 1, 2 end
		_G.GetQuestItemLink = function(kind, i) return "item:9803" end
		_G.ERR_INV_FULL = _G.ERR_INV_FULL or "Inventory is full."
		M.fire("QUEST_COMPLETE"); M.fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
		local f = MR.frame
		local function offered() local o = {}; for _, r in ipairs(f.destroyRows) do if r:IsShown() then o[#o + 1] = r.name.text end end; table.sort(o); return table.concat(o, ",") end
		check(f:IsShown() and offered() == "Broken Fang,Torn Hide", S .. "turning in Westfall Stew: Okra isn't offered (" .. offered() .. ")")
		-- a line that can't be read: nothing is offered (unreadable is a no)
		fail.info = true; MR.questMemo = {}; MR:Refresh()
		check(offered() == "", S .. "a quest log line that can't be read: nothing offered (" .. offered() .. ")")
		fail.info = nil
		f:Hide()
		C_Item.GetItemInfo = realInfo
		_G.C_QuestLog, _G.GetTitleText = nil, nil
		_G.GetQuestReward, _G.GetNumQuestRewards, _G.GetNumQuestChoices, _G.GetQuestItemInfo, _G.GetQuestItemLink = nil, nil, nil, nil, nil
	end
end)()
