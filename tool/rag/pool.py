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
            COMMIT;
        ''')
        self.views = {}; self.ann = None
        try:
            rebuilt = self.reload(progress=progress, cancelled=cancelled)
            if rebuilt:
                if progress: progress('saving', 0, 0)
                self.checkpoint(cancelled=cancelled)
        except BaseException:
            self.db.close()
            raise

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
        rebuilt = False
        try:
            saved = json.loads((self.folder / 'ann.json').read_text('utf-8'))
            if saved['generation'] != generation: raise ValueError('stale_ann')
            ann.load(str(self.folder / 'vectors.usearch'))
            if len(ann) != total:
                raise ValueError('invalid_ann')
        except (OSError,ValueError,KeyError,RuntimeError):
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
        self.ann = ann
        for view in self.views.values(): view.refresh()
        return rebuilt

    def checkpoint(self, *, cancelled=lambda: False):
        if cancelled(): raise ValueError('cancelled')
        temporary = self.folder / 'vectors.usearch.tmp'
        self.ann.save(str(temporary))
        if cancelled(): raise ValueError('cancelled')
        os.replace(temporary,self.folder/'vectors.usearch')
        generation = self.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        temp = self.folder/'ann.json.tmp'
        temp.write_text(json.dumps({'generation':generation,'count':len(self.ann)}),'utf-8')
        os.replace(temp,self.folder/'ann.json')

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
                if batch:self.ann.add(np.array([r[0] for r in batch],dtype=np.uint64),np.stack([np.frombuffer(r[1],dtype=np.float32) for r in batch]))
            self.checkpoint()
        with self.db:
            self.db.execute("INSERT OR REPLACE INTO pool_metadata VALUES(?,'pool_migrated','1')",(name,))
            self.db.execute('INSERT OR IGNORE INTO pool_migrations VALUES(?)',(name,))

    def close(self):
        self.checkpoint(); self.db.close()


class CollectionAnn:
    """A source-filtered view of one ANN; small scopes use exact pool rows."""
    def __init__(self,pool,name): self.pool=pool;self.name=name;self.keys=set()
    def refresh(self):
        self.keys={r[0] for r in self.pool.db.execute('SELECT id FROM pool_documents WHERE collection=?',(self.name,))}
    def __len__(self): return len(self.keys)
    def __contains__(self,key): return key in self.keys
    def add(self,key,vector): self.pool.ann.add(key,vector);self.keys.add(key)
    def remove(self,key): self.pool.ann.remove(key);self.keys.discard(key)
    def search(self,vector,count):
        import numpy as np
        count=min(count,len(self.keys))
        if not count:return SimpleNamespace(keys=[])
        if len(self.keys)>16384:
            overfetch=min(len(self.pool.ann),max(count,int(count*len(self.pool.ann)/len(self.keys)*2)))
            candidates=[int(k) for k in self.pool.ann.search(vector,overfetch).keys if int(k) in self.keys]
            if len(candidates)>=count:return SimpleNamespace(keys=candidates[:count])
        # Exact filtered ranking avoids losing tiny sources to a large global
        # top-k. Read in bounded batches, never copy the entire pool in memory.
        import heapq
        best=[]
        cursor=self.pool.db.execute('SELECT id,vector FROM pool_documents WHERE collection=?',(self.name,))
        while batch:=cursor.fetchmany(512):
            matrix=np.stack([np.frombuffer(row[1],dtype=np.float32) for row in batch])
            scores=(matrix@vector)/np.maximum(np.linalg.norm(matrix,axis=1),1e-8)
            best=heapq.nlargest(count,(*best,*((float(score),row[0]) for score,row in zip(scores,batch))))
        return SimpleNamespace(keys=[key for _,key in best])
