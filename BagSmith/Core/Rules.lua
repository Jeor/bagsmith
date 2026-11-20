--[[
	Core/Rules.lua (1.10.0-beta1)

	Section rules: what makes an item fit one of your custom sections, beside the items you put there yourself.

	A section's rules are { mode = "all" | "any", rows = { row, ... } }. A row is { k = key, v = { value, ... }, n = true
	or nil }: the item's answer for that key is (or, with n, is not) one of the values. Several values in a row mean any
	of them. "all": every row fits; "any": one does.

	Only facts about the item itself are keys (its type, slot, quality, binding): nothing about the moment or where it
	sits, so an item doesn't hop between sections as time passes. A fact the game hasn't supplied yet, or a key this
	version doesn't know (a newer version's, another addon's that isn't installed), never fits, with or without "not":
	the item waits in its usual section.

	This file decides nothing about which section wins: Core/Sections.lua asks Rules:Fits in priority order.
--]]
local ADDON, ns = ...
local R = {}
ns.Rules = R

R.MAX_ROWS, R.MAX_VALUES = 12, 40

local BIND = { bop = "Soulbound", boe = "Binds when equipped", bou = "Binds when used", none = "No binding" }
local QUALITY = { [0] = "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom" }
R.BIND_LABEL, R.QUALITY_LABEL = BIND, QUALITY

-- Each key: its name, whether a saved value is sound, and the item's own answers (a list; nil while not known).
R.KEYS = {
	type = {
		label = "Type",
		valid = function(v) return type(v) == "string" and #v <= 12 and (v:match("^%d+:%d+$") ~= nil or v:match("^%d+:%*$") ~= nil) end,
		of = function(rec)
			if type(rec.classID) ~= "number" then return nil end
			local t = { rec.classID .. ":*" }
			if type(rec.subclassID) == "number" then t[2] = rec.classID .. ":" .. rec.subclassID end
			return t
		end,
	},
	slot = {
		label = "Slot",
		valid = function(v) return type(v) == "string" and #v <= 40 and v:match("^INVTYPE_[%u%d_]+$") ~= nil end,
		of = function(rec)
			local e = rec.equipLoc
			if type(e) ~= "string" then return nil end
			if e == "" then return {} end   -- known: it goes in no slot
			return { e }
		end,
	},
	quality = {
		label = "Quality",
		valid = function(v) return type(v) == "number" and v >= 0 and v <= 7 and v == math.floor(v) end,
		of = function(rec) if type(rec.quality) == "number" then return { rec.quality } end end,
	},
	bind = {
		label = "Binding",
		valid = function(v) return BIND[v] ~= nil end,
		of = function(rec)
			if rec.isBound then return { "bop" } end
			local b = rec.bindType
			if type(b) ~= "number" then return nil end
			if b == 1 then return { "bop" } elseif b == 2 then return { "boe" } elseif b == 3 then return { "bou" } end
			return { "none" }
		end,
	},
}
R.KEY_ORDER = { "type", "slot", "quality", "bind" }

-- A row's values as a set, built once for each row table (never stored in the row: rows are saved data).
local sets = setmetatable({}, { __mode = "k" })
local function setOf(row)
	local s = sets[row]
	if not s then
		s = {}
		for _, v in ipairs(row.v) do s[v] = true end
		sets[row] = s
	end
	return s
end
local function rowFits(row, rec)
	local def = R.KEYS[row.k]
	if not def then return false end
	local have = def.of(rec)
	if have == nil then return false end
	local set, hit = setOf(row), false
	for _, a in ipairs(have) do if set[a] then hit = true; break end end
	if row.n then return not hit end
	return hit
end
local function usable(row) return type(row) == "table" and type(row.k) == "string" and type(row.v) == "table" and #row.v > 0 end

-- Does the item fit these rules? Rows with no values are skipped; rules with no usable row fit nothing.
function R:Fits(rules, rec)
	if type(rules) ~= "table" or type(rules.rows) ~= "table" or type(rec) ~= "table" then return false end
	local any, used = rules.mode == "any", 0
	for _, row in ipairs(rules.rows) do
		if usable(row) then
			used = used + 1
			local ok = rowFits(row, rec)
			if any and ok then return true end
			if not any and not ok then return false end
		end
	end
	return used > 0 and not any
end
function R:HasRules(rules)
	if type(rules) ~= "table" or type(rules.rows) ~= "table" then return false end
	for _, row in ipairs(rules.rows) do if usable(row) then return true end end
	return false
end

