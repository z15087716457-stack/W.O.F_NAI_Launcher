"""Opt-in native process ownership checks; no models or network requests."""
import ctypes
from ctypes import wintypes as w
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest


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
            code = ("import os,subprocess,sys,time,json;"
                    "c=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)']);"
                    "print(json.dumps([os.getpid(),c.pid]),flush=True);time.sleep(60)")
            host = subprocess.Popen([str(self.host),str(parent.pid if parent else os.getpid()),
                self.python,'-u','-c',code],stdin=subprocess.PIPE,stdout=subprocess.PIPE,
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


if __name__ == '__main__': unittest.main()
