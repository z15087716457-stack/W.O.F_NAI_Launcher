"""Native ANN scope and checkpoint migration; all data is synthetic and isolated."""
from contextlib import closing
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import numpy as np
from usearch.index import Index

from pool import VectorPool
from tag_search import TagEngine, TagSources
from test_rag import FakeModels
from test_tag_search import fixture_corpus

EXACT_TAGS = 'danbooru-search-v1'


class AnnScopeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.directory = self.root/'index'
        self.models = FakeModels()
        self.pool = self.open_pool()
        self.connections = {}

    def open_pool(self, **kwargs):
        pool = VectorPool(self.directory, self.models.fingerprint, **kwargs)
        self.addCleanup(pool.close)
        return pool

    def collection(self, name):
        if name not in self.connections:
            db, view = self.pool.collection(name, self.root/'absent')
            self.addCleanup(db.close)
            self.connections[name] = db, view
        return self.connections[name]

    @staticmethod
    def vector(value):
        result = np.zeros(768, dtype=np.float32)
        result[0] = 1
        result[1] = value
        return result/np.linalg.norm(result)

    def put(self, collection, name, value=0):
        db, view = self.collection(collection)
        vector = self.vector(value)
        with db:
            db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) '
                       'VALUES(?,0,1,\'[]\',?,\'fixture\',?,\'fixture\')', (name, name, vector.tobytes()))
            key = db.execute('SELECT id FROM documents WHERE name=?', (name,)).fetchone()[0]
            if key in view: view.remove(key)
            view.add(key, vector)
        return key

    def rows(self):
        return self.pool.db.execute('SELECT * FROM pool_documents ORDER BY id').fetchall()

    def legacy_checkpoint(self, keys=None):
        """Publish the old all-source graph, without a scope discriminator."""
        self.pool.close()  # Release Windows mmap before replacing the fixture.
        graph = Index(ndim=768, metric='cos', dtype='f32')
        with closing(sqlite3.connect(self.pool.path)) as db:
            rows = db.execute('SELECT id,vector FROM pool_documents ORDER BY id').fetchall()
            generation = db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        rows = [row for row in rows if keys is None or row[0] in keys]
        graph.add(np.array([row[0] for row in rows], dtype=np.uint64),
                  np.stack([np.frombuffer(row[1], dtype=np.float32) for row in rows]))
        graph.save(str(self.pool.folder/'vectors.usearch'))
        graph.reset()
        (self.pool.folder/'ann.json').write_text(json.dumps(
            {'generation':generation, 'count':len(rows), 'journal':1}), encoding='utf-8')

    def test_exact_tags_keep_source_counts_without_entering_shared_ann(self):
        tag = self.put(EXACT_TAGS, '["cat_ears","name"]')
        wiki = self.put('wiki', 'article', .3)
        self.assertEqual(len(self.collection(EXACT_TAGS)[1]), 1)
        self.assertEqual(len(self.collection('wiki')[1]), 1)
        self.assertEqual(set(self.pool.ann.keys), {wiki})
        self.assertNotIn(tag, self.pool.ann)

    def test_tag_mutations_do_not_copy_or_republish_the_shared_graph(self):
        self.put('blocks', 'saved')
        self.pool.checkpoint()
        before = (self.pool.folder/'vectors.usearch').read_bytes()
        generation = self.pool._current_state()
        with patch.object(self.pool, 'writable', side_effect=AssertionError('Tag writes copied ANN')), \
                patch('usearch.index.Index.save', side_effect=AssertionError('Tag writes saved ANN')):
            self.put(EXACT_TAGS, 'tag', .2)
            self.put(EXACT_TAGS, 'tag', .4)
            db, view = self.collection(EXACT_TAGS)
            key = db.execute('SELECT id FROM documents').fetchone()[0]
            with db: db.execute('DELETE FROM documents')
            view.remove(key)
            self.pool.checkpoint()
        self.assertTrue(self.pool.mapped)
        self.assertEqual(self.pool._current_state(), generation)
        self.assertEqual(self.pool.db.execute('SELECT COUNT(*) FROM pool_changes').fetchone()[0], 0)
        self.assertEqual((self.pool.folder/'vectors.usearch').read_bytes(), before)

    def test_legacy_graph_is_compacted_without_changing_sqlite_vectors(self):
        self.put(EXACT_TAGS, 'tag')
        wiki = self.put('wiki', 'article', .3)
        block = self.put('blocks', 'saved', .4)
        before = self.rows()
        self.legacy_checkpoint()
        with patch.object(FakeModels, 'embed', side_effect=AssertionError('Migration re-embedded')):
            reopened = self.open_pool()
        self.assertEqual(set(reopened.ann.keys), {wiki, block})
        self.assertEqual(reopened.db.execute('SELECT * FROM pool_documents ORDER BY id').fetchall(), before)
        metadata = json.loads((reopened.folder/'ann.json').read_text('utf-8'))
        self.assertEqual(metadata['count'], 2)
        self.assertIn('scope', metadata)
        reopened.close()
        with patch('usearch.index.Index.add', side_effect=AssertionError('Migration repeated')):
            self.open_pool().close()

    def test_missing_scope_is_not_trusted_when_old_count_happens_to_match(self):
        tag = self.put(EXACT_TAGS, 'tag')
        wiki = self.put('wiki', 'article')
        self.legacy_checkpoint(keys={tag})
        reopened = self.open_pool()
        self.assertEqual(set(reopened.ann.keys), {wiki})

    def test_cancelled_migration_leaves_previous_checkpoint_and_vectors_intact(self):
        self.put(EXACT_TAGS, 'tag')
        self.put('wiki', 'article')
        before = self.rows()
        self.legacy_checkpoint()
        graph = (self.pool.folder/'vectors.usearch').read_bytes()
        metadata = (self.pool.folder/'ann.json').read_bytes()
        cancelled = False
        def progress(phase, processed, total):
            nonlocal cancelled
            if phase == 'restoring': cancelled = True
        with self.assertRaisesRegex(ValueError, 'cancelled'):
            self.open_pool(progress=progress, cancelled=lambda: cancelled)
        self.assertEqual((self.pool.folder/'vectors.usearch').read_bytes(), graph)
        self.assertEqual((self.pool.folder/'ann.json').read_bytes(), metadata)
        reopened = self.open_pool()
        self.assertEqual(reopened.db.execute('SELECT * FROM pool_documents ORDER BY id').fetchall(), before)
        self.assertEqual(len(reopened.ann), 1)

    def test_legacy_exact_collection_import_keeps_vectors_out_of_ann(self):
        folder = self.root/'legacy'
        folder.mkdir()
        path = folder/'tags.sqlite'
        with closing(sqlite3.connect(path)) as db, db:
            db.execute('CREATE TABLE documents(name,category,post_count,aliases,text,digest,vector,seen)')
            db.execute('CREATE TABLE metadata(key,value)')
            db.execute('INSERT INTO documents VALUES(?,0,1,\'[]\',?,\'fixture\',?,\'fixture\')',
                       ('tag', 'tag', self.vector(.3).tobytes()))
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        db, view = self.pool.collection(EXACT_TAGS, folder)
        self.addCleanup(db.close)
        self.assertEqual(len(view), 1)
        self.assertEqual(len(self.pool.ann), 0)
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before)

    def test_real_tag_build_search_and_clear_leave_other_sources_unchanged(self):
        corpus = self.root/'corpus.csv'
        fixture_corpus(corpus)
        wiki = self.put('wiki', 'article', .3)
        self.pool.checkpoint()
        graph = (self.pool.folder/'vectors.usearch').read_bytes()
        engine = TagEngine(self.directory/'danbooru-search-v1', self.models, TagSources(corpus), pool=self.pool)
        self.addCleanup(engine.close)
        list(engine.build(engine.preview()['plan_id'], lambda: False))
        self.assertEqual(engine.status()['indexed'], 96)
        self.assertTrue(engine.search('cat ears')['items'])
        self.assertEqual(set(self.pool.ann.keys), {wiki})
        self.assertEqual((self.pool.folder/'vectors.usearch').read_bytes(), graph)

        engine.clear()
        self.assertEqual(engine.status()['indexed'], 0)
        self.assertEqual(set(self.pool.ann.keys), {wiki})
        self.assertEqual((self.pool.folder/'vectors.usearch').read_bytes(), graph)

    def test_mixed_journal_replay_tracks_changes_of_ann_membership(self):
        wiki = [self.put('wiki', str(index), index/100) for index in range(10)]
        tag = self.put(EXACT_TAGS, 'tag')
        self.pool.checkpoint()
        with self.pool.db:
            self.pool.db.execute('UPDATE pool_documents SET collection=? WHERE id=?', (EXACT_TAGS, wiki[0]))
            self.pool.db.execute("UPDATE pool_documents SET collection='wiki' WHERE id=?", (tag,))
            self.pool.db.execute('UPDATE pool_documents SET vector=? WHERE id=?', (self.vector(.6).tobytes(), wiki[1]))
            self.pool.db.execute('DELETE FROM pool_documents WHERE id=?', (wiki[2],))
        with patch.object(self.pool, '_replay', wraps=self.pool._replay) as replay:
            self.pool.reload()
            replay.assert_called_once()
        expected = {key for key, in self.pool.db.execute(
            'SELECT id FROM pool_documents WHERE collection!=?', (EXACT_TAGS,))}
        self.assertEqual(set(self.pool.ann.keys), expected)
        np.testing.assert_array_equal(self.pool.ann.get(wiki[1]), self.vector(.6))
        self.assertEqual(len(self.collection(EXACT_TAGS)[1]), 1)
        self.pool.checkpoint()

    def test_interrupted_migration_publication_recovers_from_sqlite(self):
        self.put(EXACT_TAGS, 'tag')
        wiki = self.put('wiki', 'article')
        before = self.rows()
        self.legacy_checkpoint()
        original = os.replace
        def replace(source, target):
            if str(target).endswith('ann.json'):
                raise PermissionError('fixture checkpoint metadata locked')
            return original(source, target)
        with patch('pool.os.replace', side_effect=replace):
            with self.assertRaises(PermissionError): self.open_pool()
        reopened = self.open_pool()
        self.assertEqual(set(reopened.ann.keys), {wiki})
        self.assertEqual(reopened.db.execute('SELECT * FROM pool_documents ORDER BY id').fetchall(), before)
        self.assertFalse(reopened.unsaved())

    def test_abrupt_exit_preserves_partial_tags_and_replays_other_sources(self):
        wiki = self.put('wiki', 'article')
        corpus = self.root/'corpus.csv'
        fixture_corpus(corpus)
        self.pool.close()
        script = '''
import os,sys
from pathlib import Path
from pool import VectorPool
from tag_search import TagEngine,TagSources
from test_rag import FakeModels
models=FakeModels()
pool=VectorPool(sys.argv[1],models.fingerprint)
tags=TagEngine(Path(sys.argv[1])/'danbooru-search-v1',models,TagSources(sys.argv[2]),pool=pool)
build=tags.build(tags.preview()['plan_id'],lambda:False)
next(build)
vector=models.embed(['changed article'])[0].tobytes()
with pool.db: pool.db.execute("UPDATE pool_documents SET vector=? WHERE collection='wiki'",(vector,))
os._exit(0)
'''
        subprocess.run([sys.executable, '-B', '-c', script, str(self.directory), str(corpus)],
                       cwd=Path(__file__).resolve().parent, timeout=30, check=True)
        reopened = self.open_pool()
        self.assertEqual(set(reopened.ann.keys), {wiki})
        np.testing.assert_array_equal(reopened.ann.get(wiki), self.models.embed(['changed article'])[0])
        engine = TagEngine(self.directory/'danbooru-search-v1', self.models, TagSources(corpus), pool=reopened)
        self.addCleanup(engine.close)
        self.assertEqual(engine.status()['indexed'], 32)
        self.assertTrue(engine.status()['partial'])
        self.models.embedded.clear()
        list(engine.build(engine.preview()['plan_id'], lambda: False))
        self.assertEqual(len(self.models.embedded), 64)
        self.assertEqual(engine.status()['indexed'], 96)
        self.assertTrue(engine.search('cat ears')['items'])
        self.assertEqual(set(reopened.ann.keys), {wiki})


if __name__ == '__main__':
    unittest.main()