-- A clean copy of saved or imported rules (never trusted as they come), or nil when nothing usable is left. A row with
-- a key this version doesn't know is kept as long as it's sound (it fits nothing here; dropping it would make an "all"
-- section take MORE items than its author meant).
function R.Clean(rules)
	if type(rules) ~= "table" or type(rules.rows) ~= "table" then return nil end
	local out = { mode = rules.mode == "any" and "any" or "all", rows = {} }
	for _, row in ipairs(rules.rows) do
		if #out.rows >= R.MAX_ROWS then break end
		if type(row) == "table" and type(row.k) == "string" and #row.k <= 24 and row.k:match("^[%a_]+$") and type(row.v) == "table" then
			local def = R.KEYS[row.k]
			local vals, seen = {}, {}
			for _, v in ipairs(row.v) do
				if #vals >= R.MAX_VALUES then break end
				local ok
				if def then ok = def.valid(v)
				else ok = (type(v) == "string" and #v <= 40) or (type(v) == "number" and v == v and v > -1e9 and v < 1e9) end
				if ok and not seen[v] then seen[v] = true; vals[#vals + 1] = v end
			end
			if #vals > 0 then out.rows[#out.rows + 1] = { k = row.k, v = vals, n = (row.n == true) or nil } end
		end
	end
	if #out.rows == 0 then return nil end
	return out
end

------------------------------------------------------------------------
-- Words
------------------------------------------------------------------------
-- A type's name: the game's own lists where it has them, else what an item of that type in your bags says.
local typeNames = {}
local function gameName(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, name = pcall(fn, ...)
	if ok and type(name) == "string" and name ~= "" and not name:find("OBSOLETE") then return name end
end
local function fromBags(class, sub)
	for _, list in ipairs({ ns.items or {}, ns.bankItems or {} }) do
		for _, r in ipairs(list) do
			if r.classID == class and (sub == nil or r.subclassID == sub) and type(r.itemType) == "string" and r.itemType ~= "" then
				return r.itemType, r.itemSubType
			end
		end
	end
end
function R:TypeLabel(v)
	if typeNames[v] then return typeNames[v] end
	local c, s = tostring(v):match("^(%d+):(.+)$")
	c = tonumber(c)
	if not c then return tostring(v) end
	local sub = tonumber(s)
	local class = gameName(C_Item and C_Item.GetItemClassInfo or rawget(_G, "GetItemClassInfo"), c)
	local subName = sub and gameName(C_Item and C_Item.GetItemSubClassInfo or rawget(_G, "GetItemSubClassInfo"), c, sub) or nil
	if not class or (sub and not subName) then
		local t, st = fromBags(c, sub)
		class = class or t
		if sub then subName = subName or (type(st) == "string" and st ~= "" and st or nil) end
	end
	local label
	if not class then label = sub and ("Type %d:%d"):format(c, sub) or ("Type %d"):format(c)
	elseif not sub then label = class
	elseif not subName or subName == class then label = class
	else label = class .. ": " .. subName end
	-- (kept only once the game or an item has named it: a fallback is asked again later)
	if class and (not sub or subName) then typeNames[v] = label end
	return label
end
function R:ValueLabel(k, v)
	if k == "type" then return self:TypeLabel(v)
	elseif k == "slot" then local s = rawget(_G, tostring(v)); return type(s) == "string" and s ~= "" and s or tostring(v)
	elseif k == "quality" then
		local s = rawget(_G, ("ITEM_QUALITY%d_DESC"):format(tonumber(v) or -1))
		return type(s) == "string" and s ~= "" and s or QUALITY[v] or tostring(v)
	elseif k == "bind" then return BIND[v] or tostring(v) end
	return tostring(v)
end
function R:KeyLabel(k) local def = R.KEYS[k]; return def and def.label or "Another addon's rule" end
-- "Type is Trade Goods: Cloth or Trade Goods: Leather", "Binding is not Soulbound"
function R:RowText(row)
	if not usable(row) then return "" end
	local names = {}
	for i, v in ipairs(row.v) do names[i] = self:ValueLabel(row.k, v) end
	local list = #names <= 2 and table.concat(names, " or ") or (table.concat(names, ", ", 1, #names - 1) .. " or " .. names[#names])
	return ("%s %s %s"):format(self:KeyLabel(row.k), row.n and "is not" or "is", list)
end
-- One line for a section's rules: "Type is Trade Goods: Cloth"; with more rows, "Fits all: A; B" or "Fits any: A; B".
function R:Summary(rules)
	if not self:HasRules(rules) then return "" end
	local parts = {}
	for _, row in ipairs(rules.rows) do if usable(row) then parts[#parts + 1] = self:RowText(row) end end
	if #parts == 1 then return parts[1] end
	return (rules.mode == "any" and "Fits any: " or "Fits all: ") .. table.concat(parts, "; ")
end

-- What an item says about itself, for "New Section From This Item": { k, v, label, text } for each fact it has.
function R:FactsOf(rec)
	local out = {}
	if type(rec) ~= "table" then return out end
	for _, k in ipairs(R.KEY_ORDER) do
		local have = R.KEYS[k].of(rec)
		local v = have and have[#have]   -- the most exact answer (a type's class and subclass, not the class alone)
		if v ~= nil then
			local text
			if k == "type" and type(rec.itemType) == "string" and rec.itemType ~= "" then
				-- the item's own words (the game's lists may not be there to ask)
				local st = rec.itemSubType
				text = (type(st) == "string" and st ~= "" and st ~= rec.itemType) and (rec.itemType .. ": " .. st) or rec.itemType
				if not typeNames[v] then typeNames[v] = text end
			else
				text = self:ValueLabel(k, v)
			end
			out[#out + 1] = { k = k, v = v, label = R.KEYS[k].label, text = text }
		end
	end
	return out
end
