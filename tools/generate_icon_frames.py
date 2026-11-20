"""Derive Bold and an interior mask from Blizzard's original WhiteIconFrame.

ui-icon-frame.tga preserves the original 64x64 RGBA pixels from
https://github.com/Gethe/wow-ui-textures/blob/live/COMMON/WhiteIconFrame.PNG
Only RGB changes for Bold; alpha and the original bevel geometry are retained.
"""
from pathlib import Path
import struct

MEDIA = Path(__file__).resolve().parents[1] / 'BagSmith' / 'Media'


def read_frame():
    data = (MEDIA / 'ui-icon-frame.tga').read_bytes()
    width, height = struct.unpack_from('<HH', data, 12)
    assert data[2] == 10 and data[16:18] == bytes((32, 8))
    pixels, pos = [], 18 + data[0]
    while len(pixels) < width * height:
        packet = data[pos]
        pos += 1
        count = (packet & 127) + 1
        if packet & 128:
            pixels.extend([tuple(data[pos:pos + 4])] * count)
            pos += 4
        else:
            pixels.extend(tuple(data[i:i + 4]) for i in range(pos, pos + count * 4, 4))
            pos += count * 4
    return width, height, pixels


def write_texture(name, width, height, pixels):
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 10, 0, 0, 0, 0, 0, width, height, 32, 8)
    encoded = bytearray()
    for row in range(height):
        pos, end = row * width, (row + 1) * width
        while pos < end:
            count = 1
            while pos + count < end and count < 128 and pixels[pos + count] == pixels[pos]:
                count += 1
            encoded.append(127 + count)
            encoded.extend(pixels[pos])
            pos += count
    (MEDIA / f'ui-icon-{name}.tga').write_bytes(header + encoded)


def generate():
    width, height, pixels = read_frame()

    def neighbors(i):
        x, y = i % width, i // width
        if x: yield i - 1
        if x + 1 < width: yield i + 1
        if y: yield i - width
        if y + 1 < height: yield i + width

    # Flood only the transparent opening enclosed by the original frame.
    center = (height // 2) * width + width // 2
    inside, pending = {center}, [center]
    while pending:
        for i in neighbors(pending.pop()):
            if i not in inside and pixels[i][3] == 0:
                inside.add(i)
                pending.append(i)
    assert not any(i % width in (0, width - 1) or i // width in (0, height - 1) for i in inside)
    # One pixel underneath the opaque bevel prevents a filtering seam.
    covered = inside | {j for i in inside for j in neighbors(i) if pixels[j][3] == 255}
    mask = [(255, 255, 255, 255 if i in covered else 0) for i in range(len(pixels))]
    bold = [tuple(min(255, round(c * 1.5)) for c in p[:3]) + (p[3],) for p in pixels]
    write_texture('frame', width, height, pixels)
    write_texture('frame-bold', width, height, bold)
    write_texture('mask', width, height, mask)


if __name__ == '__main__':
    generate()
