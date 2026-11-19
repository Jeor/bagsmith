-- ======== 1.9.0-beta7 (Shweep, 16 Nov) ========
-- Compact View: "Gear: BOE, why stacked?": a stretched section's icons fill its width, and spare width goes first to a
-- section that then needs a line fewer. Global Columns: "allow AH to be turned off but have it disabled like usual if
-- no addon w/ tooltip explaining", and "Vendor always".

;(function()
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	local C = n.CompactCategories
	local W, CELL, GAP, GUT, GG = 560, 44, 4, 3, 16
	local step = CELL + GAP
	local function lines(box, p) return math.ceil(math.max(1, box.count) / p.across) end
	-- Shweep's screenshot: Gear: BoE (2) beside Food (7, two lines)
	local boxes = { { count = 2, minWidth = 130 }, { count = 7, minWidth = 90 } }
	local rows = C.Rows(boxes, W, CELL, GAP, GUT, GG, 40)
	check(#rows == 1 and #rows[1] == 2, "(setup) one row: Gear: BoE and Food")
	C.Justify(rows, boxes, W, CELL, GAP, GUT, GG)
	local gear, food = rows[1][1], rows[1][2]
	check(lines(boxes[1], gear) == 1 and gear.across == 2, "Gear: BoE: both icons on one line (" .. gear.across .. " across)")
	local used = gear.width + GG + food.width
	check(used == W, "the row still reaches the right edge: " .. used)
	for _, p in ipairs(rows[1]) do
		check(p.across * step - GAP + 2 * GUT <= p.width, "its icons fit its width")
	end
	-- even lines, not an orphan: seven icons with room for six go four and three
	local seven = { { count = 7, minWidth = 60 }, { count = 1, minWidth = 60 } }
	local r = { { { index = 1, across = 3, width = 3 * step - GAP + 2 * GUT }, { index = 2, across = 1, width = 1 * step - GAP + 2 * GUT } } }
	C.Justify(r, seven, 6 * step - GAP + 2 * GUT + GG + (1 * step - GAP + 2 * GUT) + 4, CELL, GAP, GUT, GG)
	local a = r[1][1].across
	check(7 % a == 0 or 7 % a >= a / 2, "seven icons: even lines, not one left alone (" .. a .. " across)")
	-- spare to a section that saves its own line, before stretching: here the whole row can't lose a line (that needs
	-- three more columns, two fit), but Bandages (2, one per line) can, for one
	local two = { { count = 4, minWidth = 60 }, { count = 2, minWidth = 60 } }
	local r2 = { { { index = 1, across = 2, width = 2 * step - GAP + 2 * GUT }, { index = 2, across = 1, width = 1 * step - GAP + 2 * GUT } } }
	C.Justify(r2, two, 2 * step - GAP + 2 * GUT + GG + 1 * step - GAP + 2 * GUT + 2 * step, CELL, GAP, GUT, GG)
	check(lines(two[2], r2[1][2]) == 1 and lines(two[1], r2[1][1]) == 2, "the room went to the two-icon section, now one line; the four stay two lines")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- Global Columns: Vendor always; AH Price tickable, greyed (saying why) without a price source
	package.loaded.mock = nil
	local M = require("mock")
	M.put(0, 1, { id = 2589, name = "Linen Cloth", q = 1, count = 5, class = 7, subclass = 5, type = "Tradeskill", sub = "Cloth", price = 13 })
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { cols = { "c", "v" } } },
		globalInv = { cols = { "c" }, colOrder = { "n", "c" } } }   -- a beta6 player: AH Price was the fixed value column
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local V = n.Window.main
	V.btnGlobal:GetScript("OnClick")(V.btnGlobal); M.runTimers(); M.runTimers()
	local G = n.Inventory:Settings()
	check(n.IndexOf(G.cols, "ah") and G.ahOn, "AH Price starts on in Global Inventory")
	local function plan() local k = {} for _, c in ipairs(V:ColumnPlan()) do k[#k + 1] = c.key end return k end
	local keys = plan()
	local at = n.IndexOf(keys, "n")
	check(keys[at + 1] == "who" and keys[at + 2] == "w" and keys[at + 3] == "v" and not n.IndexOf(keys, "ah"),
		"no price source: Item, Who, Where, Vendor; no AH Price: " .. table.concat(keys, ","))
	local P = n.SettingsPanel
	P:Show(); P:ShowPage("globalcols")
	local rows = {}
	for _, l in ipairs(P.pools.list or {}) do if l:IsShown() then for _, r in ipairs(l.rows) do if r:IsShown() then rows[r.id] = r end end end end
	check(rows.ah and not rows.ah.box:IsEnabled(), "Global Columns: AH Price listed, greyed without a price addon")
	GameTooltip.lines = {}
	local enter = rows.ah.box:GetScript("OnEnter")
	if enter then enter(rows.ah.box) end
	check(table.concat(GameTooltip.lines or {}, " "):find(n.AH.INSTALL_HINT, 1, true) or (rows.ah.tip == n.AH.INSTALL_HINT), "and says why")
	check(not rows.v and not rows.who and not rows.w, "Vendor, Who and Where aren't offered: always shown")
	P:Hide()
	-- with a price source
	n.AH.Available = function() return true end
	n.AH.StackValue = function(_, r) return 100 * (r.count or 1) end
	n:RefreshViews(true); M.runTimers()
	keys = plan()
	check(n.IndexOf(keys, "ah") and keys[at + 3] == "v", "with a price source: AH Price shows, Vendor still fixed: " .. table.concat(keys, ","))
	P:Show(); P:ShowPage("globalcols")
	rows = {}
	for _, l in ipairs(P.pools.list or {}) do if l:IsShown() then for _, r in ipairs(l.rows) do if r:IsShown() then rows[r.id] = r end end end end
	check(rows.ah.box:IsEnabled() and rows.ah.box:GetChecked(), "AH Price usable and ticked")
	rows.ah.box:SetChecked(false); rows.ah.box:GetScript("OnClick")(rows.ah.box); M.runTimers()
	P:Hide()
	keys = plan()
	check(not n.IndexOf(keys, "ah") and keys[at + 3] == "v", "unticked: no AH Price, Vendor stays")
	check(not n.IndexOf(n.db.cols, "ah") and n.IndexOf(n.db.cols, "v"), "your bags' columns untouched")
	n:RefreshViews(true); M.runTimers()
	-- (by design since 1.9.0-beta8: the Total row, not a note by the title)
	check(V.totalRow.cells.v:IsShown() and not V.totalRow.cells.ah:IsShown(), "the Total row: Vendor only, as the AH column is off")
	check((n.errors or 0) == 0, "no errors")
	-- unticked stays unticked after a reload (AH Price is turned on only once)
	local saved = BagSmithDB
	package.loaded.mock = nil
	M = require("mock")
	_G.BagSmithDB = saved; _G.BagSmithCharDB = { version = 1, firstSeen = {} }
	n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	G = n.Inventory:Settings()
	check(G.ahOn and not n.IndexOf(G.cols, "ah"), "after a reload: AH Price still off")
	check((n.errors or 0) == 0, "no errors after the reload")
end)()
