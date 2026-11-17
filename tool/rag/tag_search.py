"""Exact multi-view tag retrieval for the pinned DanbooruSearch contract.

Persistence and embedding inference retain the application's existing owners.
"""
from copy import copy
from dataclasses import dataclass
import json
import math
import sqlite3

from engine import Engine
from pool import EXACT_TAG_COLLECTION
from tag_query import intent_weights
from tag_corpus import TagSources, VIEWS, view_texts, view_row, views_for

LAYERS = dict(zip(('英文', '中文扩展词', '释义', '中文核心词'), VIEWS))
CATEGORIES = {0: 'General', 1: 'Artist', 3: 'Copyright', 4: 'Character', 5: 'Meta'}
RETIRED_TAG_COLLECTIONS = ('tags', 'tag-views-v1')
LEGACY_TAG_FILES = ('tags.sqlite', 'tags.sqlite-wal', 'tags.sqlite-shm',
                    'vectors.usearch', 'ann.json')


@dataclass(frozen=True)
class SearchOptions:
    top_k: int = 5
    popularity_weight: float = .15
    use_segmentation: bool = True
    target_layers: tuple = tuple(VIEWS)
    target_categories: tuple = ('General', 'Character', 'Copyright')
    group_mode: str = 'off'
    max_per_group: int = 2

    @classmethod
    def parse(cls, params):
        values = {name: params[name] for name in cls.__dataclass_fields__ if name in params}
        for name in ('target_layers', 'target_categories'):
            if name in values:
                if not isinstance(values[name], list) or any(not isinstance(value, str) for value in values[name]):
                    raise ValueError('invalid_source')
                values[name] = tuple(LAYERS.get(value, value) if name == 'target_layers' else value for value in values[name])
        result = cls(**values)
        if (type(result.top_k) is not int or not 1 <= result.top_k <= 80
                or type(result.popularity_weight) not in (int, float) or not 0 <= result.popularity_weight <= 1
                or type(result.use_segmentation) is not bool
                or not set(result.target_layers) <= VIEWS.keys()
                or not set(result.target_categories) <= set(CATEGORIES.values()) | {'Other'}
                or result.group_mode not in ('off', 'expand', 'diverse')
                or type(result.max_per_group) is not int or result.max_per_group < 1):
            raise ValueError('invalid_source')
        return result


