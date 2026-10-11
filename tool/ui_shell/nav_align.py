"""批量对齐第二步（看内容）：拿原型已有截图 shots/*.png 和 Flutter 实绘，按 Flutter 的元素框逐个做位移搜索，
找出每个元素和原型差几像素。用法：python nav_align.py [场景...]"""
import json, sys
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
P=Path('../../mockups/nav/shots'); F=Path('.dart_tool/ui-shell/nav/flutter')
rects=json.loads((F/'rects.json').read_text(encoding='utf-8'))
R=4
out=[]
for v in sys.argv[1:] or rects:
    if not (P/f'{v}.png').exists(): continue
    a=Image.open(P/f'{v}.png').convert('L'); b=Image.open(F/f'{v}.png').convert('L')
    for k,(x,y,w,h) in sorted(rects[v].items()):
        x0,y0,x1,y1=int(round(x)),int(round(y)),int(round(x+w)),int(round(y+h))
        if w<8 or h<8 or x0<R or y0<R or x1+R>1600 or y1+R>1000: continue
        fb=b.crop((x0,y0,x1,y1))
        if ImageStat.Stat(fb).stddev[0]<3: continue
        def diff(dx,dy): return ImageStat.Stat(ImageChops.difference(a.crop((x0+dx,y0+dy,x1+dx,y1+dy)),fb)).mean[0]
        best=min(((diff(dx,dy),dx,dy) for dy in range(-R,R+1) for dx in range(-R,R+1)))
        d0=diff(0,0); d,dx,dy=best
        if (dx or dy) and d0-d>0.4: out.append(f'{v:12} {k:18} 原型在 dx {dx:+d} dy {dy:+d}  差 {d0:.1f}→{d:.1f}')
        elif d>10: out.append(f'{v:12} {k:18} 位置对、内容差 {d:.1f}')
print('\n'.join(out)); print(len(out),'项')
