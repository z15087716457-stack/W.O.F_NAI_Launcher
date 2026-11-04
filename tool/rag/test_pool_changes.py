"""After a crash, the pool replays the vectors changed since its last saved
ANN instead of rebuilding it from every row; real pool and usearch."""
import json
import unittest
from unittest.mock import patch

import numpy as np
from usearch.index import Index

from pool import VectorPool
import test_pool as fixtures


class ChangeReplayTests(unittest.TestCase):
    setUp = fixtures.PoolTests.setUp
    tearDown = fixtures.PoolTests.tearDown
    build = fixtures.PoolTests.build

    def generation(self, pool=None):
        return (pool or self.pool).db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]

    def change(self):
        """A vector replaced in place, a document deleted and one added, as a
        build commits them; the ANN in memory is not saved. Returns the ids."""
        db = self.tags.db; self.changes = getattr(self, 'changes', 0) + 1
        first, last = db.execute('SELECT MIN(id),MAX(id) FROM documents').fetchone()
        replaced, added = self.models.embed([f'replaced fixture {self.changes}', f'added fixture {self.changes}'])
        db.execute('UPDATE documents SET vector=? WHERE id=?', (replaced.tobytes(), first))
        db.execute('DELETE FROM documents WHERE id=?', (last,))
        db.execute("INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) "
                   "VALUES('added',0,0,'[]','added','digest',?,'fixture')", (added.tobytes(),))
        new = db.execute("SELECT id FROM documents WHERE name='added'").fetchone()[0]
        db.commit()
        self.tags.ann.remove(first); self.tags.ann.add(first, replaced)
        self.tags.ann.remove(last); self.tags.ann.add(new, added)
        return {first, last, new}

    def crash(self):
        """The process ends: its connections go, nothing more is saved."""
        for db in (self.tags.db, self.pages.db, self.pool.db): db.close()
        self.tags._closed = self.pages._closed = self.pool._closed = True

    def reopen(self):
        added = []
        add = Index.add
        def counted(index, keys, vectors, *args, **kwargs):
            added.extend(np.atleast_1d(np.asarray(keys)).tolist())
            return add(index, keys, vectors, *args, **kwargs)
        with patch.object(Index, 'add', autospec=True, side_effect=counted):
            self.pool = VectorPool(self.root/'indices', self.models.fingerprint)
        return added

    def assert_rows(self, pool):
        rows = pool.db.execute('SELECT id,vector FROM pool_documents').fetchall()
        self.assertEqual(len(pool.ann), len(rows))
        for key, vector in rows:
            np.testing.assert_array_equal(pool.ann.get(key), np.frombuffer(vector, dtype=np.float32))

    def test_a_crash_after_changes_replays_only_them(self):
        self.build(self.tags); self.build(self.pages)
        changed = self.change(); generation = self.generation()
        self.assertTrue(self.pool.unsaved())
        self.crash()
        added = self.reopen()
        # The replaced vector and the new one; nothing else is added again.
        self.assertEqual(len(added), 2); self.assertLessEqual(set(added), changed)
        self.assert_rows(self.pool)
        # Saved at once, so the next start loads it as it is.
        self.assertEqual(json.loads((self.pool.folder/'ann.json').read_text())['generation'], generation)
        self.pool.close()
        with patch.object(Index, 'add', side_effect=AssertionError('replayed again')):
            VectorPool(self.root/'indices', self.models.fingerprint).close()

    def test_a_save_leaves_only_later_changes_to_replay(self):
        self.build(self.tags); self.build(self.pages)
        self.change(); self.pool.checkpoint()
        self.assertEqual(self.pool.db.execute('SELECT COUNT(*) FROM pool_changes').fetchone()[0], 0)
        changed = self.change()
        self.crash()
        added = self.reopen()
        self.assertEqual(len(added), 2); self.assertLessEqual(set(added), changed)
        self.assert_rows(self.pool)

    def test_a_crash_between_the_two_files_of_a_save_replays_from_the_older_mark(self):
        self.build(self.tags); self.build(self.pages)
        self.change()
        from pool import os
        replace = os.replace
        def lose_metadata(source, target):
            if str(target).endswith('ann.json'): raise OSError('fixture crash')
            return replace(source, target)
        # vectors.usearch is the new one, ann.json still the old one.
        with patch('pool.os.replace', side_effect=lose_metadata):
            with self.assertRaises(OSError): self.pool.checkpoint()
        self.change()
        self.crash()
        self.reopen()
        self.assert_rows(self.pool)

    def test_a_cancelled_replay_publishes_nothing_and_the_next_start_replays(self):
        self.build(self.tags); self.build(self.pages)
        self.change()
        before = tuple((self.pool.folder/name).read_bytes() for name in ('vectors.usearch', 'ann.json'))
        self.crash()
        stop = []
        def progress(phase, processed, total):
            if phase == 'restoring': stop.append(True)
        with self.assertRaisesRegex(ValueError, 'cancelled'):
            VectorPool(self.root/'indices', self.models.fingerprint, progress=progress, cancelled=lambda: bool(stop))
        self.assertEqual(tuple((self.pool.folder/name).read_bytes() for name in ('vectors.usearch', 'ann.json')), before)
        self.assertEqual(len(self.reopen()), 2)
        self.assert_rows(self.pool)

    def test_a_checkpoint_saved_without_a_mark_is_rebuilt_from_every_row(self):
        # Saved by an older version: it does not say from which change on to replay.
        self.build(self.tags); self.build(self.pages)
        path = self.pool.folder/'ann.json'; saved = json.loads(path.read_text())
        saved.pop('journal'); path.write_text(json.dumps(saved))
        self.change(); total = self.pool.db.execute('SELECT COUNT(*) FROM pool_documents').fetchone()[0]
        self.crash()
        self.assertEqual(len(self.reopen()), total)
        self.assert_rows(self.pool)

    def test_changes_the_journal_does_not_account_for_are_rebuilt_from_every_row(self):
        self.build(self.tags); self.build(self.pages)
        self.change()
        self.pool.db.execute('DELETE FROM pool_changes'); self.pool.db.commit()
        total = self.pool.db.execute('SELECT COUNT(*) FROM pool_documents').fetchone()[0]
        self.crash()
        self.assertEqual(len(self.reopen()), total)
        self.assert_rows(self.pool)

    def test_a_replay_that_would_leave_most_of_the_ann_removed_builds_it_from_the_rows(self):
        # usearch keeps the place of a removed vector until an add takes it:
        # replayed, these deletions would leave 8 places empty for 1 vector.
        self.build(self.tags); self.build(self.pages)
        self.tags.db.execute('DELETE FROM documents'); self.tags.db.commit()
        self.crash()
        self.assertEqual(len(self.reopen()), 1)
        self.assert_rows(self.pool)
        self.assertEqual(self.pool.ann.stats.nodes, 1)


