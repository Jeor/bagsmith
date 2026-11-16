--[[
	BagSmith - Core/Inventory.lua (1.9.0)
	What BagSmith knows about an item, in its tooltip (Shweep, 16 Nov): an Inventory block with the total and each of
	your characters' counts by place (Bags, Bank, Equipped), on any item tooltip (your bags, the auction house, a vendor,
	a chat link, loot). And your gold, on the footer's gold: each character's on this realm, Shift for the account.

	Whose: your characters on this realm (on WoW Forever the realm is the ruleset, Normal and the others, and characters
	on one can mail each other), the one you're playing included, by name only. Where: the bags (with the keyring and
	the reagent bag), the bank (as of that character's last visit) and what they're wearing. Mail is left out: it
	expires, returns and moves between characters unseen, so its counts could be wrong.

	The counts are worked out once and kept: your other characters' when their saved data changes, yours when your
	bags, bank or gear change. A tooltip only looks its item up.
--]]

local ADDON, ns = ...
local Inv = {}
ns.Inventory = Inv

Inv.PLACES = { "bags", "bank", "equipped" }
Inv.PLACE_LABEL = { bags = "Bags", bank = "Bank", equipped = "Equipped" }
Inv.COUNT_COLOR = { 0.55, 0.78, 1 }   -- the counts' soft blue (as the screenshot Shweep sent)

local others, mine = nil, nil   -- itemID -> { [charKey] = { bags = n, bank = n, equipped = n } }

local function realm() return GetRealmName and GetRealmName() or nil end
local function add(index, id, key, place, n)
	id = tonumber(id)
	if not id or (n or 0) <= 0 then return end
	local byChar = index[id]
	if not byChar then byChar = {}; index[id] = byChar end
	local c = byChar[key]
	if not c then c = {}; byChar[key] = c end
	c[place] = (c[place] or 0) + n
end
local function addList(index, list, key, place)
	for _, r in ipairs(list or {}) do
		if type(r) == "table" and r.itemID then add(index, r.itemID, key, place, tonumber(r.count) or 1) end
	end
end

-- Your other characters on this realm, from their saved data.
function Inv:Others()
	if others then return others end
	others = {}
	local me, here = ns:CharKey(), realm()
	for key, data in pairs(BagSmithDB and BagSmithDB.cache or {}) do
		if key ~= me and not ns:IsOwnKey(key) and type(data) == "table" and data.realm == here then
			addList(others, data.items, key, "bags")
			addList(others, data.bank, key, "bank")
			addList(others, data.equipped, key, "equipped")
		end
	end
	return others
