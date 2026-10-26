import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path
from typing import NamedTuple, Optional


ROOT = Path(__file__).resolve().parent
PLUGIN_NAME = "nai_launcher_bridge"
DESKTOP_NAME = f"{PLUGIN_NAME}.desktop"
MANIFEST_NAME = "install_manifest.json"
REQUIRED_DESKTOP_LINES = (
    "ServiceTypes=Krita/PythonPlugin",
    "X-KDE-Library=nai_launcher_bridge",
    "Name=NAI Launcher Bridge",
)
REQUIRED_PLUGIN_FILES = (
    ("plugin_init", "__init__.py"),
    ("plugin_entrypoint", "nai_launcher_bridge.py"),
    ("plugin_bootstrap", "plugin.py"),
    ("plugin_runtime", "bridge_dock.py"),
    ("plugin_ui", "ui.py"),
    ("plugin_bridge_client", "bridge_client.py"),
    ("plugin_canvas_io", "canvas_io.py"),
    ("plugin_protocol", "protocol.py"),
    ("plugin_canvas_utils", "canvas_utils.py"),
    ("plugin_diagnostics", "diagnostics.py"),
    ("plugin_discovery", "discovery.py"),
    ("plugin_fallback_websocket", "fallback_websocket.py"),
)


class InstallResult(NamedTuple):
    applied: bool
    pykrita_dir: Path
    kritarc_path: Path
    backup_dir: Path
    kritarc_backup: Optional[Path]
    actions: tuple[str, ...]


class ProfileCheck(NamedTuple):
    name: str
    ok: bool
    path: Path
    message: str


class ProfileCheckResult(NamedTuple):
    ok: bool
    checks: tuple[ProfileCheck, ...]


def default_pykrita_dir() -> Path:
    appdata = _profile_env_path("APPDATA")
    if appdata:
        return appdata / "krita" / "pykrita"
    return Path.home() / "AppData" / "Roaming" / "krita" / "pykrita"


def default_kritarc_path() -> Path:
    local_appdata = _profile_env_path("LOCALAPPDATA")
    if local_appdata:
        return local_appdata / "kritarc"
    return Path.home() / "AppData" / "Local" / "kritarc"


def default_backup_dir() -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return Path.cwd() / "build" / "krita_real_profile_backup" / stamp


def check_profile(*, pykrita_dir: Path, kritarc_path: Path) -> ProfileCheckResult:
    plugin_dir = pykrita_dir / PLUGIN_NAME
    checks = (
        _check_exists("desktop_file", pykrita_dir / DESKTOP_NAME),
        _check_desktop_manifest(pykrita_dir / DESKTOP_NAME),
        _check_exists("plugin_dir", plugin_dir),
        *(
            _check_plugin_file_matches_source(
                check_name,
                plugin_dir / relative_path,
                ROOT / PLUGIN_NAME / relative_path,
            )
            for check_name, relative_path in REQUIRED_PLUGIN_FILES
        ),
        _check_exists("kritarc_file", kritarc_path),
        _check_kritarc_enabled(kritarc_path),
    )
    return ProfileCheckResult(
        ok=all(check.ok for check in checks),
        checks=checks,
    )


def install_plugin(
    *,
    pykrita_dir: Path,
    kritarc_path: Path,
    backup_dir: Path,
    apply: bool,
    krita_running: Optional[bool] = None,
    allow_running_krita: bool = False,
) -> InstallResult:
    source_desktop = ROOT / DESKTOP_NAME
    source_plugin = ROOT / PLUGIN_NAME
    if not source_desktop.exists() or not source_plugin.exists():
        raise FileNotFoundError("Krita plugin source layout is incomplete")

    actions = ["copy_plugin", "enable_kritarc"]
    kritarc_backup = backup_dir / "kritarc" if kritarc_path.exists() else None

    if not apply:
        return InstallResult(
            applied=False,
            pykrita_dir=pykrita_dir,
            kritarc_path=kritarc_path,
            backup_dir=backup_dir,
            kritarc_backup=kritarc_backup,
            actions=tuple(actions),
        )

    _ensure_krita_not_running(
        krita_running=krita_running,
        allow_running_krita=allow_running_krita,
    )

    backup_dir.mkdir(parents=True, exist_ok=True)
    pykrita_dir.mkdir(parents=True, exist_ok=True)
    _write_install_manifest(
        backup_dir=backup_dir,
        pykrita_dir=pykrita_dir,
        kritarc_path=kritarc_path,
    )

    _backup_existing(pykrita_dir / DESKTOP_NAME, backup_dir / DESKTOP_NAME)
    _backup_existing(pykrita_dir / PLUGIN_NAME, backup_dir / PLUGIN_NAME)
    if kritarc_path.exists():
        _backup_existing(kritarc_path, backup_dir / "kritarc")

    shutil.copy2(source_desktop, pykrita_dir / DESKTOP_NAME)
    destination_plugin = pykrita_dir / PLUGIN_NAME
    if destination_plugin.exists():
        shutil.rmtree(destination_plugin)
    shutil.copytree(
        source_plugin,
        destination_plugin,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
    )

    kritarc_path.parent.mkdir(parents=True, exist_ok=True)
    existing_kritarc = (
        kritarc_path.read_text(encoding="utf-8") if kritarc_path.exists() else ""
    )
    kritarc_path.write_text(
        _enable_plugin_in_kritarc(existing_kritarc),
        encoding="utf-8",
    )

    return InstallResult(
        applied=True,
        pykrita_dir=pykrita_dir,
        kritarc_path=kritarc_path,
        backup_dir=backup_dir,
        kritarc_backup=kritarc_backup,
        actions=tuple(actions),
    )


