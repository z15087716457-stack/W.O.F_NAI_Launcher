"""Device and precision choice without loading torch or model weights."""
import os
import sys
import types
import unittest
from unittest import mock

from models import Models


def fake_torch(cuda=False, mps=False):
    released = []
    torch = types.SimpleNamespace(
        float32='float32', bfloat16='bfloat16',
        cuda=types.SimpleNamespace(is_available=lambda: cuda, is_bf16_supported=lambda: True,
                                   empty_cache=lambda: released.append('cuda')),
        backends=types.SimpleNamespace(mps=types.SimpleNamespace(is_available=lambda: mps)),
        mps=types.SimpleNamespace(empty_cache=lambda: released.append('mps')))
    return torch, released


def models(requested):
    # Skip __init__: it resolves model folders and fingerprints the weights.
    value = Models.__new__(Models)
    value.requested_device = requested
    value.encoder = value.scorer = value.tokenizer = None
    value.vision = False
    return value


class DeviceTests(unittest.TestCase):
    def on(self, cuda=False, mps=False):
        torch, released = fake_torch(cuda, mps)
        patch = mock.patch.dict(sys.modules, {'torch': torch})
        patch.start(); self.addCleanup(patch.stop)
        return released

    def test_auto_uses_cuda_then_the_apple_gpu_then_the_cpu(self):
        for cuda, mps, expected in ((True, True, 'cuda'), (False, True, 'mps'), (False, False, 'cpu')):
            with self.subTest(cuda=cuda, mps=mps):
                self.on(cuda, mps)
                self.assertEqual(models('auto')._device(), expected)

    def test_cpu_is_never_moved_and_cuda_is_never_replaced(self):
        self.on(cuda=False, mps=True)
        self.assertEqual(models('cpu')._device(), 'cpu')
        with self.assertRaisesRegex(RuntimeError, 'cuda_unavailable'):
            models('cuda')._device()

    def test_the_apple_gpu_keeps_float32(self):
        # EmbeddingGemma must not run in float16; Macs match the Windows CPU.
        self.on(mps=True)
        self.assertEqual(models('auto')._dtype(), 'float32')
        self.on(cuda=True)
        self.assertEqual(models('auto')._dtype(), 'bfloat16')

    def test_unloading_frees_the_cache_of_the_device_in_use(self):
        released = self.on(mps=True)
        models('auto').unload()
        models('cpu').unload()
        self.assertEqual(released, ['mps'])
        released = self.on(cuda=True)
        models('auto').unload()
        self.assertEqual(released, ['cuda'])

    def test_metal_fallback_is_enabled_before_torch_loads(self):
        self.assertEqual(os.environ.get('PYTORCH_ENABLE_MPS_FALLBACK'), '1')


if __name__ == '__main__':
    unittest.main()
