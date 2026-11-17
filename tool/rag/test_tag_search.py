import csv
import json
import hashlib
import sqlite3
from contextlib import closing
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tag_search import TagEngine, TagSources, SearchOptions, VIEWS, view_texts
from test_rag import FakeModels, fixture


def fixture_corpus(path, total=24):
    rows = [dict(name=f'tag_{i}', cn_name=f'测试{i},候选{i}', wiki=f'含义描述{i}',
                 post_count=100000-i*1000, category=0, nsfw=i % 2) for i in range(total)]
    for index, name in enumerate(['cat_ears', 'blue_eyes', 'beam_rifle'][:total]):
        rows[index]['name'] = name
    if total > 4:
        rows[3].update(name='character', category=4, cn_name='独立袖子,分离袖子')
        rows[4].update(name='copyright', category=3, cn_name='蓝色眼睛,蓝眼')
    if total > 7:
        rows[5]['category'] = 1
        rows[6]['category'] = 5
        rows[7]['category'] = 7
    write_corpus(path, rows)
    return rows


def write_corpus(path, rows):
    with Path(path).open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=['name','cn_name','wiki','post_count','category','nsfw'])
        writer.writeheader()
        writer.writerows(rows)


class TagSearchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.corpus = self.root/'corpus.csv'
        self.records = fixture_corpus(self.corpus)
        self.sources = TagSources(self.corpus)
        self.models = FakeModels()
        self.engine = TagEngine(self.root/'index', self.models, self.sources)

    def tearDown(self):
        self.engine.close()
        self.temp.cleanup()

    def build(self):
        return list(self.engine.build(self.engine.preview()['plan_id'], lambda: False))

    def search(self, query='cat ears', **kwargs):
        return self.engine.search(query, **kwargs)

    def test_corpus_inputs_match_reference_fields_and_include_empty_views(self):
        self.records[0].update(cn_name='猫耳，猫咪耳朵|猫耳朵、兽耳', wiki='')
        write_corpus(self.corpus, self.records)
        self.build()
        self.assertEqual(self.sources.count(), 4*len(self.records))
        profile = self.sources.profiles(['cat_ears'])[0]
        self.assertEqual(view_texts(profile),dict(name='cat ears', synonyms='猫耳,猫咪耳朵,猫耳朵,兽耳', core='猫耳', meaning=''))
        self.assertEqual(self.engine.status()['indexed'], 4*len(self.records))

    def test_bundled_corpus_matches_its_pinned_source_and_count(self):
        source = Path(__file__).with_name('danbooru_tags.csv')
        metadata = json.loads(source.with_name('danbooru_tags.source.json').read_text('utf-8'))
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),metadata['sha256'])
        bundled = TagSources(source)
        self.assertEqual(bundled.count(),metadata['tagsAfterDuplicateRemoval']*4)
        self.assertEqual(len(bundled.records),48304)

    def test_unbuilt_index_does_not_inject_lexical_matches_or_infer(self):
        result = self.engine.search('cat ears')
        self.assertEqual(result['items'], [])
        self.assertEqual(result['fallback'], 'index_empty')
        self.assertEqual(self.models.queries, [])

    def test_retrieval_uses_exact_matrices_and_honors_category_defaults(self):
        self.build()
        with patch.object(self.engine.ann, 'search', side_effect=AssertionError('ANN is not exact')):
            result = self.search()
        self.assertTrue(result['items'])
        self.assertTrue(all(row['category'] in (0,3,4) for row in result['items']))
        self.assertNotIn('lexical', str([row['origins'] for row in result['items']]))

    def test_matrix_cache_reuses_unchanged_vectors_and_invalidates_on_build(self):
        self.build(); self.search()
        matrix = self.engine._matrices['name'][2]
        self.search()
        self.assertIs(self.engine._matrices['name'][2], matrix)
        self.records[0]['wiki'] = '修改后的释义'
        write_corpus(self.corpus, self.records)
        self.models.embedded.clear(); self.build(); self.search()
        self.assertEqual(self.models.embedded, ['修改后的释义'])
        self.assertIsNot(self.engine._matrices['name'][2], matrix)

    def test_other_source_changes_do_not_reload_tag_matrices(self):
        self.build(); self.search()
        matrix = self.engine._matrices['name'][2]
        db,ann = self.engine.pool.collection('blocks',self.root/'blocks')
        try:
            vector = self.models.embed(['saved block'])[0]
            with db:
                db.execute('INSERT INTO documents(name,vector) VALUES(?,?)',('saved',vector.tobytes()))
            key = db.execute("SELECT id FROM documents WHERE name='saved'").fetchone()[0]
            ann.add(key,vector)
            self.search()
            self.assertIs(self.engine._matrices['name'][2],matrix)
        finally:
            db.close()

    def test_partial_build_updates_the_matrix_cache_after_resume(self):
        generator = self.engine.build(self.engine.preview()['plan_id'],lambda:False)
        next(generator); self.search()
        first = self.engine._matrices['name'][2]
        list(generator); self.search()
        self.assertIsNot(self.engine._matrices['name'][2],first)
        self.assertEqual(len(self.engine._matrices['name'][0]),len(self.records))

    def test_changed_vectors_are_rejected_until_rebuilt(self):
        self.build(); self.search()
        self.records[0]['wiki'] = '已经更新的释义'
        write_corpus(self.corpus, self.records)
        self.search()
        self.assertNotIn('cat_ears', self.engine._matrices['meaning'][1])
        self.assertIn('cat_ears', self.engine._matrices['name'][1])

    def test_deleted_tag_is_removed_without_reembedding_survivors(self):
        self.build(); self.models.embedded.clear()
        self.records.pop(0); write_corpus(self.corpus, self.records)
        self.build()
        self.assertEqual(self.models.embedded, [])
        self.assertFalse(any(json.loads(name)[0]=='cat_ears' for name, in self.engine.db.execute('SELECT name FROM documents')))

    def test_cancellation_and_empty_input_do_not_embed(self):
        self.build()
        self.assertEqual(self.search('   ')['items'], [])
        with self.assertRaisesRegex(ValueError, 'cancelled'):
            self.search(cancelled=lambda: True)
        self.assertEqual(self.models.queries, [])

    def test_optional_aliases_do_not_use_catalog_synonyms(self):
        self.build()
        self.assertEqual(self.sources.aliases, {})
        self.sources.aliases = {'cat_ears': 'blue_eyes'}
        result = self.engine.search('cat ears',existing=['cat_ears'])
        self.assertNotIn('blue_eyes', [row['name'] for row in result['items']])

    def test_options_are_validated_at_protocol_boundary(self):
        self.assertEqual(SearchOptions.parse({'target_layers':['英文'],'top_k':10}).target_layers, ('name',))
        self.assertEqual(SearchOptions.parse({'top_k':80}).top_k,80)
        for params in [{'top_k':0},{'top_k':True},{'popularity_weight':float('nan')},
                       {'top_k':81},{'target_layers':['unknown']},{'target_categories':['unknown']},{'group_mode':'bad'}]:
            with self.assertRaisesRegex(ValueError, 'invalid_source'):
                SearchOptions.parse(params)

    def private_source(self):
        catalog = self.root/'catalog.db'
        fixture(catalog, 24)
        with closing(sqlite3.connect(catalog)) as db, db:
            db.execute("UPDATE tags SET name='cat_ears' WHERE id=1")
        overlay = self.root/'personal.db'
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute('CREATE TABLE tag_semantics(tag TEXT PRIMARY KEY,core_zh TEXT,synonyms_zh TEXT,summary_zh TEXT,wiki_hash TEXT)')
            db.execute('INSERT INTO tag_semantics VALUES(?,?,?,?,?)',('cat_ears','私人猫耳','["自定义猫耳"]','私人释义',hashlib.sha256(b'').hexdigest()))
        self.sources = self.engine.sources = TagSources(self.corpus,catalog=catalog,supplements=overlay)
        return overlay

    def test_personal_profiles_incrementally_encode_and_deletion_restores_reference(self):
        overlay = self.private_source()
        self.build(); self.models.embedded.clear()
        self.assertEqual(self.sources.profiles(['cat_ears'])[0]['core_zh'],'私人猫耳')
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute("UPDATE tag_semantics SET summary_zh='新的私人释义'")
        self.build()
        self.assertEqual(self.models.embedded,['新的私人释义'])
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute('DELETE FROM tag_semantics')
        self.build()
        profile = self.sources.profiles(['cat_ears'])[0]
        self.assertEqual(profile['cn_name'],self.records[0]['cn_name'])
        self.assertEqual(profile['wiki'],self.records[0]['wiki'])

    def test_locked_personal_profile_search_falls_back_without_changing_build_source(self):
        overlay = self.private_source()
        self.build()
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute("UPDATE tag_semantics SET core_zh='已保存猫耳'")
        with closing(sqlite3.connect(overlay)) as db:
            db.execute('BEGIN EXCLUSIVE')
            result = self.search()
            self.assertEqual(result['degraded'],['supplements_unavailable'])
            self.assertFalse(self.sources.degraded)
            db.rollback()
        self.assertEqual(self.search()['degraded'],[])
        self.assertEqual(self.sources.profiles(['cat_ears'])[0]['core_zh'],'已保存猫耳')

    def test_existing_base_profiles_extend_reference_without_rewriting_its_rows(self):
        catalog = self.root/'catalog.db';fixture(catalog,24)
        with closing(sqlite3.connect(catalog)) as db, db:
            db.execute("UPDATE tags SET name='cat_ears' WHERE id=1")
            db.execute("UPDATE tags SET category=7 WHERE name='tag_1'")
        base = self.root/'base.db'
        with closing(sqlite3.connect(base)) as db, db:
            db.execute('CREATE TABLE tag_semantics(tag TEXT PRIMARY KEY,core_zh TEXT,synonyms_zh TEXT,summary_zh TEXT)')
            db.executemany('INSERT INTO tag_semantics VALUES(?,?,?,?)',[
                ('cat_ears','旧版猫耳','[]','旧版释义'),('tag_1','额外标签','[]','额外释义')])
        source = TagSources(self.corpus,catalog=catalog,semantics=base)
        self.assertEqual(source.count(),len(self.records)*4+4+3)
        self.assertEqual(source.profiles(['cat_ears'])[0]['cn_name'],self.records[0]['cn_name'])
        self.assertEqual(source.profiles(['tag_1'])[0]['wiki'],'额外释义')
        self.assertEqual(source.profiles(['tag_1'])[0]['category'],7)
        self.assertEqual(source.profiles(['tag_1'])[0]['_category'],'General')

    def test_untranslated_catalog_tags_use_only_available_views(self):
        catalog = self.root/'catalog.db'; fixture(catalog,3)
        wiki = self.root/'wiki.db'
        with closing(sqlite3.connect(wiki)) as db, db:
            db.execute('CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT)')
            db.execute("INSERT INTO wiki_pages VALUES('tag_1','English wiki description')")
        self.sources = self.engine.sources = TagSources(self.corpus,catalog=catalog,wiki=wiki)
        self.assertEqual(self.sources.count(),len(self.records)*4+3+1)
        rows = self.sources.rows(names=[json.dumps(['tag_0',view]) for view in VIEWS],limit=4)
        self.assertEqual([row['text'] for row in rows],['tag 0'])
        rows = self.sources.rows(names=[json.dumps(['tag_1',view]) for view in VIEWS],limit=4)
        self.assertEqual([row['text'] for row in rows],['tag 1','English wiki description'])
        self.build()
        self.assertTrue(self.engine.status()['complete'])
        self.assertIn('tag_0',self.sources.records)

    def test_personal_revision_updates_only_changed_tag_and_removes_obsolete_views(self):
        overlay = self.private_source()
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute('CREATE TABLE semantic_state(revision INTEGER)')
            db.execute('INSERT INTO semantic_state VALUES(1)')
            db.execute('CREATE TABLE semantic_changes(tag TEXT PRIMARY KEY,revision INTEGER)')
            db.execute("INSERT INTO tag_semantics VALUES('tag_1','新增中文','[]','','')")
        self.build(); self.models.embedded.clear()
        with closing(sqlite3.connect(overlay)) as db, db:
            db.execute("DELETE FROM tag_semantics WHERE tag='tag_1'")
            db.execute('UPDATE semantic_state SET revision=2')
            db.execute("INSERT INTO semantic_changes VALUES('tag_1',2)")
        plan = self.engine.preview()
        self.assertEqual(len(self.engine.plan['incremental_names']),4)
        with patch.object(self.sources,'ordered_names',side_effect=AssertionError('full catalog scan')):
            list(self.engine.build(plan['plan_id'],lambda:False))
        self.assertEqual(self.models.embedded,[])
        remaining = [json.loads(name)[1] for name, in self.engine.db.execute('SELECT name FROM documents') if json.loads(name)[0]=='tag_1']
        self.assertEqual(remaining,['name'])
        self.assertTrue(self.engine.status()['complete'])

    def test_noop_build_preserves_loaded_search_matrices(self):
        self.build(); self.search()
        matrices = self.engine._matrices
        self.build(); self.search()
        self.assertIs(self.engine._matrices,matrices)


if __name__=='__main__': unittest.main()
