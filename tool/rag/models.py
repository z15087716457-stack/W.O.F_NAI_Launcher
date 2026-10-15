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
    def __init__(self, embedding, reranker, device='auto'):
        if device not in ('auto', 'cpu', 'cuda'):
            raise ValueError('invalid_device')
        self.embedding_path = str(Path(embedding).resolve(strict=True))
        self.reranker_path = str(Path(reranker).resolve(strict=True))
        self.requested_device = device
        self.encoder = self.scorer = self.tokenizer = None
        self.fingerprint = model_fingerprint(embedding)

    def _device(self):
        import torch
        if self.requested_device == 'cuda' and not torch.cuda.is_available():
            raise RuntimeError('cuda_unavailable')
        return 'cuda' if self.requested_device != 'cpu' and torch.cuda.is_available() else 'cpu'

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
        if self.encoder is None:
            from sentence_transformers import SentenceTransformer
            self.encoder = SentenceTransformer(self.embedding_path,
                device=self._device(), local_files_only=True, trust_remote_code=False,
                config_kwargs={'audio_config': None, 'vision_config': None},
                model_kwargs={'torch_dtype': self._dtype()})
            self.encoder.max_seq_length = 8192
        vectors = self.encoder.encode(texts, prompt_name='SearchQuery' if query else 'Document',
            normalize_embeddings=True, convert_to_numpy=True, show_progress_bar=False,
            batch_size=8)
        result = np.asarray(vectors, dtype=np.float32)
        if result.ndim != 2 or result.shape[1] != 768 or not np.isfinite(result).all():
            raise RuntimeError('invalid_embeddings')
        return result

    def rerank(self, query, documents, negative=False, purpose='tags'):
        if not documents:
            return []
        import numpy as np
        if self.scorer is None:
            from sentence_transformers import CrossEncoder
            self.scorer = CrossEncoder(self.reranker_path, device=self._device(),
                local_files_only=True, trust_remote_code=False, max_length=1024,
                model_kwargs={'torch_dtype': self._dtype()},
                prompts={'positive': 'Retrieve real image tags that complement the existing visual prompt; prefer useful additional concepts over repeated synonyms.',
                         'negative': 'Retrieve real image tags that can complement the existing exclusion tags in a negative prompt.',
                         'retrieval': 'Retrieve text passages relevant to the search query or useful for answering it.'},
                default_prompt_name='positive')
        scores = np.asarray(self.scorer.predict([(query, d) for d in documents],
            prompt_name='retrieval' if purpose == 'retrieval' else ('negative' if negative else 'positive'),
            batch_size=8, show_progress_bar=False), dtype=float).reshape(-1)
        if len(scores) != len(documents) or not np.isfinite(scores).all():
            raise RuntimeError('invalid_rerank_scores')
        return scores.tolist()

    def unload(self):
        self.encoder = self.scorer = None
        gc.collect()
        import torch
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

    def status(self):
        import torch
        return {'device': self._device(), 'cuda_available': torch.cuda.is_available(),
                'loaded': self.encoder is not None or self.scorer is not None,
                'audio_enabled': False, 'dimension': 768,
                'image_capable': True, 'active_modalities': ['text']}
