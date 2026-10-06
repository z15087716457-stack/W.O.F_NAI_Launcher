"""Run with the pinned SeedVR2 Python; uses synthetic tensors, never weights."""
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

import torch
from torch import nn

sys.path.insert(0, str(Path(__file__).resolve().parents[2] /
                       "assets/local_upscale/seedvr2"))
import native_int8 as native


def checkpoint():
    model = nn.Sequential(nn.Linear(512, 32, device="meta"))
    marker = json.dumps({"format": "int8_tensorwise", "convrot": True,
                         "convrot_groupsize": 256}).encode()
    state = {"0.weight": torch.randint(-127, 128, (32, 512), dtype=torch.int8),
             "0.weight_scale": torch.full((32, 1), .002),
             "0.bias": torch.zeros(32, dtype=torch.float16),
             "0.comfy_quant": torch.tensor(list(marker), dtype=torch.uint8),
             "positive_conditioning": torch.ones(1),
             "negative_conditioning": torch.zeros(1)}
    return model, state


class CheckpointTests(unittest.TestCase):
    def test_rotation_is_regular_orthogonal_involution(self):
        matrix = native.rotation("cpu")
        torch.testing.assert_close(matrix @ matrix, torch.eye(256), rtol=0, atol=0)
        torch.testing.assert_close(matrix.sum(dim=1), torch.ones(256), rtol=0, atol=0)

    def test_meta_load_keeps_packed_weights_and_channel_scales(self):
        model, state = checkpoint()
        expected = state["0.weight"].clone()
        self.assertEqual(native.prepare_model(model, state), 1)
        result = model.load_state_dict(state, strict=True, assign=True)
        self.assertEqual(result.missing_keys, [])
        self.assertEqual(model[0].weight.dtype, torch.int8)
        self.assertFalse(model[0].weight.requires_grad)
        self.assertEqual(model[0].weight_scale.shape, (32,))
        torch.testing.assert_close(model[0].weight, expected)
        with self.assertRaises(native.NativeInt8Unavailable):
            model(torch.ones(1, 512))

    def test_bad_metadata_and_scale_do_not_change_model(self):
        for fault in ("format", "group", "scale", "bias"):
            with self.subTest(fault=fault):
                model, state = checkpoint()
                old = model[0]
                if fault in ("format", "group"):
                    conf = {"format": "nvfp4" if fault == "format" else "int8_tensorwise",
                            "convrot": True, "convrot_groupsize": 64 if fault == "group" else 256}
                    state["0.comfy_quant"] = torch.tensor(list(json.dumps(conf).encode()), dtype=torch.uint8)
                elif fault == "scale":
                    state["0.weight_scale"][0] = float("nan")
                else:
                    del state["0.bias"]
                with self.assertRaises(ValueError):
                    native.prepare_model(model, state)
                self.assertIs(model[0], old)
                self.assertIn("0.comfy_quant", state)

    def test_unsupported_gpu_fails_instead_of_dequantizing(self):
        with patch.object(torch.cuda, "is_available", return_value=True), \
             patch.object(torch.cuda, "get_device_capability", return_value=(7, 0)):
            with self.assertRaises(native.NativeInt8Unavailable):
                native.probe()


@unittest.skipUnless(torch.cuda.is_available(), "CUDA hardware required")
class CudaTests(unittest.TestCase):
    def test_native_integer_kernel_probe(self):
        native.probe()

    def test_forward_matches_independent_quantized_reference_at_row_boundaries(self):
        torch.manual_seed(14)
        model, state = checkpoint()
        native.prepare_model(model, state)
        model.load_state_dict(state, strict=True, assign=True)
        model.to("cuda")
        h = native.rotation("cpu").double()
        weights = model[0].weight.cpu().double()
        scales = model[0].weight_scale.cpu().double()
        for rows in (1, 16, 17, 32, 33, 2049):
            with self.subTest(rows=rows):
                source = torch.randn(rows, 512)
                rotated = (source.double().reshape(-1, 256) @ h).reshape(rows, 512)
                row_scale = rotated.abs().amax(1, keepdim=True) / 127
                quantized = (rotated / row_scale).round().clamp(-127, 127)
                reference = (quantized @ weights.T) * row_scale * scales
                actual = model(source.cuda()).cpu()
                # FP32 rotation can cross one INT8 rounding bin compared with FP64.
                torch.testing.assert_close(actual.double(), reference, rtol=.001, atol=.01)
        model.cpu()
        self.assertEqual(model[0].weight.dtype, torch.int8)
        self.assertEqual(model[0].weight_scale.dtype, torch.float32)

    def test_autocast_and_zero_input_preserve_output_dtype(self):
        model, state = checkpoint()
        native.prepare_model(model, state)
        model.load_state_dict(state, strict=True, assign=True)
        model.cuda()
        for dtype in (torch.float16, torch.bfloat16):
            with torch.autocast("cuda", dtype=dtype):
                actual = model(torch.zeros(2, 3, 512, device="cuda"))
            self.assertEqual(actual.dtype, dtype)
            self.assertEqual(actual.shape, (2, 3, 32))
            self.assertTrue(bool((actual == 0).all()))


if __name__ == "__main__":
    unittest.main(verbosity=2)
