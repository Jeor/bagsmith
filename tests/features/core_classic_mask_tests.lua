package.path = 'tests/?.lua;' .. package.path
local TGA = require('tga')
local base = 'BagSmith/Media/ui-icon-'
local normal = assert(TGA.load(base .. 'frame.tga'))
local bold = assert(TGA.load(base .. 'frame-bold.tga'))
local mask = assert(TGA.load(base .. 'mask.tga'))
assert(normal.w == bold.w and normal.h == mask.h)
local brighter = 0
for i = 1, #normal.pixels, 4 do
 local r, a = normal.pixels:byte(i), normal.pixels:byte(i+3)
 local br, ba = bold.pixels:byte(i), bold.pixels:byte(i+3)
 assert(a == ba, 'Bold must preserve exact alpha and geometry')
 if a > 0 then assert(br > r, 'Bold brightens RGB'); brighter = brighter + 1 end
end
assert(brighter > 0)
assert(mask.pixels:byte(4) == 0, 'Corners clip artwork')
assert(mask.pixels:byte((64*128+64)*4+4) == 255, 'Center stays opaque')
package.loaded.mock = nil
local M = require('mock')
BagSmithDB = {version=2, profiles={Default={skin='classic'}}, chars={}, cache={}}
BagSmithCharDB = nil
local n = M.loadAddon('BagSmith')
M.fire('ADDON_LOADED','BagSmith'); M.fire('PLAYER_ENTERING_WORLD'); M.runTimers()
for _, b in ipairs({n.Buttons:Get(0,1), n.Buttons:GetCached(n.Window.main.child,1)}) do
 n.db.skin='classic'; n.Buttons:SetMode(b,'cell')
 assert(b.icon.mask == b.classicMask and b.classicMask.texture:find('ui-icon-mask',1,true))
 for _, weight in ipairs({'normal','bold','normal'}) do
  n.db.borderWeight=weight; n.Buttons:ApplyQuality(b,{quality=2})
  local suffix=weight=='bold' and 'frame-bold.tga' or 'frame.tga'
  assert(b.qFrame.texture:find(suffix,1,true))
 end
 n.db.skin='modern'; n.Buttons:ApplyFrame(b)
 assert(b.classicMask.texture == 'Interface\\Buttons\\WHITE8X8')
 n.db.skin='classic'; n.Buttons:SetMode(b,'row')
 assert(b.classicMask.texture == 'Interface\\Buttons\\WHITE8X8')
 n.Buttons:SetMode(b,'cell')
 assert(b.classicMask.texture:find('ui-icon-mask',1,true))
end
