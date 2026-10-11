"""原型截图（Edge 无头）：python tool/ui_shell/refs_shot.py [场景...]，输出 .dart_tool/ui-shell/refs/proto/。
先在 .devin/mockups/refs 下跑 python serve.py。"""
import subprocess, sys, tempfile
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
OUT = Path('.dart_tool/ui-shell/refs/proto').resolve(); OUT.mkdir(parents=True, exist_ok=True)
# Edge 配置目录必须是绝对路径（相对路径会弹“无法创建数据目录”）。
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-refs-shot-edge'
ALL = ['a', 'a-dark', 'a-prec', 'a-prec-dark', 'a-sel', 'a-v5', 'detail', 'pdetail', 'bundle',
       'import', 'drop', 'export', 'picker', 'empty', 'empty-prec']
for k in sys.argv[1:] or ALL:
    subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--hide-scrollbars', f'--user-data-dir={PROFILE}',
                    '--no-first-run', '--no-default-browser-check', '--virtual-time-budget=15000',
                    f'--screenshot={OUT / (k + ".png")}', '--window-size=1600,1000',
                    f'http://127.0.0.1:8774/mockups/refs/mock.html#{k}'], check=True, capture_output=True)
    print(k, end=' ', flush=True)
print()
