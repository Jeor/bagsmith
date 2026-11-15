;(function()
	-- ======== 1.8.0-beta9: each special bag's indicator style: Inner Glow (default) or Frame Color (Shweep) ========
	-- Frame Color: the slot's frame in the kind's color and opacity instead of the item's rarity color, empty slots too.
	for _, skin in ipairs({ "modern", "classic" }) do
		local S = skin .. ": "
		package.loaded.mock = nil
		local M = require("mock")
		M.sizes[3] = 6; M.bagNames[3] = "Herb Pouch"
		M.put(3, 1, { id = 2447, name = "Peacebloom", q = 2, count = 3, class = 7, subclass = 9, type = "Tradeskill", sub = "Herb", price = 5 })
		local realInstant = C_Item.GetItemInfoInstant
		C_Item.GetItemInfoInstant = function(item)
			if type(item) == "string" and item:find("%[Herb Pouch%]") then return 1, "Container", "", "INVTYPE_BAG", 1, 1, 2 end
			return realInstant(item)
		end
		_G.BagSmithCharDB = { version = 1, firstSeen = {} }
		_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin, glow_herb = true, border = "all" } } }
		local n = M.loadAddon("BagSmith")
		M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
		n.Window:Show(); n.ui.bagWindows = true; n:RefreshViews(true); M.runTimers(); M.runTimers()
		local function cell(slot) return n.Buttons.mirrors[n.Window.bagViews[3].child][slot] end
		local function frameColor(b)
			if skin == "modern" then
				local e = b.modernBorder and b.modernBorder[1]
				return (e and e:IsShown() and e.color) or nil
			end
			return (b.qFrame and b.qFrame:IsShown() and b.qFrame.color) or nil
		end
		check(n.db.glowStyle_herb == "glow", S .. "Inner Glow by default")
		check(cell(2).bagGlow and cell(2).bagGlow:IsShown(), S .. "(setup) Inner Glow: the empty slot glows")
		local hr, hg, hb = n:BagKindColor("herb")
		n:Set("glowStyle_herb", "frame"); M.runTimers()
		check(not (cell(2).bagGlow and cell(2).bagGlow:IsShown()) and not (cell(1).bagGlow and cell(1).bagGlow:IsShown()), S .. "Frame Color: no glow")
		local c = frameColor(cell(1))
		check(c and math.abs(c[1] - hr) < 1e-6 and math.abs(c[2] - hg) < 1e-6 and math.abs(c[3] - hb) < 1e-6, S .. "the Peacebloom's frame is the herb bag's color, not its rarity green")
		local e = frameColor(cell(2))
		check(e and math.abs(e[1] - hr) < 1e-6, S .. "an empty slot gets the frame too")
		n:Set("glowAlpha_herb", 0.5); M.runTimers()
		check(math.abs(frameColor(cell(1))[4] - 0.5) < 1e-9, S .. "at the kind's opacity")
		n:Set("glowItems_herb", false); M.runTimers()
		c = frameColor(cell(1))
		check(c and math.abs(c[1] - hr) > 0.01, S .. "Show on Herb Bag Items Too off: the Peacebloom's frame is its rarity color again")
		check(frameColor(cell(2)) ~= nil, S .. "and the empty slot keeps the indicator")
		n:Set("glow_herb", false); M.runTimers()
		check(frameColor(cell(2)) == nil, S .. "the indicator off: an empty slot has no frame again")
		check(n:Set("glowStyle_herb", "sparkles") == false and n.db.glowStyle_herb == "frame", S .. "only Inner Glow or Frame Color")
		check((n.errors or 0) == 0, S .. "no errors")
	end
end)()
