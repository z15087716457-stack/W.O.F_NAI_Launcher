import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from context import context_window, cursor_index, clean_tag
from engine import Engine, Sources


class FakeModels:
    fingerprint = 'fixture-model-v1'
    def __init__(self): self.embedded = []; self.queries = []; self.negative = None
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
    def rerank(self, query, documents, negative=False):
        self.negative = negative
        return [float('rain' in d) for d in documents]


def fixture(path, total=70):
    db = sqlite3.connect(path)
    db.executescript('CREATE TABLE tags(id INTEGER PRIMARY KEY,name TEXT UNIQUE,category INT,post_count INT); CREATE TABLE aliases(tag_id INT,alias TEXT);')
    for i in range(total): db.execute('INSERT INTO tags VALUES(?,?,?,?)',(i+1,f'tag_{i}',0,total-i))
    db.execute('INSERT INTO aliases VALUES(1,?)',('known_alias',));db.commit();db.close()


class ContextTests(unittest.TestCase):
    def setUp(self): self.count = FakeModels().count
    def test_before_does_not_read_future_tags(self):
        text='rain, night, future'
        result=context_window(text,len('rain, night,'),'before',self.count)
        self.assertEqual(result['text'],'rain, night')
    def test_around_uses_both_sides(self):
        result=context_window('rain, night, city',6,'around',self.count)
        self.assertEqual(result['text'],'rain, night, city')
    def test_both_modes_respect_120_and_stay_local(self):
        text=', '.join(f'word{i}' for i in range(400));cursor=len(text)//2
        for mode in ('before','around'):
            result=context_window(text,cursor,mode,self.count)
            self.assertLessEqual(result['tokens'],120)
            self.assertNotIn('word0,',result['text'])
    def test_utf16_cursor_is_not_python_codepoint_offset(self):
        self.assertEqual(cursor_index('🌧, rain, city',4),3)
        self.assertEqual(context_window('🌧, rain, city',4,'before',self.count)['text'],'🌧')
    def test_weight_syntax_preserves_input(self):
        text='1.4::white_hair::, {rain}, [night]'
        self.assertEqual(clean_tag('1.4::white_hair::'),'white hair')
        self.assertIn('white hair',context_window(text,len(text),'before',self.count)['text'])
        self.assertEqual(text,'1.4::white_hair::, {rain}, [night]')
    def test_incomplete_tag_and_alias_are_not_index_instructions(self):
        self.assertEqual(context_window('<private-block>, rain, unfinished',23,'before',self.count)['text'],'rain')
    def test_whole_prompt_mode_is_rejected(self):
        with self.assertRaises(ValueError): context_window('rain',4,'all',self.count)
    def test_pill_instance_markers_are_not_sent_to_the_model(self):
        result=context_window('rain, \ue001night, \ue002',16,'around',self.count)
        self.assertEqual(result['text'],'rain, night')


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
    def test_deleted_sources_are_not_returned_from_old_vectors(self):
        self.build();db=sqlite3.connect(self.source);db.execute('DELETE FROM tags WHERE id=1');db.commit();db.close()
        result=self.engine.search('rain',4,'before',[],['tag_0'],False)
        self.assertNotIn('tag_0',[r['name'] for r in result['items']])
    def test_alias_dedup_and_negative_intent(self):
        self.build();result=self.engine.search('rain',4,'before',['known_alias'],['tag_0'],True)
        self.assertNotIn('tag_0',[r['name'] for r in result['items']])
        self.assertTrue(self.models.negative)
    def test_query_never_becomes_a_document(self):
        self.build();secret='private_unique_prompt_content'
        self.engine.search(secret,len(secret),'before',[],[],False)
        self.assertFalse(self.engine.db.execute('SELECT 1 FROM documents WHERE text LIKE ?',('%'+secret+'%',)).fetchone())
    def test_clear_only_removes_derived_data(self):
        self.build();before=hashlib.sha256(self.source.read_bytes()).hexdigest()
        self.engine.clear();self.assertEqual(self.engine.status()['indexed'],0)
        self.assertFalse(self.engine.status()['auto_update_allowed'])
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(),before)
    def test_cancelled_query_does_not_embed(self):
        self.build();self.models.queries.clear()
        with self.assertRaisesRegex(ValueError,'cancelled'):
            self.engine.search('rain',4,'before',[],[],False,cancelled=lambda:True)
        self.assertEqual(self.models.queries,[])
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
        (self.engine.folder/'tags.usearch').write_bytes(b'corrupted')
        self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertEqual(self.engine.status()['indexed'],70)
        self.assertTrue(self.engine.search('rain',4,'before',[],[],False)['items'])

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
        self.engine.db.close()  # Process loss: skip the normal close checkpoint.
        self.engine=Engine(self.root/'index',FakeModels(),Sources(self.source))
        self.assertEqual(self.engine.status()['indexed'],69)
        self.assertTrue(self.engine.status()['complete'])


if __name__=='__main__': unittest.main()
