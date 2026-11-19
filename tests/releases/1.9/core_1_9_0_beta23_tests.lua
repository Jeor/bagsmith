-- ======== 1.9.0-beta23 (Shweep, 17 Nov) ========
-- "extend What's New about 5-10% in width": 512, about 7.5% more than beta11's 476.

for _, skin in ipairs({ "modern", "classic" }) do
	local S = skin .. ": "
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.version = "1.9.0-beta23"
	n.WhatsNew:ShowLatest(); M.runTimers()
	local c = n.WhatsNew.Card()
	check(c and math.abs(c:GetWidth() - 512) < 0.5, S .. "the card is 512 wide (" .. tostring(c and c:GetWidth()) .. ")")
	check(math.abs(512 / 476 - 1.075) < 0.002, S .. "(about 7.5% wider than 476)")
	-- what sits inside follows: the link field, the text
	check(c.field and math.abs(c.field:GetWidth() - (512 - 32 - 30 - 28)) < 0.5, S .. "the link field widens with it (" .. tostring(c.field and c.field:GetWidth()) .. ")")
	local line = c.lines and c.lines[2]
	local want = 512 - 32 - 10 - (c.scrolls and 32 or 0)
	check(line and math.abs((line.width or 0) - want) < 0.5, S .. "the bullets' text is wider too (" .. tostring(line and line.width) .. ", " .. want .. ")")
	check((n.errors or 0) == 0, S .. "no errors")
end
