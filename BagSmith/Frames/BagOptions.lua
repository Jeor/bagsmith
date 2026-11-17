-- 2.0: presentation for the existing view actions. No inventory logic lives here.
local _, ns = ...
local O = {}
ns.BagOptions = O
local WIDTH, PAD = 224, 14
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
function O.Build(v)
	if not v.big or not v.visualRefresh or v.optionsDrawer then return end
	local d=CreateFrame('Frame',v.name..'Options',v.frame,'BackdropTemplate')
	v.optionsDrawer=d; d:SetWidth(WIDTH); d:EnableMouse(true); d:SetClampedToScreen(true)
	d:SetFrameLevel(v.frame:GetFrameLevel()+10)
	d:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
	d.heading=label(d,'Bag Options'); d.heading:SetPoint('TOPLEFT',PAD,-16)
	local close=button(d,'<',function() O.Toggle(v,false) end)
	close:SetSize(24,24); close:SetPoint('TOPRIGHT',-8,-8)
	local sc=CreateFrame('ScrollFrame',nil,d)
	sc:SetPoint('TOPLEFT',0,-44); sc:SetPoint('BOTTOMRIGHT',-2,24)
	local content=CreateFrame('Frame',nil,sc); content:SetSize(WIDTH-2,740)
	sc:SetScrollChild(content); sc:EnableMouseWheel(true)
	sc:SetScript('OnMouseWheel',function(_,delta)
		local max=math.max(0,content:GetHeight()-sc:GetHeight())
		sc:SetVerticalScroll(math.max(0,math.min(max,(sc:GetVerticalScroll() or 0)-delta*36)))
	end)
	v.optionsContent,v.optionsScroll=content,sc
	d.scrollHint=label(d,'Scroll for more options')
	d.scrollHint:SetPoint('BOTTOM',d,'BOTTOM',0,4)
	v.optionsLabels={}
	for _,b in ipairs(v.grpSegBtns or {}) do
		local paint=b.SetActive
		b.SetActive=function(self,on) paint(self,on); self:SetFrameLevel(self:GetParent():GetFrameLevel()+2) end
	end
	for _,text in ipairs({'View','Layout','Grouping','Sorting','Category Details','Tools'}) do
		v.optionsLabels[text]=label(content,text)
	end
	v.optionsLayout={}
	for _,it in ipairs({{'Standard',false,false},{'Compact',true,false},{'Split',false,true}}) do
		local b=button(content,it[1],function()
			ns:Set('compactCategories',it[2],true); ns:Set('splitView',it[3],true)
			v:FreshLayout(); ns:RefreshViews(true); O.Layout(v)
		end)
		b.mode=it[1]; v.optionsLayout[#v.optionsLayout+1]=b
	end
	v.optionsDetails={}
	for _,it in ipairs({{'Item Count','categoryCount'},{'Vendor Value','categoryVendor'},{'Auction Value','categoryAuction'}}) do
		local b=button(content,it[1],function()
			ns:Set(it[2],not ns.db[it[2]]); ns:RefreshViews(true); O.Layout(v)
		end)
		b.key=it[2]; v.optionsDetails[#v.optionsDetails+1]=b
	end
	v.optionsToggle=button(v.title,'',function() O.Toggle(v) end)
	v.optionsToggle:SetSize(24,24)
	v.optionsToggle.icon=v.optionsToggle:CreateTexture(nil,'ARTWORK')
	v.optionsToggle.icon:SetSize(16,16); v.optionsToggle.icon:SetPoint('CENTER')
	v.optionsToggle.icon:SetTexture('Interface\\AddOns\\BagSmith\\Media\\mark.tga')
	v.optionsToggle:SetScript('OnEnter',function(b)
		if ns.TooltipsOK() then GameTooltip:SetOwner(b,'ANCHOR_RIGHT'); ns.TipText(GameTooltip,'Bag Options'); if b.tipStatus and b.tipStatus~='' then ns.TipLine(GameTooltip,b.tipStatus,0.8,0.8,0.8,true) end; GameTooltip:Show() end
	end)
	v.optionsToggle:SetScript('OnLeave',function() GameTooltip:Hide() end)
	v.frame:HookScript('OnHide',function() O.Toggle(v,false) end)
	v.frame:HookScript('OnSizeChanged',function() O.Position(v) end)
	d:Hide()
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
end
function O.Toggle(v,on)
	local d=v.optionsDrawer
	if not d then return end
	if on==nil then on=not d:IsShown() end
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
		local icon=v.btnFilter:CreateTexture(nil,'ARTWORK'); icon:SetSize(16,16); icon:SetPoint('CENTER')
		icon:SetTexture('Interface\\AddOns\\BagSmith\\Media\\ui-set-filter.tga'); v.btnFilter.optionsIcon=icon
	end
	v.btnFilter.tip='Filter'; v.btnFilter:Show()
	v.search:SetTextInsets(18,48,0,0)
	if v.search.clearButton then v.search.clearButton:ClearAllPoints(); v.search.clearButton:SetPoint('RIGHT',v.search,'RIGHT',-28,0) end
	if v.btnSearchFold then v.btnSearchFold:Hide() end
	v.tools:Hide()
	if v.title.band then v.title.band:Hide() end
end
function O.Layout(v)
	if not v.optionsDrawer or v.optionsLayingOut then return end
	v.optionsLayingOut=true
	local c,y=v.optionsContent,4
	local s=ns.Skins:Current()
	v.optionsDrawer:SetBackdropColor(unpack(s.bg or {0.12,0.115,0.105,1}))
	v.optionsDrawer:SetBackdropBorderColor(unpack(s.border))
	local function heading(text)
		local f=v.optionsLabels[text]; f:ClearAllPoints(); f:SetPoint('TOPLEFT',c,'TOPLEFT',PAD,-y)
		f:SetTextColor(unpack(s.muted)); y=y+23
	end
	local function row(b,text)
		if not b then return end
		place(b,c,y); b:Show()
		if b.tex then
			b.tex:ClearAllPoints(); b.tex:SetPoint('LEFT',b,'LEFT',4,0); b.tex:SetSize(16,16)
			if not b.optionsLabel then b.optionsLabel=label(b,text or b.tip or '') end
			b.optionsLabel:ClearAllPoints(); b.optionsLabel:SetPoint('LEFT',b,'LEFT',28,0)
			b.optionsLabel:SetText(text or b.tip or ''); b.optionsLabel:SetTextColor(unpack(s.text))
		end
		y=y+28
	end
	local function segments(btns)
		for _,b in ipairs(btns) do
			if not b.optionsLevel and b.SetActive then
				local paint=b.SetActive
				b.SetActive=function(self,on) paint(self,on); self:SetFrameLevel(self:GetParent():GetFrameLevel()+2) end
				b.optionsLevel=true
			end
		end
		local width=(WIDTH-2*PAD)/#btns
		for j,b in ipairs(btns) do
			place(b,c,y,width); b:ClearAllPoints(); b:SetPoint('TOPLEFT',c,'TOPLEFT',PAD+(j-1)*width,-y); b:Show()
			if b.divider then b.divider:Hide() end
		end
		y=y+30
	end
	-- All original callbacks and GlobalOff tooltips remain on the same buttons.
	heading('View'); segments(v.viewSegBtns)
	heading('Layout'); segments(v.optionsLayout)
	for _,b in ipairs(v.optionsLayout) do
			b:SetActive(b.mode==(ns.db.compactCategories and 'Compact' or ns.db.splitView and 'Split' or 'Standard'))
		if v:Pref('view')=='icons' and v:Pref('grp')~='none' then b:Enable() else b:Disable() end
	end
	heading('Grouping'); for _,b in ipairs(v.grpSegBtns) do row(b); if b.divider then b.divider:Hide() end end; row(v.btnLanes,v.btnLanes.tip)
	heading('Sorting'); row(v.btnSort); row(v.btnMerge)
	heading('Category Details')
	for _,b in ipairs(v.optionsDetails) do row(b); b:SetActive(ns.db[b.key]) end
	heading('Tools')
	for _,key in ipairs({'btnClean','btnDisenchant','btnGearSets','btnBank','btnCurrency','btnGlobal','btnTravel','btnSettings'}) do
		local b=v[key]
		local show=key~='btnDisenchant' or ns.db.deEnabled
		if key=='btnGearSets' then show=ns.GearSets and ns.GearSets:Available() end
		if b then if show then row(b) else b:Hide() end end
		if b and key=='btnDisenchant' then b:SetActive(show and ns.Disenchant and ns.Disenchant.frame and ns.Disenchant.frame:IsShown() or false) end
	end
	c:SetHeight(y+8)
	local max=math.max(0,c:GetHeight()-v.optionsScroll:GetHeight())
	v.optionsScroll:SetVerticalScroll(math.min(max,v.optionsScroll:GetVerticalScroll() or 0))
	v.optionsDrawer.scrollHint:SetShown(max>0)
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

