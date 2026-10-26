"""Run a copied batch wrapper with native, harmless executable substitutes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(os.name == 'nt', 'Windows batch behavior')
class PreflightExitTests(unittest.TestCase):
    def run_wrapper(self, *, py=False, python=False, source=False):
        with tempfile.TemporaryDirectory(prefix='preflight_exit_') as temp:
            root = Path(temp)
            scripts = root / 'scripts'
            scripts.mkdir()
            wrapper = scripts / 'krita_bridge_preflight.bat'
            wrapper.write_bytes((ROOT / 'scripts' / wrapper.name).read_bytes())
            system = Path(os.environ['SystemRoot']) / 'System32'
            if py:
                # where.exe rejects -3 without invoking Python or preflight.
                shutil.copy2(system / 'where.exe', root / 'py.exe')
            if python:
                # sort.exe reads only the disposable input file, never executes it.
                shutil.copy2(system / 'sort.exe', root / 'python.exe')
            # Never let the no-Python case start the machine's actual WSL.
            shutil.copy2(system / 'where.exe', root / 'wsl.exe')
            if source:
                (root / 'krita_plugin').mkdir()
                (root / 'krita_plugin/preflight.py').write_text(
                    "print('fixture preflight input')\n", encoding='ascii')
            env = dict(os.environ, PATH=str(root) + os.pathsep + str(system))
            result = subprocess.run(
                [env.get('COMSPEC', 'cmd.exe'), '/d', '/c', str(wrapper)],
                cwd=root, env=env, capture_output=True, timeout=15,
                stdin=subprocess.DEVNULL,
            )
            return result.returncode, result.stdout.decode('utf-8', errors='replace')

    def test_failed_py_command_is_reported_as_failure(self):
        code, output = self.run_wrapper(py=True)
        self.assertNotEqual(code, 0)
        self.assertIn('[ERROR] Krita Bridge preflight failed', output)
        self.assertNotIn('[OK]', output)

    def test_python_is_found_after_py_is_absent_and_success_is_preserved(self):
        code, output = self.run_wrapper(python=True, source=True)
        self.assertEqual(code, 0, output)
        self.assertIn('fixture preflight input', output)
        self.assertIn('[OK] Krita Bridge preflight finished.', output)

    def test_failed_python_command_is_reported_as_failure(self):
        code, output = self.run_wrapper(python=True)
        self.assertNotEqual(code, 0)
        self.assertIn('[ERROR] Krita Bridge preflight failed', output)
        self.assertNotIn('[OK]', output)

    def test_missing_python_and_failed_wsl_discovery_returns_failure(self):
        code, output = self.run_wrapper()
        self.assertEqual(code, 1)
        self.assertIn('[ERROR] Python was not found', output)


if __name__ == '__main__':
    unittest.main()
