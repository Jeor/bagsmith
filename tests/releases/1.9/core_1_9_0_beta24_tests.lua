-- ======== 1.9.0-beta24 (the 1.9.0-beta23 audit, 17 Nov) ========
-- P2: an emptied bank fell back to the saved one. Inventory's selectors took the live bank only when it had records,
-- so after the last item left the bank, the item tooltips and Global Inventory still counted the saved copy (5 Linen
-- Cloth), past the delayed save and the bank closing. Now the bank seen this session decides, even empty, as Currency
-- reads it. The auditor's case first (their repro_empty_bank.py), then Global Inventory and a bank not yet visited.

local function boot()
	package.loaded.mock = nil
	local M = require("mock")
	M.put(-1, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	return n, M
end
local function count(n, id) local _, total = n.Inventory:Counts(id or 2589); return total end

;(function()
	local n, M = boot()
	M.fire("BANKFRAME_OPENED"); M.runTimers(); M.runTimers(); M.elapse()
	check(count(n) == 5 and #n.bankItems == 1, "(setup) 5 Linen Cloth in the bank")
	-- the last one leaves the bank
	M.bags[-1][1] = nil; n:Scan()
	check(count(n) == 0, "emptied: 0 at once, before the save (" .. count(n) .. ")")
	check(#n.Inventory:Characters()[1].bank == 0, "Global Inventory's own bank: empty before the save")
	M.elapse()
	check(count(n) == 0 and #n.Inventory:Characters()[1].bank == 0, "after the save: still 0")
	M.fire("BANKFRAME_CLOSED")
	check(count(n) == 0, "the bank closed: still 0")
	n.Inventory:Invalidate(true)
	check(count(n) == 0, "and when everything's counted again")
	-- Global Inventory has no row for it
	local rows = n.Inventory:GlobalRecords(false) or {}
	local linen
	for _, r in ipairs(rows) do if r.itemID == 2589 then linen = r end end
	check(not linen, "Global Inventory: no Linen Cloth row")
	-- some of a stack: the live bank's count
	M.put(-1, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 3, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	M.fire("BANKFRAME_OPENED"); M.runTimers(); M.runTimers(); M.elapse()
	check(count(n) == 3, "back at the bank with 3: 3")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- a bank not visited this session: the saved copy still counts
	local n, M = boot()
	M.elapse()   -- (your saved entry is written by the delayed save)
	local entry = BagSmithDB.cache[n:CharKey()]
	entry.bank = { { bag = -1, slot = 1, itemID = 4306, count = 7, name = "Silk Cloth", quality = 1, link = "|Hitem:4306|h[Silk Cloth]|h" } }
	n.Inventory:Invalidate(true)
	check(not n.bankScanned, "(setup) the bank not visited this session")
	check(count(n, 4306) == 7, "the saved bank counts: 7 Silk Cloth")
	local mine = n.Inventory:Characters()[1]
	check(#mine.bank == 1 and mine.bank[1].itemID == 4306, "Global Inventory reads the saved bank too")
	check((n.errors or 0) == 0, "no errors")
end)()
