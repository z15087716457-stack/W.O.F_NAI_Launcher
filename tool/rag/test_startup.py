"""Startup recovery uses saved vectors, remains cancellable and repairs its cache."""
import json
import sqlite3
from contextlib import closing
from pathlib import Path
import tempfile
import threading
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from pool import VectorPool
import test_pool as fixtures
from test_rag import fixture, FakeModels
from engine import Engine
from test_rag import Sources
from worker import Worker
from test_tag_search import fixture_corpus


class StartupPoolTests(unittest.TestCase):
    setUp = fixtures.PoolTests.setUp
    tearDown = fixtures.PoolTests.tearDown
    build = fixtures.PoolTests.build
    def test_seen_only_update_keeps_checkpoint_valid(self):
        self.build(self.tags)
        generation = self.pool.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        # The TEMP view's update copies all fields, just like the real builder.
        self.tags.db.execute("UPDATE documents SET seen='next-pass'")
        self.tags.db.commit()
        self.assertEqual(self.pool.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0], generation)
        with patch('usearch.index.Index.add', side_effect=AssertionError('Unchanged vectors must load the checkpoint')):
            restored = VectorPool(self.root/'indices', self.models.fingerprint)
            self.assertEqual(len(restored.ann), 8)
            restored.close()

    def test_old_trigger_is_upgraded_and_vector_changes_still_invalidate(self):
        self.build(self.tags)
        self.pool.writable()  # Release the other owner's mapping before fault injection.
        self.pool.db.executescript("DROP TRIGGER pool_update; CREATE TRIGGER pool_update AFTER UPDATE ON pool_documents BEGIN UPDATE pool_state SET value=value+1 WHERE key='generation'; END;")
        restored = VectorPool(self.root/'indices', self.models.fingerprint)
        try:
            before = restored.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
            with restored.db: restored.db.execute("UPDATE pool_documents SET seen='checked'")
            self.assertEqual(restored.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0], before)
            vector = self.models.embed(['different vector'])[0].tobytes()
            with restored.db: restored.db.execute('UPDATE pool_documents SET vector=? WHERE id=(SELECT MIN(id) FROM pool_documents)',(vector,))
            self.assertEqual(restored.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0], before+1)
            with restored.db: restored.db.execute('DELETE FROM pool_documents WHERE id=(SELECT MIN(id) FROM pool_documents)')
            self.assertEqual(restored.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0], before+2)
        finally: restored.close()

    def test_stale_checkpoint_recovery_is_saved_without_reembedding(self):
        self.build(self.tags)
        self.pool.writable()  # Recovery owns publication; no second reader pins the file.
        with self.pool.db: self.pool.db.execute("UPDATE pool_state SET value=value+1 WHERE key='generation'")
        events=[]
        with patch.object(self.models, 'embed', side_effect=AssertionError('Recovery must reuse vectors')):
            restored = VectorPool(self.root/'indices', self.models.fingerprint, progress=lambda *value:events.append(value))
        self.assertIn(('restoring',8,8),events)
        saved=json.loads((restored.folder/'ann.json').read_text('utf-8'))
        self.assertEqual(saved['generation'],restored.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0])
        with patch('usearch.index.Index.add', side_effect=AssertionError('Completed recovery must not repeat next launch')):
            reopened = VectorPool(self.root/'indices', self.models.fingerprint)
            reopened.close()
        restored.close()

    def test_cancelled_recovery_never_publishes_a_partial_checkpoint(self):
        self.build(self.tags)
        before=(self.pool.folder/'vectors.usearch').read_bytes()
        before_meta=(self.pool.folder/'ann.json').read_bytes()
        with self.pool.db: self.pool.db.execute("UPDATE pool_state SET value=value+1 WHERE key='generation'")
        cancelled=threading.Event()
        def progress(phase,processed,total):
            if phase=='restoring' and processed:cancelled.set()
        with self.assertRaisesRegex(ValueError,'cancelled'):
            VectorPool(self.root/'indices',self.models.fingerprint,progress=progress,cancelled=cancelled.is_set)
        self.assertEqual((self.pool.folder/'vectors.usearch').read_bytes(),before)
        self.assertEqual((self.pool.folder/'ann.json').read_bytes(),before_meta)


class StartupWorkerTests(unittest.TestCase):
    def test_configure_reports_real_phases_and_cancellation(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp); catalog=root/'catalog.db';fixture(catalog,8)
            corpus=root/'corpus.csv';fixture_corpus(corpus,2)
            model=SimpleNamespace(fingerprint='fixture',unload=lambda:None)
            worker=Worker();events=[]
            params={'embedding':'fixture','directory':str(root/'index'),
                    'catalog':str(catalog),'tag_corpus':str(corpus),'sources':['tags']}
            with patch('worker.Models',return_value=model):
                result=worker.execute('configure',params,threading.Event(),lambda *args:events.append(args))
            try:
                self.assertEqual(result['sources']['tags']['total'],16)
                self.assertEqual(result['sources']['tags']['indexed'],0)
                self.assertEqual(events[0],('opening',0,0))
                self.assertTrue(any(event[0]=='sources' for event in events))
            finally:
                for engine in worker.engines.values():engine.close()
                worker.pool.close()
            token=threading.Event();token.set()
            with self.assertRaisesRegex(ValueError,'cancelled'):
                Worker().execute('configure',params,token)

    def test_new_tag_representation_preserves_old_vectors_and_requires_its_own_consent(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp); catalog=root/'catalog.db';fixture(catalog,8)
            models=FakeModels(); models.unload=lambda:None
            old=Engine(root/'index',models,Sources(catalog))
            plan=old.preview();list(old.build(plan['plan_id'],lambda:False))
            records=old.db.execute('SELECT name,category,post_count,aliases,text,digest,vector,seen FROM documents').fetchall()
            # A retained pre-pool file must not migrate into the new views.
            legacy=root/'index'/models.fingerprint
            legacy.mkdir(parents=True,exist_ok=True)
            with closing(sqlite3.connect(legacy/'tags.sqlite')) as db,db:
                db.executescript('CREATE TABLE documents(name,category,post_count,aliases,text,digest,vector,seen); CREATE TABLE metadata(key PRIMARY KEY,value); INSERT INTO metadata VALUES("consented","1");')
                db.executemany('INSERT INTO documents VALUES(?,?,?,?,?,?,?,?)',records)
            old.close()
            worker=Worker()
            with patch('worker.Models',return_value=models):
                status=worker.execute('configure',{'embedding':'fixture','directory':str(root/'index'),'catalog':str(catalog),'sources':['tags']},threading.Event())
            try:
                self.assertEqual(status['sources']['tags']['indexed'],0)
                self.assertFalse(status['sources']['tags']['auto_update_allowed'])
                self.assertEqual(worker.pool.db.execute("SELECT COUNT(*) FROM pool_documents WHERE collection='tags'").fetchone()[0],8)
                self.assertEqual(worker.pool.db.execute("SELECT value FROM pool_metadata WHERE collection='tags' AND key='consented'").fetchone()[0],'1')
            finally:
                worker.close()


if __name__=='__main__':unittest.main()
