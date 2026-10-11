"""原型 / Flutter 上下拼图（同尺寸 1600 × 1000），可选裁一块区域：
python tool/ui_shell/refs_pair.py 场景 [x y w h]，输出 .dart_tool/ui-shell/refs/pair_场景.png。"""
import sys
from pathlib import Path
from PIL import Image
D = Path('.dart_tool/ui-shell/refs')
name = sys.argv[1]
box = tuple(map(int, sys.argv[2:6])) if len(sys.argv) >= 6 else None
p = Image.open(D / 'proto' / f'{name}.png').convert('RGB')
f = Image.open(D / 'flutter' / f'{name}.png').convert('RGB')
if box:
    x, y, w, h = box
    p, f = p.crop((x, y, x + w, y + h)), f.crop((x, y, x + w, y + h))
sheet = Image.new('RGB', (max(p.width, f.width), p.height + f.height + 6), (255, 0, 255))
sheet.paste(p, (0, 0)); sheet.paste(f, (0, p.height + 6))
suffix = '' if not box else '_' + '_'.join(sys.argv[2:6])
sheet.save(D / f'pair_{name}{suffix}.png')
print(D / f'pair_{name}{suffix}.png')
