"""Create an independent native Windows probe; never stage/install Studio."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool' / 'canvas-frames-20261016'
APP = AUDIT / 'app'
AUDIT.mkdir(parents=True, exist_ok=True)
if APP.exists():
    raise SystemExit('Probe already exists; inspect/reuse it instead of overwriting.')
tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
(AUDIT / 'source-before.json').write_text(json.dumps({
    'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
    'files': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in tracked if p and (ROOT / p).is_file()},
    'status': subprocess.check_output(['git', 'status', '--short'], cwd=ROOT).decode(),
}, indent=2), encoding='utf-8')
APP.mkdir()
shutil.copytree(ROOT / 'windows', APP / 'windows', ignore=shutil.ignore_patterns('ephemeral', 'generated*'))
main = APP / 'windows/runner/main.cpp'
text = main.read_text(encoding='utf-8-sig')
text = text.replace('NAI_Launcher_SingleInstance_Mutex', 'Canvas_Frame_Probe_Isolated_Mutex')
text = text.replace('NAI_Launcher_WakeUp_Message', 'Canvas_Frame_Probe_WakeUp')
text = text.replace('L"W.O.F NAI Studio"', 'L"Canvas frame probe (isolated)"')
main.write_text(text, encoding='utf-8-sig')
# The probe has no browser, video, tray, drag/drop or account bootstrap. Register
# only its window controller; otherwise unrelated plugins assume app startup /
# shutdown ordering that this deliberately minimal host does not provide.
window = APP / 'windows/runner/flutter_window.cpp'
text = window.read_text(encoding='utf-8-sig')
text = '#include <window_manager/window_manager_plugin.h>\n' + text
text = text.replace('RegisterPlugins(flutter_controller_->engine());',
    'WindowManagerPluginRegisterWithRegistrar(flutter_controller_->engine()->GetRegistrarForPlugin("WindowManagerPlugin"));')
window.write_text(text, encoding='utf-8-sig')
(APP / 'lib').mkdir()
shutil.copy2(ROOT / 'tool/canvas_frame_benchmark/main.dart', APP / 'lib/main.dart')
shutil.copytree(ROOT / 'assets/icons', APP / 'assets/icons')
(APP / 'pubspec.yaml').write_text('''name: canvas_frame_probe
publish_to: none
version: 1.0.0+1
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  nai_launcher:
    path: ../../..
  flutter_riverpod: ^2.6.1
  window_manager: ^0.3.9
flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/icons/providers/
''', encoding='utf-8')
print(APP)
