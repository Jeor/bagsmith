-- Measure visible details before placing items. Pooled headers are reset on every pass.
local _, ns = ...
local H = {}
ns.CategoryHeader = H
function H.Apply(i)
	local h, width = i.h, i.colW
	local s=ns.Skins:Current()
	local base=ns.Fonts and ns.Fonts:Grow(26) or 26
	local lineH=ns.Fonts and ns.Fonts:Grow(16) or 16
	h.band:Hide(); h.accent:Hide()
	h.text:SetTextColor(unpack(s.text))
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
	local height=base
	h.line:ClearAllPoints(); h.line:SetHeight(1); h.line:SetColorTexture(unpack(s.line))
	if text~='' and titleWidth+valueWidth+24>width then
		h.sub:SetPoint('TOPLEFT',h,'TOPLEFT',20,-base)
		h.sub:SetJustifyH('LEFT'); h.sub:SetWidth(math.max(1,width-24)); h.sub:SetWordWrap(true)
		height=base+math.max(lineH,h.sub:GetStringHeight())+6
		h.line:SetPoint('BOTTOMLEFT',h,'BOTTOMLEFT',20,1); h.line:SetPoint('BOTTOMRIGHT',h,'BOTTOMRIGHT',-4,1)
	else
		h.sub:SetPoint('TOPRIGHT',h,'TOPRIGHT',-4,-6); h.sub:SetJustifyH('RIGHT')
		local left=math.min(width-4,titleWidth+10)
		local right=math.max(left,width-(text~='' and valueWidth+14 or 4))
		h.line:SetPoint('TOPLEFT',h,'TOPLEFT',left,-base/2)
		h.line:SetWidth(math.max(1,right-left))
	end
	h.sub:SetShown(text~=''); h.line:Show()
	h:SetHeight(height)
	i.v2=true
	return height
end
