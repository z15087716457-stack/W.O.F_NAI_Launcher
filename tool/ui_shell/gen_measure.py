"""批量对齐：Edge 无头量原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/generation 下跑 python serve.py（8771）
  2. flutter test tool/ui_shell/gen_prototype_capture_test.dart
  3. python tool/ui_shell/gen_measure.py [场景...]
生图页和原型同宽（左栏 420、历史栏 210），没有全局性的有意改动，直接列差值。"""
import json, re, subprocess, sys, tempfile, time
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/gen')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-gen-measure-edge'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
views = sys.argv[1:] or list(flut)


def proto(v):
    for _ in range(3):
        r = subprocess.run([EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={PROFILE}', '--no-first-run',
                            '--no-default-browser-check', '--virtual-time-budget=8000', '--window-size=1700,1300', '--dump-dom',
                            f'http://127.0.0.1:8771/wt/ui-gen/tool/ui_shell/gen_measure.html?t={time.time()}#{v}'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
        m = re.search(r'@@(.*?)@@', r.stdout, re.S)
        if m:
            return json.loads(m.group(1))
    return {}


P = {v: proto(v) for v in views}
(D / 'proto_rects.json').write_text(json.dumps(P, indent=1), encoding='utf-8')
n = 0
worst = (0, '')
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到')
    for k in sorted(set(p) | set(f)):
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
