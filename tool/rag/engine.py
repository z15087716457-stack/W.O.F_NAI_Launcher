"""Persistent, resumable tag vectors and a derived USearch ANN index.

Sources are opened read-only. Only an explicit confirmed plan creates vectors.
Draft windows are query data and are never written into the index or diagnostics.
"""
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import time

from context import context_window, clean_tag


def readonly(path):
    return sqlite3.connect(Path(path).resolve(strict=True).as_uri() + '?mode=ro', uri=True)


class Sources:
    def __init__(self, catalog, runtime='', wiki=''):
        self.paths = [str(Path(p).resolve(strict=True)) if p else '' for p in (catalog, runtime, wiki)]
        self._count_cache = None

    def signature(self):
        records = []
        for name in self.paths:
            if not name: continue
            for p in (Path(name), Path(name + '-wal')):
                if p.exists():
                    s = p.stat(); records.append((str(p), s.st_size, s.st_mtime_ns))
        return hashlib.sha256(json.dumps(records).encode()).hexdigest()

    def connect(self):
        db = readonly(self.paths[0])
        runtime = False
        if self.paths[1]:
            db.execute('ATTACH DATABASE ? AS runtime', (Path(self.paths[1]).as_uri() + '?mode=ro',))
            runtime = bool(db.execute("SELECT 1 FROM runtime.sqlite_master WHERE name='danbooru_tags'").fetchone())
        if self.paths[2]:
            db.execute('ATTACH DATABASE ? AS wiki', (Path(self.paths[2]).as_uri() + '?mode=ro',))
        union = ('SELECT tag name, category, post_count FROM runtime.danbooru_tags UNION ALL '
                 'SELECT name, category, post_count FROM tags t WHERE NOT EXISTS '
                 '(SELECT 1 FROM runtime.danbooru_tags r WHERE r.tag=t.name)' if runtime else
                 'SELECT name, category, post_count FROM tags')
        return db, union

    def count(self):
        signature = self.signature()
        if self._count_cache and self._count_cache[0] == signature:
            return self._count_cache[1]
        db, union = self.connect()
        try:
            total = db.execute('SELECT COUNT(*) FROM (' + union + ')').fetchone()[0]
            if self.signature() == signature: self._count_cache = (signature, total)
            return total
        finally: db.close()

    def rows(self, offset=0, limit=64, names=None):
        db, union = self.connect()
        try:
            sql = 'SELECT name, category, post_count FROM (' + union + ')'
            args = []
            if names is not None:
                if not names: return []
                sql += ' WHERE name IN (' + ','.join('?' for _ in names) + ')'; args.extend(names)
            sql += ' ORDER BY post_count DESC, name LIMIT ? OFFSET ?'; args.extend([limit, offset])
            rows = db.execute(sql, args).fetchall(); result = []
            for name, category, count in rows:
                aliases = [r[0] for r in db.execute('SELECT a.alias FROM aliases a JOIN tags t ON t.id=a.tag_id WHERE t.name=? ORDER BY a.alias LIMIT 24', (name,))]
                body = ''
                if self.paths[2]:
                    row = db.execute('SELECT substr(body,1,500) FROM wiki.wiki_pages WHERE tag=?', (name,)).fetchone()
                    if row: body = row[0] or ''
                text = clean_tag(name)
                if aliases: text += '; aliases: ' + ', '.join(aliases)
                if body: text += '; description: ' + body
                digest = hashlib.sha256(json.dumps([text, category], ensure_ascii=False).encode()).hexdigest()
                result.append({'name': name, 'category': category, 'post_count': count,
                    'aliases': aliases, 'text': text, 'digest': digest})
            return result
        finally: db.close()

    def ordered_names(self):
        # Sort once per pass, rather than sorting the entire catalogue again
        # for every 32 vectors. Keep only names in memory, not a long-lived
        # source transaction that would pin the runtime database's WAL.
        db, union = self.connect()
        try:
            return [r[0] for r in db.execute('SELECT name FROM (' + union + ') ORDER BY post_count DESC, name')]
        finally: db.close()


