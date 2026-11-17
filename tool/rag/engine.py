"""Persistent, resumable tag vectors and a derived USearch ANN index.

Sources are opened read-only. Only an explicit confirmed plan creates vectors.
Draft windows are query data and are never written into the index or diagnostics.
"""
import hashlib
from functools import lru_cache
import json
import os
from pathlib import Path
import sqlite3
import time

from pool import VectorPool


def readonly(path, *, timeout=5.0):
    return sqlite3.connect(Path(path).resolve(strict=True).as_uri() + '?mode=ro', uri=True, timeout=timeout)


@lru_cache(maxsize=32)
def _database_digest(path, stamp):
    # The physical stamp is a cache key, not the persisted source identity.
    db = readonly(path)
    try:
        # Pin the visible SQLite snapshot, including committed WAL pages.
        db.execute('BEGIN')
        db.execute('SELECT name FROM sqlite_master LIMIT 1').fetchone()
        return hashlib.sha256(db.serialize()).hexdigest()
    finally: db.close()


def file_stamp(path):
    try:
        stat = Path(path).stat()
        return stat.st_size, stat.st_mtime_ns, stat.st_dev, stat.st_ino
    except FileNotFoundError:
        return None


def sqlite_stamp(path):
    wal = file_stamp(str(path) + '-wal')
    return file_stamp(path), wal if wal and wal[0] else None


def settled_snapshot(cache, stamp, read):
    # SQLite publishes a WAL commit after writing it. A read racing the commit
    # can still see old rows at the new stamp. Recheck that stamp once settled.
    now = time.monotonic()
    if not cache or cache[0] != stamp:
        return stamp, read(), now + 5
    if cache[2] is not None and now >= cache[2]:
        return stamp, read(), None
    return cache


