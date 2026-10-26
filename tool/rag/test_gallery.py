import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import threading
import unittest
from PIL import Image, PngImagePlugin
from gallery import GalleryEngine, GallerySources, load_image
from test_rag import FakeModels


class GalleryModels(FakeModels):
    def __init__(self,root):
        super().__init__();self.embedding_path=str(root);self.images=0;self.reranked=[]
    def embed_images(self,images,text=''):
        import numpy as np
        self.images+=len(images)
        result=np.zeros((len(images),768),dtype=np.float32)
        for i,image in enumerate(images):
            result[i,:3]=image.resize((1,1)).getpixel((0,0))
            result[i]/=max(np.linalg.norm(result[i]),1)
        return result
    def rerank(self,query,documents,negative=False,purpose='tags'):
        self.reranked.extend(documents)
        assert all(isinstance(item,str) for item in documents)
        assert purpose=='retrieval'
        return [float('umbrella' in item) for item in documents]


class GalleryTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.library=self.root/'图库';self.library.mkdir()
        self.database=self.root/'gallery.sqlite';self.roots=self.root/'roots.json'
        self.roots.write_text(json.dumps({'version':1,'roots':[str(self.library)]}),encoding='utf-8')
        db=sqlite3.connect(self.database)
        db.executescript('''CREATE TABLE gallery_images(id INTEGER PRIMARY KEY,file_path TEXT,is_deleted INTEGER);
          CREATE TABLE gallery_metadata(image_id INTEGER PRIMARY KEY,prompt TEXT,positive_prompt_text TEXT,negative_prompt TEXT,
          model TEXT,sampler TEXT,steps INTEGER,cfg_scale REAL,seed INTEGER,width INTEGER,height INTEGER,
          software TEXT,source TEXT,raw_json TEXT,has_metadata INTEGER);''')
        for i,color in enumerate(('red','blue','green'),1):
            path=self.library/f'{i}.png';info=PngImagePlugin.PngInfo();info.add_text('private-preserve','untouched')
            Image.new('RGB',(32,24),color).save(path,pnginfo=info)
            db.execute('INSERT INTO gallery_images VALUES(?,?,0)',(i,str(path)))
            db.execute('INSERT INTO gallery_metadata VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
              (i,'umbrella' if i==1 else 'beach','umbrella' if i==1 else 'beach','rain','nai-diffusion-4' if i<3 else 'other',
               'k_euler',28,5.0,1,32,24,'NovelAI' if i<3 else 'Other','', 'private_raw_never_export',1))
        self.broken=self.library/'bad.png';self.broken.write_bytes(b'broken')
        db.execute('INSERT INTO gallery_images VALUES(4,?,0)',(str(self.broken),))
        outside=self.root/'outside.png';Image.new('RGB',(4,4),'red').save(outside)
        db.execute('INSERT INTO gallery_images VALUES(5,?,0)',(str(outside),))
        db.execute('INSERT INTO gallery_images VALUES(6,?,1)',(str(self.library/'deleted.png'),))
        db.commit();db.close()
        self.models=GalleryModels(self.root)
        self.engine=GalleryEngine(self.root/'index',self.models,self.database,self.roots)
    def tearDown(self):self.engine.close();self.temp.cleanup()
    def build(self):return list(self.engine.build(self.engine.preview()['plan_id'],lambda:False))
    def search(self,mode='mixed',paths=None,image=''):
        return self.engine.search('umbrella',paths,image,mode,20,lambda:False)['items']
    def test_preview_is_read_only_and_separates_counts(self):
        original=hashlib.sha256(self.database.read_bytes()).hexdigest()
        plan=self.engine.preview()
        self.assertEqual(plan['images'],4);self.assertEqual(plan['parameter_chunks'],2)
        self.assertEqual(self.models.images,0);self.assertEqual(self.models.embedded,[])
        self.assertEqual(hashlib.sha256(self.database.read_bytes()).hexdigest(),original)
    def test_build_skips_corrupt_images_and_never_modifies_originals(self):
        original={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in self.library.iterdir()}
        self.build();status=self.engine.status()
        self.assertEqual(status['visual_indexed'],3);self.assertEqual(status['skipped'],1)
        self.assertEqual(status['parameters_indexed'],2);self.assertTrue(status['complete'])
        self.assertEqual(original,{p:hashlib.sha256(p.read_bytes()).hexdigest() for p in self.library.iterdir()})
    def test_visual_search_does_not_call_text_reranker(self):
        self.build();hits=self.search('visual')
        self.assertEqual({item['id'] for item in hits},{'1','2','3'})
        self.assertEqual(self.models.reranked,[])
    def test_parameter_search_indexes_only_nai_and_never_raw_json(self):
        self.build();hits=self.search('parameters')
        self.assertEqual({item['id'] for item in hits},{'1','2'})
        self.assertTrue(self.models.reranked)
        self.assertFalse(any('private_raw_never_export' in text for text in self.models.reranked))
    def test_scope_is_enforced_before_visual_and_parameter_ranking(self):
        self.build();path=str(self.library/'2.png')
        hits=self.search(paths=[path]);self.assertEqual([item['id'] for item in hits],['2'])
        self.assertEqual(self.search(paths=[]),[])
    def test_deleted_or_changed_picture_does_not_return_stale_visual_vector(self):
        self.build();Image.new('RGB',(100,100),'yellow').save(self.library/'1.png')
        db=sqlite3.connect(self.database);db.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=2');db.commit();db.close()
        self.assertEqual([item['id'] for item in self.search('visual')],['3'])
    def test_image_query_excludes_itself_and_never_goes_to_qwen(self):
        self.build();hits=self.engine.search('',None,str(self.library/'1.png'),'mixed',20,lambda:False)['items']
        self.assertNotIn('1',[item['id'] for item in hits]);self.assertEqual(self.models.reranked,[])
    def test_combined_query_excludes_reference_from_parameter_results_too(self):
        self.build();hits=self.engine.search('umbrella',None,str(self.library/'1.png'),'mixed',20,lambda:False)['items']
        self.assertNotIn('1',[item['id'] for item in hits])
    def test_incremental_build_reuses_unchanged_image_vectors(self):
        self.build();count=self.models.images;self.models.embedded.clear();self.build()
        self.assertEqual(self.models.images,count);self.assertEqual(self.models.embedded,[])
    def test_removed_root_never_returns_old_images(self):
        self.build();self.roots.write_text(json.dumps({'version':1,'roots':[]}))
        self.assertEqual(self.search(),[])
    def test_partial_build_and_reopen_are_searchable(self):
        plan=self.engine.preview();generator=self.engine.build(plan['plan_id'],lambda:False);next(generator);generator.close()
        self.assertTrue(self.search('visual'));self.engine.close()
        self.engine=GalleryEngine(self.root/'index',self.models,self.database,self.roots)
        self.assertTrue(self.search('visual'));self.assertFalse(self.engine.status()['complete'])
    def test_pause_clear_and_cancel_apply_to_both_indices(self):
        self.build();self.engine.set_paused(True);self.assertTrue(self.engine.status()['paused'])
        self.engine.set_paused(False);self.assertFalse(self.engine.status()['paused'])
        with self.assertRaisesRegex(ValueError,'cancelled'):
            self.engine.search('rain',None,'','visual',20,lambda:True)
        self.engine.clear();self.assertEqual(self.engine.status()['indexed'],0)
        self.assertEqual(self.engine.sources.document_count(),4)
    def test_progress_callback_survives_visual_and_parameter_build_batches(self):
        events=[]
        plan=self.engine.preview()
        batches=list(self.engine.build(plan['plan_id'],lambda:False,progress=events.append))
        self.assertTrue(events)
        self.assertGreaterEqual(len(batches),2)
        status=self.engine.status()
        self.assertTrue(status['complete'])
        self.assertEqual(status['visual_indexed'],3)
        self.assertGreater(status['parameters_indexed'],0)
        processed=[event['processed'] for event in events]
        self.assertEqual(processed,sorted(processed))

    def test_worker_completes_gallery_build_with_its_progress_callback(self):
        from unittest.mock import patch
        from worker import Worker
        worker=Worker();worker.models=self.models
        worker.engines={'gallery':self.engine}
        token=threading.Event()
        plan=worker.execute('preview',{'source':'gallery'},token)
        job=worker.execute('start',{'source':'gallery','plan_id':plan['plan_id']},token)['job_id']
        events=[]
        with patch('worker.emit',side_effect=events.append):
            for _ in range(30):
                if job not in worker.jobs:break
                worker._step(job)
        self.assertNotIn(job,worker.jobs)
        self.assertNotIn('error',[event['phase'] for event in events])
        self.assertEqual(events[-1]['phase'],'complete')
        self.assertTrue(events[-1]['complete'])
        self.assertGreater(events[-1]['parameters_indexed'],0)

    def test_cancel_between_visual_and_parameter_batches_keeps_partial_index(self):
        cancelled=False;events=[]
        plan=self.engine.preview()
        generator=self.engine.build(plan['plan_id'],lambda:cancelled,progress=events.append)
        next(generator)
        cancelled=True
        self.assertEqual(list(generator),[])
        self.assertTrue(events)
        self.assertFalse(self.engine.status()['complete'])
        self.assertEqual(self.engine.status()['visual_indexed'],3)

    def test_bfloat_rounding_is_renormalized_before_storing_cosine_vectors(self):
        import numpy as np
        from models import Models
        result=Models._vectors(np.ones((2,768),dtype=np.float32)*.5001)
        np.testing.assert_allclose(np.linalg.norm(result,axis=1),1,atol=1e-6)
        with self.assertRaisesRegex(RuntimeError,'invalid_embeddings'):
            Models._vectors(np.zeros((1,768),dtype=np.float32))


if __name__=='__main__':unittest.main()
