"""Opt-in native process ownership checks; no models or network requests."""
import ctypes
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import unittest

if sys.platform == 'win32':
    from ctypes import wintypes as w

SLEEPER = ("import os,subprocess,sys,time,json;"
           "c=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)']);"
           "print(json.dumps([os.getpid(),c.pid]),flush=True);time.sleep(60)")


@unittest.skipUnless(sys.platform == 'win32' and os.getenv('RAG_TEST_PYTHON'),
                     'Requires Windows and RAG_TEST_PYTHON')
class HostTests(unittest.TestCase):
    def setUp(self):
        self.host = Path(__file__).resolve().parents[2] / 'assets/rag/windows/stdio_host.exe'
        self.python = os.environ['RAG_TEST_PYTHON']
        self.k = ctypes.WinDLL('kernel32', use_last_error=True)
        self.k.OpenProcess.argtypes = [w.DWORD, w.BOOL, w.DWORD]
        self.k.OpenProcess.restype = w.HANDLE
        self.k.WaitForSingleObject.argtypes = [w.HANDLE, w.DWORD]
        self.k.WaitForSingleObject.restype = w.DWORD
        self.k.CloseHandle.argtypes = [w.HANDLE]

    def test_unicode_quotes_and_trailing_slashes_preserve_arguments(self):
        value = '雨🌧 "tag" \\'
        result = subprocess.run([str(self.host),str(os.getpid()),self.python,'-c',
            'import sys,json;print(json.dumps(sys.argv[1],ensure_ascii=False))',value],
            text=True,encoding='utf-8',capture_output=True,timeout=30,
            env={**os.environ,'PYTHONIOENCODING':'utf-8'})
        self.assertEqual(result.returncode,0)
        self.assertEqual(json.loads(result.stdout),value)

    def check_descendants(self, parent_disappears):
        parent = None; host = None; handles = []
        try:
            if parent_disappears:
                parent = subprocess.Popen(['cmd.exe','/d','/q','/c','set /p wait='],
                    stdin=subprocess.PIPE,stdout=subprocess.DEVNULL)
            host = subprocess.Popen([str(self.host),str(parent.pid if parent else os.getpid()),
                self.python,'-u','-c',SLEEPER],stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,text=True,encoding='utf-8')
            ids = json.loads(host.stdout.readline())
            handles = [self.k.OpenProcess(0x100000,False,i) for i in ids]
            self.assertTrue(all(handles))
            if parent:
                parent.kill();parent.wait(timeout=10)
            else: host.kill()
            host.wait(timeout=10)
            for handle in handles: self.assertEqual(self.k.WaitForSingleObject(handle,10000),0)
        finally:
            for process in (host,parent):
                if process:
                    if process.poll() is None: process.kill()
                    process.wait(timeout=10)
                    for stream in (process.stdin,process.stdout,process.stderr):
                        if stream: stream.close()
            for handle in handles:
                if handle: self.k.CloseHandle(handle)

    def test_host_kill_reclaims_python_and_grandchildren(self): self.check_descendants(False)
    def test_app_disappearance_reclaims_python_and_grandchildren(self): self.check_descendants(True)


@unittest.skipUnless(sys.platform == 'darwin' and os.getenv('RAG_TEST_HOST'),
                     'Requires macOS and RAG_TEST_HOST (a build of stdio_host.cpp)')
class PosixHostTests(unittest.TestCase):
    """The macOS build: a process group stands in for the Windows Job."""
    def setUp(self):
        self.host = os.environ['RAG_TEST_HOST']
        self.python = os.getenv('RAG_TEST_PYTHON') or sys.executable

    @staticmethod
    def gone(pid, timeout=10):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try: os.kill(pid, 0)
            except ProcessLookupError: return True
            time.sleep(0.02)
        return False

    def run_host(self, *arguments, **options):
        return subprocess.run([self.host, str(os.getpid()), *arguments], text=True,
            encoding='utf-8', capture_output=True, timeout=30,
            env={**os.environ, 'PYTHONIOENCODING': 'utf-8'}, **options)

    def test_arguments_stdin_and_exit_code_pass_through(self):
        value = '雨🌧 "tag" \\'
        result = self.run_host(self.python, '-c', 'import sys,json;'
            'print(json.dumps([sys.argv[1],sys.stdin.read()],ensure_ascii=False));sys.exit(7)',
            value, input='piped')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(json.loads(result.stdout), [value, 'piped'])

    def test_child_gets_default_stop_signals(self):
        result = self.run_host(self.python, '-c', 'import signal as s,json;'
            'print(json.dumps([s.getsignal(s.SIGTERM)==s.SIG_DFL,s.getsignal(s.SIGHUP)==s.SIG_DFL,'
            's.getsignal(s.SIGINT)==s.default_int_handler]))')
        self.assertEqual(json.loads(result.stdout), [True, True, True])

    def test_rejects_relative_executables_and_a_missing_app(self):
        self.assertEqual(self.run_host('python3', '-c', 'pass').returncode, 2)
        missing = subprocess.run([self.host, '99999999', self.python, '-c', 'pass'], timeout=30)
        self.assertEqual(missing.returncode, 3)

    def check_descendants(self, stop):
        parent = host = None
        try:
            if stop == 'app':
                parent = subprocess.Popen([sys.executable, '-c', 'import time;time.sleep(60)'])
            host = subprocess.Popen([self.host, str(parent.pid if parent else os.getpid()),
                self.python, '-u', '-c', SLEEPER], stdout=subprocess.PIPE, text=True)
            ids = json.loads(host.stdout.readline())
            if parent: parent.kill(); parent.wait(timeout=10)
            else: host.terminate()
            host.wait(timeout=10)
            for pid in ids: self.assertTrue(self.gone(pid), pid)
            return host.returncode
        finally:
            for process in (host, parent):
                if process:
                    if process.poll() is None: process.kill()
                    process.wait(timeout=10)
                    if process.stdout: process.stdout.close()

    def test_host_stop_reclaims_python_and_grandchildren(self):
        # The host ends on the same signal, as an unhosted child would.
        self.assertEqual(self.check_descendants('host'), -signal.SIGTERM)

    def test_app_disappearance_reclaims_python_and_grandchildren(self):
        self.assertEqual(self.check_descendants('app'), 130)

    def test_child_exit_reclaims_leftover_grandchildren(self):
        result = self.run_host(self.python, '-c', 'import subprocess,sys,json;'
            "c=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)']);"
            'print(json.dumps(c.pid),flush=True);sys.exit(5)')
        self.assertEqual(result.returncode, 5)
        self.assertTrue(self.gone(json.loads(result.stdout)))


if __name__ == '__main__': unittest.main()
