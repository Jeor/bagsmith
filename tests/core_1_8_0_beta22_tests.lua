;(function()
	-- ======== 1.8.0-beta22 (Shweep: "only see these in BagSmith", and his /run on Forever) ========
	-- Fonts: each file is checked on a text of its own (a text switched from another font could still report the old
	-- one, so every font the game hadn't drawn yet looked missing all session, and choosing one did nothing). FlareUI's
	-- six fonts come with BagSmith too, shared under FlareUI's names once every addon has loaded, only where nobody
	-- shares the name yet. The Font list: twenty at a time, round marks. Classic menus: solid behind.
	local LOADED = { ["fonts\\frizqt__.ttf"] = true }   -- files the game has drawn already
	local MISSING = { ["interface\\addons\\other\\gone.ttf"] = true }
	local function key(p) return (tostring(p or "")):lower():gsub("/", "\\") end
	local function forever(fs)
		-- As the client behaves: a text that has a font, set to a file not drawn yet, still reports the old file; a fresh
		-- text reports the new one; a file that isn't there is refused and leaves no font.
		function fs:SetFont(p, size, flags)
			if MISSING[key(p)] then return false end
			if self.font and not LOADED[key(p)] then self.size = size; return true end
			self.font, self.size = p, size
			return true
		end
		function fs:GetFont() return self.font, self.size, "" end
		return fs
	end
	package.loaded.mock = nil
	local M = require("mock")
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = {} } }
	local n = M.loadAddon("BagSmith")
	local make = UIParent.CreateFontString
	UIParent.CreateFontString = function(self, ...) return forever(make(self, ...)) end
	local LSM = LibStub("LibSharedMedia-3.0")
	-- FlareUI (loading after BagSmith) shares two of the six itself
	local FLARE = "Interface/AddOns/FlareUI/Media/Fonts/"
	LSM:Register("font", "Asap Condensed", FLARE .. "AsapCondensed-Regular.ttf", LSM.LOCALE_BIT_western)
	LSM:Register("font", "Marcellus", FLARE .. "Marcellus-Regular.ttf", LSM.LOCALE_BIT_western)
	LSM:Register("font", "Gone Font", "Interface\\AddOns\\Other\\gone.ttf")
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_LOGIN"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	local F = n.Fonts
	local OWN = "Interface\\AddOns\\BagSmith\\Media\\Fonts\\"

	-- the six: shared, FlareUI's own copies kept where it shares them
	check(LSM:Fetch("font", "Barlow Condensed", true) == OWN .. "BarlowCondensed-Regular.ttf" and LSM:Fetch("font", "Fira Condensed", true) == OWN .. "FiraSansExtraCondensed-Regular.ttf"
		and LSM:Fetch("font", "Cabin Condensed", true) and LSM:Fetch("font", "Roboto Condensed Bold", true) == OWN .. "RobotoCondensed-Bold.ttf", "BagSmith shares the names nobody shares yet")
	check(LSM:Fetch("font", "Asap Condensed", true) == FLARE .. "AsapCondensed-Regular.ttf" and LSM:Fetch("font", "Marcellus", true) == FLARE .. "Marcellus-Regular.ttf", "FlareUI's own copies stay the ones used")

	-- the list: every font the game can load, none of them drawn yet; a missing file isn't offered
	local names = {}
	for _, c in ipairs(F:Choices()) do names[c.label] = true end
	local want = { "Noto Sans", "Roboto Condensed", "Inter", "Asap Condensed", "Barlow Condensed", "Cabin Condensed", "Fira Condensed", "Marcellus", "Roboto Condensed Bold" }
	local missing = {}
	for _, w in ipairs(want) do if not names[w] then missing[#missing + 1] = w end end
	check(#missing == 0, "all nine offered, though the game hadn't drawn them yet (missing: " .. table.concat(missing, ", ") .. ")")
	check(not names["Gone Font"], "a file that isn't there isn't offered")
	-- choosing one works
	n:Set("fontName", "Inter"); M.runTimers()
	check(F:Path() == OWN .. "Inter-Regular.ttf", "choosing Inter: it's the one used (" .. tostring(F:Path()) .. ")")
	-- a no isn't remembered: the file arrives later, it's offered then
	MISSING["interface\\addons\\other\\gone.ttf"] = nil
	names = {}
	for _, c in ipairs(F:Choices()) do names[c.label] = true end
	check(names["Gone Font"], "a file that wasn't there is asked again, and offered once it is")
	n:Set("fontName", ""); M.runTimers()

	-- every file the package ships, with its licence
	local function exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end
	local base = "BagSmith/Media/Fonts/"
	local files = { "AsapCondensed-Regular.ttf", "BarlowCondensed-Regular.ttf", "CabinCondensed-Regular.ttf", "FiraSansExtraCondensed-Regular.ttf",
		"Marcellus-Regular.ttf", "RobotoCondensed-Bold.ttf", "OFL-AsapCondensed.txt", "OFL-BarlowCondensed.txt", "OFL-CabinCondensed.txt",
		"OFL-FiraSansExtraCondensed.txt", "OFL-Marcellus.txt", "LICENSE-Apache-2.0-RobotoCondensed-Bold.txt" }
	local absent = {}
	for _, f in ipairs(files) do if not exists(base .. f) then absent[#absent + 1] = f end end
	check(#absent == 0, "the six fonts and their licences are in Media/Fonts (" .. table.concat(absent, ", ") .. ")")
	for _, f in ipairs(F.MORE) do check(exists((f[2]:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/"))), "the file for " .. f[1] .. " is there") end

	-- the Font list: round marks (the chosen one filled), twenty at a time
	n.SettingsPanel:Show(); n.SettingsPanel:ShowPage("look")
	local drop
	for _, w in ipairs(n.SettingsPanel.pools.dropdown) do if w:IsShown() and w.key == "fontName" then drop = w end end
	drop.btn:GetScript("OnClick")(drop.btn); M.runTimers()
	local menu = n.menuFrame
	check(menu.items.listRows == 20, "the Font list shows twenty at a time")
	local radios, filled = 0, nil
	for _, r in ipairs(menu.rows) do
		if r:IsShown() and r.radio then
			radios = radios + 1
			if r.check.texCoord and r.check.texCoord[1] == 0.25 then filled = r.text.text end
		end
	end
	check(radios >= 10 and filled == "Default Font", "round marks, Default Font's filled (" .. radios .. ", " .. tostring(filled) .. ")")
	menu:Hide()
	-- another menu keeps its ticks
	n.ShowMenu({ { text = "Toggle", checked = true, onClick = function() end }, { text = "Other", onClick = function() end } })
	local tick, other = menu.rows[1], menu.rows[2]
	check(not tick.radio and tick.check:IsShown() and not other.check:IsShown(), "a toggle menu still ticks")
	menu:Hide()
	check((n.errors or 0) == 0, "no errors")
	UIParent.CreateFontString = make
end)()

;(function()
	-- A saved choice of one of the six takes effect once it's shared; Classic menus are solid behind
	package.loaded.mock = nil
	local M = require("mock")
	-- textures report the art they were given, as the game does once it's loaded (the dark dialog art among them)
	local baseTex = M.tex
	M.tex = function() local t = baseTex(); t.GetTexture = function(self) return self.texture end; return t end
	_G.BagSmithCharDB = { version = 1, firstSeen = {} }
	_G.BagSmithDB = { version = 2, chars = {}, cache = {}, profiles = { Default = { fontName = "Fira Condensed", skin = "classic" } } }
	local n = M.loadAddon("BagSmith")
	local applied = 0
	local realApply = n.Fonts.Apply
	n.Fonts.Apply = function(self, ...) applied = applied + 1; return realApply(self, ...) end
	M.fire("ADDON_LOADED", "BagSmith"); M.fire("PLAYER_LOGIN"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
	check(applied >= 1 and n.Fonts:Path() == "Interface\\AddOns\\BagSmith\\Media\\Fonts\\FiraSansExtraCondensed-Regular.ttf", "a saved Fira Condensed is used once shared")
	n.ShowMenu({ { text = "One", onClick = function() end } })
	local st = n.menuFrame.classicState
	local under = st and st.solidUnder
	check(st and st.solid and st.solid.texture == n.Classic.DIALOG_ART, "(setup) Classic: the menu wears the game's dark dialog art")
	check(under and under.color and under.color[4] == 1 and under.colorTexture and under.sublayer < st.solid.sublayer, "Classic: plain black under the menu's dark art, so nothing behind shows through")
	n.menuFrame:Hide()
	check((n.errors or 0) == 0, "no errors")
end)()
