"""Shared-pool persistence and exact summaries; no models or user data."""
import hashlib
import json
import sqlite3
import threading
import weakref
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

from documents import TextEngine
from pool import VectorPool
import test_pool as fixtures
from worker import Worker


class LifecycleTests(unittest.TestCase):
    setUp = fixtures.PoolTests.setUp
    tearDown = fixtures.PoolTests.tearDown
    build = fixtures.PoolTests.build

    def byte_total(self, collection):
        return self.pool.db.execute('''SELECT COALESCE(SUM(length(vector)+length(text)+length(name)),0)
            FROM pool_documents WHERE collection=?''',(collection,)).fetchone()[0]

    def change_vector(self):
        key = self.tags.db.execute('SELECT MIN(id) FROM documents').fetchone()[0]
        vector = self.models.embed(['changed fixture'])[0]
        self.tags.db.execute('UPDATE documents SET vector=? WHERE id=?',(vector.tobytes(),key))
        self.tags.ann.remove(key); self.tags.ann.add(key,vector)
        self.tags.db.commit()

    def test_worker_noop_events_and_heartbeat_never_report_building(self):
        self.build(self.tags)
        worker = Worker(); worker.engines = {'tags': self.tags}
        generator = self.tags.build(self.tags.preview()['plan_id'], lambda: False)
        worker.jobs['check'] = {'id':'check', 'source':'tags', 'generator':generator,
            'cancel':threading.Event(), 'paused':False}
        events = []
        with patch.object(worker, '_event', side_effect=lambda **v: events.append(v)):
            worker._step('check')
            self.assertEqual(events[-1]['phase'], 'checking')
            self.assertFalse(events[-1]['building'])
            heartbeat = worker.status()['sources']['tags']
            self.assertTrue(heartbeat['checking'])
            self.assertFalse(heartbeat['building'])
            worker._step('check')
        self.assertEqual(events[-1]['phase'], 'complete')
        self.assertFalse(worker.jobs)
        self.assertFalse(worker.status()['sources']['tags']['checking'])
        self.assertFalse(worker.status()['sources']['tags']['building'])

    def test_clean_seen_and_metadata_changes_do_not_rewrite_ann(self):
        self.build(self.tags)
        ann = weakref.ref(self.pool.ann)
        path = self.pool.folder/'vectors.usearch'
        before = (hashlib.sha256(path.read_bytes()).hexdigest(),path.stat().st_mtime_ns)
        with patch('usearch.index.Index.save',side_effect=AssertionError('Unchanged ANN was saved')):
            self.pool.checkpoint()
            self.tags.db.execute("UPDATE documents SET seen='new-pass',post_count=post_count+1")
            self.tags.set_paused(True)
            self.pool.checkpoint()
            self.tags.close(); self.pages.close(); self.pool.close(); self.pool.close()
        self.assertIsNone(ann())
        self.assertEqual(before,(hashlib.sha256(path.read_bytes()).hexdigest(),path.stat().st_mtime_ns))

    def test_failed_publication_retries_instead_of_marking_checkpoint_clean(self):
        self.build(self.tags); self.change_vector()
        from pool import os
        replace = os.replace
        def fail_metadata(source,target):
            if str(target).endswith('ann.json'): raise OSError('fixture publication failure')
            return replace(source,target)
        with patch('pool.os.replace',side_effect=fail_metadata):
            with self.assertRaises(OSError): self.pool.checkpoint()
        self.pool.checkpoint()
        self.assertEqual(json.loads((self.pool.folder/'ann.json').read_text())['generation'],
                         self.pool.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0])
        with patch('usearch.index.Index.add',side_effect=AssertionError('Published index rebuilt')):
            reopened = VectorPool(self.root/'indices',self.models.fingerprint)
            reopened.close()

    def test_missing_checkpoint_is_republished_even_when_generation_is_unchanged(self):
        self.build(self.tags)
        # Simulate external loss after the reader has released its file view.
        self.pool.writable()
        (self.pool.folder/'vectors.usearch').unlink()
        self.pool.checkpoint()
        with patch('usearch.index.Index.add',side_effect=AssertionError('Missing checkpoint not repaired')):
            reopened = VectorPool(self.root/'indices',self.models.fingerprint)
            reopened.close()

    def test_corrupt_matching_checkpoint_is_restored_and_saved(self):
        self.build(self.tags)
        self.pool.writable()  # A Windows mapping intentionally forbids truncation.
        (self.pool.folder/'vectors.usearch').write_bytes(b'broken fixture')
        reopened = VectorPool(self.root/'indices',self.models.fingerprint)
        try:
            self.assertEqual(len(reopened.ann),8)
            with patch('usearch.index.Index.add',side_effect=AssertionError('Recovery was not saved')):
                again = VectorPool(self.root/'indices',self.models.fingerprint)
                again.close()
        finally: reopened.close()

    def test_old_pool_summary_backfills_once_without_rebuilding_or_changing_vectors(self):
        self.build(self.tags); self.build(self.pages)
        snapshot = self.pool.db.execute('SELECT id,collection,name,vector,digest FROM pool_documents ORDER BY id').fetchall()
        path = self.pool.folder/'vectors.usearch'
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        self.pool.db.executescript('''DROP TRIGGER pool_size_insert; DROP TRIGGER pool_size_update;
            DROP TRIGGER pool_size_delete; DROP TABLE pool_sizes;''')
        with patch('usearch.index.Index.add',side_effect=AssertionError('Old valid ANN rebuilt')):
            reopened = VectorPool(self.root/'indices',self.models.fingerprint)
        queries = []; reopened.db.set_trace_callback(queries.append)
        try:
            for collection in ('tags','wiki'):
                self.assertEqual(reopened.collection_bytes(collection),self.byte_total(collection))
            first_scans = sum('SUM(length(vector)' in sql for sql in queries)
            self.assertEqual(first_scans,2)
            for _ in range(4):
                for collection in ('tags','wiki'): reopened.collection_bytes(collection)
            self.assertEqual(sum('SUM(length(vector)' in sql for sql in queries),first_scans)
            self.assertEqual(reopened.db.execute('SELECT id,collection,name,vector,digest FROM pool_documents ORDER BY id').fetchall(),snapshot)
        finally: reopened.close()
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),before)

    def test_summary_tracks_unicode_nulls_updates_moves_deletes_and_rollback(self):
        self.build(self.tags); self.build(self.pages)
        for collection in ('tags','wiki','extra'): self.pool.collection_bytes(collection)
        db = self.tags.db
        key,vector = db.execute('SELECT id,vector FROM documents ORDER BY id LIMIT 1').fetchone()
        db.execute("UPDATE documents SET text='雨🌧',name='changed-name' WHERE id=?",(key,)); db.commit()
        self.assertEqual(self.pool.collection_bytes('tags'),self.byte_total('tags'))
        committed = self.pool.collection_bytes('tags')
        db.execute("UPDATE documents SET text='uncommitted fixture'")
        self.assertEqual(self.pool.collection_bytes('tags'),committed)
        db.rollback()
        self.assertEqual(self.pool.collection_bytes('tags'),committed)
        db.execute('UPDATE documents SET text=NULL WHERE id=?',(key,)); db.commit()
        self.assertEqual(self.pool.collection_bytes('tags'),self.byte_total('tags'))
        db.execute('UPDATE pool_documents SET collection=? WHERE id=?',('extra',key)); db.commit()
        for collection in ('tags','wiki','extra'):
            self.assertEqual(self.pool.collection_bytes(collection),self.byte_total(collection))
        db.execute('DELETE FROM pool_documents WHERE id=?',(key,)); db.commit()
        db.execute('INSERT INTO documents(name,text,vector) VALUES(?,?,?)',('new-row','日本語',vector)); db.commit()
        for collection in ('tags','wiki','extra'):
            self.assertEqual(self.pool.collection_bytes(collection),self.byte_total(collection))
        # This test writes directly to SQLite to exercise trigger coverage.
        self.pool.reload()

    def test_heartbeat_and_incremental_build_never_rescan_initialized_summary(self):
        self.build(self.tags); self.build(self.pages)
        queries = []; self.pool.db.set_trace_callback(queries.append)
        for _ in range(3): self.tags.status(); self.pages.status()
        self.build(self.tags)
        self.change_vector(); self.tags.status()
        self.assertFalse(any('SUM(length(vector)' in sql for sql in queries))
        self.pool.db.set_trace_callback(None)
        self.assertEqual(self.tags.status()['bytes'],self.byte_total('tags'))
        self.tags.clear()
        self.assertEqual(self.tags.status()['bytes'],0)
        self.assertEqual(self.pages.status()['bytes'],self.byte_total('wiki'))

    def test_shutdown_of_committed_partial_builder_saves_once_and_preserves_search(self):
        self.build(self.pages)
        generator = self.tags.build(self.tags.preview()['plan_id'],lambda:False)
        next(generator)
        before_vectors = self.pool.db.execute('SELECT id,collection,vector,digest FROM pool_documents ORDER BY id').fetchall()
        before_hits = self.pages.search_text('rain')['items']
        worker = Worker(); worker.pool = self.pool
        worker.models = SimpleNamespace(unload=Mock())
        worker.engines = {'tags':self.tags,'wiki':self.pages}
        worker.jobs = {'fixture':{'cancel':threading.Event(),'generator':generator}}
        with (patch.object(self.pool,'reload',side_effect=AssertionError('Shutdown reloaded entire pool')),
              patch.object(self.pool,'checkpoint',wraps=self.pool.checkpoint) as checkpoint):
            worker.close()
            self.assertEqual(checkpoint.call_count,1)
            worker.close()
            self.assertEqual(checkpoint.call_count,1)
        with patch('usearch.index.Index.add',side_effect=AssertionError('Clean shutdown left stale ANN')):
            reopened = VectorPool(self.root/'indices',self.models.fingerprint)
        pages = TextEngine(self.root/'old-wiki',self.models,self.pages.sources,pool=reopened,collection='wiki')
        try:
            self.assertEqual(reopened.db.execute('SELECT id,collection,vector,digest FROM pool_documents ORDER BY id').fetchall(),before_vectors)
            hits = pages.search_text('rain')['items']
            self.assertEqual(hits,before_hits)
            self.assertEqual(len(reopened.views['wiki']),1)
            self.assertEqual(reopened.db.execute("SELECT COUNT(*) FROM pool_documents WHERE collection='tags'").fetchone()[0],8)
        finally: pages.close(); reopened.close()

    def test_cleanup_failure_still_closes_other_connections_pool_and_models(self):
        worker = Worker(); worker.pool = self.pool
        worker.models = SimpleNamespace(unload=Mock())
        model = worker.models
        worker.engines = {'tags':self.tags,'wiki':self.pages}
        with patch.object(self.tags,'close',side_effect=ValueError('fixture cleanup failure')):
            with self.assertRaises(ValueError): worker.close()
        model.unload.assert_called_once()
        self.assertTrue(self.pages._closed); self.assertTrue(self.pool._closed)
        self.assertIsNone(worker.pool)


if __name__=='__main__': unittest.main()