class Engine:
    def __init__(self, directory, models, sources):
        self.models = models; self.sources = sources
        self.root = Path(directory).resolve(); self.root.mkdir(parents=True, exist_ok=True)
        self.folder = self.root / models.fingerprint
        self.folder.mkdir(exist_ok=True)
        self.db = sqlite3.connect(self.folder / 'tags.sqlite')
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.execute('CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY, name TEXT UNIQUE, category INTEGER, post_count INTEGER, aliases TEXT, text TEXT, digest TEXT, vector BLOB, seen TEXT)')
        self.db.execute('CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT)')
        self.db.commit()
        self.ann = None; self.plan = None; self.active = False
        self._ann_generation = 0
        self._load_ann()

    def _load_ann(self):
        import numpy as np
        from usearch.index import Index
        self.ann = Index(ndim=768, metric='cos', dtype='f32')
        generation = self.db.execute("SELECT value FROM metadata WHERE key='ann_generation'").fetchone()
        self._ann_generation = int(generation[0]) if generation else 0
        checkpoint = self.folder / 'ann.json'
        if checkpoint.exists():
            try:
                saved = json.loads(checkpoint.read_text('utf-8'))
                if saved['generation'] == self._ann_generation:
                    self.ann.load(str(self.folder / 'tags.usearch'))
                    if len(self.ann) == saved['count']: return
            except Exception: pass
            self.ann = Index(ndim=768, metric='cos', dtype='f32')
        # SQLite vectors are authoritative; ANN is disposable derived state.
        for row in self.db.execute('SELECT id,vector FROM documents WHERE vector IS NOT NULL'):
            self.ann.add(row[0], np.frombuffer(row[1], dtype=np.float32))

    def _checkpoint(self):
        temporary = self.folder / 'tags.usearch.tmp'
        self.ann.save(str(temporary))
        os.replace(temporary, self.folder / 'tags.usearch')
        metadata = self.folder / 'ann.json.tmp'
        metadata.write_text(json.dumps({'generation':self._ann_generation,'count':len(self.ann)}),encoding='utf-8')
        os.replace(metadata,self.folder / 'ann.json')

    def status(self):
        count = len(self.ann)
        total = self.sources.count()
        row = self.db.execute("SELECT value FROM metadata WHERE key='complete_signature'").fetchone()
        complete = bool(row and row[0] == self.sources.signature())
        size = sum(p.stat().st_size for p in self.folder.iterdir() if p.is_file())
        metadata = dict(self.db.execute('SELECT key,value FROM metadata'))
        return {'indexed': count, 'total': total, 'complete': complete,
                'auto_update_allowed': metadata.get('consented') == '1' and metadata.get('paused') != '1',
                'partial': bool(count and not complete), 'bytes': size, 'building': self.active,
                'paused': metadata.get('paused') == '1'}

    def preview(self):
        self.plan = {'source_signature': self.sources.signature(),
                     'model_fingerprint': self.models.fingerprint,
                     'total': self.sources.count(), 'expires': time.monotonic() + 1800}
        self.plan['plan_id'] = hashlib.sha256(json.dumps(self.plan, sort_keys=True).encode()).hexdigest()
        return {k: v for k, v in self.plan.items() if k != 'expires'}

    def build(self, plan_id, cancelled):
        if self.active: raise ValueError('index_busy')
        if not self.plan or self.plan['plan_id'] != plan_id or self.plan['expires'] < time.monotonic():
            raise ValueError('invalid_plan')
        signature = self.sources.signature()
        if signature != self.plan['source_signature']: raise ValueError('source_changed')
        plan = self.plan; self.plan = None; self.active = True
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('consented','1')")
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused','0')")
        self.db.commit()
        processed = 0
        try:
            names = self.sources.ordered_names()
            while processed < plan['total']:
                if cancelled(): break
                if self.sources.signature() != signature: raise ValueError('source_changed')
                batch = names[processed:processed+32]
                rows = self.sources.rows(names=batch, limit=32)
                if len(rows) != len(batch) or not rows: raise ValueError('source_changed')
                pending = []
                for item in rows:
                    old = self.db.execute('SELECT digest FROM documents WHERE name=?', (item['name'],)).fetchone()
                    if not old or old[0] != item['digest']: pending.append(item)
                    else: self.db.execute('UPDATE documents SET seen=?, post_count=? WHERE name=?', (signature, item['post_count'], item['name']))
                if pending:
                    vectors = self.models.embed([item['text'] for item in pending])
                    if cancelled(): break
                    for item, vector in zip(pending, vectors):
                        old = self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()
                        self.db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(name) DO UPDATE SET category=excluded.category,post_count=excluded.post_count,aliases=excluded.aliases,text=excluded.text,digest=excluded.digest,vector=excluded.vector,seen=excluded.seen',
                            (item['name'], item['category'], item['post_count'], json.dumps(item['aliases']), item['text'], item['digest'], vector.tobytes(), signature))
                        key = old[0] if old else self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()[0]
                        if old and key in self.ann: self.ann.remove(key)
                        self.ann.add(key, vector)
                self._ann_generation += 1
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.commit(); processed += len(rows)
                if processed % 32768 == 0: self._checkpoint()
                yield {'processed': processed, 'total': plan['total'], **self.status()}
            if not cancelled() and processed == plan['total']:
                if self.sources.signature() != signature: raise ValueError('source_changed')
                stale = [r[0] for r in self.db.execute('SELECT id FROM documents WHERE seen != ?', (signature,))]
                for key in stale:
                    if key in self.ann: self.ann.remove(key)
                self.db.execute('DELETE FROM documents WHERE seen != ?', (signature,))
                if stale:
                    # Invalidate a checkpoint saved just before final cleanup;
                    # a crash must not reload deleted IDs from that older ANN.
                    self._ann_generation += 1
                    self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('complete_signature',?)", (signature,))
                self.db.commit()
        except BaseException:
            self.db.rollback(); self._load_ann()
            raise
        finally:
            self.db.rollback(); self.active = False; self._checkpoint()

    def search(self, text, cursor, mode, existing, lexical, negative, limit=40, cancelled=lambda: False, keyword=''):
        import numpy as np
        window = context_window(text, cursor, mode, self.models.count)
        if not window['text'] or not len(self.ann): return {'items': [], 'context_tokens': window['tokens']}
        if cancelled(): raise ValueError('cancelled')
        query_text = window['text']
        if keyword.strip(): query_text = clean_tag(keyword[:1024]) + '; context: ' + query_text
        query = self.models.embed([query_text], query=True)[0]
        matches = self.ann.search(query, min(80, len(self.ann)))
        candidates = {}
        ranks = {}
        for rank, key in enumerate(matches.keys):
            row = self.db.execute('SELECT name,category,post_count,aliases,text,digest FROM documents WHERE id=?', (int(key),)).fetchone()
            if row: candidates[row[0]] = row; ranks[row[0]] = 1/(60+rank+1)
        # Cooccurrence and ordinary matches participate without becoming vectors
        # or requiring a complete index. Recheck all candidates against live data.
        names = list(dict.fromkeys([*candidates, *lexical]))[:160]
        live = {r['name']:r for r in self.sources.rows(names=names, limit=160)}
        excluded = {clean_tag(t).lower() for t in existing}
        valid = []
        for name in names:
            item = live.get(name)
            if not item or clean_tag(name).lower() in excluded: continue
            if any(clean_tag(a).lower() in excluded for a in item['aliases']): continue
            if name in candidates and candidates[name][5] != item['digest'] and name not in lexical: continue
            valid.append(item)
        for rank, name in enumerate(lexical): ranks[name] = ranks.get(name, 0)+1/(60+rank+1)
        valid.sort(key=lambda r:ranks.get(r['name'],0), reverse=True)
        valid = valid[:32]
        if cancelled(): raise ValueError('cancelled')
        scores = self.models.rerank(query_text, [r['text'] for r in valid], negative)
        if cancelled(): raise ValueError('cancelled')
        order = sorted(range(len(valid)), key=lambda i: (-scores[i], -ranks.get(valid[i]['name'],0), valid[i]['name']))
        return {'items':[{k:v for k,v in valid[i].items() if k in ('name','category','post_count','aliases')} for i in order[:max(1,min(limit,80))]],
                'context_tokens': window['tokens'], 'context_mode': mode}

    def clear(self):
        if self.active: raise ValueError('index_busy')
        self.db.execute('DELETE FROM documents'); self.db.execute('DELETE FROM metadata'); self.db.commit()
        self._load_ann(); self._checkpoint(); self.db.execute('VACUUM')

    def close(self):
        self._checkpoint()
        self.db.close()
