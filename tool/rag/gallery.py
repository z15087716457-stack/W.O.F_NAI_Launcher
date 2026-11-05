"""Local gallery: independent visual vectors and NAI-only text passages.

Source DB and original images are read-only. No metadata extractor, URLs,
captions, audio, or image bytes are sent to the text reranker.
"""
import hashlib
import heapq
import json
import os
from pathlib import Path
import time

from documents import CHUNK, OVERLAP, TextEngine, TextSources, count_chunks, document, key
from engine import Engine, file_stamp, readonly, settled_snapshot, sqlite_stamp
from pool import VectorPool

EXTENSIONS = {'.png','.jpg','.jpeg','.webp','.bmp','.gif','.tif','.tiff','.avif'}
NAI = """COALESCE(m.has_metadata,0)=1 AND (
 m.software LIKE '%NovelAI%' OR m.source LIKE '%NovelAI%' OR m.model LIKE 'nai-diffusion%'
 OR m.raw_json LIKE '%ucPreset%' OR m.raw_json LIKE '%request_type%' OR m.raw_json LIKE '%v4_prompt%'
 OR m.raw_json LIKE '%signed_hash%' OR m.raw_json LIKE '%noise_schedule%')"""


def path_key(path):
    return os.path.normcase(os.path.abspath(path))


def under_root(path, root):
    try:
        return path != root and os.path.commonpath((path, root)) == root
    except ValueError:  # Different drives on Windows.
        return False


def image_stamp(path):
    try:
        info = Path(path).stat()
        return [info.st_size,info.st_mtime_ns,info.st_dev,info.st_ino]
    except OSError: return None


def load_image(path):
    from PIL import Image, ImageOps
    # Copy and orient only in memory; never save or strip the original file.
    with Image.open(path) as source:
        source.seek(0)
        if source.width*source.height > 80_000_000: raise ValueError('image_too_large')
        image = ImageOps.exif_transpose(source).convert('RGB')
        image.thumbnail((2048,2048))
        return image


