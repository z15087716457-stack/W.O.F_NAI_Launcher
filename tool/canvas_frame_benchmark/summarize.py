"""Summarize reviewed runs and verify protected source/pixels/installation."""
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool/canvas-frames-20261016'
def read(name):
    return json.loads((AUDIT / name).read_text(encoding='utf-8'))
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
paired = read('paired-summary.json')
before = [r for r in paired if r['variant'] == 'before']
after = [r for r in paired if r['variant'] == 'after']
assert len(before) == len(after) == 3
table = {}
for case in ['drag', 'wheel', 'zoom']:
    table[case] = {}
    for metric in ['build', 'raster', 'total', 'vsync_gap']:
        table[case][metric] = {
            'before_p95_ms': statistics.median(r['cases'][case][metric]['p95_ms'] for r in before),
            'after_p95_ms': statistics.median(r['cases'][case][metric]['p95_ms'] for r in after),
        }
original = read('source-before.json')['files']
owned = {
    'lib/presentation/ui/channel/channel_format.dart',
    'lib/presentation/ui/channel/channel_layer.dart',
    'lib/presentation/ui/channel/channel_paint.dart',
    'lib/presentation/ui/channel/channel_themes_c.dart',
}
protected = [p for p in original if p.startswith(('lib/', 'assets/', 'windows/')) and p not in owned]
assert all(sha(ROOT / p) == original[p] for p in protected)
assert sha(ROOT / 'DEVELOPMENT.md') == original['DEVELOPMENT.md']
captures = []
base = Image.open(AUDIT / 'paired-before-0.json.png').convert('RGB')
for target in sorted(AUDIT.glob('paired-*.json.png')):
    image = Image.open(target).convert('RGB')
    same = image.size == base.size and ImageChops.difference(base, image).getbbox() is None
    assert same, target
    captures.append({'path': target.name, 'identical_rgb': same})
receipt_path = Path('E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json')
installed = Path('E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/data/app.so')
assert sha(installed) == 'a1e7f5d0561d8c8d8508ad36d0622fc74aa264023bdd82fec185f6f33b56332d'
checks = {name: read(name + '-result.json') for name in ['regression', 'channel-final', 'equivalence-final', 'analyze-final', 'build-final']}
assert all(check['exit_code'] == 0 for check in checks.values())
for p in owned:
    assert (AUDIT / 'baseline-package' / p).read_bytes() == subprocess.check_output(['git', 'show', f'370ce2153:{p}'], cwd=ROOT)
result = {
    'baseline_commit': read('source-before.json')['commit'],
    'profile_renderer': 'Impeller OpenGLESSDF (native Windows)',
    'refresh_hz': 144, 'physical_size': [1584, 961], 'dpr': 1,
    'rounds_per_side': 3, 'history_images': 200, 'seconds_per_case': 6,
    'design': 'interleaved before/after, same native host and fixture',
    'baseline_source_git_verified': True,
    'baseline_aot_sha256': sha(AUDIT / 'before-profile-app.so'),
    'optimized_aot_sha256': sha(AUDIT / 'after-profile-app.so'),
    'p95_median_across_runs': table,
    'protected_production_files_unchanged': len(protected),
    'owned_source_hashes': {p: sha(ROOT / p) for p in sorted(owned)},
    'unowned_development_md_unchanged': True,
    'native_capture_checks': captures,
    'geometry_equivalence': read('visual-equivalence.json'),
    'checks': checks,
    'distinct_tests_passed': checks['regression']['passed'] + checks['channel-final']['passed'] + checks['equivalence-final']['passed'],
    'installed_aot_unchanged': sha(installed), 'installed_receipt_sha256': sha(receipt_path),
    'installed_changed': False,
    'limitations': ['Isolated native production-widget scene, not a trace of the running user session.', 'FrameTiming is engine timing, not presented FPS.', 'Raster P95 remains above the 144Hz budget in this scene.', 'No backend, account, real generation or model workload was executed.'],
}
(AUDIT / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in result.items() if k in ['p95_median_across_runs', 'protected_production_files_unchanged', 'distinct_tests_passed', 'installed_changed']}, ensure_ascii=False, indent=2))
