"""Windows release staging helpers (Python 3, stdlib only; long paths + ZIP64)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile


def path(value):
    value = os.path.abspath(value)
    if os.name == 'nt' and not value.startswith('\\\\?\\'):
        value = '\\\\?\\' + value
    return Path(value)


def files(root):
    return sorted(p for p in root.rglob('*') if p.is_file())


def sha(p):
    h = hashlib.sha256()
    with p.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def write_json(p, obj):
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def reject_private(root):
    for p in root.rglob('*'):
        name = p.name.lower()
        if (name in {'user-data', 'agent-data', 'nai_launcher.exe.webview2', 'install_diagnostics.log'}
                or name.startswith(('.studio-data-', '.cumulative-'))
                or re.fullmatch(r'.*\.r3.-write', name) or name.endswith('-restore')):
            raise RuntimeError(f'Private application state must not be packaged: {p}')
        if p.is_symlink() or (hasattr(p, 'is_junction') and p.is_junction()):
            raise RuntimeError(f'Reparse point must not be packaged: {p}')


def verify_agent(root, runtime):
    source = root / 'tool/nai_agent'
    lock = json.loads((source / 'package-lock.json').read_text(encoding='utf-8'))['packages']
    installed = json.loads((source / 'node_modules/.package-lock.json').read_text(encoding='utf-8'))['packages']
    if set(installed) != set(lock) - {''}:
        raise RuntimeError('Agent node_modules package key set differs from package-lock.json; run npm ci in CI.')
    for family in ('pi-agent-core', 'pi-ai', 'pi-codemode', 'pi-coding-agent', 'pi-mcp', 'pi-telemetry', 'pi-tui'):
        key = f'node_modules/@earendil-works/{family}'
        version = json.loads((source / key / 'package.json').read_text(encoding='utf-8'))['version']
        if not (version == installed[key]['version'] == lock[key]['version'] == '1.3.0'):
            raise RuntimeError(f'Expected Pi 1.3.0: {family}')
    if (source / 'node_modules/@earendil-works/chord').exists():
        raise RuntimeError('Obsolete chord package found; run npm ci in CI.')
    for name in ('node.exe', 'NODE-LICENSE', 'PI-LICENSE'):
        if not (runtime / name).is_file():
            raise RuntimeError(f'NodeRuntimeDirectory must contain {name}: {runtime}')
    # Use ordinary absolute paths for CreateProcess; extended paths are for file IO.
    version = subprocess.check_output([str(runtime / 'node.exe'), '--version'], text=True).strip()
    if version != 'v24.18.0':
        raise RuntimeError(f'Expected Node v24.18.0, got {version}')


def stage(root, release, destination, runtime):
    reject_private(release)
    verify_agent(root, runtime)
    if destination.exists():
        reject_private(destination)
        shutil.rmtree(destination)
    shutil.copytree(release, destination)
    # Never inherit old auxiliary runtimes from an incremental Flutter output.
    agent = destination / 'tools/nai-agent'
    if agent.exists():
        shutil.rmtree(agent)
    agent.mkdir(parents=True)
    tracked = subprocess.check_output(['git', 'ls-files', '-z', '--', 'tool/nai_agent'], cwd=root)
    copied = 0
    for name in tracked.decode('utf-8').split('\0'):
        if not name:
            continue
        relative = Path(name).relative_to('tool/nai_agent')
        if relative.parts[0] in {'test', 'node_modules'}:
            continue
        target = agent / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / name, target)
        copied += 1
    modules = root / 'tool/nai_agent/node_modules'
    reject_private(modules)
    shutil.copytree(modules, agent / 'node_modules')
    source_files = files(modules)
    if len(source_files) != len(files(agent / 'node_modules')):
        raise RuntimeError('Agent node_modules copy lost files (possibly a long-path issue).')
    for name in ('node.exe', 'NODE-LICENSE', 'PI-LICENSE'):
        shutil.copy2(runtime / name, agent / name)
    for name in ('README.md', 'README.en-US.md', 'CHANGELOG.md', 'THIRD_PARTY_NOTICES.md', 'LICENSE'):
        shutil.copy2(root / name, destination / ('LICENSE.txt' if name == 'LICENSE' else name))
    print(json.dumps({'trackedAgentFiles': copied, 'nodeModulesFiles': len(source_files)}))


def finish(root, destination, version, display, flutter_json, crt_json):
    reject_private(destination)
    flutter = json.loads(path(flutter_json).read_text(encoding='utf-8-sig'))
    node = subprocess.check_output([str(destination / 'tools/nai-agent/node.exe'), '--version'], text=True).strip()
    write_json(destination / 'package-info.json', {
        'product': 'W.O.F NAI Studio', 'version': display, 'buildVersion': version,
        'channel': 'stable', 'platform': 'windows-x64',
        'sourceCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'aotSha256': sha(destination / 'data/app.so'),
        'flutterVersion': flutter['frameworkVersion'], 'dartVersion': flutter['dartSdkVersion'],
        'nodeVersion': node, 'piVersion': '1.3.0',
        'containsPublisherUserData': False, 'dataStorage': '<app dir>/user-data',
        'crtFiles': json.loads(path(crt_json).read_text(encoding='utf-8-sig')),
    })
    manifest = destination / 'app_files_manifest.json'
    sums = destination / 'SHA256SUMS.txt'
    manifest.unlink(missing_ok=True)
    sums.unlink(missing_ok=True)
    write_json(manifest, {'schemaVersion': 1, 'version': version, 'displayVersion': display,
                          'files': sorted(p.relative_to(destination).as_posix() for p in files(destination))})
    sums.write_text(''.join(f'{sha(p)}  {p.relative_to(destination).as_posix()}\n'
                            for p in files(destination)), encoding='utf-8')
    print(f'Staged {len(files(destination))} files')


def archive(destination, output):
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as z:
        for p in files(destination):
            z.write(p, destination.name + '/' + p.relative_to(destination).as_posix())


def checksums(outputs):
    lines = []
    for p in outputs:
        line = f'{sha(p)}  {p.name}\n'
        Path(str(p) + '.sha256').write_text(line, encoding='utf-8')
        lines.append(line)
    (outputs[0].parent / 'checksums.txt').write_text(''.join(lines), encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['preflight', 'stage', 'finish', 'zip', 'checksums'])
    parser.add_argument('--root', default='.')
    parser.add_argument('--release')
    parser.add_argument('--stage')
    parser.add_argument('--runtime')
    parser.add_argument('--version')
    parser.add_argument('--display')
    parser.add_argument('--flutter-json')
    parser.add_argument('--crt-json')
    parser.add_argument('--output', action='append')
    args = parser.parse_args()
    root = path(args.root)
    if args.operation == 'preflight':
        verify_agent(root, path(args.runtime))
    elif args.operation == 'stage':
        stage(root, path(args.release), path(args.stage), path(args.runtime))
    elif args.operation == 'finish':
        finish(root, path(args.stage), args.version, args.display, args.flutter_json, args.crt_json)
    elif args.operation == 'zip':
        archive(path(args.stage), path(args.output[0]))
    else:
        checksums([path(p) for p in args.output])