class GallerySources(TextSources):
    def __init__(self, database, roots_file, visual=True):
        super().__init__(database)
        self.roots_file = Path(roots_file).resolve(strict=True)
        self.visual = visual
        self._records_cache = None
        self._roots_cache = None

    def roots(self):
        stamp = file_stamp(self.roots_file)
        if not self._roots_cache or self._roots_cache[0] != stamp:
            data = json.loads(self.roots_file.read_text('utf-8'))
            if data.get('version') != 1 or not isinstance(data.get('roots'), list):
                raise ValueError('invalid_snapshot')
            roots = tuple(sorted({path_key(p) for p in data['roots'] if isinstance(p, str) and p}))
            self._roots_cache = stamp, roots
        return self._roots_cache[1]

    def contains(self, path, physical=False):
        value = path_key(Path(path).resolve()) if physical else path_key(path)
        for root in self.roots():
            boundary = path_key(Path(root).resolve()) if physical else root
            if under_root(value, boundary):
                return True
        return False

    def snapshot(self):
        roots = self.roots()

        def read():
            records = self.records(roots=roots)
            signature = hashlib.sha256(json.dumps(
                ['gallery-v2-image2048-exif-rgb', CHUNK, OVERLAP, roots, records],
                separators=(',', ':')).encode()).hexdigest()
            if self._records_cache and self._records_cache[1][1] == signature:
                return self._records_cache[1]
            return records, signature

        self._records_cache = settled_snapshot(
            self._records_cache, (roots, sqlite_stamp(self.path)), read)
        return self._records_cache[1]

    def signature(self):
        return self.snapshot()[1]

    def records(self, owners=None, *, roots=None):
        db = readonly(self.path)
        try:
            if not db.execute("SELECT 1 FROM sqlite_master WHERE name='gallery_images'").fetchone(): return {}
            if owners == []: return {}
            if self.visual:
                sql = 'SELECT i.id,i.file_path,i.file_size,i.modified_at FROM gallery_images i WHERE i.is_deleted=0'
            else:
                sql = '''SELECT i.id,i.file_path,COALESCE(NULLIF(m.positive_prompt_text,''),m.prompt),m.negative_prompt,m.model,m.sampler,
                    m.steps,m.cfg_scale,m.seed,m.width,m.height FROM gallery_images i
                    JOIN gallery_metadata m ON m.image_id=i.id WHERE i.is_deleted=0 AND ('''+NAI+')'
            args = []
            if owners is not None:
                sql += ' AND i.id IN (' + ','.join('?' for _ in owners) + ')'; args.extend(owners)
            rows = db.execute(sql+' ORDER BY i.id',args)
            result = {}
            if roots is None: roots = self.roots()
            for row in rows:
                path = row[1]
                if Path(path).suffix.lower() not in EXTENSIONS: continue
                value = path_key(path)
                if not any(under_root(value, root) for root in roots):
                    continue
                body = '' if self.visual else '\n'.join([
                    'Positive prompt: '+(row[2] or ''), 'Negative prompt (excluded content): '+(row[3] or ''),
                    '; '.join(f'{name}: {value}' for name,value in zip(
                        ('model','sampler','steps','guidance','seed','width','height'),row[4:]) if value is not None)])
                result[str(row[0])] = ({'path': path, 'file': row[2:4]} if self.visual
                                       else {'path': path, 'body': body})
            return result
        finally: db.close()

    def catalogue(self):
        return self.snapshot()[0]

    def size(self, row):
        return 1 if self.visual else count_chunks(row['body'])

    def counts(self):
        records, signature = self.snapshot()
        if not self._counts or self._counts[0] != signature:
            self._counts = signature, (len(records), len(records) if self.visual else
                                       sum(self.size(row) for row in records.values()))
        return self._counts[1]

    def _document(self, owner, row, index):
        if self.visual:
            stamp = image_stamp(row['path'])
            return {'name':key(owner,'image',0),'owner':owner,'path':row['path'],'stamp':stamp,
                'category':0,'post_count':0,'aliases':[],'text':'',
                'digest':hashlib.sha256(json.dumps([owner,stamp,'visual-v1']).encode()).hexdigest()}
        item = document(owner, Path(row['path']).name, 'parameters', index, row['body'])
        item['path'] = row['path']
        return item

    def documents(self, owner, row):
        return [self._document(owner, row, index) for index in range(self.size(row))]

    def rows(self, offset=0, limit=64, names=None):
        section = 'image' if self.visual else 'parameters'
        if names is None:
            names = [key(owner, section, index) for owner, row in self.catalogue().items()
                     for index in range(self.size(row))][offset:offset+limit]
        decoded = [json.loads(name) for name in names[:limit]]
        records = self.records(list(dict.fromkeys(item[0] for item in decoded)))
        return [self._document(owner, row, index) for owner, kind, index in decoded
                if kind == section and (row := records.get(owner)) and 0 <= index < self.size(row)]

    def allowed_owners(self, paths):
        wanted = {path_key(path) for path in paths}
        return [owner for owner,row in self.catalogue().items() if path_key(row['path']) in wanted]


