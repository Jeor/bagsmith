;(function()
	-- ======== 1.8.0-beta16: answering the 1.8.0-beta15 audit ========
	-- F1: a character's own copies are kept under the profile's id, so a deleted profile's never come back when its name
	-- is reused (same session, another character later, Import); Reset and Copy give a new id; beta copies kept under a
	-- name move to the same profile's id only. F2: a Text Size change in combat lays the Disenchant Helper out after it.
	-- A1: every loot source of a slot must be an item.
	local function deep(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = deep(v) end return o end
	local function boot(name, db, cdb)
		package.loaded.mock = nil
		local M = require("mock")
		M.charName = name
		_G.BagSmithDB = db; _G.BagSmithCharDB = cdb
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		return n, M
	end

	-- F1, same session (the audit's first case)
	local n, M = boot("Aldren Thorne")
	check(n.db.profileId:find("^p") and n.db.profileIdLegacy == true, "a profile with no id gets one at login, marked inherited")
	n.db.favItems = { 6948 }
	n.Profiles:Use("Temp"); n.db.favItems = { 1004 }
	local tempId = n.db.profileId
	check(tempId ~= BagSmithDB.profiles.Default.profileId and BagSmithDB.profiles.Temp.profileIdLegacy == false, "a new profile, a new id (not inherited)")
	n.Profiles:Use("Default")
	check(n.db.favItems[1] == 6948, "(control) Default's favorites")
	n.Profiles:Delete("Temp")
	check(n.cdb.own[tempId] == nil, "deleting it drops this character's copies of it")
	n.Profiles:Use("Temp")
	check(n.db.favItems[1] == 6948 and n.db.profileId ~= tempId, "Temp made again starts from the current profile, not the deleted one's copies")

	-- F1, another character recreates it while the first is offline (the audit's second case)
	n, M = boot("Aldren Thorne")
	n.db.favItems = { 6948 }; n.Profiles:Use("Temp"); n.db.favItems = { 1004 }
	M.fire("PLAYER_LOGOUT")
	local db, cdbA = deep(BagSmithDB), deep(BagSmithCharDB)
	n, M = boot("Brannoc Vale", db)
	n.Profiles:Delete("Temp"); n.db.favItems = { 4306 }; n.Profiles:Use("Temp")
	M.fire("PLAYER_LOGOUT"); db = deep(BagSmithDB)
	n, M = boot("Aldren Thorne", db, cdbA)
	n.Profiles:Use("Temp")
	check(n.db.favItems[1] == 4306, "the first character returns to the new Temp: its favorites, not his old copies")
	local stale = false
	for k in pairs(n.cdb.own) do if not k:find("^p") then stale = true end end
	check(not stale, "no copy is kept under a name")

	-- F1, Import reusing a deleted profile's name
	n, M = boot("Aldren Thorne")
	n.db.favItems = { 6948 }
	local code = n.Share:Export()
	check(not n.Share:Decode(code).profileId, "a profile code carries no identity")
	n.Profiles:Use("Shared"); n.db.favItems = { 1004 }
	local sharedId = n.db.profileId
	n.Profiles:Use("Default"); n.Profiles:Delete("Shared")
	local imported = n.Share:Import(code, "Shared")
	n.Profiles:Use(imported)
	check(imported == "Shared" and n.db.profileId ~= sharedId and n.db.favItems[1] == 6948, "an import reusing the name: its own favorites, not the deleted profile's copies")

	-- F1, Reset and Copy give a new identity (other characters start again from it too)
	local before = n.db.profileId
	n.Profiles:Reset(); M.runTimers()
	check(n.db.profileId ~= "" and n.db.profileId ~= before, "Reset: a new id")
	before = n.db.profileId
	n.Profiles:CopyFrom("Default"); M.runTimers()
	check(n.db.profileId ~= before and n.db.profileId ~= BagSmithDB.profiles.Default.profileId, "Copy: a new id, never the source's")
	local ids, dup = {}, false
	for _, p in pairs(BagSmithDB.profiles) do if ids[p.profileId] then dup = true end; ids[p.profileId] = true end
	check(not dup, "every profile's id is its own")

	-- F1, a beta's copies kept under a name move to that same profile's id; duplicated ids are split
	local beta = { version = 2, chars = {}, cache = {}, profiles = { Default = { favItems = { 6948 } }, Alts = { favItems = { 2589 } } } }
	local betaChar = { version = 1, firstSeen = {}, own = { Default = { favItems = { 1004 } } } }
	n, M = boot("Aldren Thorne", beta, betaChar)
	check(n.db.favItems[1] == 1004 and n.cdb.own.Default == nil and n.cdb.own[n.db.profileId], "beta copies kept under \"Default\" move to Default's id")
	local twins = { version = 2, chars = {}, cache = {}, profiles = { A = { profileId = "p1.1.1" }, B = { profileId = "p1.1.1" } } }
	n, M = boot("Aldren Thorne", twins)
	check(BagSmithDB.profiles.A.profileId ~= BagSmithDB.profiles.B.profileId, "two profiles with one id (copied saved data): one gets a new id")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- F2: Text Size changed in combat: the Disenchant Helper's item panel takes the latest size when combat ends
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithDB = nil; _G.BagSmithCharDB = nil
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n:Set("deEnabled", true); n.Disenchant:Show(); M.runTimers()
	local f = n.Disenchant.frame
	local start = f.cur:GetHeight()
	M.combat = true; M.fire("PLAYER_REGEN_DISABLED")
	for _, scale in ipairs({ 1.5, 0.8, 1.2 }) do n:Set("textScale", scale); M.runTimers() end
	check(f.cur:GetHeight() == start, "in combat the panel keeps its size (it holds the secure button)")
	M.combat = false; M.fire("PLAYER_REGEN_ENABLED"); M.runTimers()
	local want = n.Fonts:Grow(84)
	check(want > start and f.cur:GetHeight() == want, "after combat it takes the latest size: " .. tostring(f.cur:GetHeight()) .. " (" .. want .. ")")
	check(n.Disenchant.layoutAfterCombat == nil, "and nothing waits any more")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- A1: every source the game lists for a loot slot must be an item
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith")
	local DE = n.Disenchant
	_G.GetLootSourceInfo = function() return "Item-6796-0-4000000046B6BAE0", 1 end
	check(DE.SlotIsCast(1) == true, "one source, an item: the cast's")
	_G.GetLootSourceInfo = function() return "Item-6796-0-4000000046B6BAE0", 1, "Creature-0-1-2-3-4-5", 2 end
	check(DE.SlotIsCast(1) == false, "an item and a creature: not the cast's (only the first was checked before)")
	_G.GetLootSourceInfo = function() return "Item-1", 1, "Item-2", 1 end
	check(DE.SlotIsCast(1) == true, "two items: still the cast's (the exact item is reported with /bs debug, not yet required)")
	_G.GetLootSourceInfo = function() return nil end
	check(DE.SlotIsCast(1) == false, "no source: not the cast's")
	-- /bs debug says whether the source is the item disenchanted
	local said = {}
	n.db.debug = true
	local oldDebug = n.Debug
	n.Debug = function(_, fmt, ...) said[#said + 1] = fmt:format(...) end
	DE.castOpen = { entry = { rec = { guid = "Item-6796-0-4000000046B6BAE0" } } }
	_G.GetLootSourceInfo = function() return "Item-6796-0-4000000046B6BAE0", 1 end
	DE.SlotIsCast(1)
	check(said[#said] and said[#said]:find("is the disenchanted item", 1, true), "debug: the source is the disenchanted item")
	_G.GetLootSourceInfo = function() return "Item-6796-0-999", 1 end
	DE.SlotIsCast(1)
	check(said[#said] and said[#said]:find("is NOT the disenchanted item", 1, true), "debug: or it isn't")
	n.Debug = oldDebug; DE.castOpen = nil; _G.GetLootSourceInfo = nil
end)()
