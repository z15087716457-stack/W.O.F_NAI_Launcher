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