def restore_profile(
    *,
    pykrita_dir: Path,
    kritarc_path: Path,
    backup_dir: Path,
    apply: bool,
    krita_running: Optional[bool] = None,
    allow_running_krita: bool = False,
) -> InstallResult:
    manifest_path = backup_dir / MANIFEST_NAME
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing restore manifest: {manifest_path}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if (
        not isinstance(manifest, dict)
        or manifest.get("plugin_name") != PLUGIN_NAME
        or manifest.get("desktop_name") != DESKTOP_NAME
        or any(type(manifest.get(key)) is not bool
               for key in ("had_desktop", "had_plugin_dir", "had_kritarc"))
    ):
        raise ValueError(f"Invalid restore manifest: {manifest_path}")
    actions = ["restore_profile"]
    kritarc_backup = backup_dir / "kritarc" if manifest.get("had_kritarc") else None
    if not apply:
        return InstallResult(
            applied=False,
            pykrita_dir=pykrita_dir,
            kritarc_path=kritarc_path,
            backup_dir=backup_dir,
            kritarc_backup=kritarc_backup,
            actions=tuple(actions),
        )

    _ensure_krita_not_running(
        krita_running=krita_running,
        allow_running_krita=allow_running_krita,
    )

    _restore_paths((
        (backup_dir / DESKTOP_NAME, pykrita_dir / DESKTOP_NAME,
         manifest["had_desktop"], False),
        (backup_dir / PLUGIN_NAME, pykrita_dir / PLUGIN_NAME,
         manifest["had_plugin_dir"], True),
        (backup_dir / "kritarc", kritarc_path, manifest["had_kritarc"], False),
    ))

    return InstallResult(
        applied=True,
        pykrita_dir=pykrita_dir,
        kritarc_path=kritarc_path,
        backup_dir=backup_dir,
        kritarc_backup=kritarc_backup,
        actions=tuple(actions),
    )


def _check_exists(name: str, path: Path) -> ProfileCheck:
    ok = path.exists()
    return ProfileCheck(
        name=name,
        ok=ok,
        path=path,
        message="found" if ok else "missing",
    )


def _check_plugin_file_matches_source(
    name: str,
    installed_path: Path,
    source_path: Path,
) -> ProfileCheck:
    if not installed_path.exists():
        return ProfileCheck(
            name=name,
            ok=False,
            path=installed_path,
            message="missing",
        )
    if not source_path.exists():
        return ProfileCheck(
            name=name,
            ok=False,
            path=installed_path,
            message=f"source missing: {source_path}",
        )
    if installed_path.read_bytes() != source_path.read_bytes():
        return ProfileCheck(
            name=name,
            ok=False,
            path=installed_path,
            message="stale; differs from source",
        )
    return ProfileCheck(
        name=name,
        ok=True,
        path=installed_path,
        message="matches source",
    )


def _check_desktop_manifest(path: Path) -> ProfileCheck:
    if not path.exists():
        return ProfileCheck(
            name="desktop_manifest",
            ok=False,
            path=path,
            message="desktop file missing",
        )
    content = path.read_text(encoding="utf-8")
    missing = [line for line in REQUIRED_DESKTOP_LINES if line not in content]
    return ProfileCheck(
        name="desktop_manifest",
        ok=not missing,
        path=path,
        message="found" if not missing else "missing " + ", ".join(missing),
    )


def _check_kritarc_enabled(kritarc_path: Path) -> ProfileCheck:
    if not kritarc_path.exists():
        return ProfileCheck(
            name="kritarc_enabled",
            ok=False,
            path=kritarc_path,
            message="kritarc missing",
        )
    enabled = _kritarc_has_enabled_plugin(kritarc_path.read_text(encoding="utf-8"))
    return ProfileCheck(
        name="kritarc_enabled",
        ok=enabled,
        path=kritarc_path,
        message="enabled" if enabled else "not enabled",
    )


