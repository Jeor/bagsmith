;(function()
	-- ======== 1.8.0-beta6: Settings keeps its own size, and its page side is 15% wider (Shweep) ========
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "modern", scale = 0.7 } } }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	n.Window:Show(); M.runTimers()
	local P = n.SettingsPanel
	P:Show(); M.runTimers()
	check(math.abs(n.Window.main.frame.scale - 0.7) < 1e-9, "(setup) the bags at 70%")
	check(P.frame.scale == 1, "Settings at full size whatever BagSmith's Scale: " .. tostring(P.frame.scale))
	n:Set("scale", 0.5); M.runTimers()
	check(P.frame.scale == 1 and math.abs(n.Window.main.frame.scale - 0.5) < 1e-9, "changing Scale shrinks the bags, not Settings")
	check(P.frame:GetWidth() == 757, "the window is 757 wide (680 before): " .. tostring(P.frame:GetWidth()))
	local before = 680 - 170
	check(math.abs((757 - 170) / before - 1.15) < 0.01, "the page side, right of the 170 px page list, is 15% wider")
	-- the rows use the wider page
	P:ShowPage("look"); M.runTimers()
	local widest = 0
	for _, w in ipairs(P.pools.step or {}) do if w:IsShown() then widest = math.max(widest, w:GetWidth()) end end
	check(widest == 757 - 12 - 170 - 16 - 34 - 12 - 20, "a setting's row spans the wider page (inside its card's padding): " .. widest .. " (416 before)")
	-- Scale's help says so
	local help
	for _, w in ipairs(P.pools.step or {}) do if w:IsShown() and w.key == "scale" then help = w.help and w.help.text end end
	check(help and help:find("Settings keeps its own size", 1, true), "Scale's help: Settings keeps its own size")
	P:Hide()
	check((n.errors or 0) == 0, "no errors")
end)()
