"""One persistent vector pool for every source encoded by the same model.

Collection views enforce source boundaries inside a shared SQLite database.
There is one derived ANN, never a second index per language or source.
"""
import json
import os
from pathlib import Path
import re
import sqlite3
import time
from types import SimpleNamespace


class VectorPool:
    def __init__(self, directory, fingerprint, *, progress=None, cancelled=lambda: False):
        self.folder = Path(directory).resolve() / 'pool-v2' / fingerprint
        self.folder.mkdir(parents=True, exist_ok=True)
        self.path = self.folder / 'pool.sqlite'
        self.db = sqlite3.connect(self.path)
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.executescript('''
            CREATE TABLE IF NOT EXISTS pool_documents(
                id INTEGER PRIMARY KEY, collection TEXT NOT NULL, name TEXT NOT NULL,
                category INTEGER, post_count INTEGER, aliases TEXT, text TEXT,
                digest TEXT, vector BLOB, seen TEXT, UNIQUE(collection,name));
            CREATE INDEX IF NOT EXISTS pool_owner ON pool_documents(collection,json_extract(name,'$[0]')) WHERE json_valid(name);
            CREATE INDEX IF NOT EXISTS pool_category ON pool_documents(collection,category);
            CREATE TABLE IF NOT EXISTS pool_metadata(collection TEXT,key TEXT,value TEXT,PRIMARY KEY(collection,key));
            CREATE TABLE IF NOT EXISTS pool_state(key TEXT PRIMARY KEY,value INTEGER);
            CREATE TABLE IF NOT EXISTS pool_migrations(collection TEXT PRIMARY KEY);
            CREATE TABLE IF NOT EXISTS pool_sizes(collection TEXT PRIMARY KEY,bytes INTEGER NOT NULL);
            INSERT OR IGNORE INTO pool_state VALUES('generation',0);
            CREATE TRIGGER IF NOT EXISTS pool_insert AFTER INSERT ON pool_documents BEGIN
                UPDATE pool_state SET value=value+1 WHERE key='generation'; END;
            BEGIN IMMEDIATE;
            DROP TRIGGER IF EXISTS pool_update;
            CREATE TRIGGER pool_update AFTER UPDATE ON pool_documents
                WHEN OLD.id IS NOT NEW.id OR OLD.vector IS NOT NEW.vector
                     OR OLD.collection IS NOT NEW.collection BEGIN
                UPDATE pool_state SET value=value+1 WHERE key='generation'; END;
            CREATE TRIGGER IF NOT EXISTS pool_delete AFTER DELETE ON pool_documents BEGIN
                UPDATE pool_state SET value=value+1 WHERE key='generation'; END;
            CREATE TRIGGER IF NOT EXISTS pool_size_insert AFTER INSERT ON pool_documents BEGIN
                UPDATE pool_sizes SET bytes=bytes+COALESCE(length(NEW.vector)+length(NEW.text)+length(NEW.name),0)
                    WHERE collection=NEW.collection; END;
            CREATE TRIGGER IF NOT EXISTS pool_size_delete AFTER DELETE ON pool_documents BEGIN
                UPDATE pool_sizes SET bytes=bytes-COALESCE(length(OLD.vector)+length(OLD.text)+length(OLD.name),0)
                    WHERE collection=OLD.collection; END;
            CREATE TRIGGER IF NOT EXISTS pool_size_update AFTER UPDATE ON pool_documents
                WHEN OLD.name IS NOT NEW.name OR OLD.text IS NOT NEW.text
                     OR OLD.vector IS NOT NEW.vector OR OLD.collection IS NOT NEW.collection BEGIN
                UPDATE pool_sizes SET bytes=bytes-COALESCE(length(OLD.vector)+length(OLD.text)+length(OLD.name),0)
                    WHERE collection=OLD.collection;
                UPDATE pool_sizes SET bytes=bytes+COALESCE(length(NEW.vector)+length(NEW.text)+length(NEW.name),0)
                    WHERE collection=NEW.collection; END;
            COMMIT;
        ''')
        self.views = {}; self.ann = None; self._checkpoint_state = None; self._closed = False
        self._mapped = False; self._builders = 0
        try:
            rebuilt = self.reload(progress=progress, cancelled=cancelled)
            if rebuilt:
                if progress: progress('saving', 0, 0)
                self.checkpoint(cancelled=cancelled)
        except BaseException:
            if self.ann is not None: self.ann.reset()
            self.db.close()
            raise

    @property
    def mapped(self): return self._mapped

    def _replace_ann(self, ann, *, mapped):
        previous = self.ann
        self.ann = ann; self._mapped = mapped
        # Do not leave an old view holding vectors.usearch open on Windows.
        if previous is not None and previous is not ann: previous.reset()

    def writable(self):
        if self._mapped:
            # Native copy preserves graph, keys, precision and search settings.
            # A failed copy leaves the usable read mapping untouched.
            self._replace_ann(self.ann.copy(), mapped=False)
        return self.ann

    def begin_build(self): self._builders += 1

    def end_build(self):
        assert self._builders > 0
        self._builders -= 1

    def _map_checkpoint(self):
        if self._mapped: return
        from usearch.index import Index
        candidate = Index(ndim=768, metric='cos', dtype='f32')
        try:
            candidate.view(str(self.folder/'vectors.usearch'))
            if len(candidate) != len(self.ann): raise ValueError('invalid_ann')
        except (OSError, ValueError, RuntimeError, MemoryError):
            # Mapping is an optimization. Keep the current mutable ANN usable
            # if the checkpoint cannot be mapped; a later idle save can retry.
            candidate.reset()
            return
        self._replace_ann(candidate, mapped=True)

    def reload(self, *, progress=None, cancelled=lambda: False):
        import numpy as np
        from usearch.index import Index
        def check():
            if cancelled(): raise ValueError('cancelled')
        check()
        ann = Index(ndim=768, metric='cos', dtype='f32')
        generation = self.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        total = self.db.execute('SELECT COUNT(*) FROM pool_documents').fetchone()[0]
        if progress: progress('loading', 0, total)
        rebuilt = False; mapped = False
        try:
            try:
                saved = json.loads((self.folder / 'ann.json').read_text('utf-8'))
                if saved['generation'] != generation: raise ValueError('stale_ann')
                try:
                    ann.view(str(self.folder / 'vectors.usearch'))
                    mapped = True
                except (OSError,ValueError,RuntimeError):
                    # A view failure alone must not rebuild a valid graph or
                    # alter approximate neighbours: retain the old load path.
                    ann.reset()
                    ann = Index(ndim=768, metric='cos', dtype='f32')
                    ann.load(str(self.folder / 'vectors.usearch'))
                if len(ann) != total: raise ValueError('invalid_ann')
            except (OSError,ValueError,KeyError,RuntimeError):
                ann.reset()
                check()
                rebuilt = True
                ann = Index(ndim=768, metric='cos', dtype='f32')
                if progress: progress('restoring', 0, total)
                processed = 0; last_report = time.monotonic()
                cursor=self.db.execute('SELECT id,vector FROM pool_documents')
                while batch:=cursor.fetchmany(256):
                    check()
                    ann.add(np.array([r[0] for r in batch],dtype=np.uint64),
                        np.stack([np.frombuffer(r[1],dtype=np.float32) for r in batch]))
                    processed += len(batch)
                    if progress and (processed == total or time.monotonic() - last_report >= 1):
                        progress('restoring', processed, total); last_report = time.monotonic()
            check()
        except BaseException:
            ann.reset()
            raise
        self._replace_ann(ann, mapped=mapped and not rebuilt)
        # Only a successfully loaded/published checkpoint can suppress saves.
        # A rebuild must replace even a corrupt file with matching metadata.
        self._checkpoint_state = None if rebuilt else (generation, total)
        for view in self.views.values(): view.refresh()
        return rebuilt

    def checkpoint(self, *, cancelled=lambda: False, remap=None):
        if cancelled(): raise ValueError('cancelled')
        remap = not self._builders if remap is None else remap
        generation = self.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        state = (generation, len(self.ann))
        if (state == self._checkpoint_state and (self.folder/'vectors.usearch').is_file()
                and (self.folder/'ann.json').is_file()):
            if remap: self._map_checkpoint()
            return
        # An unusual metadata-only publication can still arrive while mapped.
        # Detach before replacing the mapped path; the live ANN remains usable
        # if saving, cancellation or either atomic publication fails.
        self.writable()
        temporary = self.folder / 'vectors.usearch.tmp'
        self.ann.save(str(temporary))
        if cancelled(): raise ValueError('cancelled')
        os.replace(temporary,self.folder/'vectors.usearch')
        temp = self.folder/'ann.json.tmp'
        temp.write_text(json.dumps({'generation':generation,'count':len(self.ann)}),'utf-8')
        os.replace(temp,self.folder/'ann.json')
        self._checkpoint_state = state
        if remap: self._map_checkpoint()

    def collection_bytes(self, name):
        row = self.db.execute('SELECT bytes FROM pool_sizes WHERE collection=?',(name,)).fetchone()
        if row is None:
            # Backfill old pools once per collection. INSERT...SELECT takes a
            # write transaction; subsequent mutations update the same summary
            # transactionally, including rollbacks and writes via TEMP views.
            with self.db:
                self.db.execute('''INSERT OR IGNORE INTO pool_sizes
                    SELECT ?,COALESCE(SUM(length(vector)+length(text)+length(name)),0)
                    FROM pool_documents WHERE collection=?''',(name,name))
            row = self.db.execute('SELECT bytes FROM pool_sizes WHERE collection=?',(name,)).fetchone()
        return row[0]

    def collection(self, name, legacy):
        if not re.fullmatch(r'[a-z0-9:_-]{1,120}',name): raise ValueError('invalid_source')
        self._migrate(name,legacy)
        db = sqlite3.connect(self.path)
        # Per-connection TEMP views make every existing scoped query safe by
        # construction, including deletes, incremental cleanup and metadata.
        db.executescript(f'''
            CREATE TEMP VIEW documents AS SELECT id,name,category,post_count,aliases,text,digest,vector,seen
                FROM pool_documents WHERE collection='{name}';
            CREATE TEMP TRIGGER documents_insert INSTEAD OF INSERT ON documents BEGIN
                INSERT INTO pool_documents(collection,name,category,post_count,aliases,text,digest,vector,seen)
                VALUES('{name}',NEW.name,NEW.category,NEW.post_count,NEW.aliases,NEW.text,NEW.digest,NEW.vector,NEW.seen)
                ON CONFLICT(collection,name) DO UPDATE SET category=excluded.category,post_count=excluded.post_count,
                    aliases=excluded.aliases,text=excluded.text,digest=excluded.digest,vector=excluded.vector,seen=excluded.seen;
            END;
            CREATE TEMP TRIGGER documents_update INSTEAD OF UPDATE ON documents BEGIN
                UPDATE pool_documents SET name=NEW.name,category=NEW.category,post_count=NEW.post_count,
                    aliases=NEW.aliases,text=NEW.text,digest=NEW.digest,vector=NEW.vector,seen=NEW.seen
                    WHERE id=OLD.id AND collection='{name}'; END;
            CREATE TEMP TRIGGER documents_delete INSTEAD OF DELETE ON documents BEGIN
                DELETE FROM pool_documents WHERE id=OLD.id AND collection='{name}'; END;
            CREATE TEMP VIEW metadata AS SELECT key,value FROM pool_metadata WHERE collection='{name}';
            CREATE TEMP TRIGGER metadata_insert INSTEAD OF INSERT ON metadata BEGIN
                INSERT INTO pool_metadata VALUES('{name}',NEW.key,NEW.value)
                    ON CONFLICT(collection,key) DO UPDATE SET value=excluded.value; END;
            CREATE TEMP TRIGGER metadata_delete INSTEAD OF DELETE ON metadata BEGIN
                DELETE FROM pool_metadata WHERE collection='{name}' AND key=OLD.key; END;
        ''')
        view = self.views.setdefault(name,CollectionAnn(self,name))
        view.refresh()
        return db,view

    def _migrate(self, name, legacy):
        if self.db.execute('SELECT 1 FROM pool_migrations WHERE collection=?',(name,)).fetchone(): return
        previous = Path(legacy)/'tags.sqlite'
        if previous.exists():
            import numpy as np
            old = sqlite3.connect(previous.resolve().as_uri()+'?mode=ro',uri=True)
            try:
                with self.db:
                    for row in old.execute('SELECT name,category,post_count,aliases,text,digest,vector,seen FROM documents'):
                        vector = np.frombuffer(row[6],dtype=np.float32)
                        if vector.shape!=(768,) or not np.isfinite(vector).all() or np.linalg.norm(vector)<1e-8: continue
                        self.db.execute('INSERT OR IGNORE INTO pool_documents(collection,name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?,?)',(name,*row))
                    for key,value in old.execute('SELECT key,value FROM metadata'):
                        self.db.execute('INSERT OR IGNORE INTO pool_metadata VALUES(?,?,?)',(name,key,value))
            finally: old.close()
            cursor=self.db.execute('SELECT id,vector FROM pool_documents WHERE collection=?',(name,))
            while batch:=cursor.fetchmany(256):
                batch=[r for r in batch if r[0] not in self.ann]
                if batch:self.writable().add(np.array([r[0] for r in batch],dtype=np.uint64),np.stack([np.frombuffer(r[1],dtype=np.float32) for r in batch]))
            self.checkpoint()
        with self.db:
            self.db.execute("INSERT OR REPLACE INTO pool_metadata VALUES(?,'pool_migrated','1')",(name,))
            self.db.execute('INSERT OR IGNORE INTO pool_migrations VALUES(?)',(name,))

    def close(self):
        if self._closed: return
        try: self.checkpoint(remap=False)
        finally:
            try: self.db.close()
            finally:
                self._closed = True; self.views.clear()
                if self.ann is not None: self.ann.reset()
                self.ann = None; self._mapped = False


