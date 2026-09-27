"""Build StudioIcons.ttf from the reviewed SVG masters (no runtime tooling).

python -m pip install fonttools==4.66.0 skia-pathops==0.9.2
python tool/branding/generate_studio_icons.py
"""
from pathlib import Path
import xml.etree.ElementTree as ET

import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path

ROOT = Path(__file__).resolve().parents[2]
MASTERS = Path(__file__).with_name('studio_icons')
# Stable codepoints: append, never reorder.
NAMES = ['style_explore', 'inherit', 'online_gallery', 'prompt_blocks',
         'precise_reference', 'vibe_library']


def glyph(svg):
    root = ET.parse(svg).getroot()
    outlines = pathops.Path()
    for element in root:
        assert element.tag.endswith('path'), 'Masters must use path elements'
        path = pathops.Path()
        parse_path(element.attrib['d'], path.getPen())
        if element.get('stroke', root.get('stroke')) != 'none':
            path.stroke(float(element.get('stroke-width', root.get('stroke-width'))),
                        pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
        path.convertConicsToQuads(0.01)
        outlines = pathops.op(outlines, path, pathops.PathOp.UNION)
    pen = TTGlyphPen(None)
    # 24px design grid -> 1024 units, with a 128-unit font descent.
    outlines.draw(TransformPen(Cu2QuPen(pen, 0.5, reverse_direction=True),
                               (1024 / 24, 0, 0, -1024 / 24, 0, 896)))
    return pen.glyph()


def main():
    font = FontBuilder(1024, isTTF=True)
    order = ['.notdef', *NAMES]
    font.setupGlyphOrder(order)
    font.setupCharacterMap({0xe900 + i: name for i, name in enumerate(NAMES)})
    glyphs = {'.notdef': TTGlyphPen(None).glyph()}
    glyphs.update({name: glyph(MASTERS / f'{name}.svg') for name in NAMES})
    font.setupGlyf(glyphs)
    font.setupHorizontalMetrics({name: (1024, getattr(g, 'xMin', 0))
                                 for name, g in glyphs.items()})
    font.setupHorizontalHeader(ascent=896, descent=-128, lineGap=0)
    font.setupNameTable({'familyName': 'StudioIcons', 'styleName': 'Regular',
                        'uniqueFontIdentifier': 'WOF-StudioIcons-1',
                        'fullName': 'StudioIcons', 'psName': 'StudioIcons',
                        'version': 'Version 1.000'})
    font.setupOS2(sTypoAscender=896, sTypoDescender=-128, sTypoLineGap=0,
                  usWinAscent=896, usWinDescent=128)
    font.setupPost()
    font.setupMaxp()
    font.font.recalcTimestamp = False
    font.font['head'].created = font.font['head'].modified = 3800000000
    target = ROOT / 'assets/fonts/StudioIcons.ttf'
    font.save(target)
    # Existing SVG consumers share precisely the same shapes as IconData users.
    for master, asset in [('precise_reference', 'precise-reference'),
                          ('vibe_library', 'vibe-transfer')]:
        (ROOT / f'assets/icons/nai-icon-{asset}.svg').write_bytes(
            (MASTERS / f'{master}.svg').read_bytes())
    print(f'Built {len(NAMES)} glyphs: {target} ({target.stat().st_size} bytes)')


if __name__ == '__main__':
    main()
