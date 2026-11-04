"""The gallery index signs only the gallery rows it reads from danbooru.db.

Standard library only: no models, numpy or Pillow (gallery.py loads Pillow
only to read a picture), so these run on the system python3. An update
(GalleryCheckTests) runs on the real pool tables with stand-ins for the ANN
and the models.
"""
import itertools
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

from documents import count_chunks
import engine
import gallery
from gallery import GalleryEngine, GallerySources
from pool import VectorPool

# The tables of danbooru.db the gallery writes, with the columns that matter
# here (gallery_data_source_schema.dart).
SCHEMA = '''PRAGMA journal_mode=WAL;
CREATE TABLE gallery_images(id INTEGER PRIMARY KEY AUTOINCREMENT,file_path TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,file_size INTEGER NOT NULL DEFAULT 0,modified_at INTEGER NOT NULL,
    indexed_at INTEGER NOT NULL DEFAULT 0,last_scanned_at INTEGER,metadata_status INTEGER NOT NULL DEFAULT 2,
    is_favorite INTEGER NOT NULL DEFAULT 0,is_deleted INTEGER NOT NULL DEFAULT 0);
CREATE TABLE gallery_metadata(image_id INTEGER PRIMARY KEY,prompt TEXT NOT NULL DEFAULT '',
    negative_prompt TEXT NOT NULL DEFAULT '',seed INTEGER,sampler TEXT,steps INTEGER,cfg_scale REAL,
    width INTEGER,height INTEGER,model TEXT,software TEXT,source TEXT,raw_json TEXT,
    has_metadata INTEGER NOT NULL DEFAULT 0,positive_prompt_text TEXT NOT NULL DEFAULT '');
CREATE TABLE gallery_favorites(image_id INTEGER PRIMARY KEY,favorited_at INTEGER NOT NULL);
CREATE TABLE gallery_collections(id TEXT PRIMARY KEY,name TEXT NOT NULL);
CREATE TABLE gallery_collection_items(collection_id TEXT,image_id INTEGER,PRIMARY KEY(collection_id,image_id));
CREATE TABLE gallery_tags(id TEXT PRIMARY KEY,tag_name TEXT NOT NULL,usage_count INTEGER NOT NULL DEFAULT 0);
CREATE TABLE gallery_image_tags(image_id INTEGER,tag_id TEXT,PRIMARY KEY(image_id,tag_id));
CREATE TABLE gallery_fts_index(image_id INTEGER,prompt_text TEXT);
CREATE TABLE gallery_scan_logs(id INTEGER PRIMARY KEY,scanned_at INTEGER);
CREATE TABLE gallery_meta(key TEXT PRIMARY KEY,value TEXT);
INSERT INTO gallery_meta VALUES('statistics_revision','0');
CREATE TABLE danbooru_tags(tag TEXT PRIMARY KEY,category INTEGER,post_count INTEGER,last_updated INTEGER);'''


