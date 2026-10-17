"""Mapped readers and writable builds share one unchanged graph; no real models."""
import hashlib
import json
import os
from pathlib import Path
import threading
import unittest
from unittest.mock import Mock,patch

import numpy as np
from usearch.index import Index
from pool import VectorPool
from worker import Worker
import test_pool as fixtures


class MappedPoolTests(unittest.TestCase):
    setUp = fixtures.PoolTests.setUp
    tearDown = fixtures.PoolTests.tearDown
    build = fixtures.PoolTests.build

    def saved(self):
        return tuple((self.pool.folder/name).read_bytes() for name in ('vectors.usearch','ann.json'))

    def change_vector(self):
        key=self.tags.db.execute('SELECT MIN(id) FROM documents').fetchone()[0]
        vector=self.models.embed(['changed mapped fixture'])[0]
        self.tags.db.execute('UPDATE documents SET vector=? WHERE id=?',(vector.tobytes(),key))
        self.tags.ann.remove(key);self.tags.ann.add(key,vector);self.tags.db.commit()
        return key,vector

    def test_valid_checkpoint_maps_without_rebuilding_or_loading_a_private_copy(self):
        self.build(self.tags);self.build(self.pages)
        before=self.saved()
        with (patch.object(Index,'load',side_effect=AssertionError('Private load')),
              patch.object(Index,'add',side_effect=AssertionError('Rebuild'))):
            reopened=VectorPool(self.root/'indices',self.models.fingerprint)
            try:
                self.assertTrue(reopened.mapped);self.assertEqual(len(reopened.ann),9)
            finally:reopened.close()
        self.assertEqual(self.saved(),before)

    def test_native_copy_is_mutable_and_preserves_graph_search_and_other_sources(self):
        self.build(self.tags);self.build(self.pages)
        self.assertTrue(self.pool.mapped)
        query=self.models.embed(['rain'])[0]
        before=self.pool.ann.search(query,9)
        original=self.saved();self.pool.writable()
        self.assertFalse(self.pool.mapped)
        after=self.pool.ann.search(query,9)
        np.testing.assert_array_equal(before.keys,after.keys)
        np.testing.assert_array_equal(before.distances,after.distances)
        self.assertEqual(self.saved(),original)
        key,vector=self.change_vector();self.pool.checkpoint()
        self.assertTrue(self.pool.mapped)
        self.assertEqual(self.pages.search_text('rain')['items'][0]['id'],'tag_0')
        np.testing.assert_array_equal(self.pool.ann.get(key),vector)

    def test_view_failure_loads_the_same_valid_checkpoint_without_rebuilding(self):
        self.build(self.tags);before=self.saved();query=self.models.embed(['rain'])[0]
        expected=self.pool.ann.search(query,8)
        with (patch.object(Index,'view',side_effect=RuntimeError('fixture mmap unavailable')),
              patch.object(Index,'add',side_effect=AssertionError('Valid graph rebuilt'))):
            reopened=VectorPool(self.root/'indices',self.models.fingerprint)
            try:
                self.assertFalse(reopened.mapped)
                actual=reopened.ann.search(query,8)
                np.testing.assert_array_equal(expected.keys,actual.keys)
                np.testing.assert_array_equal(expected.distances,actual.distances)
            finally:reopened.close()
        self.assertEqual(before,self.saved())

    def test_failed_copy_preserves_the_existing_mapping_and_query(self):
        self.build(self.tags);query=self.models.embed(['rain'])[0]
        before=list(self.pool.ann.search(query,8).keys);original=self.pool.ann
        with patch.object(Index,'copy',side_effect=MemoryError('fixture allocation')):
            with self.assertRaises(MemoryError):self.pool.writable()
        self.assertTrue(self.pool.mapped);self.assertIs(self.pool.ann,original)
        self.assertEqual(list(self.pool.ann.search(query,8).keys),before)

    def test_unchanged_incremental_build_never_copies_or_saves_the_mapped_index(self):
        self.build(self.tags);before=self.saved()
        with (patch.object(Index,'copy',side_effect=AssertionError('Unchanged copy')),
              patch.object(Index,'save',side_effect=AssertionError('Unchanged save'))):
            self.build(self.tags)
        self.assertTrue(self.pool.mapped);self.assertEqual(self.pool._builders,0)
        self.assertEqual(self.saved(),before)

    def test_periodic_saves_do_not_remap_or_copy_each_build_batch(self):
        self.tags.batch_size=2
        generator=self.tags.build(self.tags.preview()['plan_id'],lambda:False)
        try:
            next(generator);self.assertFalse(self.pool.mapped)
            with patch.object(Index,'copy',side_effect=AssertionError('Repeated mutable copy')):
                self.pool.checkpoint();self.assertFalse(self.pool.mapped)
                next(generator);self.pool.checkpoint();self.assertFalse(self.pool.mapped)
                list(generator)
            self.assertTrue(self.pool.mapped);self.assertEqual(self.pool._builders,0)
        finally:generator.close()

    def test_interleaved_builders_keep_the_writer_until_the_last_builder_finishes(self):
        self.tags.batch_size=2
        tags=self.tags.build(self.tags.preview()['plan_id'],lambda:False)
        pages=self.pages.build(self.pages.preview()['plan_id'],lambda:False)
        try:
            next(tags);next(pages);self.assertEqual(self.pool._builders,2)
            list(pages);self.assertEqual(self.pool._builders,1);self.assertFalse(self.pool.mapped)
            list(tags);self.assertEqual(self.pool._builders,0);self.assertTrue(self.pool.mapped)
        finally:tags.close();pages.close()

    def test_cancelled_checkpoint_keeps_old_files_and_writable_progress_for_retry(self):
        self.build(self.tags);before=self.saved();self.change_vector()
        calls=0
        def cancelled():
            nonlocal calls
            calls+=1;return calls>1
        with self.assertRaisesRegex(ValueError,'cancelled'):self.pool.checkpoint(cancelled=cancelled)
        self.assertFalse(self.pool.mapped);self.assertEqual(self.saved(),before)
        self.pool.checkpoint();self.assertTrue(self.pool.mapped);self.assertNotEqual(self.saved(),before)

    def test_mapping_failure_after_publication_retains_query_and_can_retry_without_resaving(self):
        self.build(self.tags);self.change_vector()
        with patch.object(Index,'view',side_effect=RuntimeError('fixture mapping unavailable')):
            self.pool.checkpoint()
        self.assertFalse(self.pool.mapped)
        self.assertTrue(len(self.pool.ann.search(self.models.embed(['rain'])[0],8).keys))
        before=self.saved()
        with patch.object(Index,'save',side_effect=AssertionError('Clean save repeated')):self.pool.checkpoint()
        self.assertTrue(self.pool.mapped);self.assertEqual(self.saved(),before)

    def test_cancelled_reload_releases_its_new_mapping_and_retains_the_previous_index(self):
        self.build(self.tags);self.pool.writable();previous=self.pool.ann
        calls=0
        def cancelled():
            nonlocal calls
            calls+=1;return calls>1
        with self.assertRaisesRegex(ValueError,'cancelled'):self.pool.reload(cancelled=cancelled)
        self.assertIs(self.pool.ann,previous);self.assertEqual(len(previous),8)
        path=self.pool.folder/'vectors.usearch';replacement=path.with_suffix('.probe')
        replacement.write_bytes(path.read_bytes());os.replace(replacement,path)
        self.pool.checkpoint();self.assertTrue(self.pool.mapped)

    def test_close_releases_windows_file_mapping_even_if_python_reference_survives(self):
        self.build(self.tags);reference=self.pool.ann;path=self.pool.folder/'vectors.usearch'
        before=hashlib.sha256(path.read_bytes()).hexdigest()
        self.tags.close();self.pages.close();self.pool.close()
        self.assertEqual(len(reference),0)
        replacement=path.with_suffix('.probe');replacement.write_bytes(path.read_bytes());os.replace(replacement,path)
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),before)

    def test_close_failure_still_releases_the_mapping_and_is_idempotent(self):
        self.build(self.tags);reference=self.pool.ann;path=self.pool.folder/'vectors.usearch'
        with patch.object(self.pool,'checkpoint',side_effect=OSError('fixture close save')):
            with self.assertRaises(OSError):self.pool.close()
        self.pool.close();self.assertEqual(len(reference),0)
        replacement=path.with_suffix('.probe');replacement.write_bytes(path.read_bytes());os.replace(replacement,path)

    def worker(self):
        self.models.unload=Mock()
        worker=Worker();worker.models=self.models;worker.pool=self.pool
        worker.engines={'tags':self.tags,'wiki':self.pages}
        return worker

    def start(self,worker,source):
        token=threading.Event();plan=worker.execute('preview',{'source':source},token)
        return worker.execute('start',{'source':source,'plan_id':plan['plan_id']},token)['job_id']

    def test_last_pause_maps_committed_partial_index_and_resume_accepts_new_vectors(self):
        self.tags.batch_size=2;worker=self.worker();job=self.start(worker,'tags');token=threading.Event()
        with patch('worker.emit'):
            worker._step(job);self.assertFalse(self.pool.mapped)
            worker.execute('pause',{'source':'tags','job_id':job},token)
            self.assertTrue(self.pool.mapped);self.assertEqual(len(self.tags.ann),2)
            worker.execute('resume',{'source':'tags','job_id':job},token)
            worker._step(job);self.assertFalse(self.pool.mapped);self.assertEqual(len(self.tags.ann),4)
            while job in worker.jobs:worker._step(job)
        self.assertTrue(self.pool.mapped);self.assertTrue(self.tags.status()['complete'])

    def test_pausing_one_source_does_not_remap_under_another_running_builder(self):
        self.tags.batch_size=2;worker=self.worker();tags=self.start(worker,'tags');pages=self.start(worker,'wiki');token=threading.Event()
        try:
            with patch('worker.emit'):
                worker._step(tags);worker._step(pages)
            worker.execute('pause',{'source':'tags','job_id':tags},token);self.assertFalse(self.pool.mapped)
            worker.execute('pause',{'source':'wiki','job_id':pages},token);self.assertTrue(self.pool.mapped)
        finally:
            for job in worker.jobs.values():job['generator'].close()
            worker.jobs.clear()

    def test_suspend_maps_only_committed_vectors_without_ending_build(self):
        self.tags.batch_size=2;worker=self.worker();job=self.start(worker,'tags')
        try:
            with patch('worker.emit'):worker._step(job)
            worker.execute('suspend',{},threading.Event())
            self.assertTrue(self.pool.mapped);self.assertTrue(worker.suspended);self.assertEqual(len(self.tags.ann),2)
            self.models.unload.assert_called_once()
        finally:worker.jobs[job]['generator'].close();worker.jobs.clear()

    def test_pause_save_failure_retains_committed_vectors_and_can_retry(self):
        self.tags.batch_size=2;worker=self.worker();job=self.start(worker,'tags');token=threading.Event()
        try:
            with patch('worker.emit'):worker._step(job)
            with patch('pool.os.replace',side_effect=OSError('fixture publish')):
                with self.assertRaises(OSError):worker.execute('pause',{'source':'tags','job_id':job},token)
            self.assertTrue(worker.jobs[job]['paused']);self.assertFalse(self.pool.mapped)
            self.assertEqual(len(self.tags.ann),2)
            worker.execute('pause',{'source':'tags','job_id':job},token);self.assertTrue(self.pool.mapped)
        finally:worker.jobs[job]['generator'].close();worker.jobs.clear()

    def test_settle_failure_after_job_completion_is_reported_without_escaping_worker_step(self):
        worker=self.worker();job=self.start(worker,'tags')
        with patch('worker.emit') as emitted:
            worker._step(job)
            with patch.object(worker,'_settle_pool',side_effect=OSError('fixture idle save')):
                worker._step(job)
        self.assertNotIn(job,worker.jobs)
        self.assertTrue(any(call.args[0].get('phase')=='error' for call in emitted.call_args_list))


if __name__=='__main__':unittest.main()
