"""Offline checks for the Node tools shipped in a macOS app; no npm installs."""
import importlib.util
import json
import os
import plistlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('payload', SCRIPTS / 'macos_release_payload.py')
payload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(payload)


class MacNodeToolsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='mac node tools ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / 'Studio 测试.app'
        self.agent = payload.agent_dir(self.app)
        self.agent.mkdir(parents=True)

    def test_package_metadata_distinguishes_preview_from_stable(self):
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
            'CFBundleExecutable': 'Studio',
            'CFBundleIdentifier': 'com.wof.naiStudio',
            'LSMinimumSystemVersion': '12.0',
        }))
        aot = self.app / 'Contents/Frameworks/App.framework/Versions/A/App'
        aot.parent.mkdir(parents=True)
        aot.write_bytes(b'synthetic AOT fixture')
        flutter = self.root / 'flutter.json'
        flutter.write_text('{"frameworkVersion":"3.47.7","dartSdkVersion":"3.13.5"}')

        pi = self.agent / 'node_modules/@earendil-works/pi-coding-agent/package.json'
        pi.parent.mkdir(parents=True)
        pi.write_text(json.dumps({'version': '1.5.0'}))

        def command(args, **kwargs):
            if args[0] == 'lipo':
                return 'arm64 x86_64\n'
            if args[0] == 'git':
                return 'fixture-source-commit\n'
            if args[-1] == '--version':
                return 'v24.18.0\n'
            raise AssertionError(args)

        with patch.object(payload.subprocess, 'check_output', side_effect=command):
            for version, display, expected in [
                ('1.2.3+4', '1.2.3', 'stable'),
                ('1.2.3-beta.1+5', '1.2.3-beta.1', 'preview'),
            ]:
                with self.subTest(version=version):
                    payload.finish(self.root, self.app, version, display, flutter, '-')
                    metadata = json.loads((self.app / 'Contents/Resources/package-info.json').read_text())
                    self.assertEqual(metadata['piVersion'], '1.5.0')
                    self.assertEqual(metadata['channel'], expected)
                    self.assertEqual(metadata['version'], display)
                    self.assertEqual(metadata['codeSignature'], 'ad-hoc')

    def prepare_locked_agent(self):
        source = self.root / 'tool/nai_agent'
        packages = {}
        for family in ('pi-agent-core', 'pi-ai', 'pi-codemode', 'pi-coding-agent',
                       'pi-mcp', 'pi-schema', 'pi-telemetry', 'pi-tui'):
            key = f'node_modules/@earendil-works/{family}'
            packages[key] = {'version': '1.5.0'}
            path = source / key / 'package.json'
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps(packages[key]))
        (source / 'package-lock.json').write_text(json.dumps({'packages': {'': {}, **packages}}))
        (source / 'node_modules/.package-lock.json').write_text(json.dumps({'packages': packages}))
        shutil.copytree(source / 'node_modules', self.agent / 'node_modules')
        for name in ('NODE-LICENSE', 'PI-LICENSE'):
            (self.agent / name).write_text('fixture license')
        node = self.agent / 'node'
        node.write_text('#!/bin/sh\nprintf "v24.18.0\\n"\n')
        node.chmod(0o755)

    def test_packaging_rejects_stale_bundled_schema(self):
        self.prepare_locked_agent()
        schema = self.agent / 'node_modules/@earendil-works/pi-schema/package.json'
        schema.write_text(json.dumps({'version': '1.3.0'}))
        with self.assertRaisesRegex(RuntimeError, 'Expected Pi 1.5.0: pi-schema'):
            payload.verify_agent(self.root, self.app)

    def test_packaging_rejects_node_without_npm(self):
        self.prepare_locked_agent()
        with self.assertRaisesRegex(RuntimeError, 'npm'):
            payload.verify_agent(self.root, self.app)

    def test_wrappers_use_adjacent_node_when_path_has_no_node(self):
        runtime = self.root / 'official node'
        npm = runtime / 'lib/node_modules/npm'
        (npm / 'bin').mkdir(parents=True)
        for name in ('npm-cli.js', 'npx-cli.js'):
            (npm / 'bin' / name).write_text('// synthetic CLI\n')
        (npm / 'package.json').write_text('{"version":"11.0.0"}')
        (npm / 'LICENSE').write_text('fixture npm license')
        result = subprocess.run(['/bin/bash', str(SCRIPTS / 'bundle_macos_node_tools.sh'),
                                 str(runtime), str(self.agent)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        node = self.agent / 'node'
        node.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        node.chmod(0o755)
        for command, script in (('npm', 'npm-cli.js'), ('npx', 'npx-cli.js')):
            result = subprocess.run([str(self.agent / command), '--version'],
                                    env={'PATH': '/usr/bin:/bin'}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(),
                             [str(self.agent / 'npm-runtime/bin' / script), '--version'])
            self.assertTrue(os.access(self.agent / command, os.X_OK))
        self.assertTrue((self.agent / 'npm-runtime/LICENSE').is_file())


if __name__ == '__main__':
    unittest.main()