class CollectionAnn:
    """A source-filtered view of one ANN; small scopes use exact pool rows."""
    def __init__(self,pool,name):
        self.pool=pool;self.name=name;self.keys=set()
        self._categories = {}; self._category_version = None
    def refresh(self):
        self.keys={r[0] for r in self.pool.db.execute('SELECT id FROM pool_documents WHERE collection=?',(self.name,))}
        self._categories.clear()
    def __len__(self): return len(self.keys)
    def __contains__(self,key): return key in self.keys
    def add(self,key,vector):
        self.pool.writable().add(key,vector);self.keys.add(key);self._categories.clear()
    def remove(self,key):
        self.pool.writable().remove(key);self.keys.discard(key);self._categories.clear()
    def search(self,vector,count,*,categories=None,min_count=None):
        import numpy as np
        eligible = self.keys
        if categories is not None:
            if not categories:return SimpleNamespace(keys=[],distances=[])
            version = self.pool.db.execute('PRAGMA data_version').fetchone()[0]
            if version != self._category_version:
                self._categories.clear(); self._category_version = version
            categories = tuple(sorted(set(categories)))
            if categories not in self._categories:
                self._categories[categories] = {r[0] for r in self.pool.db.execute(
                    'SELECT id FROM pool_documents WHERE collection=? AND category IN ('+','.join('?' for _ in categories)+')',
                    (self.name,*categories))}
            eligible = self._categories[categories]
        count=min(count,len(eligible))
        if not count:return SimpleNamespace(keys=[],distances=[])
        minimum=count if min_count is None else min(count,min_count)
        if len(eligible)>16384:
            overfetch=min(len(self.pool.ann),max(count,int(count*len(self.pool.ann)/len(eligible)*2)))
            # Category membership is correlated with the query, not uniform.
            # Enlarge the global recall before paying for an exact scope scan.
            for _ in range(4):
                matches=self.pool.ann.search(vector,overfetch)
                candidates=[(int(k),float(d)) for k,d in zip(matches.keys,matches.distances) if int(k) in eligible]
                if len(candidates)>=minimum:return SimpleNamespace(
                    keys=[key for key,_ in candidates[:count]],distances=[distance for _,distance in candidates[:count]])
                if overfetch == len(self.pool.ann): break
                overfetch=min(len(self.pool.ann),max(256,overfetch*8))
        # Exact filtered ranking avoids losing tiny sources to a large global
        # top-k. Read in bounded batches, never copy the entire pool in memory.
        import heapq
        best=[]
        sql='SELECT id,vector FROM pool_documents WHERE collection=?'
        args=(self.name,)
        if categories is not None:
            sql += ' AND category IN ('+','.join('?' for _ in categories)+')'; args += tuple(categories)
        cursor=self.pool.db.execute(sql,args)
        while batch:=cursor.fetchmany(512):
            matrix=np.stack([np.frombuffer(row[1],dtype=np.float32) for row in batch])
            scores=(matrix@vector)/np.maximum(np.linalg.norm(matrix,axis=1),1e-8)
            best=heapq.nlargest(count,(*best,*((float(score),row[0]) for score,row in zip(scores,batch))))
        return SimpleNamespace(keys=[key for _,key in best],distances=[1-score for score,_ in best])
