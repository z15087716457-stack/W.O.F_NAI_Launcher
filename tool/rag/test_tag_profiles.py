"""Profile recall, category scopes, live validation and incremental supplements."""
import hashlib
import json
import sqlite3
import unittest
from unittest.mock import patch

from engine import Sources
from context import clean_tag
import test_rag as fixtures


class TagProfileTests(unittest.TestCase):
    tearDown = fixtures.IndexTests.tearDown
    build = fixtures.IndexTests.build
    def setUp(self):
        fixtures.IndexTests.setUp(self)
        self.semantic = self.root/'semantic.db'
        self.overlay = self.root/'supplement.db'
        for path in (self.semantic,self.overlay):
            db=sqlite3.connect(path)
            db.executescript('''CREATE TABLE tag_semantics(tag TEXT PRIMARY KEY,core_zh TEXT,synonyms_zh TEXT,summary_zh TEXT,wiki_hash TEXT);
                CREATE TABLE semantic_state(revision INTEGER); INSERT INTO semantic_state VALUES(0);
                CREATE TABLE semantic_changes(tag TEXT PRIMARY KEY,revision INTEGER);''')
            db.close()
        self.source_impl=Sources(self.source,semantics=self.semantic,supplements=self.overlay)
        self.engine.sources=self.source_impl

    def profile(self,path,tag,core,summary='',revision=0):
        db=sqlite3.connect(path)
        db.execute('INSERT OR REPLACE INTO tag_semantics VALUES(?,?,?,?,?)',
            (tag,core,json.dumps([core]),summary,hashlib.sha256(b'').hexdigest()))
        if revision:
            db.execute('UPDATE semantic_state SET revision=?',(revision,))
            db.execute('INSERT OR REPLACE INTO semantic_changes VALUES(?,?)',(tag,revision))
        db.commit();db.close()

    def test_one_vector_per_live_tag_with_chinese_profile_and_live_category(self):
        self.profile(self.semantic,'tag_0','草地','植物覆盖的地面')
        self.build()
        self.assertEqual(len(self.engine.ann),70)
        text=self.engine.db.execute("SELECT text FROM documents WHERE name='tag_0'").fetchone()[0]
        for part in ('草地','植物覆盖的地面','general visual tag','known_alias'):self.assertIn(part,text)
        self.assertEqual(self.source_impl.exact_names('草地'),['tag_0'])
        self.assertEqual(self.source_impl.exact_names('known alias'),['tag_0'])

    def test_canonical_parentheses_and_english_phrases_survive_weight_parsing(self):
        self.assertEqual(clean_tag('character_(work)'), 'character (work)')
        self.assertEqual(clean_tag('(character)_(work)'), '(character) (work)')
        self.assertEqual(clean_tag('(white dress:1.2)'), 'white dress')
        self.assertEqual(clean_tag('1.2::white dress::'), 'white dress')
        db=sqlite3.connect(self.source);db.execute("UPDATE tags SET name='character_(work)',category=4 WHERE id=1");db.commit();db.close()
        self.assertEqual(self.source_impl.exact_names('character_(work)'), ['character_(work)'])

    def test_compound_concepts_use_actual_core_names_not_broad_expansions(self):
        self.profile(self.semantic,'tag_0','雨','下雨的天气')
        self.profile(self.semantic,'tag_1','夜晚','日落后的时间')
        db=sqlite3.connect(self.semantic);db.execute('UPDATE tag_semantics SET synonyms_zh=? WHERE tag=?',
            (json.dumps(['雨','下雨','天气']),'tag_0'));db.commit();db.close()
        self.assertEqual(self.source_impl.core_concepts('下雨的夜晚'),[['tag_0'],['tag_1']])
        self.assertEqual(self.source_impl.core_concepts('天气'),[])
        self.assertEqual(self.source_impl.core_concepts('没有下雨的夜晚'),[['tag_1']])
        self.build()
        result=self.engine.search('',0,'around',[],[],False,keyword='下雨的夜晚')
        self.assertEqual([r['name'] for r in result['items'][:2]],['tag_0','tag_1'])
        self.assertTrue(all('concept' in r['origins'] for r in result['items'][:2]))

    def test_nested_shorter_core_and_absent_live_names_are_not_pinned(self):
        self.profile(self.semantic,'tag_0','树下')
        self.profile(self.semantic,'tag_1','大树下')
        self.profile(self.semantic,'not_in_catalog','绿色')
        self.assertEqual(self.source_impl.core_concepts('绿色的大树下'),[['tag_1']])

    def test_old_bundle_core_cannot_override_a_corrected_supplement(self):
        self.profile(self.semantic,'tag_0','旧名称')
        self.profile(self.overlay,'tag_0','新名称',revision=1)
        self.assertEqual(self.source_impl.core_concepts('旧名称在这里'),[])
        self.assertEqual(self.source_impl.core_concepts('新名称在这里'),[['tag_0']])

    def test_overlay_priority_missing_fields_and_stale_summary(self):
        self.profile(self.semantic,'tag_0','草地','原始释义')
        self.profile(self.overlay,'tag_0','草坪','补充释义',1)
        row=self.source_impl.rows(names=['tag_0'])[0]
        self.assertEqual(row['core_zh'],'草坪');self.assertEqual(row['summary_zh'],'补充释义')
        db=sqlite3.connect(self.overlay);db.execute("UPDATE tag_semantics SET wiki_hash='stale'");db.commit();db.close()
        self.assertEqual(self.source_impl.rows(names=['tag_0'])[0]['summary_zh'],'原始释义')

    def test_semantic_change_only_visits_changed_live_tag_and_keeps_others(self):
        self.build();self.models.embedded.clear()
        original=dict(self.engine.db.execute('SELECT name,vector FROM documents'))
        self.profile(self.overlay,'tag_5','新增中文','可靠说明',1)
        self.profile(self.overlay,'not_in_catalog','未收录','不加入主库',2)
        with patch.object(self.source_impl,'rows',wraps=self.source_impl.rows) as rows, \
             patch.object(self.source_impl,'ordered_names',side_effect=AssertionError('full scan')):
            self.build()
        self.assertEqual(rows.call_count,1)
        self.assertEqual(rows.call_args.kwargs['names'],['tag_5'])
        self.assertEqual(len(self.models.embedded),1)
        self.assertEqual(len(self.engine.ann),70)
        self.assertTrue(self.engine.status()['complete'])
        for name,vector in self.engine.db.execute('SELECT name,vector FROM documents'):
            if name!='tag_5':self.assertEqual(vector,original[name])

    def test_supplement_attempt_metadata_does_not_invalidate_vectors(self):
        self.profile(self.overlay,'tag_5','标签',revision=1);self.build()
        signature=self.source_impl.signature()
        db=sqlite3.connect(self.overlay);db.execute("CREATE TABLE attempts(tag TEXT)");db.execute("INSERT INTO attempts VALUES('tag_5')");db.commit();db.close()
        self.assertEqual(signature,self.source_impl.signature())

    def test_catalog_change_falls_back_to_full_verification_and_deletes_stale(self):
        self.build()
        db=sqlite3.connect(self.source);db.execute('DELETE FROM tags WHERE id=2');db.commit();db.close()
        self.build();self.assertEqual(len(self.engine.ann),69)
        self.assertFalse(self.engine.db.execute("SELECT 1 FROM documents WHERE name='tag_1'").fetchone())

    def test_visual_category_scope_is_inside_recall_not_post_filtering(self):
        db=sqlite3.connect(self.source);db.execute('UPDATE tags SET category=1 WHERE id>4');db.execute('UPDATE tags SET category=7 WHERE id=4');db.commit();db.close()
        self.build()
        query=self.models.embed(['植物'],query=True)[0]
        keys=self.engine.ann.search(query,80,categories=(0,7)).keys
        self.assertEqual(len(keys),4)
        categories=[self.engine.db.execute('SELECT category FROM documents WHERE id=?',(k,)).fetchone()[0]for k in keys]
        self.assertEqual(set(categories),{0,7})

    def test_descriptive_query_keeps_a_reserved_entity_lane_without_exact_name(self):
        db=sqlite3.connect(self.source);db.execute('UPDATE tags SET category=4 WHERE id>35');db.commit();db.close()
        self.build()
        result=self.engine.search('scene',5,'around',[],[],False,limit=80)
        self.assertTrue(any(r['category']==4 for r in result['items']))
        self.assertTrue(any(r['category']==0 for r in result['items']))

    def test_rerank_has_category_and_can_return_more_than_32_results(self):
        self.build()
        with patch.object(self.models,'rerank',wraps=self.models.rerank) as rerank:
            result=self.engine.search('rain',4,'around',[],[],False,limit=80)
        self.assertEqual(len(result['items']),70)
        self.assertTrue(all('Category: general visual tag' in text for text in rerank.call_args.args[1]))
        self.assertTrue(all('origins' in row and 'score' in row for row in result['items']))

    def test_requested_80_results_are_not_truncated_to_32(self):
        db=sqlite3.connect(self.source)
        for i in range(70,110): db.execute('INSERT INTO tags VALUES(?,?,?,?)',(i+1,f'tag_{i}',0,110-i))
        db.commit();db.close();self.build()
        result=self.engine.search('rain',4,'around',[],[],False,limit=80)
        self.assertEqual(len(result['items']),80)

    def test_clear_removes_incremental_metadata_and_next_build_restores_every_tag(self):
        self.build();self.engine.clear();self.build();self.assertEqual(len(self.engine.ann),70)


if __name__=='__main__':unittest.main()
