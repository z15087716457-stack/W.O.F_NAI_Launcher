from contextlib import closing
import hashlib
from pathlib import Path
import sqlite3
import tempfile
import unittest
from types import SimpleNamespace

from engine import Engine,Sources
from documents import TextEngine,WikiSources
from pool import VectorPool,CollectionAnn
from test_rag import fixture
from test_documents import TextModels


class PoolTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.catalog=self.root/'catalog.db';fixture(self.catalog,8)
        self.wiki=self.root/'wiki.db'
        with closing(sqlite3.connect(self.wiki)) as db, db:
            db.execute('CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT)')
            db.execute("INSERT INTO wiki_pages VALUES('tag_0','umbrella in the rain')")
        self.cache=self.root/'translations.db';self.models=TextModels()
        self.pool=VectorPool(self.root/'indices',self.models.fingerprint)
        self.tags=Engine(self.root/'indices',self.models,Sources(self.catalog),pool=self.pool)
        self.pages=TextEngine(self.root/'old-wiki',self.models,WikiSources(self.wiki,self.catalog,self.cache),pool=self.pool,collection='wiki')
    def tearDown(self):
        self.tags.close();self.pages.close();self.pool.close();self.temp.cleanup()
    def build(self,engine):return list(engine.build(engine.preview()['plan_id'],lambda:False))
    def translation(self,body,source='umbrella in the rain'):
        with closing(sqlite3.connect(self.cache)) as db, db:
            db.execute('CREATE TABLE IF NOT EXISTS tag_translations(tag TEXT PRIMARY KEY,name_zh TEXT,wiki_zh TEXT,wiki_hash TEXT,name_language TEXT,updated_at INTEGER)')
            db.execute('INSERT OR REPLACE INTO tag_translations VALUES(?,?,?,?,?,?)',('tag_0','雨伞',body,hashlib.sha256(source.encode()).hexdigest(),'zh',len(body or '')))
    def test_one_database_and_one_ann_preserve_source_filtering(self):
        self.build(self.tags);self.build(self.pages)
        self.assertEqual(self.tags.folder,self.pages.folder)
        self.assertIs(self.tags.ann.pool.ann,self.pages.ann.pool.ann)
        self.assertEqual(len(list((self.root/'indices').rglob('pool.sqlite'))),1)
        self.assertEqual(len(list((self.root/'indices').rglob('vectors.usearch'))),1)
        self.assertEqual(len(self.pool.ann),9)
        ids=self.pages.search_text('rain')['items']
        self.assertEqual([r['id'] for r in ids],['tag_0'])
        self.pages.clear()
        self.assertEqual(self.tags.status()['indexed'],8)
        self.assertEqual(len(self.pool.ann),8)
    def test_build_steps_can_interleave_without_losing_another_source(self):
        a=self.tags.build(self.tags.preview()['plan_id'],lambda:False)
        b=self.pages.build(self.pages.preview()['plan_id'],lambda:False)
        next(a);next(b);list(a);list(b)
        self.assertEqual(self.tags.status()['indexed'],8)
        self.assertEqual(self.pages.status()['indexed'],1)
        self.assertTrue(self.tags.status()['complete']);self.assertTrue(self.pages.status()['complete'])
    def test_saved_translation_is_added_without_reembedding_english(self):
        self.build(self.pages);previous=list(self.models.embedded)
        self.translation('撑开的雨伞，用于雨天挡雨。')
        self.assertFalse(self.pages.status()['complete'])
        self.build(self.pages)
        self.assertEqual(self.pages.status()['indexed'],2)
        added=self.models.embedded[len(previous):]
        self.assertEqual(len(added),1)
        self.assertIn('挡雨',added[0])
        self.assertEqual(len(self.pages.search_text('雨天挡雨')['items']),1)
        self.translation('新的中文译文，用于遮雨。')
        self.build(self.pages)
        self.assertEqual(self.pages.status()['indexed'],2)
        self.assertNotIn('撑开的雨伞',str(self.pages.db.execute('SELECT text FROM documents').fetchall()))
    def test_stale_translation_is_not_indexed_and_is_removed_incrementally(self):
        self.translation('旧译文');self.build(self.pages)
        with closing(sqlite3.connect(self.wiki)) as db, db:db.execute("UPDATE wiki_pages SET body='changed article'")
        self.assertEqual(self.pages.search_text('旧译文')['items'],[])
        self.build(self.pages)
        self.assertEqual(self.pages.status()['indexed'],2)
        self.assertNotIn('旧译文',str(self.pages.db.execute('SELECT text FROM documents').fetchall()))
    def test_name_only_translation_is_incremental_and_later_replaced_by_body(self):
        self.build(self.pages);self.translation(None);self.build(self.pages)
        self.assertEqual(self.pages.status()['indexed'],2)
        self.assertIn('雨伞',str(self.pages.db.execute('SELECT text FROM documents').fetchall()))
        self.translation('雨伞是挡雨用具。');self.build(self.pages)
        self.assertEqual(self.pages.status()['indexed'],2)
        self.assertEqual(len(self.pages.search_text('雨伞')['items']),1)
    def test_legacy_vectors_are_imported_without_modifying_old_index(self):
        legacy=self.root/'legacy'/self.models.fingerprint;legacy.mkdir(parents=True)
        path=legacy/'tags.sqlite'
        with closing(sqlite3.connect(path)) as db, db:
            db.execute('CREATE TABLE documents(id INTEGER PRIMARY KEY,name TEXT,category INTEGER,post_count INTEGER,aliases TEXT,text TEXT,digest TEXT,vector BLOB,seen TEXT)')
            db.execute('CREATE TABLE metadata(key TEXT,value TEXT)')
            vector=self.models.embed(['legacy'])[0].tobytes()
            db.execute('INSERT INTO documents VALUES(1,?,?,?,?,?,?,?,?)',('tag_0',0,1,'[]','legacy','digest',vector,'old'))
            db.execute("INSERT INTO metadata VALUES('consented','1')")
        before=hashlib.sha256(path.read_bytes()).hexdigest()
        engine=Engine(self.root/'legacy',self.models,Sources(self.catalog),pool=self.pool,collection='legacy')
        try:
            self.assertEqual(engine.status()['indexed'],1)
            self.assertTrue(engine.status()['auto_update_allowed'])
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),before)
            engine.clear()
            # Clearing a source must never resurrect its old per-source index.
            another=VectorPool(self.root/'indices',self.models.fingerprint)
            restored=Engine(self.root/'legacy',self.models,Sources(self.catalog),pool=another,collection='legacy')
            try:self.assertEqual(restored.status()['indexed'],0)
            finally:restored.close();another.close()
        finally:engine.close()