class TagEngine(Engine):
    def __init__(self, directory, models, sources, *, pool=None, collection=EXACT_TAG_COLLECTION):
        super().__init__(directory, models, sources, pool=pool, collection=collection)
        self._matrix_key = None
        self._matrices = {}
        self._query_owner = None
        self._legacy = None
        self._cleaning = False

    def _legacy_index(self):
        if self._legacy is None:
            root = self.pool.folder.parent.parent
            fingerprint = self.pool.folder.name
            files = []
            for folder in (root/fingerprint, root/'tag-views-v1'/fingerprint):
                for name in LEGACY_TAG_FILES:
                    path = folder/name
                    if path.resolve().is_relative_to(root) and path.is_file():
                        files.append(path)
            size = sum(self.pool.collection_bytes(name) for name in RETIRED_TAG_COLLECTIONS)
            count = self.pool.db.execute(
                'SELECT COUNT(*) FROM pool_documents WHERE collection IN (?,?)',
                RETIRED_TAG_COLLECTIONS).fetchone()[0]
            self._legacy = count, size + sum(path.stat().st_size for path in files), files
        return self._legacy

    def status(self):
        status = super().status()
        count, size, files = self._legacy_index()
        row = self.db.execute("SELECT value FROM metadata WHERE key='legacy_cleanup'").fetchone()
        cleanup = row[0] if row else ''
        available = bool(count or files or cleanup in ('pending', 'failed'))
        return {**status, 'legacy_bytes': size, 'upgrade_available': available,
                'upgrade_pending': cleanup == 'pending', 'upgrade_failed': cleanup == 'failed',
                'upgrade_cleaning': self._cleaning,
                'cleanup_only': available and self._ready_to_retire(status)}

    @staticmethod
    def _ready_to_retire(status):
        return (status['complete'] and status['total'] > 0
                and status['indexed'] == status['total'] and status['skipped'] == 0)

    def preview(self):
        plan = super().preview()
        status = self.status()
        upgrade = {key: status[key] for key in ('upgrade_available', 'cleanup_only', 'legacy_bytes')}
        upgrade['tags'] = len(self.sources.records)
        self.plan.update(upgrade)
        return {**plan, **upgrade}

    def _cleanup_legacy(self):
        # Validate persisted vectors before retiring the fallback data. The
        # encoder already validates finite values and dimensions at ingestion.
        if self.db.execute('SELECT 1 FROM documents WHERE length(vector)!=3072 OR vector IS NULL LIMIT 1').fetchone():
            raise ValueError('invalid_embeddings')
        files = self._legacy_index()[2]
        self.pool.retire_collections(RETIRED_TAG_COLLECTIONS)
        root = self.pool.folder.parent.parent
        for path in files:
            if not path.resolve().is_relative_to(root):
                raise ValueError('invalid_source')
            path.unlink(missing_ok=True)
        self.pool.db.execute('VACUUM')

    def _load_matrices(self):
        import numpy as np
        import torch
        signature = self.sources.signature()
        key = signature
        if key == self._matrix_key:
            return
        rows = {view: [] for view in VIEWS}
        for encoded, digest, vector in self.db.execute('SELECT name,digest,vector FROM documents ORDER BY id'):
            name, view = json.loads(encoded)
            profile = self.sources.records.get(name)
            if profile and view in views_for(profile) and view_row(profile, view)['digest'] == digest:
                rows[view].append((name, vector))
        self._matrices = {}
        for view, entries in rows.items():
            if entries:
                names, blobs = zip(*entries)
                matrix = torch.from_numpy(np.stack([np.frombuffer(blob, dtype=np.float32) for blob in blobs]))
                self._matrices[view] = names, {name: index for index, name in enumerate(names)}, matrix
        self._matrix_key = key

    def search(self, query, existing=(), limit=40, cancelled=lambda: False, options=None):
        source = self.sources
        if self._query_owner is not source:
            self._query_owner = source
            self._query_sources = copy(source)
            self._query_sources.optional_supplements = True
        self._query_sources.aliases, self._query_sources.groups = source.aliases, source.groups
        self.sources = self._query_sources
        try:
            return self._search(query,existing,limit,cancelled,options)
        finally:
            self.sources = source

    def _search(self, query, existing, limit, cancelled, options):
        query = query[:1024].strip()
        if not query:
            return {'items': []}
        if cancelled():
            raise ValueError('cancelled')
        options = options or SearchOptions()
        self._load_matrices()
        if not self._matrices:
            return {'items': [], 'fallback': 'index_empty'}
        import torch
        queries, keywords, segments = self.sources.query(query, options.use_segmentation)
        vectors = torch.from_numpy(self.models.embed(queries, query=True))
        active = [view for view in VIEWS if view in options.target_layers]
        weights = [dict(zip(VIEWS, intent_weights(part))) for part in queries]
        quotas = [{view: max(1, round(options.top_k*weight[view]/sum(weight[v] for v in active)))
                   for view in active} for weight in weights]
        maximum = self.sources.max_log_count
        final = {}
        for view in active:
            if cancelled():
                raise ValueError('cancelled')
            layer = self._matrices.get(view)
            if layer is None:
                continue
            names, _, matrix = layer
            count = min(max(quota[view] for quota in quotas), len(names))
            scores, indices = (vectors @ matrix.T).topk(count, dim=1)
            for query_index, (values, positions) in enumerate(zip(scores.tolist(), indices.tolist())):
                for similarity, index in zip(values[:quotas[query_index][view]], positions[:quotas[query_index][view]]):
                    if similarity < .35:
                        break
                    name = names[index]
                    profile = self.sources.records[name]
                    if profile.get('_category',CATEGORIES.get(profile['category'],'Other')) not in options.target_categories:
                        continue
                    score = (1-options.popularity_weight)*similarity + options.popularity_weight*math.log1p(profile['post_count'])/maximum
                    if name not in final or score > final[name]['score']:
                        final[name] = self._item(profile, round(score, 4), round(similarity, 4), queries[query_index], view)
        if options.use_segmentation and final:
            names = list(final)
            coherence = torch.zeros(len(names))
            for view in active:
                layer = self._matrices.get(view)
                if layer is None:
                    continue
                _, positions, matrix = layer
                eligible = [(index, positions[name]) for index, name in enumerate(names) if name in positions]
                if eligible:
                    output, selected = zip(*eligible)
                    coherence[list(output)] = torch.maximum(coherence[list(output)], vectors[0] @ matrix[list(selected)].T)
            for name, value in zip(names, coherence.tolist()):
                final[name]['score'] = round(final[name]['score']*(.7+.3*value), 4)
        final = self._canonicalize(final)
        if options.group_mode == 'expand':
            self._expand_groups(final)
        guaranteed = {best['name'] for part in queries
                      if (best := max((item for item in final.values() if item['source'] == part and item['score'] > .45),
                                      key=lambda item: item['score'], default=None)) is not None}
        excluded = {self.sources.aliases.get(name, name) for name in existing}
        items, group_counts = [], {}
        for item in sorted(final.values(), key=lambda row: row['score'], reverse=True):
            name = item['name']
            if item['score'] <= .45 or name in excluded:
                continue
            groups = self.sources.groups.get(name, set())
            if options.group_mode == 'diverse' and groups and name not in guaranteed:
                if any(group_counts.get(group, 0) >= options.max_per_group for group in groups):
                    continue
            if len(items) < limit or name in guaranteed:
                items.append(item)
                if options.group_mode == 'diverse' and name not in guaranteed:
                    for group in groups:
                        group_counts[group] = group_counts.get(group, 0)+1
        if cancelled():
            raise ValueError('cancelled')
        items = [{key:value for key,value in item.items() if not key.startswith('_')} for item in items]
        return {'items': items, 'keywords': keywords, 'segments': segments,
                'degraded': ['supplements_unavailable'] if self.sources.degraded else [],
                'tags_all': ', '.join(item['name'] for item in items),
                'tags_sfw': ', '.join(item['name'] for item in items if item['nsfw'] != '1')}

    @staticmethod
    def _item(profile, score, similarity, source, view):
        return {**profile, 'score': score, 'semantic_score': similarity, 'source': source, 'origins': [view]}

    def _canonicalize(self, results):
        merged = {}
        for name, item in results.items():
            target = self.sources.aliases.get(name, name)
            if target != name:
                profile = self.sources.records.get(target)
                if profile is None:
                    profile = dict(name=target, cn_name='', core_zh='', wiki='', post_count=0,
                                   category=item['category'], nsfw=item['nsfw'], aliases=[])
                item = {**item, **profile, 'alias_from': name}
            previous = merged.get(target)
            if previous is None or (item['score'], item['semantic_score']) > (previous['score'], previous['semantic_score']):
                merged[target] = item
        return merged

    def _expand_groups(self, results):
        anchors = sorted(results.values(), key=lambda item: item['score'], reverse=True)[:20]
        strengths = {}
        for item in anchors:
            for group in self.sources.groups.get(item['name'], set()):
                strengths[group] = max(strengths.get(group, 0), item['score'])
        for item in results.values():
            overlap = self.sources.groups.get(item['name'], set()) & strengths.keys()
            if overlap:
                item['score'] = round(item['score']*(1+.2*max(strengths[group] for group in overlap)), 4)

    def close(self):
        self._matrices.clear()
        super().close()

    def build(self, plan_id, cancelled, progress=None):
        if self.active: raise ValueError('index_busy')
        self.validate_plan(plan_id)
        upgrade = self.plan.get('upgrade_available', False)
        cleanup_only = upgrade and self._ready_to_retire(super().status())
        if upgrade:
            self.db.execute("INSERT OR REPLACE INTO metadata VALUES('legacy_cleanup','pending')")
            self.db.commit()
        try:
            if cleanup_only:
                self.plan = None
                self.db.execute("DELETE FROM metadata WHERE key='build_error'")
                self.db.commit()
            else:
                for event in super().build(plan_id, cancelled, progress):
                    if event['building']:
                        self._matrix_key = None
                    yield event
        except BaseException:
            self._matrix_key = None
            raise
        if not upgrade or cancelled():
            return
        if not self._ready_to_retire(super().status()):
            self.db.execute("DELETE FROM metadata WHERE key='legacy_cleanup'")
            self.db.commit()
            return
        self.active = self._cleaning = True
        try:
            yield self.status()
            if cancelled(): return
            try:
                self._cleanup_legacy()
            except (OSError, ValueError, RuntimeError, MemoryError, sqlite3.Error):
                # A failed cleanup does not invalidate a completed new index.
                # Store only a state, never paths or raw backend errors.
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('legacy_cleanup','failed')")
            else:
                self.db.execute("DELETE FROM metadata WHERE key='legacy_cleanup'")
            self.db.commit()
        finally:
            self.active = self._cleaning = False
            self._legacy = None

    def clear(self):
        self._matrix_key = None
        self._matrices.clear()
        super().clear()
