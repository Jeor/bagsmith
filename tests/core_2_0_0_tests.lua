;(function()
-- The 2.0 presentation keeps actions and inventory data working in both layouts.
package.loaded.mock = nil
local M = require('mock')
M.shippingAppearance = true
-- WoW may resolve a backdrop's geometry synchronously, firing the toolbar's
-- OnSizeChanged while BagOptions.Build is still creating the merge checkbox.
-- The basic mock does not dispatch that nested geometry notification.
local createFrame = CreateFrame
local constructionCallbacks, constructionErrors = 0, {}
CreateFrame = function(...)
 local frame = createFrame(...)
 local setBackdrop = frame.SetBackdrop
 frame.SetBackdrop = function(self, ...)
  setBackdrop(self, ...)
  local parent = self:GetParent()
  if parent and parent.label and (parent.label:GetText() or ''):match('^Merge') then
   local toolbar = parent:GetParent()
   local callback = toolbar and toolbar:GetScript('OnSizeChanged')
   if callback then
    constructionCallbacks = constructionCallbacks + 1
    local ok, err = pcall(callback, toolbar)
    if not ok then constructionErrors[#constructionErrors+1] = tostring(err) end
   end
  end
 end
 return frame
end
M.sizes[0] = 40
for i = 1, 20 do
 M.put(0, i, {id=82000+i, name='Sample '..i, q=1, class=i<=12 and 0 or 7, subclass=0, price=123, count=2})
end
M.put(0,21,{id=83001,name='Valuable Gear',q=3,class=4,subclass=0,price=99999999,count=2})
_G.BagSmithCharDB = {version=1, firstSeen={}}
_G.BagSmithDB = {version=2, chars={}, cache={}, profiles={Default={skin='modern', view='icons', grp='type', sizeMode='fixed', fixW=720, recentSection=false, mergeStacks=false, compactCategories=true}}}
local n = M.loadAddon('BagSmith')
M.fire('ADDON_LOADED','BagSmith'); M.fire('PLAYER_ENTERING_WORLD'); M.runTimers(); M.runTimers()
CreateFrame = createFrame
check(constructionCallbacks>=2,'main and bank reproduce nested construction resize callbacks')
check(#constructionErrors==0,'construction resize callbacks are safe: '..table.concat(constructionErrors,' | '))
assert((n.errors or 0)==0,table.concat(n.errorLog or {},' | '))
n.Window:Show(); M.runTimers(); M.runTimers()
local V = n.Window.main
V.frame.IsMouseOver = function() return false end
check(V.optionsDrawer ~= nil, 'bag has an options drawer')
if not V.optionsDrawer then return end
check(not V.optionsLayingOut,'construction leaves the layout guard clear')
for _,key in ipairs({'btnClean','btnGearSets','btnBank','btnCurrency','btnGlobal','btnTravel'}) do
 if V[key] then check(not V[key]:IsShown() or V[key]:GetParent()==V.optionsContent,key..' is hidden or attached to the drawer after nested resize') end
end
local w, h = V.frame:GetWidth(), V.frame:GetHeight()
V.optionsToggle:GetScript('OnClick')(V.optionsToggle)
check(V.optionsDrawer:IsShown(), 'bag button opens drawer')
check(V.frame:GetWidth()==w and V.frame:GetHeight()==h, 'opening drawer does not resize inventory')
check(V.btnSort:GetParent()==V.optionsContent, 'original sort action lives in drawer')
check(V.btnSettings:GetParent()==V.optionsDrawer, 'settings moved out of title bar')
check(not V.tools:IsShown(), 'old toolbar is hidden')
V.optionsToggle:GetScript('OnClick')(V.optionsToggle)
check(not V.optionsDrawer:IsShown(), 'bag button closes drawer')
local oldSort = V:Pref('sort')
local entries
local oldMenu=n.ShowMenu
n.ShowMenu=function(items) entries=items end
V.btnSort:GetScript('OnClick')(V.btnSort)
check(entries and #entries==6,'sorting opens a menu instead of cycling')
if entries then entries[2].onClick() end
n.ShowMenu=oldMenu; M.runTimers()
check(V:Pref('sort')~=oldSort, 'sort action still changes sorting')
local function checkHeaders(label)
 local count = 0
 for _, b in ipairs(V.used or {}) do
  if b.laneId and b.text and b:IsShown() then
   count=count+1
   check(not b.band:IsShown() and not b.accent:IsShown(), label..': lightweight header')
   check(b.sub:IsShown() and b.sub:GetText()~='', label..': vendor value remains visible')
  end
 end
 check(count>=2,label..': categories remain visible')
end
checkHeaders('compact')
local rows,wrapped={},false
for _,h in ipairs(V.used or {}) do
 if h.laneId and h.text and h:IsShown() then
  local top=h.points[1][5]
  wrapped=wrapped or h:GetHeight()>26
  for _,b in ipairs(V.used) do
   if b.rec and b.inLane==h.laneId then
    local firstY=b.points[1][5]
    if rows[top] then check(rows[top]==firstY,'compact first item rows align with wrapped metadata') else rows[top]=firstY end
    break
   end
  end
 end
end
check(wrapped,'alignment fixture includes wrapped category metadata')

n:Set('compactCategories',false); n:Set('splitView',true); M.runTimers(); M.runTimers()
checkHeaders('split')
V:SetGlobal(true); M.runTimers(); M.runTimers()
for _, b in ipairs(V.grpSegBtns) do if b.value=='bag' then check(not b:IsEnabled(),'Global Inventory still disables By Bag') end end
V:SetGlobal(false); M.runTimers(); M.runTimers()
-- Optional details are independently controllable and pooled headers reset.
n:Set('categoryVendor',false); n:Set('categoryCount',false); V:Refresh(true); M.runTimers()
for _,b in ipairs(V.used or {}) do
 if b.laneId and b.text and b:IsShown() then
  check(not b.sub:IsShown(),'vendor details can be disabled')
  check(not b.count:IsShown(),'category count can be disabled')
 end
end
n:Set('categoryVendor',true); n:Set('categoryCount',true); V:Refresh(true); M.runTimers()
checkHeaders('details restored')
local heading
for _,b in ipairs(V.used or {}) do if b.laneId and b.text then heading=b; break end end
local i={h=heading,colW=150,v='123456 gold 99 silver 99 copper',ah='765432 gold'}
local tall=n.CategoryHeader.Apply(i)
check(tall>26 and heading.sub:IsShown(),'narrow headers reserve another line for vendor and AH details')
check(heading.sub:GetText():find('AH:',1,true)~=nil,'auction value remains visible')
i.colW=900; local short=n.CategoryHeader.Apply(i)
check(short<tall,'pooled heading returns to one line at wide widths')
for _,skin in ipairs({'classic','modern'}) do
 n:Set('skin',skin); M.runTimers(); M.runTimers(); V:Refresh(true)
 check(V.optionsToggle:IsShown() and not V.tools:IsShown(),skin..': new chrome survives skin change')
 check(V.btnSettings:GetParent()==V.optionsDrawer,skin..': tools remain in drawer')
 checkHeaders(skin)
end
n:Set('travelMode',true); M.runTimers(); M.runTimers(); V:SyncTools()
check(not V.btnLanesTravel:IsShown(),'Travel Mode does not leak its old title control outside the drawer')
check(V.btnBags.bgColor and V.btnBags.bgColor[4]==0,'footer counters are unboxed')
for _,b in ipairs(V.grpSegBtns) do b:SetActive(b.active); check(b:GetFrameLevel()>=V.optionsContent:GetFrameLevel(),'drawer controls paint above their parent') end
n:Set('travelMode',false); M.runTimers(); M.runTimers()
check(V.optionsContent:GetHeight()<650,'options fit into a substantially shorter panel')
check(V.btnGrpMenu:GetParent()==V.optionsContent and V.btnGrpMenu:IsShown(),'grouping uses its dropdown')
for _,b in ipairs(V.grpSegBtns) do check(not b:IsShown(),'old vertical grouping choices are hidden') end
for _,b in ipairs(V.optionsDetails) do check(b.optionsCheck~=nil,'category options use checkboxes') end
check(V.optionsScrollbar~=nil,'overflow has a usable scrollbar')
local B=n.Window.bank
check(B.optionsDrawer~=nil,'bank also has its own drawer')
n.BagOptions.Toggle(V,true)
n.BagOptions.Toggle(B,true)
n.Drawer:Show()
check(n.Drawer.frame:IsShown() and not V.optionsDrawer:IsShown() and not B.optionsDrawer:IsShown(),'currencies dismiss both bag options drawers')
n.BagOptions.Toggle(V,true)
check(V.optionsDrawer:IsShown() and not n.Drawer.frame:IsShown(),'opening bag options dismisses currencies')
n.Drawer:Show()
n.BagOptions.Toggle(B,true)
check(B.optionsDrawer:IsShown() and not n.Drawer.frame:IsShown(),'opening bank options also dismisses currencies')
n.BagOptions.Toggle(B,false)
local before=V:Pref('sort')
B.btnSort:GetScript('OnClick')(B.btnSort); M.runTimers()
check(V:Pref('sort')==before,'bank sorting does not change bag sorting')
V.optionsScroll:GetScript('OnMouseWheel')(V.optionsScroll,-100)
check(V.optionsScroll:GetVerticalScroll()<=math.max(0,V.optionsContent:GetHeight()-V.optionsScroll:GetHeight()),'drawer scrolling clamps to content')
M.combat=true
local ok=pcall(function() V.optionsToggle:GetScript('OnClick')(V.optionsToggle); V.optionsToggle:GetScript('OnClick')(V.optionsToggle) end)
check(ok,'drawer opens and closes without moving protected items in combat')
M.combat=false
SlashCmdList.BAGSMITH('v2 off')
check(n.db.visualRefresh==false and V.optionsDrawer~=nil,'rollback waits for reload, leaving active layout consistent')
SlashCmdList.BAGSMITH('v2')
check(n.db.visualRefresh==true,'preview can be restored')
V.optionsToggle:GetScript('OnClick')(V.optionsToggle); V:Hide()
check(not V.optionsDrawer:IsShown(),'closing bag closes its drawer')

check(type(n.CategoryHeader.AlignRow)=='function','compact layout aligns heading heights per row')
if n.CategoryHeader.AlignRow then
 local host=CreateFrame('Frame')
 local h1,h2=CreateFrame('Frame',nil,host),CreateFrame('Frame',nil,host)
 h1:SetHeight(26); h2:SetHeight(48)
 local a,b=CreateFrame('Button',nil,host),CreateFrame('Button',nil,host)
 a:SetPoint('TOPLEFT',host,'TOPLEFT',0,-30); b:SetPoint('TOPLEFT',host,'TOPLEFT',100,-52)
 local pin=host:CreateTexture(); pin.SetHeight=function(self,value) self.h=value end; pin:SetHeight(76)
 local bottom=n.CategoryHeader.AlignRow({{header=h1,first=1,last=1,bottom=76,pin=pin},{header=h2,first=2,last=2,bottom=100}}, {a,b}, host)
 check(h1:GetHeight()==48 and h2:GetHeight()==48,'row shares the tallest heading')
 check(a.points[1][5]==-52 and b.points[1][5]==-52,'first item baselines align without moving the taller group')
 check(bottom==100 and pin:GetHeight()==98,'row extent and pinned background include the extra header space')
end
local recent=CreateFrame('Frame')
recent.text=recent:CreateFontString(); recent.text:SetText('Recent')
recent.count=recent:CreateFontString(); recent.count:SetText('(6)')
recent.line=recent:CreateTexture(); recent.sub=recent:CreateFontString()
recent.clearRecent=n.TextButton(recent,'Clear Recent',86,function() end)
n.CategoryHeader.Finish({{v2=true,recent=true,h=recent,colW=150}})
check(not recent.line:IsShown(),'narrow Recent header does not draw a divider through its action')
check(recent.clearRecent.points[1][1]=='TOPRIGHT','Clear Recent stays on the right')
check((n.errors or 0)==0,'no addon errors')

end)()