end
-- The one you're playing, live: the bags now, the bank as last seen (this session, or saved), what you're wearing.
function Inv:Mine()
	if mine then return mine end
	mine = {}
	local me = ns:CharKey()
	addList(mine, ns.items, me, "bags")
	local bank = (ns.bankItems and #ns.bankItems > 0) and ns.bankItems or (ns.SavedBank and ns:SavedBank())
	addList(mine, bank, me, "bank")
	addList(mine, Inv.Worn(), me, "equipped")
	return mine
end
function Inv:Invalidate(all) mine = nil; if all then others = nil end end

-- What you're wearing (slots 1 to 19), as { slot, itemID, link, count }: saved with each character, counted live.
function Inv.Worn()
	local out = {}
	if type(GetInventoryItemID) ~= "function" then return out end
	for slot = 1, 19 do
		local id = GetInventoryItemID("player", slot)
		if id then out[#out + 1] = { slot = slot, itemID = id, link = GetInventoryItemLink and GetInventoryItemLink("player", slot) or nil, count = 1 } end
	end
	return out
end

-- One item's counts: a list of { key, name, class, isMe, total, bags, bank, equipped }, you first, then the most, then
-- by name; and the total.
function Inv:Counts(itemID)
	itemID = tonumber(itemID)
	if not itemID then return {}, 0 end
	local me = ns:CharKey()
	local list, total = {}, 0
	local function take(byChar)
		for key, c in pairs(byChar or {}) do
			local data = BagSmithDB and BagSmithDB.cache and BagSmithDB.cache[key]
			local e = { key = key, isMe = key == me, bags = c.bags or 0, bank = c.bank or 0, equipped = c.equipped or 0 }
			e.total = e.bags + e.bank + e.equipped
			if key == me then
				e.name = ns.DisplayName and ns:DisplayName("player") or (UnitName and UnitName("player")) or "?"
				-- (beta2, Shweep: the character you're on showed no class icon) both of UnitClass's values: "x and f()" keeps only one
				local class
				if UnitClass then class = select(2, UnitClass("player")) end
				e.class = class
			else
				e.name, e.class = data and data.name or key:match("^(.-) %- ") or key, data and data.class
			end
			if e.total > 0 then list[#list + 1] = e; total = total + e.total end
		end
	end
	take(self:Mine()[itemID])
	take(self:Others()[itemID])
	table.sort(list, function(a, b)
		if a.isMe ~= b.isMe then return a.isMe end
		if a.total ~= b.total then return a.total > b.total end
		return (a.name or "") < (b.name or "")
	end)
	return list, total
end

-- A class's icon, inline in a tooltip line (the game's class icons sheet).
function Inv.ClassIcon(class, size)
	local c = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
	if not c then return "" end
	size = size or 14
	return ("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:%d:%d:0:0:256:256:%d:%d:%d:%d|t "):format(size, size,
		math.floor(c[1] * 256 + 0.5), math.floor(c[2] * 256 + 0.5), math.floor(c[3] * 256 + 0.5), math.floor(c[4] * 256 + 0.5))
end
local function hex(r, g, b) return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)) end
function Inv.Places(e)
	local parts = {}
	for _, p in ipairs(Inv.PLACES) do if (e[p] or 0) > 0 then parts[#parts + 1] = ("%s: %d"):format(Inv.PLACE_LABEL[p], e[p]) end end
	return table.concat(parts, ", ")
end

-- The Inventory block, on an item's tooltip.
function Inv:AddTooltipLines(tip, itemID)
	if not (tip and ns.db and ns.db.tipInventory) then return end
	local list, total = self:Counts(itemID)
	if total <= 0 then return end
	local br, bg, bb = unpack(self.COUNT_COLOR)
	if tip.AddLine then tip:AddLine(" ") end
	if tip.AddDoubleLine then
		tip:AddDoubleLine("Inventory", ("Total: %d"):format(total), 1, 0.82, 0, br, bg, bb)
		for _, e in ipairs(list) do
			local r, g, b = ns.ClassColor(e.class)
			tip:AddDoubleLine(self.ClassIcon(e.class) .. hex(r, g, b) .. (e.name or "?") .. "|r", self.Places(e), 1, 1, 1, br, bg, bb)
		end
	end
	if tip.Show then tip:Show() end
end

-- The tooltip's item: the game's tooltip data when it has it, else its link.
local function itemOf(tip, data)
	if type(data) == "table" and tonumber(data.id) then return tonumber(data.id) end
	local link = tip and tip.GetItem and select(2, tip:GetItem())
	local id = link and link:match("item:(%d+)")
	return tonumber(id)
end
Inv.ItemOf = itemOf
-- The game's own item tooltips: the one you hover with, and a chat link's (shopping comparisons and other addons' are left alone).
local function ours(tip) return tip ~= nil and (tip == _G.GameTooltip or tip == _G.ItemRefTooltip) end
function Inv:InstallTooltipHook()
	if self.hooked then return end
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data)
			if ours(tip) then ns:Guard("Inventory tooltip", Inv.AddTooltipLines, Inv, tip, itemOf(tip, data)) end
		end)
		self.hooked = "TooltipDataProcessor"
	else
		for _, name in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
			local tip = _G[name]
			if tip and tip.HookScript then
				tip:HookScript("OnTooltipSetItem", function(t) ns:Guard("Inventory tooltip", Inv.AddTooltipLines, Inv, t, itemOf(t)) end)
			end
		end
		self.hooked = "OnTooltipSetItem"
	end
end

------------------------------------------------------------------------
-- Gold
------------------------------------------------------------------------
-- Your gold: { key, name, class, gold, isMe } for this realm's characters (or every realm's, account = true), you first
-- then the most; and the total.
function Inv:Gold(account)
	local me, here = ns:CharKey(), realm()
	local list, total = {}, 0
	local function push(e) list[#list + 1] = e; total = total + e.gold end
	local live = GetMoney and GetMoney() or 0
	local myClass
	if UnitClass then myClass = select(2, UnitClass("player")) end
	push({ key = me, isMe = true, gold = live, class = myClass, name = ns.DisplayName and ns:DisplayName("player") or (UnitName and UnitName("player")) or "?" })
	for key, data in pairs(BagSmithDB and BagSmithDB.cache or {}) do
		if key ~= me and not ns:IsOwnKey(key) and type(data) == "table" and (account or data.realm == here) then
			local g = tonumber(data.gold) or 0
			if g > 0 then push({ key = key, gold = g, class = data.class, name = data.name or key }) end
		end
	end
	table.sort(list, function(a, b)
		if a.isMe ~= b.isMe then return a.isMe end
		if a.gold ~= b.gold then return a.gold > b.gold end
		return (a.name or "") < (b.name or "")
	end)
	return list, total
end
local function coins(v) return (GetMoneyString and GetMoneyString(v or 0, true)) or (GetCoinTextureString and GetCoinTextureString(v or 0)) or tostring(v or 0) end
-- The gold tooltip's lines (the footer's gold button). Shift shows the account.
function Inv:AddGoldLines(tip)
	local account = IsShiftKeyDown and IsShiftKeyDown() and true or false
	local list, total = self:Gold(account)
	tip:AddDoubleLine(account and "Account-wide gold" or "Realm-wide gold", coins(total), 1, 0.82, 0, 1, 1, 1)
	for _, e in ipairs(list) do
		local r, g, b = ns.ClassColor(e.class)
		tip:AddDoubleLine(self.ClassIcon(e.class) .. hex(r, g, b) .. (e.name or "?") .. "|r", coins(e.gold), 1, 1, 1, 1, 1, 1)
	end
	-- (beta2, Shweep) what Shift does, always said, small and dim
	if not account then
		tip:AddLine("Shift - See all Rulesets", 0.5, 0.5, 0.5)
		Inv.SmallLine(tip)
	end
