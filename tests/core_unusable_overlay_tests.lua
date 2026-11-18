-- Real addon integration; only the game's item-tooltip answers are simulated.
for _, skin in ipairs({ "modern", "classic" }) do
	package.loaded.mock = nil
	local M = require("mock")
	local makeTexture = M.tex
	M.tex = function()
		local t = makeTexture()
		t.SetAllPoints = function(self, anchor) self.allPoints = anchor end
		return t
	end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = skin } } }
	_G.ITEM_MIN_SKILL = "Requires %s (%d)"
	_G.ITEM_REQ_SKILL = "Requires %s"
	_G.ITEM_CLASSES_ALLOWED = "Classes: %s"
	_G.ITEM_REQ_ABILITY = "Requires %s"
	local tip, calls = nil, 0
	_G.C_TooltipInfo = { GetHyperlink = function() calls = calls + 1; return tip end }
	local n = M.loadAddon("BagSmith")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	check(n.db.unusableOverlay == true, skin .. ": enabled by default")
	check(n.Usability ~= nil, "usability module is loaded")
	if n.Usability then
		local U = n.Usability
		-- Forever files edible raw fish under Trade Goods, not Consumable.
		local oldLevel, oldSpell = UnitLevel, C_Item.GetItemSpell
		_G.UnitLevel = function() return 29 end
		C_Item.GetItemSpell = function(id) if id == 4603 then return "Food", 433 end end
		local fish = {itemID=4603, link="item:4603", name="Raw Spotted Yellowtail", classID=7,
			minLevel=35, count=1, quality=1, icon=123, isCraftingReagent=true}
		check(U:IsUnusable(fish), "level-29 character cannot eat level-35 raw fish filed as Trade Goods")
		local fishButton = n.Buttons:GetCached(CreateFrame("Frame"), 1)
		n.Buttons:SetMode(fishButton, "cell"); n.Buttons:Fill(fishButton, fish)
		check(fishButton.unusableOverlay and fishButton.unusableOverlay:IsShown(), "raw fish gets a visible red wash")
		_G.UnitLevel = function() return 35 end; U:Invalidate()
		n.Buttons:Fill(fishButton, fish)
		check(not (fishButton.unusableOverlay and fishButton.unusableOverlay:IsShown()), "raw fish clears at the required level")
		_G.UnitLevel = function() return 29 end
		C_Item.GetItemSpell = function() return nil end; U:Invalidate()
		check(not U:IsUnusable(fish), "unknown use action remains unmarked")
		C_Item.GetItemSpell = function() error("not loaded") end
		check(not U:IsUnusable(fish), "unavailable use-spell API remains unmarked")
		_G.UnitLevel, C_Item.GetItemSpell = oldLevel, oldSpell
		local rec = { itemID = 100, link = "item:100", classID = 2, name = "Test", count = 2, quality = 2, icon = 123, minLevel = 40, itemSubType = "Swords" }
		for _, class in ipairs({2, 4, 9, 0}) do rec.classID = class; check(U:IsUnusable(rec), "unmet level for class " .. class) end
		rec.classID = 7; check(not U:IsUnusable(rec), "materials not flagged")
		rec.classID, rec.minLevel = 9, 1
		local function answer(text, red, right)
			tip = { lines = {{ leftText = "Test" }, { [right and "rightText" or "leftText"] = text, [right and "rightColor" or "leftColor"] = { r = red and 1 or 1, g = red and 0.1 or 1, b = red and 0.1 or 1 } }} }
			U:Invalidate()
		end
		answer("Requires Alchemy (150)", true); check(U:IsUnusable(rec), "red skill requirement")
		answer("Requires Alchemy (150)", false); check(not U:IsUnusable(rec), "met skill requirement")
		answer("Classes: Mage", true); check(U:IsUnusable(rec), "class restriction")
		rec.classID = 2; answer("Swords", true, true); check(U:IsUnusable(rec), "unlearned weapon proficiency")
		for _, text in ipairs({"Cooldown remaining: 10 sec", "Already Known", "Not enough mana", "You are in combat", "Requires a target"}) do
			answer(text, true); check(not U:IsUnusable(rec), "ignore temporary/known text: " .. text)
		end
		_G.ITEM_MIN_SKILL = "Benötigt %1$s (%2$d)"
		answer("Benötigt Alchemie (150)", true); check(U:IsUnusable(rec), "localized positional requirement")
		_G.ITEM_MIN_SKILL = "Requires %s (%d)"
		local oldTypes = Enum.TooltipDataLineType
		Enum.TooltipDataLineType = { RestrictedSkill = 23, RestrictedSpellKnown = 26 }
		tip = {lines={{leftText="Test"},{type=23,leftText="Requires Alchemy",leftColor={r=1,g=0,b=0}}}}
		U:Invalidate(); check(U:IsUnusable(rec), "typed missing profession without a rank")
		tip.lines[2].type = 26; U:Invalidate(); check(not U:IsUnusable(rec), "known recipe is excluded")
		Enum.TooltipDataLineType = oldTypes
		tip = {lines={{}}}; U:Invalidate(); check(not U:IsUnusable(rec), "partial data is unknown")
		tip = {lines={{leftText="Test"},{leftText="Requires Alchemy (150)",leftColor={r=1,g=0,b=0}}}}
		check(U:IsUnusable(rec), "partial data is retried without an event")
		tip = nil; U:Invalidate(); check(not U:IsUnusable(rec), "missing tooltip unknown")
		tip = {lines={{leftText="Requires Alchemy (150)",leftColor={r=1,g=0,b=0}}}}
		check(U:IsUnusable(rec), "unknown is retried when data arrives")
		local before = calls; U:IsUnusable(rec); check(calls == before, "conclusive result cached")
		local getter = C_TooltipInfo.GetHyperlink
		C_TooltipInfo.GetHyperlink = function() error("item data unavailable") end
		U:Invalidate(); check(not U:IsUnusable(rec), "throwing tooltip API stays unmarked")
		C_TooltipInfo.GetHyperlink = getter
		check(U:IsUnusable(rec), "API error does not poison cache")
		local create, structured, hidden = CreateFrame, C_TooltipInfo, false
		local legacyText = "Requires Alchemy (150)"
		_G.CreateFrame = function(kind, name, parent, template)
			if name ~= "BagSmithUsabilityTooltip" then return create(kind, name, parent, template) end
			_G.BagSmithUsabilityTooltipTextLeft1 = {GetText=function() return "Test" end, GetTextColor=function() return 1,1,1 end}
			_G.BagSmithUsabilityTooltipTextLeft2 = {GetText=function() return legacyText end, GetTextColor=function() return 1,0,0 end}
			return { SetOwner=function() end, ClearLines=function() end, SetHyperlink=function() hidden=false end,
				NumLines=function() return 2 end, Hide=function() hidden=true end }
		end
		_G.C_TooltipInfo = nil; U:Invalidate()
		check(U:IsUnusable(rec) and hidden, "legacy tooltip reads profession requirement and stays hidden")
		legacyText = "Requires a target"; U:Invalidate()
		check(not U:IsUnusable(rec), "legacy tooltip ignores temporary requirements")
		_G.CreateFrame, _G.C_TooltipInfo = create, structured
		_G.BagSmithUsabilityTooltipTextLeft1, _G.BagSmithUsabilityTooltipTextLeft2 = nil, nil
		U:Invalidate()
		local b = n.Buttons:GetCached(CreateFrame("Frame"), 1)
		for _, mode in ipairs({"cell", "row"}) do
			n.Buttons:SetMode(b, mode); n.Buttons:Fill(b, rec)
			check(b.unusableOverlay and b.unusableOverlay:IsShown(), skin .. " " .. mode .. ": red wash visible")
			local t = b.unusableOverlay
			check(t and t.color[1] == 1 and t.color[4] == 0.25, "translucent red at 25 percent")
			check(t and t.allPoints == b.icon, "wash bound to icon, not row")
			check(t and t.layer == "ARTWORK" and t.sublayer == 7, "wash below border and label layers")
			n:Set("unusableOverlay", false); check(not t:IsShown(), "toggle clears immediately")
			n:Set("unusableOverlay", true); check(t:IsShown(), "toggle restores immediately")
			rec.classID = 7; n.Buttons:Fill(b, rec); check(not t:IsShown(), "reuse clears wash")
			rec.classID = 2; n.Buttons:Fill(b, rec); n.Buttons:Blank(b, {}); check(not t:IsShown(), "empty clears wash")
		end
		rec.minLevel = 40; tip = nil; U:Invalidate(); n.Buttons:Fill(b, rec)
		_G.UnitLevel = function() return 40 end
		M.fire("PLAYER_LEVEL_UP", 40); M.runTimers(); M.runTimers()
		check(not b.unusableOverlay:IsShown(), "level-up refreshes existing button")
		rec.minLevel = 60; rec.globalChild = true; n.Buttons:Fill(b, rec)
		check(not b.unusableOverlay:IsShown(), "class portrait is not an item icon")
		rec.globalChild = nil
		rec.minLevel = 1
		answer("Requires Alchemy (150)", true); n.Buttons:Fill(b, rec)
		tip = {lines={{leftText="Requires Alchemy (150)",leftColor={r=1,g=1,b=1}}}}
		M.fire("SKILL_LINES_CHANGED"); M.runTimers(); M.runTimers()
		check(not b.unusableOverlay:IsShown(), "training refreshes existing overlays")
		before = calls; n:Set("unusableOverlay", false); n.Buttons:Fill(b, rec)
		check(calls == before, "disabled overlay avoids tooltip scans")
		n:Set("unusableOverlay", true)
		n.Buttons:Create(CreateFrame("Frame"))
		local live = n.Buttons:Get(0, 1)
		rec.minLevel = 60; n.Buttons:SetMode(live, "cell"); n.Buttons:Fill(live, rec)
		check(live.secure and live.unusableOverlay:IsShown(), "secure live item gets overlay")
		M.combat = true; n:Set("unusableOverlay", false)
		check(not live.unusableOverlay:IsShown(), "toggle clears secure button in combat")
		n:Set("unusableOverlay", true); check(live.unusableOverlay:IsShown(), "toggle restores in combat")
		M.combat = false
		n.SettingsPanel:Show(); n.SettingsPanel:ShowPage("icons")
		local found = false
		for _, w in ipairs(n.SettingsPanel.pools.check) do if w:IsShown() and w.key == "unusableOverlay" then found = true end end
		check(found, "toggle on Item Icons page")
		check((n.errors or 0) == 0, "no addon errors")
	end
end
