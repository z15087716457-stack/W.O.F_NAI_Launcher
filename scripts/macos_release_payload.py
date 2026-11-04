"""macOS release checks and metadata for the app bundle (Python 3, stdlib only).

Used by scripts/package_macos_release.sh on the staged copy of the app bundle;
the Windows counterpart is scripts/windows_release_payload.py.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess

NODE_VERSION = 'v24.18.0'
ARCHITECTURES = ['arm64', 'x86_64']
STUDIO_BRIDGE = 'Contents/Resources/tools/studio-bridge'
RAG_HOST = 'Contents/Resources/tools/rag-stdio-host'
# npm prebuild folders for one architecture, e.g. prebuilds/darwin-arm64/x.node
PREBUILD_DIRS = {'darwin-arm64': 'arm64', 'darwin-x64': 'x86_64'}
# Real-ESRGAN from scripts/build_macos.sh, with the engine's own license and the
# notices of what it links statically (MoltenVK, SPIRV-Cross, cereal, LLVM OpenMP).
LOCAL_UPSCALE = 'Contents/Resources/tools/local-upscale'
LOCAL_UPSCALE_FILES = ('realesrgan-ncnn-vulkan', 'LICENSE', 'MOLTENVK-LICENSE.txt',
                       'CEREAL-LICENSE.txt', 'LLVM-OPENMP-LICENSE.txt')


def files(root):
    return sorted(p for p in root.rglob('*') if p.is_file() and not p.is_symlink())


def sha(p):
    h = hashlib.sha256()
    with p.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def write_json(p, obj):
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def contents(app):
    return app / 'Contents'


def agent_dir(app):
    return contents(app) / 'Resources/tools/nai-agent'


def info_plist(app):
    with (contents(app) / 'Info.plist').open('rb') as stream:
        return plistlib.load(stream)


def reject_private(app):
    """Refuse developer data that a local run may have left inside the bundle."""
    root = app.resolve()
    for p in app.rglob('*'):
        name = p.name.lower()
        if (name in {'user-data', 'agent-data', 'install_diagnostics.log', '.runs', '.env'}
                or name.startswith(('.studio-data-', '.cumulative-'))
                or re.fullmatch(r'.*\.r3.-write', name) or name.endswith('-restore')):
            raise RuntimeError(f'Private application state must not be packaged: {p}')
        # Framework version links stay inside the bundle; anything else would
        # ship a path from this machine and fails strict code-sign checks.
        if p.is_symlink():
            target = os.readlink(p)
            resolved = (p.parent / target).resolve()
            if os.path.isabs(target) or not resolved.is_relative_to(root):
                raise RuntimeError(f'Symbolic link leaves the app bundle: {p} -> {target}')


def verify_release_build(app):
    flutter_assets = contents(app) / 'Frameworks/App.framework/Resources/flutter_assets'
    if not flutter_assets.is_dir():
        raise RuntimeError(f'Not a Flutter macOS app bundle: {app}')
    if (flutter_assets / 'kernel_blob.bin').exists():
        raise RuntimeError('This is a debug build; run scripts/build_macos.sh --release first.')
    return flutter_assets


def apple_version(value, minimum_segments):
    """Flutter keeps only digits and dots in CFBundleShortVersionString / CFBundleVersion."""
    segments = [s for s in re.sub(r'[^\d.]', '', value).split('.') if s]
    while len(segments) < minimum_segments:
        segments.append('0')
    return '.'.join(segments)


def verify_bundle_version(app, version, display):
    info = info_plist(app)
    build = version.split('+', 1)[1] if '+' in version else display
    expected = (apple_version(display, 3), apple_version(build, 1))
    actual = (info.get('CFBundleShortVersionString'), info.get('CFBundleVersion'))
    if actual != expected:
        raise RuntimeError(f'App bundle was built as {actual[0]} ({actual[1]}), '
                           f'expected {expected[0]} ({expected[1]}); rebuild before packaging.')


def verify_assets(flutter_assets):
    """Bundled databases must be real SQLite files, not Git LFS pointers."""
    databases = sorted((flutter_assets / 'assets/databases').glob('*.db'))
    if not databases:
        raise RuntimeError('No bundled databases found in the app bundle.')
    for p in databases:
        with p.open('rb') as stream:
            if stream.read(16) != b'SQLite format 3\x00':
                raise RuntimeError(f'Database is not a SQLite file (missing git lfs pull?): {p}')
    for p in files(flutter_assets):
        with p.open('rb') as stream:
            if stream.read(40).startswith(b'version https://git-lfs.github.com/spec/'):
                raise RuntimeError(f'Git LFS pointer packaged instead of the file: {p}')


def verify_local_upscale(app, flutter_assets):
    """The macOS engine is bundled; the Windows engine and worker are not."""
    for name in LOCAL_UPSCALE_FILES:
        if not (app / LOCAL_UPSCALE / name).is_file():
            raise RuntimeError(f'The app bundle must contain {LOCAL_UPSCALE}/{name}')
    windows = flutter_assets / 'assets/local_upscale/windows'
    if windows.exists():
        raise RuntimeError(f'Windows upscaling programs must not be packaged: {windows}')


def verify_agent(root, app):
    """Same Pi and Node checks as the Windows payload, on the bundled copy."""
    source = root / 'tool/nai_agent'
    lock = json.loads((source / 'package-lock.json').read_text(encoding='utf-8'))['packages']
    installed = json.loads((source / 'node_modules/.package-lock.json').read_text(encoding='utf-8'))['packages']
    if set(installed) != set(lock) - {''}:
        raise RuntimeError('Agent node_modules package key set differs from package-lock.json; run npm ci.')
    agent = agent_dir(app)
    pi_version = lock['node_modules/@earendil-works/pi-coding-agent']['version']
    for family in ('pi-agent-core', 'pi-ai', 'pi-codemode', 'pi-coding-agent',
                   'pi-mcp', 'pi-schema', 'pi-telemetry', 'pi-tui'):
        key = f'node_modules/@earendil-works/{family}'
        version = json.loads((agent / key / 'package.json').read_text(encoding='utf-8'))['version']
        if not (version == installed[key]['version'] == lock[key]['version'] == pi_version):
            raise RuntimeError(f'Expected Pi {pi_version}: {family}')
    if (agent / 'node_modules/@earendil-works/chord').exists():
        raise RuntimeError('Obsolete chord package found; run npm ci.')
    if len(files(source / 'node_modules')) != len(files(agent / 'node_modules')):
        raise RuntimeError('Bundled Agent node_modules differs from tool/nai_agent/node_modules.')
    for name in ('node', 'NODE-LICENSE', 'PI-LICENSE'):
        if not (agent / name).is_file():
            raise RuntimeError(f'The app bundle must contain tools/nai-agent/{name}')
    version = subprocess.check_output([str(agent / 'node'), '--version'], text=True).strip()
    if version != NODE_VERSION:
        raise RuntimeError(f'Expected Node {NODE_VERSION}, got {version}')
    for name in ('npm', 'npx', 'npm-runtime/bin/npm-cli.js', 'npm-runtime/bin/npx-cli.js',
                 'npm-runtime/package.json', 'npm-runtime/LICENSE'):
        if not (agent / name).is_file():
            raise RuntimeError(f'The app bundle must contain tools/nai-agent/{name}')
    for command in ('npm', 'npx'):
        if not os.access(agent / command, os.X_OK):
            raise RuntimeError(f'Bundled {command} must be executable')
    npm_version = json.loads((agent / 'npm-runtime/package.json').read_text(encoding='utf-8'))['version']
    for command in ('npm', 'npx'):
        actual = subprocess.check_output([str(agent / command), '--version'], text=True,
                                         env={**os.environ, 'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'}).strip()
        if actual != npm_version:
            raise RuntimeError(f'Bundled {command} version differs from its package.json')
    return version


def verify_rag(app, flutter_assets):
    """build_macos.sh adds the macOS RAG host and strips the Windows one."""
    host = app / RAG_HOST
    if not host.is_file() or not os.access(host, os.X_OK) or not is_macho(host):
        raise RuntimeError(f'The app bundle must contain an executable {RAG_HOST}')
    windows = flutter_assets / 'assets/rag/windows'
    if windows.exists():
        raise RuntimeError(f'Windows-only RAG host left in the bundle: {windows}')


def is_macho(p):
    with p.open('rb') as stream:
        head = stream.read(8)
    if head[:4] in (b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe'):
        return True
    # Universal binaries share 0xcafebabe with Java class files; a fat header
    # lists only a handful of architectures.
    return head[:4] in (b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf') and 0 < int.from_bytes(head[4:8], 'big') < 20


def architectures(p):
    return subprocess.check_output(['lipo', '-archs', str(p)], text=True).split()


def prebuild_pair_complete(app, relative, archs):
    """A single-architecture npm prebuild is fine when the other Mac one ships too."""
    parts = relative.split('/')
    for i, part in enumerate(parts):
        if PREBUILD_DIRS.get(part) and archs == [PREBUILD_DIRS[part]]:
            return all((app / '/'.join(parts[:i] + [folder] + parts[i + 1:])).is_file()
                       for folder in PREBUILD_DIRS)
    return False


def verify_architectures(app, allow_host_only_bridge):
    """Every executable and library must run on both Apple silicon and Intel Macs.

    Node prebuilds may come as a darwin-arm64 / darwin-x64 pair that the module
    loader picks from at run time. A studio-bridge built without Rosetta has
    only the build machine's slice; such a package is for local use and needs an
    explicit opt-in.
    """
    checked = 0
    for p in files(app):
        if not is_macho(p):
            continue
        archs = architectures(p)
        missing = [arch for arch in ARCHITECTURES if arch not in archs]
        relative = p.relative_to(app).as_posix()
        if missing and allow_host_only_bridge and relative == STUDIO_BRIDGE:
            print(f'WARNING: {relative} has only {" ".join(archs)}; do not publish this package.')
        elif missing and not prebuild_pair_complete(app, relative, archs):
            raise RuntimeError(f'{relative} has {" ".join(archs)}, missing {" ".join(missing)}')
        checked += 1
    return checked


def verify(root, app, version, display, allow_host_only_bridge):
    reject_private(app)
    flutter_assets = verify_release_build(app)
    verify_bundle_version(app, version, display)
    verify_assets(flutter_assets)
    verify_rag(app, flutter_assets)
    node = verify_agent(root, app)
    binaries = verify_architectures(app, allow_host_only_bridge)
    verify_local_upscale(app, flutter_assets)
    print(json.dumps({'node': node, 'machOFiles': binaries}))


def finish(root, app, version, display, flutter_json, signature):
    reject_private(app)
    flutter = json.loads(Path(flutter_json).read_text(encoding='utf-8-sig'))
    info = info_plist(app)
    executable = contents(app) / 'MacOS' / info['CFBundleExecutable']
    node = subprocess.check_output([str(agent_dir(app) / 'node'), '--version'], text=True).strip()
    pi = agent_dir(app) / 'node_modules/@earendil-works/pi-coding-agent/package.json'
    pi_version = json.loads(pi.read_text(encoding='utf-8'))['version']
    write_json(contents(app) / 'Resources/package-info.json', {
        'product': 'W.O.F NAI Studio', 'version': display, 'buildVersion': version,
        'channel': 'preview' if '-' in display else 'stable', 'platform': 'macos-universal',
        'architectures': architectures(executable),
        'studioBridgeArchitectures': architectures(app / STUDIO_BRIDGE),
        'bundleIdentifier': info['CFBundleIdentifier'],
        'minimumSystemVersion': info.get('LSMinimumSystemVersion'),
        'sourceCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'aotSha256': sha(contents(app) / 'Frameworks/App.framework/Versions/A/App'),
        'flutterVersion': flutter['frameworkVersion'], 'dartVersion': flutter['dartSdkVersion'],
        'nodeVersion': node, 'piVersion': pi_version,
        'codeSignature': 'ad-hoc' if signature == '-' else signature,
        'containsPublisherUserData': False,
        'dataStorage': f'~/Library/Application Support/{info["CFBundleIdentifier"]}',
    })
    print(f'Staged {len(files(app))} files')


def checksum(output):
    line = f'{sha(output)}  {output.name}\n'
    Path(str(output) + '.sha256').write_text(line, encoding='utf-8')
    print(line, end='')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['verify', 'finish', 'checksum'])
    parser.add_argument('--root', default='.')
    parser.add_argument('--app')
    parser.add_argument('--version')
    parser.add_argument('--display')
    parser.add_argument('--flutter-json')
    parser.add_argument('--signature', default='-')
    parser.add_argument('--allow-host-only-bridge', action='store_true')
    parser.add_argument('--output')
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if args.operation == 'verify':
        verify(root, Path(args.app), args.version, args.display, args.allow_host_only_bridge)
    elif args.operation == 'finish':
        finish(root, Path(args.app), args.version, args.display, args.flutter_json, args.signature)
    else:
        checksum(Path(args.output))
