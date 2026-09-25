import base64
import json
from typing import Any, Dict, Optional


PROTOCOL_VERSION = 1


def encode_ping(secret: str) -> str:
    return json.dumps(
        {
            "type": "ping",
            "version": PROTOCOL_VERSION,
            "secret": secret,
        },
        separators=(",", ":"),
    )


def encode_get_params(request_id: str) -> str:
    return _encode({"type": "get_params", "id": request_id})


def encode_cancel(request_id: str) -> str:
    return _encode({"type": "cancel", "id": request_id})


def encode_img2img(
    *,
    request_id: str,
    image_png: bytes,
    prompt: str,
    negative_prompt: str,
    strength: float,
    noise: float,
) -> str:
    return _encode(
        {
            "type": "img2img",
            "id": request_id,
            "image": _b64(image_png),
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "strength": float(strength),
            "noise": float(noise),
        }
    )


def encode_inpaint(
    *,
    request_id: str,
    image_png: bytes,
    mask_png: bytes,
    prompt: str,
    negative_prompt: str,
    strength: float,
    noise: float,
    inpaint_strength: float,
) -> str:
    return _encode(
        {
            "type": "inpaint",
            "id": request_id,
            "image": _b64(image_png),
            "mask": _b64(mask_png),
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "strength": float(strength),
            "noise": float(noise),
            "inpaint_strength": float(inpaint_strength),
            "mask_closing_iterations": 0,
            "mask_expansion_iterations": 0,
        }
    )


def decode_message(text: str) -> Dict[str, Any]:
    message = json.loads(text)
    if not isinstance(message, dict):
        raise ValueError("Bridge message must be a JSON object")
    return message


def pong_version_error(message: Dict[str, Any]) -> Optional[str]:
    launcher_version = message.get("version")
    if launcher_version == PROTOCOL_VERSION:
        return None

    supported = message.get("supported_versions")
    if isinstance(supported, list) and supported:
        supported_text = ", ".join(str(item) for item in supported)
    else:
        supported_text = "未知"

    return (
        "协议版本不兼容："
        f"Launcher: {launcher_version}, 插件: {PROTOCOL_VERSION}, 支持: {supported_text}"
    )


def decode_image_field(message: Dict[str, Any], key: str) -> bytes:
    value = message.get(key)
    if not isinstance(value, str) or not value:
        raise ValueError(f"Missing image field: {key}")
    return base64.b64decode(value)


def _encode(payload: Dict[str, Any]) -> str:
    return json.dumps(payload, separators=(",", ":"))


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")
