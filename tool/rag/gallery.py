"""Local gallery: independent visual vectors and NAI-only text passages.

Source DB and original images are read-only. No metadata extractor, URLs,
captions, audio, or image bytes are sent to the text reranker.

Both indices keep their documents by picture (OwnerIndex): an update reads
the pictures whose rows are new or changed since the index last caught up
and removes those gone, without touching the rest; it reads every picture
only when that state cannot be trusted (OwnerIndex.mode).
"""
import hashlib
import heapq
import json
import os
from pathlib import Path
import time

from documents import CHUNK, OVERLAP, TextEngine, TextSources, count_chunks, document, key
from engine import Engine, Sources, readonly, settled, wal_stamp
from pool import VectorPool

EXTENSIONS = {'.png','.jpg','.jpeg','.webp','.bmp','.gif','.tif','.tiff','.avif'}
NAI = """COALESCE(m.has_metadata,0)=1 AND (
 m.software LIKE '%NovelAI%' OR m.source LIKE '%NovelAI%' OR m.model LIKE 'nai-diffusion%'
 OR m.raw_json LIKE '%ucPreset%' OR m.raw_json LIKE '%request_type%' OR m.raw_json LIKE '%v4_prompt%'
 OR m.raw_json LIKE '%signed_hash%' OR m.raw_json LIKE '%noise_schedule%')"""
# How a picture's documents are made of its row; an index of another value
# is read again in full.
OWNER_FORMAT = json.dumps(['gallery-owners-v1', CHUNK, OVERLAP, 'visual-v1'])
# Rounds of one update: its own, then the pictures changed while it ran.
ROUNDS = 3
# Documents a step looks at when it has nothing to embed.
CHECK = 1024
# A long build saves the shared ANN after embedding this many documents, so a
# start after a crash replays at most about as many (VectorPool.reload).
SAVE_EVERY = 32768


