-- ======== 1.9.3-beta1 (Shweep, 19 Nov) ========
-- "unusable items is not working perfectly - noticed it thinks I can use a gun and sword as a priest - the leather
-- pants tho are correctly red". The overlay took a red type on a weapon or armor only when it matched the item's type
-- name, but the game's type names ("Guns", "One-Handed Swords", "Staves", "Shields") aren't what the tooltip says ("Gun",
-- "Sword", "Staff", "Shield"); only cloth, leather, mail and plate matched. Now the red text on the right of the item's
-- slot line counts, the slot's name being the game's own (INVTYPE_*). The tooltip lines below are the game's: Shweep's
-- gun on a priest, read in game (19 Nov), "Ranged | Gun" in (1, 0.1255, 0.1255), then "9 - 19 Damage | Speed 1.90" in
-- white; INVTYPE_RANGEDRIGHT "Ranged", INVTYPE_WEAPON "One-Hand".

local RED = { r = 1, g = 0.12549020349979, b = 0.12549020349979 }
local WHITE = { r = 1, g = 1, b = 1 }
local SLOTS = { INVTYPE_RANGEDRIGHT = "Ranged", INVTYPE_RANGED = "Ranged", INVTYPE_WEAPON = "One-Hand", INVTYPE_2HWEAPON = "Two-Hand",
	INVTYPE_SHIELD = "Off Hand", INVTYPE_RELIC = "Relic", INVTYPE_LEGS = "Legs", INVTYPE_ROBE = "Chest" }
-- id, name, class, the game's type name, slot, the tooltip's type, red (a priest can't use it)
local ITEMS = {
	{ 20001, "Hunting Rifle", 2, "Guns", "INVTYPE_RANGEDRIGHT", "Gun", true },
	{ 20002, "Short Sword", 2, "One-Handed Swords", "INVTYPE_WEAPON", "Sword", true },
	{ 20003, "Hunting Bow", 2, "Bows", "INVTYPE_RANGED", "Bow", true },
	{ 20004, "Battered Buckler", 4, "Shields", "INVTYPE_SHIELD", "Shield", true },
	{ 20005, "Libram of Grace", 4, "Librams", "INVTYPE_RELIC", "Libram", true },
	{ 20006, "Leather Pants", 4, "Leather", "INVTYPE_LEGS", "Leather", true },
	{ 20007, "Gnarled Staff", 2, "Staves", "INVTYPE_2HWEAPON", "Staff", false },
	{ 20008, "Worn Dagger", 2, "Daggers", "INVTYPE_WEAPON", "Dagger", false },
	{ 20009, "Lesser Magic Wand", 2, "Wands", "INVTYPE_RANGEDRIGHT", "Wand", false },
	{ 20010, "Linen Robe", 4, "Cloth", "INVTYPE_ROBE", "Cloth", false },
}
local BY = {}
for _, it in ipairs(ITEMS) do BY[it[1]] = it end

local function tipFor(it, red)
	return { lines = {
		{ leftText = it[2] },
		{ leftText = "Binds when equipped" },
		{ leftText = _G[it[5]], rightText = it[6], rightColor = red and RED or WHITE },
		{ leftText = "9 - 19 Damage", rightText = "Speed 1.90", leftColor = WHITE, rightColor = WHITE },
	} }
end

local function boot(redFor)
	package.loaded.mock = nil
	local M = require("mock")
	for k, v in pairs(SLOTS) do _G[k] = v end
	for i, it in ipairs(ITEMS) do
		M.put(0, i, { id = it[1], name = it[2], q = 2, count = 1, class = it[3], subclass = 1, type = it[3] == 2 and "Weapon" or "Armor", sub = it[4], equip = it[5], price = 10 })
	end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { view = "icons" } } }
	_G.C_TooltipInfo = { GetHyperlink = function(link)
		local it = BY[tonumber(tostring(link):match("item:(%d+)"))]
		if not it then return { lines = { { leftText = "Linen Cloth" }, { leftText = "Trade Goods" } } } end
		local red = it[7]
		if redFor then red = redFor(it) end
		return tipFor(it, red)
	end }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	return n, M
