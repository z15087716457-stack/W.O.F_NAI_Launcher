"""Real worker lifecycle, native imports and persisted fixtures; no model inference."""
from contextlib import closing
import json
import os
from pathlib import Path
import queue
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time
import unittest

from models import model_fingerprint
from pool import VectorPool
from test_rag import fixture
from test_tag_search import fixture_corpus


ENTRY = Path(os.getenv('RAG_WORKER_ENTRY', Path(__file__).with_name('worker.py'))).resolve()
HARNESS = '''
import runpy,sys,time
Worker=runpy.run_path(sys.argv[1])['Worker']
execute=Worker.execute
def fixture_execute(self,op,params,token,progress=None):
    if op=='fixture_encoder':
        self.models.encoder=object()
        self.last_use=time.monotonic()-300
        return {}
    if op=='fixture_models':
        from test_rag import FakeModels
        fixture=FakeModels()
        self.models.embed=fixture.embed
        self.models.count=fixture.count
        return {}
    if op=='fixture_crash':
        def fail(): raise RuntimeError('fixture executor failure')
        self._unload_in=fail
        return {}
    return execute(self,op,params,token,progress)
Worker.execute=fixture_execute
Worker().main()
'''


@unittest.skipUnless(os.getenv('RAG_TEST_PYTHON'), 'Requires RAG_TEST_PYTHON for native worker imports')
class WorkerProcessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        model = self.root/'model'; model.mkdir()
        (model/'config.json').write_text('{}')
        (model/'model.safetensors').write_bytes(b'fingerprint fixture; never loaded')
        catalog = self.root/'catalog.db'; fixture(catalog, 1)
        with closing(sqlite3.connect(catalog)) as db, db:
            db.execute("UPDATE tags SET name='cat_ears' WHERE id=1")
        corpus = self.root/'corpus.csv'; fixture_corpus(corpus,1)
        wiki = self.root/'wiki.db'
        with closing(sqlite3.connect(wiki)) as db, db:
            db.execute('CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY,body TEXT)')
            db.execute("INSERT INTO wiki_pages VALUES('tag_0','rain')")
        runtime = self.root/'runtime.db'
        sqlite3.connect(runtime).close()
        blocks = self.root/'blocks.json'
        blocks.write_text(json.dumps({'version':1, 'blocks':[{'id':'saved','title':'Saved','positive':'rain'}]}))
        roots = self.root/'roots.json'
        roots.write_text(json.dumps({'version':1,'roots':[str(self.root)]}))
        pool = VectorPool(self.root/'index', model_fingerprint(model))
        vector = __import__('numpy').zeros(768, dtype='float32'); vector[0] = 1
        for collection, name in [('tags','legacy_tag'), ('blocks',json.dumps(['saved','positive',0]))]:
            with pool.db:
                pool.db.execute('INSERT INTO pool_documents(collection,name,category,vector) VALUES(?,?,0,?)', (collection,name,vector.tobytes()))
                pool.db.execute("INSERT INTO pool_metadata VALUES(?,'consented','1')", (collection,))
        pool.close()
        self.params = {'embedding':str(model), 'device':'cpu', 'directory':str(self.root/'index'),
                       'catalog':str(catalog), 'tag_corpus':str(corpus), 'wiki':str(wiki), 'runtime':str(runtime),
                       'blocks':str(blocks), 'gallery_roots':str(roots), 'sources':['tags','wiki','blocks','gallery']}
        self.messages = queue.Queue(); self.errors = []; self.next_id = 0
        self.process = subprocess.Popen([os.environ['RAG_TEST_PYTHON'],'-B','-u','-c',HARNESS,str(ENTRY)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, encoding='utf-8', env={**os.environ,'PYTHONPATH':str(Path(__file__).parent.resolve())+os.pathsep+os.environ.get('PYTHONPATH',''),
                'PYTHONIOENCODING':'utf-8','PYTHONDONTWRITEBYTECODE':'1','HF_HUB_OFFLINE':'1','TRANSFORMERS_OFFLINE':'1'})
        self.addCleanup(self.stop)
        def output():
            for line in self.process.stdout: self.messages.put(json.loads(line))
        def errors(): self.errors.extend(self.process.stderr)
        self.readers = [threading.Thread(target=output,daemon=True),threading.Thread(target=errors,daemon=True)]
        for thread in self.readers: thread.start()
        self.receive(lambda value:value.get('event')=='ready', 45)

    def receive(self, predicate, timeout=8):
        deadline = time.monotonic()+timeout
        while time.monotonic()<deadline:
            try: value=self.messages.get(timeout=max(.01,deadline-time.monotonic()))
            except queue.Empty: break
            if predicate(value): return value
        self.fail('Worker did not respond; '+''.join(self.errors)[-1600:])

    def send(self, value):
        self.process.stdin.write(json.dumps(value)+'\n'); self.process.stdin.flush()

    def request(self, op, params=None):
        self.next_id += 1
        self.send({'id':self.next_id,'op':op,'params':params or {}})
        response = self.receive(lambda value:value.get('id')==self.next_id)
        self.assertNotIn('error',response)
        return response['result']

    def stop(self):
        if self.process.poll() is None:
            self.send({'op':'shutdown'})
            try: self.process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                self.process.kill(); self.process.wait(timeout=10)
        self.process.stdin.close()
        for thread in self.readers: thread.join(timeout=5)
        for stream in (self.process.stdout,self.process.stderr): stream.close()

    def test_configure_followup_unload_suspend_and_reopen_preserve_old_vectors(self):
        for turn in range(2):
            status = self.request('configure',self.params)
            self.assertEqual(set(status['sources']), {'tags','wiki','blocks','gallery'})
            self.assertEqual(status['sources']['blocks']['indexed'],1)
            self.assertEqual(status['sources']['tags']['indexed'],0)
            self.assertFalse(status['sources']['tags']['auto_update_allowed'])
            self.assertEqual(self.request('status')['sources']['blocks']['indexed'],1)
            self.request('fixture_encoder')
            self.assertFalse(self.request('status')['loaded'])
            self.assertTrue(self.request('suspend')['suspended'])
            self.request('release')
            self.assertFalse(self.request('status')['suspended'])
            self.assertEqual(self.request('preview',{'source':'tags'})['total'],4)
        self.stop()
        with closing(sqlite3.connect(self.root/'index'/'pool-v2'/model_fingerprint(self.root/'model')/'pool.sqlite')) as db:
            self.assertEqual(dict(db.execute('SELECT collection,COUNT(*) FROM pool_documents GROUP BY collection')), {'tags':1,'blocks':1})
        self.assertNotIn('Traceback',''.join(self.errors))

    def test_executor_failure_closes_owners_and_publishes_fatal_before_transport_exit(self):
        self.request('configure',self.params)
        self.request('fixture_crash')
        self.assertEqual(self.receive(lambda value:value.get('event')=='fatal')['code'],'worker_failed')
        self.assertIsNone(self.process.poll())
        self.stop()
        self.assertIn('fixture executor failure',''.join(self.errors))

    def test_confirmed_fixture_build_and_exact_search_use_the_real_worker_protocol(self):
        self.request('configure',self.params)
        self.request('fixture_models')
        preview = self.request('preview',{'source':'tags'})
        self.assertTrue(preview['upgrade_available'])
        self.request('start',{'source':'tags','plan_id':preview['plan_id']})
        event = self.receive(lambda value:value.get('event')=='index' and value.get('phase')=='complete')
        self.assertEqual(event['indexed'],4)
        self.assertFalse(event['upgrade_available'])
        result = self.request('search',{'query':'cat ears','top_k':10})
        self.assertEqual([row['name'] for row in result['items']],['cat_ears'])
        self.assertNotIn('lexical',result['items'][0]['origins'])
        self.assertEqual(self.request('status')['sources']['blocks']['indexed'],1)
        self.stop()
        with closing(sqlite3.connect(self.root/'index'/'pool-v2'/model_fingerprint(self.root/'model')/'pool.sqlite')) as db:
            self.assertEqual(dict(db.execute('SELECT collection,COUNT(*) FROM pool_documents GROUP BY collection')),
                             {'danbooru-search-v1':4,'blocks':1})
        checkpoint = json.loads((self.root/'index'/'pool-v2'/model_fingerprint(self.root/'model')/'ann.json').read_text('utf-8'))
        self.assertEqual(checkpoint['count'], 1)
        self.assertEqual(checkpoint['scope'], 'non-tag-v1')


if __name__=='__main__': unittest.main()
