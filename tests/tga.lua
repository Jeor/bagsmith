-- Reads BagSmith's TGA textures for the tests, stored plainly (type 2) or compressed (type 10, run-length, since
-- 1.9.5-beta1). TGA.load(path) gives { w, h, type, bpp, desc, pixels } with the pixels decoded (BGRA, bottom row
-- first, as stored); TGA.uncompressed(path) gives the file as it would be stored plainly (an 18-byte header, then the
-- pixels), so a check written against the plain file reads the same bytes at the same places.
local TGA = {}
function TGA.load(path)
	local f = io.open(path, "rb")
	if not f then return nil, "missing" end
	local d = f:read("*a"); f:close()
	local idlen, itype = d:byte(1), d:byte(3)
	local w, h = d:byte(13) + d:byte(14) * 256, d:byte(15) + d:byte(16) * 256
	local bpp, desc = d:byte(17), d:byte(18)
	local p, need = 19 + idlen, w * h * 4
	local pixels
	if itype == 2 then
		pixels = d:sub(p, p + need - 1)
	elseif itype == 10 then
		local out, got = {}, 0
		while got < need do
			local c = d:byte(p); p = p + 1
			if not c then return nil, "short" end
			local n = (c % 128) + 1
			if c >= 128 then out[#out + 1] = d:sub(p, p + 3):rep(n); p = p + 4
			else out[#out + 1] = d:sub(p, p + n * 4 - 1); p = p + n * 4 end
			got = got + n * 4
		end
		pixels = table.concat(out)
	else
		return nil, "type " .. tostring(itype)
	end
	if #pixels ~= need then return nil, "size" end
	return { w = w, h = h, type = itype, bpp = bpp, desc = desc, pixels = pixels }
end
function TGA.uncompressed(path)
	local t = assert(TGA.load(path))
	local hdr = string.char(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, t.w % 256, math.floor(t.w / 256), t.h % 256, math.floor(t.h / 256), t.bpp, t.desc)
	return hdr .. t.pixels
end
return TGA