def _ensure_krita_not_running(
    *,
    krita_running: Optional[bool],
    allow_running_krita: bool,
) -> None:
    if allow_running_krita:
        return
    if _resolve_krita_running(krita_running):
        raise RuntimeError(
            "Krita is running. Close Krita before applying profile changes, "
            "or pass --allow-running-krita if you have confirmed it is safe.",
        )


def _resolve_krita_running(krita_running: Optional[bool]) -> bool:
    if krita_running is not None:
        return krita_running
    return is_krita_running()


def is_krita_running() -> bool:
    try:
        completed = subprocess.run(
            ["cmd.exe", "/c", "tasklist /FI \"IMAGENAME eq krita.exe\""],
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return "krita.exe" in completed.stdout.lower()


def _kritarc_has_enabled_plugin(content: str) -> bool:
    lines = content.splitlines(keepends=True)
    python_start = _find_section(lines, "python")
    if python_start is None:
        return False
    section_end = _find_section_end(lines, python_start)
    setting_index = _find_setting(lines, python_start + 1, section_end)
    if setting_index is None:
        return False
    return lines[setting_index].split("=", 1)[1].strip().lower() == "true"


def _write_install_manifest(
    *,
    backup_dir: Path,
    pykrita_dir: Path,
    kritarc_path: Path,
) -> None:
    manifest = {
        "plugin_name": PLUGIN_NAME,
        "desktop_name": DESKTOP_NAME,
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "pykrita_dir": str(pykrita_dir),
        "kritarc_path": str(kritarc_path),
        "had_desktop": (pykrita_dir / DESKTOP_NAME).exists(),
        "had_plugin_dir": (pykrita_dir / PLUGIN_NAME).exists(),
        "had_kritarc": kritarc_path.exists(),
    }
    (backup_dir / MANIFEST_NAME).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def _backup_existing(source: Path, destination: Path) -> None:
    if not source.exists():
        return
    if destination.exists():
        if destination.is_dir():
            shutil.rmtree(destination)
        else:
            destination.unlink()
    if source.is_dir():
        shutil.copytree(
            source,
            destination,
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
        )
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def _restore_paths(paths: tuple[tuple[Path, Path, bool, bool], ...]) -> None:
    # 整套备份先检查、复制到目标同盘的暂存区，再移动当前版本。
    for backup, target, had_original, directory in paths:
        if had_original and not (backup.is_dir() if directory else backup.is_file()):
            kind = "directory" if directory else "file"
            raise FileNotFoundError(f"Missing backup {kind}: {backup}")
        if target.resolve() == backup.resolve() or target.resolve() in backup.resolve().parents:
            raise ValueError(f"Backup overlaps restore target: {backup}")

    staged = []
    moved_current = []
    installed = []
    preserve_staging = False
    try:
        for backup, target, had_original, directory in paths:
            target.parent.mkdir(parents=True, exist_ok=True)
            stage = Path(tempfile.mkdtemp(prefix=".restore-", dir=target.parent))
            staged.append((target, stage, had_original))
            if had_original:
                if directory:
                    shutil.copytree(backup, stage / "replacement")
                else:
                    shutil.copy2(backup, stage / "replacement")

        for target, stage, had_original in staged:
            if target.exists():
                current = stage / "current"
                target.rename(current)
                moved_current.append((target, current))
            if had_original:
                (stage / "replacement").rename(target)
                installed.append(target)
    except Exception as error:
        try:
            for target in reversed(installed):
                _remove_path(target)
            for target, current in reversed(moved_current):
                current.rename(target)
        except Exception as rollback_error:
            preserve_staging = True
            locations = ", ".join(str(stage) for _, stage, _ in staged)
            raise RuntimeError(
                f"Restore failed ({error}); rollback failed ({rollback_error}); "
                f"current files preserved at: {locations}"
            ) from error
        raise
    finally:
        if not preserve_staging:
            for _, stage, _ in staged:
                shutil.rmtree(stage)


def _remove_path(path: Path) -> None:
    if not path.exists():
        return
    if path.is_dir():
        shutil.rmtree(path)
    else:
        path.unlink()


def _enable_plugin_in_kritarc(content: str) -> str:
    lines = content.splitlines(keepends=True)
    python_start = _find_section(lines, "python")
    if python_start is None:
        prefix = "" if not content or content.endswith(("\n", "\r")) else "\n"
        return f"{content}{prefix}[python]\nenable_nai_launcher_bridge=true\n"

    section_end = _find_section_end(lines, python_start)
    setting_index = _find_setting(lines, python_start + 1, section_end)
    if setting_index is not None:
        lines[setting_index] = "enable_nai_launcher_bridge=true\n"
    else:
        lines.insert(section_end, "enable_nai_launcher_bridge=true\n")
    return "".join(lines)


def _find_section(lines: list[str], name: str) -> Optional[int]:
    expected = f"[{name}]"
    for index, line in enumerate(lines):
        if line.strip().lower() == expected:
            return index
    return None


def _find_section_end(lines: list[str], section_start: int) -> int:
    for index in range(section_start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            return index
    return len(lines)


def _find_setting(lines: list[str], start: int, end: int) -> Optional[int]:
    for index in range(start, end):
        key = lines[index].split("=", 1)[0].strip().lower()
        if key == "enable_nai_launcher_bridge":
            return index
    return None


def _profile_env_path(name: str) -> Optional[Path]:
    value = os.environ.get(name)
    if value:
        return Path(value)
    if not os.environ.get("WSL_DISTRO_NAME"):
        return None

    windows_value = _read_windows_env_path(name)
    if not windows_value:
        return None
    return _windows_path_to_wsl_path(windows_value)


def _read_windows_env_path(name: str) -> Optional[str]:
    try:
        completed = subprocess.run(
            ["cmd.exe", "/c", f"echo %{name}%"],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    value = completed.stdout.strip()
    if completed.returncode != 0 or not value or value == f"%{name}%":
        return None
    return value


def _windows_path_to_wsl_path(path: str) -> Path:
    match = re.match(r"^([A-Za-z]):[\\/](.*)$", path)
    if not match:
        return Path(path.replace("\\", "/"))
    drive = match.group(1).lower()
    tail = match.group(2).replace("\\", "/")
    return Path(f"/mnt/{drive}/{tail}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install and enable the NAI Launcher Bridge Krita plugin.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="check profile layout and enable flag without writing files",
    )
    parser.add_argument("--apply", action="store_true", help="write profile files")
    parser.add_argument(
        "--restore",
        action="store_true",
        help="restore profile files from --backup-dir; combine with --apply to write",
    )
    parser.add_argument(
        "--allow-running-krita",
        action="store_true",
        help="allow writes while krita.exe is running after manual confirmation",
    )
    parser.add_argument("--pykrita-dir", type=Path, default=default_pykrita_dir())
    parser.add_argument("--kritarc", type=Path, default=default_kritarc_path())
    parser.add_argument("--backup-dir", type=Path, default=default_backup_dir())
    args = parser.parse_args()

    if args.check:
        result = check_profile(
            pykrita_dir=args.pykrita_dir,
            kritarc_path=args.kritarc,
        )
        _print_profile_check(result)
        return 0 if result.ok else 1

    if args.restore:
        result = restore_profile(
            pykrita_dir=args.pykrita_dir,
            kritarc_path=args.kritarc,
            backup_dir=args.backup_dir,
            apply=args.apply,
            allow_running_krita=args.allow_running_krita,
        )
        mode = "restored" if result.applied else "restore-dry-run"
        print(f"mode={mode}")
        print(f"pykrita_dir={result.pykrita_dir}")
        print(f"kritarc_path={result.kritarc_path}")
        print(f"backup_dir={result.backup_dir}")
        print(f"actions={','.join(result.actions)}")
        if result.kritarc_backup is not None:
            print(f"kritarc_backup={result.kritarc_backup}")
        return 0

    result = install_plugin(
        pykrita_dir=args.pykrita_dir,
        kritarc_path=args.kritarc,
        backup_dir=args.backup_dir,
        apply=args.apply,
        allow_running_krita=args.allow_running_krita,
    )

    mode = "applied" if result.applied else "dry-run"
    print(f"mode={mode}")
    print(f"pykrita_dir={result.pykrita_dir}")
    print(f"kritarc_path={result.kritarc_path}")
    print(f"backup_dir={result.backup_dir}")
    print(f"actions={','.join(result.actions)}")
    if result.kritarc_backup is not None:
        print(f"kritarc_backup={result.kritarc_backup}")
    if result.applied:
        profile = check_profile(
            pykrita_dir=result.pykrita_dir,
            kritarc_path=result.kritarc_path,
        )
        _print_profile_check(profile)
        return 0 if profile.ok else 1
    return 0


def _print_profile_check(result: ProfileCheckResult) -> None:
    print(f"profile_ok={str(result.ok).lower()}")
    for check in result.checks:
        status = "ok" if check.ok else "fail"
        print(f"{check.name}={status} path={check.path} message={check.message}")


if __name__ == "__main__":
    raise SystemExit(main())
