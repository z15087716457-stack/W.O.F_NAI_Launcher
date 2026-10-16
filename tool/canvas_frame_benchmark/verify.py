"""Bounded local verification, with immutable logs per operation."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool/canvas-frames-20261016'
SDK = 'E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7/bin/flutter.bat'
mode = sys.argv[1]
commands = {
    'channel': [SDK, 'test', '--no-pub', '--reporter=expanded', 'test/presentation/ui/channel'],
    'analyze': [SDK, 'analyze', '--no-pub'],
    'build': [SDK, 'build', 'windows', '--release', '--no-pub', '--no-tree-shake-icons'],
    'equivalence': [SDK, 'test', '--no-pub', '.dart_tool/canvas-frames-20261016/equivalence_test.dart', '--reporter=expanded'],
}
if mode == 'regression':
    paths = json.loads((ROOT / '.dart_tool/cumulative-r17-20261016/regression-paths.json').read_text())
    commands[mode] = [SDK, 'test', '--no-pub', '--reporter=expanded', *paths]
label = mode if len(sys.argv) < 3 else f'{mode}-{sys.argv[2]}'
path = AUDIT / f'{label}.log'
if path.exists():
    raise SystemExit(f'Preserve existing evidence: {path}')
with path.open('w', encoding='utf-8') as log:
    result = subprocess.run(commands[mode], cwd=ROOT, env={**os.environ, 'PYTHONIOENCODING': 'utf-8'}, stdout=log, stderr=subprocess.STDOUT)
text = path.read_text(encoding='utf-8')
evidence = {'exit_code': result.returncode, 'command': commands[mode], 'tail': text.splitlines()[-3:]}
if mode in ['regression', 'equivalence', 'channel'] and result.returncode == 0:
    last = next(line for line in reversed(text.splitlines()) if 'All tests passed!' in line)
    skipped = re.search(r'~(\d+)', last)
    evidence.update(passed=int(re.search(r'\+(\d+)', last).group(1)), skipped=int(skipped.group(1)) if skipped else 0)
(AUDIT / f'{label}-result.json').write_text(json.dumps(evidence, indent=2))
print(json.dumps(evidence, ensure_ascii=False), flush=True)
raise SystemExit(result.returncode)
