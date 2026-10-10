"""同一矩形裁原型（去 48px 导航）和实绘，上下叠放。python crop.py name x y w h [out]"""
import sys
from PIL import Image
n, x, y, w, h = sys.argv[1], *map(int, sys.argv[2:6])
out = sys.argv[6] if len(sys.argv) > 6 else f".dart_tool/ui-shell/stats/cmp/crop-{n}.png"
p = Image.open(f"../../mockups/stats/shots/{n}.png").convert("RGB").crop((48 + x, y, 48 + x + w, y + h))
f = Image.open(f".dart_tool/ui-shell/stats/flutter/{n}.png").convert("RGB").crop((x, y, x + w, y + h))
s = Image.new("RGB", (w, h * 2 + 6), (255, 0, 255)); s.paste(p, (0, 0)); s.paste(f, (0, h + 6)); s.save(out)
