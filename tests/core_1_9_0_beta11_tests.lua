-- ======== 1.9.0-beta11 (Shweep, 17 Nov) ========
-- Compact View: "sometimes we are still not using full width" (a section alone in its row was skipped), and, asked
-- "are you sure we can't shore up this code even more", a check over hundreds of random layouts that every row
-- reaches the window's edge and none could be a line shorter. The What's New card "5-10% wider".
package.loaded.mock = nil
local M = require("mock")
_G.BagSmithCharDB = { version = 1, firstSeen = {} }
_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
local n = M.loadAddon("BagSmith")
local C = n.CompactCategories

local function lines(count, across) return math.ceil(math.max(1, count) / across) end
-- what the layout promises, for one planned and justified layout
local function audit(boxes, rows, W, CELL, GAP, GUT, GG, label)
	local step = CELL + GAP
	local problems, last = {}, 0
	for r, row in ipairs(rows) do
		local used, depth = 0, 0
		for j, p in ipairs(row) do
			local b = boxes[p.index]
			used = used + p.width + (j > 1 and GG or 0)
			depth = math.max(depth, lines(b.count, p.across))
			if p.index ~= last + 1 then problems[#problems + 1] = "row " .. r .. ": sections out of order" end
			last = p.index
			if p.across * step - GAP + 2 * GUT > p.width + 0.5 then problems[#problems + 1] = "row " .. r .. ": icons wider than their section" end
			if p.across > math.max(1, b.count) and not b.fullWidth then problems[#problems + 1] = "row " .. r .. ": more columns than icons" end
		end
		if math.abs(used - W) > 0.5 then problems[#problems + 1] = ("row %d: ends %d px short of the edge"):format(r, W - used) end
		-- a line shorter: every section at the fewest columns for one line less, its heading respected
		if depth > 1 then
			local need = 0
			for j, p in ipairs(row) do
				local b = boxes[p.index]
				local across = math.min(math.max(1, b.count), math.ceil(math.max(1, b.count) / (depth - 1)))
				local headingCols = math.max(1, math.ceil((math.min(W, b.minWidth) - 2 * GUT + GAP) / step))
				local capacity = math.max(1, math.floor((W - 2 * GUT + GAP) / step))
				if across > capacity then need = math.huge break end   -- (more columns than the window holds: no)
				need = need + math.min(W, math.max(headingCols, across) * step - GAP + 2 * GUT) + (j > 1 and GG or 0)
			end
			if need <= W and not row[1].fullWidthRow then problems[#problems + 1] = "row " .. r .. ": could be a line shorter" end
		end
	end
	if last ~= #boxes then problems[#problems + 1] = "not every section placed" end
	return problems
end

;(function()
	-- hundreds of random layouts: window widths, icon sizes, section sizes and heading widths
	math.randomseed(1911)
	local layouts, rowsSeen, bad, first = 0, 0, 0, nil
	for _, size in ipairs({ { 37, 4, 3, 16 }, { 44, 4, 3, 16 }, { 30, 2, 2, 12 } }) do
		local CELL, GAP, GUT, GG = size[1], size[2], size[3], size[4]
		for t = 1, 150 do
			local W = math.random(360, 1000)
			local boxes = {}
			for i = 1, math.random(1, 14) do
				boxes[i] = { count = math.random(1, 30), minWidth = 20 + math.random(30, 120) + 6 + 24 + 4 }
			end
			if math.random() < 0.2 then boxes[math.random(1, #boxes)].fullWidth = true end
			local rows = C.Rows(boxes, W, CELL, GAP, GUT, GG, 40)
			C.Justify(rows, boxes, W, CELL, GAP, GUT, GG)
			layouts = layouts + 1
			rowsSeen = rowsSeen + #rows
			local p = audit(boxes, rows, W, CELL, GAP, GUT, GG)
			if #p > 0 then bad = bad + 1; first = first or (("width %d, icons %d: %s"):format(W, CELL, p[1])) end
		end
	end
	check(bad == 0, ("%d random layouts (%d rows): every row reaches the edge, none could be a line shorter, icons fit, order kept%s"):format(layouts, rowsSeen, first and (": first problem: " .. first) or ""))
end)()

;(function()
	-- Shweep's screenshot (17 Nov): Trade Goods (19) alone in its row, at 7 across, short of the edge
	local function heading(name, count) return 20 + #name * 6 + 6 + #("(" .. count .. ")") * 6 + 4 end
	local spec = { { "Gear: BoE", 1 }, { "Food", 6 }, { "Drink", 1 }, { "Potions", 3 }, { "Scrolls", 6 }, { "Bandages", 1 },
		{ "Consumables: Other", 1 }, { "Quest", 4 }, { "Trade Goods", 19 }, { "Reagents", 1 }, { "Other", 2 } }
	local boxes, tg = {}, nil
	for i, s in ipairs(spec) do boxes[i] = { count = s[2], minWidth = heading(s[1], s[2]) }; if s[1] == "Trade Goods" then tg = i end end
	local W, CELL, GAP, GUT, GG = 570, 44, 4, 3, 16
	local rows = C.Rows(boxes, W, CELL, GAP, GUT, GG, 40)
	C.Justify(rows, boxes, W, CELL, GAP, GUT, GG)
	local p = audit(boxes, rows, W, CELL, GAP, GUT, GG)
	check(#p == 0, "the screenshot's sections: every row reaches the edge" .. (#p > 0 and (": " .. p[1]) or ""))
	for _, row in ipairs(rows) do
		for _, q in ipairs(row) do
			if q.index == tg then
				check(#row > 1 or q.width == W, "Trade Goods reaches the edge (" .. q.width .. " of " .. W .. ")")
			end
		end
	end
	-- alone in its row, as in the screenshot: full width, its 19 icons in two lines, not three
	local one = { { count = 19, minWidth = heading("Trade Goods", 19) } }
	local r1 = { { { index = 1, across = 7, width = 7 * 48 - 4 + 6 } } }
	C.Justify(r1, one, 570, 44, 4, 3, 16)
	check(r1[1][1].width == 570 and lines(19, r1[1][1].across) == 2 and r1[1][1].across * 48 - 4 + 6 <= 570,
		"Trade Goods alone: the full width, two lines (" .. r1[1][1].across .. " across)")
end)()

;(function()
	-- the What's New card: about 8% wider (476, was 440)
	n.WhatsNew:ShowLatest(); M.runTimers()
	local c = n.WhatsNew.Card()
	check(c and math.abs(c:GetWidth() - 476) < 0.5, "the What's New card is 476 wide (" .. tostring(c and c:GetWidth()) .. ")")
	check((n.errors or 0) == 0, "no errors")
end)()
