"""批量对齐：Edge 无头量视觉通道原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/canvas-channel 下跑 python serve.py（8790）
  2. flutter test tool/ui_shell/channel_prototype_capture_test.dart
  3. python tool/ui_shell/channel_measure.py [场景...] [--reuse]

坐标：设置分区以“视觉通道”标题内容框左上角为原点；刻度条以画布右上角为原点（h 记的是离画布底的距离）。
有意改动（先减掉再列残差）：
- 弹层宽 316、内边距 12（沿用现有显示设置弹层），内容宽 292；原型是 4 + 每节左右 10，内容宽 288。
  撑满宽度的件（分段、卡片区、说明框、开关行）宽 +4，卡片每张宽 +1.33，右列卡片 x +2.67。
- “本次”这句两边用同一种子（7）算，文字必须一致——用来核对哈希 / 随机数 / 洗牌移植是否逐位相同。
画在画布上的部分（装饰、时间标签、日期分隔）没有 DOM，用 channel_pair.py 出并排图目测。"""
import json, re, subprocess, sys, tempfile, time
from pathlib import Path

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
D = Path('.dart_tool/ui-shell/channel')
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-channel-measure-edge'; PROFILE.mkdir(parents=True, exist_ok=True)
flut = json.loads((D / 'flutter/rects.json').read_text(encoding='utf-8'))
args = [a for a in sys.argv[1:] if not a.startswith('--')]
views = args or ['pop', 'pop-dark', 'pop-fixed', 'pop-off', 'random']
WIDE = {'mode', 'cards', 'note', 'level', 'ruler', 'motion', 'sec'}


def proto(v):
    for _ in range(3):
        r = subprocess.run([EDGE, '--headless=new', '--disable-gpu', f'--user-data-dir={PROFILE}', '--no-first-run',
                            '--no-default-browser-check', '--virtual-time-budget=12000', '--window-size=1700,1200', '--dump-dom',
                            f'http://127.0.0.1:8790/wt/ui-channel/tool/ui_shell/channel_measure.html?t={time.time()}#{v}'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
        m = re.search(r'@@(.*?)@@', r.stdout, re.S)
        if m:
            return json.loads(m.group(1))
    return {}


def flutter_frame(f):
    out = {}
    sec, cv = f.get('sec'), f.get('canvas')
    for k, r in f.items():
        if k in ('pop', 'canvas', 'noteText'):
            continue
        if k == 'scrub' and cv:
            out[k] = [r[0] - (cv[0] + cv[2]), r[1] - cv[1], r[2], (cv[1] + cv[3]) - (r[1] + r[3])]
        elif sec:
            out[k] = [r[0] - sec[0], r[1] - sec[1], r[2], 0 if k == 'sec' else r[3]]
    return out


def intended(k, r):
    """把原型换算成 Flutter 的内容宽（292）。"""
    x, y, w, h = r
    if k in WIDE:
        return [x, y, w + 4, h]
    if k == 'card-wave':
        return [x + 8 / 3, y, w + 4 / 3, h]
    if k == 'card-circuit':
        return [x, y, w + 4 / 3, h]
    if k.startswith('mode-'):
        i = ['mode-off', 'mode-fixed', 'mode-random'].index(k)
        return [x + i * 4 / 3, y, w + 4 / 3, h]
    return r


CACHE = D / 'proto_rects.json'
if '--reuse' in sys.argv and CACHE.exists():
    P = json.loads(CACHE.read_text(encoding='utf-8'))
else:
    P = {v: proto(v) for v in views}
    CACHE.write_text(json.dumps(P, indent=1, ensure_ascii=False), encoding='utf-8')
n, worst = 0, (0, '')
for v in views:
    p, f = P.get(v, {}), flut.get(v, {})
    if not p:
        print(v, '| 原型没量到'); continue
    pt, ft = p.pop('noteText', None), f.get('noteText')
    if pt and ft is None and v in ('pop', 'pop-dark'):
        print(f'{v} | Flutter 没导出“本次”文字'); n += 1
    elif pt and ft is not None:
        if pt.strip() != ft.strip():
            print(f'{v} | 本次顺序不一致 | 原型「{pt}」 Flutter「{ft}」'); n += 1
        else:
            print(f'{v} | 本次顺序一致：{pt}')
    ff = flutter_frame(f)
    for k in sorted(set(p) | set(ff)):
        if k not in ff or k not in p:
            print(v, '|', k, '| 只有', '原型' if k in p else 'Flutter'); continue
        a, b = intended(k, p[k]), ff[k]
        d = [round(b[i] - a[i], 1) for i in range(4)]
        mx = max(abs(x) for x in d)
        if mx >= 1:
            print(f'{v} | {k} | dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+} | proto {[round(x, 1) for x in a]}'); n += 1
            if mx > worst[0]:
                worst = (mx, f'{v}/{k}')
print(f'{n} 处偏差 ≥1px，最大 {worst[0]}（{worst[1]}）')
