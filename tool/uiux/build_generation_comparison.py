"""Build same-scene evidence from original PNGs and recorded screen bounds."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", required=True, type=Path)
    args = parser.parse_args()
    root = args.directory.resolve()
    config = json.loads((root / "comparison-config.json").read_text(encoding="utf-8"))
    output = root / "comparison"
    output.mkdir(exist_ok=True)
    cases = config["cases"]
    regular = ImageFont.truetype("assets/fonts/HarmonyOS_Sans_SC_Regular.ttf", 14)
    bold = ImageFont.truetype("assets/fonts/HarmonyOS_Sans_SC_Bold.ttf", 20)
    for i, case in enumerate(cases):
        cropped = []
        for side in ("prototype", "actual"):
            source = case[side]
            rect = source["rect"]
            x, y = math.floor(rect["x"]), math.floor(rect["y"])
            crop = Image.open(root / source["file"]).convert("RGB").crop(
                (x, y, x + math.ceil(rect["width"]), y + math.ceil(rect["height"])))
            name = f"{i:02}-{side}.png"
            crop.save(output / name)
            case[side + "Image"] = name
            cropped.append(crop)
        size = (max(im.width for im in cropped), max(im.height for im in cropped))
        layers = []
        for im in cropped:
            layer = Image.new("RGB", size, "#111111" if case["dark"] else "#ffffff")
            layer.paste(im, (0, 0))
            layers.append(layer)
        case["overlayImage"] = f"{i:02}-overlay.png"
        Image.blend(*layers, .5).save(output / case["overlayImage"])
        for dimension in ("width", "height"):
            case[dimension + "Delta"] = case["actual"]["rect"][dimension] - case["prototype"]["rect"][dimension]
    height = 90 + sum(max(c["actual"]["rect"]["height"], c["prototype"]["rect"]["height"]) + 65 for c in cases)
    overview = Image.new("RGB", (1080, math.ceil(height)), "#fafafa")
    draw = ImageDraw.Draw(overview)
    draw.text((20, 12), config["title"], font=bold, fill="#171717")
    draw.text((220, 50), "HTML 原型（原尺寸）", font=regular, fill="#171717")
    draw.text((650, 50), "生产组件（原尺寸）", font=regular, fill="#171717")
    y = 90
    for case in cases:
        draw.text((20, y), case["label"], font=regular, fill="#171717")
        for x, field in [(220, "prototypeImage"), (650, "actualImage")]:
            overview.paste(Image.open(output / case[field]), (x, y))
        row_height = math.ceil(max(case["actual"]["rect"]["height"], case["prototype"]["rect"]["height"]))
        draw.text((220, y + row_height + 9), case.get("notes", ""), font=regular, fill="#666666")
        y += row_height + 65
    overview.save(output / "原型与实现对照.png")
    (output / "对照数据.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    rows = "".join(f'''<article><h2>{c["label"]}</h2><div class="pair"><div><p>HTML 原型</p><img src="{c["prototypeImage"]}"></div><div><p>生产组件</p><img src="{c["actualImage"]}"></div><div><p>50% 叠加</p><img src="{c["overlayImage"]}"></div></div><p>{c.get("notes", "")} · 宽差 {c["widthDelta"]:.3f}px，高差 {c["heightDelta"]:.3f}px</p></article>''' for c in cases)
    page = f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>{config["title"]}</title><style>body{{margin:24px;background:#fafafa;color:#171717;font:14px/1.6 Arial,"Microsoft YaHei",sans-serif}}h1{{font-size:24px}}h2{{font-size:16px}}.pair{{display:flex;gap:24px;overflow:auto}}.pair div{{flex:none}}img{{display:block}}article{{padding:16px 0;border-top:1px solid #ccc}}button{{padding:8px 12px}}</style><h1>{config["title"]}</h1><p>相同内容、模型与主题；仅裁取原始截图，不缩放匹配。文字明确的出入附在各场景；仍须独立审查。</p><p><a href="对照数据.json">场景、测量和依据</a> · <a href="原型与实现对照.png">并排总览</a></p><button id="zoom">原尺寸 / 2×</button>{rows}<script>let scale=1;document.querySelector('#zoom').onclick=()=>{{scale=scale===1?2:1;for(const im of document.querySelectorAll('img'))im.style.width=im.naturalWidth*scale+'px';}};</script></html>'''
    (output / "index.html").write_text(page, encoding="utf-8")
    print(json.dumps({"cases": len(cases), "output": str(output)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
