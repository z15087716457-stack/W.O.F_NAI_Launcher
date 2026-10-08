"""Compose original-size HTML/production-widget evidence without repainting it."""

import argparse
import json
import math
from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFont


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--materials", required=True, type=Path)
    args = parser.parse_args()
    materials = args.materials.resolve()
    evidence = Path(".dart_tool/uiux-checkpoint01")
    prototype = materials / "原型"
    implementation = materials / "实现"
    implementation.mkdir(exist_ok=True)
    (materials / "叠加").mkdir(exist_ok=True)
    pills = load(evidence / "prototype-pill-cases.json")
    actual_pills = load(evidence / "same-scene-measurements.json")
    generations = load(evidence / "prototype-generation-cases.json")
    actual_generations = load(evidence / "same-scene-generation-measurements.json")
    pairs = []
    pill_source = Image.open(prototype / "blocks-pills-live.png").convert("RGB")
    for case in (c for c in pills if c["index"] < 29):
        name = f"pill-{case['theme']}-{case['index']:02}"
        actual = next(c for c in actual_pills if c["name"] == name)
        rect = case["rect"]
        x, y = math.floor(rect["x"]) - 4, math.floor(rect["y"]) - 4
        crop = pill_source.crop((x, y, x + math.ceil(rect["width"]) + 8,
                                y + math.ceil(rect["height"]) + 8))
        ref_path = prototype / "药丸" / f"{name}.png"
        crop.save(ref_path)
        image = Image.open(evidence / "same-scene-captures" / f"{name}.png").convert("RGB")
        ax, ay = math.floor(actual["x"]) - 4, math.floor(actual["y"]) - 4
        image.crop((ax, ay, ax + math.ceil(actual["flutterWidth"]) + 8,
                    ay + math.ceil(actual["flutterHeight"]) + 8)).save(implementation / f"{name}.png")
        pairs.append({"name": name, "theme": case["theme"], "kind": "pill",
                      "label": case["label"] or case["title"],
                      "prototype": ref_path.relative_to(materials).as_posix(),
                      "actual": f"实现/{name}.png", "widthDelta": actual["flutterWidth"] - rect["width"],
                      "heightDelta": actual["flutterHeight"] - rect["height"]})
    labels = {"header-character": "角色模块标题", "header-reference": "参考图模块标题",
              "header-image": "图像模块标题", "position": "标题行定位轨道",
              "orientation": "方向轨道", "count": "张数轨道"}
    for case in generations:
        name = f"generation-{case['theme']}-{case['name']}"
        actual = next(c for c in actual_generations if c["name"] == name)
        variant = "a-dark" if case["theme"] == "dark" else "a"
        source = Image.open(prototype / f"generation-{variant}-live.png").convert("RGB")
        rect = case["rect"]
        x, y = math.floor(rect["x"]), math.floor(rect["y"])
        ref_path = prototype / "模块" / f"{name}.png"
        source.crop((x, y, x + math.ceil(rect["width"]), y + math.ceil(rect["height"]))).save(ref_path)
        image = Image.open(evidence / "same-scene-captures" / f"{name}.png").convert("RGB")
        ax, ay = math.floor(actual["x"]), math.floor(actual["y"])
        image.crop((ax, ay, ax + math.ceil(actual["width"]), ay + math.ceil(actual["height"]))).save(
            implementation / f"{name}.png")
        pairs.append({"name": name, "theme": case["theme"], "kind": "generation",
                      "label": labels[case["name"]], "prototype": ref_path.relative_to(materials).as_posix(),
                      "actual": f"实现/{name}.png", "widthDelta": actual["width"] - rect["width"],
                      "heightDelta": actual["height"] - rect["height"]})
    regular = ImageFont.truetype("assets/fonts/HarmonyOS_Sans_SC_Regular.ttf", 13)
    bold = ImageFont.truetype("assets/fonts/HarmonyOS_Sans_SC_Bold.ttf", 20)
    for theme in ("light", "dark"):
        for kind in ("pill", "generation"):
            rows = [p for p in pairs if p["theme"] == theme and p["kind"] == kind]
            dark = theme == "dark"
            row_height = 48 if kind == "pill" else 66
            width = 790 if kind == "pill" else 1060
            title = f"{'深色' if dark else '浅色'} · {'药丸逐项' if kind == 'pill' else '模块与轨道'}对照"
            image = Image.new("RGB", (width, 96 + len(rows) * row_height), "#111111" if dark else "#ffffff")
            draw = ImageDraw.Draw(image)
            ink = "#ededed" if dark else "#171717"
            draw.text((18, 12), title, font=bold, fill=ink)
            draw.text((18, 45), "生产组件 / 相同中文内容、主题与状态 / 原尺寸裁图，无拉伸", font=regular, fill=ink)
            left, right = 172, width // 2 + 90
            draw.text((left, 70), "HTML 原型", font=regular, fill=ink)
            draw.text((right, 70), "Flutter 实现", font=regular, fill=ink)
            for i, pair in enumerate(rows):
                y = 96 + i * row_height
                draw.text((18, y + 4), pair["label"], font=regular, fill=ink)
                for x, path in ((left, pair["prototype"]), (right, pair["actual"])):
                    crop = Image.open(materials / path).convert("RGB")
                    image.paste(crop, (x, y))
                draw.line((18, y + row_height - 4, width - 18, y + row_height - 4), fill="#333333" if dark else "#eeeeee")
            image.save(materials / f"{'深色' if dark else '浅色'}-{'药丸逐项' if kind == 'pill' else '模块与轨道'}对照.png")
    for pair in pairs:
        ref = Image.open(materials / pair["prototype"]).convert("RGBA")
        actual = Image.open(materials / pair["actual"]).convert("RGBA")
        size = (max(ref.width, actual.width), max(ref.height, actual.height))
        a, b = Image.new("RGBA", size), Image.new("RGBA", size)
        a.paste(ref, (0, 0)); b.paste(actual, (0, 0))
        Image.blend(a, b, .5).save(materials / "叠加" / f"{pair['name']}.png")
        pair["overlay"] = f"叠加/{pair['name']}.png"
    (materials / "同场景对照数据.json").write_text(json.dumps(pairs, ensure_ascii=False, indent=2), encoding="utf-8")
    for name in ("prototype-pill-cases.json", "prototype-generation-cases.json",
                 "same-scene-measurements.json", "same-scene-generation-measurements.json"):
        shutil.copy2(evidence / name, materials / name)
    data = json.dumps(pairs, ensure_ascii=False).replace("</", "<\\/")
    page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>检查点① · 原型对照</title>
