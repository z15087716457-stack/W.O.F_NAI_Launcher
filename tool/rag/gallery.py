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

from documents import TextEngine, TextSources, count_chunks, document, key
from engine import Engine, readonly
from pool import VectorPool

EXTENSIONS = {'.png','.jpg','.jpeg','.webp','.bmp','.gif','.tif','.tiff','.avif'}
NAI = """COALESCE(m.has_metadata,0)=1 AND (
 m.software LIKE '%NovelAI%' OR m.source LIKE '%NovelAI%' OR m.model LIKE 'nai-diffusion%'
 OR m.raw_json LIKE '%ucPreset%' OR m.raw_json LIKE '%request_type%' OR m.raw_json LIKE '%v4_prompt%'
 OR m.raw_json LIKE '%signed_hash%' OR m.raw_json LIKE '%noise_schedule%')"""


def path_key(path):
    return os.path.normcase(os.path.abspath(path))


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

    def roots(self):
        data = json.loads(self.roots_file.read_text('utf-8'))
        if data.get('version') != 1 or not isinstance(data.get('roots'),list): raise ValueError('invalid_snapshot')
        return [path_key(p) for p in data['roots'] if isinstance(p,str) and p]

    def contains(self, path, physical=False):
        value = path_key(Path(path).resolve()) if physical else path_key(path)
        for root in self.roots():
            try:
                boundary = path_key(Path(root).resolve()) if physical else root
                if os.path.commonpath((value,boundary)) == boundary and value != boundary: return True
            except ValueError: pass
        return False

    def signature(self):
        return hashlib.sha256((super().signature()+self.roots_file.read_text('utf-8')+'gallery-v1-image2048-exif-rgb').encode()).hexdigest()

    def records(self, owners=None):
        db = readonly(self.path)
        try:
            if not db.execute("SELECT 1 FROM sqlite_master WHERE name='gallery_images'").fetchone(): return {}
            if owners == []: return {}
            if self.visual:
                sql = 'SELECT i.id,i.file_path FROM gallery_images i WHERE i.is_deleted=0'
            else:
                sql = '''SELECT i.id,i.file_path,COALESCE(NULLIF(m.positive_prompt_text,''),m.prompt),m.negative_prompt,m.model,m.sampler,
                    m.steps,m.cfg_scale,m.seed,m.width,m.height FROM gallery_images i
                    JOIN gallery_metadata m ON m.image_id=i.id WHERE i.is_deleted=0 AND ('''+NAI+')'
            args = []
            if owners is not None:
                sql += ' AND i.id IN (' + ','.join('?' for _ in owners) + ')'; args.extend(owners)
            rows = db.execute(sql+' ORDER BY i.id',args)
            result = {}
            roots = self.roots()
            for row in rows:
                path = row[1]
                if Path(path).suffix.lower() not in EXTENSIONS: continue
                value = path_key(path)
                try: inside = any(os.path.commonpath((value,r))==r and value!=r for r in roots)
                except ValueError: inside = False
                if not inside: continue
                body = '' if self.visual else '\n'.join([
                    'Positive prompt: '+(row[2] or ''), 'Negative prompt (excluded content): '+(row[3] or ''),
                    '; '.join(f'{name}: {value}' for name,value in zip(
                        ('model','sampler','steps','guidance','seed','width','height'),row[4:]) if value is not None)])
                result[str(row[0])] = {'path':path,'body':body}
            return result
        finally: db.close()

    def catalogue(self):
        signature = self.signature()
        if not self._records_cache or self._records_cache[0] != signature:
            self._records_cache = (signature,self.records())
        return self._records_cache[1]

    def counts(self):
        records = self.catalogue()
        return len(records),sum(1 if self.visual else count_chunks(r['body']) for r in records.values())

    def ordered_names(self):
        return [key(owner,'image' if self.visual else 'parameters',i) for owner,row in self.catalogue().items()
                for i in range(1 if self.visual else count_chunks(row['body']))]

    def rows(self, offset=0, limit=64, names=None):
        if names is None: names = self.ordered_names()[offset:offset+limit]
        decoded = [json.loads(name) for name in names[:limit]]
        records = self.records(list(dict.fromkeys(item[0] for item in decoded)))
        result = []
        for owner,section,index in decoded:
            row = records.get(owner)
            if row is None: continue
            if self.visual:
                if section!='image' or index!=0: continue
                stamp = image_stamp(row['path'])
                result.append({'name':key(owner,section,index),'owner':owner,'path':row['path'],'stamp':stamp,
                    'category':0,'post_count':0,'aliases':[],'text':'',
                    'digest':hashlib.sha256(json.dumps([owner,stamp,'visual-v1']).encode()).hexdigest()})
            elif section=='parameters' and 0<=index<count_chunks(row['body']):
                item = document(owner,Path(row['path']).name,section,index,row['body'])
                item['path'] = row['path'];result.append(item)
        return result

    def allowed_owners(self, paths):
        wanted = {path_key(path) for path in paths}
        return [owner for owner,row in self.catalogue().items() if path_key(row['path']) in wanted]


class VisualEngine(Engine):
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
        self.text = TextEngine(Path(directory)/'nai-text-v1',models,GallerySources(database,roots_file,False),pool=self.pool,collection='gallery-parameters')
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

    def preview(self):
        plans = [self.visual.preview(),self.text.preview()]
        self.plan = {'plan_id':hashlib.sha256(json.dumps(plans,sort_keys=True).encode()).hexdigest(),
            'expires':time.monotonic()+1800,'plans':plans,'source_signature':self.sources.signature()}
        return {'plan_id':self.plan['plan_id'],**self.status()}

    def build(self,plan_id,cancelled):
        if not self.plan or self.plan['plan_id']!=plan_id or self.plan['expires']<time.monotonic(): raise ValueError('invalid_plan')
        if self.plan['source_signature']!=self.sources.signature(): raise ValueError('source_changed')
        plans = self.plan['plans'];self.plan = None
        generators = [engine.build(plan['plan_id'],cancelled) for engine,plan in zip((self.visual,self.text),plans)]
        processed = [0,0];active = {0,1}
        try:
            while active and not cancelled():
                for i in list(active):
                    try:
                        progress = next(generators[i]);processed[i] = progress['processed']
                        yield {'processed':sum(processed),**self.status()}
                    except StopIteration: active.remove(i)
        finally:
            for generator in generators: generator.close()

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