def fingerprint(record):
    """Of what an index reads of one picture's row (GallerySources.records)."""
    return hashlib.sha256(json.dumps(record, sort_keys=True).encode()).hexdigest()[:32]


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
    # A read of the gallery rows is final once its stamp has held this long.
    settle_seconds = Sources.runtime_settle_seconds

    def __init__(self, database, roots_file, visual=True):
        super().__init__(database)
        self.roots_file = Path(roots_file).resolve(strict=True)
        self.visual = visual
        self._records_cache = None
        self._fingerprints = None

    def roots(self):
        data = json.loads(self.roots_file.read_text('utf-8'))
        if data.get('version') != 1 or not isinstance(data.get('roots'),list): raise ValueError('invalid_snapshot')
        return [path_key(p) for p in data['roots'] if isinstance(p,str) and p]

    def roots_digest(self):
        """Of the roots as a set: other roots make an update read every
        picture (they also decide which linked pictures can be read)."""
        return hashlib.sha256(json.dumps(sorted(set(self.roots()))).encode()).hexdigest()

    def contains(self, path, physical=False):
        value = path_key(Path(path).resolve()) if physical else path_key(path)
        for root in self.roots():
            try:
                boundary = path_key(Path(root).resolve()) if physical else root
                if os.path.commonpath((value,boundary)) == boundary and value != boundary: return True
            except ValueError: pass
        return False

    @staticmethod
    def _sign(digest):
        return hashlib.sha256((digest+'gallery-v1-image2048-exif-rgb').encode()).hexdigest()

    def signature(self):
        return self._sign(self._snapshot()[0])

    def state(self):
        """(signature, records, fingerprints) of one snapshot of the rows. An
        update compares the fingerprints with those of the rows the documents
        were made of; a record the snapshot before had too keeps the
        fingerprint worked out then."""
        digest, records = self._snapshot()
        if self._fingerprints is None or self._fingerprints[0] != digest:
            _, before, known = self._fingerprints or (None, {}, {})
            self._fingerprints = digest, records, {owner: known[owner] if before.get(owner) == record else fingerprint(record)
                                                   for owner, record in records.items()}
        return self._sign(digest), records, self._fingerprints[2]

    def _snapshot(self):
        """(digest, records) of the gallery rows the index reads (see records).

        danbooru.db also stores favourites, collections, the gallery's own
        tags and bookkeeping, and the runtime tag table, so its size and time
        alone would start a full check of the gallery index for each of those
        writes. The rows are read again only after the file, its WAL or the
        roots changed, and once more when that stamp has held for
        settle_seconds (see settled in engine.py). For pictures the rows carry
        the size and time the gallery recorded for each file, so a picture
        replaced in place is checked again once the gallery has seen it."""
        roots = self.roots_file.read_text('utf-8')
        def read():
            records = self.records()
            return hashlib.sha256(json.dumps([roots, records], sort_keys=True).encode()).hexdigest(), records
        value, self._records_cache = settled(self._records_cache, [roots, *wal_stamp(self.path)], read,
                                             self.settle_seconds)
        return value

    def records(self, owners=None):
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
                result[str(row[0])] = {'path':path,'body':body,**({'file':list(row[2:4])} if self.visual else {})}
            return result
        finally: db.close()

    def catalogue(self):
        return self._snapshot()[1]

    def counts(self):
        """(pictures, documents) of the rows signed, worked out once for each
        snapshot (by its digest, which covers the records): status() asks for
        them three times in each step of a check, and going through every
        record each time took most of the CPU of a check."""
        digest, records = self._snapshot()
        if not self._counts or self._counts[0] != digest:
            self._counts = digest, (len(records), len(records) if self.visual else
                                    sum(count_chunks(r['body']) for r in records.values()))
        return self._counts[1]

    def ordered_names(self):
        return [key(owner,'image' if self.visual else 'parameters',i) for owner,row in self.catalogue().items()
                for i in range(1 if self.visual else count_chunks(row['body']))]

    def _document(self, owner, row, index):
        if self.visual:
            # The file as it is now: a picture changed on disk is another document.
            stamp = image_stamp(row['path'])
            return {'name':key(owner,'image',0),'owner':owner,'path':row['path'],'stamp':stamp,
                'category':0,'post_count':0,'aliases':[],'text':'',
                'digest':hashlib.sha256(json.dumps([owner,stamp,'visual-v1']).encode()).hexdigest()}
        item = document(owner,Path(row['path']).name,'parameters',index,row['body'])
        item['path'] = row['path']
        return item

    def size(self, row):
        """How many documents a build makes of one picture's row."""
        return 1 if self.visual else count_chunks(row['body'])

    def documents(self, owner, row):
        """Every document a build makes of one picture's row now."""
        return [self._document(owner,row,i) for i in range(self.size(row))]

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
            elif section!='parameters' or not 0<=index<count_chunks(row['body']): continue
            result.append(self._document(owner,row,index))
        return result

    def allowed_owners(self, paths):
        wanted = {path_key(path) for path in paths}
        return [owner for owner,row in self.catalogue().items() if path_key(row['path']) in wanted]