class GalleryRows(unittest.TestCase):
    """danbooru.db as the app keeps it, with three NovelAI pictures in one root."""
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.library=self.root/'图库';self.library.mkdir()
        self.roots=self.root/'roots.json'
        self.roots.write_text(json.dumps({'version':1,'roots':[str(self.library)]}),encoding='utf-8')
        self.database=self.root/'danbooru.db'
        # The app keeps danbooru.db open, so every write lands in its WAL.
        self.app=sqlite3.connect(self.database,isolation_level=None)
        self.app.executescript(SCHEMA)
        # As the app's triggers do, every write to these moves the statistics.
        for table in ('gallery_images','gallery_metadata','gallery_favorites','gallery_image_tags'):
            for op in ('INSERT','UPDATE','DELETE'):
                self.app.execute(f'''CREATE TRIGGER statistics_{table}_{op} AFTER {op} ON {table} BEGIN
                    UPDATE gallery_meta SET value=CAST(value AS INTEGER)+1 WHERE key='statistics_revision'; END''')
        for i in range(1,4): self.save_image(i)
        self.visual=GallerySources(self.database,self.roots)
        self.text=GallerySources(self.database,self.roots,False)
    def tearDown(self): self.app.close();self.temp.cleanup()

    def save_image(self,i,nai=True):
        path=str(self.library/f'{i}.png')
        self.app.execute('INSERT INTO gallery_images(id,file_path,file_name,file_size,modified_at,indexed_at) VALUES(?,?,?,?,?,?)',
            (i,path,f'{i}.png',100+i,1000+i,1))
        self.app.execute('''INSERT INTO gallery_metadata(image_id,prompt,positive_prompt_text,negative_prompt,model,sampler,steps,
            cfg_scale,seed,width,height,software,source,raw_json,has_metadata) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)''',
            (i,f'rain {i}',f'rain {i}','lowres','nai-diffusion-4-5-full','k_euler',28,5.0,i,832,1216,
             'NovelAI' if nai else 'Other','','{}'))

    def recount(self,visual):
        """counts() as it was before it was kept per snapshot: the rows read
        afresh and every record summed."""
        records=GallerySources(self.database,self.roots,visual).records()
        return len(records),sum(1 if visual else count_chunks(r['body']) for r in records.values())