class GalleryIndex:
    """Reconcile documents by picture; only the first pass needs old owners from SQLite.

    The live row catalogue is kept in memory. A restart checks the image files
    again, while existing document digests still avoid unnecessary embedding.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._indexed = None
        self._indexed_roots = None
        self._skipped = set()

    def clear(self):
        super().clear()
        self._indexed = None
        self._skipped.clear()

    def _batches(self, owners, records):
        plans = []
        pending = []
        for owner in owners:
            row = records.get(owner)
            expected = self.sources.documents(owner, row) if row is not None else []
            stored = {name: (doc_id, digest) for doc_id, name, digest in self.db.execute(
                "SELECT id,name,digest FROM pool_documents WHERE collection=? AND json_valid(name) "
                "AND json_extract(name,'$[0]')=?", (self.collection, owner))}
            plans.append((owner, row, expected, stored))
            pending.extend(item for item in expected
                           if item['name'] not in stored or stored[item['name']][1] != item['digest'])
            if len(pending) >= self.batch_size or len(plans) >= 256:
                yield plans, pending
                plans = []
                pending = []
        if plans:
            yield plans, pending

    def _write_batch(self, plans, vectors, signature):
        removed, added, skipped = [], [], set()
        with self.db:
            for owner, _, expected, stored in plans:
                kept = set()
                for item in expected:
                    name = item['name']
                    if name in vectors:
                        vector = vectors[name]
                        if vector is None:
                            skipped.add(owner)
                            continue
                        self.db.execute(
                            'INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) '
                            'VALUES(?,?,?,?,?,?,?,?)',
                            (name, item['category'], item['post_count'], json.dumps(item['aliases']),
                             item['text'], item['digest'], vector.tobytes(), signature))
                        doc_id = stored[name][0] if name in stored else self.db.execute(
                            'SELECT id FROM documents WHERE name=?', (name,)).fetchone()[0]
                        if name in stored:
                            removed.append(doc_id)
                        added.append((doc_id, vector))
                    kept.add(name)
                for name, (doc_id, _) in stored.items():
                    if name not in kept:
                        self.db.execute('DELETE FROM documents WHERE id=?', (doc_id,))
                        removed.append(doc_id)

        return removed, added, skipped

    def _apply_batch(self, removed, added):
        # The authoritative rows are committed before their in-memory graph.
        try:
            for doc_id in removed:
                if doc_id in self.ann:
                    self.ann.remove(doc_id)
            for doc_id, vector in added:
                self.ann.add(doc_id, vector)
        except Exception:
            self._load_ann()
            raise

    def build_pictures(self, signature, verify, cancelled, progress):
        records, current = self.sources.snapshot()
        if signature != current:
            raise ValueError('source_changed')
        roots = self.sources.roots()
        full = verify or self._indexed is None or self._indexed_roots != roots
        if full:
            previous = {row[0] for row in self.db.execute(
                "SELECT DISTINCT json_extract(name,'$[0]') FROM pool_documents "
                "WHERE collection=? AND json_valid(name)", (self.collection,))}
            owners = list(records)
            self._indexed = None
            indexed, skipped = {}, set()
        else:
            indexed, skipped = self._indexed, self._skipped
            previous = indexed.keys()
            owners = [owner for owner, row in records.items()
                      if indexed.get(owner) != row or owner in skipped]
        owners.extend(owner for owner in previous if owner not in records)
        processed = 0 if full else self.sources.count() - sum(
            self.sources.size(records[owner]) for owner in owners if owner in records)
        self.active = True
        self.writing = False
        with self.db:
            self.db.executemany('INSERT OR REPLACE INTO metadata VALUES(?,?)',
                                [('consented', '1'), ('paused', '0')])
        try:
            for plans, pending in self._batches(owners, records):
                if cancelled():
                    return
                if self.sources.signature() != signature:
                    raise ValueError('source_changed')
                self.writing = bool(pending)
                if pending and progress:
                    progress({'processed': processed, **self.status()})
                vectors = {}
                for offset in range(0, len(pending), self.batch_size):
                    batch = pending[offset:offset+self.batch_size]
                    vectors.update((item['name'], vector)
                                   for item, vector in zip(batch, self.embed_rows(batch), strict=True))
                    if cancelled():
                        return
                removed, added, failed = self._write_batch(plans, vectors, signature)
                for owner, row, expected, _ in plans:
                    if row is None:
                        indexed.pop(owner, None)
                    else:
                        indexed[owner] = row
                    skipped.discard(owner)
                    if owner in failed:
                        skipped.add(owner)
                    processed += len(expected)
                self._apply_batch(removed, added)
                yield {'processed': processed, **self.status()}
            if cancelled():
                return
            if self.sources.signature() != signature:
                raise ValueError('source_changed')
            with self.db:
                self.db.executemany('INSERT OR REPLACE INTO metadata VALUES(?,?)',
                                    [('complete_signature', signature), ('skipped', str(len(skipped)))])
            self._indexed, self._indexed_roots, self._skipped = records.copy(), roots, skipped
        finally:
            self.active = False
            self.writing = False


class VisualEngine(GalleryIndex, Engine):
    batch_size = 8

    def embed_rows(self, rows):
        from PIL import Image
        images = []; positions = []; result = [None]*len(rows)
        try:
            for i,row in enumerate(rows):
                try:
                    if not row['stamp'] or not self.sources.contains(row['path'],physical=True): continue
                    image = load_image(row['path'])
                    if image_stamp(row['path'])!=row['stamp']: image.close();continue
                    images.append(image);positions.append(i)
                except (OSError,ValueError,SyntaxError,Image.DecompressionBombError): continue
            if images:
                for i,vector in zip(positions,self.models.embed_images(images)):
                    if image_stamp(rows[i]['path'])==rows[i]['stamp']: result[i] = vector
            return result
        finally:
            for image in images: image.close()

    def search_visual(self, vector, allowed, limit, cancelled):
        import numpy as np
        if not len(self.ann) or allowed == []: return []
        rows = []
        if allowed is None:
            for rank,item in enumerate(self.ann.search(vector,min(160,len(self.ann))).keys):
                row = self.db.execute('SELECT name,digest FROM documents WHERE id=?',(int(item),)).fetchone()
                if row: rows.append((-rank,*row))
        else:
            for offset in range(0,len(allowed),400):
                owners = allowed[offset:offset+400]
                def scores():
                    for name,digest,stored in self.db.execute(
                        "SELECT name,digest,vector FROM documents WHERE json_extract(name,'$[0]') IN ("+','.join('?' for _ in owners)+')',owners):
                        if cancelled(): raise ValueError('cancelled')
                        previous = np.frombuffer(stored,dtype=np.float32)
                        yield (float(np.dot(previous,vector)/max(np.linalg.norm(previous),1e-8)),name,digest)
                rows = heapq.nlargest(160,(*rows,*heapq.nlargest(160,scores())))
        live = {r['name']:r for r in self.sources.rows(names=[r[1] for r in rows],limit=160)}
        result = []
        for _,name,digest in rows:
            row = live.get(name)
            if row and row['stamp'] and row['digest']==digest and self.sources.contains(row['path'],physical=True):
                result.append({'id':row['owner'],'path':row['path'],'channel':'visual'})
                if len(result)==limit: break
        return result


class ParameterEngine(GalleryIndex, TextEngine):
    pass


class GalleryEngine:
    def __init__(self,directory,models,database,roots_file,*,pool=None):
        self.models = models
        self.pool = pool or VectorPool(directory,models.fingerprint)
        self._owns_pool = pool is None
        self.sources = GallerySources(database,roots_file)
        processor = hashlib.sha256(b'wof-gallery-rgb-exif-2048-v1')
        for name in ('preprocessor_config.json','processor_config.json'):
            path = Path(models.embedding_path)/name
            if path.is_file(): processor.update(path.read_bytes())
        self.visual = VisualEngine(Path(directory)/('images-v1-'+processor.hexdigest()[:16]),models,self.sources,pool=self.pool,collection='gallery-images-'+processor.hexdigest()[:16])
        self.text = ParameterEngine(Path(directory)/'nai-text-v1',models,GallerySources(database,roots_file,False),pool=self.pool,collection='gallery-parameters')
        self.plan = None

    def status(self):
        visual = self.visual.status();text = self.text.status()
        complete = visual['complete'] and text['complete']
        return {'indexed':visual['indexed']+text['indexed'],'total':visual['total']+text['total'],
            'complete':complete,'partial':bool(visual['indexed']+text['indexed']) and not complete,
            'bytes':visual['bytes']+text['bytes'],'paused':visual['paused'] or text['paused'],
            'auto_update_allowed':(visual['auto_update_allowed'] or text['auto_update_allowed']) and not(visual['paused'] or text['paused']),
            'building':visual['building'] or text['building'],'skipped':visual['skipped'],
            'images':visual['total'],'visual_indexed':visual['indexed'],'parameter_chunks':text['total'],'parameters_indexed':text['indexed']}

    def signature(self):
        return self.visual.sources.signature(), self.text.sources.signature()

    def preview(self, verify=None):
        status = self.status()
        self.plan = {'expires': time.monotonic() + 1800, 'source_signature': self.signature(),
                     'verify': status['complete'] if verify is None else verify}
        self.plan['plan_id'] = hashlib.sha256(json.dumps(self.plan).encode()).hexdigest()
        return {'plan_id': self.plan['plan_id'], **status}

    def validate_plan(self, plan_id):
        if not self.plan or self.plan['plan_id'] != plan_id or self.plan['expires'] < time.monotonic():
            raise ValueError('invalid_plan')
        if self.plan['source_signature'] != self.signature():
            raise ValueError('source_changed')

    def build(self, plan_id, cancelled, progress=None):
        if self.visual.active or self.text.active:
            raise ValueError('index_busy')
        self.validate_plan(plan_id)
        plan = self.plan
        self.plan = None
        processed = [0, 0]
        generators = [engine.build_pictures(signature, plan['verify'], cancelled,
            (lambda value: progress({**self.status(), 'building': True,
                'processed': sum(processed)})) if progress else None)
            for engine, signature in zip((self.visual, self.text), plan['source_signature'])]
        active = {0, 1}
        closing = False
        self.pool.begin_build()
        try:
            while active and not cancelled():
                for i in list(active):
                    try:
                        processed[i] = next(generators[i])['processed']
                        yield {'processed': sum(processed), **self.status()}
                    except StopIteration:
                        active.remove(i)
        except GeneratorExit:
            closing = True
            raise
        finally:
            for generator in generators:
                generator.close()
            self.pool.end_build()
            if not closing and (self._owns_pool or plan['verify']):
                self.pool.checkpoint()

    def set_paused(self,paused):
        self.visual.set_paused(paused);self.text.set_paused(paused)

    def clear(self):
        self.visual.clear();self.text.clear()

    def close(self):
        self.visual.close();self.text.close()
        if self._owns_pool: self.pool.close()

    def search(self,query,paths,image_path,mode,limit,cancelled):
        if mode not in ('mixed','visual','parameters'): raise ValueError('invalid_source')
        query = query.strip()[:32768]
        while self.models.count(query)>256: query = query[:max(0,len(query)*3//4)]
        visual = [];text = []
        allowed = None if paths is None else self.sources.allowed_owners(paths)
        if allowed is not None and len(allowed)==self.sources.document_count(): allowed = None
        if mode!='parameters' and (query or image_path) and self.visual.status()['indexed']:
            if image_path:
                image = load_image(image_path)
                try: vector = self.models.embed_images([image],text=query)[0]
                finally: image.close()
            else: vector = self.models.embed([query],query=True)[0]
            if cancelled(): raise ValueError('cancelled')
            visual = self.visual.search_visual(vector,allowed,limit,cancelled)
            if image_path:
                visual = [item for item in visual if path_key(item['path'])!=path_key(image_path)]
        if query and mode!='visual' and self.text.status()['indexed']:
            text = self.text.search_text(query,allowed=allowed,limit=limit,cancelled=cancelled)['items']
            records = self.text.sources.records([item['id'] for item in text])
            text = [{**item,'path':records[item['id']]['path'],'channel':'parameters'} for item in text
                    if item['id'] in records and Path(records[item['id']]['path']).is_file()
                    and self.text.sources.contains(records[item['id']]['path'],physical=True)]
        if cancelled(): raise ValueError('cancelled')
        # Rank fusion, never compare raw cross-modal similarity to Qwen scores.
        scores = {};items = {}
        for matches in (visual,text):
            for rank,item in enumerate(matches):
                if image_path and path_key(item['path'])==path_key(image_path): continue
                scores[item['id']] = scores.get(item['id'],0)+1/(60+rank+1)
                if item['id'] in items: item = {**item,'channel':'mixed'}
                items[item['id']] = item
        order = sorted(items,key=lambda owner:-scores[owner])
        return {'items':[items[owner] for owner in order[:limit]]}
