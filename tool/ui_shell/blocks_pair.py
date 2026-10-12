"""原型 / Flutter 对照拼图：python tool/ui_shell/blocks_pair.py 场景 [x y w h]
先跑 blocks_shot.py（原型截图）、blocks_prototype_capture_test.dart（实绘 + rects.json）、blocks_measure.py（原型 rects）。
管理页去掉原型的 48 主导航后上下拼；浮层按各自根元素裁出来左右拼（各留 12 边）。可选再裁一块（坐标相对裁出的图）。
输出 .dart_tool/ui-shell/blocks/pair_场景.png。"""
import json, sys
from pathlib import Path
from PIL import Image
D = Path('.dart_tool/ui-shell/blocks')
HASH = {'lib': 'a-lib', 'sel': 'a-sel', 'dock': 'a'}
name = sys.argv[1]
box = tuple(map(int, sys.argv[2:6])) if len(sys.argv) >= 6 else None
p = Image.open(D / 'proto' / f'{HASH.get(name, name)}.png').convert('RGB')
f = Image.open(D / 'flutter' / f'{name}.png').convert('RGB')
pr = json.loads((D / 'proto_rects.json').read_text(encoding='utf-8')).get(name, {}).get('@root')
fr = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8')).get(name, {}).get('@root')
if pr and fr:
    w, h = max(pr[2], fr[2]) + 24, max(pr[3], fr[3]) + 24
    p = p.crop((int(pr[0]) - 12, int(pr[1]) - 12, int(pr[0] - 12 + w), int(pr[1] - 12 + h)))
    f = f.crop((int(fr[0]) - 12, int(fr[1]) - 12, int(fr[0] - 12 + w), int(fr[1] - 12 + h)))
else:
    p = p.crop((48, 0, p.width, p.height))
if box:
    x, y, w, h = box
    p, f = p.crop((x, y, x + w, y + h)), f.crop((x, y, x + w, y + h))
side = p.width < 700
sheet = Image.new('RGB', (p.width + f.width + 6, max(p.height, f.height)) if side else
                  (max(p.width, f.width), p.height + f.height + 6), (255, 0, 255))
sheet.paste(p, (0, 0)); sheet.paste(f, (p.width + 6, 0) if side else (0, p.height + 6))
suffix = '' if not box else '_' + '_'.join(sys.argv[2:6])
sheet.save(D / f'pair_{name}{suffix}.png')
print(D / f'pair_{name}{suffix}.png')
