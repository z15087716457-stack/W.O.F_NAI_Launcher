"""原型（去掉 48 主导航）和 Flutter 实绘并排：.dart_tool/ui-shell/gen/pair-<场景>.png。
可选裁剪：python tool/ui_shell/gen_pair.py a 0,0,520,1120  → 只看这块（原尺寸）。"""
import sys
from pathlib import Path
from PIL import Image

D = Path('.dart_tool/ui-shell/gen')
PROTO = Path('../../mockups/generation')
name = sys.argv[1] if len(sys.argv) > 1 else 'a'
box = tuple(int(x) for x in sys.argv[2].split(',')) if len(sys.argv) > 2 else None
p = Image.open(PROTO / f'v_{name.replace("-", "-")}.png').convert('RGB')
p = p.crop((48, 0, p.width, p.height))
f = Image.open(D / 'flutter' / f'{name}.png').convert('RGB')
if box:
    p, f = p.crop(box), f.crop(box)
w = p.width + f.width + 10
out = Image.new('RGB', (w, max(p.height, f.height)), 'red')
out.paste(p, (0, 0))
out.paste(f, (p.width + 10, 0))
if not box and out.width > 1500:
    out = out.resize((1500, int(out.height * 1500 / out.width)))
suffix = '' if not box else '-' + '_'.join(map(str, box))
out.save(D / f'pair-{name}{suffix}.png')
print(D / f'pair-{name}{suffix}.png')
