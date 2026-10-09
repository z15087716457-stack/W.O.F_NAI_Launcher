"""Build a local, reversible typography experiment from lossless native GPU snapshots."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
from PIL import Image, ImageChops

src = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--screens', type=Path, default=src / '.dart_tool/typography-coverage-2026-10-10/results')
parser.add_argument('--out', type=Path, default=src.parents[2] / '04_工具/字体覆盖率试验/2026-10-10')
args = parser.parse_args()
args.out.mkdir(parents=True, exist_ok=True)
(args.out / 'fonts').mkdir(exist_ok=True)

font_files = [
    'HarmonyOS_Sans_SC_Regular.ttf', 'HarmonyOS_Sans_SC_Medium.ttf', 'HarmonyOS_Sans_SC_Bold.ttf',
    'Geist-Regular.ttf', 'Geist-Medium.ttf', 'Geist-SemiBold.ttf', 'Geist-Bold.ttf',
    'GeistMono-Regular.ttf', 'GeistMono-Medium.ttf',
]
fonts = {}
for name in font_files:
    path = src / 'assets/fonts' / name
    shutil.copyfile(path, args.out / 'fonts' / name)
    fonts[name] = hashlib.sha256(path.read_bytes()).hexdigest()

report = {'fonts': fonts, 'capture': 'Lossless RepaintBoundary GPU snapshots from a native Windows Impeller process; desktop captures are separate lossy JPEG evidence.', 'themes': {}}
for theme in ['light', 'dark', 'identity']:
    im = Image.open(args.screens / f'{theme}-gpu.png').convert('RGBA')
    assert im.size == (1084, 741), 'Recheck crop geometry for a resized window or different DPR'
    shutil.copyfile(args.screens / f'{theme}-gpu.png', args.out / f'{theme}-gpu.png')
    meta = json.loads((args.screens / f'{theme}-ready.json').read_text(encoding='utf-8'))
    report['themes'][theme] = {'metadata': meta, 'panels': []}
    for i in range(4):
        panel = im.crop((24 + 262 * i, 124, 274 + 262 * i, 690))
        panel.save(args.out / f'{theme}-{i}.png')
        neutral = panel.crop((15, 15, 235, 201)).convert('RGB')
        pixels = list(neutral.get_flattened_data())
        bg, ink = (22, 237) if theme == 'dark' else (250, 23)
        total = sum(max(0, min(1, (sum(p) / 3 - bg) / (ink - bg))) for p in pixels)
        report['themes'][theme]['panels'].append({'neutralCoverage': total, 'rgbFringePixels': sum(max(p) - min(p) > 3 for p in pixels)})
    desktop = args.screens / f'{theme}-native.png'
    if desktop.exists():
        # Computer Use returns JPEG. Preserve its format and identify it honestly.
        shutil.copyfile(desktop, args.out / f'{theme}-desktop.jpg')

light = report['themes']['light']['panels']
for i, panel in enumerate(light):
    panel['gainPercent'] = (panel['neutralCoverage'] / light[0]['neutralCoverage'] - 1) * 100
identity = report['themes']['identity']['panels']
for panel in identity:
    panel['gainPercent'] = (panel['neutralCoverage'] / identity[0]['neutralCoverage'] - 1) * 100
checks = {}
for theme in ['dark', 'skia']:
    im = Image.open(args.screens / f'{theme}-gpu.png').convert('RGBA')
    baseline = im.crop((39, 139, 259, 325))
    checks[theme + 'NeutralTextPixelsIdentical'] = all(
        baseline.tobytes() == im.crop((39 + 262 * i, 139, 259 + 262 * i, 325)).tobytes()
        for i in range(1, 4))
    if theme == 'skia':
        meta = json.loads((args.screens / 'skia-ready.json').read_text(encoding='utf-8'))
        checks['skiaShaderFilterSupported'] = meta['shaderFilterSupported']
im = Image.open(args.screens / 'identity-gpu.png').convert('RGBA')
base = im.crop((39, 139, 259, 325))
checks['identityLayerChangedPixels'] = [
    sum(p != (0, 0, 0, 0) for p in ImageChops.difference(base, im.crop((39 + 262 * i, 139, 259 + 262 * i, 325))).get_flattened_data())
    for i in range(1, 4)]
report['checks'] = checks
report['metric'] = 'Normalized grayscale contrast sum in a fixed neutral text ROI; not measured glyph alpha, font weight, or prototype similarity.'
(args.out / 'verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')

html = r'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>浅色字体字缘补偿试验</title><style>
@font-face{font-family:HOS;src:url(fonts/HarmonyOS_Sans_SC_Regular.ttf);font-weight:400}
@font-face{font-family:HOS;src:url(fonts/HarmonyOS_Sans_SC_Medium.ttf);font-weight:500}
@font-face{font-family:HOS;src:url(fonts/HarmonyOS_Sans_SC_Bold.ttf);font-weight:600 700}
@font-face{font-family:Geist;src:url(fonts/Geist-Regular.ttf);font-weight:400}
@font-face{font-family:Geist;src:url(fonts/Geist-Medium.ttf);font-weight:500}
@font-face{font-family:Geist;src:url(fonts/Geist-SemiBold.ttf);font-weight:600}
@font-face{font-family:Geist;src:url(fonts/Geist-Bold.ttf);font-weight:700}
@font-face{font-family:Mono;src:url(fonts/GeistMono-Regular.ttf);font-weight:400}
@font-face{font-family:Mono;src:url(fonts/GeistMono-Medium.ttf);font-weight:500 700}
:root{--page:#eee;--panel:#fafafa;--ink:#171717;--muted:#666;--faint:#8f8f8f;--border:#e6e6e6;--heart:#e5484d;--violet:#6e56cf;--blue:#0064e2}
body.dark{--page:#111;--panel:#161616;--ink:#ededed;--muted:#a1a1a1;--faint:#7a7a7a;--border:#2e2e2e;--heart:#ff6369;--violet:#9e8cfc;--blue:#50a8ff}
*{box-sizing:border-box}body{margin:0;background:var(--page);color:var(--ink);font:13px/1.45 HOS,sans-serif;-webkit-font-smoothing:antialiased}
main{max-width:1100px;margin:auto;padding:24px}h1{font-size:20px;margin:0 0 8px;font-weight:600}p{margin:6px 0;color:var(--muted)}
.toolbar{display:flex;gap:8px;flex-wrap:wrap;margin:18px 0;align-items:center}.toolbar span{color:var(--muted);margin-right:4px}button{font:500 13px HOS;padding:7px 12px;border:1px solid var(--border);border-radius:7px;background:var(--panel);color:var(--ink);cursor:pointer}button[aria-pressed=true]{border-color:var(--blue);color:var(--blue)}
.stage{overflow:auto;padding-bottom:10px}.triptych{display:flex;gap:14px;width:max-content}.col{width:250px;flex:none}.heading{height:31px;font-size:13px;font-weight:500}.card{width:250px;height:566px;border:1px solid var(--border);border-radius:8px;background:var(--panel);padding:14px;overflow:hidden}
.line{font-size:12px;line-height:1.45;white-space:pre;height:17.4px}.hos{font-size:13px;height:18.85px}.latin{font-family:Geist}.mono{font-family:Mono,HOS,monospace}.pair{margin-bottom:7px}.muted{color:var(--muted)}.faint{color:var(--faint);font-size:11px;height:15.95px}.heart{color:var(--heart)}.violet{color:var(--violet)}.blue{color:var(--blue)}.action{font-size:12.5px;font-weight:500;height:18.125px}.gap12{height:12px}.gap10{height:10px}.gap8{height:8px}.gap6{height:6px}.gap3{height:3px}.divider{height:1px;background:var(--border)}.group{display:flex;font-size:12px;height:17.4px;align-items:center;white-space:pre}.kv{display:flex;font-size:12px;height:17.4px}.kv .label{width:36px;flex:none}.rich{font-size:12px;height:17.4px}.field{font:12px/1.45 HOS;background:transparent;border:0;padding:0;width:100%;height:32px;display:block;outline:0;color:var(--ink)}
.native{display:block;width:250px;height:566px;max-width:none}.caption{font-size:12px;color:var(--muted);margin-top:8px;max-width:250px}.notes{margin:16px 0;border-top:1px solid var(--border);padding-top:12px}a{color:var(--blue)}details{margin-top:14px}details img{display:block;max-width:100%;height:auto;margin-top:8px}.evidence{font-size:12px}
</style><main><h1>浅色字体字缘补偿试验</h1><p>左侧按原型字体设置实时绘制；中间和右侧来自 Windows Flutter 3.47.7 / Impeller 原生进程的无损 GPU 图。</p><p>字体文件、字号、字重、行高和字距一致。这里只比较字体样例，尚未应用到整个启动器。</p>
<div class="toolbar" id="themes"><span>主题</span><button data-theme="light" aria-pressed="true">浅色</button><button data-theme="dark" aria-pressed="false">深色</button></div>
<div class="toolbar" id="strengths"><span>补偿</span><button data-level="1" aria-pressed="false">轻微 · 0.90</button><button data-level="2" aria-pressed="true">中等 · 0.80</button><button data-level="3" aria-pressed="false">较强 · 0.70</button><button data-level="0" aria-pressed="false">关闭 / 退回原始</button></div>
<div class="toolbar" id="zooms"><span>倍率</span><button data-zoom="1" aria-pressed="true">1:1</button><button data-zoom="2" aria-pressed="false">2 倍</button><button data-zoom="3" aria-pressed="false">3 倍</button></div>
<div class="stage"><div class="triptych" id="comparison"><section class="col"><div class="heading">浏览器原型字体样例</div><div class="card" id="reference"></div><div class="caption">原型同一组字体与文字颜色。浏览器实际渲染，可观察字缘。</div></section><section class="col"><div class="heading">Impeller 原始</div><img class="native" id="original" alt="原始 Impeller 字体"><div class="caption">基线：不使用额外文字滤镜。</div></section><section class="col"><div class="heading" id="correctedTitle"></div><img class="native" id="corrected" alt="字缘覆盖率补偿字体"><div class="caption" id="gain"></div></section></div></div>
<div class="notes"><p id="state"></p><p>优先看 400 字重正文、浅灰说明、种子数字和彩色操作文字。字号和字重不随补偿改变。</p><p>系统 DPR 1、实际窗口客户区 1084 × 741。尚未验证其他系统 DPI。请以 1:1 判断观感；放大时浏览器文字会重新绘制，不是原始像素的同倍率比较。</p><p>输入框仅为独立控件试验；选择高亮与混合透明文字需要单独处理，不能直接给整页套滤镜。</p></div>
<details><summary>运行证据与恒等滤镜检查</summary><p class="evidence">无损图是原生进程 RepaintBoundary GPU 快照；下面的桌面窗口图由 computer-use 采集，原始格式为 JPEG，不用于精确像素统计。</p><a href="verification.json">验证数据与字体哈希</a> · <a href="identity-gpu.png">强度为 1 的滤镜</a><img id="nativeWindow" alt="实际 Windows 原生窗口"><p class="evidence">可退回原始：上方选择“关闭 / 退回原始”。生产界面、字体和 Flutter 引擎未改动。</p></details>
</main><script>
const stats = __STATS__;
let theme='light', level=2, zoom=1;
const weights=[400,500,600,700];
reference.innerHTML=weights.map(w=>`<div class="pair" style="font-weight:${w}"><div class="line hos">本地画廊　画风探索　${w}</div><div class="line latin">NovelAI Studio 3274348526</div></div>`).join('')+`<div class="line mono">832×1216 · 28 步 · 5.0</div><div class="gap12"></div><div class="divider"></div><div class="gap12"></div><div class="line action heart">已收藏</div><div class="gap3"></div><div class="line action violet">加入进化　套用到编辑区</div><div class="gap12"></div><div class="line muted">分组</div><div class="line faint">按 1–9 快速归组</div><div class="gap6"></div><div class="group"><span>✓ </span><span class="blue" style="font-weight:600">冷色调</span><span class="muted">　厚涂　＋ 新分组</span></div><div class="gap12"></div>`+[['种子','3274348526'],['耗时','14.8 s'],['参数','832×1216 · 28 · 5.0']].map(p=>`<div class="kv"><span class="label muted">${p[0]}</span><span class="mono">${p[1]}</span></div>`).join('')+`<div class="gap10"></div><div class="rich"><span class="muted">富文本 </span><span class="blue">冷色调 </span><span class="mono">14.8 s</span></div><div class="gap8"></div><div class="line" style="opacity:.6">外层透明度 60% 保持</div><div class="gap10"></div><div class="line faint">编辑控件：仅试验文字和光标</div><input class="field" readonly value="套用到编辑区">`;
function render(){document.body.classList.toggle('dark',theme==='dark');document.querySelectorAll('[data-theme]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.theme===theme)));document.querySelectorAll('[data-level]').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.level)===level)));document.querySelectorAll('[data-zoom]').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.zoom)===zoom)));original.src=`${theme}-0.png`;corrected.src=`${theme}-${level}.png`;nativeWindow.src=`${theme}-desktop.jpg`;correctedTitle.textContent=theme==='dark'?'深色：保持原始':level===0?'已关闭补偿':['','轻微补偿 · γ=0.90','中等补偿 · γ=0.80','较强补偿 · γ=0.70'][level];gain.textContent=theme==='dark'?'深色直接绕过滤镜。':`中性文字区域的覆盖量变化约 +${stats.themes.light.panels[level].gainPercent.toFixed(1)}%。这个数值不代表与原型的吻合度。`;state.textContent=theme==='dark'?'深色保留现在的观感，所有强度均回到原始文字。':level===0?'已退回原始 Impeller 字体，额外补偿关闭。':'浅色只改变半透明字缘的覆盖率，背景、边框和图标不进入文字滤镜。';comparison.style.zoom=String(zoom)}
themes.addEventListener('click',e=>{if(e.target.dataset.theme){theme=e.target.dataset.theme;render()}});strengths.addEventListener('click',e=>{if(e.target.dataset.level!==undefined){level=Number(e.target.dataset.level);render()}});zooms.addEventListener('click',e=>{if(e.target.dataset.zoom){zoom=Number(e.target.dataset.zoom);render()}});render();
</script></html>'''
html = html.replace('__STATS__', json.dumps(report, ensure_ascii=False))
(args.out / 'index.html').write_text(html, encoding='utf-8')
print(json.dumps({'output': str(args.out), 'lightGains': [round(x['gainPercent'], 3) for x in light], 'identityGains': [round(x['gainPercent'], 3) for x in identity]}, ensure_ascii=False))
