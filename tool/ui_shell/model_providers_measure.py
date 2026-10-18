"""批量对齐：Edge 无头量服务商工作台原型（方案 B），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. flutter test tool/ui_shell/model_providers_prototype_capture_test.dart
  2. python tool/ui_shell/model_providers_measure.py [视图...] [--reuse] [--all]
脚本在 8793 起服务（根目录 .devin/），原型页量完 POST 回来。
有意改动（先减掉再列残差）：
- 基线：原型滚动区 10px 滚动条使内容左移 5px；纵向以服务商列表顶边对齐（标题区由设置页测量负责）。
- 连接失败横幅（b-p_relay）方案 B 原型没画，Flutter 按方案 A 的横幅补上：横幅以下整体下移，属场景不同。
- 文字类（title）只比 x、y、h：原型是行内块宽，Flutter 是文字宽。
- list / middle / inspector：Flutter 的栏按内容高，原型的栏铺满卡片：只比 x、y、w。
- 假数据：OpenRouter 目录原型写死 5 条，Flutter 是 342 条按筛选显示前 60 条：catalog 只比 x、y、w。"""
import functools, http.server, json, re, subprocess, sys, tempfile, threading, time, urllib.parse
from pathlib import Path

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/model-providers')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-mp-measure'; PROFILE.mkdir(parents=True, exist_ok=True)
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
                        '--virtual-time-budget=15000', '--window-size=1700,1300',
                        f'--screenshot={PROFILE / "x.png"}',
                        f'http://127.0.0.1:8793/wt/ui-model-providers/tool/ui_shell/model_providers_measure.html#{v}'],
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
    srv = http.server.ThreadingHTTPServer(('127.0.0.1', 8793), functools.partial(H, directory=str(ROOT)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    P = {v: proto(v) for v in views}
    srv.shutdown()
    CACHE.write_text(json.dumps(P, indent=1, ensure_ascii=False), encoding='utf-8')

total, worst = 0, (0, '')
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到'); continue
    for fam in ('prov',):
        a = sum(1 for k in p if re.fullmatch(fam + r'\d+', k)); b = sum(1 for k in f if re.fullmatch(fam + r'\d+', k))
        if a != b:
            print(f'{v} | {fam} 数量 原型 {a} / Flutter {b}')
    rows = []
    for k in p:
        if k not in f:
            continue
        a, b = p[k], list(f[k])
        # 基线：原型滚动区有 10px 滚动条（内容整体左移 5）；卡片以上的标题区属于设置页外框（另有测量），
        # 两边都以服务商列表顶边为原点。
        oy = f['list'][1] - p['list'][1]
        b = [b[0] - 5, b[1] - oy, b[2], b[3]]
        d = [round(b[i] - a[i], 1) for i in range(4)]
        if k in ('title',):
            d[2] = 0
        if k in ('list', 'middle', 'inspector', 'catalog', 'models'):
            d[3] = 0
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
