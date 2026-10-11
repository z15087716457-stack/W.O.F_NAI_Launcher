"""批量对齐第一步：用 Edge 无头模式量原型（DOM 位置），和 Flutter 实绘导出的 rects.json 比，出偏差表（≥1px）。
用法（源码根目录）：
  1. 在 .devin/mockups/online 下跑 python serve.py
  2. flutter test tool/ui_shell/online_prototype_capture_test.dart
  3. python tool/ui_shell/online_measure.py [场景...]
原型结果写到 .dart_tool/ui-shell/nav/proto_rects.json。"""
import json, re, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
EDGE=r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
import tempfile
D=Path('.dart_tool/ui-shell/online')
# Edge 配置目录必须是绝对路径（相对路径会弹“无法创建数据目录”），放系统临时目录。
PROFILE=Path(tempfile.gettempdir()).resolve()/'wof-online-measure-edge'; PROFILE.mkdir(parents=True,exist_ok=True)
flut=json.loads((D/'flutter/rects.json').read_text(encoding='utf-8'))
views=sys.argv[1:] or list(flut)
def proto(v):
  for _ in range(3):
    r=subprocess.run([EDGE,'--headless=new','--disable-gpu',f'--user-data-dir={PROFILE}','--no-first-run','--no-default-browser-check','--virtual-time-budget=6000','--window-size=1700,1200','--dump-dom',f'http://127.0.0.1:8775/wt/ui-online/tool/ui_shell/online_measure.html?t={time.time()}#{v}'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,encoding='utf-8',errors='replace')
    m=re.search(r'@@(.*?)@@',r.stdout,re.S)
    if m: return v,json.loads(m.group(1))
  return v,{}
with ThreadPoolExecutor(1) as ex: P=dict(ex.map(proto,views))
(D/'proto_rects.json').write_text(json.dumps(P,indent=1),encoding='utf-8')
rows=[]
for v in views:
    p,f=P.get(v,{}),flut.get(v,{})
    for k in sorted(set(p)|set(f)):
        if k not in p or k not in f:
            if p: rows.append((v,k,'缺 '+('原型' if k not in p else 'Flutter'),''))
            continue
        a,b=p[k],f[k]
        d=[round(b[i]-a[i],1) for i in range(4)]
        if max(abs(x) for x in d)>=1: rows.append((v,k,f'dx {d[0]:+} dy {d[1]:+} dw {d[2]:+} dh {d[3]:+}',f'proto {[round(x,1) for x in a]}'))
for v in views:
    if not P.get(v): print(v,'| 原型没量到')
for r in rows: print(' | '.join(r))
print(f'{len(rows)} 处偏差 ≥1px')