class Sources:
    """Read-only catalog metadata; tag_corpus owns the embedding representation."""
    representation_version = 'catalog-profiles-v1'

    def __init__(self, catalog, runtime='', wiki='', semantics='', supplements='', *, optional_supplements=False):
        self.paths = [str(Path(p).resolve(strict=True)) if p else '' for p in (catalog, runtime, wiki, semantics, supplements)]
        self._count_cache = None
        self._runtime_snapshot = None
        self.optional_supplements = optional_supplements
        self.degraded = False

    def _file_stamp(self, paths):
        records = []
        for name in paths:
            if not name: continue
            for p in (Path(name), Path(name + '-wal')):
                if p.exists():
                    s = p.stat()
                    # Empty WAL creation does not invalidate cached snapshots.
                    if p.name.endswith('-wal') and not s.st_size: continue
                    records.append((str(p), s.st_size, s.st_mtime_ns))
        return hashlib.sha256(json.dumps([self.representation_version, records]).encode()).hexdigest()

    def _file_signature(self, paths):
        records = [(name, self._runtime_signature() if name == self.paths[1]
                    else _database_digest(name, self._file_stamp([name])))
                   for name in paths if name]
        return hashlib.sha256(json.dumps([self.representation_version, records]).encode()).hexdigest()

    def _runtime_signature(self):
        path = self.paths[1]

        def read():
            db = readonly(path)
            try:
                if not db.execute("SELECT 1 FROM sqlite_master WHERE name='danbooru_tags'").fetchone():
                    return None
                digest = hashlib.sha256()
                for row in db.execute('SELECT tag,category,post_count FROM danbooru_tags ORDER BY tag'):
                    digest.update(json.dumps(row, separators=(',', ':')).encode())
                return digest.hexdigest()
            finally:
                db.close()

        self._runtime_snapshot = settled_snapshot(self._runtime_snapshot, sqlite_stamp(path), read)
        return self._runtime_snapshot[1]

    def change_state(self):
        revision = 0
        if self.paths[4]:
            db = readonly(self.paths[4], timeout=0.2)
            try: revision = db.execute('SELECT revision FROM semantic_state').fetchone()[0]
            except sqlite3.OperationalError: revision = None
            finally: db.close()
        return {'base':self._file_signature(self.paths[:4]), 'revision':revision}

    def signature(self, state=None):
        if state is None: state = self.change_state()
        if state['revision'] is None: return self._file_stamp(self.paths)
        return hashlib.sha256(json.dumps([state,self.paths[4]]).encode()).hexdigest()

    def changed_names(self, metadata):
        state = self.change_state()
        if (state['revision'] is None or not self.paths[4] or
            metadata.get('source_base') != state['base'] or 'semantic_revision' not in metadata): return None
        db, union = self.connect()
        try:
            return [r[0] for r in db.execute('SELECT c.tag FROM supplements.semantic_changes c JOIN ('+union+
                ') t ON t.name=c.tag WHERE c.revision>? ORDER BY c.revision,c.tag', (int(metadata['semantic_revision']),))]
        finally: db.close()

    def connect(self, *, details=True):
        db = readonly(self.paths[0])
        if self.optional_supplements: db.execute('PRAGMA busy_timeout=200')
        runtime = False
        if self.paths[1]:
            db.execute('ATTACH DATABASE ? AS runtime', (Path(self.paths[1]).as_uri() + '?mode=ro',))
            runtime = bool(db.execute("SELECT 1 FROM runtime.sqlite_master WHERE name='danbooru_tags'").fetchone())
        if details and self.paths[2]:
            db.execute('ATTACH DATABASE ? AS wiki', (Path(self.paths[2]).as_uri() + '?mode=ro',))
        for schema, name in zip(('semantics', 'supplements'), self.paths[3:]):
            if not details or not name: continue
            try:
                db.execute('ATTACH DATABASE ? AS ' + schema, (Path(name).as_uri() + '?mode=ro',))
                if schema == 'supplements' and self.optional_supplements:
                    db.execute('SELECT tag FROM supplements.tag_semantics LIMIT 1').fetchone()
            except sqlite3.OperationalError as error:
                db.close()
                if (schema != 'supplements' or not self.optional_supplements or
                    getattr(error, 'sqlite_errorcode', 0) & 255 not in (sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED)):
                    raise
                # Only the per-search Sources copy may omit an unavailable overlay.
                self.paths[4] = ''; self.degraded = True
                return self.connect()
        union = ('SELECT tag name, category, post_count FROM runtime.danbooru_tags UNION ALL '
                 'SELECT name, category, post_count FROM tags t WHERE NOT EXISTS '
                 '(SELECT 1 FROM runtime.danbooru_tags r WHERE r.tag=t.name)' if runtime else
                 'SELECT name, category, post_count FROM tags')
        return db, union

    def count(self):
        signature = self._file_signature(self.paths[:2])
        if self._count_cache and self._count_cache[0] == signature:
            return self._count_cache[1]
        db, union = self.connect(details=False)
        try:
            total = db.execute('SELECT COUNT(*) FROM (' + union + ')').fetchone()[0]
            if self._file_signature(self.paths[:2]) == signature: self._count_cache = (signature, total)
            return total
        finally: db.close()

    def rows(self, offset=0, limit=64, names=None):
        db, union = self.connect()
        try:
            sql = 'SELECT name, category, post_count FROM (' + union + ')'
            args = []
            if names is not None:
                if not names: return []
                # The catalog's name index is NOCASE, the runtime's is BINARY.
                # Enable both indexes while preserving the union's comparison.
                slots = ','.join('?' for _ in names)
                sql += ' WHERE name COLLATE NOCASE IN ('+slots+') AND name IN ('+slots+')'
                args.extend(names); args.extend(names)
            sql += ' ORDER BY post_count DESC, name LIMIT ? OFFSET ?'; args.extend([limit, offset])
            rows = db.execute(sql, args).fetchall(); result = []
            if not rows: return result
            names = [row[0] for row in rows]
            slots = ','.join('?' for _ in names)
            aliases_by_name = {name:[] for name in names}
            for name, alias in db.execute('SELECT t.name,a.alias FROM aliases a JOIN tags t ON t.id=a.tag_id '
                    'WHERE t.name IN ('+slots+') ORDER BY t.name,a.alias',names):
                if len(aliases_by_name[name]) < 24: aliases_by_name[name].append(alias)
            bodies = dict(db.execute('SELECT tag,body FROM wiki.wiki_pages WHERE tag IN ('+slots+')',names)) if self.paths[2] else {}
            profiles = {}
            saved_hashes = {}
            for schema, path in zip(('semantics','supplements'),self.paths[3:]):
                if not path: continue
                profiles[schema] = {row[0]:row[1:] for row in db.execute(
                    'SELECT tag,core_zh,synonyms_zh,summary_zh FROM '+schema+'.tag_semantics WHERE tag IN ('+slots+')',names)}
                if schema == 'supplements' and any(row[2] for row in profiles[schema].values()):
                    columns = {r[1] for r in db.execute('PRAGMA supplements.table_info(tag_semantics)')}
                    column = 'summary_hash' if 'summary_hash' in columns else 'wiki_hash'
                    saved_hashes = dict(db.execute('SELECT tag,'+column+' FROM supplements.tag_semantics WHERE tag IN ('+slots+')',names))
            for name, category, count in rows:
                aliases = aliases_by_name[name]
                full_body = bodies.get(name) or ''; body = full_body[:500]
                profile = {'core_zh':'', 'synonyms_zh':[], 'summary_zh':''}
                for schema, records in profiles.items():
                    row = records.get(name)
                    if row:
                        summary = row[2]
                        if schema == 'supplements' and summary:
                            if saved_hashes[name] != hashlib.sha256(full_body.encode()).hexdigest(): summary = ''
                        for key, value in zip(profile, (row[0], json.loads(row[1]), summary)):
                            if value: profile[key] = value
                result.append({'name': name, 'category': category, 'post_count': count,
                    'aliases': aliases, 'wiki': body, **profile})
            return result
        finally: db.close()

    def ordered_names(self):
        # Sort once per pass, rather than sorting the entire catalogue again
        # for every 32 vectors. Keep only names in memory, not a long-lived
        # source transaction that would pin the runtime database's WAL.
        db, union = self.connect(details=False)
        try:
            return [r[0] for r in db.execute('SELECT name FROM (' + union + ') ORDER BY post_count DESC, name')]
        finally: db.close()


