import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    'release_payload', Path(__file__).resolve().parents[2] / 'scripts/windows_release_payload.py',
)
payload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(payload)


class AgentPayloadTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='wof-payload-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'tool/nai_agent'
        self.runtime = self.root / 'runtime'
        self.runtime.mkdir()
        self.packages = {}
        for name in ('pi-agent-core', 'pi-ai', 'pi-codemode', 'pi-coding-agent', 'pi-mcp', 'pi-schema', 'pi-telemetry', 'pi-tui'):
            key = f'node_modules/@earendil-works/{name}'
            self.write(self.source / key / 'package.json', {'version': '1.5.0'})
            self.packages[key] = {'version': '1.5.0'}
        self.write(self.source / 'package-lock.json', {'packages': {'': {}, **self.packages}})
        self.write(self.source / 'node_modules/.package-lock.json', {'packages': self.packages})
        for name in ('node.exe', 'NODE-LICENSE', 'PI-LICENSE'):
            (self.runtime / name).write_text('fixture', encoding='utf-8')

    def write(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value), encoding='utf-8')

    def test_accepts_the_locked_pi_version_instead_of_an_old_release_pin(self):
        with patch.object(payload.subprocess, 'check_output', return_value='v24.18.0\n'):
            payload.verify_agent(self.root, self.runtime)

    def test_rejects_a_schema_package_that_does_not_match_the_lock(self):
        self.write(self.source / 'node_modules/@earendil-works/pi-schema/package.json', {'version': '1.3.0'})
        with self.assertRaisesRegex(RuntimeError, 'Expected Pi 1.5.0: pi-schema'):
            payload.verify_agent(self.root, self.runtime)

    def test_package_metadata_reports_the_actual_bundled_pi_version(self):
        destination = self.root / 'package'
        self.write(destination / 'tools/nai-agent/node_modules/@earendil-works/pi-coding-agent/package.json', {'version': '1.5.0'})
        self.write(destination / 'data/app.so', {})
        self.write(self.root / 'flutter.json', {'frameworkVersion': '3.47.7', 'dartSdkVersion': '3.13.5'})
        self.write(self.root / 'crt.json', [])
        with patch.object(payload.subprocess, 'check_output', side_effect=['v24.18.0\n', 'fixture-commit\n']):
            payload.finish(self.root, destination, '2.2.5+80', '2.2.5', self.root / 'flutter.json', self.root / 'crt.json')
        info = json.loads((destination / 'package-info.json').read_text(encoding='utf-8'))
        self.assertEqual(info['piVersion'], '1.5.0')
        self.assertEqual(info['buildVersion'], '2.2.5+80')


if __name__ == '__main__':
    unittest.main()
