"""Same-vector comparisons against the pinned reference methods, without models.

Set DANBOORU_REFERENCE to the downloaded reference core/engine.py. The upstream
implementation is read for this check, never bundled into production modules.
"""
import ast
import hashlib
import os
from pathlib import Path
import re
import runpy
from types import SimpleNamespace
import unittest

import jieba
import numpy as np
import torch

import test_tag_search as fixtures
from tag_query import STOP_WORDS, intent_weights
from tag_search import VIEWS, LAYERS, SearchOptions, view_texts

REFERENCE = os.environ.get('DANBOORU_REFERENCE')


def reference_type(path):
    raw = Path(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest()=='35c727c2f85390c62fa7ece34dc4357b8958f459f2e9b0a60450734c785458c4'
    parsed = ast.parse(raw)
    constants = []
    for node in parsed.body:
        target = node.target if isinstance(node,ast.AnnAssign) else node.targets[0] if isinstance(node,ast.Assign) else None
        if isinstance(target,ast.Name) and target.id in ('STOP_WORDS','CAT_MAP','_ATOMIC_CJK_MAX_LEN','_LAYER_SPEC','_ALL_LAYER_NAMES'):
            constants.append(node)
    cls = next(node for node in parsed.body if isinstance(node,ast.ClassDef) and node.name=='DanbooruTagger')
    required = {'_smart_split','_tokenize_en_chunk','_resolve_tag_variant','_merge_compound_english',
                '_detect_intent','_setup_jieba_from_memory','_search_tag_results',
                '_canonicalize_search_aliases','_apply_group_expand'}
    methods = [node for node in cls.body if isinstance(node,ast.FunctionDef) and node.name in required]
    types = runpy.run_path(str(Path(path).with_name('models.py')))
    namespace = {'re':re,'torch':torch,'np':np,'jieba':jieba.Tokenizer(),**types}
    exec(compile(ast.Module(body=[*constants,*methods],type_ignores=[]),'pinned-reference-methods','exec'),namespace)
    return type('Reference',(),{'_EN_MAX_COMPOUND':4,**{name:namespace[name] for name in required}}),namespace


class Series(list):
    def dropna(self): return self
    def astype(self, _): return self


@unittest.skipUnless(REFERENCE,'Requires DANBOORU_REFERENCE for upstream differential checks')
class DanbooruParityTests(unittest.TestCase):
    setUp = fixtures.TagSearchTests.setUp
    tearDown = fixtures.TagSearchTests.tearDown
    build = fixtures.TagSearchTests.build

    def oracle(self):
        cls,namespace = reference_type(REFERENCE)
        reference = cls()
        self.sources.signature()
        profiles = list(self.sources.records.values())
        for attribute,key in [('name','name'),('cn_name','cn_name'),('category','category'),('nsfw','nsfw'),('wiki','wiki'),('post_count','post_count')]:
            values = [str(row[key]) if key in ('category','nsfw') else row[key] for row in profiles]
            setattr(reference,'_arr_'+attribute,np.array(values))
        reference._arr_pop_score = np.log1p(reference._arr_post_count)/(max(np.log1p(reference._arr_post_count)) or 1.)
        reference._name_to_idx = {row['name']:index for index,row in enumerate(profiles)}
        reference._tag_names_set = set(reference._name_to_idx)
        reference.df = {'cn_name':Series(reference._arr_cn_name)}
        reference._setup_jieba_from_memory()
        for view,attribute in [('name','emb_en'),('synonyms','emb_cn'),('meaning','emb_wiki'),('core','emb_cn_core')]:
            setattr(reference,attribute,torch.from_numpy(self.models.embed([view_texts(row)[view] for row in profiles])))
        reference._encode_queries = lambda queries:(torch.from_numpy(self.models.embed(queries,query=True)),[False]*len(queries))
        reference._tag_aliases = {name:SimpleNamespace(consequent_name=target) for name,target in self.sources.aliases.items()}
        reference._tag_to_groups = self.sources.groups
        return reference,namespace

    def compare(self,query,options=SearchOptions(),limit=8):
        reference,_ = self.oracle()
        translated = {value:key for key,value in LAYERS.items()}
        request = SimpleNamespace(query=query,top_k=options.top_k,limit=limit,
                                  popularity_weight=options.popularity_weight,use_segmentation=options.use_segmentation,
                                  target_layers=[translated[view] for view in options.target_layers],
                                  target_categories=list(options.target_categories),group_mode=options.group_mode,
                                  max_per_group=options.max_per_group)
        expected,keywords,segments,_ = reference._search_tag_results(request)
        actual = self.engine.search(query,limit=limit,options=options)
        self.assertEqual(actual['keywords'],keywords)
        self.assertEqual(actual['segments'],segments)
        projection = lambda item:(item['name'],item['score'],item['semantic_score'],item['source'],item['origins'][0])
        self.assertEqual([projection(row) for row in actual['items']],
                         [(row.tag,row.final_score,row.semantic_score,row.source,LAYERS[row.layer]) for row in expected])

    def test_query_processing_and_intent_match_reference(self):
        reference,namespace = self.oracle()
        self.assertEqual(STOP_WORDS,namespace['STOP_WORDS'])
        for query in ['独立袖子 蓝色眼睛','a girl with cat ears','cats with blue eyes',
                      'beam rifle scope','[cat-ears] 3d 123','穿着水手服的女孩在阳光下奔跑',
                      '红色眼睛。长发；微笑','red hair, blue eyes','刻晴','cat_ears','中英文 mixed cat ears',
                      'water ' * 25]:
            with self.subTest(query=query):
                raw,segments = reference._smart_split(query)
                keywords = [word.strip() for word in raw if word.strip() and word.strip() not in namespace['STOP_WORDS']]
                extra = [part for part in segments if part!=query and part not in set(keywords)]
                self.assertEqual(self.sources.query(query,True),([query,*extra,*keywords],keywords,extra))
                self.assertEqual(intent_weights(query),tuple(reference._detect_intent(query)[layer] for layer in LAYERS))

    def test_same_vectors_default_queries_match_reference(self):
        self.build()
        for query in ['cat ears','cats with blue eyes','独立袖子 蓝色眼睛','在阳光下奔跑','beam rifle scope','测试10']:
            with self.subTest(query=query): self.compare(query)

    def test_options_groups_and_final_limits_match_reference(self):
        self.build()
        self.sources.groups = {record['name']:{'even' if index%2==0 else 'odd'} for index,record in enumerate(self.records)}
        for options in [SearchOptions(top_k=40),SearchOptions(top_k=20,use_segmentation=False),
                        SearchOptions(top_k=20,popularity_weight=0),SearchOptions(top_k=20,popularity_weight=1),
                        SearchOptions(top_k=20,target_layers=('core','name')),
                        SearchOptions(top_k=20,target_categories=('Artist','Meta','Other')),
                        SearchOptions(top_k=20,group_mode='diverse',max_per_group=1),
                        SearchOptions(top_k=20,group_mode='expand')]:
            with self.subTest(options=options): self.compare('cat ears 蓝色眼睛',options,limit=2)

    def test_official_alias_merge_and_absent_target_match_reference(self):
        self.build()
        self.sources.aliases = {'cat_ears':'blue_eyes','tag_8':'not_in_corpus'}
        self.compare('cat ears 测试8',SearchOptions(top_k=30),limit=2)

    def test_thresholds_coherence_and_guarantees_with_varied_identical_vectors(self):
        def embed(texts, query=False):
            vectors = np.zeros((len(texts),768),dtype=np.float32)
            for index,text in enumerate(texts):
                seed = int.from_bytes(hashlib.sha256(text.encode()).digest()[:8],'little')
                random = np.random.default_rng(seed)
                vectors[index,:6] = random.normal(size=6)
                vectors[index,0] += 1.2
                vectors[index] /= np.linalg.norm(vectors[index])
            return vectors
        self.models.embed = embed
        self.build()
        for query in ['cat ears 蓝色眼睛','测试9 独立袖子','beam rifle and blue eyes']:
            for limit in (1,8):
                with self.subTest(query=query,limit=limit):
                    self.compare(query,SearchOptions(top_k=50),limit=limit)


if __name__=='__main__': unittest.main()
