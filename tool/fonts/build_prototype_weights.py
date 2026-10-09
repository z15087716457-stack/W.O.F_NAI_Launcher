"""Mirror prototype Medium at weights 600/700 without changing its glyphs.

Native Flutter matches intrinsic SFNT weight. Only OS/2.usWeightClass and
checksums change; outlines, metrics, kerning, hints and names remain identical.
The original font and its SIL OFL license remain in assets.
"""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / 'assets/fonts'

def table_entries(data):
    return {data[p:p+4].decode('ascii'): (p, *struct.unpack_from('>II', data, p+8))
            for p in range(12, 12 + 16 * struct.unpack_from('>H', data, 4)[0], 16)}

def checksum(data):
    data = bytes(data) + b'\0' * (-len(data) % 4)
    return sum(struct.unpack('>' + 'I' * (len(data) // 4), data)) & 0xffffffff

def build(weight):
    original = (FONTS / 'GeistMono-Medium.ttf').read_bytes()
    data = bytearray(original)
    tables = table_entries(data)
    _, os_offset, _ = tables['OS/2']
    _, head_offset, _ = tables['head']
    struct.pack_into('>H', data, os_offset + 4, weight)
    struct.pack_into('>I', data, head_offset + 8, 0)
    for entry, offset, length in [tables['OS/2'], tables['head']]:
        struct.pack_into('>I', data, entry + 4, checksum(data[offset:offset+length]))
    struct.pack_into('>I', data, head_offset + 8, (0xb1b0afba - checksum(data)) & 0xffffffff)
    assert checksum(data) == 0xb1b0afba
    for tag, (_, offset, length) in tables.items():
        if tag not in {'OS/2', 'head'}:
            assert data[offset:offset+length] == original[offset:offset+length], tag
    output = FONTS / f'GeistMono-Prototype{weight}.ttf'
    if not output.exists() or output.read_bytes() != data:
        output.write_bytes(data)
    print(output.name, len(data), 'bytes; glyph and metric tables unchanged')

if __name__ == '__main__':
    for weight in (600, 700):
        build(weight)
