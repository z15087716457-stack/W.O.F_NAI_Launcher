import json
import os
import ctypes
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class BridgeDiscovery:
    port: int
    secret: str
    pid: Optional[int] = None
    version: Optional[int] = None
    started_at: Optional[str] = None

    @property
    def url(self) -> str:
        return f"ws://127.0.0.1:{self.port}/krita"


def discovery_file_path() -> Path:
    # Same lookup order as the Launcher (lib/core/krita/krita_bridge_server.dart):
    # %APPDATA%/nai-launcher when APPDATA is set, otherwise ~/.nai-launcher on
    # macOS and Linux.
    app_data = os.environ.get("APPDATA")
    if app_data:
        return Path(app_data) / "nai-launcher" / "krita-bridge.json"
    if _is_windows():
        return Path.home() / "AppData" / "Roaming" / "nai-launcher" / "krita-bridge.json"
    return Path.home() / ".nai-launcher" / "krita-bridge.json"


def _is_windows() -> bool:
    return os.name == "nt"


def load_discovery(path: Optional[Path] = None) -> BridgeDiscovery:
    source = path or discovery_file_path()
    with source.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    port = int(data["port"])
    raw_secret = data.get("secret")
    if raw_secret is None:
        raise ValueError("Bridge discovery file is missing secret")
    secret = str(raw_secret)
    if not secret:
        raise ValueError("Bridge discovery file has an empty secret")
    pid = data.get("pid")
    started_at = data.get("started_at")
    if pid is not None:
        pid = int(pid)
        if not _pid_is_alive(pid):
            raise ValueError("Bridge discovery file points to a stopped Launcher")
        if not started_at:
            raise ValueError("Bridge discovery file is missing start time")
        if not _process_started_at_matches(pid, str(started_at)):
            raise ValueError("Bridge discovery file start time is stale")

    return BridgeDiscovery(
        port=port,
        secret=secret,
        pid=pid,
        version=data.get("version"),
        started_at=started_at,
    )


def _pid_is_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        return _windows_pid_is_alive(pid)

    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False
    return True


def _windows_pid_is_alive(pid: int) -> bool:
    kernel32 = ctypes.windll.kernel32
    process_query_limited_information = 0x1000
    synchronize = 0x00100000
    wait_timeout = 0x00000102

    handle = kernel32.OpenProcess(
        process_query_limited_information | synchronize,
        False,
        pid,
    )
    if not handle:
        return False

    try:
        return kernel32.WaitForSingleObject(handle, 0) == wait_timeout
    finally:
        kernel32.CloseHandle(handle)


def _process_started_at_matches(pid: int, discovery_started_at: str) -> bool:
    discovery_time = _parse_discovery_time(discovery_started_at)
    if discovery_time is None:
        return False

    process_time = _process_started_at(pid)
    if process_time is None:
        return True

    # The bridge can start after the Launcher process. A reused PID with a
    # stale discovery file will have a process start time later than this file.
    return process_time <= discovery_time + timedelta(seconds=5)


def _parse_discovery_time(value: str) -> Optional[datetime]:
    try:
        normalized = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _process_started_at(pid: int) -> Optional[datetime]:
    if os.name == "nt":
        return _windows_process_started_at(pid)
    return _procfs_process_started_at(pid)


def _windows_process_started_at(pid: int) -> Optional[datetime]:
    kernel32 = ctypes.windll.kernel32
    process_query_limited_information = 0x1000
    handle = kernel32.OpenProcess(process_query_limited_information, False, pid)
    if not handle:
        return None

    class FILETIME(ctypes.Structure):
        _fields_ = [
            ("dwLowDateTime", ctypes.c_uint32),
            ("dwHighDateTime", ctypes.c_uint32),
        ]

    created = FILETIME()
    exited = FILETIME()
    kernel = FILETIME()
    user = FILETIME()
    try:
        ok = kernel32.GetProcessTimes(
            handle,
            ctypes.byref(created),
            ctypes.byref(exited),
            ctypes.byref(kernel),
            ctypes.byref(user),
        )
        if not ok:
            return None
        ticks = (created.dwHighDateTime << 32) + created.dwLowDateTime
        unix_seconds = ticks / 10_000_000 - 11644473600
        return datetime.fromtimestamp(unix_seconds, tz=timezone.utc)
    finally:
        kernel32.CloseHandle(handle)


def _procfs_process_started_at(pid: int) -> Optional[datetime]:
    try:
        stat_fields = Path(f"/proc/{pid}/stat").read_text(encoding="utf-8").split()
        start_ticks = int(stat_fields[21])
        ticks_per_second = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
        boot_time = _procfs_boot_time()
    except (OSError, ValueError, IndexError, KeyError):
        return None
    if boot_time is None:
        return None
    return boot_time + timedelta(seconds=start_ticks / ticks_per_second)


def _procfs_boot_time() -> Optional[datetime]:
    try:
        for line in Path("/proc/stat").read_text(encoding="utf-8").splitlines():
            if line.startswith("btime "):
                return datetime.fromtimestamp(int(line.split()[1]), tz=timezone.utc)
    except (OSError, ValueError, IndexError):
        return None
    return None
