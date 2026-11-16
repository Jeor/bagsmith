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
