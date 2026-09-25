import argparse
import json
import sys
from pathlib import Path
from typing import Any, NamedTuple, Optional

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import install_plugin

DIAGNOSTICS_SCHEMA_VERSION = 1
DIAGNOSTICS_PLUGIN_NAME = "nai_launcher_bridge"


class Gate(NamedTuple):
    name: str
    status: str
    detail: str
    evidence: str = ""


class AcceptanceReport(NamedTuple):
    ok: bool
    gates: tuple[Gate, ...]


MANUAL_GATES: tuple[tuple[str, str], ...] = (
    (
        "plugin_manager_visible",
        "NAI Launcher Bridge appears in Krita's Python Plugin Manager after install.",
    ),
    (
        "launcher_settings_toggle",
        "Launcher bridge can be enabled and disabled from settings.",
    ),
    (
        "auto_discovery_connect",
        "Krita connects through the discovery file without copying tokens or ports manually.",
    ),
    (
        "auth_failure_safe",
        "Wrong session secret fails without crashing or exposing account/token data.",
    ),
    (
        "img2img_e2e",
        "Krita can send the active canvas to Launcher img2img and receive a result.",
    ),
    (
        "inpaint_e2e",
        "Krita can send selection/mask inpaint through Launcher and receive a result.",
    ),
    (
        "krita_cancel_e2e",
        "Krita cancel stops the active bridge generation and clears preview state.",
    ),
    (
        "no_selection_behavior",
        "No-selection behavior is clear: whole canvas img2img or explicit inpaint message.",
    ),
    (
        "large_canvas_rejected",
        "Canvas above V1 bounds is rejected before any generation request.",
    ),
    (
        "disconnect_generation_safe",
        "Disconnect during generation surfaces an error and never writes partial output as final.",
    ),
    (
        "preview_throttle",
        "Streaming preview updates stay within the agreed throttle interval.",
    ),
    (
        "result_layer_aligned",
        "Final result appears as an aligned Krita layer with expected dimensions and alpha.",
    ),
    (
        "launcher_history_recorded",
        "Launcher history records the generated final image and key params.",
    ),
    (
        "novelai_token_launcher_only",
        "NovelAI token remains only inside Launcher and is not sent to Krita.",
    ),
    (
        "bridge_rejects_unauthenticated",
        "Bridge refuses unauthenticated local clients.",
    ),
    (
        "gallery_send_e2e",
        "Generation/gallery send-to-Krita action reaches an authenticated Krita connection.",
    ),
    (
        "disabled_bridge_existing_flows",
        "Existing generation, gallery, and Vibe flows keep working when the bridge is disabled.",
    ),
)
KNOWN_MANUAL_EVIDENCE_KEYS = {
    "plugin_manager_visible",
    "docker_visible",
    *(name for name, _detail in MANUAL_GATES),
}


def default_diagnostics_path() -> Path:
    appdata = install_plugin._profile_env_path("APPDATA")
    if appdata:
        return appdata / "nai-launcher" / "krita-bridge-diagnostics.json"
    return Path.home() / "AppData" / "Roaming" / "nai-launcher" / "krita-bridge-diagnostics.json"


