import asyncio
import argparse
import base64
import json
import os
import time
from io import BytesIO
from pathlib import Path

import websockets
from PIL import Image


def _discovery_path() -> Path:
    appdata = os.environ.get("APPDATA", r"C:\Users\10562\AppData\Roaming")
    return Path(appdata) / "nai-launcher" / "krita-bridge.json"


def _png(width: int, height: int) -> bytes:
    image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    for offset in range(0, min(width, height), 12):
        x = min(width - 1, 160 + offset)
        y = min(height - 1, 260 + offset)
        image.putpixel((x, y), (70, 45, 55, 255))
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def _mask_png(width: int, height: int, rect: tuple[int, int, int, int]) -> bytes:
    image = Image.new("L", (width, height), 0)
    x, y, w, h = rect
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            image.putpixel((xx, yy), 255)
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


async def _recv_json(ws, timeout: float = 10.0) -> dict:
    raw = await asyncio.wait_for(ws.recv(), timeout=timeout)
    if isinstance(raw, bytes):
        return {"type": "binary", "byte_length": len(raw)}
    return json.loads(raw)


async def _main(mode: str) -> int:
    discovery_file = _discovery_path()
    discovery = json.loads(discovery_file.read_text(encoding="utf-8"))
    url = f"ws://127.0.0.1:{discovery['port']}/krita"
    secret = str(discovery["secret"])

    checks: list[dict] = []

    def add(name: str, passed: bool, detail: str, message: dict | None = None) -> None:
        entry = {"name": name, "passed": passed, "detail": detail}
        if message is not None:
            entry["message"] = {
                key: value
                for key, value in message.items()
                if key
                not in {
                    "secret",
                    "image",
                    "preview_image",
                    "params",
                    "prompt",
                    "negative_prompt",
                }
            }
        checks.append(entry)

    wrong_ws = await websockets.connect(url, max_size=80 * 1024 * 1024)
    try:
        await wrong_ws.send(
            json.dumps(
                {"type": "ping", "version": 1, "secret": "definitely-wrong"},
                separators=(",", ":"),
            ),
        )
        wrong_msg = await _recv_json(wrong_ws)
        add(
            "auth_failure_safe",
            wrong_msg.get("type") == "error"
            and wrong_msg.get("code") == "auth_failed",
            "Wrong secret returned auth_failed without token/account data.",
            wrong_msg,
        )
    finally:
        await wrong_ws.close()

    ws = await websockets.connect(url, max_size=80 * 1024 * 1024)
    try:
        await ws.send(
            json.dumps(
                {"type": "ping", "version": 1, "secret": secret},
                separators=(",", ":"),
            ),
        )
        pong = await _recv_json(ws)
        add(
            "auto_discovery_connect",
            pong.get("type") == "pong" and pong.get("version") == 1,
            "Authenticated using the real discovery file, without logging the secret.",
            pong,
        )

        unauth_ws = await websockets.connect(url, max_size=80 * 1024 * 1024)
        try:
            await unauth_ws.send(
                json.dumps(
                    {"type": "get_params", "id": "unauth-probe"},
                    separators=(",", ":"),
                ),
            )
            unauth_msg = await _recv_json(unauth_ws)
            add(
                "bridge_rejects_unauthenticated",
                unauth_msg.get("type") == "error"
                and unauth_msg.get("code") == "unauthorized_bridge_client",
                "Unauthenticated local WebSocket message was rejected.",
                unauth_msg,
            )
        finally:
            await unauth_ws.close()

        large_png = base64.b64encode(_png(4097, 64)).decode("ascii")
        await ws.send(
            json.dumps(
                {"type": "img2img", "id": "large-canvas-probe", "image": large_png},
                separators=(",", ":"),
            ),
        )
        large_msg = await _recv_json(ws)
        add(
            "large_canvas_rejected",
            large_msg.get("type") == "error"
            and large_msg.get("id") == "large-canvas-probe",
            "4097x64 PNG was rejected before any generation request.",
            large_msg,
        )

        await ws.send(
            json.dumps(
                {"type": "get_params", "id": "params-probe"},
                separators=(",", ":"),
            ),
        )
        params = await _recv_json(ws)
        add(
            "get_params",
            params.get("type") == "params" and params.get("id") == "params-probe",
            "Launcher returned current bridge params.",
            params,
        )

        if mode == "inpaint":
            width = int(params.get("width") or 832)
            height = int(params.get("height") or 1216)
            width = min(width, 832)
            height = min(height, 1216)
            width = max(width, 64)
            height = max(height, 64)
            rect = (
                max(0, width // 3),
                max(0, height // 3),
                max(64, width // 4),
                max(64, height // 5),
            )
            request_id = f"{mode}-probe-{int(time.time())}"
            payload = {
                "type": "inpaint",
                "id": request_id,
                "image": base64.b64encode(_png(width, height)).decode("ascii"),
                "mask": base64.b64encode(_mask_png(width, height, rect)).decode(
                    "ascii",
                ),
                "prompt": params.get("prompt") or "simple anime illustration",
                "negative_prompt": params.get("negative_prompt") or "",
                "strength": float(params.get("strength") or 0.7),
                "noise": float(params.get("noise") or 0.0),
                "inpaint_strength": float(params.get("inpaint_strength") or 1.0),
                "mask_closing_iterations": 0,
                "mask_expansion_iterations": 0,
            }
            await ws.send(json.dumps(payload, separators=(",", ":")))
            progress_count = 0
            preview_count = 0
            terminal = None
            started_at = time.time()
            while time.time() - started_at < 240:
                message = await _recv_json(ws, timeout=45)
                message_type = message.get("type")
                if message_type == "progress":
                    progress_count += 1
                    if "preview_image" in message:
                        preview_count += 1
                    continue
                terminal = message
                break
            add(
                "inpaint_e2e",
                terminal is not None
                and terminal.get("type") == "result"
                and terminal.get("id") == request_id,
                (
                    f"{mode} terminal={terminal.get('type') if terminal else None}; "
                    f"progress_count={progress_count}; preview_count={preview_count}; "
                    f"size={width}x{height}"
                ),
                terminal or {},
            )
    finally:
        await ws.close()

    print(
        json.dumps(
            {
                "discovery_path": str(discovery_file),
                "port": discovery.get("port"),
                "pid": discovery.get("pid"),
                "checks": checks,
            },
            ensure_ascii=False,
            indent=2,
        ),
    )
    return 0 if all(check["passed"] for check in checks) else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        choices=("protocol", "inpaint"),
        default="protocol",
    )
    args = parser.parse_args()
    raise SystemExit(asyncio.run(_main(args.mode)))
