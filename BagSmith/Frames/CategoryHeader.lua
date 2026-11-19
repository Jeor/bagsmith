-- Measure visible details before placing items. Pooled headers are reset on every pass.
local _, ns = ...
local H = {}
ns.CategoryHeader = H
function H.Apply(i)
	local h, width = i.h, i.colW
	local base=ns.Fonts and ns.Fonts:Grow(26) or 26
	h.band:Show(); h.accent:Show()
	h.text:SetTextColor(ns.Skins:Accent())
	h.text:ClearAllPoints(); h.text:SetPoint('TOPLEFT',h,'TOPLEFT',h.textX or 20,-6)
	h.arrow:ClearAllPoints(); h.arrow:SetPoint('TOPLEFT',h,'TOPLEFT',5,-7)
	h.count:SetWidth(0); h.count:SetWordWrap(false)
	if ns.db.categoryCount==false then h.count:SetText('') end
	h.count:SetShown(ns.db.categoryCount~=false)
	if h.setIcon and h.setIcon:IsShown() then h.setIcon:ClearAllPoints(); h.setIcon:SetPoint('TOPLEFT',h,'TOPLEFT',22,-5) end
	for _,key in ipairs({'sub','vLabel','vAmt','aLabel','aAmt'}) do h[key]:Hide() end
	if h.valCoin then h.valCoin:Hide() end
	h.compactValues=nil
	local parts={}
	if not i.recent and not i.emptyCustom and not i.emptySet then
		if ns.db.categoryVendor~=false and i.v and i.v~='-' then parts[#parts+1]=i.v end
		if ns.db.categoryAuction~=false and i.ah and i.ah~='-' then parts[#parts+1]='AH: '..i.ah end
	end
	local text=table.concat(parts,'   ')
	local actions=0
	for _,key in ipairs({'clearRecent','clearShards','equipSet','wornTag'}) do
		local b=h[key]
		if b and b:IsShown() then actions=actions+(b.GetStringWidth and b:GetStringWidth() or b:GetWidth())+10 end
	end
	local titleRoom=math.max(1,width-(h.textX or 20)-10-(ns.db.categoryCount~=false and h.count:GetStringWidth()+6 or 0)-actions)
	if h.text:GetStringWidth()>titleRoom then
		h.compactWrap=not h.text.CanWordWrap or h.text:CanWordWrap()
		h.text:SetWidth(titleRoom); h.text:SetWordWrap(false); h.compactTitle=true
	end
	local titleWidth=(h.textX or 20)+math.min(titleRoom,h.text:GetStringWidth())+6+(ns.db.categoryCount~=false and h.count:GetStringWidth() or 0)+actions
	h.sub:SetWidth(0); h.sub:SetWordWrap(false); h.sub:SetText(text)
	local valueWidth=h.sub:GetStringWidth()
	h.sub:ClearAllPoints()
	-- Values never create another line or enlarge neighboring compact headers.
	i.valuesOverflow=text~='' and titleWidth+valueWidth+24>width
	if i.valuesOverflow then h.compactValues={v=i.v,ah=i.ah} end
	h.sub:SetPoint('TOPRIGHT',h,'TOPRIGHT',-4,-6); h.sub:SetJustifyH('RIGHT')
	h.sub:SetShown(text~='' and not i.valuesOverflow); h.line:Hide()
	h:SetHeight(base)
	i.v2=true
	return base
end

-- The row is rendered once. Only shorter headings and their item offsets need
-- adjusting; secure item buttons are already owned by this out-of-combat layout.
function H.AlignRow(spans, used, host)
	local tallest, bottom=0,0
	for _,span in ipairs(spans) do
		if span.header then tallest=math.max(tallest,span.header:GetHeight()) end
	end
	for _,span in ipairs(spans) do
		local delta=span.header and tallest-span.header:GetHeight() or 0
		if delta>0 then
			span.header:SetHeight(tallest)
			for index=span.first,span.last do
				local b=used[index]
				if b~=span.header then
					local point,relative,relativePoint,x,y=b:GetPoint(1)
					if relative==host and point=='TOPLEFT' then
						b:ClearAllPoints(); b:SetPoint(point,relative,relativePoint,x,y-delta)
					end
				end
			end
			if span.pin then span.pin:SetHeight(span.pin:GetHeight()+delta) end
		end
		bottom=math.max(bottom,span.bottom+delta)
	end
	return bottom
end
function H.Finish(infos)
	for _,i in ipairs(infos) do
		if i.v2 and i.recent and i.h.clearRecent then
			local h,b=i.h,i.h.clearRecent
			b:ClearAllPoints(); b:SetPoint('TOPRIGHT',h,'TOPRIGHT',-4,-4)
			if not b.v2Quiet then
				local paint=b.SetActive
				b.SetActive=function(self,on) paint(self,on); self:SetBackdropColor(0,0,0,0); self:SetBackdropBorderColor(0,0,0,0) end
				b.v2Quiet=true
			end
			b:SetActive(false); h.sub:Hide()
			h.line:Hide()
		end
	end
end
