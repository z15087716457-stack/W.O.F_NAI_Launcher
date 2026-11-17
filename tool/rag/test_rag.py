import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from engine import Engine, Sources as CatalogSources


class FakeModels:
    fingerprint = 'fixture-model-v1'
    def __init__(self): self.embedded = []; self.queries = []
    def count(self, value): return len(value.replace(',', ' ').split())
    def embed(self, texts, query=False):
        import numpy as np
        (self.queries if query else self.embedded).extend(texts)
        vectors = np.zeros((len(texts),768),dtype=np.float32)
        for i,text in enumerate(texts):
            vectors[i,0] = 1
            vectors[i,1] = int(hashlib.sha256(text.encode()).hexdigest()[:4],16)/65536
            vectors[i] /= np.linalg.norm(vectors[i])
        return vectors


def fixture(path, total=70):
    db = sqlite3.connect(path)
    db.executescript('CREATE TABLE tags(id INTEGER PRIMARY KEY,name TEXT UNIQUE,category INT,post_count INT); CREATE TABLE aliases(tag_id INT,alias TEXT);')
    for i in range(total): db.execute('INSERT INTO tags VALUES(?,?,?,?)',(i+1,f'tag_{i}',0,total-i))
    db.execute('INSERT INTO aliases VALUES(1,?)',('known_alias',));db.commit();db.close()


class Sources(CatalogSources):
    """Synthetic documents for persistence tests, independent of tag retrieval."""
    def rows(self, *args, **kwargs):
        result = super().rows(*args, **kwargs)
        for row in result:
            text = json.dumps({key:value for key,value in row.items() if key!='post_count'},ensure_ascii=False,sort_keys=True)
            row.update(text=text,digest=hashlib.sha256(text.encode()).hexdigest())
        return result


class IndexTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.source=self.root/'catalog.db';fixture(self.source)
        self.models=FakeModels();self.engine=Engine(self.root/'index',self.models,Sources(self.source))
    def tearDown(self): self.engine.close();self.temp.cleanup()
    def build(self):
        plan=self.engine.preview();return list(self.engine.build(plan['plan_id'],lambda:False))
    def test_preview_and_status_do_not_create_vectors(self):
        self.assertEqual(self.engine.preview()['total'],70)
        self.assertEqual(self.models.embedded,[])
        self.assertFalse(self.engine.status()['auto_update_allowed'])
    def test_noop_verification_is_not_a_vector_build(self):
        signals = []
        plan = self.engine.preview()
        def signal(value):
            self.assertTrue(value['building'])
            self.assertEqual(len(self.models.embedded), value['processed'])
            signals.append(value)
        first = list(self.engine.build(plan['plan_id'], lambda:False, progress=signal))
        self.assertEqual(len(signals), 3)
        self.assertTrue(all(p['building'] and not p['checking'] for p in first))
        self.models.embedded.clear()
        db = sqlite3.connect(self.source)
        db.execute('UPDATE tags SET post_count=post_count+1'); db.commit(); db.close()
        self.assertFalse(self.engine.status()['complete'])
        checked = self.build()
        self.assertTrue(all(p['checking'] and not p['building'] for p in checked))
        self.assertTrue(all(p['indexed'] == p['total'] for p in checked))
        self.assertEqual(self.models.embedded, [])
        self.assertFalse(self.engine.status()['checking'])
        self.assertFalse(self.engine.status()['building'])
        self.assertTrue(self.engine.status()['complete'])

    def test_wrong_plan_rejected(self):
        self.engine.preview()
        with self.assertRaises(ValueError): list(self.engine.build('wrong',lambda:False))
    def test_source_drift_invalidates_plan(self):
        plan=self.engine.preview();db=sqlite3.connect(self.source);db.execute("UPDATE tags SET name='changed' WHERE id=1");db.commit();db.close()
        with self.assertRaisesRegex(ValueError,'source_changed'): list(self.engine.build(plan['plan_id'],lambda:False))
    def test_partial_index_resumes_without_reembedding(self):
        cancel=False;plan=self.engine.preview();build=self.engine.build(plan['plan_id'],lambda:cancel)
        next(build);cancel=True;list(build)
        self.assertEqual(self.engine.status()['indexed'],32)
        self.assertTrue(self.engine.status()['partial'])
        self.build();self.assertEqual(len(self.models.embedded),70)
        self.assertTrue(self.engine.status()['complete'])
    def test_restart_keeps_vectors_and_consent(self):
        self.build();self.engine.close();self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertEqual(self.engine.status()['indexed'],70)
        self.assertTrue(self.engine.status()['auto_update_allowed'])
        self.assertEqual(self.engine.models.embedded,[])
    def test_count_change_does_not_reembed(self):
        self.build();self.models.embedded.clear()
        db=sqlite3.connect(self.source);db.execute('UPDATE tags SET post_count=post_count+1');db.commit();db.close()
        self.build();self.assertEqual(self.models.embedded,[])
    def test_clear_only_removes_derived_data(self):
        self.build();before=hashlib.sha256(self.source.read_bytes()).hexdigest()
        self.engine.clear();self.assertEqual(self.engine.status()['indexed'],0)
        self.assertFalse(self.engine.status()['auto_update_allowed'])
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(),before)
    def test_changed_description_only_updates_changed_document(self):
        self.build();self.models.embedded.clear()
        db=sqlite3.connect(self.source);db.execute("INSERT INTO aliases VALUES(2,'new_alias')");db.commit();db.close()
        self.build();self.assertEqual(len(self.models.embedded),1)

    def test_paused_consent_survives_reopening(self):
        self.build()
        self.engine.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused','1')");self.engine.db.commit()
        self.engine.close();self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertTrue(self.engine.status()['paused'])
        self.assertFalse(self.engine.status()['auto_update_allowed'])

    def test_corrupted_ann_checkpoint_is_rebuilt_from_sqlite(self):
        self.build();self.engine.close()
        (self.engine.folder/'vectors.usearch').write_bytes(b'corrupted')
        self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertEqual(self.engine.status()['indexed'],70)
        self.assertTrue(len(self.engine.ann.search(self.models.embed(['rain'],query=True)[0],5).keys))

    def test_source_ordering_is_done_once_per_build_not_per_batch(self):
        from unittest.mock import patch
        source=self.engine.sources
        with patch.object(source,'ordered_names',wraps=source.ordered_names) as ordered:
            self.build();self.assertEqual(ordered.call_count,1)

    def test_crash_after_deleted_rows_commit_invalidates_previous_checkpoint(self):
        from unittest.mock import patch
        self.build()
        db=sqlite3.connect(self.source);db.execute('DELETE FROM tags WHERE id=1');db.commit();db.close()
        plan=self.engine.preview();build=self.engine.build(plan['plan_id'],lambda:False)
        while next(build)['processed'] < plan['total']: pass
        self.engine._checkpoint()  # Periodic save before the final stale-row cleanup.
        with patch.object(self.engine,'_checkpoint',side_effect=RuntimeError('crash')):
            with self.assertRaisesRegex(RuntimeError,'crash'): next(build)
        self.engine.pool.db.close()  # Process loss also releases the shared connection.
        self.engine.db.close()  # Process loss: skip the normal close checkpoint.
        self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertEqual(self.engine.status()['indexed'],69)
        self.assertTrue(self.engine.status()['complete'])


if __name__=='__main__': unittest.main()
