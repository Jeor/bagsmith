-- Geometry only. Plan from visible (already merged) icons, in category order.
-- Compare complete layouts rather than greedily filling the current row.
-- Collapsed state is deliberately absent: folding preserves row membership.
local _, ns = ...
local Compact = {}
ns.CompactCategories = Compact

function Compact.Rows(boxes, width, cell, gap, gutter, groupGap, rowOverhead)
	local step = cell + gap
	local capacity = math.max(1, math.floor((width - 2 * gutter + gap) / step))
	rowOverhead = rowOverhead or 40
	local function shape(index, lines)
		local box = boxes[index]
		local count = math.max(1, box.count)
		local headingWidth = math.min(width, box.minWidth)
		-- Separate the heading's footprint from the item wrapping. For example,
		-- seven icons in a six-column viewport use four plus three, not six plus
		-- one, even when the heading itself needs a wider block.
		local depth = math.max(lines, math.ceil(count / capacity))
		local across = math.ceil(count / depth)
		local headingCols = math.max(1, math.ceil((headingWidth - 2 * gutter + gap) / step))
		return { index = index, across = across,
			width = math.min(width, math.max(headingCols, across) * step - gap + 2 * gutter) }
	end
	local function fit(first, last, lines)
		local row, used, depth = {}, 0, 0
		for i = first, last do
			local s = shape(i, lines)
			row[#row + 1] = s
			used = used + s.width + (i > first and groupGap or 0)
			depth = math.max(depth, math.ceil(boxes[i].count / s.across))
		end
		return used <= width, row, depth, used
	end
	local function shortestRow(first, last)
		local most = 1
		for i = first, last do most = math.max(most, boxes[i].count) end
		-- Width is monotone as the allowed number of icon lines increases.
		if not fit(first, last, most) then return end
		local low, high = 1, most
		while low < high do
			local mid = math.floor((low + high) / 2)
			if fit(first, last, mid) then high = mid else low = mid + 1 end
		end
		local _, row, depth, used = fit(first, last, low)
		return row, depth, used
	end
	-- Cheapest suffix from each category. Equal-height layouts prefer balanced
	-- row depths, then less unused width. All ties are deterministic.
	local best = { [#boxes + 1] = { height = 0, balance = 0, waste = 0 } }
	for first = #boxes, 1, -1 do
		for last = first, #boxes do
			if last > first and (boxes[first].fullWidth or boxes[last].fullWidth) then break end
			local row, depth, used
			if boxes[first].fullWidth then
				row = { { index = first, width = width, across = capacity } }
				depth, used = math.ceil(boxes[first].count / capacity), width
			else
				row, depth, used = shortestRow(first, last)
			end
			if not row then break end -- Adding another heading cannot make it fit.
			local rest = best[last + 1]
			local height = rowOverhead + depth * step + rest.height
			local balance = depth * depth + rest.balance
			local waste = (width - used) ^ 2 + rest.waste
			local prev = best[first]
			if not prev or height < prev.height or (height == prev.height and
				(balance < prev.balance or (balance == prev.balance and waste < prev.waste))) then
				best[first] = { row = row, nextIndex = last + 1, height = height, balance = balance, waste = waste }
			end
		end
	end
	local rows, index = {}, 1
	while index <= #boxes do
		local choice = best[index]
		rows[#rows + 1], index = choice.row, choice.nextIndex
	end
	return rows
end

-- (1.9.0-beta6, Shweep: "campact view, can it better utilize the width of the window?") After Rows plans the rows, each
-- row with room to spare uses it: first more icon columns, whenever that saves the whole row a line of icons; then
-- the sections stretch, their spare width shared out by size, so the row reaches the right edge. Rows (the plan) is
-- left as it was; this only widens what it chose. A one-section row already spans the width.
function Compact.Justify(rows, boxes, width, cell, gap, gutter, groupGap)
	local step = cell + gap
	local function lines(p) return math.ceil(math.max(1, boxes[p.index].count) / p.across) end
	local function widthOf(p, across)
		local box = boxes[p.index]
		local headingCols = math.max(1, math.ceil((math.min(width, box.minWidth) - 2 * gutter + gap) / step))
		return math.min(width, math.max(headingCols, across) * step - gap + 2 * gutter)
	end
	local function used(row)
		local u = 0
		for j, p in ipairs(row) do u = u + p.width + (j > 1 and groupGap or 0) end
		return u
	end
	for _, row in ipairs(rows) do
		if #row > 1 then
			-- 1. a line fewer for the whole row, while it fits
			while true do
				local depth = 0
				for _, p in ipairs(row) do depth = math.max(depth, lines(p)) end
				if depth <= 1 then break end
				local trial, total = {}, 0
				for j, p in ipairs(row) do
					local across = p.across
					if lines(p) == depth then across = math.ceil(math.max(1, boxes[p.index].count) / (depth - 1)) end
					trial[j] = { across = across, width = widthOf(p, across) }
					total = total + trial[j].width + (j > 1 and groupGap or 0)
				end
				if total > width then break end
				for j, p in ipairs(row) do p.across, p.width = trial[j].across, trial[j].width end
			end
			-- 2. (1.9.0-beta7, Shweep: "Gear: BOE, why stacked?") the spare width first to a section that then needs a line
			-- fewer of its own, the cheapest first (the deepest on a tie), as long as there's room
			while true do
				local spare, best, bestCost = width - used(row), nil, nil
				for _, p in ipairs(row) do
					local l = lines(p)
					if l > 1 then
						local across = math.ceil(math.max(1, boxes[p.index].count) / (l - 1))
						local cost = widthOf(p, across) - p.width
						if cost <= spare and (not best or cost < bestCost or (cost == bestCost and l > lines(best))) then best, bestCost = p, cost end
					end
				end
				if not best then break end
				best.across = math.ceil(math.max(1, boxes[best.index].count) / (lines(best) - 1))
				best.width = widthOf(best, best.across)
			end
			-- 3. the rest shared out, so the row ends at the right edge
			local spare = width - used(row)
			if spare > 0 then
				local base, given = used(row) - (#row - 1) * groupGap, 0
				for j, p in ipairs(row) do
					local add = (j == #row) and (spare - given) or math.floor(spare * p.width / base)
					p.width = p.width + add
					given = given + add
				end
			end
			-- 4. (beta7) and each section's icons fill its width: as many across as fit, in even lines (seven in a width
			-- for six: four and three, not six and one)
			for _, p in ipairs(row) do
				local count = math.max(1, boxes[p.index].count)
				local fit = math.max(1, math.floor((p.width - 2 * gutter + gap) / step))
				if fit > p.across then
					local l = math.ceil(count / fit)
					p.across = math.max(p.across, math.ceil(count / l))
				end
			end
		end
	end
	return rows
end