class FilteredRecallTests(unittest.TestCase):
    def test_correlated_categories_expand_ann_recall_without_reading_vectors(self):
        import numpy as np
        db=sqlite3.connect(':memory:')
        # No vector column: falling back to a full scope scan must fail this test.
        db.execute('CREATE TABLE pool_documents(id INTEGER,collection TEXT,category INTEGER)')
        db.executemany('INSERT INTO pool_documents VALUES(?,?,?)',
            [(i,'tags',0 if i<=500 else 1) for i in range(1,17501)])
        class Ann:
            def __init__(self):self.calls=[]
            def __len__(self):return 17500
            def search(self,vector,count):
                self.calls.append(count)
                return SimpleNamespace(keys=np.arange(1,count+1),distances=np.zeros(count))
        ann=Ann();view=CollectionAnn(SimpleNamespace(db=db,ann=ann),'tags');view.refresh()
        try:
            hits=view.search(np.zeros(768),20,categories=(1,))
            self.assertEqual(list(hits.keys),list(range(501,521)))
            self.assertEqual(len(ann.calls),3)
            statements=[];db.set_trace_callback(statements.append)
            view.search(np.zeros(768),20,categories=(1,))
            self.assertFalse(any('category IN' in sql for sql in statements))
        finally:db.close()

if __name__=='__main__':unittest.main()
