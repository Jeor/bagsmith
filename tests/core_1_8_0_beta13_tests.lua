;(function()
	-- ======== 1.8.0-beta13 (Shweep; learned from Guildy): Classic tabs overlap like the game's; /bs cpu ========
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "classic" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	ToggleAllBags(); M.runTimers(); M.runTimers()
	local main = n.Window.main
	local shown = {}
	for _, b in ipairs(main.tabButtons) do if b:IsShown() then shown[#shown + 1] = b end end
	check(#shown >= 3, "(setup) Classic tabs: " .. #shown)
	-- (1.8.0-beta14, by design, Shweep: "the tabs look terrible") the overlap is off again: beta12's layout, 2 px
	local a, b = shown[1], shown[2]
	local ax, bx = a.points[1][4], b.points[1][4]
	check(n.View.CLASSIC_TAB_EXTRA == 0, "the overlap is off (CLASSIC_TAB_EXTRA 0)")
	check(ax + a:GetWidth() - bx == 2 and ax == 0, "neighbors overlap 2 px, the first tab at the row's start, as in beta12: " .. (ax + a:GetWidth() - bx) .. ", " .. ax)
	-- the end trims (kept for a later attempt; not used while the overlap is off), on a stand-in for the game's tab art
	local function piece(w)
		local t = { w = w, c = { 0, 0, 0, 1, 1, 0, 1, 1 } }
		function t:GetWidth() return self.w end
		function t:SetWidth(v) self.w = v end
		function t:GetTexCoord() return unpack(self.c) end
		function t:SetTexCoord(l, r, top, bottom) self.c = { l, top, l, bottom, r, top, r, bottom } end
		return t
	end
	local fake = { classic = { isTab = true, Left = piece(20), LeftActive = piece(20), Middle = piece(40), Right = piece(20), RightActive = piece(20) } }
	n.Classic.TrimTabEnds(fake, 7, 0)
	check(fake.classic.Left.w == 13 and math.abs(fake.classic.Left.c[1] - 7 / 20) < 1e-9 and fake.classic.LeftActive.w == 13, "the first tab's left end loses 7 px, its art cropped from the outside")
	check(fake.classic.Right.w == 20 and fake.classic.Middle.w == 40, "the other end and the middle are untouched")
	n.Classic.TrimTabEnds(fake, 7, 0); n.Classic.TrimTabEnds(fake, 7, 0)
	check(fake.classic.Left.w == 13, "trims never compound")
	n.Classic.TrimTabEnds(fake, 0, 7)
	check(fake.classic.Left.w == 20 and fake.classic.Left.c[1] == 0 and fake.classic.Right.w == 13 and math.abs(fake.classic.Right.c[5] - 13 / 20) < 1e-9, "a tab that stops being the first gets its left end back; now the right end is trimmed")
	check((n.errors or 0) == 0, "no errors")

	-- /bs cpu
	local said = {}
	local oldPrint = n.Print
	n.Print = function(_, fmt, ...) said[#said + 1] = fmt:format(...) end
	_G.C_AddOnProfiler = nil
	SlashCmdList.BAGSMITH("cpu")
	check(said[#said]:find("doesn't report addon CPU time", 1, true), "no profiler on the client: it says so")
	local values = { 0.5, 1.5, 1.0 }
	local i = 0
	_G.C_AddOnProfiler = { GetAddOnMetric = function(addon, metric) i = i + 1; return values[(i - 1) % 3 + 1] end }
	_G.Enum.AddOnProfilerMetric = { LastTime = 4 }
	SlashCmdList.BAGSMITH("cpu 1")
	check(said[#said]:find("Measuring BagSmith for 1 seconds", 1, true), "it starts measuring")
	local f = n.cpuFrame
	for _ = 1, 3 do f:GetScript("OnUpdate")(f, 0.4) end
	check(said[#said]:find("1.00 ms per frame on average, 1.50 ms at most, over 3 frames", 1, true), "and reports the average and the peak: " .. said[#said])
	check(f:GetScript("OnUpdate") == nil and n.cpuRun == nil, "then stops")
	n.Print = oldPrint
	_G.C_AddOnProfiler = nil
end)()

;(function()
	-- (1.8.0-beta15, from Shweep's /bs debug report) a narrow Classic tab: its two ends share it instead of overlapping
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "classic" } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith")
	-- the report's geometry: left end 35 wide at x -3, right end 37 wide ending 3 past the tab's right edge
	local function piece(w, point, x)
		local t = { w = w, c = { 0, 0, 0, 0.778, 1, 0, 1, 0.778 }, pt = { point, nil, point, x, 0 } }
		function t:GetWidth() return self.w end
		function t:SetWidth(v) self.w = v end
		function t:GetTexCoord() return unpack(self.c) end
		function t:SetTexCoord(l, r, top, bottom) self.c = { l, top, l, bottom, r, top, r, bottom } end
		function t:GetPoint() return unpack(self.pt) end
		return t
	end
	local function tab(width)
		local art = { isTab = true, Left = piece(35, "TOPLEFT", -3), Right = piece(37, "TOPRIGHT", 3),
			LeftActive = piece(35, "TOPLEFT", -1), RightActive = piece(37, "TOPRIGHT", 4) }
		return { classic = art, GetWidth = function() return width end }
	end
	local gear = tab(44)   -- 44 + 3 + 3 = 50 between the outer edges; the ends want 72
	n.Classic.FitTabEnds(gear)
	local L, R = gear.classic.Left, gear.classic.Right
	check(L.w + R.w == 50, "Gear: the two ends fill the tab between their outer edges, no overlap: " .. (L.w + R.w))
	check(L.w == 24 and R.w == 26, "each its share, as their widths: " .. L.w .. ", " .. R.w)
	check(L.c[1] == 0 and math.abs(L.c[5] - 24 / 35) < 1e-9 and L.c[4] == 0.778, "the left end keeps its outer (left) edge, cropped from the inside; the height crop kept")
	check(R.c[5] == 1 and math.abs(R.c[1] - (1 - 26 / 37)) < 1e-9, "the right end keeps its outer (right) edge")
	check(gear.classic.LeftActive.w + gear.classic.RightActive.w == 44 + 4 + 1, "the selected set too")
	n.Classic.FitTabEnds(gear); n.Classic.FitTabEnds(gear)
	check(L.w == 24 and math.abs(L.c[5] - 24 / 35) < 1e-9, "fitting again changes nothing (recorded once)")
	local wide = tab(120)
	n.Classic.FitTabEnds(wide)
	check(wide.classic.Left.w == 35 and wide.classic.Right.w == 37 and wide.classic.Left.c[5] == 1, "a wide tab keeps its ends whole")
	check((n.errors or 0) == 0, "no errors")
end)()
