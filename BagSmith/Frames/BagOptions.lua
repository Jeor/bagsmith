-- 2.0: presentation for the existing view actions. No inventory logic lives here.
local _, ns = ...
local O = {}
ns.BagOptions = O
local WIDTH, PAD = 280, 14
local function label(parent, text)
	local f = parent:CreateFontString(nil, 'OVERLAY', ns.Fonts:Name('GameFontHighlightSmall'))
	f:SetText(text); f:SetJustifyH('LEFT'); f:SetWordWrap(false)
	return f
end
local function button(parent, text, click)
	local b = CreateFrame('Button', nil, parent, 'BackdropTemplate')
	b:SetSize(WIDTH-2*PAD, 24)
	b.label = label(b, text); b.label:SetPoint('CENTER')
	b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8', edgeFile='Interface\\Buttons\\WHITE8X8', edgeSize=1})
	function b:SetActive(on)
		self.active=on
		local s=ns.Skins:Current()
		self:SetBackdropColor(1,1,1,on and 0.10 or 0.025)
		if on then self:SetBackdropBorderColor(ns.Skins:Accent()) else self:SetBackdropBorderColor(unpack(s.line)) end
		self.label:SetTextColor(unpack(on and s.heading or s.muted))
	end
	b:SetScript('OnClick',click); b:SetActive(false)
	return b
end
local function place(widget, parent, y, width)
	widget:SetParent(parent); widget:ClearAllPoints()
	widget:SetPoint('TOPLEFT',parent,'TOPLEFT',PAD,-y)
	widget:SetSize(width or WIDTH-2*PAD,24)
	widget:SetFrameLevel(parent:GetFrameLevel()+2)
end
-- Choice controls share geometry; actions keep their original callbacks/tooltips.
local function checkbox(b)
	if b.optionsCheck then return end
	local box=CreateFrame('Frame',nil,b,'BackdropTemplate')
	box:SetSize(13,13); box:SetPoint('LEFT',2,0)
	box:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
	box.mark=box:CreateTexture(nil,'ARTWORK'); box.mark:SetPoint('TOPLEFT',3,-3); box.mark:SetPoint('BOTTOMRIGHT',-3,3)
	b.optionsCheck=box
	local original=b.SetActive
	b.SetActive=function(self,on)
		original(self,on)
		self:SetBackdropColor(0,0,0,0); self:SetBackdropBorderColor(0,0,0,0)
		box:SetBackdropColor(0,0,0,0.15); box:SetBackdropBorderColor(unpack(ns.Skins:Current().line))
		box.mark:SetColorTexture(ns.Skins:Accent()); box.mark:SetShown(on)
		self.label:SetTextColor(unpack(ns.Skins:Current().text))
	end
	b.label:ClearAllPoints(); b.label:SetPoint('LEFT',22,0); b.label:SetJustifyH('LEFT')
	b.label:SetWidth(WIDTH-2*PAD-24)
	b:SetActive(b.active)
end
function O.Scroll(v,value)
	if v.optionsScrolling then return end
	v.optionsScrolling=true
	local sc=v.optionsScroll
	local max=math.max(0,v.optionsContent:GetHeight()-sc:GetHeight())
	value=math.max(0,math.min(max,value or sc:GetVerticalScroll() or 0))
	sc:SetVerticalScroll(value)
	v.optionsScrollbar:SetMinMaxValues(0,max); v.optionsScrollbar:SetValue(value); v.optionsScrollbar:SetShown(max>0)
	v.optionsShadeTop:SetShown(value>0); v.optionsShadeBottom:SetShown(value<max)
	v.optionsScrolling=nil
