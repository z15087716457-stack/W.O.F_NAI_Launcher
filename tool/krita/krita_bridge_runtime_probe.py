import json
import os
import time
import traceback
from pathlib import Path


def _report_path() -> Path:
    appdata = os.environ.get("APPDATA")
    if appdata:
        base = Path(appdata)
    else:
        base = Path.home() / "AppData" / "Roaming"
    target = base / "nai-launcher"
    target.mkdir(parents=True, exist_ok=True)
    return target / "krita-bridge-runtime-probe.json"


def _process_events(seconds: float) -> None:
    try:
        from PyQt5.QtWidgets import QApplication

        app = QApplication.instance()
        if app is None:
            return
        deadline = time.time() + seconds
        while time.time() < deadline:
            app.processEvents()
            time.sleep(0.05)
    except Exception:
        return


def _set_selection(doc, x: int, y: int, width: int, height: int) -> None:
    from krita import Selection

    selection = Selection()
    selection.select(x, y, width, height, 255)
    doc.setSelection(selection)
    doc.refreshProjection()


def _make_probe_document(payload: dict):
    from krita import Krita

    app = Krita.instance()
    doc = app.createDocument(
        128,
        128,
        "NAI Bridge Runtime Probe",
        "RGBA",
        "U8",
        "",
        120.0,
    )
    payload["created_document"] = doc is not None
    window = app.activeWindow()
    payload["active_window"] = window is not None
    if doc is not None and window is not None:
        window.addView(doc)
        _process_events(0.5)
        _set_selection(doc, 16, 16, 64, 64)
        _process_events(0.5)
    return doc


def __main__(*args) -> None:
    payload = {
        "ok": False,
        "checks": [],
    }
    try:
        from krita import Krita
        from nai_launcher_bridge import diagnostics
        from nai_launcher_bridge.ui import NAILauncherBridgeDocker

        app = Krita.instance()
        payload["krita_instance"] = app is not None

        _make_probe_document(payload)
        docker = NAILauncherBridgeDocker()
        try:
            payload["docker_title"] = docker.windowTitle()
            payload["connect_button"] = docker._connect_button.text()
            payload["diagnostics_button"] = docker._diagnostics_button.text()
            payload["initial_status"] = docker._status.text()
            _process_events(3.0)
            payload["connected"] = docker._client.is_connected
            payload["status_after_events"] = docker._status.text()
        finally:
            try:
                docker._client.stop()
            except Exception:
                pass
            try:
                docker.deleteLater()
            except Exception:
                pass

        report = diagnostics.run_diagnostics(write_report=True)
        payload["diagnostics_summary"] = report.get("summary")
        payload["diagnostics_report_path"] = report.get("report_path")
        payload["checks"] = report.get("checks", [])
        payload["ok"] = True
    except Exception:
        payload["error"] = traceback.format_exc()

    _report_path().write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    __main__()
