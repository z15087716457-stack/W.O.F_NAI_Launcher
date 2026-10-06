"""Native INT8 ConvRot adapter for Studio's pinned standalone SeedVR2.

Uses the existing PyTorch CUDA integer GEMM, without a ComfyUI process or a
second runtime. Packed weights remain INT8 when moved between CPU and CUDA.
The regular H4 rotation matches Comfy-Org's ConvRot checkpoint format.
"""
import json
import math
import torch
from torch import nn
from torch.nn import functional as F


MODEL_FILES = {
    "seedvr2_3b_int8_convrot.safetensors": ("3B", None,
        "c3dec8bcc5916843a8a858572970597462e1f2dc598d6dfd818f6cd40f53a157"),
    "seedvr2_7b_int8_convrot.safetensors": ("7B", None,
        "5aa0d25fc9d35e449b659d0c9a5dcb22e2a4fa04032101b95a39da42b32c1be6"),
    "seedvr2_7b_sharp_int8_convrot.safetensors": ("7B", "sharp",
        "db48be2f1cc7e36b01a2aa529810f5d9c6a971edd29be225cf1b0eb18d51c366"),
}
_ROTATIONS = {}


class NativeInt8Unavailable(RuntimeError):
    pass


def rotation(device):
    key = str(device)
    if key not in _ROTATIONS:
        base = torch.tensor([[1, 1, 1, -1], [1, 1, -1, 1],
                             [1, -1, 1, 1], [-1, 1, 1, 1]],
                            device=device, dtype=torch.float32)
        matrix = base
        for _ in range(3):
            matrix = torch.kron(matrix, base)
        _ROTATIONS[key] = matrix / math.sqrt(256)
    return _ROTATIONS[key]


