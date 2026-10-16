"""Compile old rendering code in a copied package, never in active source."""
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool/canvas-frames-20261016'
APP = AUDIT / 'app'
FORK = AUDIT / 'baseline-package'
assert not FORK.exists()
FORK.mkdir()
shutil.copytree(ROOT / 'lib', FORK / 'lib')
shutil.copy2(ROOT / 'pubspec.yaml', FORK / 'pubspec.yaml')
for name in ['format', 'layer', 'paint', 'themes_c']:
    path = f'lib/presentation/ui/channel/channel_{name}.dart'
    (FORK / path).write_bytes(subprocess.check_output(['git', 'show', f'370ce2153:{path}'], cwd=ROOT))
# Native Windows directory junction: asset reads remain in the verified source.
subprocess.run(['powershell.exe', '-NoProfile', '-Command',
    f"New-Item -ItemType Junction -Path '{FORK / 'assets'}' -Target '{ROOT / 'assets'}' | Out-Null"], check=True)
subprocess.run(['powershell.exe', '-NoProfile', '-Command',
    f"New-Item -ItemType Junction -Path '{FORK / 'tool'}' -Target '{ROOT / 'tool'}' | Out-Null"], check=True)
config = APP / '.dart_tool/package_config.json'
shutil.copy2(config, AUDIT / 'original-probe-package-config.json')
payload = json.loads(config.read_text())
item = next(p for p in payload['packages'] if p['name'] == 'nai_launcher')
item['rootUri'] = FORK.as_uri() + '/'
config.write_text(json.dumps(payload, indent=2), encoding='utf-8')
shutil.copy2(APP / 'build/windows/x64/runner/Profile/data/app.so', AUDIT / 'after-profile-app.so')
print('Isolated baseline package prepared; restore package config after build.')
