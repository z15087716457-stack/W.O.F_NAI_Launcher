"""Profile recall, category scopes, live validation and incremental supplements."""
import hashlib
import json
import sqlite3
import unittest
from unittest.mock import patch

from test_rag import Sources
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

    def test_catalog_profile_reads_fields_without_building_an_old_tag_representation(self):
        self.profile(self.semantic,'tag_0','草地','植物覆盖的地面')
        row=self.source_impl.rows(names=['tag_0'])[0]
        self.assertEqual(row['core_zh'],'草地')
        self.assertEqual(row['summary_zh'],'植物覆盖的地面')
        self.assertEqual(row['aliases'],['known_alias'])
        from engine import Sources as CatalogSources
        raw=CatalogSources(self.source,semantics=self.semantic).rows(names=['tag_0'])[0]
        self.assertNotIn('text',raw)
        self.assertNotIn('digest',raw)

    def test_overlay_priority_missing_fields_and_stale_summary(self):
        self.profile(self.semantic,'tag_0','草地','原始释义')
        self.profile(self.overlay,'tag_0','草坪','补充释义',1)
        row=self.source_impl.rows(names=['tag_0'])[0]
        self.assertEqual(row['core_zh'],'草坪');self.assertEqual(row['summary_zh'],'补充释义')
        db=sqlite3.connect(self.overlay);db.execute("UPDATE tag_semantics SET wiki_hash='stale'");db.commit();db.close()
        self.assertEqual(self.source_impl.rows(names=['tag_0'])[0]['summary_zh'],'原始释义')

    def test_batch_profiles_keep_alias_limits_full_wiki_hash_and_constant_queries(self):
        wiki=self.root/'wiki.db'
        body='完整的释义。'*100
        db=sqlite3.connect(wiki);db.execute('CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT)')
        db.executemany('INSERT INTO wiki_pages VALUES(?,?)',[(f'tag_{i}',body) for i in range(60)])
        db.commit();db.close()
        self.source_impl=Sources(self.source,wiki=wiki,semantics=self.semantic,supplements=self.overlay)
        for path in (self.semantic,self.overlay):
            db=sqlite3.connect(path)
            db.executemany('INSERT INTO tag_semantics VALUES(?,?,?,?,?)',
                [(f'tag_{i}','基础' if path==self.semantic else '补充','[]','原释义' if path==self.semantic else '新释义','stale') for i in range(60)])
            if path==self.overlay:
                db.execute('ALTER TABLE tag_semantics ADD COLUMN summary_hash TEXT')
                db.execute('UPDATE tag_semantics SET summary_hash=?',(hashlib.sha256(body.encode()).hexdigest(),))
                db.execute("UPDATE tag_semantics SET summary_hash='stale' WHERE tag='tag_1'")
            db.commit();db.close()
        db=sqlite3.connect(self.source)
        db.executemany('INSERT INTO aliases VALUES(1,?)',[(f'alias_{i:02d}',) for i in range(30)])
        db.commit();db.close()
        statements=[];connect=self.source_impl.connect
        def traced():
            db,union=connect();db.set_trace_callback(statements.append);return db,union
        names=[f'tag_{i}' for i in range(60)]+['missing']
        with patch.object(self.source_impl,'connect',side_effect=traced):
            rows=self.source_impl.rows(names=names,limit=80)
        self.assertEqual([row['name'] for row in rows],names[:-1])
        self.assertEqual(rows[0]['aliases'],[f'alias_{i:02d}' for i in range(24)])
        self.assertEqual(rows[0]['summary_zh'],'新释义')
        self.assertEqual(rows[1]['summary_zh'],'原释义')
        self.assertIn(body[:500],rows[0]['text']);self.assertNotIn(body[:501],rows[0]['text'])
        self.assertEqual(len(statements),7)
        self.assertEqual(sum('table_info' in sql for sql in statements),1)
        self.assertEqual(rows,[self.source_impl.rows(names=[name])[0] for name in names[:-1]])

    def test_mixed_name_collations_use_the_catalog_index_without_broadening_matches(self):
        catalog=self.root/'case-catalog.db';runtime=self.root/'runtime.db'
        db=sqlite3.connect(catalog)
        db.executescript('CREATE TABLE tags(id INTEGER PRIMARY KEY,name TEXT COLLATE NOCASE UNIQUE,category INTEGER,post_count INTEGER); CREATE TABLE aliases(tag_id INTEGER,alias TEXT)')
        db.executemany('INSERT INTO tags VALUES(?,?,0,?)',[(i+1,f'tag_{i}',2000-i) for i in range(2000)])
        db.commit();db.close()
        db=sqlite3.connect(runtime)
        db.executescript("CREATE TABLE danbooru_tags(tag TEXT PRIMARY KEY,category INTEGER,post_count INTEGER); INSERT INTO danbooru_tags VALUES('tag_0',0,9000),('tag_2',0,8000)")
        db.commit();db.close()
        source=Sources(catalog,runtime);connect=source.connect;statements=[]
        def traced():
            db,union=connect();db.set_trace_callback(statements.append);return db,union
        with patch.object(source,'connect',side_effect=traced):
            rows=source.rows(names=['tag_0','TAG_1','tag_2','tag_3'])
        self.assertEqual([row['name'] for row in rows],['tag_0','tag_2','tag_3'])
        self.assertEqual([row['post_count'] for row in rows],[9000,8000,1997])
        sql=next(sql for sql in statements if sql.startswith('SELECT name, category, post_count'))
        db,_=connect()
        try:plan=[row[3] for row in db.execute('EXPLAIN QUERY PLAN '+sql)]
        finally:db.close()
        self.assertTrue(any('SEARCH t USING INDEX' in row for row in plan),plan)
        self.assertFalse(any('SCAN t' in row for row in plan),plan)
        self.assertEqual(Sources(catalog).rows(names=['TAG_1'])[0]['name'],'tag_1')

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





    def test_clear_removes_incremental_metadata_and_next_build_restores_every_tag(self):
        self.build();self.engine.clear();self.build();self.assertEqual(len(self.engine.ann),70)


if __name__=='__main__':unittest.main()
