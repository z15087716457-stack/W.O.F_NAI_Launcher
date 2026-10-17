"""JSONL local worker; one model owner and resumable, low-priority build steps."""
import importlib.metadata
from contextlib import redirect_stdout
import json
import os
import queue
import sys
import threading
import time
import uuid

from engine import Engine, Sources
from pool import VectorPool
from models import Models
from documents import TextEngine, WikiSources, BlockSources
from gallery import GalleryEngine

write_lock = threading.Lock()
protocol_stdout = sys.stdout


def emit(value):
    with write_lock:
        protocol_stdout.write(json.dumps(value, ensure_ascii=False, allow_nan=False) + '\n')
        protocol_stdout.flush()


class Worker:
    def __init__(self):
        self.queue = queue.PriorityQueue()
        self.sequence = 0; self.tokens = {}; self.jobs = {}
        self.engine = None; self.models = None; self.engines = {}; self.settings = None; self.pool = None
        self.last_use = time.monotonic(); self.running = True; self.suspended = False

    def enqueue(self, value, priority=0):
        self.sequence += 1
        self.queue.put((priority, self.sequence, value))

    def _event(self, **values):
        emit({'event': 'index', **values})

    def _step(self, job_id):
        job = self.jobs.get(job_id)
        if job is None or job['paused'] or self.suspended: return
        engine = self.engines[job['source']]
        try:
            progress = next(job['generator'])
            self._event(source=job['source'],job_id=job_id, phase='building', **progress)
            self.enqueue({'_step':job_id}, 10)
        except StopIteration:
            self.jobs.pop(job_id, None)
            self._event(source=job['source'],job_id=job_id, phase='paused' if job['cancel'].is_set() else 'complete', **engine.status())
        except Exception as error:
            self.jobs.pop(job_id, None)
            self._event(source=job['source'],job_id=job_id, phase='error', code=self.error_code(error), **engine.status())

    @staticmethod
    def error_code(error):
        # Never expose paths, query text, URLs, or raw backend exceptions.
        allowed = {'cancelled','source_changed','invalid_plan','index_busy','cuda_unavailable',
                   'invalid_embeddings','invalid_rerank_scores','invalid_context_mode','disabled_source',
                   'invalid_source','source_too_large','invalid_snapshot'}
        code = str(error)
        return code if code in allowed else 'rag_runtime_error'

    def close(self):
        # Release every owner even if one cleanup fails. Shared Engine.close()
        # only closes its scoped connection; the pool publishes one checkpoint.
        jobs, engines, pool, models = self.jobs, self.engines, self.pool, self.models
        self.jobs = {}; self.engines = {}; self.engine = self.pool = self.models = None
        error = None
        def attempt(action):
            nonlocal error
            try: action()
            except Exception as failure:
                if error is None: error = failure
        for job in jobs.values():
            job['cancel'].set(); attempt(job['generator'].close)
        for engine in engines.values(): attempt(engine.close)
        if pool: attempt(pool.close)
        if models: attempt(models.unload)
        if error is not None: raise error

    def execute(self, op, p, token, progress=None):
        if op == 'configure':
            if token.is_set(): raise ValueError('cancelled')
            if progress: progress('opening', 0, 0)
            self.close()
            models = Models(p['embedding'], p['reranker'], p.get('device','auto'))
            self.models = models
            enabled = p.get('sources',['tags'])
            if not isinstance(enabled,list) or any(s not in ('tags','wiki','blocks','gallery') for s in enabled): raise ValueError('invalid_source')
            root = os.path.abspath(p['directory'])
            self.pool = VectorPool(root,models.fingerprint,progress=progress,cancelled=token.is_set)
            if progress: progress('sources', 0, 0)
            if 'tags' in enabled:
                self.engine = self.engines['tags'] = Engine(root,models,Sources(p['catalog'],p.get('runtime',''),p.get('wiki','')),pool=self.pool,collection='tags')
            if 'wiki' in enabled:
                self.engines['wiki'] = TextEngine(os.path.join(root,'wiki-v1'),models,WikiSources(p['wiki'],p['catalog'],p.get('translations','')),pool=self.pool,collection='wiki')
            if 'blocks' in enabled:
                self.engines['blocks'] = TextEngine(os.path.join(root,'blocks-v1'),models,BlockSources(p['blocks']),pool=self.pool,collection='blocks')
            if 'gallery' in enabled:
                self.engines['gallery'] = GalleryEngine(os.path.join(root,'gallery-v1'),models,p['runtime'],p['gallery_roots'],pool=self.pool)
            self.settings = p; self.suspended = False
            if token.is_set(): raise ValueError('cancelled')
            return self.status(progress=progress, cancelled=token.is_set)
        if self.models is None: raise ValueError('not_configured')
        if op == 'status':
            return {**self.status(), **self.models.status()}
        if op in ('suspend','unload'):
            self.suspended = op == 'suspend'
            self.models.unload()
            return {**self.status(),'suspended':self.suspended}
        if op == 'release':
            self.suspended = False
            for job_id,j in self.jobs.items():
                if not j['paused']: self.enqueue({'_step':job_id},10)
            return {'suspended':False}
        source = p.get('source','tags')
        if source not in ('tags','wiki','blocks','gallery'): raise ValueError('invalid_source')
        engine = self.engines.get(source)
        if engine is None: raise ValueError('disabled_source')
        if op == 'preview': return engine.preview()
        if op == 'start':
            # Validate before clearing, in this same serialized command.
            engine.validate_plan(p['plan_id'])
            if p.get('rebuild'):
                if any(j['source']==source and not j['paused'] for j in self.jobs.values()): raise ValueError('index_busy')
                for previous,job in list(self.jobs.items()):
                    if job['source']==source:
                        job['cancel'].set();job['generator'].close();self.jobs.pop(previous)
                engine.clear()
            elif any(j['source']==source for j in self.jobs.values()): raise ValueError('index_busy')
            job_id = uuid.uuid4().hex
            cancellation = threading.Event()
            generator = engine.build(p['plan_id'], cancellation.is_set)
            # Validate the plan before acknowledging start; first work is queued.
            if not engine.plan or engine.plan['plan_id'] != p['plan_id']:
                raise ValueError('invalid_plan')
            self.jobs[job_id] = {'id':job_id,'source':source,'generator':generator,'cancel':cancellation,'paused':False,'signature':engine.sources.signature()}
            self.enqueue({'_step':job_id},10)
            return {'job_id':job_id}
        if op in ('pause','resume'):
            job = self.jobs.get(p['job_id'])
            if job and job['source'] != source: raise ValueError('invalid_source')
            if job and job['source'] == source:
                if op == 'resume' and job['signature'] != engine.sources.signature():
                    job['cancel'].set();job['generator'].close()
                    plan = engine.preview(); cancellation = threading.Event()
                    job.update(generator=engine.build(plan['plan_id'],cancellation.is_set),cancel=cancellation,
                               signature=engine.sources.signature())
                job['paused'] = op == 'pause'
                if op == 'resume': self.enqueue({'_step':p['job_id']},10)
            engine.set_paused(op == 'pause')
            return {'job_id':p['job_id'],'paused':op == 'pause',**engine.status()}
        if op == 'clear':
            for job_id,job in list(self.jobs.items()):
                if job['source'] == source:
                    job['cancel'].set(); job['generator'].close(); self.jobs.pop(job_id)
            engine.clear()
            return engine.status()
        if op == 'text_search':
            if source not in ('wiki','blocks'): raise ValueError('invalid_source')
            if self.suspended: return {'items':[],'fallback':'resource_busy'}
            self.last_use = time.monotonic()
            allowed = p.get('allowed'); categories = p.get('categories')
            if allowed is not None and (not isinstance(allowed,list) or len(allowed)>100000): raise ValueError('source_too_large')
            if categories is not None and (not isinstance(categories,list) or len(categories)>32): raise ValueError('invalid_source')
            return engine.search_text(p['query'][:32768],allowed,categories,
                min(80,max(1,p.get('limit',40))),token.is_set)
        if op == 'gallery_search':
            if source != 'gallery': raise ValueError('invalid_source')
            if self.suspended: return {'items':[],'fallback':'resource_busy'}
            self.last_use = time.monotonic()
            scope = p.get('scope')
            if not isinstance(scope,str) or os.path.getsize(scope)>64*1024*1024: raise ValueError('source_too_large')
            with open(scope,encoding='utf-8') as stream: paths = json.load(stream)
            if not isinstance(paths,list) or len(paths)>500000 or any(not isinstance(path,str) for path in paths): raise ValueError('source_too_large')
            return engine.search(p.get('query',''),paths,p.get('image',''),p.get('mode','mixed'),
                min(80,max(1,p.get('limit',60))),token.is_set)
        if op == 'search':
            if source != 'tags': raise ValueError('invalid_source')
            if self.suspended: return {'items':[],'fallback':'resource_busy'}
            if len(p['text']) > 262144: raise ValueError('input_too_large')
            self.last_use = time.monotonic()
            return engine.search(p['text'],p['cursor'],p.get('mode','around'),
                p.get('existing',[])[:20000],p.get('lexical',[])[:80],p.get('negative',False),
                min(80,max(1,p.get('limit',40))),token.is_set,p.get('keyword',''))
        raise ValueError('unknown_operation')

    def status(self, progress=None, cancelled=lambda: False):
        sources = {}
        for name,engine in self.engines.items():
            if cancelled(): raise ValueError('cancelled')
            if progress: progress('sources', len(sources), len(self.engines))
            status = engine.status()
            jobs = [j for j in self.jobs.values() if j['source'] == name]
            paused = status['paused'] or bool(jobs and all(j['paused'] for j in jobs))
            sources[name] = {**status,'paused':paused,'building':bool(jobs and not paused and not self.suspended)}
        tags = sources.get('tags',{'indexed':0,'total':0,'bytes':0,'complete':False,'partial':False,'building':False,'paused':False})
        return {**tags,'sources':sources,'suspended':self.suspended,
                'jobs':[{k:v for k,v in j.items() if k in ('id','paused','source')} for j in self.jobs.values()]}

    def run(self):
        while self.running:
            try: _,_,request = self.queue.get(timeout=1)
            except queue.Empty:
                if self.models and not any(not j['paused'] for j in self.jobs.values()) and time.monotonic()-self.last_use > 120:
                    self.models.unload(); self.last_use = time.monotonic()
                continue
            if '_step' in request:
                self._step(request['_step']); continue
            request_id = request['id']; token = self.tokens.get(request_id,threading.Event())
            try:
                if token.is_set(): raise ValueError('cancelled')
                def progress(phase, processed, total):
                    emit({'event':'initialization','request_id':request_id,
                          'phase':phase,'processed':processed,'total':total})
                result = self.execute(request['op'],request.get('params',{}),token,progress)
                if token.is_set(): raise ValueError('cancelled')
                emit({'id':request_id,'result':result})
            except Exception as error:
                emit({'id':request_id,'error':{'code':self.error_code(error)}})
            finally: self.tokens.pop(request_id,None)
        try: self.close()
        except Exception:
            emit({'event':'shutdown','phase':'failed'})
            raise
        emit({'event':'shutdown','phase':'complete'})

    def main(self):
        # Libraries may print progress to stdout. Keep the strict JSON pipe
        # isolated, including imports and prints from the inference thread.
        with redirect_stdout(sys.stderr):
            self._main()

    def _main(self):
        # Load native runtimes on the main thread before it blocks reading stdin.
        # On Windows, first importing NumPy/OpenBLAS from the executor thread
        # while the CRT is reading a pipe can deadlock inside DLL initialization.
        import numpy
        import torch
        import sentence_transformers
        import usearch.index
        thread = threading.Thread(target=self.run,daemon=True); thread.start()
        emit({'event':'ready','protocol':1,'versions':{name:importlib.metadata.version(name)
             for name in ('torch','transformers','sentence-transformers','numpy','usearch')}})
        for line in sys.stdin:
            if len(line) > 4*1024*1024: continue
            try:
                request = json.loads(line)
                if request.get('op') == 'shutdown': break
                if request.get('op') == 'cancel':
                    token = self.tokens.get(request.get('target'))
                    if token: token.set()
                    continue
                if not isinstance(request.get('id'),int) or len(self.tokens) >= 64: continue
                self.tokens[request['id']] = threading.Event()
                self.enqueue(request, -1 if request['op'] in ('pause','suspend','configure') else 0)
            except (ValueError,KeyError,TypeError): continue
        self.running = False
        for token in self.tokens.values(): token.set()
        for job in list(self.jobs.values()): job['cancel'].set()
        # The owning client bounds graceful shutdown and can terminate its Job.
        # Do not abandon a daemon writer halfway through a large checkpoint.
        thread.join()


if __name__ == '__main__':
    # Library progress belongs on stderr, never on the JSON protocol stream.
    Worker().main()
