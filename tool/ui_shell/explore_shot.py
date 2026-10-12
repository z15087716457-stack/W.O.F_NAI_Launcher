"""原型截图（Edge 无头）：python tool/ui_shell/explore_shot.py [原型 hash...]，输出 .dart_tool/ui-shell/explore/proto/。
先在 .devin/mockups/style-explore 下跑 python serve.py（8773）。"""
import subprocess, sys, tempfile
from pathlib import Path
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
OUT = Path('.dart_tool/ui-shell/explore/proto').resolve(); OUT.mkdir(parents=True, exist_ok=True)
PROFILE = Path(tempfile.gettempdir()).resolve() / 'wof-explore-shot-edge'
ALL = ['a', 'a-gen', 'a-sel', 'a-evo', 'a-runs', 'a-empty', 'a-detail', 'a-ab', 'a-family', 'a-adopt',
       'a-dark', 'a-evo-dark']
for k in sys.argv[1:] or ALL:
    subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--hide-scrollbars', f'--user-data-dir={PROFILE}',
                    '--no-first-run', '--no-default-browser-check', '--virtual-time-budget=15000',
                    f'--screenshot={OUT / (k + ".png")}', '--window-size=1600,1000',
                    f'http://127.0.0.1:8772/mockups/style-explore/mock.html#{k}'], check=True, capture_output=True)
    print(k, end=' ', flush=True)
print()