class Engine:
    batch_size = 32
    def __init__(self, directory, models, sources, *, pool=None, collection='tags'):
        self.models = models; self.sources = sources
        self.root = Path(directory).resolve()
        self.pool = pool or VectorPool(self.root,models.fingerprint)
        self._owns_pool = pool is None; self.collection = collection
        self.folder = self.pool.folder
        self.db,self.ann = self.pool.collection(collection,self.root/models.fingerprint)
        self.plan = None; self.active = False; self.writing = False; self._ann_generation = 0; self._closed = False

    def _load_ann(self):
        self.pool.reload()
        self.ann = self.pool.views[self.collection]

    def _checkpoint(self): self.pool.checkpoint()

    def status(self):
        count = len(self.ann)
        total = self.sources.count()
        row = self.db.execute("SELECT value FROM metadata WHERE key='complete_signature'").fetchone()
        complete = bool(row and row[0] == self.sources.signature())
        size = self.pool.collection_bytes(self.collection)
        metadata = dict(self.db.execute('SELECT key,value FROM metadata'))
        return {'indexed': count, 'total': total, 'complete': complete,
                'auto_update_allowed': metadata.get('consented') == '1' and metadata.get('paused') != '1' and not metadata.get('build_error'),
                'partial': bool(count and not complete), 'bytes': size,
                'building': self.active and self.writing, 'checking': self.active and not self.writing,
                'paused': metadata.get('paused') == '1', 'skipped': int(metadata.get('skipped','0')),
                'error': metadata.get('build_error')}

    def preview(self):
        state = self.sources.change_state() if isinstance(self.sources,Sources) else None
        self.plan = {'source_signature': self.sources.signature(state) if state is not None else self.sources.signature(),
                     'model_fingerprint': self.models.fingerprint,
                     'total': self.sources.count(), 'expires': time.monotonic() + 1800}
        if state is not None:
            self.plan['source_state'] = state
            changes = self.sources.changed_names(dict(self.db.execute('SELECT key,value FROM metadata')))
            if changes is not None: self.plan['incremental_names'] = changes
        self.plan['plan_id'] = hashlib.sha256(json.dumps(self.plan, sort_keys=True).encode()).hexdigest()
        return {k: v for k, v in self.plan.items() if k not in ('expires','incremental_names','source_state')}

    def embed_rows(self, rows):
        return self.models.embed([item['text'] for item in rows])

    def set_paused(self, paused):
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused',?)", ('1' if paused else '0',))
        self.db.commit()

    def set_build_error(self, code):
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('build_error',?)", (code,))
        self.db.commit()

    def validate_plan(self, plan_id):
        if not self.plan or self.plan['plan_id'] != plan_id or self.plan['expires'] < time.monotonic():
            raise ValueError('invalid_plan')
        signature = self.sources.signature()
        if signature != self.plan['source_signature']: raise ValueError('source_changed')

    def build(self, plan_id, cancelled, progress=None):
        if self.active: raise ValueError('index_busy')
        self.validate_plan(plan_id)
        signature = self.plan['source_signature']
        plan = self.plan; self.plan = None; self.active = True; self.writing = False
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('consented','1')")
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused','0')")
        self.db.execute("DELETE FROM metadata WHERE key='build_error'")
        self.db.commit()
        processed = 0; skipped = 0; closing = False
        self.pool.begin_build()
        try:
            incremental = 'incremental_names' in plan
            names = plan['incremental_names'] if incremental else self.sources.ordered_names()
            work_total = len(names) if incremental else plan['total']
            while processed < work_total:
                if cancelled(): break
                if self.sources.signature() != signature: raise ValueError('source_changed')
                batch = names[processed:processed+self.batch_size]
                rows = self.sources.rows(names=batch, limit=self.batch_size)
                if len(rows) != len(batch) and not getattr(self.sources, 'sparse_views', False):
                    raise ValueError('source_changed')
                missing = set(batch) - {item['name'] for item in rows}
                old = dict(self.db.execute('SELECT name,digest FROM documents WHERE name IN ('+
                    ','.join('?' for _ in rows)+')',[item['name'] for item in rows])) if rows else {}
                pending = []; unchanged = []
                for item in rows:
                    if old.get(item['name']) != item['digest']: pending.append(item)
                    else: unchanged.append((signature,item['post_count'],item['name']))
                if unchanged:
                    self.db.executemany('UPDATE documents SET seen=?, post_count=? WHERE name=?',unchanged)
                self.writing = bool(pending)
                if pending:
                    if progress: progress({'processed':max(0,plan['total']-work_total+processed), **self.status()})
                    vectors = self.embed_rows(pending)
                    if cancelled(): break
                    for item, vector in zip(pending, vectors):
                        if vector is None:
                            skipped += 1
                            continue
                        old = self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()
                        self.db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?)',
                            (item['name'], item['category'], item['post_count'], json.dumps(item['aliases']), item['text'], item['digest'], vector.tobytes(), signature))
                        key = old[0] if old else self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()[0]
                        if old and key in self.ann: self.ann.remove(key)
                        self.ann.add(key, vector)
                for name in missing:
                    prior = self.db.execute('SELECT id FROM documents WHERE name=?', (name,)).fetchone()
                    if prior and prior[0] in self.ann: self.ann.remove(prior[0])
                    self.db.execute('DELETE FROM documents WHERE name=?', (name,))
                self._ann_generation += 1
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('skipped',?)", (str(skipped),))
                self.db.commit(); processed += len(batch)
                if processed % 32768 == 0: self._checkpoint()
                yield {'processed': max(0,plan['total']-work_total+processed), 'total': plan['total'], **self.status()}
            if not cancelled() and processed == work_total:
                if self.sources.signature() != signature: raise ValueError('source_changed')
                stale = [] if incremental else [r[0] for r in self.db.execute('SELECT id FROM documents WHERE seen != ?', (signature,))]
                if stale:
                    self.writing = True
                    if progress: progress({'processed':plan['total'], **self.status()})
                for key in stale:
                    if key in self.ann: self.ann.remove(key)
                if not incremental: self.db.execute('DELETE FROM documents WHERE seen != ?', (signature,))
                if stale:
                    # Invalidate a checkpoint saved just before final cleanup;
                    # a crash must not reload deleted IDs from that older ANN.
                    self._ann_generation += 1
                    self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('complete_signature',?)", (signature,))
                if isinstance(self.sources,Sources):
                    state = plan['source_state']
                    self.db.execute("INSERT OR REPLACE INTO metadata VALUES('source_base',?)", (state['base'],))
                    if state['revision'] is not None:
                        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('semantic_revision',?)", (str(state['revision']),))
                self.db.commit()
        except GeneratorExit:
            # close() can only interrupt a suspended yield: both SQLite and
            # ANN already contain the committed batch. The pool owner saves
            # once after all builders/connections have been closed.
            closing = True
            raise
        except BaseException:
            self.db.rollback(); self._load_ann()
            raise
        finally:
            self.db.rollback(); self.active = False; self.writing = False
            self.pool.end_build()
            if not closing: self._checkpoint()

    def clear(self):
        if self.active: raise ValueError('index_busy')
        self.db.execute('DELETE FROM documents'); self.db.execute('DELETE FROM metadata'); self.db.commit()
        self._load_ann(); self._checkpoint(); self.db.execute('VACUUM')

    def close(self):
        if self._closed: return
        self.db.close(); self._closed = True
        if self._owns_pool: self.pool.close()
