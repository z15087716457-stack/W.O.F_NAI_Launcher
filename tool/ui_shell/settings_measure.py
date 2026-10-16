"""批量对齐：Edge 无头量设置页原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. flutter test tool/ui_shell/settings_prototype_capture_test.dart
  2. python tool/ui_shell/settings_measure.py [页面...] [--reuse] [--all]
脚本自己在 8792 起一个服务（根目录 .devin/），原型页量完把结果 POST 回来；
本机 Edge 无头要加 --no-sandbox，且 --dump-dom 不再输出，所以用 --screenshot 驱动页面。

坐标以设置页左上角为原点（原型扣掉 48px 主导航）。行 / 分区 / 卡片按出现顺序配对；两边数量不同的页列出数量差，
只比前面能配上的部分。默认只列每页最大的 6 项，--all 列全部。
有意改动（先减掉再列残差）：
- 假数据：快捷键 31 项（原型 62）、存储 42 GB（原型 38）、语义检索 91%（原型 72%）只影响文字，不影响位置。
- 原型窗口按钮占顶栏右侧 160px；Flutter 测试里没有窗口按钮（真实应用由 WindowChromeScope 避让）。
- 目录项：Flutter 量的是含外边距的点击区（左右各 8、上 1），原型量的是色块：x +8、w −16、y −1、h −1 后再比。
- 分区：Flutter 的 SettingsSection 含底部 30 间距，h −30 后再比。
- 眉题：原型 .eb 含前面 14px 短线 + 8 间距，Flutter 量的是文字：x −22 后再比。
- 文字类（眉题、标题、说明）只比 x、y、h：原型是块宽，Flutter 是文字宽。"""
import functools, http.server, json, re, subprocess, sys, tempfile, threading, time, urllib.parse
from pathlib import Path

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/settings')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-settings-measure'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
args = [a for a in sys.argv[1:] if not a.startswith('--')]
views = args or list(flut)


ROOT = Path(__file__).resolve().parents[4]  # .devin/
GOT = {}


class H(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        v = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)['v'][0]
        GOT[v] = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        self.send_response(204); self.end_headers()

    def log_message(self, *a):
        if '-v' in sys.argv: print(*a)


def proto(v):
    for _ in range(3):
        subprocess.run([EDGE, '--headless=new', '--no-sandbox', f'--user-data-dir={tempfile.mkdtemp(dir=PROFILE)}',
                        '--virtual-time-budget=15000', '--window-size=1700,1200',
                        f'--screenshot={PROFILE / "x.png"}',
                        f'http://127.0.0.1:8792/wt/ui-settings/tool/ui_shell/settings_measure.html#{v}'],
                       capture_output=True)
        # msedge.exe 启动器会立刻返回，真正的无头进程在后台跑：轮询等结果。
        for _ in range(120):
            if v in GOT:
                return GOT[v]
            time.sleep(.25)
    return {}


CACHE = D / 'proto_rects.json'
if '--reuse' in sys.argv and CACHE.exists():
    P = json.loads(CACHE.read_text(encoding='utf-8'))
else:
    srv = http.server.ThreadingHTTPServer(('127.0.0.1', 8792), functools.partial(H, directory=str(ROOT)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    P = {v: proto(v) for v in views}
    srv.shutdown()
    CACHE.write_text(json.dumps(P, indent=1, ensure_ascii=False), encoding='utf-8')

total, worst = 0, (0, '')
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到'); continue
    for fam in ('nav', 'sec', 'card', 'row', 'ac', 'tile'):
        a = sum(1 for k in p if re.fullmatch(fam + r'\d+', k)); b = sum(1 for k in f if re.fullmatch(fam + r'\d+', k))
        if a != b:
            print(f'{v} | {fam} 数量 原型 {a} / Flutter {b}')
    rows = []
    for k in p:
        if k not in f:
            continue
        a, b = p[k], list(f[k])
        if k.startswith('nav'):
            b = [b[0] + 8, b[1] + 1, b[2] - 16, b[3] - 1]
        elif re.fullmatch(r'sec\d+', k):
            b[3] -= 30
        elif k == 'eyebrow':
            b[0] -= 22
        d = [round(b[i] - a[i], 1) for i in range(4)]
        if k in ('eyebrow', 'title', 'desc'):
            d[2] = 0
        mx = max(abs(x) for x in d)
        if mx >= 1:
            rows.append((mx, k, d, a))
    rows.sort(reverse=True)
    total += len(rows)
    if rows and rows[0][0] > worst[0]:
        worst = (rows[0][0], f'{v}/{rows[0][1]}')
    print(f'{v} | {len(rows)} 处 ≥1px' + (f'，最大 {rows[0][0]}' if rows else ''))
    for mx, k, d, a in rows if '--all' in sys.argv else rows[:6]:
        print(f'   {k} | dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+} | proto {[round(x, 1) for x in a]}')
print(f'共 {total} 处偏差 ≥1px，最大 {worst[0]}（{worst[1]}）')
