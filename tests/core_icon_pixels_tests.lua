-- Geometry-aware checks: fractional screen positions, nested effective scales,
-- and physical resolutions. Unlike the generic mock, these textures resolve anchors.
local ns = { db = { skin = 'classic', border = 'unc' }, OnSignal = function() end }
C_Item = { GetItemQualityColor = function() return 0, 1, 0 end }
assert(loadfile('BagSmith/Core/Buttons.lua'))('BagSmith', ns)
local function texture()
 local t = { points = {} }
 function t:SetPoint(...) self.points[#self.points + 1] = {...} end
 function t:ClearAllPoints() self.points = {} end
 function t:SetSize(w,h) self.w,self.h=w,h end
 function t:SetBlendMode(mode) self.blend=mode end
 function t:SetDrawLayer(layer,sub) self.layer,self.sub=layer,sub end
 function t:SetTexture(file) self.file=file end
 function t:SetVertexColor() end
 function t:SetRoundLayoutToNearestPixel() end
 function t:Show() self.shown=true end
 function t:Hide() self.shown=false end
 function t:SetAllPoints(target) self.allPoints=target end
 function t:SetAlpha() end
 function t:GetTexCoord() return 0,0,0,1,1,0,1,1 end
 function t:SetTexCoord(...) self.uv={...} end
 function t:GetRect()
  local p=self.points[1]; if not p then return end
  local x,y,w,h=p[2]:GetRect(); if not x then return end
  if p[1]=='BOTTOMLEFT' then return x+p[4],y+p[5],self.w,self.h end
  if p[1]=='LEFT' then return x+p[4],y+(h-self.h)/2+p[5],self.w,self.h end
  local q=self.points[2]
  return x+p[4], y+q[5], w+q[4]-p[4], h+p[5]-q[5]
 end
 function t:GetWidth() local _,_,w=self:GetRect(); return w end
 return t
end
local function integer(n) return math.abs(n-math.floor(n+0.5))<0.000001 end
-- Bold must never cover the icon artwork, including after resizing.
PixelUtil={GetPixelToUIUnitFactor=function() return 1 end}
do
 local b={classicBoldActive=true,classicBold={},classicBorderOutset=2}
 function b:GetEffectiveScale() return 1 end
 for i=1,4 do b.classicBold[i]=texture() end
 for size=24,96 do
  b.icon={GetRect=function() return 0,0,size,size end}
  b.qFrame={GetRect=function() return -2,-2,size+4,size+4 end}
  ns.Buttons:UpdateClassicBoldGeometry(b)
  local topX,_,topW=b.classicBold[1]:GetRect()
  assert(topX==-2 and topW==size+4,'Textured edges cover the outside margin without gaps at the corners')
  for _,part in ipairs(b.classicBold) do
   local x,y,w,h=part:GetRect()
   assert(x+w<=0 or x>=size or y+h<=0 or y>=size,'Bold reinforcement must stay entirely outside the icon')
   local uv=part.uv
   assert(math.abs(-2+uv[1]*(size+4)-x)<.000001 and math.abs(-2+uv[2]*(size+4)-x-w)<.000001,'Every size samples the same horizontal contour')
   assert(math.abs(-2+(1-uv[3])*(size+4)-y-h)<.000001 and math.abs(-2+(1-uv[4])*(size+4)-y)<.000001,'Every size samples the same vertical contour')
  end
 end
end
for _, screenH in ipairs({1080,1440,2160}) do
 PixelUtil={GetPixelToUIUnitFactor=function() return 768/screenH end}
 for _,scale in ipairs({0.3,0.48,0.64,0.8,.9,1,1.1,1.25,1.5}) do
  for _,skin in ipairs({'classic','modern'}) do
   for _,mode in ipairs({'cell','row'}) do
    ns.db.skin=skin
    local b={mode=mode,x=101.317,y=203.719,w=37,h=37,icon=texture(),Count=texture(),slotBG=texture()}
    function b:GetRect() return self.x,self.y,self.w,self.h end
    function b:GetWidth() return self.w end
    b.scale=scale
    function b:GetEffectiveScale() return self.scale end
    function b:CreateTexture() return texture() end
    function b:HookScript(event, fn) self.hooks=self.hooks or {}; self.hooks[event]=fn end
    b.iconLayoutX,b.iconPx=41.3,18
    if mode=='row' then b.w,b.h=300,24; b.icon:SetSize(18,18); b.icon:SetPoint('LEFT',b,'LEFT',41.3,0) end
    b.Count:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-2,2)
    local countAnchor=b.Count.points[1]
    ns.Buttons.AddFrame(b)
    assert(b.slotBG.allPoints==b.icon,'Empty-slot art must share the snapped icon footprint')
    ns.Buttons:ApplyFrame(b)
    ns.Buttons:ApplyQuality(b,{quality=2})
    for move=1,3 do
     ns.Buttons:RealignModernBorders()
     local x,y,w,h=b.icon:GetRect()
     local pixel=ns.Buttons.PixelSize(b)
     if skin=='classic' and mode=='cell' then
      local margin=math.max(0,math.min(2,math.floor((math.floor(6/pixel)-2)/2)))
      for _,frame in ipairs({b.qFrame,b.defaultFrame}) do
       local fx,fy,fw,fh=frame:GetRect()
       assert(fx and math.abs((x-fx)/pixel-margin)<0.000001 and math.abs((y-fy)/pixel-margin)<0.000001,'Classic border margin must use available physical-pixel space without moving the icon')
       assert(math.abs((fw-w)/pixel-2*margin)<0.000001 and math.abs((fh-h)/pixel-2*margin)<0.000001,'Border margin must be symmetric at every scale')
       local adjacent=math.floor((b.x+37+6)/pixel+0.5)*pixel
       assert(adjacent-margin*pixel>=fx+fw,'Expanded borders must not overlap adjacent slots')
      end
     end
     assert(integer(x/pixel) and integer(y/pixel) and integer(w/pixel) and integer(h/pixel), 'Icon bounds must land on physical pixels: '..skin..' '..mode)
     assert(math.abs(w-h)<0.000001,'Square icons must remain square at fractional positions')
     if b.previousWidth then assert(math.abs(w-b.previousWidth)<0.000001,'Moving must not change icon dimensions') end
     b.previousWidth=w
     assert(b.Count.points[1]==countAnchor,'Pixel alignment must not move numeric anchors')
     assert(b.Count.layer=='OVERLAY' and b.Count.sub>2,'Counts must draw above borders')
     if mode=='cell' then
      local expected=37-(skin=='modern' and 4 or 0)
      assert(math.abs(ns.Buttons:IconPx(b)-expected)<0.00001,'Report actual logical icon size for each skin')
     elseif skin=='classic' then
      assert(math.abs(b.qRing.points[1][4]+pixel)<0.000001,'Classic row ring must be one physical pixel')
     end
     if skin=='classic' and mode=='row' then
      ns.Buttons:ApplyQuality(b,{quality=1})
      assert(b.qRing.shown and not b.defaultFrame.shown,'Neutral rows use the solid ring at every scale')
      local rx,ry,rw,rh=b.qRing:GetRect()
      assert(math.abs((x-rx)/pixel-1)<.000001 and math.abs((y-ry)/pixel-1)<.000001,'Left and bottom neutral edges remain one physical pixel')
      assert(math.abs((rx+rw-x-w)/pixel-1)<.000001 and math.abs((ry+rh-y-h)/pixel-1)<.000001,'Right and top neutral edges remain one physical pixel')
     end
     local anchors=b.icon.points
     ns.Buttons:RealignModernBorders()
     assert(b.icon.points==anchors,'Settled geometry must not rewrite anchors')
     b.x,b.y=b.x+0.27,b.y+0.19
    end
    -- Bold keeps its frame and reinforcement aligned within the available gap.
    ns.db.borderWeight='bold'
    ns.Buttons:ApplyQuality(b,{quality=2})
    ns.Buttons:RealignModernBorders()
    local px=ns.Buttons.PixelSize(b)
    if skin=='modern' or mode=='row' then
     assert(b.modernBorder[1].shown and math.abs(b.modernBorder[1].h/px-2)<.000001,'Bold solid outlines are two physical pixels')
     if skin=='classic' then assert(not b.qRing.shown,'Bold rows do not double up translucent rings') end
    else
     assert(b.classicBold and b.qFrame.shown,'Bold Classic preserves the original bevel')
     for _,part in ipairs(b.classicBold) do
      assert(part.file==b.qFrame.file,'Bold must sample the Blizzard frame itself')
      if part.boldVisible then
       local x,y,w,h=part:GetRect()
       local fx,fy,fw,fh=b.qFrame:GetRect()
       local uv=part.uv
       assert(uv and math.abs(fx+uv[1]*fw-x)<.000001 and math.abs(fx+uv[2]*fw-x-w)<.000001,'Border texture must align horizontally with the Blizzard frame')
       assert(math.abs(fy+(1-uv[3])*fh-y-h)<.000001 and math.abs(fy+(1-uv[4])*fh-y)<.000001,'Border texture must align vertically with the Blizzard frame')
      end
     end
     local fx,fy,fw,fh=b.qFrame:GetRect()
     local expected=math.max(0,math.min(3,math.floor((math.floor(6/px)-2)/2)))*px
     assert(math.abs(b.classicBorderOutset-expected)<.000001,'Bold base frame must grow with the reinforcement')
     assert(math.abs(b.boldOutset-b.classicBorderOutset)<.000001,'Bold and the base frame must share one contour at the corners')
     local adjacent=math.floor((b.x+37+6)/px+0.5)*px
     assert(adjacent-b.boldOutset>=fx+fw-.000001,'Thicker Bold frames must remain separated')
     local _,_,sideW=b.classicBold[3]:GetRect()
     assert(sideW<=3*px+.000001,'Classic Bold stays within reserved slot spacing')
     for _,part in ipairs(b.classicBold) do
      assert(part.blend=='ADD','Bold strengthens only the sampled Blizzard outline')
     end
     for _,part in ipairs(b.classicBold) do
      local sx,sy,sw,sh=part:GetRect()
      assert(not part.shown or (sx>=fx-.000001 and sy>=fy-.000001 and sx+sw<=fx+fw+.000001 and sy+sh<=fy+fh+.000001),'Visible Bold strips remain within reserved spacing')
      local ix,iy,iw,ih=b.icon:GetRect()
      if part.shown then assert(sx+sw<=ix+.000001 or sx>=ix+iw-.000001 or sy+sh<=iy+.000001 or sy>=iy+ih-.000001,'Visible Bold geometry cannot overlap the icon artwork') end
      assert(integer(sw/px) and integer(sh/px),'Bold artwork slice sizes use whole physical pixels')
     end
     for i,part in ipairs(b.classicBold) do
      local ax,ay,aw,ah=part:GetRect()
      for j=i+1,#b.classicBold do
       local bx,by,bw,bh=b.classicBold[j]:GetRect()
       local overlapW=math.min(ax+aw,bx+bw)-math.max(ax,bx)
       local overlapH=math.min(ay+ah,by+bh)-math.max(ay,by)
       assert(not part.shown or not b.classicBold[j].shown or overlapW<.000001 or overlapH<.000001,'Translucent textured pieces must not overlap and increase opacity')
      end
     end
    end
    assert(b.Count.points[1]==countAnchor,'Bold must not move counts')
    ns.db.borderWeight='normal'
    ns.Buttons:ApplyQuality(b,{quality=2})
    for _,part in ipairs(b.classicBold or {}) do assert(not part.shown,'Normal hides Bold artwork on reused cells') end
    if skin=='classic' and mode=='cell' then
     local expected=math.max(0,math.min(2,math.floor((math.floor(6/px)-2)/2)))*px
     assert(math.abs(b.classicBorderOutset-expected)<.000001,'Normal restores its original frame bounds')
    end
    if skin=='modern' then assert(math.abs(b.modernBorder[1].h/px-1)<.000001,'Normal restores one-pixel thickness without movement') end
    -- A reused button must handle live scale and skin changes, not just creation.
    b.scale=scale*0.91
    ns.db.skin=skin=='classic' and 'modern' or 'classic'
    ns.Buttons:ApplyFrame(b)
    ns.Buttons:ApplyQuality(b,{quality=1,classID=12})
    ns.Buttons:RealignModernBorders()
    local x,y,w,h=b.icon:GetRect()
    local pixel=ns.Buttons.PixelSize(b)
    assert(integer(x/pixel) and integer(y/pixel) and integer(w/pixel) and integer(h/pixel),'Reused icons must realign after scale/skin changes')
    assert(b.Count.points[1]==countAnchor,'Skin/scale changes must preserve numeric anchors')
    -- A template/item refresh may replace texture bounds while the button
    -- itself has not moved. The last requested geometry is not proof of reality.
    local ix,iy,iw,ih=b.icon:GetRect()
    b.icon:ClearAllPoints(); b.icon:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',0,0)
    b.icon:SetSize(b.w,b.h)
    ns.Buttons:RealignModernBorders()
    local ax,ay,aw,ah=b.icon:GetRect()
    assert(math.abs(ax-ix)<.000001 and math.abs(ay-iy)<.000001 and math.abs(aw-iw)<.000001 and math.abs(ah-ih)<.000001,
     'An overwritten icon must recover without moving or resizing the button')
    for _,event in ipairs({'OnShow','OnSizeChanged'}) do
     assert(b.hooks and b.hooks[event],'Visibility and size changes must wake alignment')
     b.icon:SetSize(b.w,b.h)
     b.hooks[event](b)
     local _,_,rw,rh=b.icon:GetRect()
     assert(math.abs(rw-iw)<.000001 and math.abs(rh-ih)<.000001,'A visible/size transition must repair icon bounds')
    end
    local rect=b.GetRect
    b.GetRect=function() return nil end
    ns.Buttons:ApplyFrame(b) -- layout may be unresolved immediately after a resize
    b.GetRect=rect
    ns.Buttons:RealignModernBorders()
    x,y,w,h=b.icon:GetRect()
    assert(integer(x/pixel) and integer(y/pixel),'Driver must retry unresolved layout')
   end
  end
 end
end
print('Pixel geometry matrix passed')