class OwnerIndex:
    """An index of the gallery kept by picture (owner), for updates that read
    only the pictures whose rows changed.

    pool_owners holds, for each picture of the index, the fingerprint of the
    row its documents were made of and how many it has. While that table
    accounts for every document (the metadata 'owners' says so), an update
    reads the pictures whose rows are new or changed and removes those gone;
    otherwise it reads every picture (mode). A step commits the documents of
    its pictures together with their rows of the table, and the ANN follows
    the commit: an update stopped anywhere leaves a table that still accounts
    for every document, and the next update reads only what is left."""
    section = ''
    # Its documents are made of the file as well (its stamp), not of the row alone.
    live = False

    def owner_rows(self):
        return {owner:(print_,count) for owner,print_,count in self.db.execute(
            'SELECT owner,fingerprint,documents FROM pool_owners WHERE collection=?',(self.collection,))}

    def stored(self, owner):
        """(id, name, digest) of the documents of one picture."""
        prefix = json.dumps([owner],ensure_ascii=False)[:-1]+','
        return self.db.execute('SELECT id,name,digest FROM documents WHERE name>=? AND name<?',(prefix,prefix+'~')).fetchall()

    def mode(self, roots, verify, checked):
        """'full' to read every picture, 'changes' for those whose rows changed.

        Every picture when the check was asked for while the index was
        complete (verify), once a process for documents made of the files
        (checked: not yet), and when the table cannot be trusted to account
        for the documents: an index from before it or of another format, a
        check of every picture that did not finish, other roots, a completion
        written by other code (an older version), or another count of
        documents than the table's."""
        meta = dict(self.db.execute('SELECT key,value FROM metadata'))
        if (verify or (self.live and not checked) or meta.get('owners') != OWNER_FORMAT
                or meta.get('full_pending') == '1' or meta.get('owner_roots') != roots
                or meta.get('owner_complete') != meta.get('complete_signature')):
            return 'full'
        held = self.db.execute('SELECT COUNT(*) FROM documents').fetchone()[0]
        counted = self.db.execute('SELECT COALESCE(SUM(documents),0) FROM pool_owners WHERE collection=?',
                                  (self.collection,)).fetchone()[0]
        return 'changes' if held == counted else 'full'

    def prepare(self, roots, verify, checked, retry=False):
        """One round of an update: what it reads (the pictures in the rows
        now, all of them or the changed ones, then those of the table that
        are gone), and from which snapshot.

        retry (the first round of an update): also the pictures whose image
        could not be read (missing, on a drive not mounted, locked, broken),
        which have no document, as a build from nothing would try them; once,
        so that a round that leaves them unread still ends the update. Only
        documents made of a file can be left out (live): an embedding of
        parameters does not skip a chunk."""
        signature, records, prints = self.sources.state()
        mode = self.mode(roots, verify, checked)
        table = self.owner_rows()
        retry = retry and self.live
        owners = [o for o in records if mode == 'full' or (row := table.get(o)) is None or row[0] != prints[o]
                  or retry and not row[1]]
        documents = sum(self.sources.size(records[o]) for o in owners)
        return {'signature':signature,'records':records,'prints':prints,'table':table,'mode':mode,'roots':roots,
                'work':owners+[o for o in table if o not in records],
                'offset':max(0,self.sources.count()-documents),'done':0}

    def begin(self, state):
        # Until its sweep, a round that reads every picture leaves the next
        # update to read every picture too.
        if state['mode'] == 'full':
            self.db.execute("INSERT OR REPLACE INTO metadata VALUES('full_pending','1')"); self.db.commit()

    def steps(self, state, cancelled, progress=None):
        """Brings the documents of each picture of the round in line with its
        row: a step embeds up to batch_size documents or looks at CHECK.
        Yields the number embedded after each committed step."""
        work = state['work']; position = 0
        while position < len(work) and not cancelled():
            plans = []; pending = []; looked = 0
            while position < len(work) and len(pending) < self.batch_size and looked < CHECK:
                owner = work[position]; position += 1
                record = state['records'].get(owner)
                expected = [] if record is None else self.sources.documents(owner,record)
                stored = {name:(doc,digest) for doc,name,digest in self.stored(owner)}
                todo = [item for item in expected if stored.get(item['name'],(None,None))[1] != item['digest']]
                plans.append((owner,record,expected,stored,todo)); pending.extend(todo)
                looked += max(1,len(expected))
            self.writing = bool(pending)
            if pending and progress: progress()
            vectors = iter(self.embed_rows(pending) if pending else ())
            if cancelled(): break
            try:
                removed, added = self._write(plans,vectors,state)
                self.db.commit()
            except BaseException:
                self.db.rollback(); raise
            self._apply(removed,added)
            state['done'] += sum(len(plan[2]) for plan in plans)
            yield len(pending)

    def _write(self, plans, vectors, state):
        removed = []; added = []
        for owner,record,expected,stored,todo in plans:
            made = {item['name']:next(vectors) for item in todo}
            kept = set()
            for item in expected:
                name = item['name']
                if name not in made: kept.add(name); continue
                vector = made[name]
                if vector is None: continue  # a picture that could not be read
                self.db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?)',
                    (name,item['category'],item['post_count'],json.dumps(item['aliases']),item['text'],item['digest'],
                     vector.tobytes(),state['signature']))
                old = stored.get(name)
                # A document of the same name keeps its id (the view upserts).
                doc = old[0] if old else self.db.execute('SELECT id FROM documents WHERE name=?',(name,)).fetchone()[0]
                if old: removed.append(doc)
                added.append((doc,vector)); kept.add(name)
            for name,(doc,_) in stored.items():
                if name not in kept:
                    self.db.execute('DELETE FROM documents WHERE id=?',(doc,)); removed.append(doc)
            if record is None:
                self.db.execute('DELETE FROM pool_owners WHERE collection=? AND owner=?',(self.collection,owner))
            elif state['table'].get(owner) != (state['prints'][owner],len(kept)):
                self.db.execute('INSERT OR REPLACE INTO pool_owners VALUES(?,?,?,?)',
                                (self.collection,owner,state['prints'][owner],len(kept)))
        return removed, added

    def _apply(self, removed, added):
        """The ANN after a commit; on a failure it is loaded again to match the rows."""
        try:
            for doc in removed:
                if doc in self.ann: self.ann.remove(doc)
            for doc,vector in added: self.ann.add(doc,vector)
        except BaseException:
            self._load_ann(); raise

    def sweep(self, state):
        """After a round read every picture: remove the documents no row of
        the table accounts for (an index built before the table, or written
        by other code), and trust the table from now on."""
        counted = {key(owner,self.section,i) for owner,(_,count) in self.owner_rows().items() for i in range(count)}
        stale = [doc for doc,name in self.db.execute('SELECT id,name FROM documents') if name not in counted]
        try:
            for doc in stale: self.db.execute('DELETE FROM documents WHERE id=?',(doc,))
            complete = self.db.execute("SELECT value FROM metadata WHERE key='complete_signature'").fetchone()
            for name,value in (('owners',OWNER_FORMAT),('owner_roots',state['roots']),
                               ('owner_complete',complete and complete[0])):
                self.db.execute('INSERT OR REPLACE INTO metadata VALUES(?,?)',(name,value))
            self.db.execute("DELETE FROM metadata WHERE key='full_pending'")
            self.db.commit()
        except BaseException:
            self.db.rollback(); raise
        self._apply(stale,[])

    def finish(self, state):
        """Caught up: the documents are those of the rows of this snapshot."""
        for name in ('complete_signature','owner_complete'):
            self.db.execute('INSERT OR REPLACE INTO metadata VALUES(?,?)',(name,state['signature']))
        if self.sources.visual:
            skipped = self.db.execute('SELECT COUNT(*) FROM pool_owners WHERE collection=? AND documents=0',
                                      (self.collection,)).fetchone()[0]
            self.db.execute("INSERT OR REPLACE INTO metadata VALUES('skipped',?)",(str(skipped),))
        self.db.commit()