def load_diagnostics(path: Path) -> Optional[dict[str, Any]]:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def load_manual_evidence(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Manual evidence file must contain a JSON object")
    _validate_evidence_keys(data, path, KNOWN_MANUAL_EVIDENCE_KEYS)
    _validate_manual_evidence_notes(data, path)
    return data


def load_automation_evidence(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Automation evidence file must contain a JSON object")
    _validate_evidence_keys(data, path, KNOWN_MANUAL_EVIDENCE_KEYS)
    return data


def build_acceptance_report(
    *,
    profile: install_plugin.ProfileCheckResult,
    diagnostics: Optional[dict[str, Any]],
    diagnostics_path: Path,
    manual_evidence: Optional[dict[str, Any]] = None,
    automation_evidence: Optional[dict[str, Any]] = None,
) -> AcceptanceReport:
    diagnostics_schema_error = _diagnostics_schema_error(diagnostics)
    by_name = _diagnostic_checks_by_name(
        diagnostics if diagnostics_schema_error is None else None,
    )
    manual_evidence = manual_evidence or {}
    automation_evidence = automation_evidence or {}
    gates = [
        Gate(
            "profile_installed_enabled",
            "pass" if profile.ok else "fail",
            "Krita profile contains plugin layout and enable flag."
            if profile.ok
            else _profile_failure_detail(profile),
        ),
        Gate(
            "diagnostics_report",
            _diagnostics_report_status(diagnostics, diagnostics_schema_error),
            f"Diagnostics report found at {diagnostics_path}"
            if diagnostics is not None and diagnostics_schema_error is None
            else (
                f"Run Diagnostics in the Krita docker to create {diagnostics_path}"
                if diagnostics is None
                else diagnostics_schema_error
            ),
        ),
        _diagnostic_gate(
            by_name,
            "launcher_discovery",
            "Launcher discovery file is usable.",
        ),
        _diagnostic_gate(
            by_name,
            "active_document",
            "Krita has an active document for canvas validation.",
        ),
        _diagnostic_gate(
            by_name,
            "canvas_png_round_trip",
            "Krita canvas PNG export and layer writeback passed.",
        ),
        _diagnostic_gate(
            by_name,
            "selection_and_masks",
            "Krita selection mask source is available.",
        ),
        _manual_gate(
            manual_evidence,
            automation_evidence,
            "plugin_manager_visible",
            "NAI Launcher Bridge appears in Krita's Python Plugin Manager after install.",
        ),
        Gate(
            "docker_visible",
            _docker_visible_status(manual_evidence, diagnostics),
            "Confirm Settings > Dockers > NAI Launcher Bridge is visible in the real Krita UI.",
            _gate_evidence(manual_evidence, automation_evidence, "docker_visible"),
        ),
    ]
    gates.extend(
        _manual_gate(manual_evidence, automation_evidence, name, detail)
        for name, detail in MANUAL_GATES
        if name != "plugin_manager_visible"
    )
    return AcceptanceReport(
        ok=all(gate.status == "pass" for gate in gates),
        gates=tuple(gates),
    )


def format_report(report: AcceptanceReport) -> str:
    lines = [f"acceptance_ok={str(report.ok).lower()}"]
    for gate in report.gates:
        evidence = f" evidence={gate.evidence}" if gate.evidence else ""
        lines.append(f"{gate.name}={gate.status} detail={gate.detail}{evidence}")
    return "\n".join(lines)


def report_to_dict(report: AcceptanceReport) -> dict[str, Any]:
    return {
        "acceptance_ok": report.ok,
        "gates": [
            {
                "name": gate.name,
                "status": gate.status,
                "detail": gate.detail,
                "evidence": gate.evidence,
            }
            for gate in report.gates
        ],
    }


def format_markdown(report: AcceptanceReport) -> str:
    lines = [
        "# Krita Bridge Acceptance Report",
        "",
        f"- Acceptance OK: `{str(report.ok).lower()}`",
        "",
        "| Gate | Status | Detail | Evidence |",
        "|------|--------|--------|----------|",
    ]
    for gate in report.gates:
        lines.append(
            f"| {gate.name} | {gate.status} | {_escape_markdown_table(gate.detail)} | {_escape_markdown_table(gate.evidence)} |",
        )
    lines.append("")
    return "\n".join(lines)


def write_acceptance_artifacts(
    *,
    report: AcceptanceReport,
    json_path: Optional[Path] = None,
    markdown_path: Optional[Path] = None,
) -> None:
    if json_path is not None:
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(
            json.dumps(report_to_dict(report), ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
    if markdown_path is not None:
        markdown_path.parent.mkdir(parents=True, exist_ok=True)
        markdown_path.write_text(format_markdown(report), encoding="utf-8")


def _profile_failure_detail(profile: install_plugin.ProfileCheckResult) -> str:
    missing = [check.name for check in profile.checks if not check.ok]
    return "Missing or disabled profile checks: " + ", ".join(missing)


def _diagnostics_schema_error(diagnostics: Optional[Any]) -> Optional[str]:
    if diagnostics is None:
        return None
    if not isinstance(diagnostics, dict):
        return "Diagnostics report must contain a JSON object."
    if diagnostics.get("schema_version") != DIAGNOSTICS_SCHEMA_VERSION:
        return (
            "Diagnostics report must contain "
            f"schema_version={DIAGNOSTICS_SCHEMA_VERSION}."
        )
    if diagnostics.get("plugin") != DIAGNOSTICS_PLUGIN_NAME:
        return (
            "Diagnostics report must contain "
            f"plugin={DIAGNOSTICS_PLUGIN_NAME}."
        )
    if not isinstance(diagnostics.get("checks"), list):
        return "Diagnostics report must contain a checks list."
    plugin_layout = _diagnostic_checks_by_name(diagnostics).get("plugin_layout")
    if plugin_layout is None:
        return "Diagnostics report must contain a plugin_layout check."
    if plugin_layout.get("status") != "pass":
        return "Diagnostics report plugin_layout check must pass."
    return None


def _diagnostics_report_status(
    diagnostics: Optional[dict[str, Any]],
    schema_error: Optional[str],
) -> str:
    if diagnostics is None:
        return "pending"
    if schema_error is not None:
        return "fail"
    return "pass"


def _diagnostic_checks_by_name(
    diagnostics: Optional[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    if diagnostics is None:
        return {}
    checks = diagnostics.get("checks")
    if not isinstance(checks, list):
        return {}
    return {
        str(check.get("name")): check
        for check in checks
        if isinstance(check, dict) and check.get("name")
    }


def _diagnostic_gate(
    checks: dict[str, dict[str, Any]],
    name: str,
    pass_detail: str,
) -> Gate:
    check = checks.get(name)
    if check is None:
        return Gate(
            name,
            "pending",
            "Diagnostics report does not contain this check yet.",
        )
    status = str(check.get("status"))
    if status == "pass":
        return Gate(name, "pass", pass_detail)
    if status in {"fail", "warning", "skip"}:
        return Gate(name, status, str(check.get("detail", "")))
    return Gate(name, "pending", f"Unknown diagnostics status: {status}")


def _manual_gate(
    manual_evidence: dict[str, Any],
    automation_evidence: dict[str, Any],
    name: str,
    pass_detail: str,
) -> Gate:
    status = _manual_gate_status(manual_evidence, name)
    return Gate(
        name,
        status,
        pass_detail if status == "pass" else "Manual GUI evidence is required.",
        _gate_evidence(manual_evidence, automation_evidence, name),
    )


def _manual_gate_status(manual_evidence: dict[str, Any], name: str) -> str:
    value = _manual_gate_value(manual_evidence, name)
    if value is True:
        return "pass"
    if value is False:
        return "fail"
    return "pending"


def _docker_visible_status(
    manual_evidence: dict[str, Any],
    diagnostics: Optional[dict[str, Any]],
) -> str:
    if "docker_visible" in manual_evidence:
        return _manual_gate_status(manual_evidence, "docker_visible")
    return "pending"


def _manual_gate_value(manual_evidence: dict[str, Any], name: str) -> Any:
    value = manual_evidence.get(name)
    if isinstance(value, dict):
        return value.get("passed", value.get("ok"))
    return value


def _manual_gate_note(manual_evidence: dict[str, Any], name: str) -> str:
    value = manual_evidence.get(name)
    if isinstance(value, dict):
        return str(value.get("note", ""))
    return ""


def _gate_evidence(
    manual_evidence: dict[str, Any],
    automation_evidence: dict[str, Any],
    name: str,
) -> str:
    parts = []
    manual_note = _manual_gate_note(manual_evidence, name)
    if manual_note:
        parts.append(manual_note)
    automation_note = _automation_gate_note(automation_evidence, name)
    if automation_note:
        parts.append(f"Automation: {automation_note}")
    commands = _automation_gate_commands(automation_evidence, name)
    if commands:
        parts.append("Commands: " + "; ".join(commands))
    return " ".join(parts)


def _automation_gate_note(automation_evidence: dict[str, Any], name: str) -> str:
    value = automation_evidence.get(name)
    if isinstance(value, dict):
        return str(value.get("note", ""))
    if isinstance(value, str):
        return value
    return ""


def _automation_gate_commands(
    automation_evidence: dict[str, Any],
    name: str,
) -> list[str]:
    value = automation_evidence.get(name)
    if not isinstance(value, dict):
        return []
    commands = value.get("commands", [])
    if not isinstance(commands, list):
        return []
    return [str(command) for command in commands if command]


def _validate_evidence_keys(
    data: dict[str, Any],
    path: Path,
    known_keys: set[str],
) -> None:
    unknown = sorted(set(data) - known_keys)
    if unknown:
        raise ValueError(
            f"Unknown evidence gate(s) in {path}: {', '.join(unknown)}",
        )


def _validate_manual_evidence_notes(data: dict[str, Any], path: Path) -> None:
    missing = _passed_manual_evidence_without_notes(data)
    if missing:
        raise ValueError(
            "Manual evidence passed gate(s) in "
            f"{path} require a non-empty note: {', '.join(sorted(missing))}",
        )


def _passed_manual_evidence_without_notes(data: dict[str, Any]) -> list[str]:
    missing = []
    for name, value in data.items():
        if value is True:
            missing.append(name)
            continue
        if not isinstance(value, dict):
            continue
        passed = value.get("passed", value.get("ok"))
        note = str(value.get("note", "")).strip()
        if passed is True and not note:
            missing.append(name)
    return sorted(missing)


def _manual_evidence_from_args(args: argparse.Namespace) -> dict[str, Any]:
    evidence = load_manual_evidence(args.evidence_file) if args.evidence_file else {}
    if args.evidence_plugin_manager_visible:
        evidence["plugin_manager_visible"] = True
    if args.evidence_docker_visible:
        evidence["docker_visible"] = True
    if args.evidence_launcher_settings_toggle:
        evidence["launcher_settings_toggle"] = True
    if args.evidence_auto_discovery_connect:
        evidence["auto_discovery_connect"] = True
    if args.evidence_auth_failure_safe:
        evidence["auth_failure_safe"] = True
    if args.evidence_img2img_e2e:
        evidence["img2img_e2e"] = True
    if args.evidence_inpaint_e2e:
        evidence["inpaint_e2e"] = True
    if args.evidence_krita_cancel_e2e:
        evidence["krita_cancel_e2e"] = True
    if args.evidence_no_selection_behavior:
        evidence["no_selection_behavior"] = True
    if args.evidence_large_canvas_rejected:
        evidence["large_canvas_rejected"] = True
    if args.evidence_disconnect_generation_safe:
        evidence["disconnect_generation_safe"] = True
    if args.evidence_preview_throttle:
        evidence["preview_throttle"] = True
    if args.evidence_result_layer_aligned:
        evidence["result_layer_aligned"] = True
    if args.evidence_launcher_history_recorded:
        evidence["launcher_history_recorded"] = True
    if args.evidence_novelai_token_launcher_only:
        evidence["novelai_token_launcher_only"] = True
    if args.evidence_bridge_rejects_unauthenticated:
        evidence["bridge_rejects_unauthenticated"] = True
    if args.evidence_gallery_send_e2e:
        evidence["gallery_send_e2e"] = True
    if args.evidence_disabled_bridge_existing_flows:
        evidence["disabled_bridge_existing_flows"] = True
    return evidence


def _escape_markdown_table(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize real Krita Bridge acceptance gate evidence.",
    )
    parser.add_argument(
        "--pykrita-dir",
        type=Path,
        default=install_plugin.default_pykrita_dir(),
    )
    parser.add_argument(
        "--kritarc",
        type=Path,
        default=install_plugin.default_kritarc_path(),
    )
    parser.add_argument("--diagnostics", type=Path, default=default_diagnostics_path())
    parser.add_argument("--evidence-file", type=Path)
    parser.add_argument("--automation-evidence-file", type=Path)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-markdown", type=Path)
    parser.add_argument(
        "--require-ok",
        action="store_true",
        help="Return a non-zero exit code unless all acceptance gates pass.",
    )
    parser.add_argument("--evidence-plugin-manager-visible", action="store_true")
    parser.add_argument("--evidence-docker-visible", action="store_true")
    parser.add_argument("--evidence-launcher-settings-toggle", action="store_true")
    parser.add_argument("--evidence-auto-discovery-connect", action="store_true")
    parser.add_argument("--evidence-auth-failure-safe", action="store_true")
    parser.add_argument("--evidence-img2img-e2e", action="store_true")
    parser.add_argument("--evidence-inpaint-e2e", action="store_true")
    parser.add_argument("--evidence-krita-cancel-e2e", action="store_true")
    parser.add_argument("--evidence-no-selection-behavior", action="store_true")
    parser.add_argument("--evidence-large-canvas-rejected", action="store_true")
    parser.add_argument("--evidence-disconnect-generation-safe", action="store_true")
    parser.add_argument("--evidence-preview-throttle", action="store_true")
    parser.add_argument("--evidence-result-layer-aligned", action="store_true")
    parser.add_argument("--evidence-launcher-history-recorded", action="store_true")
    parser.add_argument("--evidence-novelai-token-launcher-only", action="store_true")
    parser.add_argument("--evidence-bridge-rejects-unauthenticated", action="store_true")
    parser.add_argument("--evidence-gallery-send-e2e", action="store_true")
    parser.add_argument("--evidence-disabled-bridge-existing-flows", action="store_true")
    args = parser.parse_args()

    profile = install_plugin.check_profile(
        pykrita_dir=args.pykrita_dir,
        kritarc_path=args.kritarc,
    )
    diagnostics = load_diagnostics(args.diagnostics)
    automation_evidence = (
        load_automation_evidence(args.automation_evidence_file)
        if args.automation_evidence_file
        else {}
    )
    manual_evidence = _manual_evidence_from_args(args)
    report = build_acceptance_report(
        profile=profile,
        diagnostics=diagnostics,
        diagnostics_path=args.diagnostics,
        manual_evidence=manual_evidence,
        automation_evidence=automation_evidence,
    )
    missing_manual_notes = _passed_manual_evidence_without_notes(manual_evidence)
    if args.require_ok and missing_manual_notes:
        report = AcceptanceReport(
            ok=False,
            gates=(
                *report.gates,
                Gate(
                    "manual_evidence_notes",
                    "fail",
                    "Release gate requires note-bearing manual evidence for "
                    + ", ".join(missing_manual_notes),
                ),
            ),
        )
    write_acceptance_artifacts(
        report=report,
        json_path=args.output_json,
        markdown_path=args.output_markdown,
    )
    print(format_report(report))
    return 0 if report.ok or not args.require_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
