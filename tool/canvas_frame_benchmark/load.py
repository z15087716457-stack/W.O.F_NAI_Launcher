"""Low-frequency Windows load context; never reads process arguments or data."""
import argparse
import ctypes as c
from ctypes import wintypes as w
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import threading
import time


def utc():
    return datetime.now(timezone.utc).isoformat()


class WindowsCpu:
    def __init__(self):
        self.kernel = c.WinDLL('kernel32', use_last_error=True)
        self.psapi = c.WinDLL('psapi', use_last_error=True)
        self.kernel.OpenProcess.argtypes = [w.DWORD, w.BOOL, w.DWORD]
        self.kernel.OpenProcess.restype = w.HANDLE
        self.kernel.CloseHandle.argtypes = [w.HANDLE]
        self.kernel.GetProcessTimes.argtypes = [w.HANDLE] + [c.POINTER(w.FILETIME)] * 4
        self.kernel.QueryFullProcessImageNameW.argtypes = [w.HANDLE, w.DWORD, w.LPWSTR, c.POINTER(w.DWORD)]
        self.kernel.GetSystemTimes.argtypes = [c.POINTER(w.FILETIME)] * 3
        self.psapi.EnumProcesses.argtypes = [c.POINTER(w.DWORD), w.DWORD, c.POINTER(w.DWORD)]
        self.previous = self.snapshot()

    @staticmethod
    def ticks(value):
        return (value.dwHighDateTime << 32) | value.dwLowDateTime

    def snapshot(self):
        idle, kernel, user = w.FILETIME(), w.FILETIME(), w.FILETIME()
        if not self.kernel.GetSystemTimes(c.byref(idle), c.byref(kernel), c.byref(user)):
            raise c.WinError(c.get_last_error())
        pids, size = (w.DWORD * 8192)(), w.DWORD()
        if not self.psapi.EnumProcesses(pids, c.sizeof(pids), c.byref(size)):
            raise c.WinError(c.get_last_error())
        processes = {}
        for pid in pids[:size.value // c.sizeof(w.DWORD)]:
            handle = self.kernel.OpenProcess(0x1000, False, pid)
            if not handle:
                continue
            try:
                created, exited, pk, pu = (w.FILETIME() for _ in range(4))
                if not self.kernel.GetProcessTimes(handle, c.byref(created), c.byref(exited), c.byref(pk), c.byref(pu)):
                    continue
                name, length = c.create_unicode_buffer(32768), w.DWORD(32768)
                if not self.kernel.QueryFullProcessImageNameW(handle, 0, name, c.byref(length)):
                    continue
                processes[pid] = (Path(name.value).name, self.ticks(created), self.ticks(pk) + self.ticks(pu))
            finally:
                self.kernel.CloseHandle(handle)
        return (time.monotonic(), self.ticks(idle), self.ticks(kernel) + self.ticks(user), processes)

    def sample(self):
        now = self.snapshot()
        old, self.previous = self.previous, now
        elapsed = now[0] - old[0]
        total = now[2] - old[2]
        rows = []
        for pid, (name, created, ticks) in now[3].items():
            previous = old[3].get(pid)
            if previous and previous[1] == created:
                rows.append({'pid': pid, 'name': name, 'cpu_one_core_pct': round((ticks - previous[2]) / 1e7 / elapsed * 100, 2)})
        rows.sort(key=lambda row: row['cpu_one_core_pct'], reverse=True)
        relevant = [row for row in rows if any(key in row['name'].lower() for key in ('python', 'rag', 'nai_launcher'))]
        return {'utc': utc(), 'interval_s': round(elapsed, 3), 'cpu_total_pct': round((total - (now[1] - old[1])) / total * 100, 2), 'top_cpu': rows[:5], 'related_processes': relevant}


class LoadCapture:
    def __init__(self, prefix):
        self.cpu_path = Path(str(prefix) + '-cpu.json')
        self.gpu_path = Path(str(prefix) + '-gpu.csv')
        if self.cpu_path.exists() or self.gpu_path.exists():
            raise FileExistsError(prefix)
        self.cpu = WindowsCpu()
        self.samples = []
        self.started = utc()
        self.stop = threading.Event()

    def __enter__(self):
        self.gpu_log = self.gpu_path.open('w', encoding='utf-8')
        self.gpu = subprocess.Popen(['nvidia-smi', '--query-gpu=timestamp,utilization.gpu,utilization.memory,memory.used,temperature.gpu,clocks.gr,power.draw', '--format=csv,nounits', '--loop=2'], stdout=self.gpu_log, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
        self.thread = threading.Thread(target=self._sample, daemon=True)
        self.thread.start()
        return self

    def _sample(self):
        while not self.stop.wait(2):
            self.samples.append(self.cpu.sample())

    def __exit__(self, *exc):
        self.stop.set()
        self.thread.join()
        if self.gpu.poll() is None:
            self.gpu.terminate()
        self.gpu.wait(timeout=5)
        self.gpu_log.close()
        self.cpu_path.write_text(json.dumps({'started_utc': self.started, 'ended_utc': utc(), 'monitor_pid': os.getpid(), 'interval_target_s': 2, 'samples': self.samples}, indent=2), encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('prefix', type=Path)
    parser.add_argument('--seconds', type=int, default=12)
    args = parser.parse_args()
    with LoadCapture(args.prefix) as capture:
        time.sleep(args.seconds)
    print(json.dumps(capture.samples, indent=2))