<style>body{margin:0;background:#fafafa;color:#171717;font:14px/1.6 Arial,"Microsoft YaHei",sans-serif}main{padding:24px;max-width:1320px;margin:auto}h1{font-size:24px}button,select{font:inherit;padding:7px 12px;border:1px solid #ccc;background:white;border-radius:6px;cursor:pointer}label{margin-right:12px}.controls{position:sticky;top:0;background:#fafafa;padding:12px 0;z-index:1}.row{display:grid;grid-template-columns:160px 1fr 1fr;gap:12px;border-bottom:1px solid #ddd;padding:16px 0}.pictures{overflow:auto;min-height:42px}img{display:block;max-width:none}small{color:#666}a{color:#0064e2}details{margin:16px 0}.dark .row{background:#111;color:#ededed;border-color:#333;padding:16px}.dark .row small{color:#a1a1a1}</style>
<main><h1>检查点① · 完整原型与生产组件对照</h1><p>原型来源：完整 index / mock 与配套材料。当前只验收共用模块和药丸，整页套用仍按施工总图推进。这里提供相同中文内容、主题与状态的70组对照；尺寸测量与截图不能代替独立审查。</p>
<p><a href="差异与验证.md">差异和任务文字依据</a> · <a href="原型入口核对.json">九页原型入口</a> · <a href="同场景对照数据.json">场景与尺寸数据</a></p>
<div class="controls"><label>主题 <select id="theme"><option value="light">浅色</option><option value="dark">深色</option></select></label><label>组件 <select id="kind"><option value="all">全部</option><option value="generation">模块与轨道</option><option value="pill">药丸</option></select></label><label>相同比例缩放 <select id="zoom"><option value="1">原尺寸 1×</option><option value="2">2×</option><option value="4">4×</option></select></label><label><input id="overlay" type="checkbox">显示50%叠加</label></div>
<div class="row"><b>场景</b><b>HTML 原型</b><b>Flutter 实现 / 叠加</b></div><section id="rows"></section>
<details><summary>原型全图（整页背景供定位；当前阶段不宣称整页完成）</summary><a href="原型/blocks-pills-live.png">药丸规范</a> · <a href="原型/generation-a-live.png">V5 浅色</a> · <a href="原型/generation-a-dark-live.png">V5 深色</a> · <a href="原型/generation-a-v45-live.png">V4.5 浅色</a> · <a href="原型/generation-a-v45-dark-live.png">V4.5 深色</a></details>
<p>截图为浏览器原型与真实字体 widget 渲染，均保留原始PNG。布局不靠拉伸截图匹配；2× / 4×仅用于查看。字体抗锯齿、亚像素位置及材料明确指定的出入见差异记录。</p></main>
<script>const data=DATA;const theme=document.getElementById('theme'),kind=document.getElementById('kind'),zoom=document.getElementById('zoom'),overlay=document.getElementById('overlay'),rows=document.getElementById('rows');const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));function render(){rows.className=theme.value==='dark'?'dark':'';rows.innerHTML=data.filter(p=>p.theme===theme.value&&(kind.value==='all'||p.kind===kind.value)).map(p=>`<div class="row"><div>${esc(p.label)}<br><small>宽差 ${p.widthDelta.toFixed(3)}px<br>高差 ${p.heightDelta.toFixed(3)}px</small></div><div class="pictures"><img src="${p.prototype}" alt="${esc(p.label)} 原型"></div><div class="pictures"><img src="${overlay.checked?p.overlay:p.actual}" alt="${esc(p.label)} 实现"></div></div>`).join('');for(const im of rows.querySelectorAll('img'))im.onload=()=>{im.style.width=im.naturalWidth*Number(zoom.value)+'px';};}for(const control of [theme,kind,zoom,overlay])control.addEventListener('change',render);render();</script></html>'''
    (materials / "index.html").write_text(page.replace("DATA", data), encoding="utf-8")
    print(json.dumps({"pairs": len(pairs), "pills": len(actual_pills),
                      "modulesAndTracks": len(actual_generations)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