class GallerySignatureTests(GalleryRows):
    """danbooru.db also stores favourites, collections, tags and bookkeeping."""
    def stamp(self):
        return [(p.stat().st_size,p.stat().st_mtime_ns) for p in (self.database,Path(str(self.database)+'-wal')) if p.exists()]

    def state(self):
        return [(s.signature(),s.count(),s.document_count()) for s in (self.visual,self.text)]

    def test_favourites_collections_tags_and_bookkeeping_leave_both_indices_complete(self):
        before=self.state();stamp=self.stamp()
        writes={'favourite':'INSERT INTO gallery_favorites VALUES(1,5)',
            'unfavourite':'DELETE FROM gallery_favorites WHERE image_id=1',
            'new collection':"INSERT INTO gallery_collections VALUES('picks','Picks')",
            'added to a collection':"INSERT INTO gallery_collection_items VALUES('picks',2)",
            'tagged':"INSERT INTO gallery_tags VALUES('rain','rain',1)",
            'tag on a picture':"INSERT INTO gallery_image_tags VALUES(2,'rain')",
            'search text':"INSERT INTO gallery_fts_index VALUES(2,'rain')",
            'scan log':'INSERT INTO gallery_scan_logs VALUES(1,9)',
            'scanned again':'UPDATE gallery_images SET last_scanned_at=9,indexed_at=9,metadata_status=1',
            # The scanner writes every column of a row it finds unchanged.
            'rewritten as it was':'UPDATE gallery_images SET file_path=file_path,file_size=file_size,modified_at=modified_at,is_deleted=is_deleted',
            'old favourite column':'UPDATE gallery_images SET is_favorite=1 WHERE id=3',
            'tag sync':"INSERT INTO danbooru_tags VALUES('rain',0,1200,0)"}
        for change,sql in writes.items():
            self.app.execute(sql)
            self.assertEqual(self.state(),before,change)
        self.assertNotEqual(self.stamp(),stamp,'the writes are in the file')

    def test_every_change_to_the_pictures_changes_the_visual_signature(self):
        changes={'saved':lambda: self.save_image(4),
            'moved':lambda: self.app.execute("UPDATE gallery_images SET file_path=? WHERE id=2",(str(self.library/'moved.png'),)),
            'replaced in place':lambda: self.app.execute('UPDATE gallery_images SET file_size=999,modified_at=5000 WHERE id=3'),
            'deleted':lambda: self.app.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=1'),
            'restored':lambda: self.app.execute('UPDATE gallery_images SET is_deleted=0 WHERE id=1'),
            'removed':lambda: self.app.execute('DELETE FROM gallery_images WHERE id=4'),
            'roots':lambda: self.roots.write_text(json.dumps({'version':1,'roots':[str(self.library),str(self.root/'more')]})),
            'table dropped':lambda: self.app.execute('DROP TABLE gallery_images')}
        for change,apply in changes.items():
            before=self.visual.signature();apply()
            self.assertNotEqual(self.visual.signature(),before,change)

    def test_every_change_to_the_parameters_changes_the_text_signature(self):
        changes={'saved':lambda: self.save_image(4),
            'prompt':lambda: self.app.execute("UPDATE gallery_metadata SET positive_prompt_text='snow' WHERE image_id=1"),
            'negative':lambda: self.app.execute("UPDATE gallery_metadata SET negative_prompt='blurry' WHERE image_id=2"),
            'model':lambda: self.app.execute("UPDATE gallery_metadata SET model='nai-diffusion-4-full' WHERE image_id=3"),
            'no longer NovelAI':lambda: self.app.execute("UPDATE gallery_metadata SET software='Other',model='sdxl' WHERE image_id=4"),
            'NovelAI by its request':lambda: self.app.execute("""UPDATE gallery_metadata SET raw_json='{"v4_prompt":{}}' WHERE image_id=4"""),
            'renamed':lambda: self.app.execute("UPDATE gallery_images SET file_path=? WHERE id=2",(str(self.library/'renamed.png'),)),
            'deleted':lambda: self.app.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=1')}
        for change,apply in changes.items():
            before=self.text.signature();apply()
            self.assertNotEqual(self.text.signature(),before,change)

    def test_a_read_that_missed_a_commit_is_read_again_once_the_files_hold_still(self):
        clock=[1000.0]
        with patch.object(engine.time,'monotonic',lambda: clock[0]):
            before=self.visual.signature()
            # SQLite writes a commit to the WAL before it publishes it; a read in
            # between still sees the old rows, as a snapshot held from before does.
            stale=engine.readonly(self.database);stale.execute('BEGIN')
            stale.execute('SELECT COUNT(*) FROM gallery_images').fetchone()
            self.save_image(4)
            with patch.object(gallery,'readonly',return_value=stale):
                self.assertEqual(self.visual.signature(),before)
            # Publishing changes neither file, so only the time can tell.
            clock[0]+=60
            self.assertNotEqual(self.visual.signature(),before)
            self.assertEqual(self.visual.document_count(),4)

    def test_rows_are_read_once_after_each_change_and_once_when_it_held_still(self):
        clock=[1000.0];settle=GallerySources.settle_seconds
        def calls():
            for _ in range(5):
                self.assertEqual(self.visual.signature(),before)
                self.assertEqual(self.visual.count(),count)
        with patch.object(gallery,'readonly',wraps=gallery.readonly) as opened,\
             patch.object(engine.time,'monotonic',lambda: clock[0]):
            before=self.visual.signature();count=self.visual.count();calls()
            clock[0]+=settle/2;calls()
            clock[0]+=settle/2;calls()
            clock[0]+=settle*10;calls()
            self.app.execute('INSERT INTO gallery_favorites VALUES(1,5)');calls()
            clock[0]+=settle;calls()
        self.assertEqual(len(opened.call_args_list),4)


class GalleryCountTests(GalleryRows):
    """status() asks for the counts three times in each step of a check (the
    step's own status, then the gallery's: see GalleryEngine.build)."""
    def counts(self):
        return [(s.counts(),s.document_count(),s.count()) for s in (self.visual,self.text)]

    def test_the_parameters_are_counted_once_per_snapshot(self):
        clock=[1000.0]
        def step(pictures):
            for _ in range(3):
                self.text.signature()
                self.assertEqual((self.text.document_count(),self.text.count()),(pictures,pictures))
        with patch.object(gallery,'count_chunks',wraps=gallery.count_chunks) as chunked,\
             patch.object(engine.time,'monotonic',lambda: clock[0]):
            step(3);step(3)
            self.assertEqual(chunked.call_count,3,'once for each picture with parameters')
            # The file changed and the rows were read again, but they are the same.
            self.app.execute('INSERT INTO gallery_favorites VALUES(1,5)');step(3)
            clock[0]+=60;step(3)
            self.assertEqual(chunked.call_count,3)
            self.save_image(4);step(4)
            clock[0]+=60;step(4)
            self.assertEqual(chunked.call_count,3+4)

    def test_the_counts_kept_are_those_of_the_rows_after_each_change(self):
        other=self.root/'更多'
        long=', '.join(['rain']*800)  # five chunks with the rest of the parameters
        def roots(*folders):
            self.roots.write_text(json.dumps({'version':1,'roots':[str(f) for f in folders]}),encoding='utf-8')
        changes={'saved':lambda: self.save_image(4),
            'longer prompt':lambda: self.app.execute('UPDATE gallery_metadata SET positive_prompt_text=? WHERE image_id=1',(long,)),
            'shorter prompt':lambda: self.app.execute("UPDATE gallery_metadata SET positive_prompt_text='snow' WHERE image_id=1"),
            'longer negative':lambda: self.app.execute('UPDATE gallery_metadata SET negative_prompt=? WHERE image_id=2',(long,)),
            'no longer NovelAI':lambda: self.app.execute("UPDATE gallery_metadata SET software='Other',model='sdxl' WHERE image_id=4"),
            'NovelAI by its request':lambda: self.app.execute("""UPDATE gallery_metadata SET raw_json='{"v4_prompt":{}}' WHERE image_id=4"""),
            'deleted':lambda: self.app.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=1'),
            'restored':lambda: self.app.execute('UPDATE gallery_images SET is_deleted=0 WHERE id=1'),
            'removed':lambda: self.app.execute('DELETE FROM gallery_images WHERE id=3'),
            'moved out of the roots':lambda: self.app.execute('UPDATE gallery_images SET file_path=? WHERE id=2',(str(other/'2.png'),)),
            'root added':lambda: roots(self.library,other),
            'only the other root':lambda: roots(other),
            'no roots':lambda: roots(),
            'roots back':lambda: roots(self.library,other),
            'not a picture any more':lambda: self.app.execute('UPDATE gallery_images SET file_path=? WHERE id=1',(str(self.library/'1.txt'),)),
            'table dropped':lambda: self.app.execute('DROP TABLE gallery_images')}
        before=self.counts()
        for change,apply in changes.items():
            apply();after=self.counts()
            self.assertEqual(after,[(c,*c) for c in (self.recount(True),self.recount(False))],change)
            self.assertNotEqual(after,before,change+' changes a count');before=after

    def test_the_counts_of_a_read_that_missed_a_commit_go_once_the_files_hold_still(self):
        clock=[1000.0]
        with patch.object(engine.time,'monotonic',lambda: clock[0]):
            self.assertEqual(self.counts(),[((3,3),3,3)]*2)
            # A snapshot held from before the commit stands in for a read between
            # the WAL write and its publication (as in GallerySignatureTests).
            stale=[engine.readonly(self.database) for _ in range(2)]
            for db in stale: db.execute('BEGIN');db.execute('SELECT COUNT(*) FROM gallery_images').fetchone()
            self.save_image(4)
            with patch.object(gallery,'readonly',side_effect=stale):
                self.assertEqual(self.counts(),[((3,3),3,3)]*2)
            # Publishing changes neither file, so only the time can tell.
            clock[0]+=60
            self.assertEqual(self.counts(),[((4,4),4,4)]*2)


class KeysOnly:
    """The pool's ANN without usearch: only which vectors it holds."""
    def __init__(self,keys=()): self.keys=set(keys)
    def __len__(self): return len(self.keys)
    def add(self,key,vector): self.keys.add(int(key))
    def remove(self,key): self.keys.discard(int(key))
    def reset(self): self.keys=set()


class StdlibPool(VectorPool):
    """The real pool tables (collections, metadata, sizes) with KeysOnly for
    the ANN, which is neither saved nor mapped."""
    def reload(self,*,progress=None,cancelled=lambda: False):
        self._replace_ann(KeysOnly(r[0] for r in self.db.execute('SELECT id FROM pool_documents')),mapped=False)
        for view in self.views.values(): view.refresh()
        return False
    def checkpoint(self,*,cancelled=lambda: False,remap=None): pass


class Vector:
    def tobytes(self): return bytes(12)


class CheckModels:
    fingerprint='stdlib-check-v1'
    def __init__(self,root): self.embedding_path=str(root)
    def embed(self,texts,query=False): return [Vector() for _ in texts]


class GalleryCheckTests(GalleryRows):
    """In every step an update (GalleryEngine.build) reports the counts of the
    rows as they are, also once they changed under it; a picture saved
    meanwhile is read in a later round of the same update."""
    def setUp(self):
        super().setUp()
        self.while_embedding=[]  # writes of the app while a step embeds, one each time
        def embed_rows(engine_self,rows):
            if self.while_embedding: self.while_embedding.pop(0)()
            return [Vector() for _ in rows]
        # One row a step, so a first build of three pictures takes six steps.
        for target,name,value in ((gallery.VisualEngine,'embed_rows',embed_rows),
                (gallery.VisualEngine,'batch_size',1),(engine.Engine,'batch_size',1)):
            patcher=patch.object(target,name,value);patcher.start();self.addCleanup(patcher.stop)
        models=CheckModels(self.root)
        self.pool=StdlibPool(self.root/'index',models.fingerprint)
        self.engine=GalleryEngine(self.root/'index'/'gallery-v1',models,self.database,self.roots,pool=self.pool)
    def tearDown(self): self.engine.close();self.pool.close();super().tearDown()

    def check(self): return self.engine.build(self.engine.preview()['plan_id'],lambda: False)
    def reported(self,status): return status['images'],status['parameter_chunks'],status['total']
    def walk(self,steps,reports):
        for status in steps:
            reports.append(self.reported(status))
            images,chunks=self.recount(True)[1],self.recount(False)[1]
            self.assertEqual(reports[-1],(images,chunks,images+chunks))
        return reports

    def test_each_step_reports_the_counts_of_the_rows_as_they_are(self):
        self.assertEqual(self.walk(self.check(),[]),[(3,3,6)]*6)
        # A recorded time changed: that picture alone is read, nothing embedded.
        self.app.execute('UPDATE gallery_images SET modified_at=modified_at+1 WHERE id=1')
        self.assertEqual(self.walk(self.check(),[]),[(3,3,6)])
        # A picture saved between two steps is read in the same update.
        self.save_image(4)
        steps=self.check();reports=self.walk(itertools.islice(steps,1),[])
        self.save_image(5)
        self.assertEqual(self.walk(steps,reports),[(4,4,8)]+[(5,5,10)]*3)
        self.assertTrue(self.engine.status()['complete'])
        # A picture saved while a step embeds is in the counts of that step.
        self.while_embedding.append(lambda: self.save_image(7))
        self.save_image(6)
        self.assertEqual(self.walk(self.check(),[]),[(7,7,14)]*4)
        self.assertTrue(self.engine.status()['complete'])

    def test_an_update_that_keeps_finding_pictures_ends_after_its_rounds(self):
        self.walk(self.check(),[])
        # A picture saved in each round: the update stops after its rounds,
        # not caught up, and the next one reads the last.
        self.while_embedding.extend(lambda i=i: self.save_image(i) for i in (5,6,7))
        self.save_image(4)
        self.assertEqual(len(self.walk(self.check(),[])),2*gallery.ROUNDS)
        self.assertFalse(self.engine.status()['complete'])
        self.assertEqual(self.walk(self.check(),[]),[(7,7,14)]*2)
        self.assertTrue(self.engine.status()['complete'])


if __name__=='__main__': unittest.main()
