"""批量对齐：Edge 无头量原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/tools 下跑 python serve.py（8785）
  2. flutter test tool/ui_shell/tools_prototype_capture_test.dart
  3. python tool/ui_shell/tools_measure.py [场景...]

先减掉有意改动，再列残差：
- 生图画布上的面板：原型的生图页是示意（左栏 372、历史 188、焦点图位置不同），只比工具条以下的相对位置——
  两边都换成“以焦点图水平中心、工具条顶边为原点”的坐标。Flutter 的工具条居中在图上；原型的工具条
  是手摆的（图中心 −214 起），所以 bar-top / tb-enhance 的 dx 是原型手摆的偏移，不算偏差。
- 编辑器 / 导演工具：顶栏 61（原型 52，和各页顶栏同高），顶栏下面的东西整体下移 9；
  撑满高度的栏（工具栏、画布、右栏、舞台……）同时矮 9；贴底的（状态栏、结果操作、输入队列）不动；
  画布居中的图下移 4.5。"""
import json, re, subprocess, sys, tempfile, time
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/tools')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-tools-measure-edge'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
views = sys.argv[1:] or list(flut)
TOP = 9  # 61 − 52

STRETCH = {'ed-rail', 'ed-work', 'ed-side', 'ed-layers', 'dt-tools', 'dt-stage', 'dt-side', 'dt-results', 'dt-area',
           'dt-orig', 'dt-res', 'dt-wipe'}
BOTTOM = {'ed-stat', 'dt-acts', 'dt-queue', 'dt-init', 'dt-q-0', 'dt-q-add', 'ed-note', 'ed-canvas', 'ed-adjust'}
CENTER = {'ed-img'}
RIGHT = {'ed-zoom', 'ed-apply', 'ed-cancel', 'apply-menu'}  # 顶栏里居中的，跟着顶栏中线下移 4.5
TOPBAR = {'ed-top', 'dt-top'}
SKIP = {'ed-title', 'e-switch'}  # Flutter 标题撑满剩余宽度、开关行只有内容宽；原型都是整行块


def proto(v):
    for _ in range(3):
        r = subprocess.run([EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={PROFILE}', '--no-first-run',
                            '--no-default-browser-check', '--virtual-time-budget=8000', '--window-size=1700,1200', '--dump-dom',
                            f'http://127.0.0.1:8785/wt/ui-tools/tool/ui_shell/tools_measure.html?t={time.time()}#{v}'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
        m = re.search(r'@@(.*?)@@', r.stdout, re.S)
        if m:
            return json.loads(m.group(1))
    return {}


def gen_frame(rects, proto):
    """以焦点图水平中心、工具条顶边为原点（原型：图中心 = 工具条左边 + 214）。"""
    b = rects.get('bar-top')
    if not b:
        return rects
    cx, ty = (b[0] + 214 if proto else b[0] + b[2] / 2), b[1]
    return {k: [r[0] - cx, r[1] - ty, r[2], r[3]] for k, r in rects.items()}


def page_adjust(k, r):
    x, y, w, h = r
    if k in TOPBAR:
        return [x, y, w, h + TOP]
    if k in RIGHT:
        return [x, y + TOP / 2, w, h]
    if k in BOTTOM:
        return [x, y, w, h]
    if k in CENTER:
        return [x, y + TOP / 2, w, h]
    if k in STRETCH:
        return [x, y + TOP, w, h - TOP]
    return [x, y + TOP, w, h]


CACHE = D / 'proto_rects.json'
if '--reuse' in sys.argv and CACHE.exists():  # 原型没变时直接用上次量的
    views = [v for v in views if v != '--reuse'] or list(flut)
    P = json.loads(CACHE.read_text(encoding='utf-8'))
else:
    P = {v: proto(v) for v in views}
    CACHE.write_text(json.dumps(P, indent=1), encoding='utf-8')
n = 0
worst = (0, '')
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到')
        continue
    if v.startswith(('enhance', 'upscale', 'uprun', 'bar')):
        p, f = gen_frame(p, True), gen_frame(f, False)
    else:
        p = {k: page_adjust(k, r) for k, r in p.items()}
    for k in sorted((set(p) | set(f)) - SKIP):
        if k not in f or k not in p:
            print(v, '|', k, '| 只有', '原型' if k in p else 'Flutter')
            continue
        a, b = p[k], f[k]
        d = [round(b[i] - a[i], 1) for i in range(4)]
        mx = max(abs(x) for x in d)
        if mx >= 1:
            print(f'{v} | {k} | dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+} | proto {[round(x, 1) for x in a]}'); n += 1
            if mx > worst[0]:
                worst = (mx, f'{v}/{k}')
print(f'{n} 处偏差 ≥1px，最大 {worst[0]}（{worst[1]}）')
