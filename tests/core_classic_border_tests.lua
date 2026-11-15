-- Client template art changes across game versions. Exercise the production
-- border renderer with deliberately different atlas/file-backed templates.
local ns = { db = { skin = "classic", border = "all" }, OnSignal = function() end }
C_Item = { GetItemQualityColor = function(q) return q == 2 and 0 or 1, 1, q == 2 and 0 or 1 end }
assert(loadfile("BagSmith/Core/Buttons.lua"))("BagSmith", ns)
local B = ns.Buttons
local function texture()
	return setmetatable({ points = {}, coords = { 0, 0, 0, 1, 1, 0, 1, 1 } }, { __index = {
		SetTexture = function(t, f) t.file, t.atlas = f, nil end,
		GetTexture = function(t) return t.file end,
		SetAtlas = function(t, a) t.atlas = a end,
		GetAtlas = function(t) return t.atlas end,
		SetTexCoord = function(t, ...) t.coords = { ... } end,
		GetTexCoord = function(t) return unpack(t.coords) end,
		SetVertexColor = function(t, ...) t.color = { ... } end,
		Show = function(t) t.shown = true end, Hide = function(t) t.shown = false end,
		ClearAllPoints = function(t) t.points = {}; t.allPoints = nil end,
		SetPoint = function(t, ...) t.points[#t.points + 1] = { ... } end,
		SetAllPoints = function(t, relative) t.allPoints = relative end,
		SetSize = function(t, w, h) t.w, t.h = w, h end,
		SetWidth = function(t, w) t.w = w end, SetHeight = function(t, h) t.h = h end,
		GetRect = function() return 100, 200, 37, 37 end,
	} })
end
local function button(source)
	local b = { mode = "cell", icon = texture(), IconBorder = source,
		CreateTexture = function() return texture() end, GetEffectiveScale = function() return 1 end }
	B.AddFrame(b)
	return b
end
for _, kind in ipairs({ "atlas", "file" }) do
	B.borderArt = nil; B.all = {}
	local source = texture()
	if kind == "atlas" then source:SetAtlas("client-bag-border")
	else source:SetTexture(123456); source:SetTexCoord(.1, .2, .1, .8, .9, .2, .9, .8) end
	local live = button(source)
	B.all[1] = live
	local cached = button()
	for _, b in ipairs({ live, cached }) do
		ns.db.skin = "classic"
		for _, setting in ipairs({ "all", "unc", "off" }) do
			for _, q in ipairs({ 1, 2 }) do
				ns.db.border = setting
				B:ApplyQuality(b, { quality = q })
				check(b.qFrame.shown and not b.qRing.shown, kind .. ": Classic cell has one quality frame")
				check(b.qFrame.allPoints == b.icon, kind .. ": native frame fits icon without legacy expansion")
				if kind == "atlas" then check(b.qFrame.atlas == "client-bag-border", "uses native atlas for live and cached cells")
				else
					check(b.qFrame.file == 123456, "uses native file for live and cached cells")
					check(b.qFrame.coords[1] == .1 and b.qFrame.coords[8] == .8, "preserves file texture coordinates")
				end
				local colored = setting == "all" or (setting == "unc" and q == 2)
				check(b.qFrame.color[1] == (colored and (q == 2 and 0 or 1) or B.NEUTRAL_FRAME[1]), "rarity/neutral settings retained")
			end
		end
		B:ApplyQuality(b, nil)
		check(not b.qFrame.shown, "empty cell hides item border")
		ns.db.skin = "modern"; B:ApplyQuality(b, { quality = 2 })
		check(not b.qFrame.shown and b.modernBorder[1].shown, "Modern still uses its pixel outline")
		ns.db.skin = "classic"; B:ApplyQuality(b, { quality = 2 })
		check(b.qFrame.shown and not b.modernBorder[1].shown, "switching back restores Classic border")
		b.mode = "row"; B:ApplyQuality(b, { quality = 2 })
		check(b.qRing.shown and not b.qFrame.shown, "Classic list rows retain their ring")
	end
	check(source.atlas == (kind == "atlas" and "client-bag-border" or nil), "native template atlas is not rewritten")
end

-- A cached cell may exist before a readable client template. Do not cache
-- absence permanently: it should adopt native art on its next refresh.
B.borderArt = nil; B.all = {}; ns.db.skin = "classic"
local early = button()
B:ApplyQuality(early, { quality = 1 })
check(early.qFrame.file == "Interface\\Common\\WhiteIconFrame", "unavailable native art keeps legacy fallback")
check(early.qFrame.points[1][4] == -2, "fallback keeps legacy frame geometry")
local source = texture(); source:SetAtlas("late-client-border")
B.all[1] = button(source)
B:ApplyQuality(early, { quality = 1 })
check(early.qFrame.atlas == "late-client-border" and early.qFrame.allPoints == early.icon, "late native art replaces fallback")

-- Exercise capture through the actual secure pool, then alter the native
-- region as an item-quality update might. Cached cells keep the template art.
package.loaded.mock = nil
local M = require("mock")
local create = CreateFrame
CreateFrame = function(kind, name, parent, template)
	local f = create(kind, name, parent, template)
	if template and template:find("ContainerFrameItemButtonTemplate", 1, true) then
		f.IconBorder = f.IconBorder or f:CreateTexture(nil, "OVERLAY")
		f.IconBorder:SetAtlas("pool-template-border")
		f.IconBorder.GetAtlas = function(t) return t.atlas end
	end
	return f
end
BagSmithCharDB = { version = 1, firstSeen = {} }
BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { skin = "classic" } } }
local addon = M.loadAddon("BagSmith")
M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
local pool = addon.Buttons
local live = pool:Get(0, 1)
check(pool.borderArt and pool.borderArt.atlas == "pool-template-border", "pool decoration captures client art")
live.IconBorder:SetAtlas("item-update-border")
local cached = pool:GetCached(addon.Window.main.child, 1)
for _, b in ipairs({ live, cached }) do
	pool:SetMode(b, "cell"); pool:ApplyQuality(b, { quality = 2 })
	check(b.qFrame.atlas == "pool-template-border", "live/cached pool uses captured art after native update")
	check(not b.IconBorder or not b.IconBorder:IsShown(), "native region stays hidden to avoid duplicate borders")
end
check(live.IconBorder:GetAlpha() == 0, "secure template cannot restore a second visible frame")
CreateFrame = create