class ConvRotLinear(nn.Linear):
    def __init__(self, in_features, out_features, bias, device):
        # The checkpoint's int8 weight must never inherit requires_grad=True.
        nn.Module.__init__(self)
        self.in_features = in_features
        self.out_features = out_features
        self.weight = nn.Parameter(torch.empty(out_features, in_features,
                                  dtype=torch.int8, device=device),
                                  requires_grad=False)
        self.register_buffer("weight_scale", torch.empty(out_features,
                             dtype=torch.float32, device=device))
        self.bias = (nn.Parameter(torch.empty(out_features, dtype=torch.float16,
                     device=device), requires_grad=False) if bias else None)

    @torch.no_grad()
    def forward(self, input):
        if input.device.type != "cuda" or self.weight.dtype != torch.int8:
            raise NativeInt8Unavailable("native_int8_requires_cuda_packed_weights")
        if input.shape[-1] != self.in_features:
            raise ValueError("int8_input_shape_mismatch")
        dtype = (torch.get_autocast_dtype("cuda")
                 if torch.is_autocast_enabled("cuda") else input.dtype)
        with torch.autocast("cuda", enabled=False):
            return self._forward(input, dtype)

    def _forward(self, input, dtype):
        flat = input.reshape(-1, self.in_features)
        result = torch.empty(flat.shape[0], self.out_features,
                             device=input.device, dtype=dtype)
        h = rotation(input.device)
        # Bound INT32/FP32 temporary storage for large image token sequences.
        rows = max(32, min(2048, (8 * 1024 * 1024 // self.out_features // 32) * 32))
        weight = self.weight.t()
        for start in range(0, flat.shape[0], rows):
            part = flat[start:start + rows].to(dtype).float()
            part = (part.reshape(-1, 256) @ h).reshape(part.shape)
            scales = part.abs().amax(dim=1, keepdim=True) / 127
            scales = torch.where(scales == 0, torch.ones_like(scales), scales)
            quantized = (part / scales).round().clamp(-127, 127).to(torch.int8)
            count = quantized.shape[0]
            # PyTorch 2.7's CUDA integer GEMM requires more than 16 rows.
            padding = max(32, ((count + 31) // 32) * 32) - count
            if padding:
                quantized = F.pad(quantized, (0, 0, 0, padding))
            accumulated = torch._int_mm(quantized, weight)[:count].float()
            output = accumulated * scales * self.weight_scale.float()
            if self.bias is not None:
                output.add_(self.bias.float())
            result[start:start + count].copy_(output)
        return result.reshape(*input.shape[:-1], self.out_features)


def prepare_model(model, state):
    markers = [key for key in state if key.endswith(".comfy_quant")]
    if not markers:
        raise ValueError("int8_checkpoint_metadata_missing")
    replacements = []
    # Validate the whole checkpoint before changing the model or state.
    for key in markers:
        name = key[:-len(".comfy_quant")]
        marker = state[key]
        if marker.dtype != torch.uint8 or marker.numel() > 4096:
            raise ValueError("int8_checkpoint_metadata_invalid")
        conf = json.loads(bytes(marker.detach().cpu().reshape(-1).tolist()))
        params = conf.get("params", {})
        if (conf.get("format") != "int8_tensorwise"
                or conf.get("convrot", params.get("convrot")) is not True
                or conf.get("convrot_groupsize", params.get("convrot_groupsize", 256)) != 256):
            raise ValueError("unsupported_int8_quantization")
        old = model.get_submodule(name)
        weight = state[name + ".weight"]
        scale = state[name + ".weight_scale"]
        if (not isinstance(old, nn.Linear) or weight.dtype != torch.int8
                or weight.shape != (old.out_features, old.in_features)
                or old.in_features % 256 or old.out_features % 8
                or old.out_features < 16 or scale.numel() != old.out_features
                or not scale.is_floating_point()
                or not bool(torch.isfinite(scale).all()) or not bool((scale > 0).all())):
            raise ValueError("int8_checkpoint_layer_invalid:" + name)
        if old.bias is not None and name + ".bias" not in state:
            raise ValueError("int8_checkpoint_bias_missing:" + name)
        replacements.append((key, name, old, scale))
    for key, name, old, scale in replacements:
        parent_name, _, attr = name.rpartition(".")
        parent = model.get_submodule(parent_name) if parent_name else model
        setattr(parent, attr, ConvRotLinear(old.in_features, old.out_features,
                                          old.bias is not None, old.weight.device))
        state[name + ".weight_scale"] = scale.float().reshape(-1)
        del state[key]
    # These are baked-in copies of the same fixed conditioning used by the CLI.
    state.pop("positive_conditioning", None)
    state.pop("negative_conditioning", None)
    return len(replacements)


def probe():
    if not torch.cuda.is_available() or torch.cuda.get_device_capability(0) < (7, 5):
        raise NativeInt8Unavailable("native_int8_requires_sm75")
    try:
        left = torch.ones(32, 256, device="cuda", dtype=torch.int8)
        right = torch.ones(256, 32, device="cuda", dtype=torch.int8)
        actual = torch._int_mm(left, right)
        if actual.dtype != torch.int32 or not bool((actual == 256).all()):
            raise RuntimeError("integer_gemm_probe_mismatch")
        torch.cuda.synchronize()
    except Exception as error:
        raise NativeInt8Unavailable("native_int8_kernel_unavailable") from error


def install():
    from src.core import model_loader
    from src.utils.model_registry import MODEL_REGISTRY, ModelInfo
    for name, (size, variant, digest) in MODEL_FILES.items():
        MODEL_REGISTRY[name] = ModelInfo(repo="Comfy-Org/SeedVR2", size=size,
                                       variant=variant, precision="int8_convrot", sha256=digest)
    original = model_loader._load_standard_weights
    if getattr(original, "studio_int8", False):
        return

    def load(model, state, used_meta, model_type, model_type_lower, debug=None):
        if any(key.endswith(".comfy_quant") for key in state):
            layers = prepare_model(model, state)
            result = original(model, state, used_meta, model_type, model_type_lower, debug)
            if any(parameter.device.type == "meta" for parameter in result.parameters()):
                raise ValueError("int8_checkpoint_incomplete")
            if debug:
                debug.log(f"Studio native INT8 ConvRot: {layers} packed Linear layers",
                          category="dit", force=True)
            return result
        if model_type_lower == "dit":
            raise ValueError("int8_checkpoint_metadata_missing")
        return original(model, state, used_meta, model_type, model_type_lower, debug)

    load.studio_int8 = True
    model_loader._load_standard_weights = load