class VisualEngine(OwnerIndex, Engine):
    batch_size = 8
    section = 'image'
    live = True

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


class ParameterEngine(OwnerIndex, TextEngine):
    section = 'parameters'


class GalleryEngine:
    # After an update of the changed pictures alone, the caller decides when
    # the shared ANN is saved (the worker: once no update came for a while).
    defers_checkpoint = True

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
        # Collections whose every picture an update of this process has read.
        self._checked = set()

    def status(self):
        visual = self.visual.status();text = self.text.status()
        complete = visual['complete'] and text['complete']
        return {'indexed':visual['indexed']+text['indexed'],'total':visual['total']+text['total'],
            'complete':complete,'partial':bool(visual['indexed']+text['indexed']) and not complete,
            'bytes':visual['bytes']+text['bytes'],'paused':visual['paused'] or text['paused'],
            'auto_update_allowed':(visual['auto_update_allowed'] or text['auto_update_allowed']) and not(visual['paused'] or text['paused']),
            'building':visual['building'] or text['building'],'skipped':visual['skipped'],
            'images':visual['total'],'visual_indexed':visual['indexed'],'parameter_chunks':text['total'],'parameters_indexed':text['indexed']}

    def _signatures(self):
        return [self.visual.sources.signature(),self.text.sources.signature()]

    def preview(self,verify=None):
        """verify: whether the update is a check someone asked for (the
        settings' build button), which reads every picture (OwnerIndex.mode).
        An app that does not say (older ones) starts its own updates only
        while the index is behind: a plan made while it is complete is a
        check someone asked for."""
        status = self.status()
        if verify is None: verify = status['complete']
        self.plan = {'signatures':self._signatures(),'verify':bool(verify),'expires':time.monotonic()+1800}
        self.plan['plan_id'] = hashlib.sha256(json.dumps(self.plan,sort_keys=True).encode()).hexdigest()
        return {'plan_id':self.plan['plan_id'],**status}

    def validate_plan(self,plan_id):
        if not self.plan or self.plan['plan_id']!=plan_id or self.plan['expires']<time.monotonic(): raise ValueError('invalid_plan')
        if self.plan['signatures']!=self._signatures(): raise ValueError('source_changed')

    def build(self,plan_id,cancelled,progress=None):
        """One update of both indices, in rounds (at most ROUNDS) until the
        rows hold still: a picture saved meanwhile is read in the next round,
        not a reason to stop. Each round reads, in each index, the pictures
        whose rows changed, or every picture (OwnerIndex.mode); it stops
        early only when cancelled."""
        self.validate_plan(plan_id)
        plan = self.plan;self.plan = None
        engines = (self.visual,self.text)
        if any(engine.active for engine in engines): raise ValueError('index_busy')
        for engine in engines:
            engine.db.execute("INSERT OR REPLACE INTO metadata VALUES('consented','1')")
            engine.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused','0')")
            engine.db.commit()
            engine.active = True;engine.writing = False
        self.pool.begin_build()
        states = [];reported = [0];verify = plan['verify'];embedded = saved = 0
        def processed():
            # A later round counts from its own work, which can start below
            # where the round before ended: report the furthest so far.
            reported[0] = max(reported[0],sum(s['offset']+s['done'] for s in states)); return reported[0]
        report = (lambda: progress({**self.status(),'building':True,'processed':processed()})) if progress else None
        try:
            for round_ in range(ROUNDS):
                if cancelled(): break
                roots = self.sources.roots_digest()
                states = [engine.prepare(roots,verify,engine.collection in self._checked,retry=not round_)
                          for engine in engines]
                verify = False
                if all(s['mode']=='changes' and not s['work'] for s in states):
                    for engine,s in zip(engines,states): engine.finish(s)
                    break
                for engine,s in zip(engines,states): engine.begin(s)
                steps = [engine.steps(s,cancelled,report) for engine,s in zip(engines,states)]
                try:
                    # Pictures first until one is embedded: an image loads the
                    # encoder with vision, which then embeds the parameters
                    # too; a chunk first would load it without, then again.
                    lead = True;active = list(steps)
                    while active and not cancelled():
                        for step in list(active if not lead else active[:1]):
                            try: count = next(step)
                            except StopIteration: active.remove(step);lead = False;continue
                            embedded += count;lead = lead and not count
                            if embedded-saved >= SAVE_EVERY: self.pool.checkpoint();saved = embedded
                            yield {'processed':processed(),**self.status()}
                finally:
                    for step in steps: step.close()
                if cancelled(): break
                for engine,s in zip(engines,states):
                    if s['mode']=='full': engine.sweep(s);self._checked.add(engine.collection)
        finally:
            # close() interrupts a suspended yield only: every step before it
            # is committed. The caller saves the shared ANN (defers_checkpoint;
            # the pool's owner when it closes).
            for engine in engines: engine.db.rollback();engine.active = False;engine.writing = False
            self.pool.end_build()

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
