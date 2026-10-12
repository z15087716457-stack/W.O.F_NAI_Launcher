"""批量对齐：Edge 无头量原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/blocks 下跑 python serve.py（8773）
  2. flutter test tool/ui_shell/blocks_prototype_capture_test.dart
  3. python tool/ui_shell/blocks_measure.py [场景...]
管理页按页面原点（去掉 48 主导航）比；侧栏、实例卡、规则、弹窗按各自根元素左上角比；键名带 ~ 的只比尺寸。
有意改动（左栏 232→240、顶栏 52→61、详情 360→340）会整体带出位移，见接线说明。"""
import json, re, subprocess, sys, tempfile, time
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/blocks')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-blocks-measure-edge'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
views = sys.argv[1:] or list(flut)


def proto(v):
    for _ in range(3):
        r = subprocess.run([EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={PROFILE}', '--no-first-run',
                            '--no-default-browser-check', '--virtual-time-budget=8000', '--window-size=1700,1200', '--dump-dom',
                            f'http://127.0.0.1:8773/wt/ui-blocks/tool/ui_shell/blocks_measure.html?t={time.time()}#{v}'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
        m = re.search(r'@@(.*?)@@', r.stdout, re.S)
        if m:
            return json.loads(m.group(1))
    return {}


P = {v: proto(v) for v in views}
(D / 'proto_rects.json').write_text(json.dumps(P, indent=1, ensure_ascii=False), encoding='utf-8')
n = 0
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到')
    for k in sorted(k for k in p if not k.startswith('@')):
        if k not in f:
            print(v, '|', k, '| 缺 Flutter')
            continue
        a, b = p[k], f[k]
        d = [round(b[i] - a[i], 1) for i in range(4)]
        if k.startswith('~'):
            d[0] = d[1] = 0
        if max(abs(x) for x in d) >= 1:
            print(f'{v} | {k} | dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+} | proto {[round(x, 1) for x in a]}'); n += 1
print(f'{n} 处偏差 ≥1px')
