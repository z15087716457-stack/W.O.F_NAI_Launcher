"""Run the built probe and summarize native FrameTiming (not widget counts)."""
import argparse
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import time
import shutil
from contextlib import nullcontext
from load import LoadCapture

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / '.dart_tool/canvas-frames-20261016'
parser = argparse.ArgumentParser()
parser.add_argument('label')
parser.add_argument('--variants', nargs='+', default=['full', 'no-sides', 'off'])
parser.add_argument('--rounds', type=int, default=3)
parser.add_argument('--count', type=int, default=200)
parser.add_argument('--paired', action='store_true')
parser.add_argument('--monitor-load', action='store_true')
args = parser.parse_args()
exe = AUDIT / 'app/build/windows/x64/runner/Profile/nai_launcher.exe'
assert exe.is_file(), exe
results = []
for run in range(args.rounds):
    schedule = [('before', 'full'), ('after', 'full')] if args.paired else [(v, v) for v in args.variants]
    for variant, scene in schedule:
        target = AUDIT / f'{args.label}-{variant}-{run}.json'
        if target.exists():
            raise SystemExit(f'Refusing to overwrite {target}')
        private = AUDIT / 'private' / f'{args.label}-{variant}-{run}'
        private.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ)
        env.update(APPDATA=str(private / 'roaming'), LOCALAPPDATA=str(private / 'local'))
        for folder in ['roaming', 'local']:
            (private / folder).mkdir(exist_ok=True)
        load = LoadCapture(target.with_suffix('')) if args.monitor_load else nullcontext()
        with load, target.with_suffix('.log').open('w', encoding='utf-8') as log:
            if args.paired:
                shutil.copy2(AUDIT / f'{variant}-profile-app.so', exe.parent / 'data/app.so')
            child = subprocess.Popen([
                str(exe), f'--variant={scene}', f'--source={ROOT}', f'--output={target}', f'--count={args.count}',
            ], cwd=exe.parent, env=env, stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 70
            try:
                while not target.exists() and child.poll() is None and time.monotonic() < deadline:
                    time.sleep(.1)
                if not target.exists():
                    raise SystemExit(f'Probe failed: {child.poll()}, {target.with_suffix(".log")}')
                data = json.loads(target.read_text())
            finally:
                if child.poll() is None:
                    child.terminate()
                child.wait(timeout=10)
        data = json.loads(target.read_text())
        hz = data['refresh_hz']
        budget = 1_000_000 / hz
        def stats(values):
            values = sorted(values)
            def p(q):
                return round(values[min(len(values) - 1, math.ceil(q * len(values)) - 1)] / 1000, 3)
            return {'p50_ms': p(.5), 'p95_ms': p(.95), 'p99_ms': p(.99), 'max_ms': p(1)}
        summary = {'run': run, 'variant': variant, 'refresh_hz': hz, 'dpr': data['dpr'], 'physical': data['physical'], 'shutdown': 'driver_stopped_after_complete_result', 'cases': {}}
        for name, sample in data['samples'].items():
            frames = sample['frames']
            if len(frames) < 20:
                raise SystemExit(f'Missing native timing data: {target}, {name}, {len(frames)}')
            stamps = [f['vsync'] for f in frames]
            gaps = [b - a for a, b in zip(stamps, stamps[1:])]
            summary['cases'][name] = {
                'frames': len(frames), 'ticks': sample['ticks'],
                'build': stats([f['build_us'] for f in frames]),
                'raster': stats([f['raster_us'] for f in frames]),
                'total': stats([f['total_us'] for f in frames]),
                'vsync_gap': stats(gaps),
                'build_over_budget': sum(f['build_us'] > budget for f in frames),
                'raster_over_budget': sum(f['raster_us'] > budget for f in frames),
                'gaps_over_1_5_budget': sum(g > budget * 1.5 for g in gaps),
            }
        results.append(summary)
        print(json.dumps(summary), flush=True)
        (AUDIT / f'{args.label}-summary.json').write_text(json.dumps(results, indent=2))
