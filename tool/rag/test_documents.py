import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
import threading
from unittest.mock import patch

from documents import TextEngine, WikiSources, BlockSources, count_chunks
from test_rag import FakeModels, fixture


class TextModels(FakeModels):
    def rerank(self,query,documents,negative=False,purpose='tags'):
        self.purpose=purpose
        return [float('umbrella' in d) for d in documents]


class DocumentTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.catalog=self.root/'catalog.db';fixture(self.catalog,3)
        self.wiki=self.root/'wiki.db';db=sqlite3.connect(self.wiki)
        db.execute('CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT,source_url TEXT)')
        db.executemany('INSERT INTO wiki_pages VALUES(?,?,?)',[
            ('tag_0','umbrella in the rain. '*180,'https://example.test/0'),
            ('tag_1','sunlight on the beach','https://example.test/1'),('empty','  ','')]);db.commit();db.close()
        self.snapshot=self.root/'blocks.json';self.write_blocks()
        self.models=TextModels()
        self.engines=[TextEngine(self.root/'wiki-index',self.models,WikiSources(self.wiki,self.catalog)),
                      TextEngine(self.root/'blocks-index',self.models,BlockSources(self.snapshot))]
    def tearDown(self):
        if hasattr(self,'worker'):
            for job in self.worker.jobs.values(): job['generator'].close()
        for engine in self.engines: engine.close()
        self.temp.cleanup()
    def write_blocks(self,items=None):
        self.snapshot.write_text(json.dumps({'version':1,'blocks':items or [
            {'id':'雨:[0]','title':'Storm','positive':'umbrella, rain','negative':'sunlight','tags':['weather']},
            {'id':'beach','title':'Vacation','positive':'sand, sea, sunlight','negative':'','tags':[]}]}),encoding='utf-8')
    def build(self,engine):
        return list(engine.build(engine.preview()['plan_id'],lambda:False))
    def test_preview_counts_documents_and_chunks_without_embedding(self):
        plan=self.engines[0].preview()
        self.assertEqual(plan['documents'],2)
        self.assertEqual(plan['total'],count_chunks('umbrella in the rain. '*180)+1)
        self.assertEqual(self.models.embedded,[])
    def test_collections_are_separate_but_share_one_model_owner(self):
        for engine in self.engines:self.build(engine)
        self.assertIs(self.engines[0].models,self.engines[1].models)
        self.assertNotEqual(self.engines[0].folder,self.engines[1].folder)
        wiki=self.engines[0].search_text('rain')['items'];blocks=self.engines[1].search_text('rain')['items']
        self.assertEqual({r['id'] for r in wiki},{'tag_0','tag_1'})
        self.assertEqual({r['id'] for r in blocks},{'雨:[0]','beach'})
        self.assertEqual(self.models.purpose,'retrieval')
    def test_long_article_deduplicates_to_one_search_result(self):
        self.build(self.engines[0]);result=self.engines[0].search_text('rain')['items']
        self.assertEqual(sum(r['id']=='tag_0' for r in result),1)
        self.assertTrue(all(len(r['snippet'])<=320 for r in result))
    def test_scope_is_applied_before_ranking_even_for_a_small_folder(self):
        engine=self.engines[1];self.build(engine)
        self.assertEqual([r['id'] for r in engine.search_text('rain',allowed=['beach'])['items']],['beach'])
        self.assertEqual(engine.search_text('rain',allowed=[])['items'],[])
    def test_category_filter_uses_only_its_own_indexed_documents(self):
        engine=self.engines[0];self.build(engine)
        self.assertEqual(engine.search_text('rain',categories=[99])['items'],[])
    def test_changed_and_deleted_blocks_cannot_leak_from_stale_vectors(self):
        engine=self.engines[1];self.build(engine)
        self.write_blocks([{'id':'beach','title':'Changed','positive':'forest','negative':'','tags':[]}])
        self.assertEqual(engine.search_text('rain')['items'],[])
        self.build(engine)
        self.assertEqual([r['id'] for r in engine.search_text('forest')['items']],['beach'])
    def test_incremental_build_reuses_unchanged_chunks(self):
        engine=self.engines[1];self.build(engine);self.models.embedded.clear()
        self.build(engine);self.assertEqual(self.models.embedded,[])
    def test_clearing_wiki_does_not_remove_blocks_or_original_files(self):
        for engine in self.engines:self.build(engine)
        original=hashlib.sha256(self.wiki.read_bytes()).hexdigest()
        self.engines[0].clear()
        self.assertGreater(self.engines[1].status()['indexed'],0)
        self.assertEqual(hashlib.sha256(self.wiki.read_bytes()).hexdigest(),original)
    def test_queries_are_bounded_and_not_persisted(self):
        engine=self.engines[1];self.build(engine)
        query='private_query '*800;engine.search_text(query)
        self.assertLessEqual(self.models.count(self.models.queries[-1]),256)
        self.assertFalse(engine.db.execute("SELECT 1 FROM documents WHERE text LIKE '%private_query%'").fetchone())
    def test_partial_index_remains_searchable(self):
        engine=self.engines[0];build=engine.build(engine.preview()['plan_id'],lambda:False)
        next(build);self.assertTrue(engine.search_text('rain')['items']);build.close()

    def worker_for_test(self):
        from worker import Worker
        self.worker=Worker();self.worker.models=self.models
        self.worker.engines={'wiki':self.engines[0],'blocks':self.engines[1]}
        return self.worker

    def test_worker_routes_jobs_and_pause_to_their_source_only(self):
        worker=self.worker_for_test();token=threading.Event()
        jobs={}
        for source in ('wiki','blocks'):
            plan=worker.execute('preview',{'source':source},token)
            jobs[source]=worker.execute('start',{'source':source,'plan_id':plan['plan_id']},token)['job_id']
        worker.execute('pause',{'source':'wiki','job_id':jobs['wiki']},token)
        with patch('worker.emit'):
            worker._step(jobs['wiki']);worker._step(jobs['blocks'])
        self.assertEqual(self.engines[0].status()['indexed'],0)
        self.assertGreater(self.engines[1].status()['indexed'],0)
        with self.assertRaisesRegex(ValueError,'invalid_source'):
            worker.execute('pause',{'source':'wiki','job_id':jobs['blocks']},token)
        worker.execute('clear',{'source':'wiki'},token)
        self.assertIn(jobs['blocks'],worker.jobs)
        self.assertNotIn(jobs['wiki'],worker.jobs)

    def test_resume_after_saved_block_edit_restarts_with_fresh_scope(self):
        worker=self.worker_for_test();token=threading.Event();source='blocks'
        plan=worker.execute('preview',{'source':source},token)
        job=worker.execute('start',{'source':source,'plan_id':plan['plan_id']},token)['job_id']
        worker.execute('pause',{'source':source,'job_id':job},token)
        self.write_blocks([{'id':'fresh','title':'Fresh','positive':'umbrella','negative':'','tags':[]}])
        worker.execute('resume',{'source':source,'job_id':job},token)
        with patch('worker.emit'):
            while job in worker.jobs: worker._step(job)
        self.assertEqual(self.engines[1].status()['indexed'],1)
        self.assertEqual(self.engines[1].search_text('rain')['items'][0]['id'],'fresh')


if __name__=='__main__': unittest.main()
