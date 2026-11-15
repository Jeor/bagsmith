-- The scroll viewport clips textures extending left of the first grid cell.
package.loaded.mock = nil
local M = require("mock")
for s=1,12 do M.put(0,s,{id=8100+s,name="Item"..s,q=2,count=12,class=0,subclass=5,price=1}) end
BagSmithCharDB={version=1,firstSeen={}}
BagSmithDB={version=2,chars={},cache={},profiles={Default={skin="classic"}}}
local n=M.loadAddon("BagSmith")
M.fire("ADDON_LOADED","BagSmith"); M.fire("PLAYER_ENTERING_WORLD"); M.runTimers(); M.runTimers()
n.Window:Show(); M.runTimers()
local v=n.Window.main
for _,scale in ipairs({.3,.64,1,1.5}) do
 v.frame.GetEffectiveScale=function() return scale end
 for _,skin in ipairs({"classic","modern"}) do
  n.db.skin=skin
  for _,grp in ipairs({"none","type","bag"}) do
   v:SetPref("view","icons"); v:SetPref("grp",grp)
   v:Refresh(true); M.runTimers()
   local pixel=n.Buttons.PixelSize(v.frame)
   local count=0
   for _,b in pairs(v.used or {}) do
    if type(b)=="table" and b.mode=="cell" and b.points[1] then
     local x=b.points[1][4] or 0
     if skin=="classic" then
      check(x>=2.5*pixel,"Classic first-column border and rounding stay inside the viewport at scale "..scale.." / "..grp)
      check(x+b:GetWidth()+2.5*pixel <= v.planWidth+.001,"Classic right-edge border stays inside the viewport")
     end
     count=count+1
    end
   end
   check(count>0,"Fixture exercises item cells")
  end
 end
end

-- Standalone bags use a separate slot-grid path, including empty slots.
local bag=n.Window.bagViews[0]
n.db.skin="classic"; bag:Show(); M.runTimers()
local pixel=n.Buttons.PixelSize(bag.frame)
local cells=0
for _,b in pairs(bag.used or {}) do
 if type(b)=="table" and b.mode=="cell" then
  check(b.points[1][4]>=2.5*pixel,"Standalone bag reserves left border clearance")
  cells=cells+1
 end
end
check(cells>0,"Standalone bag fixture exercises the slot grid")
-- Lists must preserve their existing column alignment across skins.
v:SetPref("view","list"); v:Refresh(true); M.runTimers()
local offsets={}
for _,b in pairs(v.used or {}) do if type(b)=="table" and b.mode=="row" then offsets[b]=b.points[1][4] end end
n.db.skin="modern"; v:Refresh(true); M.runTimers()
for b,x in pairs(offsets) do check(b.points[1][4]==x,"List row anchors are unchanged by the Classic gutter") end