class ClearTests(unittest.TestCase):
    """Clearing a source removes its vectors from the shared ANN (8 tags and a
    wiki page here). The place of a removed vector stays in the ANN, in its
    file and in a writable copy, until an add takes it: with most of the pool
    cleared, the ANN of the rest is built again from the rows."""
    setUp = fixtures.PoolTests.setUp
    tearDown = fixtures.PoolTests.tearDown
    build = fixtures.PoolTests.build

    def built(self):
        self.build(self.tags); self.build(self.pages); self.pool.checkpoint()
        return (self.pool.folder/'vectors.usearch').stat().st_size

    def places(self):
        """(places, vectors) of the ANN: places count removed vectors too."""
        return self.pool.ann.stats.nodes, len(self.pool.ann)

    def test_clearing_most_of_the_pool_leaves_an_ann_of_the_rest_alone(self):
        before = self.built()
        self.tags.clear()
        self.assertEqual(self.places(), (1, 1))
        self.assertLess((self.pool.folder/'vectors.usearch').stat().st_size, before / 4)
        ChangeReplayTests.assert_rows(self, self.pool)
        # Saved as it is: the next start maps it.
        with patch.object(Index, 'add', side_effect=AssertionError('built again at the start')):
            VectorPool(self.root/'indices', self.models.fingerprint).close()

    def test_clearing_a_small_part_only_removes_its_vectors(self):
        self.built()
        with patch.object(Index, 'add', side_effect=AssertionError('built again from the rows')):
            self.pages.clear()
        self.assertEqual(self.places(), (9, 8))
        ChangeReplayTests.assert_rows(self, self.pool)

    def test_a_source_cleared_and_built_again_takes_back_its_places(self):
        self.built()
        for engine in (self.pages, self.tags):
            with self.subTest(engine.collection):
                engine.clear(); self.build(engine); self.pool.checkpoint()
                self.assertEqual(self.places(), (9, 9))
                ChangeReplayTests.assert_rows(self, self.pool)


if __name__ == '__main__':
    unittest.main()