end
-- The tooltip's last line in the small font; put back the next time the tooltip is cleared (its lines are reused).
function Inv.SmallLine(tip)
	local n = tip and tip.NumLines and tip:NumLines()
	local name = tip and tip.GetName and tip:GetName()
	local fs = n and name and _G[name .. "TextLeft" .. n]
	if not (fs and fs.SetFontObject and _G.GameTooltipTextSmall) then return end
	fs:SetFontObject(_G.GameTooltipTextSmall)
	Inv.smallLines = Inv.smallLines or {}
	Inv.smallLines[fs] = true
	if not Inv.restoreHooked and tip.HookScript then
		Inv.restoreHooked = true
		local function restore() for line in pairs(Inv.smallLines) do if _G.GameTooltipText then line:SetFontObject(_G.GameTooltipText) end end; Inv.smallLines = {} end
		tip:HookScript("OnHide", restore)
		pcall(tip.HookScript, tip, "OnTooltipCleared", restore)
	end
end

------------------------------------------------------------------------
-- Keeping the counts current
------------------------------------------------------------------------
ns:OnSignal("ADDON_READY", function()
	Inv:InstallTooltipHook()
	ns:OnSignal("ITEMS_CHANGED", function() Inv:Invalidate() end)
	ns:OnSignal("BANK_OPENED", function() Inv:Invalidate() end)
	ns:On("PLAYER_EQUIPMENT_CHANGED", function() Inv:Invalidate() end)
	-- the gold tooltip follows Shift while it's up
	ns:On("MODIFIER_STATE_CHANGED", function(key)
		local owner = Inv.goldOwner
		if owner and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(owner) and owner.ShowGoldTip and tostring(key or ""):find("SHIFT") then
			owner:ShowGoldTip(true)
		end
	end)
end)
