"""并排对照：原型截图（裁掉 48px 主导航）| Flutter 实绘 | 差异。
用法：python tool/ui_shell/compare.py <原型 shots 目录> <flutter 目录> <输出目录> [名字...]
"""
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageOps

proto, flut, out = map(Path, sys.argv[1:4])
out.mkdir(parents=True, exist_ok=True)
names = sys.argv[4:] or sorted(p.stem for p in flut.glob("*.png"))
for n in names:
    f = flut / f"{n}.png"
    p = proto / f"{n}.png"
    if not f.exists():
        continue
    fi = Image.open(f).convert("RGB")
    if not p.exists():
        continue
    pi = Image.open(p).convert("RGB")
    pi = pi.crop((48, 0, pi.width, pi.height))
    h = max(pi.height, fi.height)
    w = max(pi.width, fi.width)
    def pad(im):
        c = Image.new("RGB", (w, h), im.getpixel((im.width - 2, im.height - 2)))
        c.paste(im, (0, 0))
        return c
    a, b = pad(pi), pad(fi)
    d = ImageOps.autocontrast(ImageChops.difference(a, b).convert("L"))
    sheet = Image.new("RGB", (w * 3 + 20, h), (255, 0, 255))
    sheet.paste(a, (0, 0)); sheet.paste(b, (w + 10, 0)); sheet.paste(d.convert("RGB"), (2 * w + 20, 0))
    sheet.save(out / f"{n}.png")
    diff = ImageChops.difference(a, b).convert("L")
    mean = sum(i * c for i, c in enumerate(diff.histogram())) / (w * h)
    print(f"{n}: proto {pi.size} flutter {fi.size} meanDiff {mean:.2f}")
