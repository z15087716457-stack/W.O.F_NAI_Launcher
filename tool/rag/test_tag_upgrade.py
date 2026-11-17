"""Upgrade fixtures never open application data or load embedding weights."""
import hashlib
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from engine import Engine
from pool import VectorPool
from tag_search import TagEngine, TagSources, RETIRED_TAG_COLLECTIONS
from test_rag import FakeModels, Sources, fixture
from test_tag_search import fixture_corpus


class TagUpgradeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.index = self.root/'index'
        self.models = FakeModels()
        self.catalog = self.root/'catalog.db'
        fixture(self.catalog, 8)
        self.corpus = self.root/'corpus.csv'
        fixture_corpus(self.corpus)
        self.pool = VectorPool(self.index, self.models.fingerprint)
        self.addCleanup(self.pool.close)
        self.engines = []
        for name in (*RETIRED_TAG_COLLECTIONS, 'wiki', 'blocks', 'gallery-images-fixture', 'gallery-parameters'):
            engine = Engine(self.index/name, self.models, Sources(self.catalog), pool=self.pool, collection=name)
            self.engines.append(engine)
            self.addCleanup(engine.close)
            self.build(engine)
        self.retained = self.snapshot()
        self.engine = self.open_tags()

    def open_tags(self):
        engine = TagEngine(self.index/'danbooru-search-v1', self.models, TagSources(self.corpus), pool=self.pool)
        self.addCleanup(engine.close)
        return engine

    @staticmethod
    def build(engine):
        return list(engine.build(engine.preview()['plan_id'], lambda: False))

    def snapshot(self):
        return self.pool.db.execute(
            "SELECT * FROM pool_documents WHERE collection NOT IN ('tags','tag-views-v1','danbooru-search-v1') ORDER BY id").fetchall()

    def old_count(self):
        return self.pool.db.execute(
            "SELECT COUNT(*) FROM pool_documents WHERE collection IN ('tags','tag-views-v1')").fetchone()[0]

    def test_detection_and_preview_do_not_inherit_consent_or_delete_old_data(self):
        status = self.engine.status()
        self.assertTrue(status['upgrade_available'])
        self.assertGreater(status['legacy_bytes'], 0)
        self.assertFalse(status['auto_update_allowed'])
        self.assertFalse(status['upgrade_pending'])
        self.assertTrue(self.engine.preview()['upgrade_available'])
        self.assertEqual(self.old_count(), 16)
        self.assertEqual(self.engine.status()['indexed'], 0)

    def test_success_retires_only_old_tags_and_keeps_other_sources_searchable(self):
        protected = self.index/'tag-views-v1'/self.models.fingerprint/'private-notes.txt'
        protected.parent.mkdir(parents=True)
        protected.write_text('retained', encoding='utf-8')
        legacy = protected.with_name('tags.sqlite')
        legacy.write_bytes(b'old index')
        other_model = self.index/'different-model'/'tags.sqlite'
        other_model.parent.mkdir()
        other_model.write_bytes(b'other model')
        self.engine._legacy = None
        self.build(self.engine)
        status = self.engine.status()
        self.assertTrue(status['complete'])
        self.assertFalse(status['upgrade_available'])
        self.assertEqual(self.old_count(), 0)
        self.assertFalse(legacy.exists())
        self.assertEqual(protected.read_text('utf-8'), 'retained')
        self.assertEqual(other_model.read_bytes(), b'other model')
        self.assertEqual(self.snapshot(), self.retained)
        self.assertEqual(len(self.pool.ann), 32)
        self.assertTrue(self.engine.search('cat ears')['items'])
        self.assertEqual(self.pool.db.execute(
            "SELECT COUNT(*) FROM pool_metadata WHERE collection IN ('tags','tag-views-v1')").fetchone()[0], 0)

    def test_interrupted_upgrade_resumes_after_reopening_without_reembedding_committed_rows(self):
        iterator = self.engine.build(self.engine.preview()['plan_id'], lambda: False)
        next(iterator)
        iterator.close()
        self.assertEqual(self.old_count(), 16)
        self.assertTrue(self.engine.status()['upgrade_pending'])
        self.engine.close()
        self.engine = self.open_tags()
        self.models.embedded.clear()
        self.build(self.engine)
        self.assertEqual(len(self.models.embedded), 64)
        self.assertEqual(self.old_count(), 0)
        self.assertEqual(self.snapshot(), self.retained)

    def test_cleanup_failure_keeps_new_search_ready_and_retry_does_not_embed(self):
        with patch.object(self.engine, '_cleanup_legacy', side_effect=PermissionError('locked')):
            self.build(self.engine)
        self.assertTrue(self.engine.status()['upgrade_failed'])
        self.assertTrue(self.engine.status()['complete'])
        self.assertTrue(self.engine.search('cat ears')['items'])
        self.assertEqual(self.old_count(), 16)
        self.models.embedded.clear()
        self.assertTrue(self.engine.preview()['cleanup_only'])
        self.engine.set_build_error('rag_runtime_error')
        self.build(self.engine)
        self.assertEqual(self.models.embedded, [])
        self.assertEqual(self.old_count(), 0)
        self.assertIsNone(self.engine.status()['error'])

    def test_cancel_before_cleanup_preserves_old_index(self):
        stopped = False
        iterator = self.engine.build(self.engine.preview()['plan_id'], lambda: stopped)
        for status in iterator:
            if status['upgrade_cleaning']:
                stopped = True
        self.assertEqual(self.old_count(), 16)
        self.assertTrue(self.engine.status()['complete'])
        self.assertTrue(self.engine.status()['upgrade_pending'])

    def test_invalid_or_skipped_vectors_never_retire_old_data(self):
        original = self.engine.embed_rows
        def skipped(rows):
            result = list(original(rows))
            result[0] = None
            return result
        with patch.object(self.engine, 'embed_rows', side_effect=skipped):
            self.build(self.engine)
        self.assertEqual(self.old_count(), 16)
        self.assertFalse(self.engine.status()['cleanup_only'])
        self.assertFalse(self.engine.status()['upgrade_pending'])
        self.build(self.engine)
        self.assertEqual(self.old_count(), 0)

    def test_legacy_files_without_pooled_rows_are_detected(self):
        self.build(self.engine)
        folder = self.index/self.models.fingerprint
        folder.mkdir()
        old = folder/'tags.sqlite'
        old.write_bytes(b'legacy')
        before = hashlib.sha256(old.read_bytes()).hexdigest()
        self.engine.close()
        self.engine = self.open_tags()
        self.assertTrue(self.engine.status()['upgrade_available'])
        self.assertTrue(self.engine.preview()['cleanup_only'])
        self.assertEqual(hashlib.sha256(old.read_bytes()).hexdigest(), before)
        self.build(self.engine)
        self.assertFalse(old.exists())

    def test_explicit_rebuild_does_not_take_a_stale_cleanup_only_shortcut(self):
        with patch.object(self.engine, '_cleanup_legacy', side_effect=PermissionError()):
            self.build(self.engine)
        plan = self.engine.preview()
        self.assertTrue(plan['cleanup_only'])
        self.engine.clear()
        self.models.embedded.clear()
        list(self.engine.build(plan['plan_id'], lambda: False))
        self.assertEqual(len(self.models.embedded), 96)
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(self.old_count(), 0)

    def test_failure_after_retirement_can_retry_compaction_without_legacy_rows(self):
        cleanup = self.engine._cleanup_legacy
        def fail_after_deletion():
            cleanup()
            raise PermissionError('fixture compaction failure')
        with patch.object(self.engine, '_cleanup_legacy', side_effect=fail_after_deletion):
            self.build(self.engine)
        self.assertEqual(self.old_count(), 0)
        self.assertTrue(self.engine.status()['upgrade_failed'])
        self.engine.close()
        self.engine = self.open_tags()
        self.models.embedded.clear()
        self.build(self.engine)
        self.assertFalse(self.engine.status()['upgrade_available'])
        self.assertEqual(self.models.embedded, [])
        self.assertEqual(self.snapshot(), self.retained)

    def test_changed_corpus_interrupts_upgrade_and_preserves_old_data(self):
        iterator = self.engine.build(self.engine.preview()['plan_id'], lambda: False)
        next(iterator)
        fixture_corpus(self.corpus, total=25)
        with self.assertRaisesRegex(ValueError, 'source_changed'):
            list(iterator)
        self.assertEqual(self.old_count(), 16)
        self.assertFalse(self.engine.status()['complete'])

    def test_worker_reports_new_index_ready_when_cleanup_checkpoint_also_fails(self):
        from worker import Worker
        with patch.object(self.engine, '_cleanup_legacy', side_effect=PermissionError()):
            self.build(self.engine)
        worker = Worker()
        plan = self.engine.preview()
        worker.engines = {'tags': self.engine}
        worker.jobs = {'upgrade': {'source': 'tags', 'paused': False, 'cancel': threading.Event(),
                                  'generator': self.engine.build(plan['plan_id'], lambda: False)}}
        with patch.object(self.engine, '_cleanup_legacy', side_effect=PermissionError()), \
                patch.object(worker, '_settle_pool', side_effect=PermissionError()), \
                patch.object(worker, '_event') as event:
            worker._step('upgrade')
            worker._step('upgrade')
        result = event.call_args.kwargs
        self.assertEqual(result['phase'], 'complete')
        self.assertTrue(result['complete'])
        self.assertTrue(result['upgrade_failed'])
        self.assertEqual(self.old_count(), 16)


if __name__ == '__main__':
    unittest.main()
