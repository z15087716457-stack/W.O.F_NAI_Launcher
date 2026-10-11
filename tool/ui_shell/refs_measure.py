"""批量对齐：用 Edge 无头模式量原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/refs 下跑 python serve.py
  2. flutter test tool/ui_shell/refs_prototype_capture_test.dart
  3. python tool/ui_shell/refs_measure.py [场景...]
原型结果写到 .dart_tool/ui-shell/refs/proto_rects.json。"""
import json, re, subprocess, sys, tempfile, time
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/refs')
# Edge 配置目录必须是绝对路径（相对路径会弹“无法创建数据目录”），放系统临时目录。
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-refs-measure-edge'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
views = sys.argv[1:] or [v for v in flut if not v.endswith('-dark')]


def proto(v):
    for _ in range(3):
        r = subprocess.run([EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={PROFILE}', '--no-first-run',
                            '--no-default-browser-check', '--virtual-time-budget=8000', '--window-size=1700,1200', '--dump-dom',
                            f'http://127.0.0.1:8774/wt/ui-refs/tool/ui_shell/refs_measure.html?t={time.time()}#{v}'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
        m = re.search(r'@@(.*?)@@', r.stdout, re.S)
        if m:
            return json.loads(m.group(1))
    return {}


P = {v: proto(v) for v in views}
(D / 'proto_rects.json').write_text(json.dumps(P, indent=1), encoding='utf-8')
n = 0
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到')
    for k in sorted(p):
        if k not in f:
            print(v, '|', k, '| 缺 Flutter'); n += 1
            continue
        a, b = p[k], f[k]
        d = [round(b[i] - a[i], 1) for i in range(4)]
        if max(abs(x) for x in d) >= 1:
            print(f'{v} | {k} | dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+} | proto {[round(x, 1) for x in a]}'); n += 1
print(f'{n} 处偏差 ≥1px')
