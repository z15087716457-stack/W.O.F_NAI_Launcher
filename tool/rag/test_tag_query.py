"""Explicit tag search is independent of prompt context, using local fixtures."""
import unittest
from unittest.mock import patch

import test_rag as fixtures


class QueryModels(fixtures.FakeModels):
    def __init__(self):
        super().__init__();self.ranked=[]
    def rerank(self,query,documents,negative=False,purpose='tags'):
        self.ranked.append((query,negative,purpose))
        return super().rerank(query,documents,negative)


class TagQueryTests(unittest.TestCase):
    tearDown=fixtures.IndexTests.tearDown
    build=fixtures.IndexTests.build
    def setUp(self):
        fixtures.IndexTests.setUp(self)
        self.models=self.engine.models=QueryModels()
        self.build()

    def test_natural_language_query_works_without_a_prompt(self):
        result=self.engine.search('',0,'around',[],[],False,keyword='在阳光下奔跑')
        self.assertTrue(result['items'])
        self.assertEqual(self.models.queries,['在阳光下奔跑'])
        self.assertEqual(self.models.ranked,[])

    def test_existing_prompt_cursor_and_context_mode_cannot_change_manual_query(self):
        for text,cursor,mode in [('rain, night, ',0,'before'),('blue hair, city, ',16,'around')]:
            result=self.engine.search(text,cursor,mode,[],[],False,keyword='在阳光下奔跑')
            self.assertTrue(result['items'])
        self.assertEqual(self.models.queries,['在阳光下奔跑']*2)
        self.assertEqual(self.models.ranked,[])

    def test_known_entity_query_keeps_category_aware_rerank(self):
        import sqlite3
        db=sqlite3.connect(self.source)
        db.execute("UPDATE tags SET category=4 WHERE name='tag_0'")
        db.commit();db.close();self.build()
        self.engine.search('',0,'around',[],[],False,keyword='tag_0')
        self.assertEqual(self.models.ranked,[('tag 0',False,'tag_search')])

    def test_only_manual_visual_recall_may_stop_at_a_partial_budget(self):
        with patch.object(self.engine.ann,'search',wraps=self.engine.ann.search) as search:
            self.engine.search('',0,'around',[],[],False,keyword='sunlit running')
            self.assertEqual(search.call_args_list[0].kwargs['min_count'],800)
            self.assertNotIn('min_count',search.call_args_list[1].kwargs)
            search.reset_mock()
            self.engine.search('rain, ',6,'before',[],[],False)
            self.assertTrue(all(call.kwargs.get('min_count') is None for call in search.call_args_list))

    def test_manual_query_does_not_even_tokenize_an_unrelated_prompt(self):
        original='unrelated_prompt_'*200
        count=self.models.count
        def checked(value):
            self.assertNotIn('unrelated',value)
            return count(value)
        with patch.object(self.models,'count',side_effect=checked):
            self.assertTrue(self.engine.search(original,0,'around',[],[],False,keyword='sunlit running')['items'])

    def test_empty_search_still_uses_prompt_context_and_negative_intent(self):
        result=self.engine.search('rain, night, ',12,'before',[],[],True,keyword='  ')
        self.assertTrue(result['items'])
        self.assertEqual(self.models.queries,['rain, night'])
        self.assertEqual(self.models.ranked,[('rain, night',True,'tags')])

    def test_worker_passes_the_budget_and_defaults_to_before_without_rebuilding(self):
        import threading
        from worker import Worker
        worker=Worker();worker.models=self.models;worker.engines={'tags':self.engine}
        before=', '.join(f'word{i}' for i in range(700))
        snapshot=self.engine.db.execute('SELECT id,vector FROM documents ORDER BY id').fetchall()
        for budget in (32,121,512):
            result=worker.execute('search',{'text':before+', future','cursor':len(before),'budget':budget},threading.Event())
            self.assertEqual(result['context_tokens'],budget)
            self.assertEqual(self.models.queries[-1],', '.join(f'word{i}' for i in range(700-budget,700)))
        self.assertEqual(self.engine.db.execute('SELECT id,vector FROM documents ORDER BY id').fetchall(),snapshot)
        with self.assertRaisesRegex(ValueError,'invalid_context_budget') as error:
            worker.execute('search',{'text':'rain','cursor':4,'budget':513},threading.Event())
        self.assertEqual(worker.error_code(error.exception),'invalid_context_budget')

    def test_manual_query_is_independent_of_the_context_budget(self):
        for budget in (32,512):
            result=self.engine.search('unrelated, ',11,'before',[],[],False,keyword='sunlit running',budget=budget)
            self.assertTrue(result['items'])
        self.assertEqual(self.models.queries,['sunlit running']*2)

    def test_manual_search_keeps_existing_alias_dedup_and_never_writes_query(self):
        snapshot=self.engine.db.execute('SELECT id,name,vector,digest FROM documents ORDER BY id').fetchall()
        result=self.engine.search('unrelated, ',11,'around',['known_alias'],[],True,keyword='在阳光下奔跑')
        self.assertNotIn('tag_0',[row['name'] for row in result['items']])
        self.assertEqual(self.engine.db.execute('SELECT id,name,vector,digest FROM documents ORDER BY id').fetchall(),snapshot)

    def test_missing_query_and_context_do_not_call_models(self):
        self.assertEqual(self.engine.search('',0,'around',[],[],False,keyword='')['items'],[])
        self.assertEqual(self.models.queries,[])
        self.assertEqual(self.models.ranked,[])

    def test_empty_normalized_manual_query_does_not_fall_back_to_prompt(self):
        result=self.engine.search('rain, night, ',12,'before',[],[],False,keyword='[::]')
        self.assertEqual(result['items'],[])
        self.assertEqual(self.models.queries,[])

    def test_manual_query_keeps_input_bounds_and_rejects_invalid_mode(self):
        query='word '*400
        self.engine.search('',0,'around',[],[],False,keyword=query)
        self.assertLessEqual(len(self.models.queries[-1]),1024)
        with self.assertRaisesRegex(ValueError,'invalid_context_mode'):
            self.engine.search('',0,'all',[],[],False,keyword='running')


if __name__=='__main__':unittest.main()
