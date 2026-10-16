"""Verify a fresh paired run while retaining earlier raw data and checks."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool/canvas-frames-20261016'
parser = argparse.ArgumentParser()
parser.add_argument('label')
args = parser.parse_args()
output = AUDIT / f'{args.label}-verification.json'
assert not output.exists(), output


def read(name):
    return json.loads((AUDIT / name).read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


prior = read('verification.json')
original = read('source-before.json')['files']
owned = prior['owned_source_hashes']
protected = [p for p in original if p.startswith(('lib/', 'assets/', 'windows/')) and p not in owned]
assert all(sha(ROOT / p) == original[p] for p in protected)
assert all(sha(ROOT / p) == expected for p, expected in owned.items())
assert sha(ROOT / 'DEVELOPMENT.md') == original['DEVELOPMENT.md']
for side, key in [('before', 'baseline_aot_sha256'), ('after', 'optimized_aot_sha256')]:
    assert sha(AUDIT / f'{side}-profile-app.so') == prior[key]
for path in owned:
    assert (AUDIT / 'baseline-package' / path).read_bytes() == subprocess.check_output(['git', 'show', f"{prior['baseline_commit']}:{path}"], cwd=ROOT)

runs = read(f'{args.label}-summary.json')
assert len(runs) == 6 and all(sum(r['variant'] == side for r in runs) == 3 for side in ('before', 'after'))
assert all(r['refresh_hz'] == prior['refresh_hz'] and r['physical'] == prior['physical_size'] and r['dpr'] == prior['dpr'] for r in runs)
table = {case: {metric: {f'{side}_p95_ms': statistics.median(r['cases'][case][metric]['p95_ms'] for r in runs if r['variant'] == side) for side in ('before', 'after')} for metric in ('build', 'raster', 'total', 'vsync_gap')} for case in ('drag', 'wheel', 'zoom')}
base = Image.open(AUDIT / f'{args.label}-before-0.json.png').convert('RGB')
captures = []
load = []
for run in runs:
    name = f"{args.label}-{run['variant']}-{run['run']}"
    raw = read(name + '.json')
    assert raw['count'] == prior['history_images']
    assert 'Impeller' in (AUDIT / f'{name}.log').read_text(encoding='utf-8')
    path = AUDIT / f'{name}.json.png'
    image = Image.open(path).convert('RGB')
    same = image.size == base.size and ImageChops.difference(base, image).getbbox() is None
    assert same, path
    captures.append({'path': path.name, 'identical_rgb': same})
for path in sorted(AUDIT.glob(f'{args.label}-*-cpu.json')):
    data = json.loads(path.read_text())
    assert len(data['samples']) >= 4, path
    cpu = [s['cpu_total_pct'] for s in data['samples']]
    processes = {}
    for sample in data['samples']:
        for process in sample['related_processes']:
            key = (process['pid'], process['name'])
            processes[key] = max(processes.get(key, 0), process['cpu_one_core_pct'])
    gpu_path = Path(str(path).replace('-cpu.json', '-gpu.csv'))
    gpu = [{key.strip(): value.strip() for key, value in row.items()} for row in csv.DictReader(gpu_path.open())]
    assert len(gpu) >= 4, gpu_path
    def gpu_range(key):
        values = [float(row[key]) for row in gpu]
        return {'min': min(values), 'median': statistics.median(values), 'max': max(values)}
    load.append({'cpu_file': path.name, 'gpu_file': gpu_path.name, 'started_utc': data['started_utc'], 'ended_utc': data['ended_utc'], 'samples': len(cpu), 'cpu_total_pct': {'min': min(cpu), 'median': statistics.median(cpu), 'max': max(cpu)}, 'gpu_utilization_pct': gpu_range('utilization.gpu [%]'), 'gpu_memory_mib': gpu_range('memory.used [MiB]'), 'related_process_max_one_core_pct': [{'pid': key[0], 'name': key[1], 'max': value} for key, value in sorted(processes.items())]})

installed = Path('E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/data/app.so')
receipt = Path('E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json')
assert sha(installed) == prior['installed_aot_unchanged']
assert sha(receipt) == prior['installed_receipt_sha256']
result = {'label': args.label, 'source_commit': prior['source_commit'], 'baseline_commit': prior['baseline_commit'], 'baseline_aot_sha256': prior['baseline_aot_sha256'], 'optimized_aot_sha256': prior['optimized_aot_sha256'], 'rounds_per_side': 3, 'history_images': prior['history_images'], 'refresh_hz': prior['refresh_hz'], 'physical_size': prior['physical_size'], 'p95_median_across_runs': table, 'load': load, 'native_capture_checks': captures, 'protected_production_files_unchanged': len(protected), 'owned_source_unchanged': True, 'unowned_development_md_unchanged': True, 'previous_validation_reused': 'verification.json (1022 checks, analysis, Release build; not rerun for measurement-only change)', 'installed_changed': False, 'installed_aot_sha256': sha(installed), 'qualification': 'User confirmed vector work paused/ended. Low-frequency system/process counters are context, not a kernel GPU scheduler or screen presentation trace.'}
output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'output': str(output), 'p95_median_across_runs': table, 'load_files': len(load), 'identical_captures': len(captures), 'installed_changed': False}, indent=2))
