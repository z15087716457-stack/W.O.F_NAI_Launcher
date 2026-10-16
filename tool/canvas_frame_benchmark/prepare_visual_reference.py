"""Retain the reviewed pre-change channel renderer for pixel equivalence."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
target = ROOT / '.dart_tool/canvas-frames-20261016/reference'
target.mkdir(parents=True, exist_ok=True)
commit = sys.argv[1]
for name in ['scene', 'paint', 'palette', 'geometry', 'themes_a', 'themes_b', 'themes_c']:
    path = f'lib/presentation/ui/channel/channel_{name}.dart'
    text = subprocess.check_output(['git', 'show', f'{commit}:{path}'], cwd=ROOT).decode()
    text = text.replace("'channel_contract.dart'", "'package:nai_launcher/presentation/ui/channel/channel_contract.dart'")
    text = text.replace("'../../themes/studio_typography.dart'", "'package:nai_launcher/presentation/themes/studio_typography.dart'")
    (target / f'channel_{name}.dart').write_text(text, encoding='utf-8')
(target.parent / 'equivalence_test.dart').write_text(
    (ROOT / 'tool/canvas_frame_benchmark/geometry_equivalence.dart.template').read_text(encoding='utf-8'),
    encoding='utf-8')
print(target)
