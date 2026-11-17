;(function()
-- The 2.0 presentation keeps actions and inventory data working in both layouts.
package.loaded.mock = nil
local M = require('mock')
M.shippingAppearance = true
M.sizes[0] = 40
for i = 1, 20 do
 M.put(0, i, {id=82000+i, name='Sample '..i, q=1, class=i<=12 and 0 or 7, subclass=0, price=123, count=2})
end
_G.BagSmithCharDB = {version=1, firstSeen={}}
_G.BagSmithDB = {version=2, chars={}, cache={}, profiles={Default={skin='modern', view='icons', grp='type', sizeMode='fixed', fixW=720, recentSection=false, mergeStacks=false, compactCategories=true}}}
local n = M.loadAddon('BagSmith')
M.fire('ADDON_LOADED','BagSmith'); M.fire('PLAYER_ENTERING_WORLD'); M.runTimers(); M.runTimers()
assert((n.errors or 0)==0,table.concat(n.errorLog or {},' | '))
n.Window:Show(); M.runTimers(); M.runTimers()
local V = n.Window.main
V.frame.IsMouseOver = function() return false end
check(V.optionsDrawer ~= nil, 'bag has an options drawer')
if not V.optionsDrawer then return end
local w, h = V.frame:GetWidth(), V.frame:GetHeight()
V.optionsToggle:GetScript('OnClick')(V.optionsToggle)
check(V.optionsDrawer:IsShown(), 'bag button opens drawer')
check(V.frame:GetWidth()==w and V.frame:GetHeight()==h, 'opening drawer does not resize inventory')
check(V.btnSort:GetParent()==V.optionsContent, 'original sort action lives in drawer')
check(V.btnSettings:GetParent()==V.optionsContent, 'settings moved out of title bar')
check(not V.tools:IsShown(), 'old toolbar is hidden')
V.optionsToggle:GetScript('OnClick')(V.optionsToggle)
check(not V.optionsDrawer:IsShown(), 'bag button closes drawer')
local oldSort = V:Pref('sort')
V.btnSort:GetScript('OnClick')(V.btnSort); M.runTimers()
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
 check(V.btnSettings:GetParent()==V.optionsContent,skin..': tools remain in drawer')
 checkHeaders(skin)
end
n:Set('travelMode',true); M.runTimers(); M.runTimers(); V:SyncTools()
check(not V.btnLanesTravel:IsShown(),'Travel Mode does not leak its old title control outside the drawer')
check(V.btnBags.bgColor and V.btnBags.bgColor[4]==0,'footer counters are unboxed')
for _,b in ipairs(V.grpSegBtns) do b:SetActive(b.active); check(b:GetFrameLevel()>=V.optionsContent:GetFrameLevel(),'drawer controls paint above their parent') end
n:Set('travelMode',false); M.runTimers(); M.runTimers()
local B=n.Window.bank
check(B.optionsDrawer~=nil,'bank also has its own drawer')
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
check((n.errors or 0)==0,'no addon errors')

end)()

