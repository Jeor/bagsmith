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