end
function O.Build(v)
	if not v.big or not v.visualRefresh or v.optionsDrawer then return end
	local d=CreateFrame('Frame',v.name..'Options',v.frame,'BackdropTemplate')
	v.optionsDrawer=d; d:SetWidth(WIDTH); d:EnableMouse(true); d:SetClampedToScreen(true)
	d:SetFrameLevel(v.frame:GetFrameLevel()+10)
	ns.Skins:ApplyBackdrop(d)
	d.heading=label(d,'BagSmith Options'); d.heading:SetPoint('TOPLEFT',PAD,-16)
	local close=button(d,'<',function() O.Toggle(v,false) end)
	close:SetSize(24,24); close:SetPoint('TOPRIGHT',-8,-8)
	local sc=CreateFrame('ScrollFrame',nil,d)
	sc:SetPoint('TOPLEFT',0,-48); sc:SetPoint('BOTTOMRIGHT',-2,50)
	local content=CreateFrame('Frame',nil,sc); content:SetSize(WIDTH-2,740)
	sc:SetScrollChild(content); sc:EnableMouseWheel(true)
	v.optionsContent,v.optionsScroll=content,sc
	local bar=CreateFrame('Slider',nil,d,'BackdropTemplate')
	bar:SetPoint('TOPRIGHT',d,'TOPRIGHT',-7,-52); bar:SetPoint('BOTTOMRIGHT',d,'BOTTOMRIGHT',-7,54); bar:SetWidth(5)
	if bar.SetOrientation then bar:SetOrientation('VERTICAL') end
	if bar.SetValueStep then bar:SetValueStep(1) end
	bar:EnableMouse(true)
	if bar.SetHitRectInsets then bar:SetHitRectInsets(-4,-4,0,0) end
	bar:SetMinMaxValues(0,1)
	if bar.SetThumbTexture then
		bar:SetThumbTexture('Interface\\Buttons\\WHITE8X8')
		local thumb=bar:GetThumbTexture(); thumb:SetSize(5,26); thumb:SetVertexColor(0.55,0.51,0.43,0.7)
	end
	bar:SetScript('OnValueChanged',function(_,value) O.Scroll(v,value) end)
	v.optionsScrollbar=bar
	for _,side in ipairs({'Top','Bottom'}) do
		local shade=d:CreateTexture(nil,'OVERLAY')
		shade:SetPoint(side=='Top' and 'TOPLEFT' or 'BOTTOMLEFT',sc,side=='Top' and 'TOPLEFT' or 'BOTTOMLEFT',10,0)
		shade:SetPoint(side=='Top' and 'TOPRIGHT' or 'BOTTOMRIGHT',sc,side=='Top' and 'TOPRIGHT' or 'BOTTOMRIGHT',-10,0)
		shade:SetHeight(5); shade:SetColorTexture(0,0,0,0.18)
		v['optionsShade'..side]=shade
	end
	sc:SetScript('OnMouseWheel',function(_,delta) O.Scroll(v,(sc:GetVerticalScroll() or 0)-delta*30) end)
	sc:SetScript('OnSizeChanged',function() if not v.optionsLayingOut then O.Scroll(v) end end)
	v.optionsSettings=v.btnSettings or button(d,'All Settings',function() ns.SettingsPanel:Toggle() end)
	v.optionsSettings:SetParent(d)
	v.optionsSettings:ClearAllPoints(); v.optionsSettings:SetPoint('BOTTOMLEFT',d,'BOTTOMLEFT',PAD,12); v.optionsSettings:SetSize(WIDTH-2*PAD,24)
	v.optionsSettings:SetFrameLevel(d:GetFrameLevel()+2)
	if v.optionsSettings.tex then
		v.optionsSettings.tex:ClearAllPoints(); v.optionsSettings.tex:SetPoint('LEFT',4,0); v.optionsSettings.tex:SetSize(15,15)
		v.optionsSettings.optionsLabel=label(v.optionsSettings,'All Settings'); v.optionsSettings.optionsLabel:SetPoint('LEFT',28,0)
	end
	d.footerLine=d:CreateTexture(nil,'ARTWORK'); d.footerLine:SetPoint('BOTTOMLEFT',PAD,44); d.footerLine:SetPoint('BOTTOMRIGHT',-PAD,44); d.footerLine:SetHeight(1)
	checkbox(v.btnMerge)
	v.btnSort:SetScript('OnClick',function(b)
		local items={}
		for _,it in ipairs({{'quality','Quality'},{'name','Name'},{'ilvl','Item Level'},{'newest','Newest'},{'oldest','Oldest'},{'off','Off'}}) do
			local value=it[1]
			items[#items+1]={text=it[2],checked=v:Pref('sort')==value,onClick=function()
				v.st.colSort=nil; v:SetPref('sort',value); v:SyncTools(); ns:RefreshViews(true)
			end}
		end
		ns.ShowMenu(items,b)
	end)
	v.btnSort.chev=v.btnSort:CreateTexture(nil,'OVERLAY'); v.btnSort.chev:SetSize(10,10); v.btnSort.chev:SetPoint('RIGHT',-7,0)
	v.btnSort.chev:SetTexture('Interface\\AddOns\\BagSmith\\Media\\ui-chev-down.tga')
	v.btnSort.label:ClearAllPoints(); v.btnSort.label:SetPoint('LEFT',8,0); v.btnSort.label:SetJustifyH('LEFT')
	v.optionsLabels={}
	for _,b in ipairs(v.grpSegBtns or {}) do
		local paint=b.SetActive
		b.SetActive=function(self,on) paint(self,on); self:SetFrameLevel(self:GetParent():GetFrameLevel()+2); if not on then self:SetBackdropBorderColor(unpack(ns.Skins:Current().line)); self:SetBackdropColor(1,1,1,0.025) end end
	end
	for _,text in ipairs({'View','Display','Layout','Grouping','Sorting','Category Details','Tools'}) do
		v.optionsLabels[text]=label(content,text)
	end
	v.optionsLayout={}
	for _,it in ipairs({{'Standard',false,false},{'Compact',true,false},{'Split',false,true}}) do
		local b=button(content,it[1],function()
			if v.isMain and ns.ui.global then return end
			v:SetPref('view','icons')
			if it[1]~='Standard' and v:Pref('grp')=='none' then v:SetPref('grp','type') end
			ns:Set('compactCategories',it[2],true); ns:Set('splitView',it[3],true)
			v:FreshLayout(); ns:RefreshViews(true); O.Layout(v)
		end)
		b:SetScript('OnEnter',function(self)
			if not ns.TooltipsOK() then return end
			GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); ns.TipText(GameTooltip,it[1])
			ns.TipLine(GameTooltip,it[1]=='Compact' and 'Pack categories to fit their items.' or it[1]=='Split' and 'Arrange categories in two columns.' or 'Show each category across the full width.',nil,nil,nil,true); GameTooltip:Show()
		end)
		b:SetScript('OnLeave',function() GameTooltip:Hide() end)
		b.mode=it[1]; v.optionsLayout[#v.optionsLayout+1]=b
	end
	v.optionsExpanded={sorting=true,details=true,tools=true}
	v.optionsSections={}
	for _,it in ipairs({{'sorting','Sorting & stacking'},{'details','Category details'},{'tools','Tools'}}) do
		local key,title=it[1],it[2]
		local b=button(content,title,function() v.optionsExpanded[key]=not v.optionsExpanded[key]; O.Layout(v) end)
		b.sectionTitle=title
		b.label:ClearAllPoints(); b.label:SetPoint('LEFT',0,0)
		b.arrow=label(b,'>'); b.arrow:SetPoint('RIGHT',-2,0)
		v.optionsSections[key]=b
	end
	v.optionsDetails={}
	for _,it in ipairs({{'Item Count','categoryCount'},{'Vendor Value','categoryVendor'},{'Auction Value','categoryAuction'}}) do
		local b=button(content,it[1],function()
			ns:Set(it[2],not ns.db[it[2]]); ns:RefreshViews(true); O.Layout(v)
		end)
		checkbox(b); b.key=it[2]; v.optionsDetails[#v.optionsDetails+1]=b
	end
	v.optionsToggle=button(v.title,'',function() O.Toggle(v) end)
	v.optionsToggle:SetSize(24,24)
	v.optionsToggle.icon=v.optionsToggle:CreateTexture(nil,'ARTWORK')
	v.optionsToggle.icon:SetSize(16,16); v.optionsToggle.icon:SetPoint('CENTER')
	v.optionsToggle.icon:SetTexture('Interface\\AddOns\\BagSmith\\Media\\mark.tga')
	v.optionsToggle:SetScript('OnEnter',function(b)
		if ns.TooltipsOK() then GameTooltip:SetOwner(b,'ANCHOR_RIGHT'); ns.TipText(GameTooltip,'BagSmith Options'); if b.tipStatus and b.tipStatus~='' then ns.TipLine(GameTooltip,b.tipStatus,0.8,0.8,0.8,true) end; GameTooltip:Show() end
	end)
	v.optionsToggle:SetScript('OnLeave',function() GameTooltip:Hide() end)
	v.frame:HookScript('OnHide',function() O.Toggle(v,false) end)
	v.frame:HookScript('OnSizeChanged',function() O.Position(v) end)
	d:Hide()
	-- Backdrop geometry can synchronously fire the old toolbar's size callback
	-- during construction. Publish readiness only after every control exists.
	v.optionsReady=true
	O.Layout(v)
	v:PlaceHeader(); v:PlaceScroll()
end
function O.Position(v)
	local d=v.optionsDrawer
	if not d then return end
	d:ClearAllPoints()
	local left=v.frame:GetLeft()
	if left and left<WIDTH+4 then d:SetPoint('TOPLEFT',v.frame,'TOPRIGHT',2,0)
	else d:SetPoint('TOPRIGHT',v.frame,'TOPLEFT',-2,0) end
	d:SetHeight(math.max(180,v.frame:GetHeight()))
	if v.optionsScrollbar then O.Scroll(v) end
end
function O.Toggle(v,on)
	local d=v.optionsDrawer
	if not d then return end
	if on==nil then on=not d:IsShown() end
	if on and ns.Drawer then ns.Drawer:Hide() end
	O.Position(v); d:SetShown(on); v.optionsToggle:SetActive(on)
end
function O.Title(v)
	if not v.optionsDrawer then return end
	v.mark:Hide(); if v.titleDivider then v.titleDivider:Hide() end
	v.optionsToggle:ClearAllPoints(); v.optionsToggle:SetPoint('LEFT',v.title,'LEFT',0,0)
	v.titleText:ClearAllPoints(); v.titleText:SetPoint('LEFT',v.optionsToggle,'RIGHT',8,0)
	v.titleText:SetText(v:TitleForms()[1]); v.titleText:Show()
	if v.charBtn then
		v.charBtn:ClearAllPoints(); v.charBtn:SetPoint('LEFT',v.titleText,'RIGHT',14,0)
		v.charBtn:SetWidth(math.max(90,math.min(170,(v.title:GetWidth() or 400)-180)))
		v:FitPickerName()
	end
	-- Status text remains available under the character picker in existing tooltips.
	v.subText:Hide()
	v.optionsToggle.tipStatus=v.subText:GetText()
	if v.btnLanesTravel then v.btnLanesTravel:Hide() end
end
function O.Search(v)
	if not v.optionsDrawer then return end
	v.search:ClearAllPoints()
	v.search:SetPoint('TOPLEFT',v.title,'BOTTOMLEFT',4+(v.belowShift or 0),-4)
	v.search:SetPoint('TOPRIGHT',v.title,'BOTTOMRIGHT',0,-4)
	v.search:SetHeight(26); v.search:Show()
	v.btnFilter:ClearAllPoints(); v.btnFilter:SetPoint('RIGHT',v.search,'RIGHT',-3,0)
	v.btnFilter:SetSize(24,22); v.btnFilter:SetFrameLevel(v.search:GetFrameLevel()+2)
	v.btnFilter.label:Hide()
	if not v.btnFilter.optionsIcon then
		local icon=v.btnFilter:CreateTexture(nil,'ARTWORK'); icon:SetSize(12,12); icon:SetPoint('CENTER')
		icon:SetTexture('Interface\\AddOns\\BagSmith\\Media\\ui-set-filter.tga'); v.btnFilter.optionsIcon=icon
	end
	v.btnFilter.optionsIcon:SetVertexColor(unpack(ns.Skins:Current().muted))
	v.btnFilter:SetBackdropColor(0,0,0,0); v.btnFilter:SetBackdropBorderColor(0,0,0,0)
	v.btnFilter.tip='Filter'; v.btnFilter:Show()
	v.search:SetTextInsets(18,48,0,0)
	if v.search.clearButton then v.search.clearButton:ClearAllPoints(); v.search.clearButton:SetPoint('RIGHT',v.search,'RIGHT',-28,0) end
	if v.btnSearchFold then v.btnSearchFold:Hide() end
	v.tools:Hide()
	if v.title.band then v.title.band:Hide() end
end
function O.Layout(v)
	if not v.optionsReady or v.optionsLayingOut then return end
	v.optionsLayingOut=true
	local c,y=v.optionsContent,4
	local s=ns.Skins:Current()
	ns.Skins:ApplyBackdrop(v.optionsDrawer)
	local opacity=ns.db.bgWhole and 1 or (tonumber(ns.db.bgOpacity) or 1)
	v.optionsDrawer:SetBackdropColor(s.bg[1],s.bg[2],s.bg[3],(s.bg[4] or 1)*opacity)
	v.optionsDrawer:SetBackdropBorderColor(unpack(s.border))
	local function heading(text)
		local f=v.optionsLabels[text]; f:ClearAllPoints(); f:SetPoint('TOPLEFT',c,'TOPLEFT',PAD,-y)
		f:SetTextColor(unpack(s.muted)); y=y+20
	end
	local function row(b,text)
		if not b then return end
		place(b,c,y); b:SetHeight(22); b:Show()
		if b.tex then
			b.tex:ClearAllPoints(); b.tex:SetPoint('LEFT',b,'LEFT',4,0); b.tex:SetSize(16,16)
			if not b.optionsLabel then b.optionsLabel=label(b,text or b.tip or '') end
			b.optionsLabel:ClearAllPoints(); b.optionsLabel:SetPoint('LEFT',b,'LEFT',28,0)
			b.optionsLabel:SetText(text or b.tip or ''); b.optionsLabel:SetWidth(WIDTH-2*PAD-28); b.optionsLabel:SetTextColor(unpack(s.text))
			if not b.optionsHover then ns.HoverWash(b,0); b.optionsHover=true end
		end
		y=y+25
	end
	local function segments(btns)
		for _,b in ipairs(btns) do
			if not b.optionsLevel and b.SetActive then
				local paint=b.SetActive
				b.SetActive=function(self,on) paint(self,on); self:SetFrameLevel(self:GetParent():GetFrameLevel()+2); if not on then self:SetBackdropBorderColor(unpack(ns.Skins:Current().line)); self:SetBackdropColor(1,1,1,0.025) end end
				b.optionsLevel=true
			end
		end
		local width=(WIDTH-2*PAD)/#btns
		for j,b in ipairs(btns) do
			place(b,c,y,width); b:ClearAllPoints(); b:SetPoint('TOPLEFT',c,'TOPLEFT',PAD+(j-1)*width,-y); b:Show()
			if b.divider then b.divider:Hide() end
		end
		y=y+32
	end
	-- Always attach controls to the scroll child before hiding them. Otherwise
	-- old toolbar ownership can leave icons floating outside a collapsed section.
	for _,f in pairs(v.optionsLabels) do f:Hide() end
	for _,b in ipairs(v.optionsLayout) do b:Hide() end
	for _,b in ipairs(v.grpSegBtns or {}) do b:Hide() end
	local function choices(text,buttons)
		local f=v.optionsLabels[text]; f:ClearAllPoints(); f:SetPoint('TOPLEFT',c,'TOPLEFT',PAD,-y-6)
		f:SetTextColor(unpack(s.muted)); f:Show()
		y=y+19
		local width=(WIDTH-2*PAD)/#buttons
		for j,b in ipairs(buttons) do
			place(b,c,y,width); b:ClearAllPoints(); b:SetPoint('TOPLEFT',c,'TOPLEFT',PAD+(j-1)*width,-y); b:Show()
			if b.divider then b.divider:Hide() end
			if not b.optionsChoice then
				b.optionsUnderline=b:CreateTexture(nil,'ARTWORK'); b.optionsUnderline:SetHeight(1)
				b.optionsUnderline:SetPoint('BOTTOMLEFT',3,0); b.optionsUnderline:SetPoint('BOTTOMRIGHT',-3,0)
				local paint=b.SetActive
				b.SetActive=function(self,on)
					paint(self,on); self:SetFrameLevel(self:GetParent():GetFrameLevel()+2)
					self:SetBackdropBorderColor(0,0,0,0); self:SetBackdropColor(1,1,1,on and 0.06 or (self.hover and 0.03 or 0))
					self.optionsUnderline:SetColorTexture(ns.Skins:Accent()); self.optionsUnderline:SetShown(on)
				end
				b.optionsChoice=true
			end
			b:SetActive(b.active)
		end
		y=y+28
	end
	for _,b in ipairs(v.viewSegBtns) do b:Hide() end
	local mode=ns.db.compactCategories and 'Compact' or ns.db.splitView and 'Split' or 'Standard'
	local list=v:Pref('view')=='list'
	local display={}
	for _,b in ipairs(v.viewSegBtns) do if b.value=='list' then b:SetActive(list); display[#display+1]=b end end
	for _,b in ipairs(v.optionsLayout) do
		b:SetActive(not list and b.mode==mode)
		if v.isMain and ns.ui.global then b:Disable() else b:Enable() end
		display[#display+1]=b
	end
	choices('Display',display)
	v.optionsLabels.Grouping:SetText('Group by')
	for _,b in ipairs(v.grpSegBtns) do b.label:SetText(b.value=='type' and 'Category' or b.value=='bag' and 'Bag' or 'All') end
	choices('Grouping',v.grpSegBtns)
	v.btnGrpMenu:Hide()
	row(v.btnLanes,v.btnLanes.tip); y=y+8
	local function section(key)
		local b=v.optionsSections[key]; row(b)
		b:SetBackdropColor(0,0,0,0); b:SetBackdropBorderColor(0,0,0,0)
		b.label:SetTextColor(unpack(s.text)); b.arrow:SetText(v.optionsExpanded[key] and 'v' or '>'); b.arrow:SetTextColor(unpack(s.muted))
		y=y+7
		return v.optionsExpanded[key]
	end
	local function optional(b,show,text)
		if not b then return end
		if show then row(b,text) else place(b,c,y); b:Hide() end
	end
	local show=section('sorting')
	optional(v.btnSort,show); v.btnSort.label:SetText(((v.btnSort.label:GetText() or ''):gsub('^Sort: ','')))
	optional(v.btnMerge,show)
	show=section('details')
	for _,b in ipairs(v.optionsDetails) do optional(b,show); b:SetActive(ns.db[b.key]) end
	show=section('tools')
	for _,key in ipairs({'btnClean','btnDisenchant','btnGearSets','btnBank','btnCurrency','btnGlobal','btnTravel'}) do
		local available=key~='btnDisenchant' or ns.db.deEnabled
		if key=='btnGearSets' then available=ns.GearSets and ns.GearSets:Available() end
		optional(v[key],show and available)
		if v[key] and key=='btnDisenchant' then v[key]:SetActive(available and ns.Disenchant and ns.Disenchant.frame and ns.Disenchant.frame:IsShown() or false) end
	end
	c:SetHeight(y+8)
	v.optionsDrawer.footerLine:SetColorTexture(unpack(s.line))
	v.optionsSettings:Show(); O.Scroll(v)
	O.Position(v); O.Title(v); O.Search(v)
	v.optionsLayingOut=nil
end
function O.Tabs(v)
	for _,b in ipairs(v.tabButtons or {}) do
		if not b.optionsPaint then
			local paint=b.SetActive
			b.SetActive=function(self,on)
				paint(self,on); self:SetBackdropColor(0,0,0,0); self:SetBackdropBorderColor(0,0,0,0)
				if self.optionsUnderline then self.optionsUnderline:SetShown(on) end
			end
			b.optionsPaint=true
		end
		if b.classic then b.classic:Hide() end
		b:SetBackdropColor(0,0,0,0); b:SetBackdropBorderColor(0,0,0,0)
		if not b.optionsUnderline then
			b.optionsUnderline=b:CreateTexture(nil,'ARTWORK')
			b.optionsUnderline:SetPoint('BOTTOMLEFT',6,0); b.optionsUnderline:SetPoint('BOTTOMRIGHT',-6,0)
			b.optionsUnderline:SetHeight(1)
		end
		b.optionsUnderline:SetColorTexture(ns.Skins:Accent()); b.optionsUnderline:SetShown(b.active)
		b.label:Show(); b.label:SetTextColor(unpack(b.active and ns.Skins:Current().heading or ns.Skins:Current().muted))
	end
end
function O.Footer(v)
	for _,key in ipairs({'btnBags','btnReagent','btnBagBar'}) do
		local b=v[key]
		if b then
			if not b.optionsPaint then
				local paint=b.SetActive
				b.SetActive=function(self,on) paint(self,on); self:SetBackdropColor(0,0,0,0); self:SetBackdropBorderColor(0,0,0,0) end
				b.optionsPaint=true
			end
			b:SetActive(b.active)
		end
	end
end

