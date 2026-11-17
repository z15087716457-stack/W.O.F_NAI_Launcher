"""Offline-only inference. Model weights and caller prompts are never modified."""
import gc
import hashlib
import json
import os
from pathlib import Path

os.environ['HF_HUB_OFFLINE'] = '1'
os.environ['TRANSFORMERS_OFFLINE'] = '1'
os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
os.environ['TOKENIZERS_PARALLELISM'] = 'false'
# Apple GPU (MPS): an operator without a Metal kernel runs on the CPU instead
# of failing the request. Read when torch loads; no effect elsewhere.
os.environ.setdefault('PYTORCH_ENABLE_MPS_FALLBACK', '1')


def model_fingerprint(folder):
    root = Path(folder).resolve(strict=True)
    h = hashlib.sha256(b'wof-rag-v1-768-search-document')
    for name in ('config.json', 'tokenizer.json', 'modules.json',
                 'config_sentence_transformers.json', '1_Pooling/config.json',
                 '2_Normalize/config.json'):
        p = root / name
        if p.is_file():
            h.update(name.encode()); h.update(p.read_bytes())
    weights = root / 'model.safetensors'
    info = weights.stat()
    h.update(str((info.st_size, info.st_mtime_ns)).encode())
    with weights.open('rb') as stream:
        h.update(stream.read(1024 * 1024))
    return h.hexdigest()


class Models:
    def __init__(self, embedding, device='auto'):
        if device not in ('auto', 'cpu', 'cuda'):
            raise ValueError('invalid_device')
        self.embedding_path = str(Path(embedding).resolve(strict=True))
        self.requested_device = device
        self.encoder = self.tokenizer = None
        self.vision = False
        self.fingerprint = model_fingerprint(embedding)

    def _device(self):
        import torch
        if self.requested_device == 'cuda' and not torch.cuda.is_available():
            raise RuntimeError('cuda_unavailable')
        if self.requested_device == 'cpu': return 'cpu'
        if torch.cuda.is_available(): return 'cuda'
        # Apple silicon: PyPI's macOS PyTorch runs on the GPU through Metal.
        return 'mps' if torch.backends.mps.is_available() else 'cpu'

    def _empty_cache(self):
        import torch
        if torch.cuda.is_available(): torch.cuda.empty_cache()
        elif self.requested_device != 'cpu' and torch.backends.mps.is_available():
            torch.mps.empty_cache()

    def _dtype(self):
        import torch
        return torch.bfloat16 if self._device() == 'cuda' and torch.cuda.is_bf16_supported() else torch.float32

    def count(self, text):
        if self.tokenizer is None:
            from transformers import AutoTokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.embedding_path,
                local_files_only=True, trust_remote_code=False)
        return len(self.tokenizer.encode(text, add_special_tokens=False))

    def embed(self, texts, *, query=False):
        import numpy as np
        self._encoder()
        vectors = self.encoder.encode([{'text': text} for text in texts], prompt_name='SearchQuery' if query else 'Document',
            normalize_embeddings=True, convert_to_numpy=True, show_progress_bar=False,
            batch_size=8)
        return self._vectors(vectors)

    def _encoder(self, vision=False):
        if vision and not self.vision and self.encoder is not None:
            self.encoder = None
            gc.collect()
            self._empty_cache()
        if self.encoder is None:
            from sentence_transformers import SentenceTransformer
            self.encoder = SentenceTransformer(self.embedding_path,
                device=self._device(), local_files_only=True, trust_remote_code=False,
                config_kwargs={'audio_config': None} if vision else {'audio_config': None, 'vision_config': None},
                model_kwargs={'torch_dtype': self._dtype()})
            self.encoder.max_seq_length = 8192
            self.vision = vision

    def embed_images(self, images, text=''):
        self._encoder(vision=True)
        # PIL images only: never let the library fetch URLs or arbitrary strings.
        items = [{'image': image, 'text': 'task: search result | query: ' + text + ' <|image|>'}
                 if text else {'image': image} for image in images]
        vectors = self.encoder.encode(items, prompt='',
            normalize_embeddings=True, convert_to_numpy=True, show_progress_bar=False,
            batch_size=2)
        return self._vectors(vectors)

    @staticmethod
    def _vectors(vectors):
        import numpy as np
        result = np.asarray(vectors, dtype=np.float32)
        if result.ndim != 2 or result.shape[1] != 768 or not np.isfinite(result).all():
            raise RuntimeError('invalid_embeddings')
        # BF16 normalization can round norms away from one. Normalize again in
        # float32 before persistence / scoped cosine scoring.
        norms = np.linalg.norm(result,axis=1,keepdims=True)
        if (norms<1e-8).any(): raise RuntimeError('invalid_embeddings')
        return result/norms

    def unload(self):
        self.encoder = self.tokenizer = None
        self.vision = False
        gc.collect()
        self._empty_cache()

    def status(self):
        import torch
        return {'device': self._device(), 'cuda_available': torch.cuda.is_available(),
                'loaded': self.encoder is not None,
                'audio_enabled': False, 'dimension': 768,
                'image_capable': True, 'active_modalities': ['text', 'image'] if self.vision else ['text']}