end
local function rec(it) return { itemID = it[1], link = "item:" .. it[1], classID = it[3], itemSubType = it[4], equipLoc = it[5], count = 1, quality = 2, icon = 1 } end

;(function()
	-- the rule itself, item by item, on a priest
	local n = boot()
	local U = n.Usability
	for _, it in ipairs(ITEMS) do
		local want = it[7]
		check(U:IsUnusable(rec(it)) == want, ("%s (%s, the game's type \"%s\"): %s"):format(it[2], it[6], it[4], want and "red" or "not red"))
	end
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- in the bags: the gun and the sword tinted, the wand not
	local n, M = boot()
	n.Window:Show(); M.runTimers(); M.runTimers()
	local function tinted(id)
		local t
		n.Buttons:EachLive(function(b) if b.hasItem and b.rec and b.rec.itemID == id then t = b.unusableOverlay and b.unusableOverlay:IsShown() or false end end)
		return t
	end
	check(tinted(20001) == true and tinted(20002) == true, "the bags: the gun and the sword tinted red")
	check(tinted(20009) == false and tinted(20007) == false, "the wand and the staff not")
	check(tinted(20006) == true, "the leather pants still red")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- only the slot line's right side counts
	local n = boot()
	local U = n.Usability
	_G.C_TooltipInfo.GetHyperlink = function()
		return { lines = { { leftText = "Hunting Rifle" }, { leftText = "Ranged", rightText = "Gun", rightColor = WHITE },
			{ leftText = "9 - 19 Damage", rightText = "Speed 1.90", rightColor = RED } } }
	end
	U:Invalidate()
	check(not U:IsUnusable(rec(BY[20001])), "red on another line's right side (not the slot line): not red")
	_G.C_TooltipInfo.GetHyperlink = function()
		return { lines = { { leftText = "Hunting Rifle" }, { leftText = "Ranged", leftColor = RED, rightText = "Gun", rightColor = WHITE } } }
	end
	U:Invalidate()
	check(not U:IsUnusable(rec(BY[20001])), "the slot's name red, the type white: not red")
	-- an item whose slot isn't known yet (its data still loading): the old rule, no error
	_G.C_TooltipInfo.GetHyperlink = function() return tipFor(BY[20006], true) end
	U:Invalidate()
	local r = rec(BY[20006]); r.equipLoc = nil
	check(U:IsUnusable(r), "no slot known: leather still caught by its type name")
	r = rec(BY[20001]); r.equipLoc = nil
	_G.C_TooltipInfo.GetHyperlink = function() return tipFor(BY[20001], true) end
	U:Invalidate()
	check(not U:IsUnusable(r), "no slot known: the gun waits (nothing to match its line to)")
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- any language: the slot's name and the type come from the game
	local n = boot()
	local U = n.Usability
	_G.INVTYPE_RANGEDRIGHT = "Distance"
	_G.C_TooltipInfo.GetHyperlink = function()
		return { lines = { { leftText = "Fusil de chasse" }, { leftText = "Distance", rightText = "Fusil", rightColor = RED } } }
	end
	U:Invalidate()
	local r = rec(BY[20001]); r.itemSubType = "Fusils"
	check(U:IsUnusable(r), "French: \"Distance | Fusil\" in red, the type name \"Fusils\": red")
	_G.INVTYPE_RANGEDRIGHT = "Ranged"
	check((n.errors or 0) == 0, "no errors")
end)()

;(function()
	-- a skill learned (a warrior's Polearms, a hunter's Guns): the game's line turns white, the tint goes
	local learned = false
	local n, M = boot(function(it) if it[1] == 20001 then return not learned end return it[7] end)
	n.Window:Show(); M.runTimers(); M.runTimers()
	local function tinted(id)
		local t
		n.Buttons:EachLive(function(b) if b.hasItem and b.rec and b.rec.itemID == id then t = b.unusableOverlay and b.unusableOverlay:IsShown() or false end end)
		return t
	end
	check(tinted(20001) == true, "Guns not learned: the gun red")
	learned = true
	M.fire("SKILL_LINES_CHANGED"); M.runTimers()
	check(tinted(20001) == false, "Guns learned: the tint goes")
	check(tinted(20002) == true, "the sword stays red")
	check((n.errors or 0) == 0, "no errors")
end)()
